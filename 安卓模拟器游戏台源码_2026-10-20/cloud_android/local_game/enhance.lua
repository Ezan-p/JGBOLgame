-- Original equipmentUpgradeUI.addFrameUI layout and equip_enhance_cost silver values.
local data=require("local_inventory_data")
local M={}
local CREAM={255,255,224}
local GREEN={0,255,0}
local PALE={255,255,210}
local function image(root,file,x,y,w,h,parent)
    local n=CCSprite:create(file)
    if not n then return end
    local s=n:getContentSize()
    n:setScaleX(w/s.width); n:setScaleY((h or w*s.height/s.width)/s.height)
    n:setPosition(CCPointMake(x,y)); (parent or root):addChild(n)
    return n
end
local function label(root,value,x,y,size,color,center,parent)
    local n=CCLabelTTF:create(tostring(value),"Arial",size)
    n:setAnchorPoint(CCPointMake(center and .5 or 0,.5))
    n:setPosition(CCPointMake(x,y)); n:setColor(ccc3(unpack(color)))
    local target=parent or root; target:addChild(n)
    return n
end
local function atlas(root,info,x,y,w)
    local n=CCSprite:create(info.file); local s=n:getContentSize()
    local cw,ch=s.width/info.columns,s.height/info.rows
    n:setTextureRect(CCRectMake((info.index-1)%info.columns*cw,
        math.floor((info.index-1)/info.columns)*ch,cw,ch))
    n:setScaleX(w/cw); n:setScaleY(w/cw)
    n:setPosition(CCPointMake(x,y)); root:addChild(n); return n
end
local function fill(root,x,y,w,h,color)
    local n=CCLayerColor:create(ccc4(unpack(color)))
    n:setContentSize(CCSizeMake(w,h)); n:setPosition(CCPointMake(x,y)); root:addChild(n)
    return n
end
local function commas(value)
    local text=tostring(math.floor(tonumber(value) or 0)):reverse():gsub("(%d%d%d)","%1,")
    text=text:reverse()
    return (text:gsub("^,",""))
end
local function entryOf(state,uid)
    for _,e in ipairs((state.inventory or {}).entries or {}) do if e.uid==uid then return e end end
end
local function canUpgrade(state,entry,item)
    local level=tonumber(entry.level) or 1
    local cap=math.min(tonumber(item.top_level) or 200,(tonumber(state.level) or 1)*2)
    if level>=cap then return 2 end
    if (tonumber(state.silver) or 0)<(tonumber(entry.upgrade_cost) or 0) then return 1 end
    return 0
end
local function blockedMessage(flag)
    if flag==1 then return "你的银两不足" end
    if flag==2 then return "装备已强化到当前上限" end
end
local function attempt(state)
    if not M.uid then return end
    local entry=entryOf(state,M.uid)
    local item=entry and data.items[entry.key]
    if not entry or not item then M.close();return end
    local flag=canUpgrade(state,entry,item)
    if flag~=0 then
        M.batch=false;M.message=blockedMessage(flag);M.ctx.render();return
    end
    M.message=nil;M.lastLevel=tonumber(entry.level) or 1
    M.ctx.send("bag_upgrade",{uid=entry.uid})
end
function M.open(ui,state,uid)
    M.uid=uid;M.batch=false;M.message=nil;M.lastLevel=nil
    M.ctx={send=ui.send,render=ui.render,root=ui.root}
end
function M.close()
    M.uid=nil;M.batch=false;M.message=nil;M.lastLevel=nil
end
function M.isOpen() return M.uid~=nil end
function M.afterUpdate(state)
    if not M.uid or not M.batch then return end
    local entry=entryOf(state,M.uid)
    local item=entry and data.items[entry.key]
    if not entry or not item then M.close();return end
    local level=tonumber(entry.level) or 1
    if M.lastLevel and level<=M.lastLevel then M.batch=false;return end
    M.lastLevel=level
    local flag=canUpgrade(state,entry,item)
    if flag==0 then M.ctx.send("bag_upgrade",{uid=entry.uid})
    else M.batch=false;M.message=blockedMessage(flag) end
end

function M.draw(ctx,state)
    if not M.uid then return end
    local entry=entryOf(state,M.uid)
    local item=entry and data.items[entry.key]
    if not entry or not item or item.category>3 then M.close();return end
    M.ctx={send=ctx.send,render=ctx.render,root=ctx.root}
    local root=ctx.root
    local level=tonumber(entry.level) or 1
    local original=item.original or {}
    local field=item.category
    local baseKey=field==1 and "gongji_plus" or field==2 and "fangyu_plus" or "maxhp_plus"
    local icon=field==1 and "damage" or field==2 and "defence" or "health"
    local effect=tonumber(original.upgrade_plus) or 0
    local property=math.floor((level-1)*effect+(tonumber(original[baseKey]) or 0))
    local cost=tonumber(entry.upgrade_cost) or 0
    local flag=canUpgrade(state,entry,item)
    ctx.clearHits()
    ctx.hit(0,0,960,540,function() M.close();ctx.render() end,true,nil)
    ctx.hit(240,72.9,480,448.2,function() end,true,nil)
    fill(root,0,0,960,540,{0,0,0,150})
    image(root,"v2/common/frame1.png",480,297,480,448.2)
    image(root,"v2/common/frame2.png",480,307.8,441.6,302.4)
    image(root,"v2/common/small_label.png",480,483.3,408.6,54)
    image(root,"v2/enhanceUI/equipEnhance.png",480,483.3,171.6,48.6)
    image(root,"v2/enhanceUI/mid3.png",556.8,367.2,120,63.6)
    atlas(root,item.icon,355.2,367.2,172.8)
    image(root,"v2/newIntroUI/star_bkg.png",355.2,313.2,81.75,17.25)
    local ratio=math.max(0,math.min(1,(tonumber(item.quality) or 0)/5))
    if ratio>0 then
        local stars=CCSprite:create("v2/introUI/stars.png")
        local size=stars:getContentSize()
        stars:setTextureRect(CCRectMake(0,0,size.width*ratio,size.height))
        stars:setScale(.75)
        stars:setPosition(CCPointMake(355.2-(1-ratio)*size.width*.75/2,313.2))
        root:addChild(stars)
    end
    label(root,item.name,355.2,270,17,{202,202,202},true)
    label(root,"强化预览",566.4,405,23,CREAM,true)
    image(root,"v2/introUI/level.png",499.2,367.2,30.75,30.75)
    label(root,level,528,367.2,17,PALE)
    label(root,"(预计+1)",585.6,367.2,17,GREEN)
    image(root,"v2/introUI/"..icon..".png",499.2,313.2,30.75,30.75)
    label(root,property,528,313.2,17,PALE)
    label(root,"(预计+"..math.floor(effect)..")",585.6,313.2,17,GREEN)
    if M.message then label(root,M.message,528,270,20,{255,96,72}) end
    image(root,"v2/enhanceUI/mid2.png",480,175.5,441.6,37.8)
    label(root,"银两需求：",278.4,175.5,23,{255,140,0})
    label(root,"消耗:",403.2,175.5,20,CREAM)
    label(root,commas(cost),451.2,175.5,17,(state.silver>=cost) and GREEN or {255,0,0})
    label(root,"现有:",547.2,175.5,20,CREAM)
    label(root,commas(state.silver),595.2,175.5,17,{189,183,107})
    local function button(file,x,y,action)
        local n=image(root,file,x,y,115.2)
        if flag~=0 then n:setColor(ccc3(115,105,95)) end
        ctx.hit(x-57.6,y-28.8,115.2,57.6,action,true,n)
    end
    button("v2/enhanceUI/continue_1.png",364.8,116.1,function()
        M.batch=true;attempt(state)
    end)
    button("v2/enhanceUI/en_1.png",595.2,116.1,function()
        M.batch=false;attempt(state)
    end)
    local close=image(root,"v2/common/close1.png",681.6,483.3,79,75)
    ctx.hit(642.1,445.8,79,75,function() M.close();ctx.render() end,true,close)
end
return M