local require = require
local bits = bits
local sqlite = sqlite
local type = type
local print = print
local tostring = tostring
local pairs = pairs
local ipairs = ipairs
local debug = debug
local string = string
local table = table
local CCLuaLog = CCLuaLog
local math = math
local tonumber = tonumber
local tostring = tostring
local os = os
local CCTextureCache = CCTextureCache
local CCRectMake = CCRectMake
local CCSizeMake = CCSizeMake
local CCPointMake = CCPointMake
local CCSpriteFrame = CCSpriteFrame
local CCLabelTTF = CCLabelTTF
local CCSprite = CCSprite
local CCLayer = CCLayer
local CCDirector = CCDirector
local ccp = ccp
local CCLayerColor = CCLayerColor
local CCMenuItemImage = CCMenuItemImage
local CCMenu = CCMenu
local ccc4 = ccc4
local ccc3 = ccc3
local CCArray = CCArray
local CCLayerColor = CCLayerColor
local ccc4 = ccc4
local ccc3 = ccc3
local CCMenuItemImage = CCMenuItemImage
local CCMenu = CCMenu
local CCArray = CCArray
local CCNode = CCNode
local CCMenuItemSprite = CCMenuItemSprite
local CCTextFieldTTF = CCTextFieldTTF
local CCEditBox = CCEditBox
local kCCTextAlignmentLeft = kCCTextAlignmentLeft
local CCScale9Sprite = CCScale9Sprite
local main_server = main_server

module("data")

d_ms = require("ms")

if not d_ms then
	CCLuaLog("d_ms.d_data load d_ms fail.")
end

local function cclog(...)
	CCLuaLog(string.format(...))
end

local gethz = d_ms.d_hz.gethz
local scrSize = CCDirector:sharedDirector():getVisibleSize()
g_characterExpTable = nil
g_shopItemsPriceTable = nil
g_characterQualityTable = nil
g_topScoreExchangeTable = nil
g_topScoreTable = nil
g_csv_role_level_config = nil
g_rechargeItemsPriceTable = nil
g_goldRushTable = nil
g_friendsLvRewardTable = nil
g_friendsVipRewardTable = nil
g_platformTable = nil
g_rotTable = nil
g_achieveTable = nil
g_stoneAttrTable = nil
g_cheerTable = nil
g_prey_gridTable = nil
g_prey_charmTable = nil
g_prey_mapTable = nil
g_prey_rankTable = nil
g_fightTip = nil
g_materialTable = nil
g_convertTable = nil
g_skill_csv_advance_Table = nil
g_exchange_table = nil
g_newCharacterAttrTable = nil
g_camp_level_Table = nil
g_camp_pos_upgrade_Table = nil
g_camp_product_Table = nil
g_camp_control_Table = nil
g_handbook_status = {}
o_t = d_ms.d_common_def.object_type
m_t = d_ms.d_common_def.item_main_type
dj_w = 8
dj_h = 8
g_card_type_id = 1094
g_summer_card_type_id = 1344

function getFightTip()
	if not g_fightTip then
		local tip_csv = d_ms.d_csv.open2("csv_config/tip_content.csv")
		local tipTable = {}

		for i = 1, #tip_csv do
			local startLevel = tonumber(tip_csv[i].start_level)

			if not tipTable[startLevel] then
				tipTable[startLevel] = {
					endLevel = tonumber(tip_csv[i].end_level)
				}
			end

			local tips = tipTable[startLevel]
			tips[#tips + 1] = tip_csv[i].content
		end

		g_fightTip = tipTable
	end
end

function getHandbookStatus(type, id)
	if type == 10 then
		return 2
	end

	local ret = 0

	if type == 7 or type == 8 or type == 10 then
		type = 5
	elseif type == 9 then
		type = 15
		ret = 1
	end

	if g_handbook_status[type] and g_handbook_status[type][id] then
		return g_handbook_status[type][id]
	end

	return ret
end

function getBodySpriteFilename(id, isAsc)
	local source_id, quality = getCharactSQ(id, isAsc)

	if quality <= 3 then
		quality = 123
	end

	local file_name = "chars/" .. quality .. "/" .. quality .. "_" .. source_id .. ".png"
	local sprite = CCSprite:create(file_name)

	if not sprite then
		quality = quality or 5
		file_name = "chars/" .. quality .. "/" .. quality .. "_1.png"
	end

	return file_name
end

function getBodySprite(id, isAsc)
	local name = getBodySpriteFilename(id, isAsc)

	return CCSprite:create(name)
end

function getMyCortName(id)
	return getNameTxt(id, d_ms.d_lineupUI.g_AscTable[id])
end

function getNameTxt(id, isAsc)
	local name = ""

	if isAsc and g_asc_CortTab[id] then
		name = g_asc_CortTab[id].name
	elseif d_ms.d_lineupUI.g_characterAttrTable[id] then
		name = d_ms.d_lineupUI.g_characterAttrTable[id].name
	end

	return name
end

function getHeadSprite(id, is_asc)
	local source_id, quality = getCharactSQ(id, is_asc)
	local pngName = nil

	if quality <= 3 then
		quality = 123
	end

	pngName = "chars/" .. quality .. "_all_head" .. math.ceil(source_id / 50) .. ".png"
	source_id = 1 + (source_id - 1) % 50

	return getSingleSpriteFromPng(pngName, 10, 5, source_id)
end

function getNameSprite(id, isAsc)
	local source_id, quality = getCharactSQ(id, isAsc)
	local pngName = nil

	if quality <= 3 then
		quality = 123
	end

	pngName = "chars/" .. quality .. "_all_name" .. math.ceil(source_id / 50) .. ".png"
	source_id = 1 + (source_id - 1) % 50

	return getSingleSpriteFromPng(pngName, 10, 5, source_id)
end

function getMapGateNameDec(map_id, npc)
	local ret = nil

	for i = npc, 1, -1 do
		ret = CCSprite:create("map/" .. map_id .. "/name" .. i .. ".png")

		if ret then
			return ret
		end
	end

	return ret
end

function getMapGateName(map_id, last_npc)
	local npc = last_npc % 100
	local ret = CCSprite:create("map/" .. map_id .. "/name" .. npc .. ".png")
	ret = ret or getMapGateNameDec(map_id, npc)

	if not ret then
		cclog("ERROR: getMapGateName return /1/101.png ")

		ret = CCSprite:create("map/1/name1.png")
	end

	return ret
end

function getSkillCastSprite(skill_id, name)
	local ret = CCSprite:create("skill/name/" .. skill_id .. ".png")

	if not ret and name and #name > 0 then
		ret = d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			fontsize = 60,
			string = name,
			color = {
				255,
				0,
				0
			}
		})
	end

	ret = ret or CCSprite:create("skill/name/22.png")

	return ret
end

function getDiceSprite(point)
	if not point or point < 1 or point > 6 then
		point = 1
	end

	return getSingleSpriteFromPng("226_1/226_2.png", 6, 1, point)
end

function getCharactSQ(id, isAsc)
	local source_id = 1
	local quality = 1

	if d_ms.d_lineupUI.g_characterAttrTable[id] then
		source_id = d_ms.d_lineupUI.g_characterAttrTable[id].file
		quality = d_ms.d_lineupUI.g_characterAttrTable[id].quality

		if isAsc and g_asc_CortTab[id] then
			source_id = g_asc_CortTab[id].source_id
		end
	else
		cclog("ERROR: char id error=%s", id)
	end

	return tonumber(source_id), quality
end

function getCharNameById(id, isAsc)
	local ret = getNameTxt(id, isAsc)

	if not ret or #ret <= 0 then
		ret = "NPC"
	end

	return ret
end

function getSingleSpriteFromPng(filename, wl, hl, id)
	local texture = CCTextureCache:sharedTextureCache():addImage(filename)
	local w = texture:getContentSize().width / wl
	local h = texture:getContentSize().height / hl
	local sprite_ret = nil
	local rect = CCRectMake((id - 1) % wl * w, math.floor((id - 1) / wl) * h, w, h)
	local tmp_frame = CCSpriteFrame:createWithTexture(texture, rect)
	local sprite_ret = CCSprite:createWithSpriteFrame(tmp_frame)

	return sprite_ret
end

function getItemName(item_id, is_asc, is_tilian)
	local itemInfo = d_ms.d_packageUI.g_itemAttrTable[item_id]

	if is_asc or is_tilian then
		if itemInfo.mainType == m_t.stone then
			if is_tilian == 12 then
				return gethz("stone_tilianName" .. itemInfo.sub_type)
			elseif is_tilian == 13 then
				return gethz("stone_tilianNameB" .. itemInfo.sub_type)
			elseif is_tilian == 14 then
				return gethz("stone_tilianNameC" .. itemInfo.sub_type)
			else
				return gethz("stone_ascName" .. itemInfo.sub_type)
			end
		else
			return gethz("pre_item_name") .. itemInfo.name
		end
	elseif itemInfo.main_type == m_t.awaken_star then
		return d_ms.d_wakeUI.getStarName()
	else
		return itemInfo.name
	end
end

function getSmallItemFileName(item_id)
	local itemIconFile = "items/" .. item_id .. ".png"
	local sprite = CCSprite:create(itemIconFile)

	if not sprite then
		itemIconFile = "items/4014.png"
	end

	return itemIconFile
end

function getAscStoneSprite(type_id, level)
	local csvInfo = d_ms.d_data.getCertainInfo(o_t.item, type_id)
	local sub_type = csvInfo.sub_type

	if level == 14 then
		return CCSprite:create("v2/stoneCastUI/tl14" .. sub_type .. ".png")
	elseif level == 13 then
		return CCSprite:create("v2/stoneCastUI/tl13" .. sub_type .. ".png")
	elseif level == 12 then
		return CCSprite:create("v2/stoneCastUI/tl" .. sub_type .. ".png")
	else
		return CCSprite:create("v2/stoneCastUI/" .. sub_type .. ".png")
	end
end

function getStoneSprite(source_id, level)
	local sprite = getSingleSpriteFromPng("items/stone.png", 8, 4, source_id + level - 1)
	local size = sprite:getContentSize()
	local label1 = CCLabelTTF:create("+" .. level, "arial", 26)

	label1:setPosition(0.9 * size.width, 0.9 * size.height)
	label1:setAnchorPoint(CCPointMake(1, 1))
	label1:setColor(ccc3(255, 128, 0))

	local label2 = CCLabelTTF:create("+" .. level, "arial", 26)

	label2:setPosition(0.9 * size.width + 1, 0.9 * size.height - 1)
	label2:setAnchorPoint(CCPointMake(1, 1))
	label2:setColor(ccc3(0, 0, 0))
	sprite:addChild(label1, 2)
	sprite:addChild(label2, 1)

	return sprite
end

function getEquipPiece(i_source_id)
	if i_source_id < 1 or i_source_id > 200 then
		i_source_id = 1
	end

	local ret = nil

	if i_source_id <= 100 then
		ret = getSingleSpriteFromPng("items/all_items1.png", 10, 10, i_source_id)
	else
		ret = getSingleSpriteFromPng("items/all_items2.png", 10, 10, i_source_id - 100)
	end

	local mask_parts = d_ms.d_u.createByStyle({
		pic = "map/parts.png",
		anchor = {
			0,
			0
		}
	})

	ret:addChild(mask_parts)

	return ret
end

function addlvLabelToSprite(sprite, level)
	if not sprite then
		return
	end

	local size = sprite:getContentSize()
	local label1 = CCLabelTTF:create("Lv " .. level, "arial", 26)

	label1:setPosition(0.1 * size.width, 0.95 * size.height)
	label1:setAnchorPoint(CCPointMake(0, 1))
	label1:setColor(ccc3(255, 128, 0))

	local label2 = CCLabelTTF:create("Lv " .. level, "arial", 26)

	label2:setPosition(0.1 * size.width + 1, 0.95 * size.height - 1)
	label2:setAnchorPoint(CCPointMake(0, 1))
	label2:setColor(ccc3(255, 128, 0))
	sprite:addChild(label1, 2)
	sprite:addChild(label2, 1)
end

function getCardSprite(level)
	local sprite = CCSprite:create("v2/CardUI/card_bkg.png")
	local size = sprite:getContentSize()

	getSpringCardLetters()

	if g_letters[level] then
		local label1 = CCLabelTTF:create(g_letters[level], "arial", 38)

		label1:setPosition(0.5 * size.width, 0.5 * size.height)
		label1:setColor(ccc3(0, 0, 0))
		sprite:addChild(label1, 1)
	end

	return sprite
end

function getSummerCardSprite(level)
	local sprite = CCSprite:create("v2/summerUI/cbkg3.png")
	local size = sprite:getContentSize()

	getSummerCardLetters()

	if g_summer_letters[level] then
		local label1 = CCLabelTTF:create(g_summer_letters[level], "arial", 38)

		label1:setPosition(0.5 * size.width, 0.5 * size.height)
		label1:setColor(ccc3(0, 0, 0))
		sprite:addChild(label1, 1)
	end

	return sprite
end

function getExtSkillSprite(id)
	local ext_src_id = id

	if ext_src_id <= 400 or ext_src_id >= 600 then
		ext_src_id = 401

		cclog("ERROR: getExtSkillSprite id=" .. id)
	end

	pic_name = "skill/ext/" .. ext_src_id .. ".png"
	local sprite = CCSprite:create(pic_name)

	return sprite
end

function getFileIdByExtSkillType(item_id)
	local ret = 401
	local name = ""

	if d_ms.d_packageUI.g_itemAttrTable[item_id] and d_ms.d_packageUI.g_itemAttrTable[item_id].file then
		ret = d_ms.d_packageUI.g_itemAttrTable[item_id].file
		name = d_ms.d_packageUI.g_itemAttrTable[item_id].name or ""
	end

	return ret, name
end

function getLittleIcon(object_type, attach_type)
	local sprite = nil
	local o_t = d_ms.d_common_def.object_type

	if object_type == o_t.gold_coin then
		sprite = CCSprite:create("v2/money_gold.png")
	elseif object_type == o_t.silver_coin then
		sprite = CCSprite:create("v2/money_silver.png")
	elseif object_type == o_t.item and attach_type == 1361 then
		sprite = CCSprite:create("v2/homeUI/copper.png")
	end

	sprite = sprite or CCSprite:create("v2/money_silver.png")

	return sprite
end

function getSmallItemSprite(item_id, level, is_asc, star_level)
	local level = level or 1
	d_ms.d_packageUI.g_itemAttrTable[item_id] = d_ms.d_packageUI.g_itemAttrTable[item_id] or d_ms.d_packageUI.g_itemAttrTable[1081]
	local quality = d_ms.d_packageUI.g_itemAttrTable[item_id].quality
	local source_id = d_ms.d_packageUI.g_itemAttrTable[item_id].file
	local show_level = d_ms.d_packageUI.g_itemAttrTable[item_id].show_level
	local mainType = d_ms.d_packageUI.g_itemAttrTable[item_id].mainType
	local i_source_id = tonumber(source_id)

	if mainType == m_t.invisible_card and item_id == g_card_type_id then
		return getCardSprite(level)
	end

	if mainType == m_t.summer_card and item_id == g_summer_card_type_id then
		return getSummerCardSprite(level)
	end

	if mainType == m_t.stone then
		if level > 10 then
			return getAscStoneSprite(item_id, level)
		else
			return getStoneSprite(i_source_id, level)
		end
	end

	if mainType == m_t.material_fregment then
		return getEquipPiece(i_source_id)
	end

	if mainType == m_t.ext_skill then
		return getExtSkillSprite(i_source_id)
	end

	if mainType == m_t.awaken_star then
		return d_ms.d_wakeUI.getStarSprite(item_id, level)
	end

	if mainType == m_t.destiny_card then
		return d_ms.d_destinyUI.getReduceCardSprite(item_id)
	end

	if m_t.talismans < mainType then
		local file_name = "items/all_daoju1.png"

		if i_source_id < 1 then
			i_source_id = 1
		end

		if i_source_id > dj_w * dj_h and i_source_id <= dj_w * dj_h * 2 then
			i_source_id = i_source_id - dj_w * dj_h
			file_name = "items/all_daoju2.png"
		elseif i_source_id > dj_w * dj_h * 2 and i_source_id <= dj_w * dj_h * 3 then
			i_source_id = i_source_id - dj_w * dj_h * 2
			file_name = "items/all_daoju3.png"
		elseif i_source_id > dj_w * dj_h * 3 then
			i_source_id = i_source_id - dj_w * dj_h * 3
			file_name = "items/all_daoju4.png"
		end

		local sprite = getSingleSpriteFromPng(file_name, dj_w, dj_h, i_source_id)

		if show_level > 0 and (show_level > 7984 or show_level < 7981) then
			addlvLabelToSprite(sprite, show_level)
		elseif show_level <= 7984 or show_level >= 7981 then
			d_ms.d_yaoshendianUI.addSuperscript(sprite, show_level)
		end

		return sprite
	end

	if i_source_id < 1 or i_source_id > 200 then
		i_source_id = 1
	end

	local original = nil

	if i_source_id <= 100 then
		original = getSingleSpriteFromPng("items/all_items1.png", 10, 10, i_source_id)
	else
		original = getSingleSpriteFromPng("items/all_items2.png", 10, 10, i_source_id - 100)
	end

	if star_level == 1 then
		local sp = CCSprite:create("v2/shengxing/kuang2.png")
		local size = original:getContentSize()

		sp:setPosition(size.width * 0.5, size.height * 0.5)
		original:addChild(sp, 1)
	elseif is_asc then
		local sp = CCSprite:create("v2/ascCast/circle.png")
		local size = original:getContentSize()

		sp:setPosition(size.width * 0.5, size.height * 0.5)
		original:addChild(sp, 1)
	end

	return original
end

function getExpBookSprite(id, level)
	return getSingleSpriteFromPng("items/all_daoju1.png", dj_w, dj_h, id)
end

function getBigItemFileName(item_id)
	local itemIconFile = "items/" .. item_id .. ".jpg"
	local sprite = CCSprite:create(itemIconFile)

	if not sprite then
		itemIconFile = "items/4014.jpg"
	end

	return itemIconFile
end

function getBigItemSprite(item_id)
	local filename = getBigItemFileName(item_id)
	local sprite = CCSprite:create(filename)

	return sprite
end

function getSmallSkillFileName(item_id)
	local itemIconFile = "skill/" .. item_id .. ".png"

	return itemIconFile
end

function getSmallSkillSprite(item_id)
	local source_id = d_ms.d_packageUI.g_itemSkillTable[item_id].file

	return getSingleSpriteFromPng("skill/skill_icons.png", 10, 10, source_id)
end

function getSkillName(skill_id)
	if not d_ms.d_packageUI.g_itemSkillTable[skill_id] then
		return ""
	end

	return d_ms.d_packageUI.g_itemSkillTable[skill_id].name
end

function getBigSkillFileName(item_id)
	local itemIconFile = "skill/" .. item_id .. ".jpg"

	return itemIconFile
end

function getBigSkillSprite(item_id)
	local filename = getBigSkillFileName(item_id)
	local sprite = CCSprite:create(filename)
	sprite = sprite or "skill/107.jpg"

	return sprite
end

function getSkillQuality(skill_id)
	if not d_ms.d_packageUI.g_itemSkillTable or not d_ms.d_packageUI.g_itemSkillTable[skill_id] then
		return 0
	else
		return d_ms.d_packageUI.g_itemSkillTable[skill_id].quality
	end
end

function getItemCountByType(object_type, type_id)
	local info = getCertainInfo(object_type, type_id)
	local count = 0
	local packageItemsInfo = d_ms.d_packageUI.g_reorgItemsInfo[object_type]

	if object_type == o_t.skill then
		for k, v in pairs(packageItemsInfo) do
			if v.type_id == type_id then
				count = count + 1
			end
		end
	elseif object_type == o_t.item then
		local main_type = info.mainType
		local subPackage = packageItemsInfo[main_type]

		if subPackage ~= nil then
			if info.isStackable == 0 then
				for k, v in pairs(subPackage) do
					if v.type_id == type_id then
						count = count + 1
					end
				end
			else
				for k, v in pairs(subPackage) do
					if v.type_id == type_id and (main_type ~= m_t.ext_skill or v.owner_id == 0) then
						count = subPackage[k].count

						break
					end
				end
			end
		end
	elseif object_type == o_t.gold_coin then
		return d_ms.d_mainUI.g_playerInfo.gold_coin
	elseif object_type == o_t.silver_coin then
		return d_ms.d_mainUI.g_playerInfo.silver_coin
	end

	return count
end

function getPropsID(type_id)
	local info = getCertainInfo(o_t.item, type_id)
	local packageItemsInfo = d_ms.d_packageUI.g_reorgItemsInfo[o_t.item]
	local main_type = info.mainType
	local subPackage = packageItemsInfo[main_type]

	for i = 1, #subPackage do
		if subPackage[i].type_id == type_id then
			return subPackage[i].id
		end
	end
end

function getItemById(id)
	local item = nil
	local packageItemsInfo = d_ms.d_packageUI.g_packageItemsInfo

	for i = 1, #packageItemsInfo do
		if packageItemsInfo[i].id == id then
			item = packageItemsInfo[i]

			break
		end
	end

	return item
end

function getItemSpriteByTypeID(type_id)
	return getSmallItemSprite(type_id)
end

function getSkillSpriteByTypeID(type_id)
	return getSmallSkillSprite(type_id)
end

function getSpriteByTypeId(obj_type, type_id)
	local ret = nil

	if obj_type == o_t.item then
		ret = getSmallItemSprite(type_id)
	elseif obj_type == o_t.skill then
		ret = getSmallSkillSprite(type_id)
	elseif obj_type == o_t.silver_coin then
		ret = getSilverSprite()
	elseif obj_type == o_t.gold_coin then
		ret = getGoldSprite()
	else
		cclog("ERROR: get getSpriteByTypeId, type=" .. obj_type .. ", id=" .. type_id)

		ret = getBoxSprite()
	end

	return ret
end

function getNameByTypeId(obj_type, type_id, is_asc, is_tilian)
	local ret = ""

	if obj_type == o_t.item then
		ret = getItemName(type_id, is_asc, is_tilian)
	elseif obj_type == o_t.skill then
		ret = getSkillName(type_id)
	elseif obj_type == o_t.cortege then
		ret = getNameTxt(type_id, is_asc)
	elseif obj_type == o_t.animal then
		ret = d_ms.d_petUI.getNameTxt(type_id)
	elseif obj_type == o_t.silver_coin then
		ret = gethz("money")
	elseif obj_type == o_t.gold_coin then
		ret = gethz("goldHZ")
	else
		cclog("ERROR: get getNameByTypeId, type=" .. obj_type .. ", id=" .. type_id)

		ret = ""
	end

	return ret
end

function showDetail(layer, itemIntro, zorder)
	local mainLayer = nil

	local function menuCancel()
		d_ms.d_u.remove(mainLayer)

		mainLayer = nil
	end

	zorder = zorder or 50

	if itemIntro.object_type == 5 or itemIntro.object_type == 6 then
		mainLayer = d_ms.d_subLevelUI.createPriItemIntroLayer(itemIntro.object_type, itemIntro.attach_type, menuCancel, itemIntro.level or itemIntro.attach_level or 1)

		layer:addChild(mainLayer, zorder)
	end
end

function loadingBaseData()
	getCharacterExperienceCSVConfig()
	getShopItemsPriceCSVConfig()
	getCharacterQualityCSVConfig()
	getTopScoreExchangeCSVConfig()
	getTopScoreCSVConfig()
	getRechargeItemsPriceCSVConfig()
	d_ms.d_feishengUI.getFeiShengCount()
	getStoneAttrCSVConfig()
	getFightTip()
	initSoulsData()
	getMaterialTransformCSVConfig()
	getEquipPiecePrice()
	getCortCollectCSVConfig()
	getAscensionConfig()
	getEquipAscConfig()
	getPetCSVConfig()
	getSkillCsv_advance()
	getSpecialitemuseCSVConfig()
	getExchangeData()
end

g_adaptiveTable = nil

function getAdaptiveCSVConfig()
	if not g_adaptiveTable then
		local ada_csv = d_ms.d_csv.open2("csv_config/adaptive_spirit_convert.csv")
		g_adaptiveTable = {}

		for k, v in pairs(ada_csv) do
			local cortType = tonumber(v.cortege_type)
			local cost = tonumber(v.need_count)
			g_adaptiveTable[cortType] = cost
		end
	end
end

function getKickConfig()
	if not g_kickRankTable then
		local tmp = d_ms.d_csv.open2("csv_config/hill_top_prize.csv")
		g_kickRankTable = {}

		for k, v in pairs(tmp) do
			g_kickRankTable[k] = {
				min_order = tonumber(v.min_order),
				max_order = tonumber(v.max_order),
				min_score = tonumber(v.min_score),
				prize_list = getItemListFromStr(v.prize_list)
			}
		end
	end
end

function getDreamConfig()
	if not g_dreamTable then
		local tmp = d_ms.d_csv.open2("csv_config/dream_prize_config.csv")
		g_dreamTable = {}

		for k, v in pairs(tmp) do
			g_dreamTable[tonumber(v.index)] = {
				dream_prizes = getItemListFromStr(v.dream_prizes),
				own_wish_prizes = getItemListFromStr(v.own_wish_prizes),
				other_wish_prizes = getItemListFromStr(v.other_wish_prizes)
			}
		end
	end
end

function getCharacterExperienceCSVConfig()
	if g_characterExpTable == nil then
		local char_exp_tab_csv = d_ms.d_csv.open("csv_config/cortege_experience.csv")
		g_characterExpTable = {}
		local char_exp_tab = g_characterExpTable

		for k, v in pairs(char_exp_tab_csv.records) do
			local quality = tonumber(v[1])
			local level = tonumber(v[2])
			local value = tonumber(v[3])

			if not char_exp_tab[quality] then
				char_exp_tab[quality] = {}
			end

			char_exp_tab[quality][level] = value
		end
	end
end

function getShopItemAttr(object_type, type_id)
	local allItems = d_ms.d_shopUI.g_self.Goods[2]

	for k, v in pairs(allItems) do
		if v.buyInfo.type_id == type_id and object_type == v.buyInfo.object_type then
			return v.buyInfo
		end
	end
end

function getExtSkillLockPrice()
	if not g_ext_skill_lock_price then
		local tab_csv = d_ms.d_csv.open2("csv_config/ext_skill_lock_cost.csv")
		g_ext_skill_lock_price = {}

		for k, v in pairs(tab_csv) do
			g_ext_skill_lock_price[tonumber(v.lock_count)] = tonumber(v.cost)
		end
	end
end

function getEquipPiecePrice()
	if not g_ep_price then
		local tab_csv = d_ms.d_csv.open2("csv_config/item_price_config.csv")
		g_ep_price = {}

		for k, v in pairs(tab_csv) do
			g_ep_price[tonumber(v.item_type)] = tonumber(v.silver_count)
		end
	end
end

function getAnniversaryConfig()
	if not g_anni_quest then
		local tab_csv = d_ms.d_csv.open2("csv_config/old_task_prize.csv")
		g_anni_quest = {}

		for k, v in pairs(tab_csv) do
			g_anni_quest[tonumber(v.task_index)] = {
				desc = string.format(v.desc, tonumber(v.do_times)),
				prize_list = getItemListFromStr(v.prize_list)
			}
		end
	end
end

function getLingConfig()
	if not g_ling_stone_need then
		local tab_csv = d_ms.d_csv.open2("csv_config/ling_active.csv")
		g_ling_stone_need = {}

		for k, v in pairs(tab_csv) do
			local index = tonumber(v.index)

			if not g_ling_stone_need[index] then
				g_ling_stone_need[index] = {}
			end

			g_ling_stone_need[index][tonumber(v.pos)] = {
				type_id = tonumber(v.stone_type),
				level = tonumber(v.stone_lv)
			}
		end
	end

	if not g_ling_pos then
		local tab_csv = d_ms.d_csv.open2("csv_config/ling_first.csv")
		g_ling_pos = {}

		for k, v in pairs(tab_csv) do
			g_ling_pos[tonumber(v.ling_level)] = tonumber(v.ling_first)
		end
	end

	if not g_ling_stone_value then
		local tab_csv = d_ms.d_csv.open2("csv_config/ling_stone_value.csv")
		g_ling_stone_value = {}

		for k, v in pairs(tab_csv) do
			local type = tonumber(v.type)

			if not g_ling_stone_value[type] then
				g_ling_stone_value[type] = {}
			end

			g_ling_stone_value[type][tonumber(v.level)] = tonumber(v.count)
		end
	end

	if not g_ling_upgrade then
		local tab_csv = d_ms.d_csv.open2("csv_config/ling_upgrade.csv")
		g_ling_upgrade = {}

		for k, v in pairs(tab_csv) do
			local count_list = d_ms.d_str.split(v.count, "|")

			for k, v in pairs(count_list) do
				count_list[k] = tonumber(v)
			end

			g_ling_upgrade[tonumber(v.index)] = count_list
		end
	end

	if not g_ling_name then
		local tab_csv = d_ms.d_csv.open2("csv_config/ling_pos_name.csv")
		g_ling_name = {}

		for k, v in pairs(tab_csv) do
			local index = tonumber(v.index)
			local pos = tonumber(v.pos)

			if not g_ling_name[index] then
				g_ling_name[index] = {
					attr = {}
				}
			end

			if pos == 0 then
				g_ling_name[index].name = v.name
			else
				g_ling_name[index].attr[pos] = v.name
			end
		end
	end

	if not g_ling_effect then
		local tab_csv = d_ms.d_csv.open2("csv_config/ling_effect.csv")
		g_ling_effect = {}

		for k, v in pairs(tab_csv) do
			local index = tonumber(v.index)
			local pos = tonumber(v.pos)

			if not g_ling_effect[index] then
				g_ling_effect[index] = {
					name = g_ling_name[index].name,
					attr = {}
				}
			end

			if not g_ling_effect[index].attr[pos] then
				g_ling_effect[index].attr[pos] = {
					name = g_ling_name[index].attr[pos]
				}
			end

			local data = g_ling_effect[index].attr[pos]
			local active_level = tonumber(v.active_level)

			if not data.skill_list then
				data.skill_list = {}
			end

			local skill = {
				name = v.name,
				effect_type = tonumber(v.name_index),
				activate_level = active_level
			}
			local effects = d_ms.d_str.split(v.effect_value, "/")

			for k, v in pairs(effects) do
				effects[k] = tonumber(v)
			end

			skill.effect = effects

			table.insert(data.skill_list, skill)
		end

		for _, tmp1 in pairs(g_ling_effect) do
			for _, tmp2 in pairs(tmp1.attr) do
				table.sort(tmp2.skill_list, function (a, b)
					return a.activate_level < b.activate_level
				end)
			end
		end
	end
end

function getSoulHuntConfig()
	if not g_hunt_price then
		local tab_csv = d_ms.d_csv.open2("csv_config/hunt_ball_config.csv")
		g_hunt_price = {}

		for k, v in pairs(tab_csv) do
			g_hunt_price[tonumber(v.ball_type)] = {
				need_energy = tonumber(v.need_energy),
				bump_times = tonumber(v.bump_times)
			}
		end
	end

	if not g_hunt_soul then
		local tab_csv = d_ms.d_csv.open2("csv_config/hunt_soul_config.csv")
		g_hunt_soul = {}

		for k, v in pairs(tab_csv) do
			g_hunt_soul[tonumber(v.soul_type)] = {
				soul_value = tonumber(v.soul_value)
			}
		end
	end

	if not g_hunt_day_prize then
		local tab_csv = d_ms.d_csv.open2("csv_config/hunt_day_prize.csv")
		g_hunt_day_prize = {}

		for k, v in pairs(tab_csv) do
			g_hunt_day_prize[k] = {
				min = tonumber(v.min_rank),
				max = tonumber(v.max_rank),
				prize_list = getItemListFromStr(v.attach_list)
			}
		end
	end

	if not g_hunt_week_prize then
		local tab_csv = d_ms.d_csv.open2("csv_config/hunt_week_prize.csv")
		g_hunt_week_prize = {}

		for k, v in pairs(tab_csv) do
			g_hunt_week_prize[k] = {
				min = tonumber(v.min_rank),
				max = tonumber(v.max_rank),
				prize_list = getItemListFromStr(v.attach_list)
			}
		end
	end
end

local function getPetTableFromStr(str)
	local list = {}
	local stab = d_ms.d_str.split(str, "/")

	for k, v in pairs(stab) do
		local sstab = d_ms.d_str.split(v, "|")
		list[k] = {
			tonumber(sstab[1]),
			tonumber(sstab[2])
		}
	end

	return list
end

local function getPetSpecialStr(str)
	local stab = d_ms.d_str.split(str, "|")

	return string.format(gethz("pet_test6"), tonumber(stab[4]), gethz("asc_attr" .. stab[2]), gethz("pet_direction" .. stab[1]), gethz("asc_attr" .. stab[3]))
end

local function getPetSpecialTab(str)
	local stab = d_ms.d_str.split(str, "|")
	local result = {
		addPos = tonumber(stab[1]),
		sourceAttr = tonumber(stab[2]),
		attrRate = tonumber(stab[4])
	}

	return result
end

local function getPetConsumeList(str)
	local list = {}
	local stab = d_ms.d_str.split(str, "/")

	for k, v in pairs(stab) do
		local sstab = d_ms.d_str.split(v, "|")
		list[k] = {
			type = tonumber(sstab[1]),
			quality = tonumber(sstab[2]),
			count = tonumber(sstab[3]),
			begin_index = list[k - 1] and list[k - 1].end_index + 1 or 1
		}
		list[k].end_index = list[k].begin_index + list[k].count - 1
	end

	return list
end

function getPetCSVConfig()
	if not g_pet_base then
		g_pet_base = {}
		local tab_csv = d_ms.d_csv.open2("csv_config/animal_name.csv")

		for k, v in pairs(tab_csv) do
			g_pet_base[tonumber(v.type_id)] = {
				name = v.name,
				intro = v.intro
			}
		end

		local tab_csv2 = d_ms.d_csv.open2("csv_config/animal_base.csv")

		for k, v in pairs(tab_csv2) do
			local record = g_pet_base[tonumber(v.type_id)]
			record.main_type = tonumber(v.main_type)
			record.base_gongji = tonumber(v.base_gongji)
			record.base_fangyu = tonumber(v.base_fangyu)
			record.base_hp = tonumber(v.base_hp)
			record.base_magic = tonumber(v.base_magic)
			record.attrList = getPetTableFromStr(v.plus_order)
			record.specialStr = getPetSpecialStr(v.special_property)
			record.specialTab = getPetSpecialTab(v.special_property)
			record.is_exp_pet = v.is_exp_pet == "Y"
		end
	end

	if not g_pet_plusControl then
		g_pet_plusControl = {}
		local tab_csv = d_ms.d_csv.open2("csv_config/animal_control.csv")

		for k, v in pairs(tab_csv) do
			local main_type = tonumber(v.main_type)
			local quality = tonumber(v.quality)

			if not g_pet_plusControl[main_type] then
				g_pet_plusControl[main_type] = {}
			end

			g_pet_plusControl[main_type][quality] = {
				max_open_pos = tonumber(v.max_open_pos),
				open_special = v.open_special == "Y",
				max_star_level = tonumber(v.max_star_level)
			}
		end
	end

	if not g_pet_growup then
		g_pet_growup = {}
		local tab_csv = d_ms.d_csv.open2("csv_config/animal_growup.csv")

		for k, v in pairs(tab_csv) do
			g_pet_growup[tonumber(v.index)] = getPetTableFromStr(v.grow_list)
		end
	end

	if not g_pet_baseExp then
		g_pet_baseExp = {}
		local tab_csv = d_ms.d_csv.open2("csv_config/animal_exprience.csv")

		for k, v in pairs(tab_csv) do
			local main_type = tonumber(v.main_type)
			local quality = tonumber(v.quality)

			if not g_pet_baseExp[main_type] then
				g_pet_baseExp[main_type] = {}
			end

			g_pet_baseExp[main_type][quality] = tonumber(v.base_exp)
		end
	end

	if not g_pet_baseFusion then
		g_pet_baseFusion = {}
		local tab_csv = d_ms.d_csv.open2("csv_config/animal_exprience.csv")

		for k, v in pairs(tab_csv) do
			local main_type = tonumber(v.main_type)
			local quality = tonumber(v.quality)

			if not g_pet_baseFusion[main_type] then
				g_pet_baseFusion[main_type] = {}
			end

			g_pet_baseFusion[main_type][quality] = tonumber(v.base_quality_value)
		end
	end

	if not g_pet_expSpecial then
		g_pet_expSpecial = {}
		local tab_csv = d_ms.d_csv.open2("csv_config/animal_pet_exp.csv")

		for k, v in pairs(tab_csv) do
			local type_id = tonumber(v.type_id)
			local quality = tonumber(v.quality)

			if not g_pet_expSpecial[type_id] then
				g_pet_expSpecial[type_id] = {}
			end

			g_pet_expSpecial[type_id][quality] = tonumber(v.base_exp)
		end
	end

	if not g_pet_expNeed then
		g_pet_expNeed = {}
		local tab_csv = d_ms.d_csv.open2("csv_config/animal_upgrade.csv")

		for k, v in pairs(tab_csv) do
			local main_type = tonumber(v.main_type)
			local level = tonumber(v.level)

			if not g_pet_expNeed[main_type] then
				g_pet_expNeed[main_type] = {}
			end

			g_pet_expNeed[main_type][level] = tonumber(v.exp)
		end
	end

	if not g_pet_star then
		g_pet_star = {}
		local tab_csv = d_ms.d_csv.open2("csv_config/animal_train_config.csv")

		for k, v in pairs(tab_csv) do
			local level = tonumber(v.star_level)
			g_pet_star[level] = {
				name = v.name,
				star_plus = getPetTableFromStr(v.star_plus),
				plus_rate = getPetTableFromStr(v.plus_growup_rate),
				use_prop = getItemFromStr(v.star_consume1),
				use_list = getPetConsumeList(v.star_consume2),
				stage_plus = tonumber(v.each_stage_plus),
				stage_consume = getItemFromStr(v.each_stage_consume)
			}
			local order_list = {}
			local use_type_list = {}

			for m, n in pairs(g_pet_star[level].use_list) do
				for i = n.begin_index, n.end_index do
					use_type_list[i] = {
						type = n.type,
						quality = n.quality
					}

					if d_ms.d_common_def.animal_main_type.shen < n.type then
						order_list[i] = 0
					else
						order_list[i] = 1
					end
				end
			end

			g_pet_star[level].order_list = order_list
			g_pet_star[level].use_type_list = use_type_list
			g_pet_star[level].all_train_add = (g_pet_star[level] and g_pet_star[level].stage_plus * 4 or 0) + (g_pet_star[level - 1] and g_pet_star[level - 1].all_train_add or 0)
		end
	end
end

function getPreyCSVConfig()
	if not g_prey_gridTable then
		local tab_csv = d_ms.d_csv.open2("csv_config/prey_open_grid.csv")
		g_prey_gridTable = {}
		local grid = g_prey_gridTable

		for k, v in pairs(tab_csv) do
			grid[tonumber(v.cortege_index)] = {
				soul = tonumber(v.consume_soul),
				boss = tonumber(v.boss_layer)
			}
		end
	end

	if not g_prey_charmTable then
		local tab_csv = d_ms.d_csv.open2("csv_config/prey_open_charm.csv")
		g_prey_charmTable = {}
		local charm = g_prey_charmTable

		for k, v in pairs(tab_csv) do
			charm[tonumber(v.index)] = {
				unlock_soul = tonumber(v.force_open_soul),
				soul = tonumber(v.consume_soul),
				boss = tonumber(v.need_boss),
				can_force_open = tonumber(v.can_force_open),
				auto_open = tonumber(v.auto_open)
			}
		end
	end

	if not g_prey_mapTable then
		local tab_csv = d_ms.d_csv.open2("csv_config/prey_map_config.csv")
		g_prey_mapTable = {}
		local map = g_prey_mapTable

		for k, v in pairs(tab_csv) do
			map[tonumber(v.map_level)] = {
				soul = tonumber(v.soul_count),
				boss = tonumber(v.need_boss_layer)
			}
		end
	end

	if not g_prey_rankTable then
		local tab_csv = d_ms.d_csv.open2("csv_config/prey_week_rank.csv")
		g_prey_rankTable = {}
		local rank = g_prey_rankTable

		for k, v in pairs(tab_csv) do
			rank[k] = {
				min = tonumber(v.min_rank),
				max = tonumber(v.max_rank),
				prize_list = getItemListFromStr(v.attach_list)
			}
		end
	end

	if not g_prey_convertTable then
		local tab_csv = d_ms.d_csv.open2("csv_config/prey_charm_convert.csv")
		g_prey_convertTable = {}
		local convert = g_prey_convertTable

		for k, v in pairs(tab_csv) do
			convert[tonumber(v.charm)] = {
				value = tonumber(v.compose_value),
				critical = tonumber(v.critical_chance),
				cost = tonumber(v.convert_cost)
			}
		end
	end
end

function getAttrPlusFromStr(str)
	local list = {}
	local stab = d_ms.d_str.split(str, "/")

	for k, v in pairs(stab) do
		local sstab = d_ms.d_str.split(v, "|")
		list[tonumber(sstab[1])] = tonumber(sstab[2])
	end

	for i = 1, 4 do
		if not list[i] then
			list[i] = 0
		end
	end

	return list
end

function getAttrSum(a, b)
	local list = {}

	for i = 1, 4 do
		list[i] = a[i] + b[i]
	end

	return list
end

function getAscensionConfig()
	if not g_asc_CortTab then
		local tab_csv = d_ms.d_csv.open2("csv_config/cortege_reborn_config.csv")
		g_asc_CortTab = {}

		for k, v in pairs(tab_csv) do
			g_asc_CortTab[tonumber(v.cortege_type)] = {
				name = v.name,
				source_id = tonumber(v.source_id),
				plus_type = tonumber(v.plus_type)
			}
		end
	end

	if not g_asc_StageEffectTab then
		local tab_csv = d_ms.d_csv.open2("csv_config/cortege_reborn_effect.csv")
		g_asc_StageEffectTab = {}
		local stage = g_asc_StageEffectTab

		for k, v in pairs(tab_csv) do
			local layer = tonumber(v.layer)

			if not stage[layer] then
				stage[layer] = {}
			end

			stage[layer][tonumber(v.effect_type)] = {
				effect = getAttrPlusFromStr(v.plus_list),
				desc = v.desc
			}
		end

		for k, v in ipairs(stage) do
			if stage[k - 1] then
				for m, n in pairs(v) do
					n.effect = getAttrSum(n.effect, stage[k - 1][m].effect)
				end
			end
		end
	end

	if not g_asc_StageNeedTab then
		local tab_csv = d_ms.d_csv.open2("csv_config/cortege_reborn_layer.csv")
		g_asc_StageNeedTab = {}
		local need = g_asc_StageNeedTab

		for k, v in pairs(tab_csv) do
			need[tonumber(v.layer)] = {
				min_level = tonumber(v.min_level),
				reset_level = tonumber(v.reset_level),
				ret_culture = tonumber(v.ret_culture),
				four_plus_rate = tonumber(v.four_plus_rate),
				consume_list = getItemListFromStr(v.consum_list)
			}
		end
	end

	if not g_asc_PointTab then
		local tab_csv = d_ms.d_csv.open2("csv_config/cortege_reborn_vein.csv")
		g_asc_PointTab = {}
		local point = g_asc_PointTab

		for k, v in pairs(tab_csv) do
			local layer = tonumber(v.layer)

			if not point[layer] then
				point[layer] = {}
			end

			point[layer][tonumber(v.pulse)] = {
				consume_list = getItemListFromStr(v.consume_list),
				fixed_count = tonumber(v.fixed_count),
				effect_list = getAttrPlusFromStr(v.effect_list)
			}
		end
	end
end

function getEquipAscConfig()
	local function getAttrFromStr(str)
		local attr = {}
		local stab = d_ms.d_str.split(str, "|")
		attr.type = tonumber(stab[1])
		attr.value = tonumber(stab[2])

		return attr
	end

	local function getAttrListFromStr(str)
		local list = {}
		local stab = d_ms.d_str.split(str, "/")

		for k, v in pairs(stab) do
			list[k] = getAttrFromStr(v)
		end

		return list
	end

	local function getTierAttrDesc(attr)
		local attrHz = {
			gethz("enhance_attack"),
			gethz("enhance_defence"),
			gethz("enhance_hp"),
			gethz("neili")
		}

		if attr.type > 4 then
			local desc = attrHz[attr.type - 4] .. gethz("increase") .. attr.value

			return desc
		else
			local desc = attrHz[attr.type] .. gethz("increase") .. attr.value .. "%"

			return desc
		end
	end

	if not g_equipAsc_baseTab then
		local tab_csv = d_ms.d_csv.open2("csv_config/equip_reborn_base.csv")
		g_equipAsc_baseTab = {}
		local base = g_equipAsc_baseTab

		for k, v in pairs(tab_csv) do
			base[tonumber(v.equip_type)] = {
				cosume_item = getItemFromStr(v.cosume_item),
				effect_value = getAttrFromStr(v.plus_value)
			}
		end
	end

	if not g_equipAsc_castTab then
		local tab_csv = d_ms.d_csv.open2("csv_config/equip_reborn_advance.csv")
		g_equipAsc_castTab = {}
		local cast = g_equipAsc_castTab

		for k, v in pairs(tab_csv) do
			local type = tonumber(v.equip_type)

			if not cast[type] then
				cast[type] = {}
			end

			cast[type][tonumber(v.level)] = {
				consume_list = getItemListFromStr(v.consume_list),
				effect_value = getAttrListFromStr(v["effect_value)"])
			}
		end
	end

	if not g_equipAsc_tierTab then
		local tab_csv = d_ms.d_csv.open2("csv_config/equip_reborn_fate.csv")
		g_equipAsc_tierTab = {}
		local tier = g_equipAsc_tierTab

		for k, v in pairs(tab_csv) do
			local stab = d_ms.d_str.split(v.equip_list, "|")
			local equips = {}

			for m, n in pairs(stab) do
				equips[m] = tonumber(n)
			end

			local equipStr = nil

			for _, equip in ipairs(equips) do
				local name = d_ms.d_data.getCertainInfo(o_t.item, equip).name

				if equipStr then
					equipStr = equipStr .. "," .. name
				else
					equipStr = gethz("cast12") .. " " .. name
				end
			end

			local effect_value = getAttrListFromStr(v.effect_list)
			local desc = {}

			for _, attr in ipairs(effect_value) do
				local tmp = getTierAttrDesc(attr)

				table.insert(desc, tmp)
			end

			tier[tonumber(v.index)] = {
				name = v.fate_name,
				equip_list = equips,
				effect_value = effect_value,
				desc = desc,
				equipStr = equipStr
			}
		end
	end

	if not g_equipAsc_avgTab then
		local tab_csv = d_ms.d_csv.open2("csv_config/equip_reborn_level_plus.csv")
		g_equipAsc_avgTab = {}
		local avg = g_equipAsc_avgTab

		for k, v in pairs(tab_csv) do
			table.insert(avg, {
				cast_level = tonumber(v.cast_level),
				effect_value = getAttrListFromStr(v.effect_list),
				name = v.name
			})
		end

		table.sort(avg, function (a, b)
			return a.cast_level < b.cast_level
		end)
	end
end

function getOmenConfig()
	if not g_omen_rankTable then
		local tab_csv = d_ms.d_csv.open2("csv_config/monster_top_prize.csv")
		g_omen_rankTable = {}
		local rank = g_omen_rankTable

		for k, v in pairs(tab_csv) do
			rank[k] = {
				min = tonumber(v.min_order),
				max = tonumber(v.max_order),
				prize_list = getItemListFromStr(v.prize_list)
			}
		end
	end

	if not g_omen_foodTable then
		local tab_csv = d_ms.d_csv.open2("csv_config/monster_food_prize.csv")
		g_omen_foodTable = {}
		local food = g_omen_foodTable

		for k, v in pairs(tab_csv) do
			food[tonumber(v.index)] = {
				food_count = tonumber(v.left_food),
				prize_list = getItemListFromStr(v.prize_list)
			}
		end
	end
end

function getAchievementsCSVConfig()
	if not g_achieveTable then
		local achieve_tab_csv = d_ms.d_csv.open2("csv_config/achievements_config.csv")
		g_achieveTable = {}
		local achTab = g_achieveTable

		for k, v in ipairs(achieve_tab_csv) do
			if not achTab[k] then
				achTab[k] = {}
			end

			local achieve = achTab[k]
			achieve.sort_id = k
			achieve.id = tonumber(v.id)
			achieve.category = tonumber(v.category)
			achieve.name = v.name
			achieve.desc = v.desc
			local point = tonumber(v.plus_point)
			local ptype = v.plus_type

			if ptype == "A" then
				achieve.plus_str = "+" .. point
			elseif ptype == "R" then
				achieve.plus_str = "+" .. point .. "%"
			else
				cclog("achievements_config.csv plus_type error")
			end

			achieve.repeatable = v.repeatable == "Y"
			achieve.is_open = v.is_open == "Y"
			achieve.full_progress = tonumber(v.full_progress)
			achieve.max_repeatable_times = tonumber(v.max_repeatable_times)
		end
	end
end

function getStoneAttrCSVConfig()
	if not g_stoneAttrTable then
		local stone_csv = d_ms.d_csv.open2("csv_config/stone_cost_worth.csv")
		g_stoneAttrTable = {}
		local stoneTab = g_stoneAttrTable

		for k, v in pairs(stone_csv) do
			local stone_type = tonumber(v.stone_type)

			if not stoneTab[stone_type] then
				stoneTab[stone_type] = {}
			end

			local level = tonumber(v.level)

			if not stoneTab[stone_type][level] then
				stoneTab[stone_type][level] = {}
			end

			local cell = stoneTab[stone_type][level]
			cell.base = tonumber(v.base)
			cell.cost = tonumber(v.cost)
			cell.worth = tonumber(v.worth)
			cell.silver_cost = tonumber(v.silver_cost)
		end
	end
end

function getCheerCSVConfig()
	if g_cheerTable == nil then
		local cheer_tab_csv = d_ms.d_csv.open("csv_config/cortege_cheer_config.csv")
		g_cheerTable = {}
		local cheer = g_cheerTable

		for k, v in pairs(cheer_tab_csv.records) do
			local index = tonumber(v[1])

			if not cheer[index] then
				cheer[index] = {}
			end

			local level = tonumber(v[2])
			cheer[index][level] = {}
			local tab = cheer[index][level]
			tab.cost = tonumber(v[11])
			tab.plus = {}
			tab.plus_dynamic = {}
			tab.plus[1] = tonumber(v[7])
			tab.plus_dynamic[1] = tonumber(v[8])
			tab.plus[2] = tonumber(v[3])
			tab.plus_dynamic[2] = tonumber(v[4])
			tab.plus[3] = tonumber(v[5])
			tab.plus_dynamic[3] = tonumber(v[6])
			tab.plus[4] = tonumber(v[9])
			tab.plus_dynamic[4] = tonumber(v[10])
		end
	end
end

function getFriendsLvRewardCSVConfig()
	if g_friendsLvRewardTable == nil then
		local friends_lv_tab_csv = d_ms.d_csv.open2("csv_config/friends_lv_reward.csv")
		g_friendsLvRewardTable = {}
		local lvReward = g_friendsLvRewardTable

		for k, v in pairs(friends_lv_tab_csv) do
			local index = tonumber(v.index)

			if not lvReward[index] then
				lvReward[index] = {}
			end

			lvReward[index].level = tonumber(v.level)
			lvReward[index].max_count = tonumber(v.max_count)
			local attach = tostring(v.attach_list)

			if attach and #attach > 0 then
				local attach_list = {}
				local stab = d_ms.d_str.split(attach, "/")

				for i = 1, #stab do
					local substab = d_ms.d_str.split(stab[i], "|")
					attach_list[i] = {
						object_type = tonumber(substab[1]),
						attach_type = tonumber(substab[2]),
						attach_level = tonumber(substab[3]),
						attach_count = tonumber(substab[4])
					}
				end

				lvReward[index].attach_list = attach_list
			end
		end
	end
end

function getFriendsVipRewardCSVConfig()
	if g_friendsVipRewardTable == nil then
		local friends_vip_tab_csv = d_ms.d_csv.open2("csv_config/friends_recharge_reward.csv")
		g_friendsVipRewardTable = {}
		local vipReward = g_friendsVipRewardTable

		for k, v in pairs(friends_vip_tab_csv) do
			local index = tonumber(v.vip_level)

			if not vipReward[index] then
				vipReward[index] = {}
			end

			local attach = tostring(v.reward)

			if attach and #attach > 0 then
				local attach_list = {}
				local stab = d_ms.d_str.split(attach, "/")

				for i = 1, #stab do
					local substab = d_ms.d_str.split(stab[i], "|")
					attach_list[i] = {
						object_type = tonumber(substab[1]),
						attach_type = tonumber(substab[2]),
						attach_level = tonumber(substab[3]),
						attach_count = tonumber(substab[4])
					}
				end

				vipReward[index].attach_list = attach_list
				vipReward[index].max_count = v.max_count
			end
		end
	end
end

function getShopItemsPriceCSVConfig()
	if g_shopItemsPriceTable == nil then
		local shop_sell_tab_csv = d_ms.d_csv.open2("csv_config/item_buy_config.csv")
		g_shopItemsPriceTable = {}
		local shop_sell_tab = g_shopItemsPriceTable

		for k, v in pairs(shop_sell_tab_csv) do
			local index = tonumber(v.index)

			if not shop_sell_tab[index] then
				shop_sell_tab[index] = {}
			end

			shop_sell_tab[index].page_id = tonumber(v.page_id)
			local type_id_tab = tostring(v.type_id)
			local tmp_table = d_ms.d_str.split(type_id_tab, "|")
			shop_sell_tab[index].main_type = tonumber(tmp_table[1])
			shop_sell_tab[index].type_id = tonumber(tmp_table[2])
			shop_sell_tab[index].amount = tonumber(tmp_table[3])
			shop_sell_tab[index].price = tonumber(v.buy_price)
			shop_sell_tab[index].vip_level = tonumber(v.vip_level)
			local begin_time = tonumber(v.begin_time)
			local end_time = tonumber(v.end_time)

			if begin_time ~= 0 and end_time ~= 0 then
				local btime = tostring(v.begin_time)
				local etime = tostring(v.end_time)
				shop_sell_tab[index].begin_time = os.time({
					hour = 0,
					year = string.sub(btime, 1, 4),
					month = string.sub(btime, 5, 6),
					day = string.sub(btime, 7, 8)
				})
				shop_sell_tab[index].end_time = os.time({
					hour = 0,
					year = string.sub(etime, 1, 4),
					month = string.sub(etime, 5, 6),
					day = string.sub(etime, 7, 8)
				})
			end

			shop_sell_tab[index].sort_order = tonumber(v.order)
			local attach = tostring(v.attach_list)

			if attach and #attach > 0 then
				local attach_list = {}
				local stab = d_ms.d_str.split(attach, "/")

				for i = 1, #stab do
					local substab = d_ms.d_str.split(stab[i], "|")
					attach_list[i] = {
						object_type = tonumber(substab[1]),
						attach_type = tonumber(substab[2]),
						attach_level = tonumber(substab[3]),
						attach_count = tonumber(substab[4])
					}
				end

				shop_sell_tab[index].attach_list = attach_list
			end
		end
	end
end

function getCortCollectPrizeFromStr(str)
	local tab = d_ms.d_str.split(str, "|")

	return {
		type = tonumber(tab[1]),
		value = tonumber(tab[2])
	}
end

function getCortList(str)
	local list = {}
	local stab = d_ms.d_str.split(str, "/")

	for i = 1, #stab do
		local sub = d_ms.d_str.split(stab[i], "|")

		table.insert(list, {
			type = tonumber(sub[1])
		})
	end

	return list
end

function getCortCollectCSVConfig()
	if not g_cort_collect_tab then
		local tab_csv = d_ms.d_csv.open2("csv_config/collector_cortege.csv")
		g_cort_collect_tab = {}

		for k, v in pairs(tab_csv) do
			g_cort_collect_tab[tonumber(v.index)] = {
				name = v.name,
				prize = getCortCollectPrizeFromStr(v.prize),
				line_up = getCortList(v.line_up),
				desc = v.desc
			}
		end
	end
end

function getRewardOverTimeCSVConfig()
	if g_rotTable == nil then
		local rot_csv = d_ms.d_csv.open2("csv_config/reward_over_time.csv")
		g_rotTable = {}
		local rot_tab = g_rotTable

		for k, v in pairs(rot_csv) do
			local index = tonumber(v.index)

			if not rot_tab[index] then
				rot_tab[index] = {}
			end

			rot_tab[index].interval = tonumber(v.interval) * 60
			local attach = tostring(v.attach_list)

			if attach and #attach > 0 then
				local attach_list = {}
				local stab = d_ms.d_str.split(attach, "/")

				for i = 1, #stab do
					local substab = d_ms.d_str.split(stab[i], "|")
					attach_list[i] = {
						object_type = tonumber(substab[1]),
						attach_type = tonumber(substab[2]),
						attach_level = tonumber(substab[3]),
						attach_count = tonumber(substab[4])
					}
				end

				rot_tab[index].attach_list = attach_list
			end
		end
	end
end

function getRechargeItemsPriceCSVConfig()
	if g_rechargeItemsPriceTable == nil then
		local recharge_csv = d_ms.d_csv.open2("csv_config/order_config.csv")
		g_rechargeItemsPriceTable = {}
		local recharge_tab = g_rechargeItemsPriceTable
		local platform = d_ms.d_tp_config.getThirdPartyFlag()

		for k, v in pairs(recharge_csv) do
			local index = tonumber(v.item_id)

			if not recharge_tab[index] then
				recharge_tab[index] = {}
			end

			if v.category == "2" and platform == 8 or v.category == "4" and platform == 41 or v.category == "4" and platform == 42 or v.category == "1" and platform ~= 8 and platform ~= 41 and platform ~= 42 then
				recharge_tab[index].price = tonumber(v.item_price) / 100
				recharge_tab[index].gold_count = tonumber(v.gold_count)
				recharge_tab[index].plus_count = tonumber(v.plus_count)
				recharge_tab[index].item_name = tostring(v.item_name)
				recharge_tab[index].item_desc = tostring(v.item_desc)
				recharge_tab[index].product_id = tostring(v.product_id)
			end
		end
	end
end

function getGoldRushCSVConfig()
	if g_goldRushTable == nil then
		local csv = d_ms.d_csv.open2("csv_config/gold_rush_config.csv")
		g_goldRushTable = {}

		for k, v in pairs(csv) do
			local index = tonumber(v.rush_times)

			if not g_goldRushTable[index] then
				g_goldRushTable[index] = {}
			end

			local v2 = tostring(v.gold)
			local stab = d_ms.d_str.split(v2, "|")
			g_goldRushTable[index].pay = tonumber(stab[1])
			g_goldRushTable[index].min_gain = tonumber(stab[2])
			g_goldRushTable[index].max_gain = tonumber(stab[3])
		end
	end
end

function getMiniGameCSVConfig()
	if g_miniGameIntroTable == nil then
		local csv = d_ms.d_csv.open2("csv_config/guide_index.csv")
		g_miniGameIntroTable = {}

		for k, v in pairs(csv) do
			local record = {
				title = v.title,
				content = v.content
			}

			if #record.title == 0 then
				record.title = nil
			end

			if #record.content == 0 then
				record.content = nil
			end

			g_miniGameIntroTable[k] = record
		end
	end

	if g_miniGameDetailTable == nil then
		local csv = d_ms.d_csv.open2("csv_config/guide_detail.csv")
		g_miniGameDetailTable = {}
		local detail = g_miniGameDetailTable

		for k, v in ipairs(csv) do
			local index = tonumber(v.index)

			if not detail[index] then
				detail[index] = {}
			end

			table.insert(detail[index], v.content)
		end
	end
end

function getCharacterQualityCSVConfig()
	if g_characterQualityTable == nil then
		local role_prop_tab_csv = d_ms.d_csv.open("csv_config/cortege_quality.csv")
		g_characterQualityTable = {}
		local role_prop_tab = g_characterQualityTable

		for k, v in pairs(role_prop_tab_csv.records) do
			local idx = tonumber(v[1])
			local convert = tonumber(v[2])
			local compose = tonumber(v[3])
			local worth = tonumber(v[4])
			local cortege_worth = tonumber(v[5])

			if not role_prop_tab[idx] then
				role_prop_tab[idx] = {}
			end

			role_prop_tab[idx].convert = convert
			role_prop_tab[idx].compose = compose
			role_prop_tab[idx].worth = worth
			role_prop_tab[idx].cortege_worth = cortege_worth
		end
	end
end

function getTopScoreExchangeCSVConfig()
	if g_topScoreExchangeTable == nil then
		local score_tab_csv = d_ms.d_csv.open("csv_config/top_score_exchange.csv")
		g_topScoreExchangeTable = {}
		local score_tab = g_topScoreExchangeTable

		for k, v in pairs(score_tab_csv.records) do
			local idx = tonumber(v[1])
			local score = tonumber(v[2])

			if not score_tab[idx] then
				score_tab[idx] = {}
			end

			score_tab[idx].score = score
			local stab = d_ms.d_str.split(v[3], "|")
			local promoteOrder = tonumber(v[4])
			score_tab[idx].promoteOrder = promoteOrder

			for i = 1, #stab do
				score_tab[idx].object_type = tonumber(stab[1])
				score_tab[idx].sub_type = tonumber(stab[2])
				score_tab[idx].count = tonumber(stab[3])
			end
		end
	end
end

function getTopScoreCSVConfig()
	if g_topScoreTable == nil then
		local top_score_csv = d_ms.d_csv.open("csv_config/top_score.csv")
		g_topScoreTable = {}
		local top_score = g_topScoreTable

		for k, v in pairs(top_score_csv.records) do
			local idx = tonumber(v[1])
			top_score[idx] = {}
			local tab = top_score[idx]
			tab.upper = idx
			tab.lower = tonumber(v[2])
			tab.score = tonumber(v[3])
			tab.day_score = tonumber(v[4])
		end
	end
end

function getTowerCSVConfig()
	if g_towerUnionConfig == nil then
		local tmp_csv = d_ms.d_csv.open2("csv_config/tower_road.csv")
		g_towerUnionConfig = {}
		local move = {
			{
				x = 0,
				y = 1
			},
			{
				x = -1,
				y = 0
			},
			{
				x = 1,
				y = 0
			}
		}

		for k, v in pairs(tmp_csv) do
			local strTab = d_ms.d_u.splitUTF8String(v.road)
			local road = {}
			local magic_pos = {
				x = 0,
				y = 0
			}

			for k, v in pairs(strTab) do
				road[k] = move[tonumber(v)]
				magic_pos.x = magic_pos.x + road[k].x
				magic_pos.y = magic_pos.y + road[k].y
			end

			local old = tonumber(v.old)
			local new = tonumber(v.new)

			if not g_towerUnionConfig[old] then
				g_towerUnionConfig[old] = {}
			end

			g_towerUnionConfig[old][new] = {
				road = road,
				magic_pos = magic_pos
			}
		end
	end

	if g_towerComposeConfig == nil then
		local tmp_csv = d_ms.d_csv.open2("csv_config/tower_compose.csv")
		g_towerComposeConfig = {}

		for k, v in pairs(tmp_csv) do
			local bricks = {}
			local stab = d_ms.d_str.split(v.bricks, "/")
			local tx = 0
			local ty = 0
			local count = 0

			for m, n in pairs(stab) do
				local sub_stab = d_ms.d_str.split(n, "|")
				local xx = tonumber(sub_stab[1])
				local yy = tonumber(sub_stab[2])
				bricks[m] = {
					x = xx,
					y = yy
				}
				tx = tx + xx
				ty = ty + yy
				count = count + 1
			end

			g_towerComposeConfig[k] = {
				bricks = bricks,
				mid = {
					x = tx / count,
					y = ty / count
				}
			}
		end
	end

	if g_towerLevelConfig == nil then
		local tmp_csv = d_ms.d_csv.open2("csv_config/tower_level.csv")
		g_towerLevelConfig = {}

		for k, v in pairs(tmp_csv) do
			g_towerLevelConfig[tonumber(v.sky_index)] = tonumber(v.need_steps)
		end
	end
end

function getCardTipConfig()
	if not g_card_tip then
		local tab_csv = d_ms.d_csv.open2("csv_config/cards_tip.csv")
		g_card_tip = {}

		for k, v in pairs(tab_csv) do
			g_card_tip[tonumber(v.index)] = v.tip
		end
	end
end

function getDevolveConfig()
	if not g_devolveTable then
		local devolve_csv = d_ms.d_csv.open2("csv_config/cortege_devolve.csv")
		g_devolveTable = {}
		local devTab = g_devolveTable

		for k, v in pairs(devolve_csv) do
			local lv = tonumber(v.evolve_level)
			devTab[lv] = {
				jiehun_count = tonumber(v.jiehun_count),
				consume_item_list = getItemListFromStr(v.consume_item_list)
			}
		end
	end
end

function getItemFromStr(str)
	local item = {}
	local stab = d_ms.d_str.split(str, "|")
	item.object_type = tonumber(stab[1])
	item.attach_type = tonumber(stab[2])
	item.attach_level = tonumber(stab[3])
	item.attach_count = tonumber(stab[4])

	return item
end

function getItemListFromStr(str)
	local list = {}
	local stab = d_ms.d_str.split(str, "/")

	for i = 1, #stab do
		table.insert(list, getItemFromStr(stab[i]))
	end

	return list
end

function getTransInfoByTypeid(type_id, returnAll)
	if g_convertTable and g_convertTable[type_id] then
		if returnAll then
			return g_convertTable[type_id]
		else
			return g_convertTable[type_id][1] or g_convertTable[type_id][2]
		end
	end
end

function getMaterialTransformCSVConfig()
	if not g_materialIndexTable then
		local material_tab_csv = d_ms.d_csv.open2("csv_config/material_transform_index.csv")
		g_materialIndexTable = {
			{},
			{},
			{}
		}

		for k, v in pairs(material_tab_csv) do
			local category = tonumber(v.category)

			if category > 200 then
				g_materialIndexTable[3][category - 200] = v.name
			elseif category > 100 then
				g_materialIndexTable[2][category - 100] = v.name
			else
				g_materialIndexTable[1][category] = v.name
			end
		end
	end

	if not g_materialTable then
		local material_tab_csv = d_ms.d_csv.open2("csv_config/material_transform.csv")
		g_materialTable = {}
		g_convertTable = {}
		local materialTab = g_materialTable

		for k, v in pairs(material_tab_csv) do
			local category = tonumber(v.category)

			if not materialTab[category] then
				materialTab[category] = {}
			end

			local line = {
				category = category,
				src_material = getItemListFromStr(v.src_material),
				cost_material = getItemListFromStr(v.cost_material),
				is_random = v.is_random == "1"
			}

			if line.is_random then
				line.des_material = getItemListFromStr(v.des_material)
			else
				line.des_material = getItemFromStr(v.des_material)
			end

			line.min_role_level = tonumber(v.min_role_level)
			line.desc = v.desc or ""
			line.category = category

			for k, v in pairs(line.src_material) do
				local single = d_ms.d_c.table_copy(line)
				single.src_material = v

				table.insert(materialTab[category], single)

				if not g_convertTable[v.attach_type] then
					g_convertTable[v.attach_type] = {}
				end

				local index = category > 100 and 2 or 1
				g_convertTable[v.attach_type][index] = single
			end
		end

		local material_tab_csv = d_ms.d_csv.open2("csv_config/skill_material_transform.csv")
		local materialTab = g_materialTable

		for k, v in pairs(material_tab_csv) do
			local category = tonumber(v.category)

			if not materialTab[category] then
				materialTab[category] = {}
			end

			local line = {
				category = category,
				src_material = getItemListFromStr(v.src_material),
				cost_material = getItemListFromStr(v.cost_material),
				is_random = v.is_random == "1",
				des_material = getItemListFromStr(v.des_material),
				min_role_level = tonumber(v.min_role_level),
				desc = v.desc or "",
				category = category
			}

			for k, v in pairs(line.src_material) do
				local single = d_ms.d_c.table_copy(line)
				single.src_material = v

				table.insert(materialTab[category], single)

				if not g_convertTable[v.attach_type] then
					g_convertTable[v.attach_type] = {}
				end

				local index = 3
				g_convertTable[v.attach_type][index] = single
			end
		end
	end
end

g_soulsTypeTable = nil
g_soulsInfoTable = nil

function initSoulsData()
	if not g_soulsTypeTable then
		g_soulsTypeTable = {}
		g_soulsInfoTable = {}
	end
end

function recvSoulsDataFromServer(msg_table)
	if msg_table.first_send == true then
		g_soulsInfoTable = {}
		g_soulsTypeTable = {}

		for i = 1, #msg_table.spirit_list do
			local spiritInfo = msg_table.spirit_list[i]

			if spiritInfo.count > 0 then
				g_soulsInfoTable[#g_soulsInfoTable + 1] = getSoulInfo(spiritInfo.type_id, spiritInfo.count)
				g_soulsTypeTable[spiritInfo.type_id] = spiritInfo.count
			end
		end
	elseif g_soulsInfoTable == nil then
		local tmp_req = {
			flag = -1
		}

		cclog("send ST_msg_query_cortege_list_1033 to BS.")
		d_ms.d_u.main_server_send_msg(d_ms.d_msg_def.gscl_msg_id.msg_query_top_list, tmp_req)

		return
	else
		for i = 1, #msg_table.spirit_list do
			local spiritInfo = msg_table.spirit_list[i]

			if spiritInfo.count > 0 then
				g_soulsInfoTable[#g_soulsInfoTable + 1] = getSoulInfo(spiritInfo.type_id, spiritInfo.count)
				g_soulsTypeTable[spiritInfo.type_id] = spiritInfo.count
			end
		end
	end

	g_soulsInfoTable.isSorted = false
end

function updateAllSoulsStatus()
	for i = 1, #g_soulsInfoTable do
		local spiritInfo = g_soulsInfoTable[i]

		if spiritInfo.count > 0 then
			g_soulsInfoTable[i] = getSoulInfo(spiritInfo.type_id, spiritInfo.count)
		end
	end
end

function getSoulInfo(soulType, soulCount)
	local soulTable = {
		count = soulCount
	}
	local charInfo = getCharBySoul(soulType)
	soulTable.type = soulType
	soulTable.type_id = soulType
	soulTable.isSoul = true

	if charInfo then
		d_ms.d_feishengUI.getFeiShengCount()

		local feiShengCount = d_ms.d_feishengUI.g_feiShengCount
		local level = charInfo.evolve_level or 0
		soulTable.feiShengCount = (feiShengCount[level + 1] or feiShengCount[level]) - soulCount
		soulTable.csvInfo = charInfo.csvInfo
	else
		soulTable.csvInfo = d_ms.d_lineupUI.g_characterAttrTable[soulType]
		local quality = soulTable.csvInfo.quality

		if not g_characterQualityTable then
			getCharacterQualityCSVConfig()
		end

		soulTable.huanHunCount = g_characterQualityTable[quality].compose - soulCount
	end

	return soulTable
end

function getCharBySoul(type_id)
	local chartab = d_ms.d_lineupUI.g_characterInfo
	local charInfo = nil

	for i = 1, #chartab do
		if chartab[i].type == type_id then
			charInfo = chartab[i]

			break
		end
	end

	return charInfo
end

function updateSoulInfo(type_id)
	local soulsInfoTable = g_soulsInfoTable

	for i = 1, #soulsInfoTable do
		if soulsInfoTable[i].type == type_id then
			soulsInfoTable[i] = getSoulInfo(soulsInfoTable[i].type, soulsInfoTable[i].count)

			break
		end
	end
end

function refreshSoulNeed(type_id)
	local soulsInfoTable = g_soulsInfoTable

	if not soulsTable then
		initSoulsData()
	end

	for i = 1, #soulsInfoTable do
		if soulsInfoTable[i].type == type_id then
			soulsInfoTable[i] = getSoulInfo(type_id, soulsInfoTable[i].count)

			break
		end
	end
end

function updateSoulsData(msg_table)
	local soulsInfoTable = g_soulsInfoTable
	local soulsTypeTable = g_soulsTypeTable

	if not soulsTable then
		initSoulsData()
	end

	soulsInfoTable.isSorted = false
	local isFound = false

	for i = 1, #soulsInfoTable do
		if soulsInfoTable[i].type == msg_table.type_id then
			if msg_table.total_count == 0 then
				table.remove(soulsInfoTable, i)
			else
				soulsInfoTable[i] = getSoulInfo(msg_table.type_id, msg_table.total_count)
			end

			isFound = true

			break
		end
	end

	if not isFound then
		soulsInfoTable[#soulsInfoTable + 1] = getSoulInfo(msg_table.type_id, msg_table.total_count)
	end

	if msg_table.total_count == 0 then
		soulsTypeTable[msg_table.type_id] = nil
	else
		soulsTypeTable[msg_table.type_id] = msg_table.total_count
	end

	d_ms.d_allLineupUI.updateSoulCellByType(msg_table.type_id)
end

function getCertainInfo(object_type, type_id)
	local info = nil

	if object_type == d_ms.d_common_def.object_type.item then
		info = d_ms.d_packageUI.g_itemAttrTable[type_id]
	elseif object_type == d_ms.d_common_def.object_type.skill then
		info = d_ms.d_packageUI.g_itemSkillTable[type_id]
	elseif object_type == d_ms.d_common_def.object_type.spirit then
		info = d_ms.d_c.table_copy(d_ms.d_lineupUI.g_characterAttrTable[type_id])
		info.name = info.name .. gethz("hunTip")
		info.isSpirit = true
	elseif object_type == d_ms.d_common_def.object_type.cortege then
		info = d_ms.d_lineupUI.g_characterAttrTable[type_id]
		info.isSpirit = false
	elseif object_type == d_ms.d_common_def.object_type.animal then
		info = {
			name = d_ms.d_petUI.getNameTxt(type_id)
		}
	elseif object_type == d_ms.d_common_def.object_type.gold_coin then
		info = {
			name = gethz("goldHZ"),
			count = d_ms.d_mainUI.g_playerInfo.gold_coin
		}
	elseif object_type == d_ms.d_common_def.object_type.silver_coin then
		info = {
			name = gethz("money"),
			count = d_ms.d_mainUI.g_playerInfo.silver_coin
		}
	end

	return info
end

function getGoldSprite()
	return getSingleSpriteFromPng("items/all_daoju1.png", dj_w, dj_h, 7)
end

function getSilverSprite()
	return getSingleSpriteFromPng("items/all_daoju1.png", dj_w, dj_h, 8)
end

function getBoxSprite()
	return getSingleSpriteFromPng("items/all_daoju1.png", dj_w, dj_h, 16)
end

function getCertainBigSpriteFile(object_type, type_id)
	local fileName = nil

	if object_type == d_ms.d_common_def.object_type.item then
		fileName = getBigItemFileName(type_id)
	elseif object_type == d_ms.d_common_def.object_type.skill then
		fileName = getBigItemFileName(type_id)
	elseif object_type == d_ms.d_common_def.object_type.spirit then
		fileName = getBodySpriteFilename(type_id)
	elseif object_type == d_ms.d_common_def.object_type.cortege then
		fileName = getBodySpriteFilename(type_id)
	elseif object_type == d_ms.d_common_def.object_type.gold_coin then
		fileName = "v2/other1.png"
	elseif object_type == d_ms.d_common_def.object_type.silver_coin then
		fileName = "v2/other1.png"
	else
		fileName = "v2/other1.png"
	end

	return fileName
end

function getCertainBigSprite(object_type, type_id)
	local sprite = nil

	if object_type == d_ms.d_common_def.object_type.item then
		sprite = getBigItemSprite(type_id)
	elseif object_type == d_ms.d_common_def.object_type.skill then
		sprite = getBigSkillSprite(type_id)
	elseif object_type == d_ms.d_common_def.object_type.spirit then
		sprite = getBodySprite(type_id)
	elseif object_type == d_ms.d_common_def.object_type.cortege then
		sprite = getBodySprite(type_id)
	elseif object_type == d_ms.d_common_def.object_type.gold_coin then
		sprite = getGoldSprite()
	elseif object_type == d_ms.d_common_def.object_type.silver_coin then
		sprite = getSilverSprite()
	else
		sprite = getBoxSprite()
	end

	return sprite
end

function getCertainSmallSprite(object_type, type_id, level, is_asc, star_level)
	local sprite = nil
	local isOtherType = false

	if object_type == d_ms.d_common_def.object_type.item then
		sprite = getSmallItemSprite(type_id, level, is_asc, star_level)
	elseif object_type == d_ms.d_common_def.object_type.skill then
		sprite = getSmallSkillSprite(type_id)
	elseif object_type == d_ms.d_common_def.object_type.spirit then
		sprite = getHeadSprite(type_id, d_ms.d_lineupUI.g_AscTable[type_id])
		local soul = CCSprite:create("v2/introUI/soul_label.png")

		sprite:addChild(soul)
		d_ms.d_u.setProperties(sprite, soul, {
			scaleW = 0.4,
			x = 0.73,
			y = 0.78
		})
	elseif object_type == d_ms.d_common_def.object_type.cortege then
		sprite = getHeadSprite(type_id, is_asc)
	elseif object_type == d_ms.d_common_def.object_type.animal then
		sprite = d_ms.d_petUI.getHeadSprite(type_id, 1)
	elseif object_type == d_ms.d_common_def.object_type.gold_coin then
		isOtherType = true
		sprite = getGoldSprite()
	elseif object_type == d_ms.d_common_def.object_type.silver_coin then
		isOtherType = true
		sprite = getSilverSprite()
	else
		isOtherType = true
		sprite = getBoxSprite()
	end

	return sprite, isOtherType
end

function getCertainSmallSpriteLevel(object_type, type_id, level, amount)
	local sprite, isOtherType = getCertainSmallSprite(object_type, type_id, level)

	if amount and amount > 1 then
		local level_label1 = d_ms.d_u.createByStyle({
			type = "label",
			fontsize = 26,
			string = "" .. amount,
			anchor = {
				0,
				0
			},
			color = {
				0,
				0,
				0
			}
		})
		local level_label2 = d_ms.d_u.createByStyle({
			fontsize = 26,
			type = "label",
			string = "" .. amount,
			anchor = {
				0,
				0
			}
		})
		local w, h = d_ms.d_u.getRealScale(sprite)

		level_label1:setPosition(9, 9)
		level_label2:setPosition(8, 8)
		sprite:addChild(level_label1)
		sprite:addChild(level_label2)
	end

	return sprite, isOtherType
end

function createTestLayer(parent)
	local testLayer = CCLayer:create()

	parent:addChild(testLayer, 50)

	local scrSize = CCDirector:sharedDirector():getVisibleSize()

	function onTouch(eventType, x, y)
		cclog("x = %f, y = %f", x / scrSize.width, y / scrSize.height)

		return true
	end

	testLayer:registerScriptTouchHandler(onTouch, false, -128, false)
	testLayer:setTouchEnabled(true)
end

function getExpInfo(input_level)
	local level = input_level or d_ms.d_mainUI.g_playerInfo.level

	checkRoleLevelConfigCsv()

	return g_csv_role_level_config[level]
end

function checkRoleLevelConfigCsv()
	if g_csv_role_level_config == nil then
		g_csv_role_level_config = {}
		local tmp_csv = d_ms.d_csv.open2("csv_config/role_level_config.csv")

		for i = 1, #tmp_csv do
			table.insert(g_csv_role_level_config, tonumber(tmp_csv[i].level), tmp_csv[i])
		end

		cclog("checkRoleLevelConfigCsv set ok")
	end
end

g_vip_pri = {}

function getVipPriContent(vip_level)
	if not g_vip_pri or #g_vip_pri <= 0 then
		g_vip_pri = {}
		local tmp_csv_content = d_ms.d_csv.open2("csv_config/vip_pri_config.csv")

		for i, v in pairs(tmp_csv_content) do
			local tmp_vip_level = tonumber(v.vip_level)

			if not g_vip_pri[tmp_vip_level] then
				g_vip_pri[tmp_vip_level] = {}
			end

			local tmp_pri_table = {
				index = tonumber(v.index),
				content = v.pri_content
			}

			table.insert(g_vip_pri[tmp_vip_level], tmp_pri_table)
		end
	end

	return g_vip_pri[vip_level]
end

g_letters = {}

function getSpringCardLetters()
	if not g_letters or #g_letters == 0 then
		local tmp_csv_table = d_ms.d_csv.open2("csv_config/cards_letter.csv")

		for k, v in pairs(tmp_csv_table) do
			local level = tonumber(v.level)
			local letter = v.letter
			g_letters[level] = letter
		end
	end
end

g_summer_letters = {}

function getSummerCardLetters()
	if not g_summer_letters or #g_summer_letters == 0 then
		local tmp_csv_table = d_ms.d_csv.open2("csv_config/summer_cards_letter.csv")

		for k, v in pairs(tmp_csv_table) do
			local level = tonumber(v.level)
			local letter = v.letter
			g_summer_letters[level] = letter
		end
	end
end

g_equipAdvanceExpTab = {}

function getEquipAdvanceExp()
	if not g_equipAdvanceExpTab or #g_equipAdvanceExpTab == 0 then
		g_equipAdvanceExpTab = {}
		local exp = g_equipAdvanceExpTab
		local tmp_csv_table = d_ms.d_csv.open2("csv_config/equip_star_cost.csv")

		for k, v in pairs(tmp_csv_table) do
			local quality = tonumber(v.equip_quality)

			if not exp[quality] then
				exp[quality] = {
					{},
					{},
					{}
				}
			end

			local qualityTab = exp[quality]

			for i = 1, 100 do
				local tar = v["advance" .. i]

				if tar then
					local substab = d_ms.d_str.split(tar, "|")

					for m, n in pairs(qualityTab) do
						if not n[i] then
							n[i] = {}
						end

						n[i][tonumber(v.star_level)] = tonumber(substab[m])
					end
				else
					break
				end
			end
		end
	end
end

g_equipAdvanceCostTab = {}

function getEquipAdvanceCost()
	if not g_equipAdvanceCostTab or #g_equipAdvanceCostTab == 0 then
		g_equipAdvanceCostTab = {}
		local cost = g_equipAdvanceCostTab
		local tmp_csv_table = d_ms.d_csv.open2("csv_config/equip_advance_cost.csv")
		local names = {
			"wuqi_cost",
			"fangyu_cost",
			"fabao_cost"
		}

		for k, v in pairs(tmp_csv_table) do
			local quality = tonumber(v.equip_quality)

			if not cost[quality] then
				cost[quality] = {
					{},
					{},
					{}
				}
			end

			local qualityTab = cost[quality]

			for m, n in pairs(names) do
				local items = {}
				local stab = d_ms.d_str.split(v[n], "/")

				for i = 1, #stab do
					items[i] = {}
					local subStab = d_ms.d_str.split(stab[i], "|")
					items[i].object_type = o_t.item
					items[i].attach_type = tonumber(subStab[1])
					items[i].attach_level = 1
					items[i].attach_count = tonumber(subStab[2])
				end

				qualityTab[m][tonumber(v.advance_level)] = items
			end
		end
	end
end

g_equipAdvanceValueTab = {}

function getEquipAdvanceValue()
	if not g_equipAdvanceValueTab or #g_equipAdvanceValueTab == 0 then
		g_equipAdvanceValueTab = {}
		local value = g_equipAdvanceValueTab
		local tmp_csv_table = d_ms.d_csv.open("csv_config/equip_advance_worth.csv")

		for k, v in pairs(tmp_csv_table.records) do
			local quality = tonumber(v[2])
			local mainType = tonumber(v[1])

			if not value[quality] then
				value[quality] = {}
			end

			if not value[quality][mainType] then
				value[quality][mainType] = {}
			end

			local worth = value[quality][mainType]

			for i = 3, #v do
				local advance = math.floor((i - 2) / 8)
				local star = (i - 2) % 8
				local effect = d_ms.d_str.split(v[i], "|")

				if not worth[advance] then
					worth[advance] = {}
				end

				worth[advance][star] = {
					percent = tonumber(effect[1]),
					plus = tonumber(effect[2]),
					extra = effect[3] and tonumber(effect[3])
				}
			end

			worth[0][0] = {
				percent = 0,
				plus = 0
			}
		end
	end
end

g_guildPartyBuffTab = {}

function getGuildPartyBuff()
	if not g_guildPartyBuffTab or #g_guildPartyBuffTab == 0 then
		g_guildPartyBuffTab = {}
		local tmp_csv_table = d_ms.d_csv.open2("csv_config/union_feast_award.csv")

		for k, v in pairs(tmp_csv_table) do
			g_guildPartyBuffTab[tonumber(v.award_type)] = v
			local substab = d_ms.d_str.split(v.attach_data, "|")
			v.item = {
				object_type = tonumber(substab[1]),
				attach_type = tonumber(substab[2]),
				attach_level = tonumber(substab[3]),
				attach_count = tonumber(substab[4])
			}
		end
	end
end

g_charge_gift = {}

function setChargeGiftDetail(data)
	for i = 1, #data do
		g_charge_gift[i] = {
			itemType = data[i].object_type,
			type_id = data[i].attach_type,
			level = data[i].attach_level,
			count = data[i].attach_count
		}
	end
end

function getChargeGiftDetail()
	return
end

function getRicePuddingConfig()
	if not g_rice then
		g_rice = {}
		local tmp_csv_table = d_ms.d_csv.open2("csv_config/zongzi_formula.csv")

		for _, v in pairs(tmp_csv_table) do
			local gredit = {}
			g_rice[tonumber(v.index)] = gredit
			gredit.source = getItemListFromStr(v.object_type)
			gredit.dest = getItemFromStr(v.sub_type)
		end
	end
end

g_vip_gift_detail = {}

function getVipGiftDetail(vip_level)
	if not g_vip_gift_detail or #g_vip_gift_detail <= 0 then
		local tmp_csv_content = d_ms.d_csv.open2("csv_config/item_receive_config.csv")

		for i, v in pairs(tmp_csv_content) do
			local tmp_vip_index = tonumber(v.index)
			g_vip_gift_detail[tmp_vip_index] = v

			if #v.attach_data > 0 then
				g_vip_gift_detail[tmp_vip_index].gift_list = {}
				local stab = d_ms.d_str.split(v.attach_data, "/")

				for i = 1, #stab do
					local substab = d_ms.d_str.split(stab[i], "|")
					g_vip_gift_detail[tmp_vip_index].gift_list[i] = {
						itemType = tonumber(substab[1]),
						type_id = tonumber(substab[2]),
						level = tonumber(substab[3]),
						count = tonumber(substab[4])
					}
				end
			end
		end
	end

	return g_vip_gift_detail[vip_level]
end

g_cortCall = nil

function getCortCallTable()
	if not g_cortCall then
		local tmp_csv_content = d_ms.d_csv.open2("csv_config/convert_output.csv")

		for i, v in pairs(tmp_csv_content) do
			if not g_cortCall then
				g_cortCall = {}
			end

			v.output_table = {}
			local tmp_p1 = d_ms.d_str.split(v.output, "|")

			for p1 = 1, #tmp_p1 do
				local tmp_p2 = d_ms.d_str.split(tmp_p1[p1], "/")
				local tmp_p3 = {
					type = tonumber(tmp_p2[1]),
					cout = tonumber(tmp_p2[2])
				}

				table.insert(v.output_table, tmp_p3)
			end

			g_cortCall[tonumber(v.src_cortege_type)] = v
		end
	end
end

function getCortCallById(id)
	getCortCallTable()

	local ret = nil

	if g_cortCall[id] and g_cortCall[id].des_cortege_type then
		ret = tonumber(g_cortCall[id].des_cortege_type)
	end

	return ret
end

function getCortCallPrizeById(id)
	getCortCallTable()

	local ret = nil

	if g_cortCall[id] and g_cortCall[id].output_table then
		ret = g_cortCall[id].output_table
	end

	return ret
end

function showItemIntro(parent, item, level)
	if item ~= nil then
		if item.object_type == o_t.spirit then
			showCharacterIntroByTypeId(item.attach_type, parent, true)
		elseif item.object_type == o_t.cortege then
			showCharacterIntroByTypeId(item.attach_type, parent)
		elseif item.object_type == o_t.item or item.object_type == o_t.skill then
			local introLayer = nil

			function closeIntroCallback()
				if introLayer ~= nil then
					introLayer:getParent():removeChild(introLayer, true)
				end
			end

			introLayer = d_ms.d_subLevelUI.createPriItemIntroLayer(item.object_type, item.attach_type, closeIntroCallback, item.attach_level or level)

			parent:addChild(introLayer, 300)
		end
	end
end

function createBuyFixedItem(object_type, type_id)
	local info = getCertainInfo(object_type, type_id)
	local shopItemInfo = getShopItemAttr(object_type, type_id)

	if not info or not shopItemInfo then
		return
	end

	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local main_layer = CCLayer:create()
	local menuArr = CCArray:create()
	local posTab = d_ms.d_loginGameUI.createPrizeBoxBkg(main_layer, 0.65, d_ms.d_loginGameUI.titleType.hint)
	local w = posTab.width
	local h = posTab.height

	local function showItemIntro()
		local introLayer = nil

		local function closeCallback()
			main_layer:removeChild(introLayer, true)
		end

		introLayer = d_ms.d_subLevelUI.createPriItemIntroLayer(o_t.item, type_id, closeCallback)

		main_layer:addChild(introLayer, 10)
	end

	local sprite1 = getCertainSmallSprite(object_type, type_id)
	local sprite2 = getCertainSmallSprite(object_type, type_id)
	local itemMenuSprite = CCMenuItemSprite:create(sprite1, sprite2)

	itemMenuSprite:registerScriptTapHandler(showItemIntro)
	d_ms.d_u.setStyles(itemMenuSprite, {
		x = 0.5,
		y = 0.5,
		anchor = {
			0.5,
			0
		}
	})
	menuArr:addObject(itemMenuSprite)

	local itemNameLabel = d_ms.d_u.createByStyle({
		y = 0.5,
		font = "arial",
		type = "label",
		x = 0.5,
		fontsize = 30,
		string = info.name,
		anchor = {
			0.5,
			1
		}
	})

	main_layer:addChild(itemNameLabel, 1)

	local w1, w2, h1 = nil
	local costStr = gethz("enhance_cost") .. ": " .. shopItemInfo.buy_price .. " "
	local label_cost = d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		x = 0.5,
		fontsize = 30,
		string = costStr,
		y = 0.5 - 0.2 * h,
		color = {
			255,
			215,
			169
		}
	})

	main_layer:addChild(label_cost, 1)

	w1, h1 = d_ms.d_u.getRealScale(label_cost)
	local moneyPic = shopItemInfo.money_type == o_t.gold_coin and "v2/money_gold.png" or "v2/money_silver.png"
	local gold_icon = d_ms.d_u.createByStyle({
		x = 0.5,
		pic = moneyPic,
		y = 0.5 - 0.2 * h,
		scaleH = h1 * 0.75
	})

	main_layer:addChild(gold_icon, 1)

	w2, _ = d_ms.d_u.getRealScale(gold_icon)

	label_cost:setPositionX((0.5 - 0.5 * w2) * scrSize.width)
	gold_icon:setPositionX((0.5 + 0.5 * w1) * scrSize.width)

	local hintStr = string.format(gethz("ensure_buy_drill_material"), info.name)
	local label_hint = d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		x = 0.5,
		fontsize = 30,
		string = hintStr,
		y = 0.5 - 0.4 * h + 0.5 * h1,
		color = {
			192,
			213,
			86
		}
	})

	main_layer:addChild(label_hint, 1)

	local function pressYes()
		local parent = main_layer:getParent()

		d_ms.d_u.remove(main_layer)

		local player = d_ms.d_mainUI.g_playerInfo

		if shopItemInfo.money_type == o_t.gold_coin then
			if player.gold_coin < shopItemInfo.buy_price then
				d_ms.d_summonUI.needGold(parent, true)

				return
			end
		elseif shopItemInfo.money_type == o_t.silver_coin and player.silver_coin < shopItemInfo.buy_price then
			d_ms.d_info.show(gethz("enhance_cannot1"))

			return
		end

		d_ms.d_shopUI.g_buyAndUse = type_id
		local tmpMsg = {
			count = 1,
			first_send = 0,
			page_id = 2,
			index = shopItemInfo.index,
			type_id = type_id
		}

		d_ms.d_u.main_server_send_msg(d_ms.d_msg_def.gscl_msg_id.msg_buy_item_in_batch, tmpMsg)
	end

	local function pressNo()
		d_ms.d_u.remove(main_layer)
	end

	local cancelButton = CCMenuItemImage:create("v2/buttons/cancel1.png", "v2/buttons/cancel2.png")

	cancelButton:registerScriptTapHandler(pressNo)
	cancelButton:setPosition(posTab.first.x, posTab.first.y)
	menuArr:addObject(cancelButton)

	local buyButton = CCMenuItemImage:create("v2/buttons/buy1.png", "v2/buttons/buy2.png")

	buyButton:registerScriptTapHandler(pressYes)
	buyButton:setPosition(posTab.second.x, posTab.second.y)
	menuArr:addObject(buyButton)

	local menu = CCMenu:createWithArray(menuArr)

	menu:setPosition(CCPointMake(0, 0))
	main_layer:addChild(menu, 1)

	return main_layer
end

function showCertainIntro(parent, info, isGot)
	if not isGot then
		showItemIntro(parent, {
			object_type = info.attach_type,
			attach_type = info.type
		})
	else
		if info.attach_type == o_t.item or info.attach_type == o_t.skill then
			local introLayer = nil

			function closeIntroCallback()
				if introLayer ~= nil then
					introLayer:getParent():removeChild(introLayer, true)
				end
			end

			introLayer = d_ms.d_packageUI.createItemIntroLayer(info, closeIntroCallback)

			parent:addChild(introLayer, 300)

			return
		end

		if info.type then
			local object_type = info.object_type

			if object_type == o_t.spirit or info.isSoul then
				showCharacterIntroByTypeId(info.type, parent, true)
			else
				showCharacterIntroByTypeId(info.type, parent, false)
			end
		end
	end
end

function showCharacterIntroByTypeId(type_id, parent, isSoul)
	local isSoul = isSoul or false
	local charIntoTable = {}

	local function menuCancel()
		d_ms.d_music_mgr.playClickEffect()

		if charIntoTable.mainLayer then
			charIntoTable.mainLayer:removeFromParentAndCleanup(true)
		end
	end

	local lt_IntroMenuList = {
		{
			npic = "v2/multi-selectUI/back1.png",
			spic = "v2/multi-selectUI/back2.png",
			y = 0.125,
			x = 0.26171875,
			call_back = menuCancel
		},
		{
			npic = "v2/introUI/close1.png",
			spic = "v2/introUI/close2.png",
			y = 0.9583333333333334,
			x = 0.9609375,
			call_back = menuCancel
		},
		x = 0,
		y = 0
	}
	local argInfoTab = {
		csvInfo = d_ms.d_c.table_copy(d_ms.d_lineupUI.g_characterAttrTable[type_id]),
		type = type_id,
		order = 1
	}
	argInfoTab.hp = argInfoTab.csvInfo.hp
	argInfoTab.magic = argInfoTab.csvInfo.mana
	argInfoTab.gongji = argInfoTab.csvInfo.damage
	argInfoTab.fangyu = argInfoTab.csvInfo.defence
	argInfoTab.hp_plus = argInfoTab.csvInfo.hpOffset
	argInfoTab.magic_plus = argInfoTab.csvInfo.manaOffset
	argInfoTab.gongji_plus = argInfoTab.csvInfo.damageOffset
	argInfoTab.fangyu_plus = argInfoTab.csvInfo.defenceOffset
	argInfoTab.culture_point = 0
	argInfoTab.id = 0
	argInfoTab.level = 1
	argInfoTab.reborn_layer = d_ms.d_lineupUI.g_AscTable[type_id] and 1 or 0

	d_ms.d_formationUI.createCharacterIntroduceLayer(charIntoTable, parent, argInfoTab, 100, isSoul, lt_IntroMenuList)
end

function createRelativeTestLayer(parent, size, pos)
	local layer = CCLayer:create()

	parent:addChild(layer)

	local function onTouch(eventType, x, y)
		cclog("x = %f, y = %f", (x - pos.x) / size.width, (y - pos.y) / size.height)

		return true
	end

	layer:registerScriptTouchHandler(onTouch, false, -128, false)
	layer:setTouchEnabled(true)
end

function getNumberSprite(num, height)
	if not num or num < 0 then
		return
	end

	local numNode = CCNode:create()
	local numStr = tostring(num)
	local totalWidth = 0
	local num_sprite = {}

	for i = 1, #numStr do
		local _bit = string.sub(numStr, i, i)
		num_sprite[i] = {}
		local tmp = num_sprite[i]
		tmp.sprite = CCSprite:create("v2/vip/" .. _bit .. ".png")
		local contentSize = tmp.sprite:getContentSize()

		if height then
			tmp.sprite:setScale(height / contentSize.height)

			tmp.width = contentSize.width * height / contentSize.height
		else
			tmp.width = contentSize.width
		end

		totalWidth = totalWidth + tmp.width

		numNode:addChild(tmp.sprite, 1)
	end

	local offset = totalWidth * 0.5

	for i = 1, #numStr do
		local tmp = num_sprite[i]

		tmp.sprite:setAnchorPoint(CCPointMake(0, 0.5))
		tmp.sprite:setPosition(-offset, 0)

		offset = offset - tmp.width
	end

	return numNode, totalWidth
end

function getWorldPos(x, y, size, pos)
	return ccp(x * size.width + pos.x, y * size.height + pos.y)
end

function createBox(isPrize)
	return
end

function createEnsureBox(parent, defs)
	local hintLayer = CCLayer:create()

	parent:addChild(hintLayer, 100)

	local function onTouch(eventType, x, y)
		return true
	end

	hintLayer:registerScriptTouchHandler(onTouch, false, -128, true)
	hintLayer:setTouchEnabled(true)

	local mask = CCLayerColor:create(ccc4(0, 0, 0, 100))

	hintLayer:addChild(mask, -1)

	local frame = d_ms.d_u.createByStyle({
		pic = "v2/rechargeUI/tip.png",
		x = 0.5,
		y = 0.5
	})

	hintLayer:addChild(frame)

	local w, h = d_ms.d_u.getRealScale(frame)

	local function closeCallBack(tag)
		parent:removeChild(hintLayer, true)

		if tag == 1 then
			if defs.firstBtn.callback then
				defs.firstBtn.callback()
			end
		elseif tag == 2 and defs.secondBtn.callback then
			defs.secondBtn.callback()
		end
	end

	local N = #defs.Hints
	local up_y = 0.25
	local offset_y = 0.5 / (N + 1)
	local default_color = {
		255,
		216,
		167
	}

	for i = 1, N do
		local hint = defs.Hints[i]
		local cur_y = 0.5 + (up_y - i * offset_y) * h
		local strLabel = d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			x = 0.5,
			string = hint.string,
			y = cur_y,
			fontsize = hint.fontsize,
			color = hint.color or default_color
		})

		hintLayer:addChild(strLabel, 1)
	end

	local item_menu_list = {
		{
			tag = 1,
			x = 0.5 - 0.23 * w,
			y = 0.5 - 0.38 * h,
			npic = defs.firstBtn.pic1,
			spic = defs.firstBtn.pic2,
			call_back = closeCallBack
		},
		{
			tag = 2,
			x = 0.5 + 0.23 * w,
			y = 0.5 - 0.38 * h,
			npic = defs.secondBtn.pic1,
			spic = defs.secondBtn.pic2,
			call_back = closeCallBack
		},
		x = 0,
		y = 0
	}

	hintLayer:addChild(d_ms.d_u.createMenu(item_menu_list), 5)

	return hintLayer
end

function createBatchUse(parent, defs, ensureCallback)
	local layer = CCLayer:create()

	parent:addChild(layer, 50)

	local function onTouch(eventType, x, y)
		return true
	end

	layer:registerScriptTouchHandler(onTouch, false, -128, true)
	layer:setTouchEnabled(true)

	local minLimit = defs.min or 1
	local maxLimit = defs.max or 15
	local mask = CCLayerColor:create(ccc4(0, 0, 0, 100))

	layer:addChild(mask)

	local frame = CCSprite:create("v2/batchBuyUI/frame.png")

	d_ms.d_u.setStyles(frame, {
		x = 0.5,
		y = 0.5
	})
	layer:addChild(frame)

	local frameSize = frame:getContentSize()
	local framePos = frame:getPositionLua()

	local function setNodePosition(node, x, y)
		node:setPosition(getWorldPos(x, y, frameSize, framePos))
	end

	local headerPic = defs.headerPic or "v2/batchBuyUI/header2.png"
	local header = CCSprite:create(headerPic)

	setNodePosition(header, 0, 0.36)
	layer:addChild(header)

	if defs.buyTip then
		local buyTip = d_ms.d_u.createByStyle({
			font = "arial",
			fontsize = 30,
			type = "label",
			string = defs.buyTip
		})

		setNodePosition(buyTip, 0, 0.2)
		layer:addChild(buyTip)
	end

	local count = defs.defaultCount or maxLimit
	local countLabel = d_ms.d_u.createByStyle({
		y = 0.51,
		font = "arial",
		type = "label",
		x = 0.5,
		fontsize = 30,
		string = tostring(count)
	})

	countLabel:setColor(ccc3(0, 0, 0))
	layer:addChild(countLabel)

	local menu_array = CCArray:create()

	local function changeCount(tag)
		count = count + tag
		count = math.max(count, minLimit)
		count = math.min(count, maxLimit)

		countLabel:setString(tostring(count))
	end

	local minus1 = CCMenuItemImage:create("v2/batchBuyUI/minus1.png", "v2/batchBuyUI/minus2.png")

	minus1:registerScriptTapHandler(changeCount)
	minus1:setTag(-1)
	menu_array:addObject(minus1)
	setNodePosition(minus1, -0.22, 0.02)

	local minus10 = CCMenuItemImage:create("v2/batchBuyUI/minusT1.png", "v2/batchBuyUI/minusT2.png")

	minus10:registerScriptTapHandler(changeCount)
	minus10:setTag(-10)
	setNodePosition(minus10, -0.4, 0.02)
	menu_array:addObject(minus10)

	local add1 = CCMenuItemImage:create("v2/batchBuyUI/add1.png", "v2/batchBuyUI/add2.png")

	add1:registerScriptTapHandler(changeCount)
	add1:setTag(1)
	menu_array:addObject(add1)
	setNodePosition(add1, 0.22, 0.02)

	local add10 = CCMenuItemImage:create("v2/batchBuyUI/addT1.png", "v2/batchBuyUI/addT2.png")

	add10:registerScriptTapHandler(changeCount)
	add10:setTag(10)
	menu_array:addObject(add10)
	setNodePosition(add10, 0.4, 0.02)

	local function pressButton(tag)
		layer:getParent():removeChild(layer, true)

		if tag == 1 then
			ensureCallback(count)
		end
	end

	local ensureMenuItem = CCMenuItemImage:create("v2/batchBuyUI/ensure1.png", "v2/batchBuyUI/ensure2.png")

	ensureMenuItem:registerScriptTapHandler(pressButton)
	ensureMenuItem:setTag(1)
	menu_array:addObject(ensureMenuItem)
	setNodePosition(ensureMenuItem, 0.23, -0.32)

	local closeMenuItem = CCMenuItemImage:create("v2/batchBuyUI/cancel1.png", "v2/batchBuyUI/cancel2.png")

	closeMenuItem:registerScriptTapHandler(pressButton)
	closeMenuItem:setTag(-1)
	menu_array:addObject(closeMenuItem)
	setNodePosition(closeMenuItem, -0.23, -0.32)

	local menu = CCMenu:createWithArray(menu_array)

	menu:setPosition(0, 0)
	layer:addChild(menu)
end

function createBatchSale(parent_layer, type_id, max)
	local layer = CCLayer:create()

	d_ms.d_u.createSwallowTouchLayer(layer)

	local mask = CCLayerColor:create(ccc4(0, 0, 0, 100))

	layer:addChild(mask, -1)

	local bkg = d_ms.d_u.createByStyle({
		pic = "v2/batchBuyUI/frame.png",
		x = 0.5,
		y = 0.5
	})

	layer:addChild(bkg)

	local w, h = d_ms.d_u.getRealScale(bkg)
	local header = d_ms.d_u.createByStyle({
		pic = "v2/batchBuyUI/title_sale.png",
		x = 0.5,
		y = 0.5 + 0.37 * h
	})

	layer:addChild(header, 1)

	local count = 0
	local pp = d_ms.d_data.g_ep_price[type_id]

	local function onNumChanged(num, overflowType)
		count = num

		layer:removeChildByTag(11, true)

		local descStr = gethz("saleHint") .. pp * count .. gethz("money")
		local priceLabel = d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			x = 0.5,
			fontsize = 26,
			string = descStr,
			y = 0.5 - 0.14 * h,
			color = {
				0,
				0,
				0
			}
		})

		layer:addChild(priceLabel, 1, 11)
	end

	local calc = d_ms.d_guildPartyUI.getCalc(onNumChanged, max)

	d_ms.d_u.setStyles(calc, {
		x = 0.5,
		y = 0.5 + 0.02 * h
	})
	layer:addChild(calc, 1)
	onNumChanged(1, 0)

	local function press(tag)
		d_ms.d_u.remove(layer)

		if tag == 2 then
			local tmp_req = {
				data = table.tostring({
					item_list = {
						[type_id] = count
					}
				})
			}

			d_ms.d_u.main_server_send_msg(d_ms.d_msg_def.gscl_msg_id.msg_sell_items, tmp_req)
		end
	end

	local menu_btn_list = {
		{
			npic = "v2/batchBuyUI/cancel1.png",
			spic = "v2/batchBuyUI/cancel2.png",
			tag = 1,
			x = 0.5 - 0.2 * w,
			y = 0.5 - 0.35 * h,
			call_back = press
		},
		{
			npic = "v2/batchBuyUI/ensure1.png",
			spic = "v2/batchBuyUI/ensure2.png",
			tag = 2,
			x = 0.5 + 0.2 * w,
			y = 0.5 - 0.35 * h,
			call_back = press
		},
		x = 0,
		y = 0
	}

	layer:addChild(d_ms.d_u.createMenu(menu_btn_list), 5)
	parent_layer:addChild(layer, 50)
end

local function createChooseBkg(parent, showArea)
	local bkg = CCSprite:create("v2/common/frame3.png")
	local bkgSize = bkg:getContentSize()
	local bkgScaleX = showArea.width / bkgSize.width
	local bkgScaleY = showArea.height / bkgSize.height

	cclog("bkgScaleX:%f, bkgScaleY:%f", bkgScaleX, bkgScaleY)
	parent:addChild(bkg, 100)
	bkg:setAnchorPoint(ccp(0, 0))
	bkg:setPosition(showArea.x, showArea.y)
	bkg:setScaleX(bkgScaleX)
	bkg:setScaleY(bkgScaleY)
end

local m_t = d_ms.d_common_def.item_main_type

local function createSkillLabel(parent, level, type_id, position)
	d_ms.d_skillUpgradeUI.initSkillCsv()

	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local effect_type = d_ms.d_skillUpgradeUI.g_self.csv_map_skill[type_id]
	local pro = 0
	local powerSprite = nil
	local itemInfo_level = level

	if effect_type[8] == "1" then
		powerSprite = CCSprite:create("v2/introUI/damage.png")
		local num = tonumber(effect_type[9]) + tonumber(effect_type[14]) * (itemInfo_level - 1)
		num = string.format("%.1f", num)
		pro = num .. "%"
	elseif effect_type[8] == "2" then
		powerSprite = CCSprite:create("v2/introUI/defence.png")
		local num = tonumber(effect_type[10]) + tonumber(effect_type[14]) * (itemInfo_level - 1)
		num = string.format("%.1f", num)
		pro = num .. "%"
	elseif effect_type[8] == "3" then
		powerSprite = CCSprite:create("v2/introUI/mana.png")
		local num = tonumber(effect_type[11]) + tonumber(effect_type[14]) * (itemInfo_level - 1)
		num = string.format("%.1f", num)
		pro = num .. "%"
	else
		powerSprite = CCSprite:create("v2/introUI/skill_strong.png")
		pro = math.floor(tonumber(effect_type[12]) + tonumber(effect_type[14]) * (itemInfo_level - 1))
	end

	local powerLabel = d_ms.d_u.createByStyle({
		font = "arial",
		fontsize = 26,
		type = "label",
		string = pro
	})

	powerSprite:setPosition(position)
	powerLabel:setPosition(position.x + 0.02 * scrSize.width, position.y)
	powerLabel:setAnchorPoint(ccp(0, 0.5))
	parent:addChild(powerSprite, 5)
	parent:addChild(powerLabel, 5)

	return powerLabel
end

local cellBkgTag = 1111
local checkSpriteTag = 1112

local function createItemCell(showInfo, pos, tag, tapIconCallback)
	local node = CCNode:create()
	local spriteBkg = CCSprite:create("v2/charPositionUI/item_bkg.png")

	spriteBkg:setAnchorPoint(ccp(0.5, 1))
	node:addChild(spriteBkg, -1)
	spriteBkg:setTag(cellBkgTag)
	spriteBkg:setPosition(pos)

	local bkgSize = spriteBkg:getContentSize()
	local object_type = showInfo.attach_type
	local type_id = showInfo.type or showInfo.type_id
	local info = getCertainInfo(object_type, type_id)
	local sprite_checkFrame = CCSprite:create("v2/multi-selectUI/check_frame.png")

	sprite_checkFrame:setPosition(bkgSize.width * 0.8, bkgSize.height * 0.5)
	spriteBkg:addChild(sprite_checkFrame, 1)

	if showInfo.isChecked then
		local checkSprite = CCSprite:create("v2/multi-selectUI/check.png")

		checkSprite:setTag(checkSpriteTag)
		checkSprite:setPosition(sprite_checkFrame:getPositionLua())
		spriteBkg:addChild(checkSprite, 20)
	end

	local nameLabel = d_ms.d_u.createByStyle({
		font = "arial",
		fontsize = 30,
		type = "label",
		string = info.name
	})

	spriteBkg:addChild(nameLabel, 1)
	nameLabel:setAnchorPoint(ccp(0, 0.5))
	nameLabel:setColor(ccc3(254, 235, 192))
	nameLabel:setPosition(bkgSize.width * 0.22, bkgSize.height * 0.7)
	nameLabel:setAnchorPoint(CCPointMake(0, 0.5))

	local quality = info.quality

	if quality and quality > 0 then
		local qualityRatio = info.quality / 5
		local starsLevelSprite = CCSprite:create("v2/introUI/stars.png")

		spriteBkg:addChild(starsLevelSprite, 1)
		starsLevelSprite:setPosition(bkgSize.width * 0.5, bkgSize.height * 0.7)
		starsLevelSprite:setAnchorPoint(ccp(0, 0.5))

		local starsContentSize = starsLevelSprite:getContentSize()

		starsLevelSprite:setTextureRect(CCRectMake(0, 0, starsContentSize.width * qualityRatio, starsContentSize.height))
	end

	local level = showInfo.level

	if level then
		local levelSprite = CCSprite:create("v2/packageUI/level.png")

		levelSprite:setPosition(bkgSize.width * 0.22, bkgSize.height * 0.3)
		levelSprite:setAnchorPoint(ccp(0, 0.5))
		spriteBkg:addChild(levelSprite)

		local levelLabel = d_ms.d_u.createByStyle({
			font = "arial",
			fontsize = 30,
			type = "label",
			string = tostring(level)
		})

		spriteBkg:addChild(levelLabel)
		levelLabel:setPosition(bkgSize.width * 0.29, bkgSize.height * 0.3)
		levelLabel:setAnchorPoint(ccp(0, 0.5))
		levelLabel:setColor(ccc3(253, 190, 37))
	end

	local power = showInfo.effect_value
	local main_type = info.mainType

	if main_type and main_type <= m_t.talismans then
		local powerSpritePos = ccp(bkgSize.width * 0.5, bkgSize.height * 0.3)
		local powerLabelPos = ccp(bkgSize.width * 0.58, bkgSize.height * 0.3)
		local powerSprite = nil
		local isShowPowerLabel = false

		if main_type == m_t.weapon then
			powerSprite = CCSprite:create("v2/packageUI/CHAR_gong.png")
			isShowPowerLabel = true
		elseif packageTag == m_t.armor then
			powerSprite = CCSprite:create("v2/packageUI/CHAR_fang.png")
			isShowPowerLabel = true
		elseif packageTag == m_t.fabao then
			powerSprite = CCSprite:create("v2/packageUI/CHAR_ming.png")
			isShowPowerLabel = true
		elseif packageTag == packageTagDef.skill then
			createSkillLabel(spriteBkg, showInfo.type_id, powerSpritePos, showInfo.level)

			local typeSprite = nil

			if packageItemsInfo[i].csvInfo.skillType == 1 then
				if packageItemsInfo[i].csvInfo.attackType == 1 then
					typeSprite = CCSprite:create("v2/newIntroUI/dan.png")
				else
					typeSprite = CCSprite:create("v2/newIntroUI/qun.png")
				end
			else
				typeSprite = CCSprite:create("v2/newIntroUI/bei.png")
			end

			typeSprite:setPosition(bkgSize.width * 0.58, bkgSize.height * 0.25)
			spriteBkg:addChild(typeSprite)
		end

		if power and isShowPowerLabel then
			powerLabel = d_ms.d_u.createByStyle({
				font = "arial",
				fontsize = 30,
				type = "label",
				string = tostring(power)
			})

			spriteBkg:addChild(powerLabel)
			powerLabel:setAnchorPoint(ccp(0, 0.5))
			powerLabel:setPosition(powerLabelPos)
			powerLabel:setColor(ccc3(253, 190, 37))
		end

		if powerSprite then
			spriteBkg:addChild(powerSprite)
			powerSprite:setAnchorPoint(ccp(0, 0.5))
			powerSprite:setPosition(powerSpritePos)
		end
	end

	local iconSprite1 = getCertainSmallSprite(object_type, type_id)
	local iconSprite2 = getCertainSmallSprite(object_type, type_id)
	local menuItem = CCMenuItemSprite:create(iconSprite1, iconSprite2)

	if tapIconCallback then
		menuItem:registerScriptTapHandler(tapIconCallback)
	end

	menuItem:setTag(tag)
	menuItem:setPosition(bkgSize.width * 0.1, bkgSize.height * 0.5)
	menuItem:setTag(tag)

	local menu = CCMenu:createWithItem(menuItem)

	menu:setPosition(0, 0)
	spriteBkg:addChild(menu)

	return node, bkgSize, sprite_checkFrame
end

local function createCharCell(showInfo, pos)
	local node = CCNode:create()

	return node, size
end

showType = {
	item = 1,
	char = 2
}

function createCommonChooseLayer(parent, showList, showArea, checkFunc)
	local viewSize = {
		width = showArea.width,
		height = showArea.height
	}
	local viewPosition = {
		x = showArea.x,
		y = showArea.y
	}
	local checkFrameTable = {}

	local function touchCellFunc(cell)
		local tag = cell:getTag()
		local bkgSprite = cell:getChildByTag(cellBkgTag)
		local checkFrame = checkFrameTable[tag]

		if bkgSprite and checkFrame then
			local checkSprite = bkgSprite:getChildByTag(checkSpriteTag)

			if checkSprite then
				bkgSprite:removeChild(checkSprite, true)

				if checkFunc then
					checkFunc(false, showList[tag])
				end
			elseif checkFunc and checkFunc(true, showList[tag]) then
				local checkSprite = CCSprite:create("v2/multi-selectUI/check.png")

				checkSprite:setTag(checkSpriteTag)
				checkSprite:setPosition(checkFrame:getPositionLua())
				bkgSprite:addChild(checkSprite, 20)
			end
		end
	end

	local itemListView = d_ms.d_inertiaLayer.inertiaLayer.new(viewSize, viewPosition, showArea, touchCellFunc)

	parent:addChild(itemListView.scrollView, 102)
	itemListView:createInertiaMove()

	local space = 0.03 * viewSize.height
	local startPos = ccp(0.5 * viewSize.width, viewSize.height - space)
	local firstShow = 10
	local count = math.min(firstShow, #showList)

	local function showCertainIntroWrap(tag)
		showCertainIntro(parent, showList[tag], true)
	end

	local cellTable = {}

	for i = 1, count do
		local node, size, checkFrame = createItemCell(showList[i], startPos, i, showCertainIntroWrap)

		node:setTag(i)

		cellTable[i] = node
		checkFrameTable[i] = checkFrame
		startPos.y = startPos.y - size.height - space

		itemListView:addCell(node, {
			width = size.width,
			height = size.height + space
		})
	end

	local showIndex = firstShow + 1

	function d_ms.d_inertiaLayer.scrollViewHelper.scrollViewDidScroll()
		if showIndex > #showList then
			return
		end

		if showList[showIndex] then
			local node, size, checkFrame = createItemCell(showList[showIndex], startPos, showIndex, showCertainIntroWrap)
			startPos.y = startPos.y - size.height - space
			checkFrameTable[showIndex] = checkFrame

			node:setTag(showIndex)

			cellTable[showIndex] = node

			itemListView:addCell(node, {
				width = size.width,
				height = size.height + space
			})
		end

		showIndex = showIndex + 1
	end
end

function registerExitFunc(layer, callback)
	local function sceneEventHandler(eventType)
		if eventType.name == "exit" and callback then
			callback()
		end
	end

	layer:registerScriptHandler(sceneEventHandler)
end

local allTagsDef = require("allTagsDef")

function getTagFromDef(key)
	return allTagsDef[key]
end

g_new_config = {}
local c_c_t = d_ms.d_common_def.client_config_type

function callback_update_config(data)
	cclog("callback_update_config")

	if data and #data then
		g_new_config = g_new_config or {}

		for i, v in pairs(data) do
			g_new_config[i] = v
		end

		if data.config_end == true then
			set_g_new_config()
		end
	end
end

function set_g_new_config()
	local data = g_new_config or {}

	getGoldConfig()

	d_ms.d_worldBossUI.g_topList = data[c_c_t.party_fight].party_top_list

	d_ms.d_summonUI.initSummonLimit(data[c_c_t.vip_config])
	d_ms.d_shopUI.initBagLimit(data[c_c_t.vip_config])
	d_ms.d_xianmengUI.getGuildConfig(data[c_c_t.union_config])
	d_ms.d_shopUI.loadGoods(data[c_c_t.shop_items])

	d_ms.d_stoneUI.g_self.isOpen = data[c_c_t.stone_config].open_flag
	d_ms.d_stoneUI.g_self.Lvlimit = data[c_c_t.stone_config].min_role_level

	d_ms.d_godBlessUI.getBlessConfig(data[c_c_t.land_father])
	d_ms.d_cheerSquadUI.initCost(data[c_c_t.cheer_data])
	d_ms.d_soulExchangeUI.initData(data[c_c_t.adaptive_spirtit])
	d_ms.d_crossRankUI.initData(data[c_c_t.single_fight])
	d_ms.d_roleRebornUI.initData(data[c_c_t.reborn_config])

	g_version_submit = data[c_c_t.update_version]
	local qiankunnizhuanConfig = data[c_c_t.skill_transform] or {}
	d_ms.d_qiankunnizhuan.requireGold = qiankunnizhuanConfig.cost_gold or 200

	d_ms.d_activityUI.updateAllActivityStatus(data[c_c_t.activity_time])
	d_ms.d_mondayUI.updateFlag(data[c_c_t.monday_activity])
	d_ms.d_equipAdvanceUI.getConfig(data[c_c_t.equip_advance])
	d_ms.d_cortegeRecycleUI.getEquipConfig(data[c_c_t.equip_advance])
	forBanshu(data[c_c_t.common_config])
	d_ms.d_actNoticeUI.getConfig(data[c_c_t.common_config])

	d_ms.d_mainUI.g_week_time = data[c_c_t.week_year]

	d_ms.d_kickUI.onGetCortList(data[c_c_t.longer_hill])
	d_ms.d_wakeUI.onGetConfig(data[c_c_t.awaken_star_config])
	d_ms.d_returnUI.onGetConfig(data[c_c_t.hero_back_config])
	forNewYear(data[c_c_t.spring_festival])

	if data[c_c_t.invite_config] and data[c_c_t.invite_config].inner_charge == 0 then
		d_ms.d_c.g_can_recharge = false
	end

	cclog("--------------------AD=begin---------------------------")

	if data[c_c_t.option_config] and data[c_c_t.option_config].immob_ads == true then
		cclog("--------------------AD=true---------------------------")

		if main_server.thirdPartyIOSDomobAdDisplay then
			main_server.thirdPartyIOSDomobAdDisplay(1)
		end
	elseif data[c_c_t.option_config] and data[c_c_t.option_config].immob_ads == false then
		cclog("--------------------AD=false---------------------------")

		if main_server.thirdPartyIOSDomobAdDisplay then
			main_server.thirdPartyIOSDomobAdDisplay(0)
		end
	end

	if c_c_t.country_config and data[c_c_t.country_config] then
		countrylist = table.tostring(data[c_c_t.country_config])

		if countrylist then
			cclog("--------------------country list be found---------------------------")
			cclog(countrylist)

			if d_ms.d_u.isIOS() then
				cclog("--------------------seting allow country list for purchase ---------")
				main_server.setIOSAllowPurchaseCountryList(countrylist)
				cclog("--------------------set allow country list done!--------------------")
			else
				cclog("-----------------not in IOS ,the country list will not be set ------")
			end
		end
	else
		cclog("----------not country list be found,the list will be set none--------")
	end

	if not g_rechargeItemsPriceTable or #g_rechargeItemsPriceTable <= 0 then
		getRechargeItemsPriceCSVConfig()

		local true_prices = g_new_config[d_ms.d_common_def.client_config_type.order_config]

		for k, v in pairs(g_rechargeItemsPriceTable) do
			if true_prices[k] then
				v.price = true_prices[k].item_price
				v.gold_count = true_prices[k].gold_count
				v.plus_count = true_prices[k].plus_count
			else
				cclog("ERROR, true_prices can not find k=" .. k)
			end
		end
	end
end

function isSaoFree()
	if g_sweep_spring_config and g_sweep_spring_config.begin_time and g_sweep_spring_config.end_time then
		local now = d_ms.d_time.getTime()

		if g_sweep_spring_config.begin_time < now and now < g_sweep_spring_config.end_time then
			return true
		end
	end

	return false
end

function isNoTower()
	if g_prey_spring_config and g_prey_spring_config.begin_time and g_prey_spring_config.end_time then
		local now = d_ms.d_time.getTime()

		if g_prey_spring_config.begin_time < now and now < g_prey_spring_config.end_time then
			return true
		end
	end

	return false
end

function forNewYear(data_table)
	cclog("hehe")

	if not data_table then
		return
	end

	local a_t = d_ms.d_common_def.activity_type

	d_ms.d_firework.initData(data_table[a_t.spring_festival])

	g_prey_spring_config = data_table[a_t.prey_activity]
	g_sweep_spring_config = data_table[a_t.sweep_activity]
end

function forBanshu(data_table)
	if not data_table or not data_table.banshu_config then
		return
	end

	d_ms.d_escortUI.g_banshu = data_table.banshu_config.union_west == false
	d_ms.d_trainingUI.g_banshu = data_table.banshu_config.train_intensive == false
	d_ms.d_crossDoomUI.g_banshu = data_table.banshu_config.rape_flush == false
end

function getGoldConfig()
	d_ms.d_worldBossUI.g_payFightGold = g_new_config[c_c_t.party_fight].pay_consume_gold
	d_ms.d_tianShuUI.goldConfig = g_new_config[c_c_t.task_guide]
end

function checkIsSameDay(time1, time2)
	if not time1 or not time2 then
		return false
	end

	local date1 = os.date("*t", time1)
	local date2 = os.date("*t", time2)

	if date1.year == date2.year and date1.month == date2.month and date1.day == date2.day then
		return true
	end

	return false
end

function createCommonFilterMenu(parent, tag, pos, ensureCallBack, currentFilter)
	local function createFilterLayer()
		d_ms.d_filterLayer.show(CCDirector:sharedDirector():getRunningScene(), 100, tag, ensureCallBack, currentFilter)
	end

	local filter = CCMenuItemImage:create("v2/buttons/filter1.png", "v2/buttons/filter2.png")

	filter:registerScriptTapHandler(createFilterLayer)
	filter:setPosition(pos)

	local menu = CCMenu:createWithItem(filter)

	menu:setPosition(CCPointMake(0, 0))
	parent:addChild(menu)
end

local inputLayerTag = 400001

function createInputBox(parent, defs)
	local inputLayer = parent:getChildByTag(inputLayerTag)

	if inputLayer then
		parent:removeChild(inputLayer, true)
	end

	inputLayer = CCLayer:create()

	parent:addChild(inputLayer, 50)
	inputLayer:setTag(inputLayerTag)

	local maskLayer = CCLayerColor:create(ccc4(0, 0, 0, 100))

	inputLayer:addChild(maskLayer, -1)

	local function onTouch(eventType, x, y)
		return true
	end

	maskLayer:registerScriptTouchHandler(onTouch, false, -128, true)
	maskLayer:setTouchEnabled(true)

	local bkg_big = CCSprite:create("v2/messageUI/frame1.png")

	d_ms.d_u.setStyles(bkg_big, {
		scaleY = 0.6,
		x = 0.5,
		y = 0.5
	})
	inputLayer:addChild(bkg_big)

	local scaleY = bkg_big:getScaleY()

	if defs.cost_silver then
		local str_tink = gethz("no_speaker_cost_tink")

		if defs.cost_silver > 0 then
			str_tink = str_tink .. defs.cost_silver
		else
			str_tink = str_tink .. gethz("no_speaker_free")
		end

		inputLayer:addChild(d_ms.d_u.createByStyle({
			y = 0.75,
			type = "label",
			x = 0.5,
			fontsize = 26,
			string = str_tink,
			color = {
				245,
				220,
				180
			}
		}), 100)
	end

	local bkgSize = bkg_big:getContentSize()
	bkgSize = CCSizeMake(bkgSize.width, bkgSize.height * scaleY)
	local position = bkg_big:getPositionLua()
	local bkg_small = CCSprite:create("v2/messageUI/frame2.png")

	d_ms.d_u.setStyles(bkg_small, {
		x = 0.5,
		y = 0.5
	})
	bkg_small:setScaleY(scaleY)
	inputLayer:addChild(bkg_small)

	local bkg_size = bkg_small:getContentSize()
	local bkg_small_w, bkg_small_h = d_ms.d_u.getRealScale(bkg_small)
	local innerBkgSize = bkg_small:getContentSize()

	local function getRelativePos(x, y)
		return getWorldPos(x, y, bkgSize, position)
	end

	local inputBox = nil
	local tapHint = d_ms.d_hz.gethz("tapInputHint")
	local maxCount = defs.maxCount or 80

	if d_ms.d_u.isIOS() and d_ms.d_u.isLuaC() or d_ms.d_u.isWP8() then
		cclog("this is ios and luac")

		local p1 = CCScale9Sprite:create("v2/empty_mask.png", CCRectMake(0, 0, bkg_size.width * 0.95, 50))
		local inputSize = p1:getContentSize()
		inputBox = CCEditBox:create(inputSize, p1)

		d_ms.d_u.setStyles(inputBox, {
			opacity = 0,
			x = 0.5,
			y = 0.5
		})

		if inputBox.setPlaceHolder and main_server.getCppVersion and main_server.getCppVersion() >= 104 then
			inputBox:setPlaceHolder(tapHint)
		end

		if inputBox.setFontSize then
			inputBox:setFontSize(26)
		end

		if inputBox.getLabel then
			local txt_, holder_ = inputBox:getLabel()

			txt_:setFontSize(26)
			txt_:setDimensions(CCSizeMake(inputSize.width, inputSize.height * 0))
			txt_:setHorizontalAlignment(0)
			holder_:setFontSize(26)
			holder_:setDimensions(CCSizeMake(inputSize.width, inputSize.height * 0))
			holder_:setHorizontalAlignment(0)
		end

		local fake_btn = {}

		local function openKeyBoard()
			if inputBox.touchDownAction then
				inputBox:touchDownAction(fake_btn[1], 1)
			end
		end

		local fake_menu = {
			{
				opacity = 0,
				npic = "v2/empty_mask.png",
				spic = "v2/empty_mask.png",
				y = 0.5,
				x = 0.5,
				scaleX = bkg_small_w * 0.95,
				scaleY = bkg_small_h * 0.96,
				call_back = openKeyBoard
			},
			x = 0,
			y = 0
		}

		inputLayer:addChild(d_ms.d_u.createMenu(fake_menu, fake_btn), 5)

		local function de_layer_()
			inputBox:setTouchPriority(-130)
		end

		d_ms.d_u.delay(inputLayer, 0.1, de_layer_)
	elseif d_ms.d_u.isIOS() then
		inputBox = CCEditBox:createWithPosition(CCSizeMake(innerBkgSize.width * 0.9, innerBkgSize.height * 0.7), d_ms.d_u.makePoint(0.28, 0.7))

		inputBox:setMaxLength(maxCount * 3)

		if main_server.getCppVersion() >= 104 then
			inputBox:setPlaceHolder(tapHint)
		end
	else
		inputBox = CCTextFieldTTF:textFieldWithPlaceHolder(tapHint, CCSizeMake(innerBkgSize.width * 0.9, innerBkgSize.height * 0.7), kCCTextAlignmentLeft, "Arial", 26)

		d_ms.d_u.setStyles(inputBox, {
			x = 0.5,
			y = 0.5
		})

		local lastInput = " "

		local function tick()
			local currentStr = inputBox:getString()

			if currentStr ~= lastInput then
				local tapStr = inputBox:getString()
				local trimStr = ""
				local count = 0

				for uchar in string.gfind(tapStr, "[%z-\\xc2-\\xf4][\\x80-\\xbf]*") do
					if maxCount <= count then
						break
					end

					trimStr = trimStr .. uchar
					count = count + 1
				end

				inputBox:setString(trimStr)
			end

			lastInput = currentStr

			d_ms.d_u.delay(inputLayer, 0, tick)
		end

		d_ms.d_u.delay(inputLayer, 0, tick)

		local frame = bkg_small:boundingBox()

		local function onTouch(eventType, x, y)
			if frame:containsPoint(ccp(x, y)) then
				inputBox:attachWithIME()
			end
		end

		inputLayer:registerScriptTouchHandler(onTouch, false, -128, true)
		inputLayer:setTouchEnabled(true)
	end

	if defs.defaultStr then
		inputBox:setString(defs.defaultStr)
	end

	inputLayer:addChild(inputBox)

	local function ensureInput()
		if defs.ensureFunc then
			defs.ensureFunc(inputBox:getString())

			if defs.ensureAndDel then
				parent:removeChildByTag(inputLayerTag, true)
			end
		else
			parent:removeChildByTag(inputLayerTag, true)
		end
	end

	local function closeLayer()
		parent:removeChildByTag(inputLayerTag, true)
	end

	local menuArray = CCArray:create()
	local ensureMenuItem = CCMenuItemImage:create("v2/batchBuyUI/ensure1.png", "v2/batchBuyUI/ensure2.png")

	ensureMenuItem:registerScriptTapHandler(ensureInput)
	ensureMenuItem:setPosition(getRelativePos(0.3, -0.42))
	menuArray:addObject(ensureMenuItem)

	local cancelMenuItem = CCMenuItemImage:create("v2/multi-selectUI/back1.png", "v2/multi-selectUI/back2.png")

	cancelMenuItem:registerScriptTapHandler(closeLayer)
	cancelMenuItem:setPosition(getRelativePos(-0.3, -0.42))
	menuArray:addObject(cancelMenuItem)

	local menu = CCMenu:createWithArray(menuArray)

	menu:setPosition(0, 0)
	inputLayer:addChild(menu)

	return inputLayer
end

function createLevelSprite(level, parent, center)
	local levelStr = tostring(level)
	local level_num = {}
	local totalWidth = 0

	for i = 1, string.len(levelStr) do
		local _levelNum = string.sub(levelStr, i, i)
		level_num[i] = CCSprite:create("v2/vip/" .. _levelNum .. ".png")
		local contentSize = level_num[i]:getContentSize()

		parent:addChild(level_num[i], 1)

		totalWidth = totalWidth + contentSize.width
	end

	local offset = totalWidth * 0.5

	for i = 1, #level_num do
		local contentSize = level_num[i]:getContentSize()

		level_num[i]:setAnchorPoint(CCPointMake(0, 0.5))
		level_num[i]:setPosition(center.x - offset, center.y)

		offset = offset - contentSize.width
	end
end

function getFSccbiFile(fs_level)
	local index = fs_level or 0

	cclog("call getFSccbiFile, lvl=" .. index)

	local file_name_f, file_name_b = nil

	if index >= 9 then
		file_name_f = "feisheng9f.ccbi"
		file_name_b = "feisheng9b.ccbi"
	elseif index >= 6 then
		file_name_f = "feisheng6f.ccbi"
		file_name_b = "feisheng6b.ccbi"
	elseif index >= 3 then
		file_name_f = "feisheng3f.ccbi"
		file_name_b = "feisheng3b.ccbi"
	elseif index >= 1 then
		file_name_f = "feisheng1f.ccbi"
	end

	return file_name_f, file_name_b
end

function addFSccbi(obj, fs_level, pos)
	local index = fs_level or self.evolve
	local file_name_f, file_name_b = getFSccbiFile(index)
	local size = obj:getContentSize()
	local pos = ccp(size.width * 0.5, size.height * 0.5)

	if file_name_f then
		local ccbi_node_f = d_ms.d_u.createLoopAnimation(file_name_f)

		obj:addChild(ccbi_node_f, 1)
		ccbi_node_f:setPosition(pos)
		ccbi_node_f:setScale(0.5)
	end

	if file_name_b then
		local ccbi_node_b = d_ms.d_u.createLoopAnimation(file_name_b)

		obj:addChild(ccbi_node_b, -1)
		ccbi_node_b:setPosition(pos)
		ccbi_node_b:setScale(0.5)
	end
end

function addAdvanceCcbi(sprite, level)
	if not sprite then
		return
	end

	level = level or 0
	local name, anch = getCcbiByAdvanceLevel(level)

	if name then
		local size = sprite:getContentSize()
		local scrSize = CCDirector:sharedDirector():getVisibleSize()
		local pos = ccp(size.width * 0.5 - scrSize.width * 0.5, size.height * 0.5 - scrSize.height * 0.5)
		local anim_node = d_ms.d_u.createLoopAnimation(name)

		sprite:addChild(anim_node, 1)
		anim_node:setPosition(pos)
		anim_node:setScale(size.width / 120)
		anim_node:setAnchorPoint(anch)
	end
end

g_battle_diag_table = nil

function initBattleDiagTable()
	cclog("call initBattleDiagTable")

	local battle_csv_table = d_ms.d_csv.open2("csv_config/battle_diag.csv")
	g_battle_diag_table = {}

	for i, v in pairs(battle_csv_table) do
		if v.map_id and v.tollgate_id and v.step and v.content and #v.map_id > 0 and #v.tollgate_id > 0 and #v.step > 0 then
			local m_id = tonumber(v.map_id)
			local t_id = tonumber(v.tollgate_id)
			local s_id = tonumber(v.step) or 999

			if m_id and t_id and s_id then
				local tmp_table = {
					m_id = m_id,
					t_id = t_id,
					s_id = s_id,
					character = d_ms.d_str.trim(v.character),
					npc_id = tonumber(v.npc_id),
					name = d_ms.d_str.trim(v.name),
					content = v.content
				}

				if not g_battle_diag_table[m_id] then
					g_battle_diag_table[m_id] = {}
				end

				if not g_battle_diag_table[m_id][t_id] then
					g_battle_diag_table[m_id][t_id] = {}
				end

				if not g_battle_diag_table[m_id][t_id][s_id] then
					g_battle_diag_table[m_id][t_id][s_id] = {}
				end

				table.insert(g_battle_diag_table[m_id][t_id][s_id], tmp_table)
			end
		end
	end
end

function getBattleDiag(m_id, t_id, s_id)
	cclog("call getBattleDiag")

	if not g_battle_diag_table then
		initBattleDiagTable()
	end

	if g_battle_diag_table[m_id] and g_battle_diag_table[m_id][t_id] and g_battle_diag_table[m_id][t_id][s_id] then
		return g_battle_diag_table[m_id][t_id][s_id]
	end
end

function getCcbiByAdvanceLevel(level)
	local name = nil
	local anchor = ccp(0.5, 0.56)

	if level >= 3 and level <= 5 then
		name = "01.ccbi"
	elseif level >= 6 and level <= 8 then
		name = "02.ccbi"
		anchor = ccp(0.5, 0.45)
	elseif level == 9 then
		name = "03.ccbi"
	elseif level >= 10 then
		name = "04.ccbi"
	end

	return name, anchor
end

function getMoonCakeConfig()
	if not g_mooncake then
		g_mooncake = {}
		local tmp_csv_table = d_ms.d_csv.open2("csv_config/compose_monthcake.csv")

		for _, v in pairs(tmp_csv_table) do
			local gredit = {}
			g_mooncake[#g_mooncake + 1] = gredit
			gredit.source = {
				getItemFromStr(v.common_src_type),
				getItemFromStr(v.src_type)
			}
			gredit.dest = getItemFromStr(v.des_type)
		end
	end
end

function getSkillCsv_advance()
	if not g_skill_csv_advance_Table then
		csv_skill_advance = d_ms.d_csv.open2("csv_config/skill_advaced_conf.csv")
		g_skill_csv_advance_Table = {}

		for i, v in pairs(csv_skill_advance) do
			local params = {
				{
					"",
					"",
					""
				},
				{
					"",
					"",
					""
				},
				{
					"",
					"",
					""
				},
				{
					"",
					"",
					""
				},
				{
					"",
					"",
					""
				}
			}
			local canshu_table = d_ms.d_str.split(v.material_list, "/")
			local id = d_ms.d_str.split(canshu_table[1], "|")
			local id2 = d_ms.d_str.split(canshu_table[2], "|")
			g_skill_csv_advance_Table[v.type_id + 0] = {
				id[2] + 0,
				id2[2] + 0
			}
		end
	end
end

function getBodySpriteFilename_CrossServer(id, level, reborn)
	if not level or level == 0 then
		level = 1
	end

	local reborn = reborn or false

	if id >= 1000 and id <= 1010 then
		local config = getCharacterConfig(id)

		if config.main_type == 1 then
			if level <= 2 then
				return "chars/123/123_41.png"
			else
				return "chars/cross_server/1001.png"
			end
		end

		level, star = d_ms.d_crossServerUI.transformLevelStar(id, level)
		local file_name = "chars/cross_server/" .. id .. "_" .. level .. ".png"
		local sprite = CCSprite:create(file_name)

		if not sprite then
			file_name = "chars/cross_server/" .. id .. "_1.png"
			local sprite = CCSprite:create(file_name)

			if not sprite then
				file_name = "chars/cross_server/1002_1.png"
			end
		end

		return file_name
	else
		return getBodySpriteFilename(id, reborn)
	end
end

function getBodySprite_CrossServer(id, level, reborn)
	local name = getBodySpriteFilename_CrossServer(id, level, reborn)

	return CCSprite:create(name)
end

function getNameTxt_CrossServer(id)
	local name = ""

	if id < 10 then
		name = gethz("crossServer_info12") .. id
	else
		local charConfig = getCharacterConfig(id)

		if charConfig then
			name = charConfig.name
		end
	end

	return name
end

function getHeadSprite_CrossServer(id, level)
	if not level or level == 0 then
		level = 1
	end

	if id == 1001 then
		if level < 3 then
			return getHeadSprite(1001)
		else
			return getHeadSprite(3028)
		end
	end

	local source_id = getCharactSourceID_CrossServer(id)

	if source_id then
		level, star = d_ms.d_crossServerUI.transformLevelStar(id, level)
		source_id = source_id + level
		local pngName = nil
		pngName = "chars/cross_server/cross_server_all_head.png"
		source_id = (source_id - 1) % 50

		return getSingleSpriteFromPng(pngName, 10, 5, source_id)
	else
		return getHeadSprite(id, false)
	end
end

function getCharactSourceID_CrossServer(id)
	local source_id = 1
	local charConfig = getCharacterConfig(id)

	if charConfig then
		source_id = charConfig.resource
	else
		cclog("ERROR: char id error=%s", id)
	end

	return tonumber(source_id)
end

function getNameSprite_CrossServer(id)
	local source_id = getCharactSourceID_CrossServer(id)
	local pngName = nil
	pngName = "chars/cross_server/cross_server_all_name.png"
	source_id = 1 + (source_id - 1) % 50

	return getSingleSpriteFromPng(pngName, 10, 5, source_id)
end

function getCharacterConfig(char_id)
	if g_newCharacterAttrTable == nil then
		getCrossServerCSVConfig()
	end

	local csvInfo = g_newCharacterAttrTable[char_id]
	csvInfo = csvInfo or d_ms.d_lineupUI.g_characterAttrTable[char_id]

	return csvInfo
end

function getCampMaxLevelNum(typeID)
	if g_camp_level_Table == nil then
		getCrossServerCSVConfig()
	end

	return #g_camp_level_Table[typeID]
end

function getAwareMaxLevelNum(typeID)
	if g_aware_upgrade_config == nil then
		getCrossServerCSVConfig()
	end

	return #g_aware_upgrade_config[typeID]
end

function getCampLevelMaxConfig(typeID)
	if g_camp_level_Table == nil then
		getCrossServerCSVConfig()
	end

	return g_camp_level_Table[typeID][#g_camp_level_Table[typeID]]
end

function getCampPosUpdateConfig(level)
	if g_camp_pos_upgrade_Table == nil then
		getCrossServerCSVConfig()
	end

	return g_camp_pos_upgrade_Table[level]
end

function getCampLevelConfig(typeID, level)
	if g_camp_level_Table == nil then
		getCrossServerCSVConfig()
	end

	return g_camp_level_Table[typeID][level]
end

function getAwareUpdateConfig(typeID, level)
	if g_aware_upgrade_config == nil then
		getCrossServerCSVConfig()
	end

	return g_aware_upgrade_config[typeID][level]
end

function getCampProductConfig(level)
	if g_camp_product_Table == nil then
		getCrossServerCSVConfig()
	end

	return g_camp_product_Table[level]
end

function getCampAllProductConfig()
	if g_camp_product_Table == nil then
		getCrossServerCSVConfig()
	end

	return g_camp_product_Table
end

function getCampControlConfig(Level)
	if g_camp_control_Table == nil then
		getCrossServerCSVConfig()
	end

	return g_camp_control_Table[Level]
end

function getAllCampControlConfig()
	if g_camp_control_Table == nil then
		getCrossServerCSVConfig()
	end

	return g_camp_control_Table
end

function getCrossServerCSVConfig()
	local file_name1 = "csv_config/cross_server/camp_base.csv"
	local reload_flag = false

	if g_newCharacterAttrTable == nil or reload_flag then
		local character_attr_tab_csv = d_ms.d_csv.open2(file_name1)

		if not g_newCharacterAttrTable then
			g_newCharacterAttrTable = {}
		end

		local character_attr_tab = g_newCharacterAttrTable

		for i = 1, #character_attr_tab_csv do
			local v = character_attr_tab_csv[i]
			local id = tonumber(v.type_id)

			if not character_attr_tab[id] then
				character_attr_tab[id] = {}
			end

			local character_attr = character_attr_tab[id]
			character_attr.main_type = tonumber(v.main_type)
			character_attr.use_cortege_type = tonumber(v.use_cortege_type)
			character_attr.owner_type = tonumber(v.owner_type)
			character_attr.special_type = tonumber(v.special_type)
			character_attr.resource = tonumber(v.resource)
			character_attr.desc = v.desc
			character_attr.name = v.name
		end
	end

	local file_name2 = "csv_config/cross_server/camp_level.csv"

	if g_camp_level_Table == nil or reload_flag then
		local camp_upgrade_tab_csv = d_ms.d_csv.open2(file_name2)

		if not g_camp_level_Table then
			g_camp_level_Table = {}
		end

		local camp_upgrade_tab = g_camp_level_Table

		for i = 1, #camp_upgrade_tab_csv do
			local v = camp_upgrade_tab_csv[i]
			local id = tonumber(v.type_id)

			if not camp_upgrade_tab[id] then
				camp_upgrade_tab[id] = {}
			end

			local level = tonumber(v.level)

			if not camp_upgrade_tab[id][level] then
				camp_upgrade_tab[id][level] = {}
			end

			local camp_upgrade_attr = camp_upgrade_tab[id][level]
			camp_upgrade_attr.merit = tonumber(v.merit)
			camp_upgrade_attr.bodhi = tonumber(v.bodhi)
			camp_upgrade_attr.need_time = tonumber(v.need_time)
			camp_upgrade_attr.unit = tonumber(v.unit)
			camp_upgrade_attr.gongji = tonumber(v.gongji)
			camp_upgrade_attr.hp = tonumber(v.hp)
			camp_upgrade_attr.skill_desc = v.skill_desc
			camp_upgrade_attr.skill_speci_desc = v.skill_speci_desc
		end
	end

	local file_name3 = "csv_config/cross_server/aware_upgrade.csv"

	if g_aware_upgrade_config == nil or reload_flag then
		local aware_upgrade_tab_csv = d_ms.d_csv.open2(file_name3)

		if not g_aware_upgrade_config then
			g_aware_upgrade_config = {}
		end

		local aware_upgrade_tab = g_aware_upgrade_config

		for i = 1, #aware_upgrade_tab_csv do
			local v = aware_upgrade_tab_csv[i]
			local id = tonumber(v.aware_type)

			if not aware_upgrade_tab[id] then
				aware_upgrade_tab[id] = {}
			end

			local level = tonumber(v.level)

			if not aware_upgrade_tab[id][level] then
				aware_upgrade_tab[id][level] = {}
			end

			local aware_upgrade_attr = aware_upgrade_tab[id][level]
			aware_upgrade_attr.merit = tonumber(v.merit)
			aware_upgrade_attr.bodhi = tonumber(v.bodhi)
			aware_upgrade_attr.min_vip_level = tonumber(v.min_vip_level)
			aware_upgrade_attr.gold_count = tonumber(v.gold_count)
			aware_upgrade_attr.enhance_rate = tonumber(v.enhance_rate)
		end
	end

	local file_name4 = "csv_config/cross_server/camp_pos_upgrade.csv"

	if g_camp_pos_upgrade_Table == nil or reload_flag then
		local camp_pos_upgrade_tab_csv = d_ms.d_csv.open2(file_name4)

		if not g_camp_pos_upgrade_Table then
			g_camp_pos_upgrade_Table = {}
		end

		local camp_pos_upgrade_tab = g_camp_pos_upgrade_Table

		for i = 1, #camp_pos_upgrade_tab_csv do
			local v = camp_pos_upgrade_tab_csv[i]
			local id = tonumber(v.level)

			if not camp_pos_upgrade_tab[id] then
				camp_pos_upgrade_tab[id] = {}
			end

			local camp_pos_upgrade_attr = camp_pos_upgrade_tab[id]
			camp_pos_upgrade_attr.plus_rate = tonumber(v.plus_rate)
			camp_pos_upgrade_attr.merit = tonumber(v.merit)
			camp_pos_upgrade_attr.bodhi = tonumber(v.bodhi)
		end
	end

	local file_name5 = "csv_config/cross_server/camp_product.csv"

	if g_camp_product_Table == nil or reload_flag then
		local camp_product_tab_csv = d_ms.d_csv.open2(file_name5)

		if not g_camp_product_Table then
			g_camp_product_Table = {}
		end

		local camp_product_tab = g_camp_product_Table

		for i = 1, #camp_product_tab_csv do
			local v = camp_product_tab_csv[i]
			local id = tonumber(v.level)

			if not camp_product_tab[id] then
				camp_product_tab[id] = {}
			end

			local camp_pos_upgrade_attr = camp_product_tab[id]
			camp_pos_upgrade_attr.max_merit = tonumber(v.max_merit)
			camp_pos_upgrade_attr.merit_count = tonumber(v.merit_count)
			camp_pos_upgrade_attr.time_unit = tonumber(v.time_unit)
			camp_pos_upgrade_attr.max_bodhi = tonumber(v.max_bodhi)
			camp_pos_upgrade_attr.bodhi_count = tonumber(v.bodhi_count)
			camp_pos_upgrade_attr.time_unit = tonumber(v.time_unit)
		end
	end

	local file_name6 = "csv_config/cross_server/camp_control.csv"

	if g_camp_control_Table == nil or reload_flag then
		local camp_control_tab_csv = d_ms.d_csv.open2(file_name6)

		if not g_camp_control_Table then
			g_camp_control_Table = {}
		end

		local camp_control_tab = g_camp_control_Table

		for i = 1, #camp_control_tab_csv do
			local v = camp_control_tab_csv[i]
			local camp_level = tonumber(v.base_camp_level)

			if not camp_control_tab[camp_level] then
				camp_control_tab[camp_level] = {}
			end

			local camp_control_attr_item = camp_control_tab[camp_level]
			camp_control_attr_item.normal_aware_level = tonumber(v.normal_aware_level)
			local hufa = getCampControlTableFromStr(v.hufa_control)
			camp_control_attr_item.hufa_control = hufa
			camp_control_attr_item.order_control_max_level = tonumber(v.order_control)
			camp_control_attr_item.bashi_control = tonumber(v.bashi_control)
			camp_control_attr_item.desc = v.extra_desc
			camp_control_attr_item.unlock_desc = v.unlock_desc
		end
	end

	local file_name7 = "csv_config/cross_server/fight_tip.csv"

	if g_cross_fight_tip == nil or reload_flag then
		local tab_csv = d_ms.d_csv.open2(file_name7)
		g_cross_fight_tip = {}

		for k, v in pairs(tab_csv) do
			table.insert(g_cross_fight_tip, v.tip)
		end
	end

	local file_name8 = "csv_config/cross_server/manual.csv"

	if g_cross_manual == nil or reload_flag then
		local tab_csv = d_ms.d_csv.open2(file_name8)
		g_cross_manual = {}

		for k, v in pairs(tab_csv) do
			g_cross_manual[tonumber(v.page_index)] = {
				title = v.title,
				key_words = getCrossManulList(v.key),
				content = v.content
			}
		end
	end
end

local function getCrossManualCell(str)
	local cell = {}
	local stab = d_ms.d_str.split(str, "|")
	cell.key = stab[1]
	cell.page = tonumber(stab[2])

	return cell
end

function getCrossManulList(str)
	local list = {}
	local stab = d_ms.d_str.split(str, "/")

	for i = 1, #stab do
		table.insert(list, getCrossManualCell(stab[i]))
	end

	return list
end

function getCampControlTableFromStr(str)
	local list = {}
	local stab = d_ms.d_str.split(str, "/")

	for k, v in pairs(stab) do
		local sstab = d_ms.d_str.split(v, "|")
		list[tonumber(sstab[1])] = tonumber(sstab[2])
	end

	return list
end

function transLeveltoStarLevel_crossServer(level)
	if level == 0 then
		return 1
	end

	return math.ceil(level / 3)
end

function getSpecialitemuseCSVConfig()
	if g_specialItemUseTable == nil then
		local item_level_tab_csv = d_ms.d_csv.open("csv_config/happiness_bag_config.csv")
		g_specialItemUseTable = {}

		for i, v in pairs(item_level_tab_csv.records) do
			local specialId = tonumber(v[1])

			if not g_specialItemUseTable[specialId] then
				g_specialItemUseTable[specialId] = {}
			end

			local items_info = g_specialItemUseTable[specialId]
			local item = {
				object_type = tonumber(v[2])
			}
			local stab = d_ms.d_str.split(v[3], "|")
			item.attach_type = tonumber(stab[1])
			item.attach_count = tonumber(stab[2])

			table.insert(items_info, item)
		end
	end
end

function getExchangeData()
	if not g_exchange_table then
		g_exchange_table = {}
		local tab_csv = d_ms.d_csv.open2("csv_config/assist_shop_config.csv")

		for k, v in pairs(tab_csv) do
			g_exchange_table[tonumber(v.index)] = {
				consume = d_ms.d_str.split(v.consume, "|"),
				item = d_ms.d_str.split(v.item, "|")
			}
		end
	end
end

function getTTTfloorDL(floor, max_floor)
	local f = 1

	for i = 1, max_floor do
		if floor >= 5 * i - 4 and floor < 5 * (i + 1) - 4 then
			f = 5 * i - 4

			break
		end
	end

	local tab_csv = d_ms.d_csv.open2("csv_config/babel_tower_floor_prize.csv")
	local prize_list = {}

	for i, v in pairs(tab_csv) do
		if tonumber(v.floor_l) == f then
			local stab = d_ms.d_str.split(v.daoju, "/")
			local index = 1
			local j = 1

			for k, f in pairs(stab) do
				local sstab = d_ms.d_str.split(f, "|")

				if prize_list[index] == nil then
					prize_list[index] = {}
				end

				if prize_list[index][j] == nil then
					prize_list[index][j] = {}
				end

				prize_list[index][j].object_type = tonumber(sstab[1])
				prize_list[index][j].attach_type = tonumber(sstab[2])
				prize_list[index][j].attach_level = tonumber(sstab[3])
				j = j + 1

				if j > 3 then
					j = 1
					index = index + 1
				end
			end
		end
	end

	return prize_list
end

function getTTTfloorDL2(floor, max_floor)
	local f = 1

	for i = 1, max_floor do
		if floor >= 5 * i - 4 and floor < 5 * (i + 1) - 4 then
			f = 5 * i - 4

			break
		end
	end

	local tab_csv = d_ms.d_csv.open2("csv_config/babel_tower_floor_prize.csv")
	local prize_list = {}

	for i, v in pairs(tab_csv) do
		if tonumber(v.floor_l) == f then
			local stab = d_ms.d_str.split(v.daoju, "/")
			local index = 1

			for k, f in pairs(stab) do
				local sstab = d_ms.d_str.split(f, "|")

				if prize_list[index] == nil then
					prize_list[index] = {}
				end

				prize_list[index].object_type = tonumber(sstab[1])
				prize_list[index].attach_type = tonumber(sstab[2])
				prize_list[index].attach_level = tonumber(sstab[3])
				index = index + 1
			end
		end
	end

	return prize_list
end

function getTTTfloorDLSec(floor, max_floor)
	floor = floor - 1000
	max_floor = 15
	local f = 1001

	for i = 1, max_floor do
		if floor >= 3 * i - 2 and floor < 3 * (i + 1) - 2 then
			f = 3 * i - 2

			break
		end
	end

	local tab_csv = d_ms.d_csv.open2("csv_config/babel_secret_tower_floor_prize.csv")
	local prize_list = {}

	for i, v in pairs(tab_csv) do
		if tonumber(v.floor_l - 1000) == f then
			local stab = d_ms.d_str.split(v.daoju, "/")
			local index = 1
			local j = 1

			for k, f in pairs(stab) do
				local sstab = d_ms.d_str.split(f, "|")

				if prize_list[index] == nil then
					prize_list[index] = {}
				end

				if prize_list[index][j] == nil then
					prize_list[index][j] = {}
				end

				prize_list[index][j].object_type = tonumber(sstab[1])
				prize_list[index][j].attach_type = tonumber(sstab[2])
				prize_list[index][j].attach_level = tonumber(sstab[3])
				j = j + 1

				if j > 3 then
					j = 1
					index = index + 1
				end
			end
		end
	end

	return prize_list
end

function getTTTfloorDLSec2(floor, max_floor)
	max_floor = 15
	local f = 1001

	for i = 1, max_floor do
		if floor >= 3 * i - 2 and floor < 3 * (i + 1) - 2 then
			f = 3 * i - 2

			break
		end
	end

	local tab_csv = d_ms.d_csv.open2("csv_config/babel_secret_tower_floor_prize.csv")
	local prize_list = {}

	for i, v in pairs(tab_csv) do
		if tonumber(v.floor_l - 1000) == f then
			local stab = d_ms.d_str.split(v.daoju, "/")
			local index = 1

			for k, f in pairs(stab) do
				local sstab = d_ms.d_str.split(f, "|")

				if prize_list[index] == nil then
					prize_list[index] = {}
				end

				prize_list[index].object_type = tonumber(sstab[1])
				prize_list[index].attach_type = tonumber(sstab[2])
				prize_list[index].attach_level = tonumber(sstab[3])
				index = index + 1
			end
		end
	end

	return prize_list
end
