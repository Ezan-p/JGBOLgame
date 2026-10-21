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

local function vertical(value, x, top, size, color)
    local chars = {}
    for ch in string.gmatch(value, "[%z\1-\127\194-\244][\128-\191]*") do
        table.insert(chars, ch)
    end
    local node = label(table.concat(chars, "\n"), x, top, size, color, nil, true)
    node:setAnchorPoint(CCPointMake(.5, 1))
    return node
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
    local panel = image("v2/introUI/introBkg2.png", 240, 337, 350, 352)
    if panel then panel:setColor(ccc3(96, 72, 54)) end
    local floor = image("v2/introUI/floorHighLight.png", 246, 190, 330, 150)
    if floor then
        floor:setColor(ccc3(214, 174, 116))
        floor:setOpacity(120)
    end

    local category = {["神"] = 1, ["妖"] = 2, ["人"] = 3, ["魔"] = 4, ["佛"] = 5}
    image("v2/charPositionUI/type_" .. (category[entry.category] or 1) .. ".png",
          52, 486, 30, 30)

    if entry.name_icon then
        atlas(entry.name_icon, 58, 356, 34, 140)
    else
        vertical(entry.name, 58, 426, 21, GOLD)
    end
    local stars = image("v2/CharaterUI/stars.png", 88, 424, 13, 60)
    if stars then
        stars:setTextureRect(CCRectMake(0, 0, 22, 20 * (entry.quality or 1)))
    end

    local node = CCSprite:create(entry.sprite)
    if node then
        local size = node:getContentSize()
        node:setScale(math.min(300 / size.width, 300 / size.height))
        node:setAnchorPoint(CCPointMake(.5, 0))
        node:setPosition(CCPointMake(250, 174))
        root:addChild(node)
    end

    local values = {hero and hero.hp or entry.hp, hero and hero.attack or entry.attack,
                    hero and hero.defense or entry.defense, hero and hero.magic or entry.magic}
    local icons = {"health", "damage", "defence", "mana"}
    local sx, sy, sw = 250, 181, 340
    image("v2/introUI/property_bkg.png", sx, sy, sw, 20)
    for i = 1, 4 do
        local xx = sx - sw / 2 + (i - 1) * sw / 4 + 14
        image("v2/introUI/" .. icons[i] .. ".png", xx, sy, 19, 19)
        label(values[i] or 0, xx + 12, sy, 14, GOLD)
    end

    local level = hero and hero.level or 1
    image("v2/charPositionUI/level_bkg.png", 52, 157, 38, 24)
    label(level, 52, 157, 16, GOLD, nil, true)
    local bx, bw = 76, 340
    image("v2/CharaterUI/expbar1.png", bx + bw / 2, 157, bw, 14)
    local ratio = hero and math.min(1, level / 20) or 0
    if ratio > 0 then
        local fillNode = CCSprite:create("v2/CharaterUI/expbar2.png")
        if fillNode then
            local size = fillNode:getContentSize()
            fillNode:setAnchorPoint(CCPointMake(0, .5))
            fillNode:setScaleX(bw * ratio / size.width)
            fillNode:setScaleY(14 / size.height)
            fillNode:setPosition(CCPointMake(bx, 157))
            root:addChild(fillNode)
        end
    end
    label("等级 " .. level .. " / 20", bx + bw / 2, 157, 11, PALE, nil, true)

    local function artButton(file, x, w, action, enabled)
        local node = image(file, x, 112, w, 40)
        if not enabled and node then node:setColor(ccc3(115, 105, 95)) end
        ui.hit(x - w / 2, 92, w, 40, action, enabled, node)
    end

    if hero then
        local cost = hero.upgrade_cost or (80 * level)
        artButton("v2/trainingUI/training1.png", 150, 160, opts.onTrain,
                  level < 20 and state.silver >= cost)
        artButton("v2/buttons/inherit1.png", 325, 160, opts.onInherit, true)
        label(level >= 20 and "已达满级" or ("培养消耗 " .. cost .. " 银两"),
              150, 140, 10, MUTED, nil, true)
    else
        artButton("v2/multi-selectUI/back1.png", 150, 160, opts.onBack, true)
        local recruit = image("v2/soulExchangeUI/btn_bkg1.png", 325, 112, 160, 40)
        label("招募 · 600 银两", 325, 112, 16, GOLD, nil, true)
        ui.hit(245, 92, 160, 40, opts.onRecruit, state.silver >= 600, recruit)
        label("招募消耗 600 银两", 325, 140, 10, MUTED, nil, true)
    end

    local close = image("v2/introUI/close1.png", 917, 509, 44, 42)
    ui.hit(895, 488, 44, 42, opts.onClose, true, close)
end

local function drawRight(opts)
    local entry, hero = opts.entry, opts.hero
    local fates = (hero and hero.fates) or entry.fates or {}
    local skill = skillFor(entry, opts.spells)
    local descWidth = CW - 54
    local titleH = 44
    local need = 8 + titleH + 12
    for _, fate in ipairs(fates) do
        need = need + 22 + measure(fate.description or "", 15, descWidth) + 12
    end
    if #fates == 0 then need = need + 40 end
    need = need + 14 + titleH + 8
    local talentText = entry.skill_description or (skill and skill.description) or ""
    need = need + math.max(78, 28 + measure(talentText, 15, CW - 118)) + 18
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
        image("v2/introUI/small_label.png", CW / 2, y - titleH / 2, 250, titleH, container)
        image(file, CW / 2, y - titleH / 2, width, height, container)
        y = y - titleH - 12
    end

    title("v2/introUI/yuanfen_label.png", 58, 35)
    if #fates == 0 then
        label("暂无仙缘", 30, y, 16, MUTED, container, false, descWidth)
        y = y - 40
    end
    for _, fate in ipairs(fates) do
        local active = fate.active
        local nameColor = active == false and DIMMED or GOLD
        local descColor = active == false and {188, 168, 142} or PALE
        local dot = image("v2/CharaterUI/hongdian.png", 16, y - 9, 9, 9, container)
        if dot then
            if active then dot:setColor(ccc3(132, 226, 104))
            elseif active == false then dot:setColor(ccc3(112, 88, 66)) end
        end
        label(fate.name, 30, y, 19, nameColor, container)
        local desc = label(fate.description or "", 30, y - 24, 15, descColor,
                           container, false, descWidth)
        y = y - 24 - desc:getContentSize().height - 12
    end

    y = y - 14
    image("v2/introUI/small_label.png", CW / 2, y - titleH / 2, 250, titleH, container)
    image("v2/introUI/talent_label.png", CW / 2, y - titleH / 2, 52, 33, container)
    y = y - titleH - 8

    if skill then
        image("v2/charPositionUI/frame1.png", 49, y - 37, 80, 80, container)
        atlas(skill.icon, 49, y - 37, 72, 72, container)
        label(entry.skill_name or skill.name, 94, y, 21, GOLD, container)
        local desc = label(talentText, 94, y - 28, 15, PALE, container, false, CW - 118)
        y = y - 28 - desc:getContentSize().height
    else
        label("暂无天赋", 30, y - 8, 16, MUTED, container, false, descWidth)
        y = y - 40
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
