local require = require
local bits = bits
local sqlite = sqlite
local type = type
local print = print
local tostring = tostring
local pairs = pairs
local string = string
local table = table
local math = math
local main_server = main_server
local _G = _G
local bits = bits
local tonumber = tonumber
local tolua = tolua
local class = class
local CCArray = CCArray
local CCDirector = CCDirector
local CCLayer = CCLayer
local CCMenu = CCMenu
local CCMenuItemImage = CCMenuItemImage
local CCSprite = CCSprite
local CCScene = CCScene
local CCTextFieldTTF = CCTextFieldTTF
local CCTOUCHBEGAN = CCTOUCHBEGAN
local CCTOUCHMOVED = CCTOUCHMOVED
local CCLayerColor = CCLayerColor
local CCMenuItemSprite = CCMenuItemSprite
local CCMenuItemImage = CCMenuItemImage
local CCRectMake = CCRectMake
local CCPointMake = CCPointMake
local CCMoveBy = CCMoveBy
local CCMenuItemFont = CCMenuItemFont
local CCEaseOut = CCEaseOut
local CCSequence = CCSequence
local CCEaseElasticOut = CCEaseElasticOut
local CCEaseElastic = CCEaseElastic
local CCEaseBounce = CCEaseBounce
local CCEaseBounceInOut = CCEaseBounceInOut
local CCEaseBounceOut = CCEaseBounceOut
local CCEaseBackInOut = CCEaseBackInOut
local CCSizeMake = CCSizeMake
local CCScrollView = CCScrollView
local CCCallFuncN = CCCallFuncN
local CCMoveTo = CCMoveTo
local CCSpawn = CCSpawn
local CCTargetedAction = CCTargetedAction
local CCOrbitCamera = CCOrbitCamera
local CCFadeOut = CCFadeOut
local CCScaleBy = CCScaleBy
local CCFadeIn = CCFadeIn
local CCScaleTo = CCScaleTo
local ccBezierConfig = ccBezierConfig
local CCBezierTo = CCBezierTo
local CCNode = CCNode
local CCRectMake = CCRectMake
local io = io
local ccp = ccp
local ccc3 = ccc3
local ccc4 = ccc4
local ccpAdd = ccpAdd

module("ui.lineupUI")

d_ms = require("ms")

if not d_ms then
	print("lineupUI load d_ms fail.\n")
end

local function cclog(...)
	print(string.format(...))
end

r_p = d_ms.d_common_def.role_property
c_p = d_ms.d_common_def.cortege_property
i_p = d_ms.d_common_def.item_property
s_p = d_ms.d_common_def.skill_property
o_t = d_ms.d_common_def.object_type
m_t = d_ms.d_common_def.item_main_type
g_maxLevel = 60
g_lineupUI = {}
g_AscTable = {}
g_characterAttrTable = nil
g_usedCharacters = {}
g_cheerCharacters = {}
g_characterInfo = nil
g_showOrder = 0
g_button = {}
g_lastSelectedButton = 0
g_beSelectedButton = 0
g_characterButton = {}
g_fateAttrTable = nil
g_fateLabelList = {}
g_showDetailClickVoice = true
g_displayLineupInfo = {}
g_guideChangeItem = nil
g_guideSelectItem = nil
g_guideEnsureSelectItem = nil
g_characterMaxGrowth = nil
g_last_silver = 0

function saveLastFightLevel()
	for i, v in pairs(g_usedCharacters) do
		if v.character.level then
			v.character.last_fight_level = v.character.level
		end
	end

	g_last_silver = d_ms.d_mainUI.g_playerInfo.silver_coin
end

function getSilverAdd()
	if not d_ms.d_mainUI.g_playerInfo.silver_coin then
		return 0
	end

	return d_ms.d_mainUI.g_playerInfo.silver_coin - g_last_silver
end

function getCharNameById(id)
	local ret = ""

	for i, v in pairs(g_characterInfo) do
		if v.id == id then
			return v.csvInfo.name
		end
	end

	return ret
end

function getDateFormServer(msg_table)
	cclog("getDateFormServer:1034")

	if msg_table.first_send == true then
		cclog("getDateFormServer:1034  first_send is true")

		g_characterInfo = {}
		g_characterInfo = msg_table.cortege_list
		g_AscTable = {}
	else
		cclog("getDateFormServer:1034  first_send is false")

		if not g_characterInfo then
			g_characterInfo = {}
		end

		for i = 1, #msg_table.cortege_list do
			g_characterInfo[#g_characterInfo + 1] = msg_table.cortege_list[i]
		end
	end

	for k, v in pairs(msg_table.cortege_list) do
		if v.reborn_layer > 0 then
			g_AscTable[v.type] = true
		end
	end

	cclog("start sort character")
	sortcharacterInfo()
	cclog("end sort character")

	if not d_ms.d_packageUI.g_isPackageSorted then
		d_ms.d_packageUI.sortItems()
	end

	cclog("getDateFormServer:1034 end")
end

function updateCharacterInfo(msg_table)
	if g_characterInfo == nil then
		g_characterInfo = {}
	end

	local characterInfo = g_characterInfo
	local updateCharacter = nil

	for i = 1, #characterInfo do
		if msg_table.id == characterInfo[i].id then
			updateCharacter = characterInfo[i]

			break
		end
	end

	local isNeedResort = false

	if updateCharacter ~= nil then
		for i = 1, msg_table.attr_count do
			if msg_table.attr_list[i].type == c_p.level then
				updateCharacter.level = msg_table.attr_list[i].value
				isNeedResort = true
			elseif msg_table.attr_list[i].type == c_p.order then
				updateCharacter.order = msg_table.attr_list[i].value
				isNeedResort = true
			elseif msg_table.attr_list[i].type == c_p.cheer_order then
				updateCharacter.cheer_order = msg_table.attr_list[i].value
				isNeedResort = true
			elseif msg_table.attr_list[i].type == c_p.max_hp_show then
				updateCharacter.hp = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == c_p.max_magic_show then
				updateCharacter.magic = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == c_p.wuligongji_show then
				updateCharacter.gongji = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == c_p.wulifangyu_show then
				updateCharacter.fangyu = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == c_p.cur_exp then
				updateCharacter.cur_exp = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == c_p.next_exp then
				updateCharacter.next_exp = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == c_p.culture_point then
				updateCharacter.culture_point = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == c_p.culture_max_hp_plus then
				updateCharacter.hp_plus = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == c_p.culture_wuligongji_plus then
				updateCharacter.gongji_plus = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == c_p.culture_wulifangyu_plus then
				updateCharacter.fangyu_plus = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == c_p.culture_max_magic_plus then
				updateCharacter.magic_plus = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == c_p.train_change_value then
				updateCharacter.train_change_value = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == c_p.train_increase_field then
				updateCharacter.train_increase_field = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == c_p.train_decrease_field then
				updateCharacter.train_decrease_field = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == c_p.evolve_level then
				updateCharacter.evolve_level = msg_table.attr_list[i].value
			else
				local t_name = d_ms.d_common_def.attr_name_of_cortege[msg_table.attr_list[i].type]

				if msg_table.attr_list[i].type >= 340 and msg_table.attr_list[i].type <= 391 then
					cclog("update item property, property_name=" .. t_name)

					updateCharacter[t_name] = msg_table.attr_list[i].value
				elseif updateCharacter[t_name] then
					updateCharacter[t_name] = msg_table.attr_list[i].value
				elseif t_name then
					cclog("ERROR: 1032 can not find cortege_property=[" .. t_name .. "] in cortege.")
				end
			end
		end
	end

	if isNeedResort then
		sortcharacterInfo()
	end
end

function sortcharacterInfo()
	cclog("sortcharacterInfo")

	local characterInfoTable = g_characterInfo

	if characterInfoTable == nil then
		cclog("can use item table")

		return
	end

	local attributeStr = nil
	g_usedCharacters = {}
	g_cheerCharacters = {}

	cclog("start get csvInfo")
	getFateCSVConfig()
	getCharacterCSVConfig()
	cclog("end get csvInfo")
	cclog("sort character")

	for i = 1, #characterInfoTable do
		characterInfoTable[i].csvInfo = g_characterAttrTable[characterInfoTable[i].type]

		if characterInfoTable[i].order ~= 0 then
			local characterInfo = {
				character = characterInfoTable[i],
				index = i
			}

			table.insert(g_usedCharacters, characterInfo)
		end

		local cheer_order = characterInfoTable[i].cheer_order

		if cheer_order and cheer_order ~= 0 then
			local characterInfo = {
				character = characterInfoTable[i],
				index = i
			}
			g_cheerCharacters[cheer_order] = characterInfo
		end
	end

	cclog("start sort character")
	table.sort(characterInfoTable, sortCharacter)
	table.sort(g_usedCharacters, sortcharacterByOrder)

	g_displayLineupInfo.usedCharacters = g_usedCharacters

	cclog("sort character end")
end

function sortCharacter(a, b)
	local isA_In = a.order > 0
	local isB_In = b.order > 0

	if isA_In and isB_In or not isA_In and not isB_In then
		isA_In = a.cheer_order > 0
		isB_In = b.cheer_order > 0

		if isA_In and isB_In or not isA_In and not isB_In then
			return d_ms.d_charPositionUI.sortChar(a, b)
		else
			return b.cheer_order < a.cheer_order
		end
	else
		return b.order < a.order
	end
end

function sortcharacterByOrder(a, b)
	return a.character.order < b.character.order
end

function callbackRemoveCortege(data)
	cclog("callbackRemoveCortege")

	if data and data.object_list and #data.object_list > 0 then
		for i = 1, #data.object_list do
			deleteChar(data.object_list[i])
		end
	end

	d_ms.d_data.updateAllSoulsStatus()
end

function deleteChar(obj_id)
	cclog("deleteChar")

	for i, v in pairs(d_ms.d_lineupUI.g_characterInfo) do
		if v.id == obj_id then
			table.remove(d_ms.d_lineupUI.g_characterInfo, i)
			cclog("deleteChar ok, id=" .. obj_id)

			return
		end
	end

	cclog("ERRROR: delete Char fail, id=" .. obj_id)
end

function getFateCSVConfig()
	if g_fateAttrTable == nil then
		local fate_attr_tab_csv = d_ms.d_csv.open("csv_config/fate_config.csv")
		g_fateAttrTable = {
			character = {},
			item = {}
		}
		local character_fate_tab = g_fateAttrTable.character
		local item_fate_tab = g_fateAttrTable.item

		for i, v in pairs(fate_attr_tab_csv.records) do
			local fate_table = {
				effectField = tonumber(v[2]),
				effectValue = tonumber(v[3]),
				character = tonumber(v[4]),
				targetType = tonumber(v[5]),
				targetList = v[6],
				description = v[7],
				introduction = v[8]
			}
			local character = fate_table.character

			if character_fate_tab[character] == nil then
				character_fate_tab[character] = {}
			end

			local len = #character_fate_tab[character]
			character_fate_tab[character][len + 1] = fate_table
			local targetType = fate_table.targetType

			if targetType == 5 or targetType == 6 then
				local item_table = parseFateTargetStr(fate_table.targetList)

				if item_table ~= nil and #item_table > 0 then
					for i = 1, #item_table do
						local itemID = tonumber(item_table[i])

						if item_fate_tab[itemID] == nil then
							item_fate_tab[itemID] = {}
						end

						local len = #item_fate_tab[itemID]
						item_fate_tab[itemID][len + 1] = fate_table
					end
				end
			end
		end
	end
end

function parseFateTargetStr(str)
	local pos1 = 1
	local pos2 = string.find(str, "/")
	local itemList = {}

	while pos2 ~= nil do
		itemList[#itemList + 1] = string.sub(str, pos1, pos2 - 1)
		pos1 = pos2 + 1

		if string.len(str) <= pos1 then
			break
		end

		pos2 = string.find(str, "/", pos1)
	end

	itemList[#itemList + 1] = string.sub(str, pos1)

	return itemList
end

function getCharacterCSVConfig(map_id)
	local file_name1, file_name2 = nil
	local reload_flag = false
	local cortege_0_flag = false

	if map_id == "elite" then
		file_name1 = "csv_config/elite/elite_cortege_name.csv"
		file_name2 = "csv_config/elite/elite_cortege_base.csv"
		reload_flag = true
	elseif map_id == "specter_boss" then
		file_name1 = "csv_config/elite/specter_cortege_name.csv"
		file_name2 = "csv_config/elite/specter_cortege_base.csv"
		reload_flag = true
	elseif map_id then
		if g_characterAttrTable == nil or g_characterAttrTable[map_id * 10000 + 101] == nil then
			reload_flag = true
		end

		file_name1 = "csv_config/cortege/cortege_name_" .. map_id .. ".csv"
		file_name2 = "csv_config/cortege/cortege_base_" .. map_id .. ".csv"
	else
		file_name1 = "csv_config/cortege/cortege_name_0.csv"
		file_name2 = "csv_config/cortege/cortege_base_0.csv"
		cortege_0_flag = true
	end

	if g_characterAttrTable == nil or reload_flag then
		local characterHZ_tab_csv = d_ms.d_csv.open(file_name1)
		local characterHZ_tab = {}

		for i, v in pairs(characterHZ_tab_csv.records) do
			local id = tonumber(v[1])

			if not characterHZ_tab[id] then
				characterHZ_tab[id] = {}
			end

			local characterHZ = characterHZ_tab[id]
			characterHZ.name = v[2]
			characterHZ.introduction = v[3]
		end

		local character_attr_tab_csv = d_ms.d_csv.open(file_name2)

		if not g_characterAttrTable then
			g_characterAttrTable = {}
		end

		local character_attr_tab = g_characterAttrTable
		local maxDamageGrowth = 0
		local maxDefenceGrowth = 0
		local maxHpGrowth = 0
		local maxManaGrowth = 0

		for i, v in pairs(character_attr_tab_csv.records) do
			local id = tonumber(v[1])

			if not character_attr_tab[id] then
				character_attr_tab[id] = {}
			end

			local base_type = tonumber(v[2])
			local name = v[3]
			local character_attr = character_attr_tab[id]
			character_attr.category = tonumber(v[4])
			character_attr.name = characterHZ_tab[id].name or ""
			character_attr.file = v[5]
			character_attr.quality = tonumber(v[6])
			character_attr.damage = tonumber(v[7])
			character_attr.defence = tonumber(v[8])
			character_attr.hp = tonumber(v[9])
			character_attr.mana = tonumber(v[10])
			character_attr.damageOffset = tonumber(v[11])
			character_attr.defenceOffset = tonumber(v[12])
			character_attr.hpOffset = tonumber(v[13])
			character_attr.manaOffset = tonumber(v[14])
			character_attr.originalSkill = tonumber(v[15])
			character_attr.introduction = characterHZ_tab[id].introduction or ""
			character_attr.floatType = tonumber(v[16])
			character_attr.offset_x = tonumber(v[17])
			character_attr.offset_y = tonumber(v[18])
			character_attr.book_hide = tonumber(v[19])

			if tonumber(v[1]) < 6000 then
				if maxDamageGrowth < character_attr.damageOffset then
					maxDamageGrowth = character_attr.damageOffset
				end

				if maxDefenceGrowth < character_attr.defenceOffset then
					maxDefenceGrowth = character_attr.defenceOffset
				end

				if maxHpGrowth < character_attr.hpOffset then
					maxHpGrowth = character_attr.hpOffset
				end

				if maxManaGrowth < character_attr.manaOffset then
					maxManaGrowth = character_attr.manaOffset
				end
			end
		end

		if cortege_0_flag == true then
			g_characterMaxGrowth = {
				damage = maxDamageGrowth,
				defence = maxDefenceGrowth,
				health = maxHpGrowth,
				mana = maxManaGrowth
			}
		end
	end
end

function updateItemInfoOwnerId(msg_table)
	cclog("call updateItemInfoOwnerId")

	if msg_table.ext_skill_id and msg_table.owner_id then
		local itemInfo = d_ms.d_packageUI.g_packageItemsInfo

		for i = 1, #itemInfo do
			if msg_table.object_type == itemInfo[i].attach_type and msg_table.ext_skill_id == itemInfo[i].id then
				itemInfo[i].owner_id = msg_table.owner_id
				d_ms.d_packageUI.g_isPackageSorted = false

				break
			end
		end
	end
end

function updateItemInfo(msg_table)
	if d_ms.d_packageUI.g_packageItemsInfo == nil then
		return
	end

	local itemInfo = d_ms.d_packageUI.g_packageItemsInfo
	local updateItem = nil
	local index = 0

	for i = 1, #itemInfo do
		if msg_table.id == itemInfo[i].id and itemInfo[i].attach_type == o_t.item then
			updateItem = itemInfo[i]
			index = i

			break
		end
	end

	if updateItem ~= nil then
		local packageTag = 0

		if updateItem.csvInfo then
			packageTag = updateItem.csvInfo.packageTag
		end

		for i = 1, msg_table.attr_count do
			if msg_table.attr_list[i].type == i_p.level then
				updateItem.level = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == i_p.count then
				if msg_table.attr_list[i].value == 0 then
					table.remove(itemInfo, index)

					updateItem.count = msg_table.attr_list[i].value
				else
					updateItem.count = msg_table.attr_list[i].value
				end
			elseif msg_table.attr_list[i].type == i_p.equip_pos then
				updateItem.equip_pos = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == i_p.order then
				updateItem.equip_order = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == i_p.gongji_plus and packageTag == d_ms.d_packageUI.packageTagDef.weapon then
				updateItem.effect_value = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == i_p.fangyu_plus and packageTag == d_ms.d_packageUI.packageTagDef.armor then
				updateItem.effect_value = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == i_p.maxhp_plus and packageTag == d_ms.d_packageUI.packageTagDef.fabao then
				updateItem.effect_value = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == i_p.effect_value then
				-- Nothing
			elseif msg_table.attr_list[i].type == i_p.owner_id then
				-- Nothing
			elseif msg_table.attr_list[i].type == i_p.star_level then
				updateItem.star_level = msg_table.attr_list[i].value
			else
				local has_find_value = false

				for t_name, t_number in pairs(i_p) do
					if t_number == msg_table.attr_list[i].type then
						has_find_value = true

						cclog("update item property, property_name=" .. t_name)

						if updateItem[t_name] then
							updateItem[t_name] = msg_table.attr_list[i].value

							break
						end

						cclog("ERROR: 1032 can not find item_property=[" .. t_name .. "] in item.")

						break
					end
				end

				if has_find_value == false then
					cclog("ERROR: 1032 unhandle item_property=" .. msg_table.attr_list[i].type)
				end
			end
		end

		if not updateItem.csvInfo then
			updateItem.csvInfo = d_ms.d_data.getCertainInfo(updateItem.attach_type, updateItem.type_id)
		end

		local mainType = updateItem.csvInfo.mainType
		local package = d_ms.d_packageUI.g_reorgItemsInfo[o_t.item][mainType] or {}

		for i = 1, #package do
			if package[i].id == updateItem.id then
				if updateItem.count <= 0 then
					table.remove(package, i)

					break
				end

				package[i] = updateItem

				break
			end
		end

		d_ms.d_packageUI.g_isPackageSorted = false
	end
end

function updateSkillInfo(msg_table)
	if d_ms.d_packageUI.g_packageItemsInfo == nil then
		return
	end

	local itemInfo = d_ms.d_packageUI.g_packageItemsInfo
	local updateSkill = nil

	for i = 1, #itemInfo do
		if msg_table.id == itemInfo[i].id and itemInfo[i].attach_type == o_t.skill then
			updateSkill = itemInfo[i]

			break
		end
	end

	if updateSkill ~= nil then
		for i = 1, msg_table.attr_count do
			if msg_table.attr_list[i].type == s_p.level then
				updateSkill.level = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == s_p.equip_pos then
				updateSkill.equip_pos = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == s_p.order then
				updateSkill.equip_order = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == s_p.gongji_plus then
				updateSkill.effect_value = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == s_p.fangyu_plus then
				updateSkill.effect_value = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == s_p.magic_plus then
				updateSkill.effect_value = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == s_p.prob_compen then
				updateSkill.count = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == s_p.upgrade_level then
				updateSkill.upgrade_level = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == s_p.awaken then
				updateSkill.awaken = msg_table.attr_list[i].value
			elseif msg_table.attr_list[i].type == s_p.intensity then
				updateSkill.effect_value = msg_table.attr_list[i].value
			end
		end

		local package = d_ms.d_packageUI.g_reorgItemsInfo[o_t.skill]

		for i = 1, #package do
			if package[i].id == updateSkill.id then
				package[i] = updateSkill
			end
		end
	end

	d_ms.d_packageUI.g_isPackageSorted = false
end

function show(index)
	g_index = index or 1

	create(d_ms.d_mainUI.g_mainUI.main_layer)

	d_ms.d_mainUI.g_currentBoard = d_ms.d_mainUI.boardID.lineup

	d_ms.d_mainUI.g_mainUI.player_layer:setVisible(false)

	if d_ms.d_mainUI.g_mainUI.menu_other_layer ~= nil then
		d_ms.d_mainUI.g_mainUI.main_layer:removeChild(d_ms.d_mainUI.g_mainUI.menu_other_layer, true)

		d_ms.d_mainUI.g_mainUI.menu_other_layer = nil
	end
end

function create(parent)
	local childBoard = parent:getChildByTag(d_ms.d_mainUI.boardID.lineup)

	if childBoard then
		return
	end

	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	g_lineupUI = {}
	local main_layer = parent
	local board_layer = CCLayer:create()

	main_layer:addChild(board_layer, 5)
	board_layer:setTag(d_ms.d_mainUI.boardID.lineup)

	d_ms.d_mainUI.g_boardlayer[d_ms.d_mainUI.boardID.lineup] = board_layer
	g_lineupUI.board_layer = board_layer
	g_lineupUI.main_layer = main_layer
	local position = {
		x = 0.5,
		y = 0.56
	}
	local scaleXY = {
		scaleY = 0.8,
		scaleX = 0.95
	}
	local closeMenu = nil
	g_lineupUI.board_size, closeMenu = d_ms.d_mainUI.createBoardBkg(board_layer, position, scaleXY, false)
	g_guideCloseMenu = closeMenu
	local item_menu_list = {
		{
			npic = "v2/CharaterUI/shenxian1.png",
			scale = 0.18,
			disPic = "v2/CharaterUI/shenxian2.png",
			tag = 1,
			x = 0,
			y = -0.12 * 0,
			call_back = ClickShowDetailUI
		},
		{
			npic = "v2/CharaterUI/hunpo1.png",
			scale = 0.18,
			disPic = "v2/CharaterUI/hunpo2.png",
			y = -0.12,
			tag = 2,
			x = 0,
			call_back = ClickShowDetailUI
		},
		{
			npic = "v2/CharaterUI/jingpo1.png",
			scale = 0.18,
			disPic = "v2/CharaterUI/jingpo2.png",
			y = -0.24,
			tag = 3,
			x = 0,
			call_back = ClickShowDetailUI
		},
		{
			npic = "v2/CharaterUI/common1.png",
			scale = 0.18,
			disPic = "v2/CharaterUI/common2.png",
			y = -0.36,
			tag = 4,
			x = 0,
			call_back = ClickShowDetailUI
		},
		{
			npic = "v2/handbook/tj_btn1.png",
			scale = 0.12,
			disPic = "v2/handbook/tj_btn2.png",
			y = -0.5720000000000001,
			x = 0,
			call_back = pressHandBook
		},
		x = 0.12,
		y = 0.88
	}
	g_button = {}

	board_layer:addChild(d_ms.d_u.createMenu(item_menu_list, g_button, true))

	if not d_ms.d_soulExchangeUI.g_self.isOpen then
		g_button[3]:setVisible(false)
		g_button[3]:setEnabled(false)
	end

	g_lineupUI.detail_layer = CCLayer:create()

	board_layer:addChild(g_lineupUI.detail_layer)

	if index ~= 5 then
		board_layer:setPosition(d_ms.d_u.makePoint(0, 1))
		d_ms.d_mainUI.showBoard(board_layer)
	end

	g_showOrder = 0
	g_displayLineupInfo = {}

	showDetailUI(g_index)
end

function reShowDetail(arg)
	if arg == 1 then
		showDetailUI(arg)

		return
	end

	d_ms.d_formationUI.reloadSrcCharList()
	showDetailUI(g_beSelectedButton)
end

function pressHandBook()
	cclog("call pressHandBook")

	d_ms.d_handbookUI.g_self.ready_open_tag = 4

	d_ms.d_other_functionUI.menuHandbookCallback(d_ms.d_handbookUI.g_self.ready_open_tag)
end

function ClickShowDetailUI(tag)
	d_ms.d_music_mgr.playClickEffect()
	showDetailUI(tag)
end

function createCommonSoulCellOnPackage(parentNode, info, bkgPic, cellSize)
	d_ms.d_soulExchangeUI.createCommonSoulCell(parentNode, info, bkgPic, cellSize)

	local function gotoExchange()
		d_ms.d_soulExchangeUI.show(d_ms.d_mainUI.g_mainUI.main_layer, info.type_id)
	end

	local menuItemsDefs = {
		menuItems = {
			{
				npic = "v2/CharaterUI/exchange1.png",
				spic = "v2/CharaterUI/exchange2.png",
				tapHandler = gotoExchange,
				pos = ccp(cellSize.width * 0.85, cellSize.height * 0.3)
			}
		},
		priority = -128,
		usedDefaultRect = true
	}
	local menuLayer = d_ms.d_tableView.createTableViewMenu(menuItemsDefs)

	parentNode:addChild(menuLayer)
end

function getAllCommonSoulDataSource(infoTable)
	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local cellSize = CCSizeMake(0.7 * scrSize.width, 0.21 * scrSize.height)
	local bkgPic = "v2/packageUI/xinxilan.png"
	local dataSource = {}
	local num = #infoTable

	function dataSource.tableViewNumberOfRows()
		return num
	end

	function dataSource.drawCellAtIndex(index)
		local cell = CCNode:create()

		if infoTable[index] then
			createCommonSoulCellOnPackage(cell, infoTable[index], bkgPic, cellSize)
		end

		return cell
	end

	function dataSource.heightForRowAtIndex(index)
		return cellSize.height
	end

	return dataSource
end

function showCommonSoul()
	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local board_size = g_lineupUI.board_size
	local touchArea = {
		x = scrSize.width * 0.24,
		y = board_size.y,
		width = board_size.width,
		height = board_size.height * 0.97
	}
	local displayLayer = CCLayer:create()

	g_lineupUI.detail_layer:addChild(displayLayer)

	local data = d_ms.d_packageUI.g_reorgItemsInfo[o_t.item][m_t.adaptive_spirit] or {}

	if #data == 0 then
		return false
	end

	table.sort(data, d_ms.d_soulExchangeUI.adaptiveSpiritSort)

	local charTableView = d_ms.d_tableView.tableView(displayLayer, touchArea)
	local dataSource = getAllCommonSoulDataSource(data)

	charTableView:startScroll()
	charTableView:setDataSource(dataSource)
end

function createJingpoCellOnPackage(parentNode, info, cellSize)
	local bkgSprite = CCSprite:create("v2/packageUI/xinxilan.png")

	bkgSprite:setPosition(ccp(cellSize.width * 0.5, cellSize.height * 0.5))
	parentNode:addChild(bkgSprite, -1)

	local bkgSize = bkgSprite:getContentSize()

	bkgSprite:setScaleX(cellSize.width / bkgSize.width)
	bkgSprite:setScaleY(0.9 * cellSize.height / bkgSize.height)

	local csvInfo = info.csvInfo
	local nameLabel = d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		fontsize = 30,
		string = csvInfo.name,
		anchor = {
			0,
			0.5
		},
		color = {
			254,
			235,
			192
		}
	})

	parentNode:addChild(nameLabel, 1)
	nameLabel:setPosition(cellSize.width * 0.2, cellSize.height * 0.7)

	local starsLevelSprite = CCSprite:create("v2/introUI/stars.png")

	parentNode:addChild(starsLevelSprite, 1)
	starsLevelSprite:setPosition(cellSize.width * 0.43, cellSize.height * 0.7)
	starsLevelSprite:setAnchorPoint(ccp(0, 0.5))

	local starsContentSize = starsLevelSprite:getContentSize()

	starsLevelSprite:setTextureRect(CCRectMake(0, 0, starsContentSize.width * csvInfo.quality / 5, starsContentSize.height))
	parentNode:addChild(d_ms.d_u.createByStyle({
		pic = "v2/introUI/level.png",
		pos_x = cellSize.width * 0.22,
		pos_y = cellSize.height * 0.33
	}))
	parentNode:addChild(d_ms.d_u.createByStyle({
		type = "label",
		font = "arial",
		fontsize = 26,
		string = tostring(info.level or 1),
		anchor = {
			0,
			0.5
		},
		color = {
			241,
			218,
			182
		},
		pos_x = cellSize.width * 0.26,
		pos_y = cellSize.height * 0.33
	}))

	local menuItems = {}

	if info.owner_id > 0 then
		local o_name = d_ms.d_lineupUI.getCharNameById(info.owner_id)

		if o_name and #o_name > 0 then
			local hintLabel = d_ms.d_u.createByStyle({
				fontsize = 22,
				type = "label",
				string = d_ms.d_hz.gethz("equip") .. o_name,
				pos_x = cellSize.width * 0.83,
				pos_y = cellSize.height * 0.7,
				color = {
					186,
					169,
					157
				}
			})

			parentNode:addChild(hintLabel, 1)
		end

		local function gotoMK()
			d_ms.d_jpmkUI.show(d_ms.d_mainUI.g_mainUI.main_layer, 1000, info.owner_id)
		end

		table.insert(menuItems, {
			npic = "v2/jpmkUI/jp_mk1.png",
			spic = "v2/jpmkUI/jp_mk1.png",
			tapHandler = gotoMK,
			pos = ccp(cellSize.width * 0.85, cellSize.height * 0.3)
		})
	else
		local numLabel = d_ms.d_u.createByStyle({
			fontsize = 22,
			type = "label",
			string = d_ms.d_hz.gethz("number") .. ": " .. info.count,
			pos_x = cellSize.width * 0.43,
			pos_y = cellSize.height * 0.3,
			anchor = {
				0,
				0.5
			},
			color = {
				254,
				235,
				192
			}
		})

		parentNode:addChild(numLabel, 1)

		local function gotoForge()
			local transInfo = d_ms.d_data.getTransInfoByTypeid(info.type_id)

			d_ms.d_smithUI.show(transInfo)
		end

		table.insert(menuItems, {
			npic = "v2/transformUI/btn11.png",
			spic = "v2/transformUI/btn12.png",
			tapHandler = gotoForge,
			pos = ccp(cellSize.width * 0.85, cellSize.height * 0.3)
		})
	end

	local iconSprite1 = d_ms.d_data.getCertainSmallSprite(info.attach_type, info.type_id)
	local iconSprite2 = d_ms.d_data.getCertainSmallSprite(info.attach_type, info.type_id)

	local function showDetail()
		local introLayer = nil

		local function closeIntroLayer()
			if introLayer then
				d_ms.d_u.remove(introLayer)
			end
		end

		introLayer = d_ms.d_packageUI.createItemIntroLayer(info, closeIntroLayer)
		local parent = CCDirector:sharedDirector():getRunningScene()

		parent:addChild(introLayer, 300)
	end

	table.insert(menuItems, {
		nSprite = iconSprite1,
		sSprite = iconSprite2,
		tapHandler = showDetail,
		pos = ccp(cellSize.width * 0.1, cellSize.height * 0.5)
	})

	local menuItemsDefs = {
		usedDefaultRect = true,
		menuItems = menuItems
	}
	local menuLayer = d_ms.d_tableView.createTableViewMenu(menuItemsDefs)

	parentNode:addChild(menuLayer)
end

function getAllJingpoDataSource(infoTable, cellSize)
	local dataSource = {}
	local num = #infoTable

	function dataSource.tableViewNumberOfRows()
		return num
	end

	function dataSource.drawCellAtIndex(index)
		local cell = CCNode:create()

		if infoTable[index] then
			createJingpoCellOnPackage(cell, infoTable[index], cellSize)
		end

		return cell
	end

	function dataSource.heightForRowAtIndex(index)
		return cellSize.height
	end

	return dataSource
end

function showJingpo()
	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local board_size = g_lineupUI.board_size
	local touchArea = {
		x = scrSize.width * 0.24,
		y = board_size.y,
		width = board_size.width,
		height = board_size.height * 0.97
	}
	local cellSize = CCSizeMake(0.7 * scrSize.width, 0.21 * scrSize.height)
	local displayLayer = CCLayer:create()

	d_ms.d_u.addOnlyChild(g_lineupUI.detail_layer, displayLayer, 10235)

	local data = d_ms.d_packageUI.g_reorgItemsInfo[o_t.item][m_t.ext_skill] or {}

	if #data == 0 then
		return false
	end

	table.sort(data, d_ms.d_jpmkUI.jpSort)

	local charTableView = d_ms.d_tableView.tableView(displayLayer, touchArea)
	local dataSource = getAllJingpoDataSource(data, cellSize)

	charTableView:startScroll()
	charTableView:setDataSource(dataSource)
end

function onSoulExchangeExit()
	if d_ms.d_mainUI.g_currentBoard == d_ms.d_mainUI.boardID.lineup and g_lastSelectedButton == 4 then
		g_lineupUI.detail_layer:removeAllChildrenWithCleanup(true)
		showCommonSoul()
	end
end

function showDetailUI(tag)
	if g_lastSelectedButton ~= 0 then
		local menuItem = g_button[g_lastSelectedButton]

		menuItem:setEnabled(true)
	end

	g_lineupUI.detail_layer:removeAllChildrenWithCleanup(true)
	g_button[tag]:setEnabled(false)

	g_lastSelectedButton = tag

	if g_characterInfo == nil then
		requestShowCharacters()
	elseif tag == 1 then
		d_ms.d_allLineupUI.showAllCharacters(g_lineupUI.detail_layer)
	elseif tag == 2 then
		d_ms.d_allLineupUI.showAllSoul(g_lineupUI.detail_layer)
	elseif tag == 3 then
		showJingpo()
	elseif tag == 4 then
		showCommonSoul()
	end
end

function requestShowCharacters()
	local tmp_req = {
		flag = 1
	}

	cclog("send ST_msg_query_cortege_list_1033 to BS.")
	d_ms.d_u.main_server_send_msg(d_ms.d_msg_def.gscl_msg_id.msg_query_cortege_list, tmp_req)
end

function downwardDisplayHZ(parent, hzStr, fontSize, displayLength, position, color)
	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local hzHeightOffset = 0
	local hzWidthOffset = 0

	for uchar in string.gfind(hzStr, "[%z-\\xc2-\\xf4][\\x80-\\xbf]*") do
		local label = d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			string = uchar,
			x = position.x,
			y = position.y - hzHeightOffset,
			fontsize = fontSize
		})

		if color then
			label:setColor(color)
		end

		hzHeightOffset = hzHeightOffset + label:getContentSize().height * label:getScaleY() / scrSize.height

		if hzWidthOffset < label:getContentSize().width * label:getScaleX() / scrSize.width then
			hzWidthOffset = label:getContentSize().width * label:getScaleX() / scrSize.width
		end

		if displayLength < hzHeightOffset then
			hzHeightOffset = 0
			position.x = position.x - hzWidthOffset
		end

		if position and position.z then
			parent:addChild(label, position.z)
		else
			parent:addChild(label)
		end
	end
end

g_addMoreItems_params1 = {}

function createPackageCells(cells_view, packageTag, introCallBack, filter_callback, packageItemsInfo, isShowAllItems)
	position_x = 0.1
	position_y = 0.65
	local packageItemsInfo = packageItemsInfo or d_ms.d_packageUI.g_packageItemsInfo
	local spriteList = {}
	local packageTagDef = d_ms.d_packageUI.packageTagDef
	g_packageListIndex1 = 0
	g_addMoreItems_params1 = {
		cells_view = cells_view,
		packageTag = packageTag,
		introCallBack = introCallBack,
		filter_callback = filter_callback,
		packageItemsInfo = packageItemsInfo,
		isShowAllItems = isShowAllItems,
		spriteList = spriteList,
		packageTagDef = packageTagDef
	}

	addMoreItems1()
	cells_view:setNearToEndCallBack(addMoreItems1, 0.5)

	return spriteList
end

function addMoreItems1()
	cclog("call addMoreItems1")

	local cells_view = g_addMoreItems_params1.cells_view
	local packageTag = g_addMoreItems_params1.packageTag
	local introCallBack = g_addMoreItems_params1.introCallBack
	local filter_callback = g_addMoreItems_params1.filter_callback
	local packageItemsInfo = g_addMoreItems_params1.packageItemsInfo
	local isShowAllItems = g_addMoreItems_params1.isShowAllItems
	local spriteList = g_addMoreItems_params1.spriteList
	local packageTagDef = g_addMoreItems_params1.packageTagDef
	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local menuItemArray = CCArray:create()
	local menuOnCellArray = CCArray:create()
	local order = 1
	local count = 10

	for i = 1 + g_packageListIndex1, #packageItemsInfo do
		g_packageListIndex1 = g_packageListIndex1 + 1
		local isItemShow = true

		if isShowAllItems ~= nil and isShowAllItems == true then
			packageTag = packageItemsInfo[i].csvInfo.packageTag
		elseif packageItemsInfo[i].csvInfo.packageTag ~= packageTag then
			isItemShow = false
		end

		if isItemShow and filter_callback ~= nil and filter_callback(i) == true then
			isItemShow = false
		end

		if isItemShow then
			if count > 0 then
				count = count - 1
			else
				g_packageListIndex1 = g_packageListIndex1 - 1

				break
			end

			local parent = CCLayer:create()

			parent:setTag(i)

			local spriteBkg = CCSprite:create("v2/packageUI/xinxilan.png")

			d_ms.d_u.setStyles(spriteBkg, {
				scale = 0.8,
				x = position_x,
				y = position_y
			})
			spriteBkg:setAnchorPoint(CCPointMake(0, 0.5))
			spriteBkg:setTag(13)

			spriteList[#spriteList + 1] = spriteBkg

			parent:addChild(spriteBkg, -1)

			local bkgScale = spriteBkg:getScale()
			local bkgContentSize = spriteBkg:getContentSize()
			local bkgPosition = spriteBkg:getPositionLua()
			local sprite_checkFrame = CCSprite:create("v2/multi-selectUI/check_frame.png")

			sprite_checkFrame:setScale(bkgScale)
			sprite_checkFrame:setPosition(CCPointMake(bkgPosition.x + scrSize.width * 0.72, bkgPosition.y))
			parent:addChild(sprite_checkFrame, 1)

			if g_guideSelectItem == nil then
				g_guideSelectItem = sprite_checkFrame
			end

			local itemName = d_ms.d_u.createByStyle({
				font = "arial",
				type = "label",
				x = 0.27,
				fontsize = 30,
				string = packageItemsInfo[i].csvInfo.name,
				y = position_y + 0.03
			})

			itemName:setAnchorPoint(CCPointMake(0, 0.5))
			itemName:setColor(ccc3(254, 235, 192))
			parent:addChild(itemName)

			local quality = packageItemsInfo[i].csvInfo.quality

			if quality and quality > 0 then
				local qualityRatio = packageItemsInfo[i].csvInfo.quality / 5
				local starsLevelSprite = CCSprite:create("v2/introUI/stars.png")

				d_ms.d_u.setStyles(starsLevelSprite, {
					x = 0.4,
					y = position_y + 0.03
				})
				starsLevelSprite:setAnchorPoint(CCPointMake(0, 0.5))

				local starsContentSize = starsLevelSprite:getContentSize()

				starsLevelSprite:setTextureRect(CCRectMake(0, 0, starsContentSize.width * qualityRatio, starsContentSize.height))
				parent:addChild(starsLevelSprite)
			end

			local levelSprite = CCSprite:create("v2/packageUI/level.png")

			d_ms.d_u.setStyles(levelSprite, {
				x = 0.27,
				y = position_y - 0.03
			})
			levelSprite:setAnchorPoint(CCPointMake(0, 0.5))
			parent:addChild(levelSprite)

			local level = packageItemsInfo[i].level
			local levelLabel = d_ms.d_u.createByStyle({
				font = "arial",
				type = "label",
				x = 0.315,
				fontsize = 30,
				string = tostring(level),
				y = position_y - 0.03
			})

			parent:addChild(levelLabel)
			levelSprite:setAnchorPoint(CCPointMake(0, 0.5))
			levelLabel:setColor(ccc3(253, 190, 37))

			local powerLabel = nil
			local power = packageItemsInfo[i].effect_value
			local powerLabelPositionX = 0.37

			if packageTag == packageTagDef.weapon then
				local powerSprite = CCSprite:create("v2/packageUI/CHAR_gong.png")

				d_ms.d_u.setStyles(powerSprite, {
					x = powerLabelPositionX,
					y = position_y - 0.03
				})
				parent:addChild(powerSprite)

				powerLabel = d_ms.d_u.createByStyle({
					font = "arial",
					type = "label",
					fontsize = 30,
					string = tostring(power),
					x = powerLabelPositionX + 0.03,
					y = position_y - 0.03
				})

				parent:addChild(powerLabel)
				powerLabel:setAnchorPoint(CCPointMake(0, 0.5))
				powerLabel:setColor(ccc3(253, 190, 37))
			elseif packageTag == packageTagDef.armor then
				local powerSprite = CCSprite:create("v2/packageUI/CHAR_fang.png")

				d_ms.d_u.setStyles(powerSprite, {
					x = powerLabelPositionX,
					y = position_y - 0.03
				})
				parent:addChild(powerSprite)

				powerLabel = d_ms.d_u.createByStyle({
					font = "arial",
					type = "label",
					fontsize = 30,
					string = tostring(power),
					x = powerLabelPositionX + 0.03,
					y = position_y - 0.03
				})

				parent:addChild(powerLabel)
				powerLabel:setAnchorPoint(CCPointMake(0, 0.5))
				powerLabel:setColor(ccc3(253, 190, 37))
			elseif packageTag == packageTagDef.fabao then
				local powerSprite = CCSprite:create("v2/packageUI/CHAR_ming.png")

				d_ms.d_u.setStyles(powerSprite, {
					x = powerLabelPositionX,
					y = position_y - 0.03
				})
				parent:addChild(powerSprite)

				powerLabel = d_ms.d_u.createByStyle({
					font = "arial",
					type = "label",
					fontsize = 30,
					string = tostring(power),
					x = powerLabelPositionX + 0.03,
					y = position_y - 0.03
				})

				parent:addChild(powerLabel)
				powerLabel:setAnchorPoint(CCPointMake(0, 0.5))
				powerLabel:setColor(ccc3(253, 190, 37))
			elseif packageTag == packageTagDef.skill then
				d_ms.d_packageUI.createSkillLabel(parent, packageItemsInfo[i].type_id, {
					x = powerLabelPositionX + 0.03,
					y = position_y - 0.03
				}, packageItemsInfo[i].level)
			end

			if packageItemsInfo[i].equip_order > 0 then
				local ownerIndex = d_ms.d_lineupUI.g_usedCharacters[packageItemsInfo[i].equip_order].index
				local owner = d_ms.d_lineupUI.g_characterInfo[ownerIndex].csvInfo.name
				local hintLabel = d_ms.d_u.createByStyle({
					font = "arial",
					type = "label",
					x = 0.25,
					fontsize = 15,
					string = d_ms.d_hz.gethz("equip") .. owner,
					y = position_y - 0.03
				})

				hintLabel:setAnchorPoint(CCPointMake(0, 0.5))
				hintLabel:setColor(ccc3(186, 170, 157))
				parent:addChild(hintLabel, 10)
			end

			local itemSprite = nil

			if packageItemsInfo[i].attach_type == 6 then
				itemSprite = d_ms.d_data.getSmallSkillSprite(packageItemsInfo[i].type_id)
			else
				itemSprite = d_ms.d_data.getSmallItemSprite(packageItemsInfo[i].type_id)
			end

			local itemSprite = CCMenuItemSprite:create(itemSprite, itemSprite)

			itemSprite:setTag(i)

			local itemHeight = itemSprite:getContentSize().height
			local scaleRatio = bkgContentSize.height * bkgScale / itemHeight

			d_ms.d_u.setStyles(itemSprite, {
				x = position_x + 0.04,
				y = position_y
			})
			itemSprite:setScale(scaleRatio * 0.7)
			itemSprite:setAnchorPoint(CCPointMake(0, 0.5))
			itemSprite:registerScriptTapHandler(introCallBack)
			menuItemArray:addObject(itemSprite)

			order = order + 1
			position_y = position_y - bkgContentSize.height * bkgScale / scrSize.height - 0.02

			cells_view:addCell(parent, {
				width = bkgContentSize.width * bkgScale,
				height = bkgContentSize.height * bkgScale + 0.02 * scrSize.height
			})
		end
	end

	if menuItemArray:count() ~= 0 then
		local menuItem = CCMenu:createWithArray(menuItemArray)

		menuItem:setPosition(CCPointMake(0, 0))
		cells_view.scrollView:addChild(menuItem)
	end

	return spriteList
end

g_addMoreItems_params = {}

function createPackageCellsShort(cells_view, packageTag, introCallBack, filter_callback, packageItemsInfo, isShowAllItems, isCortCall)
	position_x = 0.05
	position_y = 0.56
	local packageItemsInfo = packageItemsInfo or d_ms.d_packageUI.g_packageItemsInfo
	local spriteList = {}
	local packageTagDef = d_ms.d_packageUI.packageTagDef
	g_packageListIndex = 0
	g_addMoreItems_params = {
		cells_view = cells_view,
		packageTag = packageTag,
		introCallBack = introCallBack,
		filter_callback = filter_callback,
		packageItemsInfo = packageItemsInfo,
		isShowAllItems = isShowAllItems,
		spriteList = spriteList,
		packageTagDef = packageTagDef,
		isCortCall = isCortCall
	}

	addMoreItems()
	cells_view:setNearToEndCallBack(addMoreItems, 0.5)

	return spriteList
end

function addMoreItems()
	cclog("call addMoreItems")

	local cells_view = g_addMoreItems_params.cells_view
	local packageTag = g_addMoreItems_params.packageTag
	local introCallBack = g_addMoreItems_params.introCallBack
	local filter_callback = g_addMoreItems_params.filter_callback
	local packageItemsInfo = g_addMoreItems_params.packageItemsInfo
	local isShowAllItems = g_addMoreItems_params.isShowAllItems
	local spriteList = g_addMoreItems_params.spriteList
	local packageTagDef = g_addMoreItems_params.packageTagDef
	local isCortCall = g_addMoreItems_params.isCortCall
	local menuOnCellArray = CCArray:create()
	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local order = 1
	local count = 10

	if packageTag == packageTagDef.props or packageTag == packageTagDef.cortege then
		count = 512
	end

	for i = g_packageListIndex + 1, #packageItemsInfo do
		g_packageListIndex = g_packageListIndex + 1
		local isItemShow = true

		if isShowAllItems ~= nil and isShowAllItems == true then
			packageTag = packageItemsInfo[i].csvInfo.packageTag
		elseif packageItemsInfo[i].csvInfo.packageTag ~= packageTag then
			isItemShow = false

			if packageTag == packageTagDef.cortege then
				isItemShow = true
			end
		end

		if isItemShow and filter_callback ~= nil and filter_callback(i) == true then
			isItemShow = false
		end

		if isItemShow then
			if count > 0 then
				count = count - 1
			else
				g_packageListIndex = g_packageListIndex - 1

				break
			end

			local parent = CCLayer:create()

			parent:setTag(i)

			local menuItemArray = CCArray:create()
			local spriteBkg = CCSprite:create("v2/charPositionUI/item_bkg.png")

			d_ms.d_u.setStyles(spriteBkg, {
				scaleX = 0.5,
				x = position_x,
				y = position_y
			})
			spriteBkg:setAnchorPoint(CCPointMake(0, 0.5))
			spriteBkg:setTag(13)

			spriteList[#spriteList + 1] = spriteBkg

			parent:addChild(spriteBkg, -1)

			local bkgScale = 1
			local bkgContentSize = spriteBkg:getContentSize()
			local bkgPosition = spriteBkg:getPositionLua()
			local sprite_checkFrame = CCSprite:create("v2/multi-selectUI/check_frame.png")

			sprite_checkFrame:setScale(bkgScale)
			sprite_checkFrame:setPosition(CCPointMake(bkgPosition.x + scrSize.width * 0.45, bkgPosition.y))
			parent:addChild(sprite_checkFrame, 1)

			if g_guideSelectItem == nil then
				g_guideSelectItem = sprite_checkFrame
			end

			local itemNameStr = packageItemsInfo[i].csvInfo.name
			local quality = packageItemsInfo[i].csvInfo.quality

			if quality and quality > 0 then
				local qualityRatio = packageItemsInfo[i].csvInfo.quality / 5
				local starsLevelSprite = CCSprite:create("v2/introUI/stars.png")

				d_ms.d_u.setStyles(starsLevelSprite, {
					x = 0.3,
					y = position_y + 0.03
				})
				starsLevelSprite:setAnchorPoint(CCPointMake(0, 0.5))

				local starsContentSize = starsLevelSprite:getContentSize()

				starsLevelSprite:setTextureRect(CCRectMake(0, 0, starsContentSize.width * qualityRatio, starsContentSize.height))
				parent:addChild(starsLevelSprite)
			end

			if packageTag ~= packageTagDef.fabao then
				local levelSprite = CCSprite:create("v2/packageUI/level.png")

				d_ms.d_u.setStyles(levelSprite, {
					x = 0.17,
					y = position_y - 0.03
				})
				levelSprite:setAnchorPoint(CCPointMake(0, 0.5))
				parent:addChild(levelSprite)

				local level = packageItemsInfo[i].level
				local levelLabel = d_ms.d_u.createByStyle({
					font = "arial",
					type = "label",
					x = 0.213,
					fontsize = 30,
					string = tostring(level),
					y = position_y - 0.03,
					anchor = {
						0,
						0.5
					}
				})

				parent:addChild(levelLabel)
				levelSprite:setAnchorPoint(CCPointMake(0, 0.5))
				levelLabel:setColor(ccc3(253, 190, 37))
			end

			local powerLabel = nil
			local power = packageItemsInfo[i].effect_value
			local powerLabelPositionX = 0.23

			if packageTag == packageTagDef.weapon then
				local powerSprite = CCSprite:create("v2/packageUI/CHAR_gong.png")

				d_ms.d_u.setStyles(powerSprite, {
					x = powerLabelPositionX,
					y = position_y - 0.03
				})
				parent:addChild(powerSprite)

				powerLabel = d_ms.d_u.createByStyle({
					font = "arial",
					type = "label",
					fontsize = 30,
					string = tostring(power),
					x = powerLabelPositionX + 0.03,
					y = position_y - 0.03
				})

				parent:addChild(powerLabel)
				powerLabel:setAnchorPoint(CCPointMake(0, 0.5))
				powerLabel:setColor(ccc3(253, 190, 37))
			elseif packageTag == packageTagDef.armor then
				local powerSprite = CCSprite:create("v2/packageUI/CHAR_fang.png")

				d_ms.d_u.setStyles(powerSprite, {
					x = powerLabelPositionX,
					y = position_y - 0.03
				})
				parent:addChild(powerSprite)

				powerLabel = d_ms.d_u.createByStyle({
					font = "arial",
					type = "label",
					fontsize = 30,
					string = tostring(power),
					x = powerLabelPositionX + 0.03,
					y = position_y - 0.03
				})

				parent:addChild(powerLabel)
				powerLabel:setAnchorPoint(CCPointMake(0, 0.5))
				powerLabel:setColor(ccc3(253, 190, 37))
			elseif packageTag == packageTagDef.fabao then
				local powerSprite = CCSprite:create("v2/packageUI/CHAR_ming.png")

				d_ms.d_u.setStyles(powerSprite, {
					x = powerLabelPositionX,
					y = position_y - 0.03
				})
				parent:addChild(powerSprite)

				powerLabel = d_ms.d_u.createByStyle({
					font = "arial",
					type = "label",
					fontsize = 30,
					string = tostring(power),
					x = powerLabelPositionX + 0.03,
					y = position_y - 0.03
				})

				parent:addChild(powerLabel)
				powerLabel:setAnchorPoint(CCPointMake(0, 0.5))
				powerLabel:setColor(ccc3(253, 190, 37))
			elseif packageTag == packageTagDef.skill then
				d_ms.d_packageUI.createSkillLabel(parent, packageItemsInfo[i].type_id, d_ms.d_u.makePoint(powerLabelPositionX + 0.03, position_y - 0.03), packageItemsInfo[i].level)

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

				d_ms.d_u.setStyles(typeSprite, {
					x = powerLabelPositionX + 0.12,
					y = position_y - 0.03
				})
				parent:addChild(typeSprite)
			end

			if packageItemsInfo[i].equip_order and packageItemsInfo[i].equip_order > 0 then
				local ownerIndex = d_ms.d_lineupUI.g_usedCharacters[packageItemsInfo[i].equip_order].index
				local owner = d_ms.d_lineupUI.g_characterInfo[ownerIndex].csvInfo.name
				local hintLabel = d_ms.d_u.createByStyle({
					font = "arial",
					type = "label",
					x = 0.25,
					fontsize = 15,
					string = d_ms.d_hz.gethz("equip") .. owner,
					y = position_y - 0.03
				})

				hintLabel:setAnchorPoint(CCPointMake(0, 0.5))
				hintLabel:setColor(ccc3(186, 170, 157))
				parent:addChild(hintLabel, 10)
			end

			local itemSprite = nil

			if packageItemsInfo[i].attach_type and packageItemsInfo[i].attach_type == 6 then
				itemSprite = d_ms.d_data.getSmallSkillSprite(packageItemsInfo[i].type_id)
			elseif packageItemsInfo[i].type and packageItemsInfo[i].cur_exp then
				itemSprite = d_ms.d_data.getHeadSprite(packageItemsInfo[i].type, g_AscTable[packageItemsInfo[i].type])
				itemNameStr = d_ms.d_data.getNameTxt(packageItemsInfo[i].type, g_AscTable[packageItemsInfo[i].type])

				if isCortCall == true and d_ms.d_data.getCortCallById(packageItemsInfo[i].type) == nil then
					local cortLabel = d_ms.d_u.createByStyle({
						font = "arial",
						type = "label",
						x = 0.34,
						fontsize = 26,
						color = {
							211,
							168,
							86
						},
						string = d_ms.d_hz.gethz("cortCallNoCort"),
						y = position_y - 0.03
					})

					parent:addChild(cortLabel, 11)
				end
			else
				itemSprite = d_ms.d_data.getSmallItemSprite(packageItemsInfo[i].type_id)
			end

			local itemName = d_ms.d_u.createByStyle({
				font = "arial",
				type = "label",
				x = 0.17,
				fontsize = 30,
				string = itemNameStr,
				y = position_y + 0.03
			})

			itemName:setAnchorPoint(CCPointMake(0, 0.5))
			itemName:setColor(ccc3(254, 235, 192))
			parent:addChild(itemName)

			local itemSprite = CCMenuItemSprite:create(itemSprite, itemSprite)

			itemSprite:setTag(i)

			local itemHeight = itemSprite:getContentSize().height
			local scaleRatio = bkgContentSize.height * bkgScale / itemHeight

			d_ms.d_u.setStyles(itemSprite, {
				x = position_x + 0.01,
				y = position_y
			})
			itemSprite:setScale(scaleRatio * 0.9)
			itemSprite:setAnchorPoint(CCPointMake(0, 0.5))
			itemSprite:registerScriptTapHandler(introCallBack)
			menuItemArray:addObject(itemSprite)

			order = order + 1
			position_y = position_y - bkgContentSize.height * bkgScale / scrSize.height - 0.02

			if menuItemArray:count() ~= 0 then
				local menuItem = CCMenu:createWithArray(menuItemArray)

				menuItem:setPosition(CCPointMake(0, 0))
				parent:addChild(menuItem)
			end

			cells_view:addCell(parent, {
				width = bkgContentSize.width * bkgScale,
				height = bkgContentSize.height * bkgScale + 0.02 * scrSize.height
			})
		end
	end
end

function getProtogenicSkill(char_id)
	local skillData = d_ms.d_packageUI.g_reorgItemsInfo[o_t.skill] or {}

	for k, v in pairs(skillData) do
		if v.protogenic ~= 0 and v.owner_id > 0 then
			return v
		end
	end
end
