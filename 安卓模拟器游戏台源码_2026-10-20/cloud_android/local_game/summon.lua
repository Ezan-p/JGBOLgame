-- Original summonUI.lua layout, adapted to the local 960 x 540 canvas.
-- Geometry follows the original 1280 x 720 positions at the local .75 factor.
local info = require("local_handbook_data")
local data = require("local_summon_data")
local lineupOK, lineupData = pcall(require, "local_lineup_data")
if not lineupOK then lineupData = nil end
local M = {offset = 0}
local ui, state, root
local GOLD = {244, 221, 173}
local MUTED = {179, 152, 119}
local ORANGE = {255, 120, 0}
local byId = {}
for _, hero in ipairs(info.heroes) do byId[hero.id] = hero end

local function image(file, x, y, w, h, parent)
    local node = CCSprite:create(file)
    if not node then return nil end
    local size = node:getContentSize()
    node:setScaleX(w / size.width)
    node:setScaleY((h or w * size.height / size.width) / size.height)
    node:setPosition(CCPointMake(x, y))
    ;(parent or root):addChild(node)
    return node
end

local function label(value, x, y, size, color, parent, center, width)
    local node
    if width then
        node = CCLabelTTF:create(tostring(value), "Arial", size, CCSizeMake(width, 0), kCCTextAlignmentLeft)
    else
        node = CCLabelTTF:create(tostring(value), "Arial", size)
    end
    node:setAnchorPoint(CCPointMake(center and .5 or 0, width and 1 or .5))
    node:setPosition(CCPointMake(x, y))
    node:setColor(ccc3(unpack(color or GOLD)))
    ;(parent or root):addChild(node)
    return node
end

local function fill(x, y, w, h, color, parent)
    local node = CCLayerColor:create(ccc4(unpack(color)))
    node:setContentSize(CCSizeMake(w, h))
    node:setPosition(CCPointMake(x, y))
    ;(parent or root):addChild(node)
    return node
end

local function atlas(crop, x, y, size, parent, height)
    local node = CCSprite:create(crop.file)
    local full = node:getContentSize()
    local cw, ch = full.width / crop.columns, full.height / crop.rows
    node:setTextureRect(CCRectMake((crop.index - 1) % crop.columns * cw,
                        math.floor((crop.index - 1) / crop.columns) * ch, cw, ch))
    node:setScaleX(size / cw)
    node:setScaleY((height or size) / ch)
    node:setPosition(CCPointMake(x, y))
    ;(parent or root):addChild(node)
    return node
end

local function fmtTime(seconds)
    seconds = math.max(0, math.floor(seconds or 0))
    return string.format("%02d:%02d:%02d", math.floor(seconds / 3600),
                         math.floor(seconds % 3600 / 60), seconds % 60)
end

local function tier(index)
    return state.summon and state.summon.tiers[index] or {
        grade = index, name = data.tiers[index].name, cost = data.tiers[index].cost,
        free = false, remaining = 0, used = 0, limit = data.normal_daily_free,
    }
end

local function drawHeader()
    image("v2/character_frame.png", 480, 515, 880, 52)
    image("v2/namingUI/head_201.png", 30, 515, 44, 42)
    label(state.name or "本地行者", 56, 524, 15, GOLD)
    label("Lv." .. tostring(state.level or 1), 56, 508, 12, MUTED)
    image("v2/vip/vip_label.png", 158, 521, 42, 18)
    image("v2/vip/0.png", 192, 521, 18, 18)
    image("v2/Stamina2.png", 270, 520, 20, 20)
    label(tostring(state.energy or 0) .. "/60", 284, 520, 14, GOLD)
    image("v2/Energy2.png", 360, 520, 20, 20)
    label("—", 374, 520, 14, GOLD)
    image("v2/money_gold.png", 590, 520, 22, 15)
    label(tostring(state.gold or 0), 605, 520, 14, {255, 220, 153})
    image("v2/money_silver.png", 724, 520, 22, 15)
    label(tostring(state.silver or 0), 739, 520, 14, {255, 220, 153})
    local close = image("v2/introUI/close1.png", 930, 516, 40, 38)
    ui.hit(910, 496, 42, 40, function() M.back() end, true, close)
end

local function drawFrame()
    image("v2/introUI/intro_bkg.png", 480, 291.2, 912, 409.6)
    image("v2/packageUI/board_edge1.png", 24, 291.2, 15, 409.6)
    local right = image("v2/packageUI/board_edge1.png", 936, 291.2, 15, 409.6)
    right:setFlipY(true)
    image("v2/packageUI/board_edge2.png", 480, 496, 930, 37)
    image("v2/packageUI/board_edge2.png", 480, 86.4, 930, 37):setFlipY(true)
end

local function drawTitle()
    image("v2/introUI/small_label.png", 480, 486, 190, 30)
    label("召唤", 480, 486, 22, {255, 222, 156}, nil, true)
end

local function setOffset(value)
    local s = M.scroll
    if not s then return end
    s.offset = math.max(0, math.min(s.max, value))
    s.node:setPositionY(s.h - s.total + s.offset)
end

local function drawNews()
    image("v2/introUI/small_label.png", 153.6, 458, 250, 46)
    image("v2/summonUI/newsHZ.png", 153.6, 458, 210, 44.3)
    local list = state.summon and state.summon.news or {}
    local rowHeight = 88
    local viewHeight = 352
    local total = math.max(viewHeight, #list * rowHeight)
    local container = CCLayer:create()
    container:setContentSize(CCSizeMake(252, total))
    container:setAnchorPoint(CCPointMake(0, 0))
    local view = CCScrollView:create(CCSizeMake(252 * root:getScaleX(), viewHeight * root:getScaleY()), container)
    view:setTouchEnabled(false)
    view:setPosition(CCPointMake(26, 84))
    root:addChild(view)
    M.scroll = {node = container, x = 26, y = 84, w = 252, h = viewHeight,
                total = total, max = math.max(0, total - viewHeight), offset = 0}
    for i, entry in ipairs(list) do
        local y = total - (i - 1) * rowHeight - rowHeight / 2
        local hero = byId[entry.type_id]
        image("v2/summonUI/info_bkg.png", 127, y, 236, 84, container)
        if hero then atlas(hero.icon, 70, y, 64, container) end
        label(hero and hero.name or "神仙", 105, y + 20, 20, ORANGE, container)
        label(entry.name or "本地行者", 105, y - 20, 15, {240, 232, 214}, container)
    end
    if #list == 0 then label("暂无召唤喜讯", 153, 300, 18, MUTED, nil, true) end
    setOffset(M.offset or 0)
end

local CARD_Y = 333
local CARDS = {
    {width = 214.5, height = 264, original = 352},
    {width = 225.75, height = 273.75, original = 365},
    {width = 215.25, height = 266.25, original = 355},
}

local function drawCards()
    local firstBottom = CARD_Y - CARDS[1].height / 2
    local delta = firstBottom - 86.4 - 5.4
    local bottomScale = delta * .75 / 120
    local introScale = delta / 4 / 48
    image("v2/summonUI/intro_bottom.png", 609.75,
          firstBottom - 120 * bottomScale - 24 * introScale, 645.75, 48 * introScale)
    local x = 288
    for i, card in ipairs(CARDS) do
        local cx = x + card.width / 2
        local bottom = CARD_Y - card.height / 2
        image("v2/summonUI/summon_bkg_" .. i .. ".png", cx, CARD_Y, card.width, card.height)
        local buttonY = CARD_Y - .37 * card.original * .75
        local free = tier(i).free
        local enabled = not ui.busy and (free or (state.gold or 0) >= tier(i).cost)
        local button = image("v2/summonUI/summon_btn_" .. i .. ".png", cx, buttonY, 135, 48)
        if not enabled then button:setColor(ccc3(120, 120, 120)) end
        local grade = i
        ui.hit(cx - 67.5, buttonY - 24, 135, 48,
               function() ui.send("summon", {grade = grade}) end, enabled, button)
        local stars = image("v2/summonUI/bkg_bottom" .. i .. ".png", cx, bottom, 183.75, 36.75)
        stars:setAnchorPoint(CCPointMake(.5, 1))
        local bottomCenter = bottom - 60 * bottomScale
        image("v2/summonUI/bottom_bkg.png", cx, bottomCenter, 213, 120 * bottomScale)
        local status = tier(i)
        if status.free then
            label("免费召唤", cx, bottomCenter - 4, 21, {255, 200, 168}, nil, true)
        else
            local coin = image("v2/money_gold.png", cx - 14, bottomCenter, 23, 16)
            coin:setAnchorPoint(CCPointMake(1, .5))
            label(tostring(status.cost), cx + 12, bottomCenter, 24, {245, 190, 83})
            local hint
            if i == 1 and status.used >= status.limit then
                hint = "今日免费次数已用完"
            else
                hint = fmtTime(status.remaining) .. "后免费"
            end
            label(hint, cx, bottomCenter - 27, 14, {255, 200, 214}, nil, true)
        end
        x = x + card.width
    end
end

local function drawLast()
    local last = state.summon and state.summon.last
    label("上次召唤：" .. (last and last.name or "暂无"), 528, 108, 18, {255, 181, 115})
end

local function drawStatsBar(hero, cx, cy, scale)
    local width = 514 * scale
    image("v2/trainingUI/stats_bkg.png", cx, cy, width, 52 * scale)
    local left = cx - width / 2
    local start = left + width * .04
    local offset = width * .23
    local icon = 41 * scale
    local pictures = {"health", "damage", "defence", "mana"}
    local values = {hero.hp, hero.attack, hero.defense, hero.magic}
    for i = 1, 4 do
        local x = start + (i - 1) * offset
        image("v2/introUI/" .. pictures[i] .. ".png", x + icon / 2, cy, icon, icon)
        label(tostring(values[i]), x + icon + width * .01, cy, 18, {255, 246, 219})
    end
end

local CATEGORY = {["神"] = 1, ["妖"] = 2, ["人"] = 3, ["魔"] = 4, ["佛"] = 5}

local function drawSoulPanel(result)
    if not result.soul_gain or result.soul_gain <= 0 then return end
    image("v2/summonUI/soul_bkg.png", 115.2, 302.4, 117.75, 245.25)
    local heroInfo = lineupData and lineupData.heroes[tostring(result.hero.id)]
    local icon = heroInfo and heroInfo.icon or (byId[result.hero.id] and byId[result.hero.id].icon)
    if icon then atlas(icon, 115.2, 361.8, 86, nil, 86) end
    label(result.hero.name, 115.2, 307.8, 18, {255, 235, 190}, nil, true)
    image("v2/summonUI/get_soul.png", 115.2, 275.4, 103.7, 27.6)
    label("X" .. result.soul_gain, 115.2, 237.6, 19, {240, 201, 46}, nil, true)
    label("共有 " .. result.soul_total, 115.2, 210.6, 18, GOLD, nil, true)
end

local function drawResult()
    local result = M.result
    local hero = result.hero
    image("v2/summonUI/" .. ({[1] = "normal_bkg.jpg", [2] = "advance_bkg.jpg",
                             [3] = "super_bkg.jpg"})[result.grade], 480, 270, 960, 540)
    -- Original getSummonResult(): body anchored at .5/.2 and normalised to 512.
    local sprite = CCSprite:create(hero.sprite)
    if sprite then
        sprite:setScale(540 / 512)
        sprite:setAnchorPoint(CCPointMake(.5, 0))
        sprite:setPosition(CCPointMake(480, 108))
        root:addChild(sprite, 1)
    end
    drawStatsBar(hero, 480, 97.2, .75)
    image("v2/charPositionUI/type_" .. (CATEGORY[hero.category] or 1) .. ".png",
          268.8, 97.2, 25.5, 25.5)
    local heroInfo = lineupData and lineupData.heroes[tostring(hero.id)]
    if heroInfo and heroInfo.name_icon then
        -- Native 100 x 100 atlas cell: no upscaling, so the name stays sharp.
        atlas(heroInfo.name_icon, 316.8, 302.4, 100, nil, 100)
    else
        label(hero.name, 316.8, 302.4, 26, {255, 235, 190}, nil, true)
    end
    local stars = CCSprite:create("v2/CharaterUI/stars.png")
    stars:setTextureRect(CCRectMake(0, 0, 22, 20 * hero.quality))
    stars:setScale(.75)
    stars:setPosition(CCPointMake(288, 302.4))
    root:addChild(stars)
    local entry = byId[hero.id]
    if entry and #entry.fates > 0 then
        image("v2/introUI/yuanfen_label.png", 844.8, 378, 97.5, 60)
        for i, fate in ipairs(entry.fates) do
            if i > 6 then break end
            label(fate.name, 850, 330 - (i - 1) * 22, 12, {190, 180, 160}, nil, false, 100)
        end
    end
    drawSoulPanel(result)
    if not result.new then
        label("重复神仙 · 获得 " .. result.soul_gain .. " 魂魄",
              480, 486, 20, {233, 184, 151}, nil, true)
    end
    image("v2/summonUI/detail1.png", 384, 42, 136.5, 67.5)
    image("v2/summonUI/continue1.png", 576, 42, 136.5, 67.5)
end

local function drawResultDetail()
    local hero = M.result.hero
    local entry = byId[hero.id]
    fill(0, 0, 960, 540, {0, 0, 0, 255})
    image("v2/introUI/intro_bkg.png", 480, 270, 760, 430)
    label(hero.name, 480, 456, 30, {255, 235, 190}, nil, true)
    label(hero.quality .. "星 · " .. hero.category .. " · " .. hero.skill_name,
          480, 424, 17, {255, 215, 172}, nil, true)
    local body = "【简介】\n" .. (hero.description or "暂无介绍")
    body = body .. "\n\n【原生技能 · " .. hero.skill_name .. "】\n" ..
           (entry and entry.skill_description or "")
    if entry and #entry.fates > 0 then
        body = body .. "\n\n【仙缘】"
        for i, fate in ipairs(entry.fates) do
            if i > 5 then break end
            body = body .. "\n" .. fate.name .. "：" .. fate.description
        end
    end
    local text = CCLabelTTF:create(body, "Arial", 16, CCSizeMake(670, 0), kCCTextAlignmentLeft)
    text:setAnchorPoint(CCPointMake(0, 1))
    text:setColor(ccc3(unpack(GOLD)))
    text:setPosition(CCPointMake(145, 400))
    root:addChild(text)
    label("点击任意位置返回", 480, 105, 14, {190, 180, 160}, nil, true)
end

function M.reveal(result)
    M.result = result
    M.resultDetail = nil
end

function M.draw(context, player)
    ui, state, root = context, player, context.root
    M.scroll = nil
    drawFrame()
    drawHeader()
    drawTitle()
    drawNews()
    drawCards()
    drawLast()
    if M.result then
        if M.resultDetail then
            drawResultDetail()
        else
            drawResult()
        end
    end
    if ui.error and not ui.busy then
        label(ui.error, 480, 270, 16, {255, 130, 110}, nil, true)
    end
end

function M.open()
    M.result = nil
    M.resultDetail = nil
    M.offset = 0
end

function M.back()
    if M.resultDetail then
        M.resultDetail = nil
        ui.render()
    elseif M.result then
        M.result = nil
        ui.render()
    else
        ui.navigate("home")
    end
end

function M.touch(event, x, y)
    if M.resultDetail then
        if event == CCTOUCHENDED or event == "ended" then
            M.resultDetail = nil
            ui.render()
        end
        return true
    end
    if M.result then
        if event == CCTOUCHENDED or event == "ended" then
            if x >= 315.75 and x <= 452.25 and y >= 8 and y <= 76 then
                M.resultDetail = true
            else
                M.result = nil
            end
            ui.render()
        end
        return true
    end
    local s = M.scroll
    if not s then return false end
    if event == CCTOUCHBEGAN or event == "began" then
        if x >= s.x and x <= s.x + s.w and y >= s.y and y <= s.y + s.h then
            M.gesture = {y = y, offset = s.offset, dragged = false}
            return true
        end
    elseif M.gesture then
        local g = M.gesture
        if event == CCTOUCHMOVED or event == "moved" then
            if math.abs(y - g.y) > 7 then g.dragged = true end
            if g.dragged then
                setOffset(g.offset - (y - g.y))
                M.offset = s.offset
            end
        elseif event == CCTOUCHENDED or event == "ended" then
            M.gesture = nil
        else
            M.gesture = nil
        end
        return true
    end
    return false
end

return M

