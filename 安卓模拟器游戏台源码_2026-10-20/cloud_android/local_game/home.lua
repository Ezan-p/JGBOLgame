-- Original 1280 x 720 mainUI layout, adapted to the local 960 x 540 canvas.
-- Source: ui/mainUI.lua, ui/playerInfoUI.lua and ui/bonusLayerUI.lua.
local M = {}
local S = .75

function M.draw(ui, state, navigate, info)
    local root = ui.root
    local function sprite(file, x, y, scale, ax, ay)
        local node = CCSprite:create(file)
        if not node then return nil end
        node:setScale(scale or S)
        node:setAnchorPoint(CCPointMake(ax or .5, ay or .5))
        node:setPosition(CCPointMake(x, y))
        root:addChild(node)
        return node
    end
    local function hit(x,y,w,h,callback,node)
        ui.hit(x,y,w,h,callback,node)
    end
    local function go(target)
        return function() navigate(target) end
    end
    local function explain(title, lines)
        return function() info(title, lines) end
    end
    local function bob(node, distance, seconds)
        if not node then return end
        local actions=CCArray:create()
        actions:addObject(CCMoveBy:create(seconds,CCPointMake(0,distance)))
        actions:addObject(CCMoveBy:create(seconds,CCPointMake(0,-distance)))
        node:runAction(CCRepeatForever:create(tolua.cast(CCSequence:create(actions),"CCActionInterval")))
    end
    local function shadow(value,x,y,size,color,center)
        ui.text(value,x+1,y-1,size,{30,22,15},center)
        return ui.text(value,x,y,size,color or {245,235,205},center)
    end
    local function number(value,x,y,scale,filename,cellw,cellh)
        for digit in tostring(value):gmatch(".") do
            local n=tonumber(digit)
            local node=CCSprite:create(filename)
            node:setTextureRect(CCRectMake(((n+9)%10)*cellw,0,cellw,cellh))
            node:setScale(scale)
            node:setAnchorPoint(CCPointMake(0,.5))
            node:setPosition(CCPointMake(x,y))
            root:addChild(node)
            x=x+cellw*scale
        end
    end

    if not ui.menuOnly then
    -- The original backdrop is width-fitted, anchored at bottom left (not stretched).
    local bg=sprite("v2/mainUI/bkg_d.jpg",0,0,960/1024,0,0)
    sprite("v2/mainUI/tail1.png",398.08*S,584*S)
    sprite("v2/mainUI/tail2.png",176.64*S,588*S)
    sprite("v2/mainUI/tail3.png",42.24*S,580*S)
    sprite("v2/mainUI/tollgate1.png",906.24*S,0,S,.5,0)
    sprite("v2/mainUI/strange1.png",276.48*S,115*S,S,.5,0)
    sprite("v2/mainUI/news1.png",577.28*S,0,S,.5,0)
    sprite("v2/mainUI/xianmeng1.png",980.48*S,341*S,S,.5,0)
    sprite("v2/mainUI/cele1.png",579.84*S,533*S)

    -- Reuse original atlas frames for the monkey and cranes.
    local cache=CCSpriteFrameCache:sharedSpriteFrameCache()
    cache:addSpriteFramesWithFile("150_1/150_1.plist")
    cache:addSpriteFramesWithFile("270_3/270_3.plist")
    local monkey=CCSprite:createWithSpriteFrameName("150_10001.png")
    if monkey then
        monkey:setScale(S)
        monkey:setPosition(CCPointMake(435,287))
        root:addChild(monkey)
        bob(monkey,4,2.4)
    end
    for i=1,2 do
        local bird=CCSprite:createWithSpriteFrameName(i==1 and "270_1_01.png" or "270_1_02.png")
        if bird then
            bird:setScale(i==1 and .34 or .27)
            bird:setPosition(CCPointMake(789+(i-1)*29,477-(i-1)*53))
            root:addChild(bird)
            bob(bird,7,i==1 and 3.3 or 2.7)
        end
    end

    hit(767,126,104,183,go("stages"))
    hit(127,290,102,160,explain("试炼",{
        "原版试炼入口已还原。",
        "试炼排行及专属奖励尚未接入本地服务。",
        "可从「旅途」进入当前十个 PvE 关卡。"}))
    hit(355,351,91,141,explain("名人山",{
        "原版名人山入口已还原。",
        "跨服排名和玩家记录需要对应的服务端数据。",
        "本地版目前不提供联网排名。"}))
    hit(604,360,111,112,explain("仙盟",{
        "原版仙盟入口已还原。",
        "仙盟成员、捐献与联盟战尚未实现。"}))
    hit(475,116,93,134,explain("活动",{
        "当前已开放：两章十关本地取经。",
        "首通银两翻倍，已通关关卡可以重复挑战。",
        "角色培养、招募与阵容调整均会自动保存。"}))

    end
    -- Original boards hide the player header while retaining the scene and bottom menu.
    if not ui.hideHeader then
    -- Header positions follow createPlayerInfo() in the original Lua.
    local header=sprite("v2/character_frame.png",480,540-81*S/2)
    local hx, hy, hw, hh = 78, 540-81*S, 1072*S, 81*S
    shadow(state.name,hx+hw*.5,hy+hh*.70,16,nil,true)
    sprite("v2/vip/vip_label.png",hx+hw*.61,hy+hh*.70)
    sprite("v2/vip/0.png",hx+hw*.65,hy+hh*.70)
    sprite("v2/Stamina2.png",hx+hw*.06,hy+hh*.60)
    shadow(state.energy.."/60",hx+hw*.08,hy+hh*.60,16)
    sprite("v2/Energy2.png",hx+hw*.18,hy+hh*.60)
    shadow("—",hx+hw*.20,hy+hh*.60,16)
    sprite("v2/money_gold.png",hx+hw*.73,hy+hh*.60)
    shadow(state.gold or 0,hx+hw*.75,hy+hh*.60,16)
    sprite("v2/money_silver.png",hx+hw*.85,hy+hh*.60)
    shadow(state.silver,hx+hw*.87,hy+hh*.60,16)
    local exp=sprite("v2/exp_bar2.png",hx+hw*.51-335*S/2,hy+hh*.30,S,0,.5)
    local size=exp:getContentSize()
    exp:setTextureRect(CCRectMake(0,0,size.width*((state.experience%200)/200),size.height))
    shadow((state.experience%200).."/200",hx+hw*.50,hy+hh*.35,14,nil,true)
    local level=tostring(state.level)
    for i=1,#level do
        sprite("v2/vip/"..level:sub(i,i)..".png",hx+hw*.335+(i-(#level+1)/2)*17,hy+hh*.32,.70)
    end
    local portrait=sprite("v2/namingUI/head_201.png",37.44,502.2,76.8/94)
    hit(0,463,80,77,explain("本地行者",{
        "等级 "..state.level.." · 已解锁关卡 "..state.unlocked.."/10",
        "银两 "..state.silver.." · 元宝 "..(state.gold or 0).." · 体力 "..state.energy.."/60",
        "本地存档自动保存，免账号登录。",
        "元宝用于召唤，VIP 与精力系统尚未启用。"}),portrait)
    local power=state.role_combat_power
    sprite("v2/playerInfoUI/com_sword.png",178,466,.75)
    sprite("v2/playerInfoUI/com_label.png",132,486,.75)
    if type(power)=="number" then
        number(power,174,485,.54,"v2/playerInfoUI/com_num.png",36,46)
    else
        shadow("—",192,485,22,nil,true)
    end
    hit(88,451,245,47,explain("战斗力",{
        "当前出战阵容战斗力："..(type(power)=="number" and tostring(power) or "暂不可用"),
        "原版战斗力由服务器提供。",
        "本地版尚缺原版战力公式，四维属性和战斗照常生效。"}))
    local buff=sprite("v2/mainUI/level_buff.png",39.36,421.2,57.6/118)
    shadow("经验加成",39.36,390,16,{248,222,142},true)
    hit(7,379,68,77,explain("经验加成",{
        "原版入口已还原，当前没有额外经验增益。",
        "挑战旅途关卡可获得经验，累计每 200 经验升一级。"}),buff)

    local side={
        {"sign","日常",{"本地旅途：已解锁 "..state.unlocked.."/10 关。","通关、培养与招募功能已开放。","原服签到与每日任务尚未接入。"}},
        {"vip","VIP",{"本地版无需充值或 VIP 即可体验已开放内容。","当前 VIP 等级为 0，没有付费入口。"}},
        {"month","月卡",{"原版月卡入口已还原。","本地版未启用月卡购买与每日领取。"}},
        {"recharge","福利",{"旅途首次通关获得双倍银两。","原服礼包、充值返利与兑换码未接入。"}},
        {"mystery","许愿阁",{"原版许愿阁玩法尚未接入。","可使用底部「召唤」入口招募伙伴。"}},
        {"god","土地祝福",{"原版土地祝福入口已还原。","本地版体力每五分钟恢复一点，上限 60。"}}
    }
    for i,item in ipairs(side) do
        local x,y=918,496.8-(i-1)*64.8
        local disk=sprite("v2/bonusUI/bkg1.png",x,y,.64)
        if item[1]=="mystery" then
            -- Original temple art, with the reference screenshot's entry label.
            sprite("v2/mainUI/xianmeng1.png",x,y+6,.15)
            shadow("许愿阁",x,y-19,13,{255,231,163},true)
        else
            sprite("v2/bonusUI/"..item[1].."1.png",x,y,.50)
        end
        hit(x-32,y-31,64,62,explain(item[2],item[3]),disk)
    end

    end
    sprite("v2/bottom_main.png",480,16.2,.75)
    local menu={
        {"other","其它",.065,explain("其它",{"金箍棒 · 本地版","使用原版资源与布局，还原主界面。","「旅途」挑战关卡；「神仙」培养；「阵容」调整。","「召唤」招募伙伴，所有进度自动保存。"})},
        {"Home","首页",.294,go("home")},
        {"shop","集市",.4,explain("集市",{"原版商品与道具交易尚未实现。","当前银两可用于角色培养与伙伴招募。"})},
        {"package","包裹",.506,go("inventory")},
        {"character","神仙",.612,go("cortege")},
        {"roleRebornUI/role_reborn","转生",.718,explain("转生",{"转生按钮已从原版更新资源中还原。","转生消耗、突破与成长规则尚未接入。","当前可在「神仙」中将伙伴培养至 20 级。"})},
        {"buddy","阵容",.824,go("lineup")},
        {"summon","召唤",.93,go("summon")}
    }
    for _,item in ipairs(menu) do
        local x=item[3]*960
        local icon=sprite("v2/"..item[1].."1.png",x,35,86.4/110)
        hit(x-43,0,86,78,item[4],icon)
    end
    -- Small edition marker: preserve the artwork and keep the local mode explicit.
    shadow("本地版 · 已存档",163,19,12,{255,239,188},true)
end

return M
