-- Reconstructed from original handbookUI.lua / mainUI.createBoardBkg().
-- Canvas: 960 x 540. Six columns, original atlas portraits, clipped vertical scroll.
local data = require("local_handbook_data")
local M = {tab="heroes", ownedOnly=false, offsets={}}
local GOLD = {255,235,190}
local MUTED = {179,152,119}
local ui, state, root
local GX,GY,GW,GH = 249.6,97.2,662.4,356.4
local FIRST_X,FIRST_Y,STEP_X,STEP_Y = 48,299.7,110.4,118.8

local function image(file,x,y,w,h,parent)
    local node=CCSprite:create(file)
    if not node then return nil end
    local size=node:getContentSize()
    node:setScaleX(w/size.width)
    node:setScaleY((h or w*size.height/size.width)/size.height)
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

local function button(title,x,y,w,h,action,enabled)
    if enabled==nil then enabled=true end
    local node=image("v2/soulExchangeUI/btn_bkg1.png",x+w/2,y+h/2,w,h)
    if not enabled then node:setColor(ccc3(105,105,105)) end
    label(title,x+w/2,y+h/2,16,enabled and GOLD or MUTED,nil,true)
    ui.hit(x,y,w,h,action,enabled,node)
end

local function own(id)
    for _,hero in ipairs(state.heroes) do
        if hero.id==id then return hero end
    end
end

local function icon(entry,x,y,width,parent,dim)
    local info=entry.icon
    local node=CCSprite:create(info.file)
    local size=node:getContentSize()
    local w,h=size.width,size.height
    if info.index then
        w,h=w/info.columns,h/info.rows
        node:setTextureRect(CCRectMake((info.index-1)%info.columns*w,
                            math.floor((info.index-1)/info.columns)*h,w,h))
    end
    node:setScale(width/w)
    node:setPosition(CCPointMake(x,y))
    if dim then node:setColor(ccc3(128,128,128)) end
    parent:addChild(node)
    return node
end

local function frame()
    -- Original percentages: board center .5/.56, size .95/.8, divider .23.
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
    image("v2/introUI/small_label.png",604.8,486,576,64.8)
    local close=image("v2/introUI/close1.png",921.6,513,63,60)
    ui.hit(890,483,63,57,function() M.back() end,true,close)
end

local function tabs()
    local choices={
        {"heroes","v2/CharaterUI/shenxian"},
        {"equipment","v2/packageUI/equip"},
        {"spells","v2/packageUI/Label_spell"},
        {"essence","v2/handbook/btn7"},
    }
    for i,choice in ipairs(choices) do
        local target=choice[1]
        local y=475.2-(i-1)*64.8
        local node=image(choice[2]..(M.tab==target and "2" or "1")..".png",115.2,y,172.8)
        ui.hit(28.8,y-32,172.8,64,function()
            M.tab=target; M.selected=nil; M.gesture=nil; ui.render()
        end,true,node)
    end
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
    -- This old engine's GL scissor ignores ancestor scaling; compensate only its
    -- viewport size. Content and touch coordinates remain in our 960x540 canvas.
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

local function drawGrid()
    local list={}
    for _,entry in ipairs(data[M.tab]) do
        if M.tab~="heroes" or not M.ownedOnly or own(entry.id) then
            table.insert(list,entry)
        end
    end
    local titles={heroes="cortege",equipment="equip",spells="skill",essence="jp"}
    image("v2/handbook/"..titles[M.tab].."_txt.png",604.8,486,
          M.tab=="heroes" and 186 or 190,54)
    local key=M.tab..(M.tab=="heroes" and M.ownedOnly and "-owned" or "")
    local rows=math.ceil(#list/6)
    local contentHeight=GH+math.max(0,rows-3)*STEP_Y
    local container=scrollArea(GX,GY,GW,GH,key,contentHeight,function(x,y,offset)
        local col=math.floor((x-GX-FIRST_X+STEP_X/2)/STEP_X)
        local row=math.floor((FIRST_Y-(y-GY-offset)+STEP_Y/2)/STEP_Y)
        if col<0 or col>=6 or row<0 then return end
        local entry=list[row*6+col+1]
        if entry then
            M.selected=entry; M.lastSelected=M.tab..":"..entry.id; M.gesture=nil; ui.render()
        end
    end)
    for i,entry in ipairs(list) do
        local col=(i-1)%6
        local row=math.floor((i-1)/6)
        local x,y=FIRST_X+col*STEP_X,FIRST_Y-row*STEP_Y
        icon(entry,x,y,96,container,M.tab=="heroes" and not own(entry.id))
        image("v2/handbook/name_frame.png",x,y-54,115.2,25,container)
        label(entry.name,x,y-54,16,{255,255,224},container,true)
        if M.lastSelected==M.tab..":"..entry.id then
            image("v2/handbook/select.png",x,y,101,101,container)
        end
    end
    if #list==0 then label("尚未拥有神仙",590,300,23,MUTED,nil,true) end
    if M.tab=="heroes" then
        label("已拥有 "..#state.heroes.." / "..#data.heroes,115,217,16,GOLD,nil,true)
        button(M.ownedOnly and "查看全部神仙" or "我的神仙",35,162,160,39,function()
            M.ownedOnly=not M.ownedOnly; ui.render()
        end)
    else
        label("共 "..#list.." 项",115,217,16,GOLD,nil,true)
        label("图鉴资料",115,182,15,MUTED,nil,true)
    end
    -- Paging is also available for mouse-only users; drag scrolling stays continuous.
    button("上翻",35,117,74,32,function() setOffset(M.scroll.offset-3*STEP_Y) end)
    button("下翻",121,117,74,32,function() setOffset(M.scroll.offset+3*STEP_Y) end)
    label("上下滑动查看更多",115,101,12,MUTED,nil,true)
end

local function drawDetail()
    local entry=M.selected
    local hero=M.tab=="heroes" and own(entry.id) or nil
    label(entry.name,604.8,487,31,{35,18,8},nil,true)
    if M.tab=="heroes" then
        local node=CCSprite:create(entry.sprite)
        local size=node:getContentSize()
        node:setScale(math.min(232/size.width,240/size.height))
        node:setPosition(CCPointMake(364,311))
        root:addChild(node)
        label(entry.quality.."星 · "..entry.category,364,445,20,GOLD,nil,true)
        label(hero and ("Lv."..hero.level..(hero.active and " · 出战中" or " · 已拥有")) or "尚未招募",
              364,418,17,MUTED,nil,true)
        local stats=hero or entry
        label("生命 "..stats.hp.."   攻击 "..stats.attack,364,184,16,GOLD,nil,true)
        label("防御 "..stats.defense.."   基础法力 "..entry.magic,364,159,16,GOLD,nil,true)
    else
        icon(entry,364,335,150,root,false)
        label(entry.quality.."星",364,221,21,GOLD,nil,true)
        label("原版图鉴资料",364,183,16,MUTED,nil,true)
    end
    local body="【简介】\n"..(entry.description or "暂无介绍")
    if M.tab=="heroes" then
        body=body.."\n\n【原生技能 · "..entry.skill_name.."】\n"..entry.skill_description
        body=body.."\n\n【仙缘】"
        for _,fate in ipairs(entry.fates) do
            body=body.."\n"..fate.name.."："..fate.description
        end
        body=body.."\n\n仙缘按当前出战、助阵与装备激活，详情见阵容。"
    elseif entry.introduce and entry.introduce~=entry.description then
        body=body.."\n\n"..entry.introduce
    end
    local bodyLabel=CCLabelTTF:create(body,"Arial",17,CCSizeMake(395,0),kCCTextAlignmentLeft)
    local bodyHeight=bodyLabel:getContentSize().height
    local container=scrollArea(499,178,398,265,"detail-"..M.tab.."-"..entry.id,bodyHeight+12)
    bodyLabel:setAnchorPoint(CCPointMake(0,1))
    bodyLabel:setColor(ccc3(unpack(GOLD)))
    bodyLabel:setPosition(CCPointMake(0,265))
    container:addChild(bodyLabel)
    label("银两 "..state.silver,895,460,16,GOLD,nil,true)
    button("返回图鉴",35,163,160,39,function() M.selected=nil; ui.render() end)
    if M.tab=="heroes" then
        if hero then
            button(hero.level>=20 and "已达满级" or "培养 · "..hero.upgrade_cost,500,113,174,43,
                   function() ui.send("upgrade",{hero=entry.id}) end,
                   hero.level<20 and state.silver>=hero.upgrade_cost)
            button(hero.supporting and "助阵中" or hero.active and "休息" or "出战",696,113,174,43,
                   function() ui.send("lineup",{hero=entry.id}) end,
                   not hero.supporting and (hero.active and #state.lineup>1 or not hero.active and #state.lineup<4))
            label("最多四位神仙同时出战",695,94,14,MUTED,nil,true)
        else
            button("招募 · 600 银两",500,113,200,43,
                   function() ui.send("recruit",{hero=entry.id}) end,state.silver>=600)
            label(state.silver<600 and "银两不足，可在旅途获取" or "招募后可培养、加入阵容",
                  700,94,14,MUTED,nil,true)
        end
    else
        label("收集与装备功能尚未开放",695,137,17,MUTED,nil,true)
    end
    if ui.notice and ui.notice~="" then
        label(ui.notice,500,168,13,MUTED)
    end
    label("上下滑动查看详情",115,127,13,MUTED,nil,true)
end

function M.draw(context,player)
    ui,state,root=context,player,context.root
    M.scroll=nil
    frame()
    tabs()
    if M.selected then drawDetail() else drawGrid() end
end

function M.open()
    M.tab="heroes"; M.selected=nil; M.ownedOnly=false; M.gesture=nil
end

function M.back()
    M.gesture=nil
    if M.selected then M.selected=nil; ui.render()
    else ui.navigate("home") end
end

function M.touch(event,x,y)
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
