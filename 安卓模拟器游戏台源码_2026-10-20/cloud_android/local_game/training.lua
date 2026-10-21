-- 培养 page reconstructed from the original ui/trainingUI.lua.
-- Left panel: portrait, faction, stars, stats, level/exp, 剩余潜能点.
-- Right panel: four growth bars, 元宝/蟠桃, four training options, hint, big 培养 button.
-- When the server has a pending result the same panel switches to 培养结果 with 放弃/接受.
local data = require('local_lineup_data')
local D = {kind = 1, returnPage = 'lineup'}
local ui, state, root
local GOLD = {255, 226, 163}
local PALE = {238, 226, 202}
local MUTED = {176, 148, 115}
local RED = {241, 67, 21}
local GREEN = {163, 211, 32}
local GREY = {141, 141, 141}
local CX, CY, CW, CH = 474, 108, 442, 392
local STATS = {'hp', 'attack', 'defense', 'magic'}
local ICONS = {'health', 'damage', 'defence', 'mana'}

local function image(file, x, y, w, h, parent)
    local node = CCSprite:create(file)
    if not node then return nil end
    local size = node:getContentSize()
    if w then
        node:setScaleX(w / size.width)
        node:setScaleY((h or w * size.height / size.width) / size.height)
    end
    node:setPosition(CCPointMake(x, y))
    local target = parent or root
    target:addChild(node)
    return node
end

local function atlas(info, x, y, w, h, parent)
    if not info then return nil end
    local node = CCSprite:create(info.file)
    if not node then return nil end
    local size = node:getContentSize()
    local cw, ch = size.width, size.height
    if info.index then
        cw, ch = size.width / info.columns, size.height / info.rows
        node:setTextureRect(CCRectMake((info.index - 1) % info.columns * cw,
                            math.floor((info.index - 1) / info.columns) * ch, cw, ch))
    end
    node:setScaleX(w / cw)
    node:setScaleY((h or w * ch / cw) / ch)
    node:setPosition(CCPointMake(x, y))
    local target = parent or root
    target:addChild(node)
    return node
end

local function label(value, x, y, size, color, parent, center, width)
    local node
    if width then
        node = CCLabelTTF:create(tostring(value), 'Arial', size, CCSizeMake(width, 0),
                                 kCCTextAlignmentLeft)
    else
        node = CCLabelTTF:create(tostring(value), 'Arial', size)
    end
    node:setAnchorPoint(CCPointMake(center and .5 or 0, width and 1 or .5))
    node:setPosition(CCPointMake(x, y))
    node:setColor(ccc3(unpack(color or GOLD)))
    local target = parent or root
    target:addChild(node)
    return node
end

local function fill(x, y, w, h, color, parent)
    local node = CCLayerColor:create(ccc4(unpack(color)))
    node:setContentSize(CCSizeMake(w, h))
    node:setPosition(CCPointMake(x, y))
    local target = parent or root
    target:addChild(node)
    return node
end

local function frame()
    image('v2/packageUI/board_chain.png', 221, 525, 76, 235):setAnchorPoint(CCPointMake(.5, 0))
    image('v2/packageUI/board_chain.png', 730, 525, 76, 235):setAnchorPoint(CCPointMake(.5, 0))
    fill(24, 86.4, 912, 432, {39, 24, 19, 255})
    image('v2/introUI/intro_bkg.png', 480, 302.4, 912, 432)
    image('v2/packageUI/board_edge1.png', 24, 302.4, 15, 432)
    local right = image('v2/packageUI/board_edge1.png', 936, 302.4, 15, 432)
    if right then right:setFlipY(true) end
    image('v2/packageUI/board_edge2.png', 480, 514.1, 930, 37.2)
    local bottom = image('v2/packageUI/board_edge2.png', 480, 90.7, 930, 37.2)
    if bottom then bottom:setFlipY(true) end
    fill(CX, CY, CW, CH, {20, 12, 8, 70})
end

local function heroFor(ident)
    for _, hero in ipairs(state.heroes or {}) do
        if hero.id == ident then return hero end
    end
end

local function entryFor(ident)
    return data.heroes[tostring(ident)]
end


local function drawLeft(entry, hero, pending)
    local floor = image('v2/introUI/floorHighLight.png', 273, 190, 320, 150)
    if floor then
        floor:setColor(ccc3(214, 174, 116))
        floor:setOpacity(120)
    end
    local category = {['神'] = 1, ['妖'] = 2, ['人'] = 3, ['魔'] = 4, ['佛'] = 5}
    local node = CCSprite:create(entry.sprite)
    if node then
        local boxX, boxY, boxW, boxH = 116, 176, 326, 320
        local clip = CCLayer:create()
        clip:setContentSize(CCSizeMake(boxW, boxH))
        local view = CCScrollView:create(CCSizeMake(boxW * root:getScaleX(),
                                                  boxH * root:getScaleY()), clip)
        view:setTouchEnabled(false)
        view:setPosition(CCPointMake(boxX, boxY))
        root:addChild(view)
        local b = entry.sprite_bounds
        if b and b.width > 0 and b.height > 0 then
            node:setScale(boxH / b.height)
            node:setAnchorPoint(CCPointMake((b.x + b.width / 2) / b.texture_width,
                                            (b.texture_height - (b.y + b.height)) / b.texture_height))
        else
            local size = node:getContentSize()
            node:setScale(boxH / size.height)
            node:setAnchorPoint(CCPointMake(.5, 0))
        end
        node:setPosition(CCPointMake(boxW / 2, 0))
        clip:addChild(node)
    end
    image('v2/charPositionUI/type_' .. (category[entry.category] or 1) .. '.png',
          62, 484, 30, 30)
    local stars = image('v2/CharaterUI/stars.png', 68, 400, 13, 65)
    if stars then stars:setTextureRect(CCRectMake(0, 0, 22, 20 * (entry.quality or 1))) end
    if entry.name_icon then
        atlas(entry.name_icon, 94, 400, 34, 140)
    else
        local chars = {}
        for ch in string.gmatch(entry.name, '[%z\1-\127\194-\244][\128-\191]*') do
            table.insert(chars, ch)
        end
        label(table.concat(chars, '\n'), 94, 400, 21, GOLD, nil, true)
    end

    local values = {hero.hp, hero.attack, hero.defense, hero.magic}
    local sx, sy, sw = 250, 196, 330
    local bs = sw / 514
    local sh = 52 * bs
    image('v2/trainingUI/stats_bkg.png', sx, sy, sw, sh)
    local left = sx - sw / 2
    local start, offset, isz = 514 * 0.04 * bs, 514 * 0.23 * bs, 41 * bs
    for i = 1, 4 do
        local xx = left + start + offset * (i - 1)
        image('v2/introUI/' .. ICONS[i] .. '.png', xx + isz / 2, sy, isz, isz)
        label(values[i] or 0, xx + isz + 0.01 * sw, sy, 16, GOLD)
    end

    local level = hero.level or 1
    image('v2/charPositionUI/level_bkg.png', 58, 166, 38, 24)
    label(level, 58, 166, 16, GOLD, nil, true)
    local bx, bw = 82, 332
    image('v2/CharaterUI/expbar1.png', bx + bw / 2, 166, bw, 14)
    local ratio = math.min(1, level / 20)
    if ratio > 0 then
        local exp = CCSprite:create('v2/CharaterUI/expbar2.png')
        if exp then
            local size = exp:getContentSize()
            exp:setAnchorPoint(CCPointMake(0, .5))
            exp:setScaleX(bw * ratio / size.width)
            exp:setScaleY(14 / size.height)
            exp:setPosition(CCPointMake(bx, 166))
            root:addChild(exp)
        end
    end
    label('等级 ' .. level .. ' / 20', bx + bw / 2, 166, 11, PALE, nil, true)

    local potential = hero.culture_point or 0
    if pending and pending.potential_used then
        potential = math.max(0, potential - pending.potential_used)
    end
    label('剩余潜能点：', 110, 112, 20, GOLD)
    label(tostring(math.floor(potential)), 300, 112, 26, {245, 190, 83}, nil, true)
end


local function drawRightBase(entry, hero)
    fill(CX, CY, CW, CH, {33, 20, 13, 235})
    for i = 1, 3 do
        local y = CY + CH - (i - 1) * 140 - 58
        image('v2/introUI/rightBkg.png', CX + CW / 2, y, CW, 140)
    end
    image('v2/introUI/left_scroll.png', CX + 8, CY + CH / 2, 16, CH)
    image('v2/introUI/right_scroll.png', CX + CW - 8, CY + CH / 2, 16, CH)

    -- trainingUI.statsChart: four growth bars normalized by the best hero.
    local growth = entry.growth or {}
    local maximums = data.growth_max or {}
    local symbols = {'命', '攻', '防', '法'}
    for i, row in ipairs({{key = 'hp', icon = 'health'},
                          {key = 'attack', icon = 'damage'},
                          {key = 'defense', icon = 'defence'},
                          {key = 'magic', icon = 'mana'}}) do
        local cy = CY + CH - 16 - (i - 1) * 26
        local labelX = CX + 18
        image('v2/trainingUI/choose_frame.png', labelX, cy, 24, 24)
        label(symbols[i], labelX, cy, 13, GOLD, nil, true)
        local barX, barW, barH = CX + 38, CW - 60, 14
        image('v2/introUI/property_bkg.png', barX + barW / 2, cy, barW, barH)
        local value = tonumber(growth[row.key]) or 0
        local maximum = tonumber(maximums[row.key]) or 0
        local ratio = maximum > 0 and math.min(1, value / maximum) or 0
        if ratio > 0 then
            local up = CCSprite:create('v2/introUI/property_up.png')
            if up then
                local size = up:getContentSize()
                up:setAnchorPoint(CCPointMake(0, .5))
                up:setScaleX(barW * ratio / size.width)
                up:setScaleY(barH / size.height)
                up:setPosition(CCPointMake(barX, cy))
                root:addChild(up)
            end
        end
    end

    label('元宝: ', CX + 52, CY + 270, 20, {177, 132, 35})
    label(tostring(state.gold or 0), CX + 112, CY + 270, 18, GOLD)
    local peaches = 0
    for _, item in ipairs((state.inventory or {}).entries or {}) do
        if item.key == 'i1001' then peaches = peaches + (item.count or 0) end
    end
    label('蟠桃: ', CX + 232, CY + 270, 20, {177, 132, 35})
    label(tostring(peaches), CX + 292, CY + 270, 18, GOLD)
end

local function option(cx, cy, title, sub, gold)
    local hitKind = gold and (sub and 4 or 3) or (sub and 2 or 1)
    local box = image('v2/trainingUI/choose_frame.png', cx, cy, 25, 25)
    if D.kind == hitKind then
        image('v2/trainingUI/choose.png', cx, cy, 21, 21)
    end
    local top = sub and cy + 8 or cy
    label(title, cx + 19, top, 18, GOLD)
    if sub then label(sub, cx + 19, top - 20, 18, GOLD) end
    if gold then
        image('v2/money_gold.png', cx + 120, cy, 17, 12)
        label(tostring(gold), cx + 132, cy, 15, PALE)
    end
    ui.hit(cx - 14, cy - 16, 165, 34, function()
        D.kind = hitKind
        ui.render()
    end, true, box)
end

local function drawStart(entry, hero)
    option(CX + 56, CY + 208, '培养', nil, nil)
    option(CX + 56, CY + 164, '培养', '10次', nil)
    option(CX + 256, CY + 208, '精心培养', nil, 1)
    option(CX + 256, CY + 164, '精心培养', '10次', 10)
    label('提示：使用精心培养可以节省大量蟠桃', CX + CW / 2, CY + 122, 14, PALE, nil, true)
    local button = image('v2/trainingUI/training1.png', CX + CW / 2, CY + 52, 140, 66)
    ui.hit(CX + CW / 2 - 70, CY + 19, 140, 66, function()
        ui.send('train', {hero = hero.id, kind = D.kind})
    end, true, button)
end

local function deltaFor(stat, pending)
    if stat == pending.increase then return tonumber(pending.value) or 0 end
    if stat == pending.decrease then return -(tonumber(pending.decrease_value) or 0) end
    return 0
end

local function drawResult(entry, hero, pending)
    local cx, cy = CX + CW / 2, CY + 152
    image('v2/trainingUI/data_bkg.png', cx, cy, 410, 180)
    image('v2/trainingUI/title_bkg.png', CX + CW - 80, CY + 232, 200, 45)
    image('v2/trainingUI/resultHZ.png', CX + CW - 80, CY + 232, 128, 32)

    for i, stat in ipairs(STATS) do
        local y = CY + 192 - (i - 1) * 33
        local delta = deltaFor(stat, pending)
        local value = (hero[stat] or 0) + delta
        local plus = (hero[stat .. '_plus'] or 0) + delta
        image('v2/introUI/' .. ICONS[i] .. '.png', CX + 34, y, 22, 22)
        label(tostring(hero[stat] or 0) .. ' (' .. tostring(hero[stat .. '_plus'] or 0) .. ')',
              CX + 54, y, 16, GOLD)
        local color = delta > 0 and GREEN or delta < 0 and RED or GREY
        label((delta > 0 and '+' or '') .. tostring(delta), CX + 208, y, 16, color, nil, true)
        label(tostring(value) .. '(' .. tostring(plus) .. ')', CX + 226, y, 16, color)
        if delta ~= 0 then
            image(delta > 0 and 'v2/trainingUI/up.png' or 'v2/trainingUI/down.png',
                  CX + CW - 54, y, 15, 26)
        end
    end

    local give = image('v2/trainingUI/giveup1.png', CX + 148, CY + 50, 140, 69)
    ui.hit(CX + 78, CY + 16, 140, 69, function()
        ui.send('train_giveup', {hero = hero.id})
    end, true, give)
    local accept = image('v2/trainingUI/accept1.png', CX + 318, CY + 50, 140, 69)
    ui.hit(CX + 248, CY + 16, 140, 69, function()
        ui.send('train_accept', {hero = hero.id})
    end, true, accept)
end

function D.open(ident, returnPage)
    D.heroId = ident
    D.returnPage = returnPage or 'lineup'
    D.kind = 1
end

function D.draw(context, player)
    ui, state, root = context, player, context.root
    D.ctx = context
    local hero = heroFor(D.heroId)
    local entry = hero and entryFor(hero.id)
    if not hero or not entry then
        context.navigate(D.returnPage or 'lineup')
        return
    end
    frame()
    local pending = hero.train_pending
    drawLeft(entry, hero, pending)
    drawRightBase(entry, hero)
    if pending then drawResult(entry, hero, pending) else drawStart(entry, hero) end

    local close = image('v2/introUI/close1.png', 917, 509, 44, 42)
    ui.hit(895, 488, 44, 42, function() D.back() end, true, close)
    if context.error then
        label(context.error, 480, 72, 14, {255, 190, 150}, nil, true)
    elseif context.notice and context.notice ~= '已连接本地服务 · 进度已保存' then
        label(context.notice, 480, 72, 14, PALE, nil, true)
    end
end

function D.back()
    if D.ctx and D.ctx.navigate then D.ctx.navigate(D.returnPage or 'lineup') end
end

function D.touch(event, x, y)
    if event == CCTOUCHENDED or event == 'ended' then
        if x >= 895 and x <= 939 and y >= 488 and y <= 530 then
            D.back()
            return true
        end
    end
    return false
end

return D
