-- Hero detail page reconstructed from the original formationUI detail layer.
-- Left: portrait, vertical name, stars, level, stats and training/inherit
-- (read-only catalogue entries show the original "back" button instead).
-- Right: a clipped vertical scroller with the original fate list and talent.
local D = {offsets = {}}
local ui, state, root
local GOLD = {255, 226, 163}
local PALE = {238, 226, 202}
local MUTED = {176, 148, 115}
local DIMMED = {168, 142, 112}
local CX, CY, CW, CH = 474, 108, 442, 392

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
        node = CCLabelTTF:create(tostring(value), "Arial", size, CCSizeMake(width, 0),
                                 kCCTextAlignmentLeft)
    else
        node = CCLabelTTF:create(tostring(value), "Arial", size)
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

local function measure(value, size, width)
    local node = CCLabelTTF:create(tostring(value), "Arial", size, CCSizeMake(width, 0),
                                   kCCTextAlignmentLeft)
    return node:getContentSize().height
end

local function vertical(value, x, y, size, color)
    local chars = {}
    for ch in string.gmatch(value, "[%z\1-\127\194-\244][\128-\191]*") do
        table.insert(chars, ch)
    end
    return label(table.concat(chars, "\n"), x, y, size, color, nil, true)
end

local function skillFor(entry, spells)
    if not spells then return nil end
    for _, spell in ipairs(spells) do
        if spell.id == entry.skill_id then return spell end
    end
end

local function frame()
    image("v2/packageUI/board_chain.png", 221, 525, 76, 235):setAnchorPoint(CCPointMake(.5, 0))
    image("v2/packageUI/board_chain.png", 730, 525, 76, 235):setAnchorPoint(CCPointMake(.5, 0))
    fill(24, 86.4, 912, 432, {39, 24, 19, 255})
    image("v2/introUI/intro_bkg.png", 480, 302.4, 912, 432)
    image("v2/packageUI/board_edge1.png", 24, 302.4, 15, 432)
    local right = image("v2/packageUI/board_edge1.png", 936, 302.4, 15, 432)
    if right then right:setFlipY(true) end
    image("v2/packageUI/board_edge2.png", 480, 514.1, 930, 37.2)
    local bottom = image("v2/packageUI/board_edge2.png", 480, 90.7, 930, 37.2)
    if bottom then bottom:setFlipY(true) end
    fill(CX, CY, CW, CH, {20, 12, 8, 70})
end

local function setOffset(value)
    local s = D.scroll
    if not s then return end
    s.offset = math.max(0, math.min(s.max, value))
    s.node:setPositionY(s.offset)
    D.offsets[s.key] = s.offset
    if s.thumb then
        local span = math.max(1, s.h - s.thumbHeight)
        s.thumb:setPositionY(s.y + s.h - s.thumbHeight -
            (s.max > 0 and s.offset / s.max or 0) * span)
    end
end

local function drawLeft(opts)
    local entry, hero = opts.entry, opts.hero
    -- Original detail ratios (1280x720): backdrop center .259375/.5 and size
    -- .212/.799; name x .084375, stars/category x .05625, category y .875.
    -- The local 912x432 board keeps the same left-section order and fits all
    -- labels inside the original rounded frame.
    image("v2/charPositionUI/mid_frame.png", 245, 322, 410, 368)
    local panel = image("v2/introUI/introBkg2.png", 245, 322, 394, 352)
    if panel then panel:setColor(ccc3(88, 66, 50)) end
    local floor = image("v2/introUI/floorHighLight.png", 273, 190, 320, 150)
    if floor then
        floor:setColor(ccc3(214, 174, 116))
        floor:setOpacity(120)
    end

    local category = {["神"] = 1, ["妖"] = 2, ["人"] = 3, ["魔"] = 4, ["佛"] = 5}

    -- Original loadCharacterInfo scales by screen height (0.6 * 720) and lets
    -- wide poses overflow the backdrop horizontally. Clip to the inner frame so
    -- the weapon cannot cover the right-hand fate panel.
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

    image("v2/charPositionUI/type_" .. (category[entry.category] or 1) .. ".png",
          62, 484, 30, 30)

    local stars = image("v2/CharaterUI/stars.png", 68, 400, 13, 65)
    if stars then
        stars:setTextureRect(CCRectMake(0, 0, 22, 20 * (entry.quality or 1)))
    end
    if entry.name_icon then
        atlas(entry.name_icon, 94, 400, 34, 140)
    else
        vertical(entry.name, 94, 400, 21, GOLD)
    end

    local values = {hero and hero.hp or entry.hp, hero and hero.attack or entry.attack,
                    hero and hero.defense or entry.defense, hero and hero.magic or entry.magic}
    local icons = {"health", "damage", "defence", "mana"}
    -- Original trainingUI.createCharaterStatsBar: 514x52 bar, four 41px icons,
    -- font 25, start 4%, step 23%. Keep those ratios at a 330px local bar.
    local sx, sy, sw = 250, 196, 330
    local bs = sw / 514
    local sh = 52 * bs
    image("v2/trainingUI/stats_bkg.png", sx, sy, sw, sh)
    local left = sx - sw / 2
    local start, offset, isz = 514 * 0.04 * bs, 514 * 0.23 * bs, 41 * bs
    for i = 1, 4 do
        local xx = left + start + offset * (i - 1)
        image("v2/introUI/" .. icons[i] .. ".png", xx + isz / 2, sy, isz, isz)
        label(values[i] or 0, xx + isz + 0.01 * sw, sy, 16, GOLD)
    end

    local level = hero and hero.level or 1
    image("v2/charPositionUI/level_bkg.png", 58, 166, 38, 24)
    label(level, 58, 166, 16, GOLD, nil, true)
    local bx, bw = 82, 332
    image("v2/CharaterUI/expbar1.png", bx + bw / 2, 166, bw, 14)
    local ratio = hero and math.min(1, level / 20) or 0
    if ratio > 0 then
        local fillNode = CCSprite:create("v2/CharaterUI/expbar2.png")
        if fillNode then
            local size = fillNode:getContentSize()
            fillNode:setAnchorPoint(CCPointMake(0, .5))
            fillNode:setScaleX(bw * ratio / size.width)
            fillNode:setScaleY(14 / size.height)
            fillNode:setPosition(CCPointMake(bx, 166))
            root:addChild(fillNode)
        end
    end
    label("等级 " .. level .. " / 20", bx + bw / 2, 166, 11, PALE, nil, true)

    local function artButton(file, x, w, action, enabled, h)
        h = h or 40
        local node = image(file, x, 112, w, h)
        if not enabled and node then node:setColor(ccc3(115, 105, 95)) end
        ui.hit(x - w / 2, 112 - h / 2, w, h, action, enabled, node)
    end

    if hero then
        artButton("v2/trainingUI/training1.png", 170, 150, opts.onTrain, true, 50)
        artButton("v2/buttons/inherit1.png", 330, 150, opts.onInherit, true, 50)
    else
        local back = image("v2/multi-selectUI/back1.png", 245, 112, 190, 40)
        ui.hit(150, 92, 190, 40, opts.onBack, true, back)
    end

    local close = image("v2/introUI/close1.png", 917, 509, 44, 42)
    ui.hit(895, 488, 44, 42, opts.onClose, true, close)
end

local function drawRight(opts)
    local entry, hero = opts.entry, opts.hero
    local fates = (hero and hero.fates) or entry.fates or {}
    local skill = skillFor(entry, opts.spells)
    local descWidth = CW - 54
    local titleH = 32
    local nameSize, descSize = 22, 19
    local nameGap, itemGap = 6, 8
    local talentText = entry.skill_description or (skill and skill.description) or ""
    local talentName = entry.skill_name or (skill and skill.name) or ""
    local items = {}
    local need = 8 + titleH + 4
    for _, fate in ipairs(fates) do
        local item = {fate = fate, nameH = measure(fate.name, nameSize, descWidth),
                      descH = measure(fate.description or "", descSize, descWidth)}
        table.insert(items, item)
        need = need + item.nameH + nameGap + item.descH + itemGap
    end
    if #items == 0 then need = need + 30 end
    local talentNameH = measure(talentName, nameSize, CW - 118)
    local talentDescH = measure(talentText, descSize, CW - 118)
    need = need + 8 + titleH + 4 + math.max(70, talentNameH + nameGap + talentDescH) + 16
    need = need + 14 + titleH + 4 + 4 * 32 + 14
    local total = math.max(CH, need)

    local container = CCLayer:create()
    container:setContentSize(CCSizeMake(CW, total))
    local view = CCScrollView:create(CCSizeMake(CW * root:getScaleX(), CH * root:getScaleY()),
                                     container)
    view:setTouchEnabled(false)
    view:setPosition(CCPointMake(CX, CY))
    root:addChild(view)
    D.scroll = {node = container, x = CX, y = CY, w = CW, h = CH,
                max = total - CH, key = "hero-" .. entry.id .. (hero and "-owned" or "-book"),
                offset = 0}

    local y = CH - 8
    local function title(file, width, height)
        image("v2/introUI/small_label.png", CW / 2, y - titleH / 2, 220, titleH, container)
        image(file, CW / 2, y - titleH / 2, width, height, container)
        y = y - titleH - 4
    end

    title("v2/introUI/yuanfen_label.png", 52, 32)
    if #items == 0 then
        label("暂无仙缘", 30, y, 17, MUTED, container, false, descWidth)
        y = y - 30
    end
    for _, item in ipairs(items) do
        local fate = item.fate
        local active = fate.active
        local nameColor = active == false and DIMMED or GOLD
        local descColor = active == false and {188, 168, 142} or PALE
        local nameCenter = y - item.nameH / 2
        local dot = image("v2/CharaterUI/hongdian.png", 16, nameCenter, 9, 9, container)
        if dot then
            if active then dot:setColor(ccc3(132, 226, 104))
            elseif active == false then dot:setColor(ccc3(112, 88, 66)) end
        end
        label(fate.name, 30, nameCenter, nameSize, nameColor, container)
        local descTop = y - item.nameH - nameGap
        label(fate.description or "", 30, descTop, descSize, descColor,
              container, false, descWidth)
        y = descTop - item.descH - itemGap
    end

    y = y - 8
    image("v2/introUI/small_label.png", CW / 2, y - titleH / 2, 220, titleH, container)
    image("v2/introUI/talent_label.png", CW / 2, y - titleH / 2, 46, 29, container)
    y = y - titleH - 4

    if skill then
        image("v2/charPositionUI/frame1.png", 49, y - 35, 78, 78, container)
        atlas(skill.icon, 49, y - 35, 70, 70, container)
        label(talentName, 94, y - talentNameH / 2, nameSize, GOLD, container)
        local descTop = y - talentNameH - nameGap
        label(talentText, 94, descTop, descSize, PALE, container, false, CW - 118)
        y = descTop - talentDescH
    else
        label("暂无天赋", 30, y - 8, 17, MUTED, container, false, descWidth)
        y = y - 40
    end

    -- Original intro_label_ql = 成长潜力. Four progress rows use the original
    -- property_bkg/property_up bars, normalized by the maximum growth of all
    -- 166 heroes for each attribute.
    y = y - 14
    image("v2/introUI/small_label.png", CW / 2, y - titleH / 2, 220, titleH, container)
    image("v2/introUI/intro_label_ql.png", CW / 2, y - titleH / 2, 96, 28, container)
    y = y - titleH - 4
    local growth = entry.growth or {}
    local growthMax = opts.growth_max or {}
    local growthRows = {
        {key = "hp", icon = "health", text = "生命"},
        {key = "attack", icon = "damage", text = "攻击"},
        {key = "defense", icon = "defence", text = "防御"},
        {key = "magic", icon = "mana", text = "法力"},
    }
    for _, row in ipairs(growthRows) do
        local cy = y - 16
        image("v2/introUI/" .. row.icon .. ".png", 18, cy, 20, 20, container)
        label(row.text, 32, cy, 15, GOLD, container)
        local barX, barW, barH = 76, 268, 14
        image("v2/introUI/property_bkg.png", barX + barW / 2, cy, barW, barH, container)
        local value = tonumber(growth[row.key]) or 0
        local maximum = tonumber(growthMax[row.key]) or 0
        local ratio = maximum > 0 and math.min(1, value / maximum) or 0
        if ratio > 0 then
            local up = CCSprite:create("v2/introUI/property_up.png")
            if up then
                local size = up:getContentSize()
                up:setAnchorPoint(CCPointMake(0, .5))
                up:setScaleX(barW * ratio / size.width)
                up:setScaleY(barH / size.height)
                up:setPosition(CCPointMake(barX, cy))
                container:addChild(up)
            end
        end
        local valueLabel = label("+" .. tostring(value) .. "/级", 430, cy, 14, GOLD, container)
        valueLabel:setAnchorPoint(CCPointMake(1, .5))
        y = y - 32
    end

    local thumbHeight = math.max(24, CH * CH / total)
    fill(CX + CW + 4, CY, 3, CH, {65, 43, 29, 220})
    D.scroll.thumbHeight = thumbHeight
    D.scroll.thumb = fill(CX + CW + 4, CY + CH - thumbHeight, 3, thumbHeight,
                          {170, 124, 67, 235})
    setOffset(D.offsets[D.scroll.key] or 0)
end

function D.draw(opts)
    ui, state, root = opts.ui, opts.state, opts.root
    D.current = opts
    D.scroll = nil
    D.gesture = nil
    frame()
    drawLeft(opts)
    drawRight(opts)
    if D.modal then
        fill(0, 0, 960, 540, {0, 0, 0, 180})
        image("v2/charPositionUI/max_bkg.png", 480, 300, 640, 330)
        image("v2/introUI/small_label.png", 480, 438, 520, 52)
        label(D.modal[1], 480, 438, 25, GOLD, nil, true)
        label(D.modal[2], 170, 400, 17, PALE, nil, false, 620)
        image("v2/multi-selectUI/back1.png", 480, 140, 190, 56)
        label("点击任意处关闭", 480, 112, 13, MUTED, nil, true)
    end
end

function D.touch(event, x, y)
    if not D.current then return false end
    if D.modal then
        if event == CCTOUCHENDED or event == "ended" then
            D.modal = nil
            D.current.ui.render()
        end
        return true
    end
    local s = D.scroll
    if not s then return false end
    local began = event == CCTOUCHBEGAN or event == "began"
    local moved = event == CCTOUCHMOVED or event == "moved"
    local ended = event == CCTOUCHENDED or event == "ended"
    if began then
        if x >= 895 and x <= 939 and y >= 488 and y <= 530 then return false end
        if x >= s.x and x <= s.x + s.w and y >= s.y and y <= s.y + s.h then
            D.gesture = {x = x, y = y, offset = s.offset}
            return true
        end
        return false
    end
    if D.gesture then
        local g = D.gesture
        if moved then
            if math.abs(y - g.y) > 5 or math.abs(x - g.x) > 5 then g.dragged = true end
            if g.dragged then setOffset(g.offset + (y - g.y)) end
        else
            D.gesture = nil
        end
        return true
    end
    return false
end

function D.showInfo(title, body)
    D.modal = {title, body}
    if D.current then D.current.ui.render() end
end

function D.closeInfo()
    if not D.modal then return false end
    D.modal = nil
    return true
end

function D.reset()
    D.current = nil
    D.scroll = nil
    D.gesture = nil
    D.modal = nil
    D.offsets = {}
end

return D
