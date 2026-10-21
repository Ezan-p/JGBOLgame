-- 神仙 module reconstructed from the original ui/lineupUI.lua.
-- Left tabs: 神仙 / 魂魄 / 精魄 / 五法界魂, with the original 图鉴 button
-- opening ui/handbookUI.lua. Rows follow allLineupUI.createSoulCellOnLineup,
-- lineupUI.createJingpoCellOnPackage and soulExchangeUI.createCommonSoulCell.
local data = require("local_handbook_data")
local heroDetail = require("local_hero_detail")
local M = {tab="heroes", offsets={}}
local GOLD = {255,235,190}
local PALE = {238,226,202}
local MUTED = {179,152,119}
local ORANGE = {253,190,37}
local ui, state, root
local GX,GY,GW,GH = 249.6,97.2,662.4,356.4
local FIRST_Y,STEP_Y = 299.7,118.8
-- The old CCScrollView positions its container at the view origin, so row
-- children use viewport-relative coordinates (no GX/GY here).
local RX0,RW = 6,GW-16

local TABS = {
    {key="heroes", icon="v2/CharaterUI/shenxian"},
    {key="souls", icon="v2/CharaterUI/hunpo"},
    {key="jp", icon="v2/CharaterUI/jingpo"},
    {key="spirits", icon="v2/CharaterUI/common"},
}

local function image(file,x,y,w,h,parent)
    local node=CCSprite:create(file)
    if not node then return nil end
    local size=node:getContentSize()
    if w then
        node:setScaleX(w/size.width)
        node:setScaleY((h or w*size.height/size.width)/size.height)
    end
    node:setPosition(CCPointMake(x,y))
    local target=parent or root
    target:addChild(node)
    return node
end

local function label(value,x,y,size,color,parent,center,width)
    local node
    if width then
        node=CCLabelTTF:create(tostring(value),"Arial",size,CCSizeMake(width,0),kCCTextAlignmentLeft)
    else
        node=CCLabelTTF:create(tostring(value),"Arial",size)
    end
    node:setAnchorPoint(CCPointMake(center and .5 or 0,width and 1 or .5))
    node:setPosition(CCPointMake(x,y))
    node:setColor(ccc3(unpack(color or GOLD)))
    local target=parent or root
    target:addChild(node)
    return node
end

local function fill(x,y,w,h,color,parent)
    local node=CCLayerColor:create(ccc4(unpack(color)))
    node:setContentSize(CCSizeMake(w,h))
    node:setPosition(CCPointMake(x,y))
    local target=parent or root
    target:addChild(node)
    return node
end

-- Row buttons move with the scroll container, so they are drawn without a
-- static hit box; the list's tap callback checks the right-hand area instead.
local function rowButton(title,x,y,w,h,enabled,parent)
    local node=image("v2/soulExchangeUI/btn_bkg1.png",x+w/2,y+h/2,w,h,parent)
    if node and not enabled then node:setColor(ccc3(112,104,95)) end
    label(title,x+w/2,y+h/2,16,enabled and GOLD or MUTED,parent,true)
end

local function own(id)
    for _,hero in ipairs(state.heroes) do
        if hero.id==id then return hero end
    end
end

local function heroMeta(id)
    for _,hero in ipairs(data.heroes) do
        if hero.id==id then return hero end
    end
end

local function itemCount(id)
    local key="i"..id
    local total=0
    for _,entry in ipairs((state.inventory and state.inventory.entries) or {}) do
        if entry.key==key then total=total+(entry.count or 1) end
    end
    return total
end

local function itemLevel(id)
    local key="i"..id
    local level=0
    for _,entry in ipairs((state.inventory and state.inventory.entries) or {}) do
        if entry.key==key and (entry.level or 0)>level then level=entry.level end
    end
    return level
end

local function icon(entry,x,y,width,parent,dim)
    local info=entry.icon
    if not info then return end
    local node=CCSprite:create(info.file)
    if not node then return end
    local size=node:getContentSize()
    local w,h=size.width,size.height
    if info.index then
        w,h=w/info.columns,h/info.rows
        node:setTextureRect(CCRectMake((info.index-1)%info.columns*w,
                            math.floor((info.index-1)/info.columns)*h,w,h))
    end
    node:setScale(width/w)
    node:setPosition(CCPointMake(x,y))
    if dim then node:setColor(ccc3(122,122,122)) end
    parent:addChild(node)
    return node
end

local function stars(quality,x,y,parent)
    local node=CCSprite:create("v2/introUI/stars.png")
    if not node then return end
    local size=node:getContentSize()
    node:setTextureRect(CCRectMake(0,0,size.width*quality/5,size.height))
    node:setAnchorPoint(CCPointMake(0,.5))
    node:setScale(.9)
    node:setPosition(CCPointMake(x,y))
    parent:addChild(node)
end

local function frame()
    image("v2/packageUI/board_chain.png",221,525,76,235):setAnchorPoint(CCPointMake(.5,0))
    image("v2/packageUI/board_chain.png",730,525,76,235):setAnchorPoint(CCPointMake(.5,0))
    fill(24,86.4,912,432,{39,24,19,255})
    image("v2/introUI/intro_bkg.png",480,302.4,912,432)
    image("v2/packageUI/board_leftBkg.png",121,302.4,194,432)
    image("v2/packageUI/board_mid_edge.png",220.8,302.4,19,432)
    image("v2/packageUI/board_edge1.png",24,302.4,15,432)
    local right=image("v2/packageUI/board_edge1.png",936,302.4,15,432)
    right:setFlipY(true)
    image("v2/packageUI/board_edge2.png",480,514.1,930,37.2)
    image("v2/packageUI/board_edge2.png",480,90.7,930,37.2):setFlipY(true)
    local close=image("v2/introUI/close1.png",921.6,513,63,60)
    ui.hit(890,483,63,57,function() M.back() end,true,close)
end

local function tabs()
    for i,tab in ipairs(TABS) do
        local y=475.2-(i-1)*64.8
        local node=image(tab.icon..(M.tab==tab.key and "2" or "1")..".png",115.2,y,172.8)
        ui.hit(28.8,y-32.4,172.8,64.8,function()
            if M.tab==tab.key then return end
            M.tab=tab.key; M.selected=nil; M.modal=nil; M.exchange=nil
            M.gesture=nil; ui.render()
        end,true,node)
    end
    -- Original ui/lineupUI.pressHandBook -> handbookUI with ready_open_tag = 4.
    local book=image("v2/handbook/tj_btn1.png",115.2,205,130,65)
    ui.hit(50,172.5,130,65,function()
        M.modal=nil; M.exchange=nil; M.gesture=nil
        ui.navigate("heroes")
    end,true,book)
end

local function setOffset(value)
    local s=M.scroll
    if not s then return end
    s.offset=math.max(0,math.min(s.max,value))
    s.node:setPositionY(s.offset)
    M.offsets[s.key]=s.offset
    if s.thumb then
        s.thumb:setPositionY(s.y+s.h-s.thumbHeight-(s.max>0 and s.offset/s.max or 0)*(s.h-s.thumbHeight))
    end
end

local function scrollArea(x,y,w,h,key,totalHeight,onTap)
    local container=CCLayer:create()
    container:setContentSize(CCSizeMake(w,math.max(h,totalHeight)))
    -- Old engine GL scissor ignores ancestor scaling; compensate only the viewport.
    local view=CCScrollView:create(CCSizeMake(w*root:getScaleX(),h*root:getScaleY()),container)
    view:setTouchEnabled(false)
    view:setPosition(CCPointMake(x,y))
    root:addChild(view)
    M.scroll={node=container,x=x,y=y,w=w,h=h,key=key,
              max=math.max(0,totalHeight-h),offset=0,onTap=onTap}
    if totalHeight>h then
        fill(x+w+4,y,3,h,{65,43,29,220})
        local thumbHeight=math.max(24,h*h/totalHeight)
        M.scroll.thumb=fill(x+w+4,y+h-thumbHeight,3,thumbHeight,{170,124,67,235})
        M.scroll.thumbHeight=thumbHeight
    end
    setOffset(M.offsets[key] or 0)
    return container
end

local function rowList()
    if M.tab=="heroes" then
        local list={}
        for _,hero in ipairs(state.heroes) do
            local meta=heroMeta(hero.id)
            if meta then
                local row={}
                for k,v in pairs(meta) do row[k]=v end
                row.level=hero.level; row.active=hero.active
                list[#list+1]=row
            end
        end
        table.sort(list,function(a,b)
            if a.quality~=b.quality then return a.quality>b.quality end
            if a.level~=b.level then return a.level>b.level end
            return a.id<b.id
        end)
        return list
    elseif M.tab=="souls" then
        local list={}
        for _,meta in ipairs(data.heroes) do
            local count=tonumber((state.souls or {})[tostring(meta.id)] or 0) or 0
            if count>0 then
                local row={}
                for k,v in pairs(meta) do row[k]=v end
                row.count=count
                list[#list+1]=row
            end
        end
        table.sort(list,function(a,b)
            if a.quality~=b.quality then return a.quality>b.quality end
            if a.count~=b.count then return a.count>b.count end
            return a.id<b.id
        end)
        return list
    elseif M.tab=="jp" then
        return data.essence
    end
    return data.spirits
end

local function showItem(entry)
    local body="品质："..entry.quality.." 星"
    if entry.category then body=body.." · "..entry.category.."界" end
    body=body.."\n数量："..itemCount(entry.id).."\n\n"..(entry.description or "暂无说明")
    if M.tab=="spirits" then
        body=body.."\n\n转化：1 个"..entry.name.."可化为同阵营 "..entry.quality..
              " 星神仙的 1 个魂魄。\n点击右侧「转化」选择神仙。"
    else
        body=body.."\n\n精魄可在包裹中装配给神仙，提供对应被动属性。"
    end
    M.modal={title=entry.name,body=body}
    ui.render()
end

local function openExchange(entry)
    if itemCount(entry.id)<=0 then
        M.modal={title=entry.name,body="五法界魂数量不足。\n\n重复召唤或其他玩法获得界魂后即可转化。"}
        ui.render()
        return
    end
    M.exchange={item=entry}
    M.gesture=nil
    ui.render()
end

local function drawRow(row,index,y,parent)
    image("v2/packageUI/xinxilan.png",RX0+RW/2,y-2,RW,100,parent)
    local count,dim=0,false
    if M.tab=="heroes" then
        count=row.level
    elseif M.tab=="souls" then
        count=row.count
    else
        count=itemCount(row.id); dim=count<=0
    end
    icon(row,RX0+54,y,92,parent,dim)
    label(row.name,RX0+104,y+23,21,GOLD,parent)
    stars(row.quality,RX0+252,y+24,parent)
    local bottom
    if M.tab=="heroes" then
        bottom="等级 "..tostring(row.level)..(row.active and " · 出战中" or "")
    elseif M.tab=="souls" then
        bottom="数量: "..count
    elseif M.tab=="jp" then
        bottom="数量: "..count
        local level=itemLevel(row.id)
        if level>0 then bottom=bottom.." · 等级 "..level end
    else
        bottom="数量: "..count
    end
    label(bottom,RX0+104,y-24,19,ORANGE,parent)
    local bx,by,bw,bh=RX0+RW-170,y-43,150,38
    if M.tab=="heroes" then
        local maxed=row.level>=20
        local afford=(state.silver or 0)>=(row.upgrade_cost or 0)
        rowButton(maxed and "已满级" or "培养",bx,by,bw,bh,not maxed and afford,parent)
    elseif M.tab=="souls" then
        if own(row.id) then rowButton("已拥有",bx,by,bw,bh,false,parent)
        elseif count>=row.soul_need then rowButton("幻魂 "..row.soul_need,bx,by,bw,bh,true,parent)
        else rowButton("需 "..row.soul_need.." 魂魄",bx,by,bw,bh,false,parent) end
    elseif M.tab=="jp" then
        rowButton("详情",bx,by,bw,bh,true,parent)
    else
        rowButton(count>0 and "转化" or "无界魂",bx,by,bw,bh,count>0,parent)
    end
end

local function rowTap(entry,x,y,offset,index)
    local rowY=GY+offset+FIRST_Y-(index-1)*STEP_Y
    local bx=GX+RX0+RW-170
    local onButton=x>=bx and x<=bx+150 and y>=rowY-43 and y<=rowY-5
    if M.tab=="heroes" then
        if onButton and entry.level<20 and (state.silver or 0)>=(entry.upgrade_cost or 0) then
            M.gesture=nil; ui.send("upgrade",{hero=entry.id})
        else
            M.selected=entry; heroDetail.reset(); M.gesture=nil; ui.render()
        end
    elseif M.tab=="souls" then
        if onButton and not own(entry.id) and entry.count>=entry.soul_need then
            M.gesture=nil; ui.send("cortege_compose",{hero=entry.id})
        elseif onButton and not own(entry.id) then
            M.modal={title=entry.name,body="魂魄不足：需要 "..entry.soul_need..
                     " 个，当前 "..entry.count.." 个。\n\n重复召唤该神仙可获得魂魄。"}
            ui.render()
        else
            M.selected=entry; heroDetail.reset(); M.gesture=nil; ui.render()
        end
    elseif M.tab=="jp" then
        showItem(entry)
    elseif onButton then
        openExchange(entry)
    else
        showItem(entry)
    end
end

local function drawList()
    local list=rowList()
    local contentHeight=GH+math.max(0,#list-3)*STEP_Y
    local container=scrollArea(GX,GY,GW,GH,M.tab,contentHeight,function(x,y,offset)
        local row=math.floor((FIRST_Y-(y-GY-offset)+STEP_Y/2)/STEP_Y)
        local entry=list[row+1]
        if entry then rowTap(entry,x,y,offset,row+1) end
    end)
    for i,entry in ipairs(list) do
        drawRow(entry,i,FIRST_Y-(i-1)*STEP_Y,container)
    end
    if #list==0 then
        local empty="暂无神仙魂魄，重复召唤可获得"
        if M.tab=="heroes" then empty="尚未拥有神仙，可前往召唤"
        elseif M.tab=="spirits" then empty="暂无五法界魂"
        elseif M.tab=="jp" then empty="暂无精魄"
        end
        label(empty,590,300,22,MUTED,nil,true)
    end
    local summary
    if M.tab=="heroes" then summary=string.format("已拥有 %d / %d",#state.heroes,#data.heroes)
    elseif M.tab=="souls" then summary="共 "..#list.." 种魂魄"
    elseif M.tab=="jp" then summary="共 "..#list.." 项精魄"
    else summary="共 "..#list.." 种界魂" end
    label(summary,115.2,152,15,GOLD,nil,true)
    label("上下滑动查看更多",115.2,128,12,MUTED,nil,true)
end

local function drawModal()
    fill(0,0,960,540,{0,0,0,180})
    image("v2/charPositionUI/max_bkg.png",480,300,660,380)
    image("v2/introUI/small_label.png",480,452,560,54)
    label(M.modal.title,480,452,24,GOLD,nil,true)
    local body=CCLabelTTF:create(M.modal.body,"Arial",18,CCSizeMake(620,0),kCCTextAlignmentLeft)
    body:setAnchorPoint(CCPointMake(0,1))
    body:setPosition(CCPointMake(170,410))
    body:setColor(ccc3(unpack(PALE)))
    root:addChild(body)
    label("点击任意处关闭",480,132,14,MUTED,nil,true)
end

local function candidates(item)
    local list={}
    for _,meta in ipairs(data.heroes) do
        if meta.quality==item.quality and meta.category==item.category then
            list[#list+1]=meta
        end
    end
    table.sort(list,function(a,b) return a.id<b.id end)
    return list
end

local function drawExchange()
    local item=M.exchange.item
    local list=candidates(item)
    fill(0,0,960,540,{0,0,0,185})
    image("v2/charPositionUI/max_bkg.png",480,300,700,410)
    image("v2/introUI/small_label.png",480,452,580,54)
    label("转化 · "..item.name,480,452,23,GOLD,nil,true)
    label("同阵营 "..item.quality.." 星神仙 · 1 界魂转化 1 魂魄",480,424,15,MUTED,nil,true)
    local close=image("v2/introUI/close1.png",790,452,48,46)
    ui.hit(766,429,48,46,function() M.exchange=nil; M.gesture=nil; ui.render() end,true,close)
    local areaY,areaH=150,240
    local contentHeight=areaH+math.max(0,#list-5)*46
    local container=scrollArea(160,areaY,640,areaH,"exchange-"..item.id,contentHeight,
        function(x,y,offset)
            if x<660 or x>760 then return end
            local row=math.floor((areaH-24-(y-areaY-offset)+23)/46)
            local meta=list[row+1]
            if meta then
                M.exchange=nil; M.gesture=nil
                ui.send("cortege_convert",{item=item.id,hero=meta.id})
            end
        end)
    for i,meta in ipairs(list) do
        local y=areaH-24-(i-1)*46
        image("v2/packageUI/xinxilan.png",320,y-2,620,40,container)
        icon(meta,30,y,38,container,false)
        label(meta.name,54,y,18,GOLD,container)
        local have=tonumber((state.souls or {})[tostring(meta.id)] or 0) or 0
        label("魂魄 "..have.."/"..meta.soul_need,260,y,15,MUTED,container)
        rowButton("转化",500,y-16,100,32,true,container)
    end
    if #list==0 then label("没有同阵营神仙",480,270,18,MUTED,nil,true) end
end

function M.draw(context,player)
    ui,state,root=context,player,context.root
    M.scroll=nil
    if M.selected then
        local entry=M.selected
        heroDetail.draw({
            root=root,ui=ui,state=state,entry=entry,hero=own(entry.id),spells=data.spells,
            onClose=function() M.back() end,
            onBack=function() M.back() end,
            onTrain=function() ui.send("upgrade",{hero=entry.id}) end,
            onInherit=function()
                heroDetail.showInfo("传承",
                    "本地版暂未开放跨角色传承；当前等级、仙缘与属性不会被扣除。")
            end,
        })
        return
    end
    frame()
    tabs()
    drawList()
    local message=ui.notice
    if message and message~="" and message~="已连接本地服务 · 进度已保存" then
        label(message,604.8,486,15,MUTED,nil,true)
    end
    if M.modal then drawModal() end
    if M.exchange then drawExchange() end
end

function M.open()
    M.tab="heroes"; M.selected=nil; M.modal=nil; M.exchange=nil; M.gesture=nil
    heroDetail.reset()
end

function M.back()
    if M.selected and heroDetail.closeInfo() then ui.render(); return end
    if M.modal then
        M.modal=nil; ui.render()
    elseif M.exchange then
        M.exchange=nil; M.gesture=nil; ui.render()
    elseif M.selected then
        M.selected=nil; heroDetail.reset(); ui.render()
    else
        ui.navigate("home")
    end
end

function M.touch(event,x,y)
    if M.selected then return heroDetail.touch(event,x,y) end
    if M.modal then
        if event==CCTOUCHENDED or event=="ended" then
            M.modal=nil; ui.render()
        end
        return true
    end
    local s=M.scroll
    if not s then return false end
    if event==CCTOUCHBEGAN or event=="began" then
        if x>=s.x and x<=s.x+s.w and y>=s.y and y<=s.y+s.h then
            M.gesture={x=x,y=y,offset=s.offset,dragged=false}
            return true
        end
    elseif M.gesture then
        local g=M.gesture
        if event==CCTOUCHMOVED or event=="moved" then
            if math.abs(y-g.y)>7 or math.abs(x-g.x)>7 then g.dragged=true end
            if g.dragged then setOffset(g.offset+y-g.y) end
        elseif event==CCTOUCHENDED or event=="ended" then
            M.gesture=nil
            if not g.dragged and math.abs(y-g.y)<8 and math.abs(x-g.x)<8
               and x>=s.x and x<=s.x+s.w and y>=s.y and y<=s.y+s.h and s.onTap then
                s.onTap(x,y,s.offset)
            end
        else
            M.gesture=nil
        end
        return true
    end
    return false
end

return M


