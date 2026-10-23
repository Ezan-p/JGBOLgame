-- Original data.getCcbiByAdvanceLevel / addAdvanceCcbi and createCell marks.
-- The effect runs inside the icon, so it follows scrolling, clipping and cleanup.
local M={}
local EFFECT_TAG,MARK_TAG,LEVEL_TAG=87201,87202,87203
local function rank(entry)
    return math.max(0,math.min(10,math.floor(tonumber(entry and entry.advance_level) or 0)))
end
function M.effectFor(level)
    if level>=10 then return '04.ccbi',.56
    elseif level==9 then return '03.ccbi',.56
    elseif level>=6 then return '02.ccbi',.45
    elseif level>=3 then return '01.ccbi',.56 end
end
function M.effect(sprite,entry)
    if not sprite then return end
    sprite:removeChildByTag(EFFECT_TAG,true)
    local file,anchorY=M.effectFor(rank(entry));if not file then return end
    local reader=CCBReader:new(CCNodeLoaderLibrary:newDefaultCCNodeLoaderLibrary())
    local node=reader:readNodeGraphFromFile(file,sprite,nil);reader:autorelease()
    if not node then CCLuaLog('EQUIP_VISUAL_LOAD_ERROR '..file);return end
    local size=sprite:getContentSize()
    local screen=CCDirector:sharedDirector():getVisibleSize()
    node:setAnchorPoint(CCPointMake(.5,anchorY))
    node:setPosition(CCPointMake(size.width*.5-screen.width*.5,size.height*.5-screen.height*.5))
    node:setScale(size.width/120)
    sprite:addChild(node,1,EFFECT_TAG)
end
function M.corner(sprite,entry)
    if not sprite then return end
    sprite:removeChildByTag(MARK_TAG,true)
    local level=rank(entry)
    if level==0 or tonumber(entry.star_level)==1 then return end
    local n=CCSprite:create('v2/equipAdvanceUI/ad'..level..'.png')
    local size=sprite:getContentSize()
    n:setAnchorPoint(CCPointMake(1,0));n:setPosition(CCPointMake(.93*size.width,.07*size.height))
    sprite:addChild(n,2,MARK_TAG)
end
function M.level(sprite,entry)
    if not sprite then return end
    sprite:removeChildByTag(LEVEL_TAG,true)
    local size=sprite:getContentSize()
    local n=CCLabelTTF:create(tostring(entry.level or 1),'Arial',22)
    n:setAnchorPoint(CCPointMake(0,.5));n:setPosition(CCPointMake(.1*size.width,.8*size.height))
    n:setColor(ccc3(255,255,255));sprite:addChild(n,3,LEVEL_TAG)
end
function M.nameMark(parent,name,entry,scale)
    local level=rank(entry);if level==0 then return end
    local n=CCSprite:create('v2/equipAdvanceUI/ad'..level..'.png')
    local p=name:getPositionLua();local size=name:getContentSize();local a=name:getAnchorPoint()
    n:setScale(scale or .75);n:setAnchorPoint(CCPointMake(-.1,.5))
    n:setPosition(CCPointMake(p.x+(1-a.x)*size.width*name:getScaleX(),p.y))
    parent:addChild(n,2);return n
end
function M.equipped(sprite,entry)
    M.effect(sprite,entry);M.corner(sprite,entry);M.level(sprite,entry)
end
return M
