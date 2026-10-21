-- Original mapUI/subLevelUI geometry and artwork, 960 x 540 logical canvas.
local data=require("local_journey_data")
local M={offset=0,chapter=nil,selected=1,cardOffset=0,directory=false,directoryPage=1}
local ui,state,root,world,cards,gesture
local GOLD={245,190,83}
local INK={92,60,45}
local CREAM={239,211,156}
local RED={188,106,81}
local mapWidth=9000

local function image(file,x,y,w,h,parent)
    local n=CCSprite:create(file)
    if not n then return end
    local s=n:getContentSize()
    n:setScaleX(w/s.width); n:setScaleY((h or w*s.height/s.width)/s.height)
    n:setPosition(CCPointMake(x,y)); local target=parent or root; target:addChild(n)
    return n
end
local function text(value,x,y,size,color,parent,center,width)
    local n
    if width then n=CCLabelTTF:create(tostring(value),"Arial",size,CCSizeMake(width,0),kCCTextAlignmentLeft)
    else n=CCLabelTTF:create(tostring(value),"Arial",size) end
    n:setAnchorPoint(CCPointMake(center and .5 or 0,width and 1 or .5))
    n:setPosition(CCPointMake(x,y)); n:setColor(ccc3(unpack(color or CREAM)))
    local target=parent or root; target:addChild(n); return n
end
local function fill(x,y,w,h,color,parent)
    local n=CCLayerColor:create(ccc4(unpack(color)))
    n:setContentSize(CCSizeMake(w,h)); n:setPosition(CCPointMake(x,y))
    local target=parent or root; target:addChild(n); return n
end
local function button(title,x,y,w,h,action,enabled,retry)
    if enabled==nil then enabled=true end
    local n=image("v2/soulExchangeUI/btn_bkg1.png",x+w/2,y+h/2,w,h)
    if not enabled then n:setColor(ccc3(105,105,105)) end
    text(title,x+w/2,y+h/2,16,enabled and CREAM or {155,140,122},nil,true)
    ui.hit(x,y,w,h,action,enabled,n,retry)
end
local function localStage(id)
    for _,s in ipairs(state.stages) do if s.original_id==id then return s end end
end
local function currentChapter()
    local s=state.stages[math.min(state.unlocked,#state.stages)]
    return s and math.floor(s.original_id/100) or 1
end
local function centerMap(id)
    local c=data.chapters[id]
    if c and c.x then M.offset=math.max(0,math.min(mapWidth-960,c.x*1200-480)) end
end
function M.open()
    M.chapter=nil; M.popup=nil; M.directory=false
    if state then centerMap(currentChapter()) end
end
local function openChapter(id)
    M.chapter=id; M.directory=false; M.popup=nil; M.selected=1
    local c=data.chapters[id]
    for i,s in ipairs(c.stages) do
        local l=localStage(s.id)
        if l and l.unlocked then M.selected=i end
    end
    M.cardOffset=math.max(0,math.min(math.max(0,#c.stages*250-900), (M.selected-1)*250-500))
    centerMap(id); ui.render()
end
function M.back()
    gesture=nil
    if M.popup then M.popup=nil
    elseif M.directory then M.directory=false
    elseif M.chapter then M.chapter=nil
    else ui.navigate("home"); return end
    ui.render()
end
local function board()
    fill(24,86,912,432,{58,35,27,255})
    image("v2/subLevelUI/head_mid_bkg.png",480,190,912,206)
    image("v2/packageUI/board_edge1.png",24,302,15,432)
    image("v2/packageUI/board_edge1.png",936,302,15,432):setFlipY(true)
    image("v2/packageUI/board_edge2.png",480,514,930,37)
    image("v2/packageUI/board_edge2.png",480,90,930,37):setFlipY(true)
end
local function close()
    local n=image("v2/introUI/close1.png",930,512,60,57)
    ui.hit(899,483,61,57,M.back,true,n)
end
local function map()
    world=CCNode:create(); root:addChild(world); world:setPositionX(-M.offset)
    local terrain=CCNode:create(); world:addChild(terrain,-1)
    -- Twelve seamless paintings. Loading only nearby tiles avoids oversized textures.
    M.tiles={}
    M.loadTiles=function()
        local first=math.max(1,math.floor(M.offset/750))
        local last=math.min(12,math.ceil((M.offset+960)/750)+1)
        for i=first,last do
            if not M.tiles[i] then
                local tile=image("map/"..i..".jpg",(i-.5)*750,270,750,540,terrain)
                M.tiles[i]=tile
            end
        end
    end
    M.loadTiles()
    for _,c in ipairs(data.chapters) do
        if c.x then
            local finished=true
            for _,s in ipairs(c.stages) do
                local ls=localStage(s.id)
                if not ls or not ls.cleared then finished=false; break end
            end
            local kind=finished and 1 or (c.id==currentChapter() and 2 or 3)
            local x,y=c.x*1200,c.y*540-49
            image("map/mingzidi"..kind..".png",x,y,182.4,42.8,world)
            text(c.name,x,y,19,INK,world,true)
            text(c.id,x-67,y,16,{255,255,240},world,true)
        end
    end
    local c=data.chapters[currentChapter()]
    if c and c.x then
        local cache=CCSpriteFrameCache:sharedSpriteFrameCache()
        cache:addSpriteFramesWithFile("150_1/150_1.plist")
        local n=CCSprite:createWithSpriteFrameName("150_10001.png")
        if n then
            n:setScale(.65); n:setPosition(CCPointMake(c.x*1200,c.y*540+24)); world:addChild(n)
        end
    end
end
local function header()
    image("v2/character_frame.png",480,510,804,60.75)
    text(state.name,465,526,15,nil,nil,true)
    image("v2/vip/vip_label.png",575,526,42)
    text("0",608,526,18,GOLD,nil,true)
    image("v2/Stamina2.png",123,516,20); text(state.energy.."/60",140,516,16)
    image("v2/Energy2.png",222,516,20); text("—",239,516,16)
    image("v2/money_gold.png",681,516,29); text("0",699,516,16)
    image("v2/money_silver.png",778,516,26); text(state.silver,795,516,16)
    local exp=CCSprite:create("v2/exp_bar2.png")
    local size=exp:getContentSize()
    exp:setTextureRect(CCRectMake(0,0,size.width*(state.experience%200)/200,size.height))
    exp:setScaleX(240/size.width); exp:setScaleY(10/size.height)
    exp:setAnchorPoint(CCPointMake(0,.5)); exp:setPosition(CCPointMake(360,500)); root:addChild(exp)
    text("Lv."..state.level.."     "..(state.experience%200).."/200",480,501,13,nil,nil,true)
end
local function reward(entry,x,y)
    local colors={{115,110,99},{84,158,58},{40,134,220},{205,153,35},{178,69,196}}
    local color=colors[math.min(5,entry.quality or 1)]
    fill(x-36,y-36,72,72,{color[1],color[2],color[3],255})
    fill(x-33,y-33,66,66,{18,15,13,255})
    if entry.icon then
        local a=entry.icon
        local n=CCSprite:create(a.file); local size=n:getContentSize()
        local w,h=size.width,size.height
        if a.index then
            w=w/a.columns; h=h/a.rows
            n:setTextureRect(CCRectMake((a.index-1)%a.columns*w,math.floor((a.index-1)/a.columns)*h,w,h))
        end
        n:setScale(64/w); n:setPosition(CCPointMake(x,y)); root:addChild(n)
    end
    if entry.fragment then image("map/parts.png",x,y,64,64) end
    if entry.icon_level then text("+"..entry.icon_level,x+27,y+25,14,GOLD,nil,true) end
    local name=text(entry.name..(entry.count>1 and (" ×"..entry.count) or ""),
                    x,y-49,19,{255,245,218},nil,true)
    if name:getContentSize().width>108 then name:setScale(108/name:getContentSize().width) end
    ui.hit(x-40,y-65,80,105,function() M.popup={reward=entry}; ui.render() end,true)
end
local function detail()
    local c=data.chapters[M.chapter]; local s=c.stages[M.selected]
    board()
    -- The upper half previews the selected encounter's original battle painting.
    local content=CCNode:create()
    local clip=CCScrollView:create(CCSizeMake(894*root:getScaleX(),218*root:getScaleY()),content)
    clip:setTouchEnabled(false); clip:setPosition(CCPointMake(33,292)); root:addChild(clip)
    image(s.background,447,109,894,350,content)
    fill(0,0,894,218,{22,16,14,146},content)
    image("v2/subLevelUI/map_mask.png",480,299,894,27)
    local lines={
        "关卡:  "..s.name, "体力消耗:  "..s.energy, "限制等级:  "..s.require_level,
        "神仙经验:  "..s.exp, "奖励银两:  "..s.silver, "每日挑战上限:  "..s.daily_limit,
    }
    for i,v in ipairs(lines) do text(v,47,474-(i-1)*32,19,RED) end
    text("有几率获得:",344,447,25,GOLD,nil,true)
    text("三星奖励:",576,447,25,GOLD,nil,true)
    for i,p in ipairs(s.drops) do reward(p,287+(i-1)*113,368) end
    if #s.drops==0 then text("无",344,370,20,CREAM,nil,true) end
    for i,p in ipairs(s.three_star) do reward(p,576+(i-1)*90,368) end
    if #s.three_star==0 then text("无",576,370,20,CREAM,nil,true) end
    if s.sprite then
        local n=CCSprite:create(s.sprite); local size=n:getContentSize()
        n:setScale(math.min(218/size.width,180/size.height))
        n:setFlipX(true); n:setPosition(CCPointMake(792,409)); root:addChild(n)
    end
    cards=CCNode:create()
    local view=CCScrollView:create(CCSizeMake(900*root:getScaleX(),211*root:getScaleY()),cards)
    view:setTouchEnabled(false); view:setPosition(CCPointMake(30,100)); root:addChild(view)
    M.cardMax=math.max(0,#c.stages*250-900)
    M.cardOffset=math.max(0,math.min(M.cardMax,M.cardOffset))
    cards:setPositionX(-M.cardOffset)
    for i,stage in ipairs(c.stages) do
        local x=125+(i-1)*250
        local file=stage.boss==2 and "BOSS_bkg" or stage.boss==1 and "BOSS_bkg2" or "char_bkg"
        local w=stage.boss>0 and 240 or 178
        image("v2/subLevelUI/"..file..".png",x,117,w,nil,cards)
        if stage.sprite then
            local n=CCSprite:create(stage.sprite); local size=n:getContentSize()
            -- Same source crop as createSubLevel(): torso/head, original offset metadata.
            local cw,ch=213.3,156.8
            n:setTextureRect(CCRectMake(stage.offset_x*size.width-106.65,
                                       stage.offset_y*size.height-78.4,cw,ch))
            n:setScale(.75); n:setPosition(CCPointMake(x,111)); cards:addChild(n)
        end
        image("v2/subLevelUI/nameBkg.png",x,24,178,29,cards)
        text(stage.name,x,24,20,CREAM,cards,true)
        local ls=localStage(stage.id)
        if ls and ls.cleared then text("已通关",x,67,16,GOLD,cards,true) end
        if i==M.selected then
            local bw=stage.boss>0 and 182 or 178
            fill(x-bw/2,43,bw,3,{255,216,103,255},cards)
            fill(x-bw/2,187,bw,3,{255,216,103,255},cards)
            fill(x-bw/2,43,3,147,{255,216,103,255},cards)
            fill(x+bw/2-3,43,3,147,{255,216,103,255},cards)
            if ls and ls.unlocked then
                image("v2/subLevelUI/start_fight1.png",x,66,138,40,cards)
            else
                text(ls and "尚未解锁" or "关卡预览",x,66,16,CREAM,cards,true)
            end
        end
    end
    header()
    text("原版关卡资料",39,94,12,{215,180,126})
    text(c.id.." · "..c.name.."   "..M.selected.."/"..#c.stages,477,94,12,CREAM,nil,true)
    button("‹",864,91,28,22,function()
        M.selected=math.max(1,M.selected-1); M.cardOffset=math.max(0,(M.selected-1)*250-500); ui.render()
    end,M.selected>1)
    button("›",898,91,28,22,function()
        M.selected=math.min(#c.stages,M.selected+1); M.cardOffset=math.min(M.cardMax,(M.selected-1)*250); ui.render()
    end,M.selected<#c.stages)
end
local function directory()
    board(); text("取经旅途 · 关卡目录",480,478,28,GOLD,nil,true)
    local start=(M.directoryPage-1)*20
    for j=1,20 do
        local c=data.chapters[start+j]
        if c then
            local x=49+((j-1)%4)*222; local y=394-math.floor((j-1)/4)*55
            button(string.format("%02d  %s",c.id,c.name),x,y,207,43,function() openChapter(c.id) end)
        end
    end
    button("上一页",57,115,117,35,function() M.directoryPage=M.directoryPage-1; ui.render() end,M.directoryPage>1)
    text(M.directoryPage.." / 4",480,132,18,CREAM,nil,true)
    button("下一页",787,115,117,35,function() M.directoryPage=M.directoryPage+1; ui.render() end,M.directoryPage<4)
end
local function popup()
    fill(0,82,960,458,{0,0,0,160})
    fill(232,160,496,260,{139,92,46,255}); fill(235,163,490,254,{41,28,23,255})
    local p=M.popup
    if p.reward then
        text(p.reward.name,480,382,28,GOLD,nil,true)
        text(p.reward.description,263,345,20,CREAM,nil,false,434)
        text("数量 "..p.reward.count.." · 原版奖励预览",480,227,16,CREAM,nil,true)
        button("返回关卡",389,174,182,36,function() M.popup=nil; ui.render() end)
    else
        local s=p.stage
        text(s.name,480,382,27,GOLD,nil,true)
        text("本地挑战",480,339,22,CREAM,nil,true)
        text("消耗 2 体力 · 经验 "..s.exp,480,304,20,CREAM,nil,true)
        text("银两 "..s.silver.." · 首通翻倍",480,271,20,CREAM,nil,true)
        text("原版道具与三星奖励尚未接入结算",480,230,17,RED,nil,true)
        button("返回",265,174,170,36,function() M.popup=nil; ui.render() end)
        button("开战",525,174,170,36,function()
            M.popup=nil; ui.send("battle",{stage=s.id})
        end,state.energy>=2)
    end
end
function M.draw(context,player)
    ui,state,root=context,player,context.root; gesture=nil
    if not M.initialized then centerMap(currentChapter()); M.initialized=true end
    map()
    if M.directory then directory()
    elseif M.chapter then detail()
    else
        fill(0,483,310,57,{31,24,16,145})
        text("旅 途",28,514,30,GOLD)
        text("左右滑动 · 点选关卡",126,511,15,CREAM)
        button("‹",20,88,38,34,function() M.offset=math.max(0,M.offset-720); ui.render() end,M.offset>0)
        button("›",902,88,38,34,function() M.offset=math.min(mapWidth-960,M.offset+720); ui.render() end,M.offset<mapWidth-960)
        button("关卡目录",650,492,111,33,function() M.directory=true; ui.render() end)
        button("当前进度",774,492,111,33,function() centerMap(currentChapter()); ui.render() end)
    end
    close()
    if M.popup then popup() end
    if ui.error or ui.busy then
        fill(233,83,494,31,{33,23,19,245})
        text(ui.busy and "正在保存…" or ui.error,480,98,16,CREAM,nil,true)
    end
    if ui.failed then button("重试连接",389,84,182,34,function() ui.send("state",{}) end,true,true) end
end
function M.touch(event,x,y)
    if M.popup or M.directory then return false end
    local began=event==CCTOUCHBEGAN or event=="began"
    local moved=event==CCTOUCHMOVED or event=="moved"
    local ended=event==CCTOUCHENDED or event=="ended"
    local cancelled=event==CCTOUCHCANCELLED or event=="cancelled"
    if began then
        if M.chapter then
            if x<30 or x>930 or y<116 or y>304 then return false end
        elseif y<125 or y>482 then return false end
        gesture={x=x,y=y,offset=M.chapter and M.cardOffset or M.offset,drag=false}
        return true
    end
    if not gesture then return false end
    if moved then
        if math.abs(x-gesture.x)>8 or math.abs(y-gesture.y)>8 then gesture.drag=true end
        if M.chapter then
            M.cardOffset=math.max(0,math.min(M.cardMax,gesture.offset+gesture.x-x))
            cards:setPositionX(-M.cardOffset)
        else
            M.offset=math.max(0,math.min(mapWidth-960,gesture.offset+gesture.x-x))
            world:setPositionX(-M.offset); M.loadTiles()
        end
        return true
    end
    if ended or cancelled then
        local g=gesture; gesture=nil
        if ended and not g.drag and math.abs(x-g.x)<10 and math.abs(y-g.y)<10 then
            if M.chapter then
                local c=data.chapters[M.chapter]
                local i=math.floor((x-30+M.cardOffset)/250)+1
                if c.stages[i] then
                    local center=30+125+(i-1)*250-M.cardOffset
                    if i==M.selected and math.abs(x-center)<69 and y>=146 and y<=186 then
                        local ls=localStage(c.stages[i].id)
                        if ls and ls.unlocked then M.popup={stage=ls} end
                    else M.selected=i end
                    ui.render()
                end
            else
                for _,c in ipairs(data.chapters) do
                    if c.x and math.abs(x+M.offset-c.x*1200)<83
                        and y>=c.y*540-69 and y<=c.y*540+40 then
                        openChapter(c.id); break
                    end
                end
            end
        end
        return true
    end
    return true
end
return M
