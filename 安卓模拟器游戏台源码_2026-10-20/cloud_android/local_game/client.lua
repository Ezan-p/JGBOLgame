-- Independent local mode, running inside the original Cocos2d-x ARM32 client.
-- No Lenovo login, official server connection, payment or remote updater.
local json = require("base.json")
local home = require("local_home")
local combat = require("local_battle")
local battleHall = require("local_battle_hall")
local handbook = require("local_handbook")
local cortege = require("local_cortege")
local summonOK, summon = pcall(require,"local_summon")
if not summonOK then CCLuaLog("LOCAL_SUMMON_LOAD_ERROR: "..tostring(summon)); error(summon) end
local inventoryOK, inventory = pcall(require,"local_inventory")
if not inventoryOK then CCLuaLog("LOCAL_INVENTORY_LOAD_ERROR: "..tostring(inventory)); error(inventory) end
local enhanceOK, enhance = pcall(require,"local_enhance")
if not enhanceOK then CCLuaLog("LOCAL_ENHANCE_LOAD_ERROR: "..tostring(enhance)); error(enhance) end
local lineupOK, lineup = pcall(require,"local_lineup")
if not lineupOK then CCLuaLog("LOCAL_LINEUP_LOAD_ERROR: "..tostring(lineup)); error(lineup) end
local training = require("local_training")
local journeyOK, journey = pcall(require,"local_journey")
if not journeyOK then CCLuaLog("LOCAL_JOURNEY_LOAD_ERROR: "..tostring(journey)); error(journey) end
local KEY = "__LOCAL_KEY__"
local BASE = "http://10.0.2.2:8770/rpc"
local director = CCDirector:sharedDirector()
local scheduler = director:getScheduler()
local path = CCFileUtils:sharedFileUtils():getWriteablePath() .. "setting_w/"
local scene, layer, root, statusLabel
local buttons = {}
local state, battle, requestPending
local page, pageIndex = "home", 1
local qualityFilter = 0
local busy, failed = false, false
local notice = "正在连接本地存档…"
local elapsed = 0
local render, send, showBattle
local homeInfo, pressed, lastError
local W, H = 960, 540
local screen = director:getWinSize()
local sx, sy = screen.width / W, screen.height / H
local sessionPath = path .. "local_session.json"

local function read(filename)
    local f = io.open(filename, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return s
end

local function decode(s)
    if not s then return nil end
    -- The bundled 2015 decoder rejects empty arrays. In Lua both [] and {}
    -- represent an empty table. Normalize tokens only, never quoted item text.
    local parts, quoted, escaped, i = {}, false, false, 1
    while i<=#s do
        local ch=string.sub(s,i,i)
        if quoted then
            table.insert(parts,ch)
            if escaped then escaped=false
            elseif ch=="\\" then escaped=true
            elseif ch=='"' then quoted=false end
        elseif ch=='"' then quoted=true;table.insert(parts,ch)
        elseif ch=="[" and string.sub(s,i+1,i+1)=="]" then
            table.insert(parts,"{}");i=i+1
        else table.insert(parts,ch) end
        i=i+1
    end
    s=table.concat(parts)
    local ok, value = pcall(json.decode, s)
    if ok and type(value) == "table" then return value end
    return nil
end

local session = decode(read(sessionPath))
if not session then
    math.randomseed(os.time())
    session = {player = "guest-" .. os.time() .. "-" .. math.random(10000000, 99999999), counter = 0}
end

local function saveSession()
    local f = assert(io.open(sessionPath .. ".tmp", "wb"))
    f:write(json.encode(session))
    f:close()
    assert(os.rename(sessionPath .. ".tmp", sessionPath))
end

local function box(x, y, w, h, color)
    local node = CCLayerColor:create(ccc4(color[1], color[2], color[3], color[4] or 255))
    node:setContentSize(CCSizeMake(w, h))
    node:setPosition(CCPointMake(x, y))
    root:addChild(node)
    return node
end

local function text(value, x, y, size, color, center)
    local label = CCLabelTTF:create(tostring(value), "Arial", size or 20)
    label:setAnchorPoint(CCPointMake(center and .5 or 0, .5))
    label:setPosition(CCPointMake(x, y))
    color = color or {235, 230, 213}
    label:setColor(ccc3(color[1], color[2], color[3]))
    root:addChild(label)
    return label
end

local function button(title, x, y, w, h, action, enabled, retry)
    if enabled == nil then enabled = true end
    box(x, y, w, h, enabled and {184, 135, 65, 255} or {67, 70, 73, 255})
    box(x + 1, y + 1, w - 2, h - 2, enabled and {43, 39, 32, 255} or {35, 40, 44, 255})
    text(title, x + w / 2, y + h / 2, 19,
         enabled and {255, 219, 153} or {140, 145, 147}, true)
    table.insert(buttons, {x=x, y=y, w=w, h=h, action=action, enabled=enabled, retry=retry})
end

local function art(filename, x, y, maxw, maxh)
    local sprite = CCSprite:create(filename)
    if not sprite then return nil end
    local size = sprite:getContentSize()
    sprite:setScale(math.min(maxw / size.width, maxh / size.height))
    sprite:setPosition(CCPointMake(x, y))
    root:addChild(sprite)
    return sprite
end

local function heroCard(hero, x, mode)
    box(x, 119, 276, 307, {17, 27, 32, 235})
    text(hero.name .. "  Lv." .. hero.level, x+138, 400, 23, {255, 218, 155}, true)
    text(hero.quality .. "星 · " .. (hero.category or "") .. " · " .. (hero.skill_name or ""),
         x+138, 376, 15, {173, 186, 183}, true)
    art(hero.sprite, x+138, 287, 190, 150)
    text("生命 " .. hero.hp .. "  攻击 " .. hero.attack, x+138, 200, 18, nil, true)
    if mode == "recruit" then
        text("防御 " .. hero.defense .. " · 招募后永久拥有", x+138, 181, 16, {173, 186, 183}, true)
        button("招募 · " .. hero.cost .. " 银两", x+25, 131, 226, 36,
               function() send("recruit", {hero=hero.id}) end, state.silver >= hero.cost)
    elseif mode == "hero" then
        button("培养", x+12, 133, 144, 39,
               function() training.open(hero.id,"heroes"); page="training"; render() end, true)
        button(hero.active and "休息" or "出战", x+165, 133, 99, 39,
               function() send("lineup", {hero=hero.id}) end)
    else
        text("防御 " .. hero.defense .. " · 出战中", x+138, 169, 18, {173, 186, 183}, true)
    end
end

local function nav()
    local items = {{"home","首页"},{"heroes","角色培养"},{"stages","取经关卡"},{"recruit","招募伙伴"}}
    for i, item in ipairs(items) do
        local target = item[1]
        button((page == target and "◆ " or "") .. item[2], 36+(i-1)*225, 55, 213, 43,
               function()
                   if target=="heroes" then handbook.open() end
                   page=target; pageIndex=1; qualityFilter=0; notice="每次操作自动保存"; render()
               end)
    end
end

local function header()
    text("金箍棒", 36, 504, 29, {255, 223, 163})
    text("本地模式", 156, 504, 19, {187, 204, 202})
    if page~="heroes" and page~="lineup" and page~="recruit" then
        text("免账号 · 本机存档 · 本地 PvE 规则", 36, 471, 16, {192, 202, 198})
    end
    if state then
        text("银两  " .. state.silver, 590, 504, 21, {255, 220, 153})
        text("体力  " .. state.energy .. "/60", 785, 504, 21)
        text("行者 Lv." .. state.level .. "  ·  关卡 " .. state.unlocked .. "/10", 310, 504, 17)
    end
end

render = function()
    if not root then return end
    combat.stop()
    root:removeAllChildrenWithCleanup(true)
    buttons = {}
    statusLabel=nil
    pressed=nil
    if page=="recruit" then page="summon"; if state then summon.open() end end
    if page=="battle" and battle then showBattle(); return end
    if state and page=="battle_hall" then
        battleHall.draw({root=root,render=render,send=send,busy=busy,failed=failed,error=lastError,notice=notice,
            clearHits=function() buttons={} end,
            hit=function(x,y,w,h,action,enabled,node) table.insert(buttons,{x=x,y=y,w=w,h=h,action=action,enabled=enabled,node=node}) end,
            navigate=function(target) page=target;render() end},state)
        return
    end
    if state and page=="stages" then
        journey.draw({
            root=root, render=render, send=send, failed=failed, error=lastError, busy=busy,
            hit=function(x,y,w,h,action,enabled,node,retry)
                table.insert(buttons,{x=x,y=y,w=w,h=h,action=action,enabled=enabled,node=node,retry=retry})
            end,
            navigate=function(target) page=target; homeInfo=nil; render() end,
        },state)
        home.draw({
            root=root,text=text,hideHeader=true,menuOnly=true,
            hit=function(x,y,w,h,action,node)
                table.insert(buttons,{x=x,y=y,w=w,h=h,action=action,enabled=true,node=node})
            end
        },state,function(target)
            if target=="heroes" then handbook.open() end
            if target=="cortege" and page~="heroes" then cortege.open() end
            if target=="lineup" then lineup.open() end
            if target=="inventory" then inventory.open() end
            page=target; pageIndex=1; qualityFilter=0; homeInfo=nil; render()
        end,function(title,lines)
            page="home"; homeInfo={title=title,lines=lines}; render()
        end)
        return
    end
    if state and page=="training" then
        training.draw({
            root=root, render=render, send=send, busy=busy, failed=failed,
            error=lastError, notice=notice,
            clearHits=function() buttons={} end,
            hit=function(x,y,w,h,action,enabled,node)
                table.insert(buttons,{x=x,y=y,w=w,h=h,action=action,enabled=enabled,node=node})
            end,
            navigate=function(target) page=target; homeInfo=nil; render() end,
        },state)
        if failed then
            button("重试连接",35,84,160,33,function() send("state",{}) end,true,true)
        end
        return
    end
    if state and (page=="home" or page=="cortege" or page=="heroes" or page=="lineup" or page=="inventory" or page=="summon") then
        home.draw({
            root=root, text=text, hideHeader=page~="home",
            hit=function(x,y,w,h,action,node)
                table.insert(buttons,{x=x,y=y,w=w,h=h,action=action,enabled=true,node=node})
            end
        },state,function(target)
            if target=="heroes" then handbook.open() end
            if target=="cortege" and page~="heroes" then cortege.open() end
            if target=="lineup" then lineup.open() end
            if target=="inventory" then inventory.open() end
            if target=="stages" then journey.open() end
            if target=="summon" then summon.open() end
            page=target; pageIndex=1; qualityFilter=0; homeInfo=nil; render()
        end,function(title,lines)
            page="home"; homeInfo={title=title,lines=lines}; render()
        end)
        if page=="summon" then
            local bottom={}
            for _,b in ipairs(buttons) do
                if b.y==0 and b.h<=80 then table.insert(bottom,b) end
            end
            buttons=bottom
            summon.draw({
                root=root,render=render,send=send,busy=busy,failed=failed,error=lastError,notice=notice,
                clearHits=function() buttons={} end,
                hit=function(x,y,w,h,action,enabled,node)
                    table.insert(buttons,{x=x,y=y,w=w,h=h,action=action,enabled=enabled,node=node})
                end,
                navigate=function(target) page=target;homeInfo=nil;render() end,
            },state)
            return
        end
        if page=="inventory" then
            local bottom={}
            for _,b in ipairs(buttons) do
                if b.y==0 and b.h<=80 then table.insert(bottom,b) end
            end
            buttons=bottom
            inventory.draw({
                root=root,render=render,send=send,busy=busy,failed=failed,error=lastError,notice=notice,
                clearHits=function() buttons={} end,
                hit=function(x,y,w,h,action,enabled,node,retry)
                    table.insert(buttons,{x=x,y=y,w=w,h=h,action=action,enabled=enabled,node=node,retry=retry})
                end,
                navigate=function(target) page=target;homeInfo=nil;render() end,
            },state)
            return
        end
        if page=="lineup" then
            local bottom={}
            for _,b in ipairs(buttons) do
                if b.y==0 and b.h<=80 then table.insert(bottom,b) end
            end
            buttons=bottom
            lineup.draw({
                root=root,render=render,send=send,busy=busy,failed=failed,error=lastError,
                openBag=function(category,uid,hero,spellPos,preview)
                    inventory.open();inventory.returnPage="lineup";inventory.tab=category;inventory.selected=uid
                    inventory.equipHero=hero;inventory.equipPos=spellPos;inventory.preview=preview
                    page="inventory";render()
                end,
                demo=function() battle=combat.preview();page="battle";render() end,
                clearHits=function() buttons={} end,
                hit=function(x,y,w,h,action,enabled,node,retry)
                    table.insert(buttons,{x=x,y=y,w=w,h=h,action=action,enabled=enabled,node=node,retry=retry})
                end,
                openTraining=function(ident)
                    training.open(ident,"lineup")
                    page="training"; render()
                end,
                navigate=function(target)
                    if target=="summon" then summon.open() end
                    page=target;homeInfo=nil;render()
                end,
            },state)
            return
        end
        if page=="cortege" then
            -- Original mainUI "神仙" board: four side tabs and the 图鉴 button.
            local bottom={}
            for _,b in ipairs(buttons) do
                if b.y==0 and b.h<=80 then table.insert(bottom,b) end
            end
            buttons=bottom
            cortege.draw({
                root=root, render=render, send=send,
                notice=busy and "正在保存…" or notice,
                hit=function(x,y,w,h,action,enabled,node)
                    table.insert(buttons,{x=x,y=y,w=w,h=h,action=action,enabled=enabled,node=node})
                end,
                openTraining=function(ident)
                    training.open(ident,"cortege")
                    page="training"; render()
                end,
                navigate=function(target)
                    if target=="heroes" then handbook.open() end
                    page=target; homeInfo=nil; render()
                end,
            },state)
            if failed then
                button("重试连接",35,84,160,33,function() send("state",{}) end,true,true)
            end
            return
        end
        if page=="heroes" then
            -- Boards swallow scenic taps; the original bottom navigation remains usable.
            local bottom={}
            for _,b in ipairs(buttons) do
                if b.y==0 and b.h<=80 then table.insert(bottom,b) end
            end
            buttons=bottom
            handbook.draw({
                root=root, render=render, send=send,
                notice=busy and "正在保存…" or notice,
                hit=function(x,y,w,h,action,enabled,node)
                    table.insert(buttons,{x=x,y=y,w=w,h=h,action=action,enabled=enabled,node=node})
                end,
                openTraining=function(ident)
                    training.open(ident,"heroes")
                    page="training"; render()
                end,
                navigate=function(target) page=target; homeInfo=nil; render() end,
            },state)
            if failed then
                button("重试连接",35,84,160,33,function() send("state",{}) end,true,true)
            end
            return
        end
        if failed then
            box(240,85,480,48,{18,22,26,235})
            statusLabel=text("本地服务未响应",255,109,18,{255,218,155})
            button("重试连接",555,91,150,35,function() send("state",{}) end,true,true)
        end
        if homeInfo then
            buttons={}
            box(0,0,W,H,{0,0,0,155})
            box(211,130,538,300,{128,92,49,255})
            box(214,133,532,294,{36,29,25,250})
            art("v2/mainUI/ask1.png",480,397,275,57)
            -- Cover the original title text while retaining its ornamental frame.
            box(378,384,204,27,{56,36,23,255})
            text(homeInfo.title,480,397,24,{255,222,156},true)
            for i,line in ipairs(homeInfo.lines) do
                text(line,480,347-(i-1)*36,18,{239,226,200},true)
            end
            button("返回首页",380,151,200,42,function() homeInfo=nil; render() end)
        end
        return
    end
    local bg = CCSprite:create("v2/mainUI/bkg_d.jpg")
    if bg then
        local size = bg:getContentSize()
        bg:setScaleX(W/size.width)
        bg:setScaleY(H/size.height)
        bg:setPosition(CCPointMake(W/2,H/2))
        root:addChild(bg)
    end
    box(0,0,W,H,{10,19,27,148})
    box(0,449,W,91,{10,18,25,228})
    box(0,0,W,111,{10,18,25,238})
    header()
    if not state then
        text("本地取经之旅", 480, 330, 36, {255,220,153}, true)
        text("无需手机号，角色和进度保存在这台电脑",480,278,22,nil,true)
        text("原版美术资源 · 独立关卡与培养规则",480,240,18,{183,197,198},true)
        if failed then
            button("重新连接",360,155,240,50,function() send("login",{}) end,true,true)
        end
    elseif page == "heroes" or page == "lineup" or page == "recruit" then
        button("战斗演示",780,8,144,34,function()
            battle=combat.preview(); page="battle"; render()
        end)
        local all = page == "recruit" and state.recruits or state.heroes
        local list = {}
        for _,hero in ipairs(all) do
            if qualityFilter==0 or hero.quality==qualityFilter then table.insert(list,hero) end
        end
        table.sort(list,function(a,b)
            if a.quality~=b.quality then return a.quality>b.quality end
            return a.id<b.id
        end)
        local maxpage=math.max(1,math.ceil(#list/3))
        pageIndex=math.min(pageIndex,maxpage)
        for i,q in ipairs({0,5,4,3,2}) do
            local quality=q
            button((qualityFilter==q and "◆" or "") .. (q==0 and "全部" or q.."星"),
                   36+(i-1)*77,452,72,34,function()
                       qualityFilter=quality; pageIndex=1; render()
                   end)
        end
        text(#list.."位  "..pageIndex.."/"..maxpage.."页",515,469,16,nil,true)
        button("上一页",625,452,142,34,
               function() pageIndex=pageIndex-1; render() end,pageIndex>1)
        button("下一页",782,452,142,34,
               function() pageIndex=pageIndex+1; render() end,pageIndex<maxpage)
        for i=(pageIndex-1)*3+1,math.min(pageIndex*3,#list) do
            heroCard(list[i],36+((i-1)%3)*306,page=="recruit" and "recruit" or "hero")
        end
        if #list == 0 then
            text(page=="recruit" and (#all==0 and "所有伙伴均已加入队伍" or "该品质伙伴均已招募")
                 or "尚未拥有该品质伙伴",480,280,28,nil,true)
        end
        nav()
    elseif page == "battle" and battle then
        showBattle()
    end
    statusLabel=text(busy and "正在与本地服务同步…" or notice,36,25,16,{174,195,188})
    if failed and state then
        button("重试连接",774,7,150,35,function() send("state",{}) end,true,true)
    end
end

showBattle = function()
    combat.show({root=root,
        clearButtons=function() buttons={}; pressed=nil end,
        hit=function(x,y,w,h,action,enabled,n)
            table.insert(buttons,{x=x,y=y,w=w,h=h,action=action,enabled=enabled,node=n})
        end,
        navigate=function(target) page=target; render() end,
    },battle)
end

local function escape(value)
    return string.gsub(tostring(value),"([^%w%-_%.~])",function(c) return string.format("%%%02X",string.byte(c)) end)
end

local function transmit()
    busy=true; failed=false; elapsed=0
    local pending=session.pending
    requestPending=pending
    pending.filename="local_"..pending.id..".json"
    os.remove(path..pending.filename)
    local url=BASE.."?key="..KEY.."&player="..escape(session.player)
        .."&request="..escape(pending.id).."&op="..escape(pending.op)
        .."&args="..escape(next(pending.args) and json.encode(pending.args) or "{}")
    main_server.update_files(url,pending.filename,path,1,8)
    render()
end

send = function(op,args)
    if busy then return end
    lastError=nil
    if not session.pending then
        session.counter=session.counter+1
        session.pending={id=session.player.."-"..session.counter,op=op,args=args}
        saveSession()
    end
    -- A timed-out mutation is retried with exactly the same ID and payload.
    transmit()
end

local function tick(dt)
    if busy and requestPending then
        elapsed=elapsed+dt
        local response=decode(read(path..requestPending.filename))
        if response then
            os.remove(path..requestPending.filename)
            busy=false; failed=false
            session.pending=nil
            requestPending=nil
            saveSession()
            if response.ok then
                lastError=nil
                state=response.state
                if enhance.isOpen() then enhance.afterUpdate(state) end
                if page=="inventory" and inventory.afterUpdate then inventory.afterUpdate(state) end
                if page=="inventory" and inventory.equipPending then page="lineup" end
                notice=response.notice or "已连接本地服务 · 进度已保存"
                if response.battle then battle=response.battle; page="battle" end
                if response.summon_result and page=="summon" then summon.reveal(response.summon_result) end
            else
                notice=response.error or "操作失败"
                lastError=notice
                if not state then failed=true end
            end
            inventory.equipPending=nil
            render()
        elseif elapsed>12 then
            busy=false; failed=true
            notice="本地服务未响应，请确认游戏台已启动后重试"
            render()
        end
    end
    if page=="battle" then combat.update(dt) end
end

function __G__TRACKBACK__(message)
    CCLuaLog("LOCAL_GAME_ERROR: "..tostring(message).."\n"..debug.traceback())
    notice="本地客户端发生错误，请查看游戏台日志"
    if statusLabel then statusLabel:setString(notice) end
end

local function navigateBack()
    if not state or busy or session.pending then return end
    if page=="heroes" then handbook.back()
    elseif page=="training" then training.back()
    elseif page=="cortege" then cortege.back()
    elseif page=="stages" then journey.back()
    elseif page=="lineup" then lineup.back()
    elseif page=="battle_hall" then battleHall.back()
    elseif page=="inventory" then inventory.back()
    elseif page=="summon" then summon.back()
    else page="home"; homeInfo=nil; render() end
end

function main_entrance(msgid,msg,time)
    if msgid==22 then
        local event={}
        main_server.recv_msg(msgid,msg,event)
        if event.eventID==4 then navigateBack() end
    end
    return 0
end

function error_handler() return 0 end

local function init()
    jit.off()
    main_server.register_type(22,"eventID=i,status=i")
    main_server.register_type(21,"type=i,size=i,totalSize=d,status=i,filename=S[255]")
    scene=CCScene:create()
    layer=CCLayer:create()
    root=CCNode:create()
    root:setScaleX(sx); root:setScaleY(sy)
    scene:addChild(layer); layer:addChild(root)
    layer:registerScriptTouchHandler(function(event,x,y)
        -- This engine dispatches Android keypad events through the touch callback
        -- (see original common/utils.enableAndroidBack), without x/y coordinates.
        if event==1001 then navigateBack(); return true end
        if event==1002 then return true end
        if page=="inventory" and not busy and not session.pending and inventory.touch(event,x/sx,y/sy) then
            pressed=nil
            return true
        end
        if page=="cortege" and not busy and not session.pending and cortege.touch(event,x/sx,y/sy) then
            pressed=nil
            return true
        end
        if page=="heroes" and not busy and not session.pending and handbook.touch(event,x/sx,y/sy) then
            pressed=nil
            return true
        end
        if page=="lineup" and not busy and not session.pending and lineup.touch(event,x/sx,y/sy) then
            pressed=nil
            return true
        end
        if page=="stages" and not busy and not session.pending and journey.touch(event,x/sx,y/sy) then
            pressed=nil
            return true
        end
        if page=="summon" and summon.touch(event,x/sx,y/sy) then
            pressed=nil
            return true
        end
        if event==CCTOUCHBEGAN or event=="began" then
            x=x/sx; y=y/sy
            for i=#buttons,1,-1 do
                local b=buttons[i]
                if b.enabled and x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h then
                    pressed=b
                    if b.node then b.node:setColor(ccc3(255,213,145)) end
                    break
                end
            end
            return true
        end
        if event==CCTOUCHENDED or event=="ended" then
            x=x/sx; y=y/sy
            if pressed and pressed.node then pressed.node:setColor(ccc3(255,255,255)) end
            for i=#buttons,1,-1 do
                local b=buttons[i]
                if b.enabled and x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h then
                    if b==pressed and not busy and (not session.pending or b.retry) then
                        xpcall(b.action,__G__TRACKBACK__)
                    end
                    break
                end
            end
            pressed=nil
        end
        return true
    end,false,0,true)
    layer:setTouchEnabled(true)
    layer:setKeypadEnabled(true)
    if director:getRunningScene() then director:replaceScene(scene) else director:runWithScene(scene) end
    scheduler:scheduleScriptFunc(function(dt) xpcall(function() tick(dt) end,__G__TRACKBACK__) end,1/30,false)
    render()
    send("login",{})
    CCLuaLog("LOCAL_GAME_READY local-v2")
end

xpcall(init,__G__TRACKBACK__)
