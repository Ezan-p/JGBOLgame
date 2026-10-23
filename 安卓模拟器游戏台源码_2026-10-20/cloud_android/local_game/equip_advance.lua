-- ui.equipAdvanceUI: original 600x690 art on the 1280x720 design canvas.
local data=require('local_inventory_data')
local visuals=require('local_equip_visuals')
local M={}
local P='v2/equipAdvanceUI/'
local BROWN={187,86,42};local VALUE={155,155,23};local GRAY={200,200,200}
local GREEN={178,255,63};local RED={241,67,21}
local NUM={'零','一','二','三','四','五','六','七','八','九','十'}
local ui,state,root
local W,H=450,517.5
local function image(file,x,y,w,h,parent)
    local n=CCSprite:create(file);if not n then return end
    local s=n:getContentSize();w=w or s.width*.75;h=h or w*s.height/s.width
    n:setScaleX(w/s.width);n:setScaleY(h/s.height);n:setPosition(CCPointMake(x,y));local target=parent or root;target:addChild(n);return n
end
local function label(text,x,y,size,color,anchor,parent)
    local n=CCLabelTTF:create(tostring(text),'Arial',size or 19.5)
    n:setAnchorPoint(CCPointMake(anchor or .5,.5));n:setPosition(CCPointMake(x,y));n:setColor(ccc3(unpack(color or GRAY)))
    local target=parent or root;target:addChild(n);return n
end
local function fill(x,y,w,h,color,parent)
    local n=CCLayerColor:create(ccc4(unpack(color)));n:setContentSize(CCSizeMake(w,h));n:setPosition(CCPointMake(x,y));local target=parent or root;target:addChild(n);return n
end
local function icon(item,x,y,w,parent)
    local a=item.icon;local n=CCSprite:create(a.file);local s=n:getContentSize();local sw,sh=s.width,s.height
    if a.index then sw=sw/a.columns;sh=sh/a.rows;n:setTextureRect(CCRectMake((a.index-1)%a.columns*sw,math.floor((a.index-1)/a.columns)*sh,sw,sh)) end
    n:setScale(w/sw);n:setPosition(CCPointMake(x,y));local target=parent or root;target:addChild(n);return n
end
local function button(file,x,y,fn,enabled,w)
    local n=image(file,x,y,w);local s=n:getContentSize();local width=s.width*n:getScaleX();local height=s.height*n:getScaleY()
    if enabled==false then n:setColor(ccc3(110,110,110)) end
    ui.hit(x-width/2,y-height/2,width,height,fn,true,n);return n
end
local function entryOf(uid)
    for _,e in ipairs((state.inventory or {}).entries or {}) do if e.uid==uid then return e end end
end
local function message(text) M.message=text;ui.render() end
local function cropped(file,x,y,ratio,w,parent)
    if ratio<=0 then return end
    local n=CCSprite:create(file);local s=n:getContentSize();local scale=(w or s.width*.75)/s.width
    n:setTextureRect(CCRectMake(0,0,s.width*math.min(1,ratio),s.height));n:setScale(scale)
    n:setAnchorPoint(CCPointMake(0,.5));n:setPosition(CCPointMake(x,y));local target=parent or root;target:addChild(n)
end
local function choose()
    local list={}
    for _,e in ipairs(state.inventory.entries) do
        local item=data.items[e.key]
        if item.category<=3 and item.quality>=4 and e.uid~=M.uid then table.insert(list,e) end
    end
    table.sort(list,function(a,b)
        local x,y=data.items[a.key],data.items[b.key]
        if ((a.hero or 0)>0)~=((b.hero or 0)>0) then return (a.hero or 0)>0 end
        if x.quality~=y.quality then return x.quality>y.quality end
        if (a.advance_level or 0)~=(b.advance_level or 0) then return (a.advance_level or 0)>(b.advance_level or 0) end
        if a.level~=b.level then return a.level>b.level end
        if x.name~=y.name then return x.name>y.name end
        return a.uid<b.uid
    end)
    if #list==0 then message(M.uid and '无其他可进阶装备' or '无可进阶装备');return end
    M.chooser=list;M.offset=0;M.message=nil;ui.render()
end
function M.open(context,player,uid)
    ui,state,root=context,player,context.root;M.active=true;M.uid=uid;M.chooser=nil;M.message=nil;M.material=nil;M.progress=nil;M.pending=nil;M.animation=nil
end
function M.close() M.active=nil;M.uid=nil;M.chooser=nil;M.message=nil;M.material=nil;M.progress=nil;M.pending=nil;M.animation=nil;M.gesture=nil end
function M.isOpen() return M.active==true end
function M.back()
    if M.material then M.material=nil elseif M.message then M.message=nil elseif M.chooser then M.chooser=nil;M.gesture=nil else M.close() end
    ui.render()
end
function M.afterUpdate(player)
    state=player
    if not M.pending then return end
    local e=entryOf(M.uid);local a=e and e.advance
    if a then
        if a.rank==M.pending.rank and a.stars==M.pending.stars and a.spirit>M.pending.spirit then M.progress=M.pending.spirit/math.max(1,a.need) end
        if a.rank>M.pending.rank then M.animation='shengjie02.ccbi'
        elseif a.stars>M.pending.stars then M.animation='shengjie.ccbi' end
    end
    M.pending=nil
end
local function send(entry,op,one)
    local a=entry.advance
    if op=='bag_equip_pour' and a.own<a.pour_count then message('缺少'..data.items[a.material].name);return end
    if op=='bag_equip_advance' then
        for _,c in ipairs(a.costs) do if c.own<c.count then message('缺少'..data.items[c.key].name);return end end
    end
    M.message=nil;M.pending={rank=a.rank,stars=a.stars,spirit=a.spirit}
    ui.send(op,{uid=entry.uid,one_key=one or false})
end
local function drawChooser()
    fill(0,0,960,540,{0,0,0,180})
    image('v2/common/frame3.png',480,270,528,513)
    button('v2/introUI/close1.png',739.2,523.8,function() M.chooser=nil;ui.render() end)
    local total=math.max(486,#M.chooser*108)
    local c=CCLayer:create();c:setContentSize(CCSizeMake(480,total))
    local v=CCScrollView:create(CCSizeMake(480*root:getScaleX(),486*root:getScaleY()),c)
    v:setTouchEnabled(false);v:setPosition(CCPointMake(240,27));root:addChild(v)
    c:setPositionY(486-total+M.offset);M.scroll={node=c,max=total-486,total=total};M.pickHits={}
    for index,e in ipairs(M.chooser) do
        local item=data.items[e.key];local y=total-(index-.5)*108
        image('v2/charPositionUI/item_bkg.png',240,y,480,108,c)
        local itemIcon=icon(item,54,y,89,c);visuals.effect(itemIcon,e)
        local itemName=label(item.name,113,y+25,20,{254,235,192},0,c);visuals.nameMark(c,itemName,e,.75)
        label('等级 '..e.level..'    '..(NUM[(e.advance_level or 0)+1])..'阶',113,y-3,17,GRAY,0,c)
        local owner='未装备'
        for _,h in ipairs(state.heroes or {}) do if h.id==e.hero then owner=h.name;break end end
        label(owner,113,y-30,16,{186,169,157},0,c)
        image('v2/introUI/'..(M.uid and 'change1.png' or 'choose1.png'),408,y-27,96,nil,c)
        table.insert(M.pickHits,{uid=e.uid,y=27+486-total+M.offset+y-27})
    end
end
function M.draw(context,player)
    if not M.active then return end
    ui,state,root=context,player,context.root;ui.clearHits()
    ui.hit(0,0,960,540,function() end,true,nil)
    fill(0,0,960,540,{0,0,0,180})
    image(P..'bkg.png',480,270)
    local iconY,nameY=270+.295*H,270+.14*H
    image(P..'icon_bkg.png',480,iconY);image(P..'name_bkg.png',480,nameY)
    button('v2/introUI/close1.png',480+.44*W,270+.46*H,M.back)
    button('v2/stoneUI/unsee.png',480,iconY,choose,true,.3*W)
    local entry=M.uid and entryOf(M.uid);local item=entry and data.items[entry.key];local a=entry and entry.advance
    if M.uid and not a then M.uid=nil end
    if a then
        icon(item,480,iconY,.3*W)
        image('v2/newIntroUI/star_bkg.png',480,iconY-.4*.3*W,.8*.3*W)
        cropped('v2/introUI/stars.png',480-.4*.3*W,iconY-.4*.3*W,item.quality/5,.8*.3*W)
        label(item.name,480-.08*W,nameY,19.5,{216,167,48})
        label(NUM[a.rank+1]..'阶'..(a.full and '' or a.stars..'星'),480+.12*W,nameY,19.5,{177,177,177})
        local stat=({'攻击力','防御力','血量'})[item.category]
        if a.ready then
            image(P..'inner.png',480,270-.025*H)
            local xs={480-.2*W,480-.05*W,480+.075*W,480+.2*W}
            label(NUM[a.rank+1]..'阶',xs[2],270+.07*H)
            label(NUM[a.rank+2]..'阶',xs[4],270+.07*H,19.5,VALUE)
            local function compare(text,y,old,new)
                label(text..':',xs[1],y,19.5,BROWN,1);label(old,xs[2],y)
                image('v2/trainingUI/up.png',xs[3],y):setRotation(90);label(new,xs[4],y,19.5,VALUE)
            end
            compare(stat..'加成',270+.01*H,'+'..math.floor(a.effect.percent*100+.01)..'%','+'..math.floor(a.next_effect.percent*100+.01)..'%')
            compare('附加'..stat,270-.05*H,'+'..a.effect.plus,'+'..a.next_effect.plus)
            if a.next_effect.extra>0 then
                label('升阶激活:',xs[1],270-.11*H,19.5,{213,194,99},1)
                label('基础'..stat..' '..math.floor(a.next_effect.extra*100+.01)..'% ↑',xs[3],270-.11*H,19.5,GRAY)
            end
            label('消耗:',480-.35*W,270-.23*H,19.5,BROWN)
            local enough=true
            for i,c in ipairs(a.costs) do
                local x=480-.45*W+i*.3*W;local materialKey=c.key
                local n=icon(data.items[c.key],x,270-.23*H,.12*W)
                ui.hit(x-.06*W,270-.23*H-.06*W,.12*W,.12*W,function() M.material=materialKey;ui.render() end,true,n)
                label(data.items[c.key].name..'X'..c.count,x,270-.30*H,16.5,BROWN)
                label('(拥有 '..c.own..')',x,270-.33*H,16.5,c.own>=c.count and GREEN or RED)
                enough=enough and c.own>=c.count
            end
            button(P..'advance1.png',480,270-.41*H,function() send(entry,'bag_equip_advance') end,enough)
        else
            label(stat..'加成: ',480,270+.05*H,19.5,BROWN,1)
            label('+'..math.floor(a.effect.percent*entry.base_value+.0001)..'('..math.floor(a.effect.percent*100+.01)..'%)',480,270+.05*H,19.5,VALUE,0)
            label('附加'..stat..': ',480,270,19.5,BROWN,1);label('+'..a.effect.plus,480,270,19.5,VALUE,0)
            for i=1,7 do
                local x=480+.075*W*(i-4);local y=270-.07*H
                image(P..'star_emp.png',x,y)
                if a.full or i<=a.stars then image(P..'star_fill.png',x,y)
                elseif i==a.stars+1 and a.need>0 then cropped(P..'star_fill.png',x-16.875,y,a.spirit/a.need) end
            end
            label('注灵经验值',480,270-.14*H,19.5,BROWN)
            image(P..'exp_bkg.png',480,270-.18*H)
            if M.progress and not a.full then
                local n=CCSprite:create(P..'exp.png');n:setAnchorPoint(CCPointMake(0,.5));n:setPosition(CCPointMake(480-.3466666667*W,270-.18*H))
                n:setScaleY(.75);n:setScaleX(.75*M.progress);root:addChild(n)
                n:runAction(CCScaleTo:create(.5,.75*a.spirit/math.max(1,a.need),.75));M.progress=nil
            else cropped(P..'exp.png',480-.3466666667*W,270-.18*H,a.full and 1 or a.spirit/math.max(1,a.need)) end
            label(a.full and '0/0' or a.spirit..'/'..a.need,480,270-.18*H)
            label('提示: 装备注灵达到七星后即可升阶',480,270-.23*H,16.5,GREEN)
            image(P..'line.png',480,270-.27*H)
            if a.full then label('该装备已经是最高阶',480,270-.35*H)
            else
                label('消耗:',480-.2*W,270-.30*H,19.5,BROWN)
                icon(data.items[a.material],480-.1*W,270-.30*H,.05*W)
                label(data.items[a.material].name..'X'..a.pour_count..' (拥有 '..a.own..')',480+.15*W,270-.30*H,16.5,a.own>=a.pour_count and GREEN or RED)
                button(P..'exp1.png',480-.25*W,270-.4*H,function() send(entry,'bag_equip_pour',false) end,a.own>=a.pour_count)
                button(P..'aexp1.png',480+.25*W,270-.4*H,function() send(entry,'bag_equip_pour',true) end,a.own>=a.pour_count)
            end
        end
    else label('请先选择一件装备',480,nameY,19.5,{216,167,48}) end
    if M.animation then
        local file=M.animation;M.animation=nil
        local reader=CCBReader:new(CCNodeLoaderLibrary:newDefaultCCNodeLoaderLibrary())
        local node=reader:readNodeGraphFromFile(file,root,nil);reader:autorelease()
        if node then
            local s=node:getContentSize();local scale=file=='shengjie.ccbi' and .5 or 1
            node:setScale(scale*960/math.max(1,s.width));node:setPosition(CCPointMake(0,(file=='shengjie.ccbi' and 270-.07*H or iconY)-270));root:addChild(node,100)
            local seq=CCArray:create();seq:addObject(CCDelayTime:create(1.5));seq:addObject(CCCallFuncN:create(function() node:removeFromParentAndCleanup(true) end));node:runAction(CCSequence:create(seq))
        end
    end
    if M.chooser then ui.clearHits();ui.hit(0,0,960,540,function() end,true,nil);drawChooser() end
    if M.material then
        local material=data.items[M.material]
        ui.clearHits();ui.hit(0,0,960,540,function() M.material=nil;ui.render() end,true,nil)
        fill(0,0,960,540,{0,0,0,180});image('v2/messageUI/frame1.png',480,285,540,340)
        icon(material,480,365,80);label(material.name,480,310,22,{216,167,48})
        local n=CCLabelTTF:create(material.description or '', 'Arial',18,CCSizeMake(430,0),kCCTextAlignmentLeft)
        n:setPosition(CCPointMake(480,235));n:setColor(ccc3(unpack(GRAY)));root:addChild(n)
        button('v2/introUI/close1.png',720,435,function() M.material=nil;ui.render() end)
    end
    if M.message then
        fill(300,20,360,34,{0,0,0,225});label(M.message,480,37,18,{255,200,95})
    end
end
function M.touch(event,x,y)
    if M.material or not M.chooser then return false end
    local began=event==CCTOUCHBEGAN or event=='began';local moved=event==CCTOUCHMOVED or event=='moved';local ended=event==CCTOUCHENDED or event=='ended'
    if began then
        if x<240 or x>720 or y<27 or y>513 then return false end
        M.gesture={x=x,y=y,offset=M.offset};return true
    end
    local g=M.gesture;if not g then return false end
    if moved then
        if math.abs(y-g.y)>6 then g.moved=true end
        M.offset=math.max(0,math.min(M.scroll.max,g.offset+y-g.y));M.scroll.node:setPositionY(486-M.scroll.total+M.offset);return true
    end
    if ended then
        M.gesture=nil
        if not g.moved then
            for _,h in ipairs(M.pickHits or {}) do
                if x>=600 and x<=696 and math.abs(y-h.y)<=27 then M.uid=h.uid;M.chooser=nil;M.message=nil;break end
            end
        end
        ui.render();return true
    end
    M.gesture=nil;return true
end
return M
