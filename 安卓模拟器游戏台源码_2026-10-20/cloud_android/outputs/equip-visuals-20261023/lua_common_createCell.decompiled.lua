local createCell = {}
d_ms = require("ms")
local m_t = d_ms.d_common_def.item_main_type
local o_t = d_ms.d_common_def.object_type
local scrSize = CCDirector:sharedDirector():getVisibleSize()
local space = 0.04 * scrSize.width

local function createSkillLabel(parent, level, type_id, position)
	d_ms.d_skillUpgradeUI.initSkillCsv()

	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local effect_type = d_ms.d_skillUpgradeUI.g_self.csv_map_skill[type_id]
	local pro = 0
	local powerSprite = nil
	local itemInfo_level = level

	if effect_type[8] == "1" then
		powerSprite = CCSprite:create("v2/introUI/damage.png")
		local num = tonumber(effect_type[9]) + tonumber(effect_type[13]) * (itemInfo_level - 1)
		num = string.format("%.1f", num)
		pro = num .. "%"
	elseif effect_type[8] == "2" then
		powerSprite = CCSprite:create("v2/introUI/defence.png")
		local num = tonumber(effect_type[10]) + tonumber(effect_type[13]) * (itemInfo_level - 1)
		num = string.format("%.1f", num)
		pro = num .. "%"
	elseif effect_type[8] == "3" then
		powerSprite = CCSprite:create("v2/introUI/mana.png")
		local num = tonumber(effect_type[11]) + tonumber(effect_type[13]) * (itemInfo_level - 1)
		num = string.format("%.1f", num)
		pro = num .. "%"
	else
		powerSprite = CCSprite:create("v2/introUI/skill_strong.png")
		pro = math.floor(tonumber(effect_type[12]) + tonumber(effect_type[13]) * (itemInfo_level - 1))
	end

	local powerLabel = d_ms.d_u.createByStyle({
		font = "arial",
		fontsize = 26,
		type = "label",
		string = pro
	})

	powerSprite:setPosition(position)
	powerLabel:setPosition(position.x + space, position.y)
	powerLabel:setAnchorPoint(ccp(0, 0.5))
	powerLabel:setColor(ccc3(253, 190, 37))
	powerSprite:setAnchorPoint(ccp(0, 0.5))
	parent:addChild(powerSprite, 5)
	parent:addChild(powerLabel, 5)

	return powerLabel
end

local function createStoneLabel(parent, level, type_id, position)
	local type = d_ms.d_stoneUI.getStoneTypeByID(type_id)
	local attrTable = d_ms.d_data.g_stoneAttrTable[type]
	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local plus_type = {
		"v2/introUI/damage.png",
		"v2/introUI/defence.png",
		"v2/introUI/health.png"
	}
	local powerSprite = CCSprite:create(plus_type[type])

	powerSprite:setPosition(position)
	powerSprite:setAnchorPoint(ccp(0, 0.5))

	local powerStr = string.format("%.1f", attrTable[level].base * 100) .. "%"
	local powerLabel = d_ms.d_u.createByStyle({
		font = "arial",
		fontsize = 26,
		type = "label",
		string = powerStr
	})

	powerLabel:setPosition(position.x + space, position.y)
	powerLabel:setAnchorPoint(ccp(0, 0.5))
	powerLabel:setColor(ccc3(253, 190, 37))
	parent:addChild(powerSprite, 5)
	parent:addChild(powerLabel, 5)

	return powerLabel
end

createCell.createSkillLabel = createSkillLabel

local function createItemIntro(parent, info, isShowBtn)
	local introLayer = nil

	function closeIntroCallback(tag)
		local buttonType = d_ms.d_packageUI.g_introButtonType

		local function suicide()
			if introLayer ~= nil then
				introLayer:getParent():removeChild(introLayer, true)

				introLayer = nil
			end
		end

		if tag == buttonType.enhance then
			if d_ms.d_equipmentUpgradeUI.checkEquipmentCanUpgrade(true, info.level, info.csvInfo.quality) == 2 then
				return
			end

			suicide()
			d_ms.d_equipmentUpgradeUI.showEnhanceLayer(parent, info, 40)
		elseif tag == buttonType.slot then
			if d_ms.d_stoneUI.canJoin(true) then
				suicide()
				d_ms.d_stoneUI.showStoneLayer(parent, 40, info)
			end
		elseif tag == buttonType.stoneUpgrade then
			if d_ms.d_stoneUpgradeUI.canUpgrade(info, true) then
				suicide()
				d_ms.d_stoneUpgradeUI.show(parent, 40, info)
			end
		elseif tag == buttonType.enhanceSkill then
			if info.upgrade_level and info.upgrade_level ~= 0 then
				d_ms.d_info.show(d_ms.d_hz.gethz("advance16"))
			elseif info.level < 10 then
				d_ms.d_info.show(d_ms.d_hz.gethz("advance15"))
			else
				suicide()

				local params = {
					parent_layer = parent,
					skill_info = info,
					from_btn = 101
				}

				d_ms.d_skillUpgradeUI.show(params)
			end
		elseif tag == buttonType.advance then
			if not d_ms.d_equipAdvanceUI.canJoin(true) then
				return
			end

			suicide()
			d_ms.d_equipAdvanceUI.showAdvanceLayer(parent, 40, info)
		elseif tag == buttonType.handbook then
			suicide()
			d_ms.d_packageUI.pressHandBook(info.attach_type)
		else
			suicide()
		end
	end

	introLayer = d_ms.d_packageUI.createItemIntroLayer(info, closeIntroCallback, isShowBtn)

	parent:addChild(introLayer, 300)
end

local function _createCell(parent, info, bkgPic, contentSize, isShowBtn)
	local parentNode = parent or CCNode:create()
	local bkgSprite = CCSprite:create(bkgPic)

	bkgSprite:setPosition(ccp(contentSize.width * 0.5, contentSize.height * 0.5))
	parentNode:addChild(bkgSprite, -1)

	local bkgScaleX = contentSize.width / bkgSprite:getContentSize().width

	bkgSprite:setScaleX(bkgScaleX)

	local object_type = info.attach_type or info.object_type
	local type_id = info.type_id or info.type
	local csvInfo = info.csvInfo or d_ms.d_data.getCertainInfo(object_type, type_id)
	local main_type = csvInfo.mainType
	local quality = csvInfo.quality
	local nameLabel = d_ms.d_u.createByStyle({
		font = "arial",
		fontsize = 30,
		type = "label",
		string = csvInfo.name
	})

	parentNode:addChild(nameLabel, 1)
	nameLabel:setAnchorPoint(ccp(0, 0.5))
	nameLabel:setColor(ccc3(254, 235, 192))
	nameLabel:setPosition(contentSize.width * 0.2, contentSize.height * 0.7)

	if object_type == o_t.item and main_type <= m_t.talismans and info.advance_level and info.advance_level > 0 then
		local advanceSprite = CCSprite:create("v2/equipAdvanceUI/ad" .. info.advance_level .. ".png")

		advanceSprite:setAnchorPoint(ccp(-0.1, 0.5))
		advanceSprite:setPosition(contentSize.width * 0.2 + nameLabel:getContentSize().width, contentSize.height * 0.7)
		parentNode:addChild(advanceSprite, 2)
	end

	if quality and quality > 0 and (object_type ~= o_t.item or main_type <= m_t.talismans) then
		local qualityRatio = csvInfo.quality / 5
		local starsLevelSprite = CCSprite:create("v2/introUI/stars.png")

		parentNode:addChild(starsLevelSprite, 1)
		starsLevelSprite:setPosition(contentSize.width * 0.5, contentSize.height * 0.7)
		starsLevelSprite:setAnchorPoint(ccp(0, 0.5))

		local starsContentSize = starsLevelSprite:getContentSize()

		starsLevelSprite:setTextureRect(CCRectMake(0, 0, starsContentSize.width * qualityRatio, starsContentSize.height))
	end

	local level = info.level

	if main_type and m_t.talismans < main_type and main_type ~= m_t.stone and info.count then
		local count = d_ms.d_hz.gethz("number") .. ": " .. info.count
		local countLabel = d_ms.d_u.createByStyle({
			font = "arial",
			fontsize = 30,
			type = "label",
			string = tostring(count)
		})

		countLabel:setPosition(contentSize.width * 0.2, contentSize.height * 0.3)
		parentNode:addChild(countLabel)
		countLabel:setAnchorPoint(ccp(0, 0.5))
		countLabel:setColor(ccc3(253, 190, 37))
	elseif level then
		local levelSprite = CCSprite:create("v2/packageUI/level.png")

		levelSprite:setPosition(contentSize.width * 0.2, contentSize.height * 0.3)
		levelSprite:setAnchorPoint(ccp(0, 0.5))
		parentNode:addChild(levelSprite)

		local levelLabel = d_ms.d_u.createByStyle({
			font = "arial",
			fontsize = 30,
			type = "label",
			string = tostring(level)
		})

		parentNode:addChild(levelLabel)

		local spritePos = levelSprite:getPositionLua()

		levelLabel:setPosition(spritePos.x + space, spritePos.y)
		levelLabel:setAnchorPoint(ccp(0, 0.5))
		levelLabel:setColor(ccc3(253, 190, 37))
	end

	local power = info.effect_value

	if object_type and (object_type == o_t.item or object_type == o_t.skill) then
		local powerSpritePos = ccp(contentSize.width * 0.38, contentSize.height * 0.3)
		local powerLabelPos = ccp(powerSpritePos.x + space, powerSpritePos.y)

		if object_type == o_t.item and main_type and (main_type <= m_t.talismans or main_type == m_t.stone) then
			local powerSprite = nil
			local isShowPowerLabel = false
			local plus_types = {
				"CHAR_gong",
				"CHAR_fang",
				"CHAR_ming"
			}

			if main_type ~= m_t.stone then
				powerSprite = CCSprite:create("v2/packageUI/" .. plus_types[main_type] .. ".png")
			else
				powerSprite = CCSprite:create("v2/packageUI/" .. plus_types[info.csvInfo.sub_type] .. ".png")
			end

			if powerSprite then
				local hz = nil

				if main_type == m_t.stone then
					local attr = d_ms.d_data.g_stoneAttrTable[info.csvInfo.sub_type][info.level].base
					hz = string.format("%.1f", attr * 100) .. "%"
				else
					hz = tostring(power)
				end

				powerLabel = d_ms.d_u.createByStyle({
					font = "arial",
					fontsize = 30,
					type = "label",
					string = hz
				})

				parentNode:addChild(powerLabel)
				powerLabel:setAnchorPoint(ccp(0, 0.5))
				powerLabel:setPosition(powerLabelPos)
				powerLabel:setColor(ccc3(253, 190, 37))
				parentNode:addChild(powerSprite)
				powerSprite:setAnchorPoint(ccp(0, 0.5))
				powerSprite:setPosition(powerSpritePos)
			end
		elseif object_type == o_t.skill then
			local powerLabel = createSkillLabel(parentNode, info.level, info.type_id, powerSpritePos)

			if powerLabel then
				powerLabel:setPosition(powerLabelPos)
			end

			local typeSprite = nil

			if csvInfo.skillType == 1 then
				if csvInfo.attackType == 1 then
					typeSprite = CCSprite:create("v2/newIntroUI/dan.png")
				else
					typeSprite = CCSprite:create("v2/newIntroUI/qun.png")
				end
			else
				typeSprite = CCSprite:create("v2/newIntroUI/bei.png")
			end

			typeSprite:setPosition(contentSize.width * 0.6, contentSize.height * 0.3)
			parentNode:addChild(typeSprite)
		end
	end

	local iconSprite1, iconSprite2 = nil

	if object_type == o_t.item and main_type == m_t.stone then
		iconSprite1 = d_ms.d_data.getSmallItemSprite(type_id, info.level)
		iconSprite2 = d_ms.d_data.getSmallItemSprite(type_id, info.level)
	else
		iconSprite1 = d_ms.d_data.getCertainSmallSprite(object_type, type_id)
		iconSprite2 = d_ms.d_data.getCertainSmallSprite(object_type, type_id)
	end

	if info.upgrade_level and info.upgrade_level ~= 0 then
		local size = iconSprite1:getContentSize()
		local advanceLabel = CCSprite:create("v2/enhanceUI/wu.png")

		iconSprite1:addChild(advanceLabel)
		advanceLabel:setAnchorPoint(ccp(1, 0))
		advanceLabel:setPosition(0.95 * size.width, 0.05 * size.height)
	end

	local function createItemIntroWrap()
		createItemIntro(CCDirector:sharedDirector():getRunningScene(), info, isShowBtn)
	end

	local menuItemsDefs = {
		menuItems = {
			{
				nSprite = iconSprite1,
				sSprite = iconSprite2,
				tapHandler = createItemIntroWrap,
				pos = ccp(contentSize.width * 0.1, contentSize.height * 0.5)
			}
		},
		priority = -128,
		usedDefaultRect = true
	}
	local menuLayer = d_ms.d_tableView.createTableViewMenu(menuItemsDefs)

	parentNode:addChild(menuLayer)

	if object_type == o_t.item and main_type <= m_t.talismans and info.advance_level and info.advance_level > 0 then
		local name, anch = d_ms.d_data.getCcbiByAdvanceLevel(info.advance_level)

		if name then
			local node = d_ms.d_u.createAnimation_new(name, {
				scale = 0.8333333333333334,
				z = 1,
				x = menuItemsDefs.menuItems[1].pos.x / scrSize.width,
				y = menuItemsDefs.menuItems[1].pos.y / scrSize.height
			}, nil, nil, menuLayer)

			node:setAnchorPoint(anch)
		end
	end
end

local function _createCharCell(parent, info, bkgPic, contentSize, introTag)
	local parentNode = parent or CCNode:create()
	local bkgSprite = CCSprite:create(bkgPic)

	bkgSprite:setPosition(ccp(contentSize.width * 0.5, contentSize.height * 0.5))
	parentNode:addChild(bkgSprite, -1)

	local bkgScaleX = contentSize.width / bkgSprite:getContentSize().width

	bkgSprite:setScaleX(bkgScaleX)

	local csvInfo = info.csvInfo or d_ms.d_data.getCertainInfo(object_type, type_id)
	local nameLabel = d_ms.d_u.createByStyle({
		font = "arial",
		fontsize = 30,
		type = "label",
		string = csvInfo.name
	})

	parentNode:addChild(nameLabel, 1)
	nameLabel:setAnchorPoint(ccp(0, 0.5))
	nameLabel:setColor(ccc3(254, 235, 192))
	nameLabel:setPosition(contentSize.width * 0.2, contentSize.height * 0.7)
	nameLabel:setAnchorPoint(CCPointMake(0, 0.5))

	local quality = csvInfo.quality

	if quality and quality > 0 then
		local qualityRatio = csvInfo.quality / 5
		local starsLevelSprite = CCSprite:create("v2/introUI/stars.png")

		parentNode:addChild(starsLevelSprite, 1)
		starsLevelSprite:setPosition(contentSize.width * 0.43, contentSize.height * 0.7)
		starsLevelSprite:setAnchorPoint(ccp(0, 0.5))

		local starsContentSize = starsLevelSprite:getContentSize()

		starsLevelSprite:setTextureRect(CCRectMake(0, 0, starsContentSize.width * qualityRatio, starsContentSize.height))
	end

	local object_type = nil

	if info.isSoul then
		object_type = o_t.spirit
	else
		object_type = o_t.cortege
	end

	if object_type == o_t.cortege then
		local level = info.level

		if level then
			local levelSprite = CCSprite:create("v2/packageUI/level.png")

			levelSprite:setPosition(contentSize.width * 0.2, contentSize.height * 0.3)
			levelSprite:setAnchorPoint(ccp(0, 0.5))
			parentNode:addChild(levelSprite)

			local levelLabel = d_ms.d_u.createByStyle({
				font = "arial",
				fontsize = 30,
				type = "label",
				string = tostring(level)
			})

			parentNode:addChild(levelLabel)

			local spritePos = levelSprite:getPositionLua()

			levelLabel:setPosition(spritePos.x + space, spritePos.y)
			levelLabel:setAnchorPoint(ccp(0, 0.5))
			levelLabel:setColor(ccc3(253, 190, 37))
		end
	elseif object_type == o_t.spirit then
		local count = d_ms.d_hz.gethz("number") .. ": " .. info.count
		local countLabel = d_ms.d_u.createByStyle({
			font = "arial",
			fontsize = 30,
			type = "label",
			string = tostring(count)
		})

		countLabel:setPosition(contentSize.width * 0.2, contentSize.height * 0.3)
		parentNode:addChild(countLabel)
		countLabel:setAnchorPoint(ccp(0, 0.5))
		countLabel:setColor(ccc3(253, 190, 37))
	end

	if introTag < 0 then
		local icon = d_ms.d_data.getCertainSmallSprite(object_type, info.type)

		icon:setPosition(contentSize.width * 0.1, contentSize.height * 0.5)
		parentNode:addChild(icon)
	else
		local iconSprite1, iconSprite2 = nil
		iconSprite1 = d_ms.d_data.getCertainSmallSprite(object_type, info.type)
		iconSprite2 = d_ms.d_data.getCertainSmallSprite(object_type, info.type)

		local function createCharIntroWrap()
			local parent = CCDirector:sharedDirector():getRunningScene()

			if introTag > 0 then
				d_ms.d_formationUI.showIntroduceLayer(parent, info, 0)
			else
				d_ms.d_data.showCharacterIntroByTypeId(info.type, parent, info.isSoul)
			end
		end

		local menuItemsDefs = {
			menuItems = {
				{
					nSprite = iconSprite1,
					sSprite = iconSprite2,
					tapHandler = createCharIntroWrap,
					pos = ccp(contentSize.width * 0.1, contentSize.height * 0.5)
				}
			},
			priority = -128,
			usedDefaultRect = true
		}
		local menuLayer = d_ms.d_tableView.createTableViewMenu(menuItemsDefs)

		parentNode:addChild(menuLayer)
	end
end

function createCell.createItemCellWithBtnOnIntro(parent, info, bkgPic, contentSize)
	_createCell(parent, info, bkgPic, contentSize, true)
end

function createCell.createCommonItemCells(parent, info, bkgPic, contentSize)
	_createCell(parent, info, bkgPic, contentSize, false)
end

function createCell.createCommonCharCells(parent, info, bkgPic, contentSize)
	_createCharCell(parent, info, bkgPic, contentSize, 0)
end

function createCell.createCharCellsWithBtnOnIntro(parent, info, bkgPic, contentSize)
	_createCharCell(parent, info, bkgPic, contentSize, 1)
end

function createCell.createCharCellsWithoutIntro(parent, info, bkgPic, contentSize)
	_createCharCell(parent, info, bkgPic, contentSize, -1)
end

function createCell.createCellWithOwner(parent, info, bkgPic, contentSize, labelPos)
	createCell.createItemCellWithBtnOnIntro(parent, info, bkgPic, contentSize)

	local owner = nil

	if info.equip_order and info.equip_order > 0 then
		owner = d_ms.d_lineupUI.g_usedCharacters[info.equip_order].character.csvInfo.name
	elseif info.csvInfo.mainType == m_t.stone and info.owner_id and info.owner_id > 0 then
		owner = d_ms.d_stoneUI.getOwnerNameByID(info.owner_id, info.csvInfo.sub_type)
	end

	if owner then
		local hintLabel = d_ms.d_u.createByStyle({
			font = "arial",
			fontsize = 26,
			type = "label",
			string = d_ms.d_hz.gethz("equip") .. owner
		})

		hintLabel:setPosition(contentSize.width * 0.85, contentSize.height * 0.7)
		hintLabel:setColor(ccc3(186, 169, 157))
		parent:addChild(hintLabel, 10)
	end
end

function createCell.createCellWithOwnerNoBtn(parent, info, bkgPic, contentSize, labelPos)
	createCell.createCommonItemCells(parent, info, bkgPic, contentSize)

	if info.equip_order and info.equip_order > 0 then
		local owner = d_ms.d_lineupUI.g_usedCharacters[info.equip_order].character.csvInfo.name
		local hintLabel = d_ms.d_u.createByStyle({
			font = "arial",
			fontsize = 26,
			type = "label",
			string = d_ms.d_hz.gethz("equip") .. owner
		})

		hintLabel:setPosition(contentSize.width * 0.85, contentSize.height * 0.7)
		hintLabel:setColor(ccc3(186, 169, 157))
		parent:addChild(hintLabel, 10)
	end
end

function createCell.createCellWithCheckBox(parent, info, bkgPic, contentSize)
	createCell.createCommonItemCells(parent, info, bkgPic, contentSize)

	local checkFrame = CCSprite:create("v2/multi-selectUI/check_frame.png")

	checkFrame:setPosition(contentSize.width * 0.8, contentSize.height * 0.5)
	parent:addChild(checkFrame, 1)

	local scale = contentSize.height * 0.7 / checkFrame:getContentSize().height

	checkFrame:setScale(scale)

	if info.isChecked then
		local checkSprite = CCSprite:create("v2/multi-selectUI/check.png")

		checkSprite:setPosition(contentSize.width * 0.8, contentSize.height * 0.5)
		parent:addChild(checkSprite, 20)
		checkSprite:setScale(scale)
	end
end

function createCell.createCellWithUsedChar(parent, info, bkgPic, contentSize)
	createCell.createCharCellsWithBtnOnIntro(parent, info, bkgPic, contentSize)

	local tipStr = nil

	if info.order and info.order > 0 then
		tipStr = d_ms.d_hz.gethz("enterIn")
	elseif info.cheer_order and info.cheer_order > 0 then
		tipStr = string.format(d_ms.d_hz.gethz("cheer_str5"), d_ms.d_cheerSquadUI.getCheerLetter(info.cheer_order))
	end

	if tipStr then
		local enterHint = d_ms.d_u.createByStyle({
			font = "arial",
			fontsize = 26,
			type = "label",
			string = tipStr
		})

		parent:addChild(enterHint)
		enterHint:setColor(ccc3(186, 169, 157))
		enterHint:setPosition(contentSize.width * 0.85, contentSize.height * 0.7)
	end
end

function createCell.createCellWithSoulCount(parent, info, bkgPic, contentSize)
	createCell.createCommonCharCells(parent, info, bkgPic, contentSize)

	if info and info.count then
		local soul_count_str = string.format(d_ms.d_hz.gethz("compose_count"), info.count)
		local count_label = d_ms.d_u.createByStyle({
			font = "arial",
			fontsize = 26,
			type = "label",
			string = soul_count_str
		})

		count_label:setAnchorPoint(CCPointMake(0, 0.5))
		count_label:setPosition(contentSize.width * 0.22, contentSize.height * 0.3)
		count_label:setColor(ccc3(253, 190, 37))
		parent:addChild(count_label)
	end
end

return createCell
