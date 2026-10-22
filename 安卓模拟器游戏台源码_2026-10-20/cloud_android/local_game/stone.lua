-- Original stoneUI: equipment sockets, drill/mosaic/takeout/upgrade and
-- equipment/stone pickers. Local canvas 960x540.
local data=require("local_inventory_data")
local upgrade=require("local_stone_upgrade")
local M={mode="main",hits={},equipScroll=0,stoneScroll=0}
local ui,state,root
local PALE={254,235,192}
local GOLD={216,167,48}
local MUTED={186,169,157}
local GREEN={186,219,66}
local function image(file,x,y,w,h,parent)
    local n=CCSprite:create(file)
    if not n then return end
    local s=n:getContentSize()
    n:setScaleX(w/s.width); n:setScaleY((h or w*s.height/s.width)/s.height)
    n:setPosition(CCPointMake(x,y)); (parent or root):addChild(n)
    return n
end
local function anchored(file,x,y,w,h,ax,ay,parent)
    local n=image(file,x,y,w,h,parent)
    if n then n:setAnchorPoint(CCPointMake(ax or .5,ay or .5)); n:setPosition(CCPointMake(x,y)) end
    return n
end
local function label(value,x,y,size,color,parent,center,width)
    local n
    if width then n=CCLabelTTF:create(tostring(value),"Arial",size,CCSizeMake(width,0),kCCTextAlignmentLeft)
    else n=CCLabelTTF:create(tostring(value),"Arial",size) end
    n:setAnchorPoint(CCPointMake(center and .5 or 0,width and 1 or .5))
    n:setPosition(CCPointMake(x,y)); n:setColor(ccc3(unpack(color or PALE)))
    local target=parent or root; target:addChild(n)
    return n
end
local function fill(x,y,w,h,color,parent)
    local n=CCLayerColor:create(ccc4(unpack(color)))
    n:setContentSize(CCSizeMake(w,h)); n:setPosition(CCPointMake(x,y)); (parent or root):addChild(n)
    return n
end
local function hit(x,y,w,h,action) table.insert(M.hits,{x=x,y=y,w=w,h=h,action=action}) end
local function entryOf(uid)
    for _,e in ipairs(state.inventory.entries) do if e.uid==uid then return e end end
end
local function itemOf(e) return e and data.items[e.key] end
local function stonesFor(uid)
    local e=entryOf(uid); return e and e.stones or {}
end
local function stoneAt(uid,pos)
    for _,s in ipairs(stonesFor(uid)) do if (s.pos or 0)==pos then return s end end
end
local function stoneBase(sub,level)
    local row=(data.stones or {})[tostring(sub)..":"..tostring(level)]
    return tonumber(row and row.base or 0) or 0
end
local function stoneItem(entry)
    return entry and data.items[entry.key]
end
local function atlas(info,x,y,w,parent)
    if not info then return end
    local n=CCSprite:create(info.file); local s=n:getContentSize()
    local cw,ch=s.width/info.columns,s.height/info.rows
    n:setTextureRect(CCRectMake((info.index-1)%info.columns*cw,math.floor((info.index-1)/info.columns)*ch,cw,ch))
    n:setScale(w/cw); n:setPosition(CCPointMake(x,y)); (parent or root):addChild(n)
    return n
end
local function stoneIcon(entry,x,y,w,parent)
    local info=stoneItem(entry) and stoneItem(entry).icon
    if not info then return end
    local n=CCSprite:create(info.file); local s=n:getContentSize()
    local cw,ch=s.width/info.columns,s.height/info.rows
    local idx=info.index+(tonumber(entry.level) or 1)-1
    n:setTextureRect(CCRectMake((idx-1)%info.columns*cw,math.floor((idx-1)/info.columns)*ch,cw,ch))
    n:setScale(w/cw); n:setPosition(CCPointMake(x,y)); (parent or root):addChild(n)
    local text="+"..(entry.level or 1)
    local shadow=CCLabelTTF:create(text,"Arial",26);shadow:setAnchorPoint(CCPointMake(1,1))
    shadow:setPosition(CCPointMake(cw*.9+1,ch*.9-1));shadow:setColor(ccc3(0,0,0));n:addChild(shadow,1)
    local front=CCLabelTTF:create(text,"Arial",26);front:setAnchorPoint(CCPointMake(1,1))
    front:setPosition(CCPointMake(cw*.9,ch*.9));front:setColor(ccc3(255,128,0));n:addChild(front,2)
end
local STAT={[1]="攻击",[2]="防御",[3]="生命"}
local function setOffset(kind,v)
    if kind=="equip" then M.equipScroll=math.max(0,math.min(M.equipMax or 0,v))
    else M.stoneScroll=math.max(0,math.min(M.stoneMax or 0,v)) end
end
function M.open(ctx,player,uid)
    ui,state,root=ctx,player,ctx.root
    M.uid=uid;M.mode="main";M.hits={};M.equipScroll=0;M.stoneScroll=0;M.stonePos=1
    upgrade.close()
    ui.render()
end
function M.close()
    upgrade.close();M.uid=nil;M.mode="main";M.hits={}
end
function M.isOpen() return M.uid~=nil end
local function drawEquipIcon(e,x,y,w,parent)
    local item=itemOf(e); if not item then return end
    local n=atlas(item.icon,x,y,w,parent)
    if n then
        local size=n:getContentSize()
        local empty=CCSprite:create("v2/newIntroUI/star_bkg.png")
        local es=empty:getContentSize()
        empty:setAnchorPoint(CCPointMake(0,0));empty:setPosition(CCPointMake(size.width*.1,size.height*.1))
        empty:setScale(.8*size.width/es.width);n:addChild(empty)
        local q=tonumber(item.quality) or 0
        if q>0 then
            local stars=CCSprite:create("v2/introUI/stars.png");local ss=stars:getContentSize()
            stars:setTextureRect(CCRectMake(0,0,ss.width*math.min(1,q/5),ss.height))
            stars:setAnchorPoint(CCPointMake(0,0));stars:setPosition(CCPointMake(size.width*.1,size.height*.1))
            stars:setScale(.8*size.width/ss.width);n:addChild(stars)
        end
    end
end
local function drawMain()
    local e=entryOf(M.uid); local item=itemOf(e)
    if not e or not item then M.close();return end
    fill(0,0,960,540,{0,0,0,180})
    local W,H=455,528
    local cx,cy=480,270
    image("v2/stoneUI/bkg.png",cx,cy,W,H)
    image("v2/introUI/close1.png",680.2,512.9,56,53)
    hit(650,484,62,58,function() M.close();ui.render() end)
    local iconY=cy+0.295*H
    drawEquipIcon(e,cx,iconY,0.3*W)
    hit(cx-0.15*W,iconY-0.15*W,0.3*W,0.3*W,function() M.mode="equip";M.equipScroll=0;M.hits={};ui.render() end)
    label(item.name,cx,cy+0.14*H,24,GOLD,nil,true)
    hit(cx-0.12*W,cy+0.14*H-18,0.24*W,36,function() M.mode="equip";M.equipScroll=0;M.hits={};ui.render() end)
    local maximum=tonumber(e.max_sockets) or 3
    local drill=tonumber(e.drill) or 0
    local base=tonumber(e.base_value) or 0
    for i=1,maximum do
        local x=cx-0.35*W
        local y=cy-0.18*(i-1)*H
        local stone=stoneAt(e.uid,i)
        local socketH=0.174*H
        local socketW=socketH*135/137
        image("v2/stoneUI/unsee.png",x,y,socketW,socketH)
        if stone then
            stoneIcon(stone,x,y,0.185*H)
            local pct=stoneBase(item.sub_type,stone.level)
            local add=math.floor(base*pct)
            label(string.format("%s +%d(%.1f%%)",STAT[item.sub_type],add,pct*100),
                cx-0.13*W,cy+0.08*H-0.18*(i-1)*H,18,GREEN,nil,false,200)
            image("v2/stoneUI/takeout1.png",cx,cy-0.02*H-0.18*(i-1)*H,120,67)
            hit(cx-50,cy-0.02*H-0.18*(i-1)*H-20,100,40,function()
                ui.send("bag_unsocket",{uid=e.uid,pos=i})
            end)
            image("v2/stoneUI/stone_upgrade1.png",cx+0.325*W,cy-0.02*H-0.18*(i-1)*H,120,67)
            hit(cx+0.325*W-50,cy-0.02*H-0.18*(i-1)*H-20,100,40,function()
                upgrade.open(ui,state,stone.uid)
            end)
        elseif i<=drill then
            image("v2/stoneUI/stone_choose1.png",cx+0.325*W,cy-0.02*H-0.18*(i-1)*H,120,67)
            hit(cx+0.325*W-50,cy-0.02*H-0.18*(i-1)*H-20,100,40,function()
                M.stonePos=i;M.mode="stone";M.stoneScroll=0;M.hits={};ui.render()
            end)
        elseif i==drill+1 then
            image("v2/stoneUI/lock.png",x,y,socketW,socketW*110/131)
            image("v2/stoneUI/slot1.png",cx,cy-0.02*H-0.18*(i-1)*H,120,67)
            hit(cx-50,cy-0.02*H-0.18*(i-1)*H-20,100,40,function()
                ui.send("bag_drill",{uid=e.uid})
            end)
            image("v2/stoneUI/stone_choose1.png",cx+0.325*W,cy-0.02*H-0.18*(i-1)*H,120,67):setColor(ccc3(110,110,110))
        else
            image("v2/stoneUI/lock.png",x,y,socketW,socketW*110/131)
            image("v2/stoneUI/slot1.png",cx,cy-0.02*H-0.18*(i-1)*H,120,67):setColor(ccc3(110,110,110))
            image("v2/stoneUI/stone_choose1.png",cx+0.325*W,cy-0.02*H-0.18*(i-1)*H,120,67):setColor(ccc3(110,110,110))
        end
    end
end


local function drawEquipPicker()
    fill(0,0,960,540,{0,0,0,170})
    image("v2/common/frame3.png",480,270,518,513)
    image("v2/introUI/close1.png",744,497,52,49)
    hit(716,472,56,50,function() M.mode="main";M.hits={};ui.render() end)
    local list={}
    for _,e in ipairs(state.inventory.entries) do
        local item=data.items[e.key]
        if item.category<=3 and e.uid~=M.uid then table.insert(list,{entry=e,item=item}) end
    end
    table.sort(list,function(a,b)
        if (a.item.quality or 0)~=(b.item.quality or 0) then return (a.item.quality or 0)>(b.item.quality or 0) end
        return a.item.id<b.item.id
    end)
    local rowH=108;local top,bottom=420,55
    M.equipMax=math.max(0,#list*rowH-(top-bottom))
    local startY=top+M.equipScroll
    for i,row in ipairs(list) do
        local y=startY-(i-1)*rowH
        if y>=bottom-20 and y<=top+20 then
            image("v2/charPositionUI/item_bkg.png",480,y,500,94)
            drawEquipIcon(row.entry,300,y,68)
            label(row.item.name,350,y+20,20,PALE)
            local q=tonumber(row.item.quality) or 0
            local stars=CCSprite:create("v2/introUI/stars.png")
            local ss=stars:getContentSize()
            stars:setTextureRect(CCRectMake(0,0,ss.width*math.min(1,q/5),ss.height))
            stars:setScale(.7);stars:setAnchorPoint(CCPointMake(0,.5));stars:setPosition(CCPointMake(350,y-6));root:addChild(stars)
            image("v2/introUI/level.png",350,y-30,22,22)
            label(tostring(row.entry.level or 1),372,y-30,17,PALE)
            if row.entry.hero and row.entry.hero~=0 then
                local hn=row.entry.hero
                for _,h in ipairs(state.heroes) do if h.id==row.entry.hero then hn=h.name;break end end
                label("装备于"..tostring(hn),560,y-30,15,MUTED)
            end
            image("v2/soulExchangeUI/btn_bkg1.png",660,y,104,38)
            label("更换",660,y,17,PALE,nil,true)
            hit(240,y-47,480,94,function()
                M.uid=row.entry.uid;M.mode="main";M.hits={};ui.render()
            end)
        end
    end
    if #list==0 then label("没有其他装备",480,270,20,MUTED,nil,true) end
end
local function expectedStoneKey(item) return "i"..tostring(1089+item.category) end
local function drawStonePicker()
    local e=entryOf(M.uid);local item=itemOf(e)
    if not e or not item then M.close();return end
    fill(0,0,960,540,{0,0,0,170})
    image("v2/common/frame3.png",480,270,518,513)
    image("v2/introUI/close1.png",744,497,52,49)
    hit(716,472,56,50,function() M.mode="main";M.hits={};ui.render() end)
    local key=expectedStoneKey(item)
    local list={}
    for _,s in ipairs(state.inventory.entries) do
        if s.key==key and (tonumber(s.owner_uid) or 0)==0 then table.insert(list,s) end
    end
    table.sort(list,function(a,b)
        if (a.level or 1)~=(b.level or 1) then return (a.level or 1)<(b.level or 1) end
        return a.uid<b.uid
    end)
    local rowH=108;local top,bottom=420,55
    M.stoneMax=math.max(0,#list*rowH-(top-bottom))
    local startY=top+M.stoneScroll
    for i,s in ipairs(list) do
        local y=startY-(i-1)*rowH
        if y>=bottom-20 and y<=top+20 then
            image("v2/charPositionUI/item_bkg.png",480,y,500,94)
            stoneIcon(s,300,y,72)
            local si=data.items[s.key]
            label(si.name,350,y+20,20,PALE)
            image("v2/introUI/level.png",350,y-22,22,22)
            label(tostring(s.level or 1),372,y-22,17,PALE)
            image("v2/packageUI/"..({[1]="CHAR_gong",[2]="CHAR_fang",[3]="CHAR_ming"})[item.sub_type]..".png",430,y-22,22,22)
            label(string.format("%.1f%%",stoneBase(item.sub_type,s.level)*100),452,y-22,17,PALE)
            image("v2/soulExchangeUI/btn_bkg1.png",660,y,104,38)
            label("镶嵌",660,y,17,PALE,nil,true)
            hit(240,y-47,480,94,function()
                M.mode="main";M.hits={};ui.send("bag_socket",{uid=e.uid,gem=s.uid,pos=M.stonePos or 1})
            end)
        end
    end
    if #list==0 then label("没有可用的"..item.name.."类灵石",480,270,20,MUTED,nil,true) end
end
function M.draw(ctx,player)
    if not M.uid then return end
    ui,state,root=ctx,player,ctx.root;M.hits={}
    if M.mode=="equip" then drawEquipPicker()
    elseif M.mode=="stone" then drawStonePicker()
    else drawMain() end
    if upgrade.isOpen() then upgrade.draw(ctx,state) end
end
local function endTouch(x,y)
    for i=#M.hits,1,-1 do
        local h=M.hits[i]
        if x>=h.x and x<=h.x+h.w and y>=h.y and y<=h.y+h.h then h.action();return true end
    end
end
function M.touch(event,x,y)
    if not M.uid then return false end
    if upgrade.isOpen() then return upgrade.touch(event,x,y) end
    if event==CCTOUCHBEGAN or event=="began" then
        M.press={x=x,y=y}
        return true
    elseif event==CCTOUCHMOVED or event=="moved" then
        if M.press and (math.abs(y-M.press.y)>6 or math.abs(x-M.press.x)>6) then
            local delta=y-M.press.y
            if M.mode=="equip" and x>=220 and x<=740 and y>=55 and y<=420 then
                M.press.y=y;setOffset("equip",M.equipScroll+delta);ui.render();return true
            elseif M.mode=="stone" and x>=220 and x<=740 and y>=55 and y<=420 then
                M.press.y=y;setOffset("stone",M.stoneScroll+delta);ui.render();return true
            end
        end
        return true
    elseif event==CCTOUCHENDED or event=="ended" then
        local p=M.press;M.press=nil
        if p and math.abs(y-p.y)<=6 and math.abs(x-p.x)<=6 then endTouch(x,y) end
        ui.render();return true
    end
    return true
end
function M.afterUpdate(newState)
    state=newState
    if not entryOf(M.uid) then M.close();return end
    if upgrade.isOpen() then upgrade.afterUpdate(state) end
end
function M.back()
    if upgrade.isOpen() then upgrade.back();return true end
    if M.mode~="main" then M.mode="main";M.hits={};return true end
    M.close();return true
end
return M

