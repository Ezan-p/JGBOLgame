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
local package = package
local main_server = main_server
local _G = _G
local bits = bits
local tonumber = tonumber
local os = os
local io = io
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
local ccc4 = ccc4
local ccc3 = ccc3
local CCMenuItemSprite = CCMenuItemSprite
local CCMenuItemImage = CCMenuItemImage
local CCRectMake = CCRectMake
local CCPointMake = CCPointMake
local ccpAdd = ccpAdd
local CCMoveBy = CCMoveBy
local CCMenuItemFont = CCMenuItemFont
local kCCMenuHandlerPriority = kCCMenuHandlerPriority
local CCSequence = CCSequence
local CCCallFuncN = CCCallFuncN
local CCDelayTime = CCDelayTime
local CCEaseOut = CCEaseOut
local CCSpawn = CCSpawn
local CCEaseInOut = CCEaseInOut
local CCEaseElasticInOut = CCEaseElasticInOut
local CCLuaLog = CCLuaLog
local CCFileUtils = CCFileUtils
local CCVerticalTextAlignment = CCVerticalTextAlignment
local CCMoveTo = CCMoveTo
local CCEaseElasticOut = CCEaseElasticOut
local CCEaseElastic = CCEaseElastic
local CCEaseBounce = CCEaseBounce
local CCEaseBounceInOut = CCEaseBounceInOut
local CCEaseBounceOut = CCEaseBounceOut
local CCEaseBackInOut = CCEaseBackInOut
local CCSizeMake = CCSizeMake
local CCScrollView = CCScrollView
local CCTargetedAction = CCTargetedAction
local CCNode = CCNode
local CCLabelTTF = CCLabelTTF
local kCCTextAlignmentLeft = kCCTextAlignmentLeft
local CCFadeOut = CCFadeOut
local ccp = ccp

module("ui.packageUI")

d_ms = require("ms")

if not d_ms then
	print("packageUI load d_ms fail.\n")
end

local function cclog(...)
	CCLuaLog(string.format(...))
end

local scrSize = CCDirector:sharedDirector():getVisibleSize()
local o_t = d_ms.d_common_def.object_type
local m_t = d_ms.d_common_def.item_main_type
local gethz = d_ms.d_hz.gethz
g_packageUI = {}
g_usedItems = {
	{},
	{},
	{},
	{},
	{},
	{},
	{},
	{}
}
g_cheer_items = {
	{},
	{},
	{},
	{},
	{},
	{},
	{},
	{},
	{},
	{},
	{},
	{},
	{},
	{},
	{},
	{}
}
g_itemAttrTable = nil
g_itemSkillTable = nil
g_itemButton = {}
g_lastSelectedItemButton = 0
g_introButtonType = {
	enhanceSkill = 5,
	advance = 8,
	asc = 10,
	cast = 11,
	stoneUpgrade = 6,
	close = -1,
	enhance = 4,
	none = 0,
	slot = 7,
	sale = 2,
	handbook = 9,
	choose = 3,
	change = 1
}
g_packageItemsInfo = nil
g_reorgItemsInfo = {
	[o_t.item] = {},
	[o_t.skill] = {}
}
g_propsTable = {}
packageTagDef = {
	weapon = 1,
	stone = 5,
	props = 6,
	cortege = 7,
	fabao = 3,
	invisible = 8,
	none = 0,
	armor = 2,
	skill = 4
}
tagDef = {
	packageLayerTag = 300008,
	cellsLayer = 3
}
g_isPackageSorted = false
g_updatePackageFunc = {}
g_isInPackage = false
g_lastRequestUsedItem = {}
g_Color = {
	black = {
		0,
		0,
		0
	},
	white = {
		255,
		255,
		255
	},
	green = {
		0,
		255,
		0
	},
	red = {
		255,
		0,
		0
	},
	yellow = {
		255,
		255,
		0
	},
	gray = {
		230,
		230,
		230
	}
}

function show()
	cclog("show Package")
	d_ms.d_tianShuUI.showHint()
	create(d_ms.d_mainUI.g_mainUI.main_layer)
	d_ms.d_mainUI.g_mainUI.player_layer:setVisible(false)

	if d_ms.d_mainUI.g_mainUI.menu_other_layer ~= nil then
		d_ms.d_mainUI.g_mainUI.main_layer:removeChild(dMainUI.g_mainUI.menu_other_layer, true)

		d_ms.d_mainUI.g_mainUI.menu_other_layer = nil
	end
end

function create(parent)
	local childBoard = parent:getChildByTag(d_ms.d_mainUI.boardID.package)

	if childBoard then
		return
	end

	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	g_packageUI = {}
	local main_layer = parent
	local board_layer = CCLayer:create()

	parent:addChild(board_layer, 5)

	d_ms.d_mainUI.g_boardlayer[d_ms.d_mainUI.boardID.package] = board_layer

	board_layer:setTag(d_ms.d_mainUI.boardID.package)

	g_isInPackage = true

	local function sceneEventHandler(eventType)
		if eventType.name == "exit" then
			g_updatePackageFunc = {}
			g_isInPackage = false
			g_lastSelectedItemButton = 0
			g_lastRequestUsedItem = {}
			g_packageTag = packageTagDef.none
		end
	end

	board_layer:registerScriptHandler(sceneEventHandler)
	d_ms.d_mainUI.showBoard(board_layer)

	d_ms.d_mainUI.g_currentBoard = d_ms.d_mainUI.boardID.package
	g_packageUI.board_layer = board_layer
	g_packageUI.parent = parent
	local position = {
		x = 0.5,
		y = 0.56
	}
	local scaleXY = {
		scaleY = 0.8,
		scaleX = 0.95
	}
	g_packageUI.board_size = d_ms.d_mainUI.createBoardBkg(board_layer, position, scaleXY, false)
	local item_menu_list = {
		{
			npic = "v2/packageUI/Label_weapon1.png",
			scale = 0.18,
			disPic = "v2/packageUI/Label_weapon2.png",
			x = 0,
			y = -0.11 * 0,
			tag = packageTagDef.weapon,
			call_back = showPackage
		},
		{
			npic = "v2/packageUI/Label_armor1.png",
			scale = 0.18,
			disPic = "v2/packageUI/Label_armor2.png",
			y = -0.11,
			x = 0,
			tag = packageTagDef.armor,
			call_back = showPackage
		},
		{
			npic = "v2/packageUI/Label_magic-item1.png",
			scale = 0.18,
			disPic = "v2/packageUI/Label_magic-item2.png",
			y = -0.22,
			x = 0,
			tag = packageTagDef.fabao,
			call_back = showPackage
		},
		{
			npic = "v2/packageUI/Label_spell1.png",
			scale = 0.18,
			disPic = "v2/packageUI/Label_spell2.png",
			y = -0.33,
			x = 0,
			tag = packageTagDef.skill,
			call_back = showPackage
		},
		{
			npic = "v2/packageUI/stone1.png",
			scale = 0.18,
			disPic = "v2/packageUI/stone2.png",
			y = -0.44,
			x = 0,
			tag = packageTagDef.stone,
			call_back = showPackage
		},
		{
			npic = "v2/packageUI/Label_props1.png",
			scale = 0.18,
			disPic = "v2/packageUI/Label_props2.png",
			y = -0.55,
			x = 0,
			tag = packageTagDef.props,
			call_back = showPackage
		},
		{
			npic = "v2/smithUI/smith1.png",
			scale = 0.12,
			disPic = "v2/smithUI/smith2.png",
			y = -0.66,
			x = 0,
			call_back = pressSmith
		},
		x = 0.12,
		y = 0.88
	}

	if not d_ms.d_stoneUI.g_self.isOpen then
		for i = 6, 7 do
			item_menu_list[i].y = item_menu_list[i].y + 0.11
		end
	end

	g_itemButton = {}

	board_layer:addChild(d_ms.d_u.createMenu(item_menu_list, g_itemButton, true), 5)

	if not d_ms.d_stoneUI.g_self.isOpen then
		g_itemButton[5]:setVisible(false)
		g_itemButton[5]:setEnabled(false)
	end

	g_lastSelectedItemButton = 0

	showPackage(packageTagDef.weapon)
end

function pressSmith()
	d_ms.d_smithUI.show()
end

function pressHandBook(object_type)
	d_ms.d_handbookUI.g_self.ready_open_tag = object_type

	d_ms.d_other_functionUI.menuHandbookCallback(object_type)
end

local noUseBtnProps = {
	1001,
	1006,
	1007,
	1024,
	1008,
	1009,
	1010,
	1035,
	1011,
	1012,
	1013,
	1004,
	1026,
	1027,
	1028,
	1015,
	1030,
	1315,
	1016,
	1017,
	1219,
	1332,
	1336,
	1329,
	1334,
	1335,
	1337,
	1333,
	10000,
	1343,
	{
		1310,
		1314
	},
	{
		1320,
		1323
	},
	{
		1208,
		1212
	},
	{
		1113,
		1117
	},
	{
		1338,
		1341
	},
	{
		1134,
		1138
	},
	1807,
	1140,
	1366,
	10300,
	1345,
	{
		1347,
		1349
	},
	{
		1141,
		1143
	},
	{
		1350,
		1356
	},
	{
		1361,
		1362
	},
	{
		1364,
		1365
	}
}

local function hasBtn(propId)
	for _, v in pairs(noUseBtnProps) do
		if type(v) == "table" then
			if v[1] <= propId and propId <= v[2] then
				return false
			end
		elseif v == propId then
			return false
		end
	end

	return true
end

function checkEquipmentCanFenjie(info)
	local owner = nil

	if info.equip_order and info.equip_order > 0 then
		if info.equip_order <= 8 then
			owner = d_ms.d_data.getMyCortName(d_ms.d_lineupUI.g_usedCharacters[info.equip_order].character.type)
		else
			owner = d_ms.d_data.getMyCortName(d_ms.d_lineupUI.g_cheerCharacters[info.equip_order - 8].character.type)
		end
	elseif info.csvInfo.mainType == m_t.stone and info.owner_id and info.owner_id > 0 then
		owner = d_ms.d_stoneUI.getOwnerNameByID(info.owner_id, info.csvInfo.sub_type)
	end

	if not owner and info.level and info.level >= 2 and info.csvInfo and info.csvInfo.quality >= 5 and info.csvInfo.skillType ~= 1 and info.protogenic ~= 1 then
		return true
	end

	return false
end

local function createCellOnPackage(parent, packageTag, itemInfo, bkgPic, cellSize)
	d_ms.d_createCell.createCellWithOwner(parent, itemInfo, bkgPic, cellSize)

	local menuOnCellArray = CCArray:create()
	local menuItemsDefs = {
		priority = -126,
		usedDefaultRect = true
	}

	if packageTag == packageTagDef.props then
		local function useItem()
			requestUseItem(itemInfo)
		end

		local transInfo = d_ms.d_data.getTransInfoByTypeid(itemInfo.type_id, true)

		if transInfo then
			local function gotoForge(tag)
				if d_ms.d_mainUI.g_playerInfo.level < transInfo[tag].min_role_level then
					d_ms.d_info.show(string.format(d_ms.d_hz.gethz("stone_lv_limit"), transInfo[tag].min_role_level), 2)
				else
					d_ms.d_smithUI.show(transInfo[tag])
				end
			end

			menuItemsDefs.menuItems = {}
			local btn_x = cellSize.width * 0.85

			if transInfo[2] then
				table.insert(menuItemsDefs.menuItems, {
					spic = "v2/transformUI/btn12.png",
					tag = 2,
					npic = "v2/transformUI/btn11.png",
					isGray = d_ms.d_mainUI.g_playerInfo.level < transInfo[2].min_role_level,
					tapHandler = gotoForge,
					pos = ccp(btn_x, cellSize.height * 0.3)
				})

				btn_x = btn_x - cellSize.width * 0.21
			end

			if transInfo[1] then
				table.insert(menuItemsDefs.menuItems, {
					spic = "v2/transformUI/btn02.png",
					tag = 1,
					npic = "v2/transformUI/btn01.png",
					isGray = d_ms.d_mainUI.g_playerInfo.level < transInfo[1].min_role_level,
					tapHandler = gotoForge,
					pos = ccp(btn_x, cellSize.height * 0.3)
				})
			end
		elseif hasBtn(itemInfo.type_id) then
			menuItemsDefs.menuItems = {
				{
					npic = "v2/packageUI/use1.png",
					spic = "v2/packageUI/use2.png",
					tapHandler = useItem,
					pos = ccp(cellSize.width * 0.85, cellSize.height * 0.3)
				}
			}

			if d_ms.d_treasureMapUI.isJiuYouBaoTu(itemInfo.type_id) then
				local sprite1 = CCSprite:create("v2/packageUI/piliangshiyong1.png")
				local sprite2 = CCSprite:create("v2/packageUI/piliangshiyong2.png")

				if itemInfo.count < 10 then
					sprite1:setMaskEff("v2/gray.shader")
					sprite2:setMaskEff("v2/gray.shader")
				end

				local function useJiuYouBaoTu()
					if itemInfo.count >= 10 then
						local defs = {
							min = 1,
							max = math.min(15, itemInfo.count),
							itemType = itemInfo.type_id
						}

						d_ms.d_treasureMapUI.createBatchUse(d_ms.d_mainUI.g_mainUI.main_layer, defs, sendUseItemRequest)
					else
						d_ms.d_info.show(d_ms.d_hz.gethz("treasureMap_info5"))
					end
				end

				menuItemsDefs.menuItems[2] = {
					nSprite = sprite1,
					sSprite = sprite2,
					tapHandler = useJiuYouBaoTu,
					pos = ccp(cellSize.width * 0.6, cellSize.height * 0.3)
				}
			end
		end

		if d_ms.d_data.g_ep_price[itemInfo.type_id] then
			local function saleItem()
				d_ms.d_data.createBatchSale(d_ms.d_mainUI.g_mainUI.main_layer, itemInfo.type_id, itemInfo.count)
			end

			local saleBtn = {
				npic = "v2/batchBuyUI/sale1.png",
				spic = "v2/batchBuyUI/sale2.png",
				tapHandler = saleItem
			}

			if menuItemsDefs.menuItems then
				saleBtn.pos = ccp(cellSize.width * 0.63, cellSize.height * 0.3)

				table.insert(menuItemsDefs.menuItems, saleBtn)
			else
				saleBtn.pos = ccp(cellSize.width * 0.85, cellSize.height * 0.3)
				menuItemsDefs.menuItems = {
					saleBtn
				}
			end
		end
	elseif packageTag == packageTagDef.skill then
		function pressSkillUpgrade()
			local params = {
				skill_info = itemInfo,
				from_btn = 1
			}

			d_ms.d_skillUpgradeUI.show(params, 1)
		end

		function pressFenjie()
			d_ms.d_smithUI.showFenjie(itemInfo)
		end

		local canShowFenjie = checkEquipmentCanFenjie(itemInfo)

		if canShowFenjie then
			menuItemsDefs.menuItems = {
				{
					npic = "v2/enhanceUI/up1.png",
					spic = "v2/enhanceUI/up2.png",
					tapHandler = pressSkillUpgrade,
					pos = ccp(cellSize.width * 0.85, cellSize.height * 0.27)
				},
				{
					npic = "v2/smithUI/btn_rollback1.png",
					spic = "v2/smithUI/btn_rollback2.png",
					tapHandler = pressFenjie,
					pos = ccp(cellSize.width * 0.85, cellSize.height * 0.71)
				}
			}
		else
			menuItemsDefs.menuItems = {
				{
					npic = "v2/enhanceUI/up1.png",
					spic = "v2/enhanceUI/up2.png",
					tapHandler = pressSkillUpgrade,
					pos = ccp(cellSize.width * 0.85, cellSize.height * 0.27)
				}
			}
		end
	elseif packageTag == packageTagDef.stone then
		function pressStoneUpgrade()
			if d_ms.d_stoneUpgradeUI.canUpgrade(itemInfo, true) then
				d_ms.d_stoneUpgradeUI.show(d_ms.d_mainUI.g_mainUI.main_layer, 40, itemInfo)
			end
		end

		local function pressStoneAsc()
			d_ms.d_stoneCastUI.pressCast(d_ms.d_mainUI.g_mainUI.main_layer, itemInfo)
		end

		local sprite1 = CCSprite:create("v2/enhanceUI/up1.png")
		local sprite2 = CCSprite:create("v2/enhanceUI/up2.png")
		local stone_tapHandler = pressStoneUpgrade

		if not d_ms.d_stoneUpgradeUI.canUpgrade(itemInfo, false) then
			sprite1:setMaskEff("v2/gray.shader")
			sprite2:setMaskEff("v2/gray.shader")
		end

		if itemInfo.level and itemInfo.level >= 10 and itemInfo.level < 11 then
			sprite1 = CCSprite:create("v2/stoneCastUI/s_asc1.png")
			sprite2 = CCSprite:create("v2/stoneCastUI/s_asc2.png")
			stone_tapHandler = pressStoneAsc
		elseif itemInfo.level and itemInfo.level >= 11 then
			sprite1 = CCSprite:create("v2/stoneCastUI/lingshitilian1.png")
			sprite2 = CCSprite:create("v2/stoneCastUI/lingshitilian2.png")
			stone_tapHandler = pressStoneAsc

			if itemInfo.level > 12 then
				sprite1:setMaskEff("v2/gray.shader")
				sprite2:setMaskEff("v2/gray.shader")
			end
		end

		menuItemsDefs.menuItems = {
			{
				nSprite = sprite1,
				sSprite = sprite2,
				tapHandler = stone_tapHandler,
				pos = ccp(cellSize.width * 0.85, cellSize.height * 0.3)
			}
		}
	else
		function equipmentUpgrade()
			local tmp_tab = itemInfo

			if d_ms.d_equipmentUpgradeUI.checkEquipmentCanUpgrade(true, itemInfo.level, itemInfo.csvInfo.quality, itemInfo.reborn_bit) == 2 then
				return
			end

			d_ms.d_equipmentUpgradeUI.showEnhanceLayer(d_ms.d_mainUI.g_mainUI.main_layer, tmp_tab, 40)
		end

		function equipSlot()
			if d_ms.d_stoneUI.canJoin(true) then
				d_ms.d_stoneUI.showStoneLayer(g_packageUI.parent, 40, itemInfo)
			end
		end

		local sprite1 = CCSprite:create("v2/packageUI/enhance1.png")
		local sprite2 = CCSprite:create("v2/packageUI/enhance2.png")

		if d_ms.d_equipmentUpgradeUI.checkEquipmentCanUpgrade(false, itemInfo.level, itemInfo.csvInfo.quality, itemInfo.reborn_bit) == 2 then
			sprite1:setMaskEff("v2/gray.shader")
			sprite2:setMaskEff("v2/gray.shader")
		end

		local sprite3 = CCSprite:create("v2/stoneUI/putin_btn1.png")
		local sprite4 = CCSprite:create("v2/stoneUI/putin_btn2.png")
		menuItemsDefs.menuItems = {
			{
				nSprite = sprite1,
				sSprite = sprite2,
				tapHandler = equipmentUpgrade,
				pos = ccp(cellSize.width * 0.85, cellSize.height * 0.3)
			},
			{
				nSprite = sprite3,
				sSprite = sprite4,
				tapHandler = equipSlot,
				pos = ccp(cellSize.width * 0.65, cellSize.height * 0.3)
			}
		}
	end

	if menuItemsDefs.menuItems then
		local menuLayer = d_ms.d_tableView.createTableViewMenu(menuItemsDefs)

		parent:addChild(menuLayer)
	end

	return

	local count = menuOnCellArray:count()

	if count > 0 then
		local space = 0.2 * cellSize.width

		for i = 1, count do
			local menu = tolua.cast(menuOnCellArray:objectAtIndex(i - 1), "CCMenuItemImage")

			menu:setPosition(cellSize.width * 0.85 - space * (i - 1), cellSize.height * 0.3)
		end

		local menu = CCMenu:createWithArray(menuOnCellArray)

		menu:setPosition(0, 0)
		parent:addChild(menu)

		local function setPosMenuPriority()
			menu:setHandlerPriority(-126)
		end

		d_ms.d_u.delay(menu, 0.1, setPosMenuPriority)
	end
end

local currentPackageDataTable = {}

local function createBatchSaleLayer()
	local currentPackageItems = currentPackageDataTable.currentPackageItems

	if not currentPackageItems then
		return
	end

	d_ms.d_batchSaleUI.show(currentPackageItems)
end

local function showAdvance()
	if not d_ms.d_equipAdvanceUI.canJoin(true) then
		return
	end

	d_ms.d_equipAdvanceUI.showAdvanceLayer(g_packageUI.parent, 20)
end

local function createHeaderMenu(parent, packageTag, cellSize)
	local menuArray = CCArray:create()

	if packageTag <= packageTagDef.fabao then
		local batchSaleItem = CCMenuItemImage:create("v2/packageUI/piliangchushou1.png", "v2/packageUI/piliangchushou2.png")

		batchSaleItem:registerScriptTapHandler(createBatchSaleLayer)
		batchSaleItem:setPosition(cellSize.width * 0.2, cellSize.height * 0.5)
		menuArray:addObject(batchSaleItem)

		if d_ms.d_equipAdvanceUI.canJoin() then
			local advanceItem = CCMenuItemImage:create("v2/equipAdvanceUI/menu_ad1.png", "v2/equipAdvanceUI/menu_ad2.png")

			advanceItem:registerScriptTapHandler(showAdvance)
			advanceItem:setPosition(cellSize.width * 0.8, cellSize.height * 0.5)
			menuArray:addObject(advanceItem)
		end
	end

	local function createFilterLayer()
		d_ms.d_filterLayer.show(CCDirector:sharedDirector():getRunningScene(), 100, d_ms.d_filterLayer.TAG.Equip_All, ensureFilter, currentPackageDataTable.currentFilter)
	end

	local filter = CCMenuItemImage:create("v2/buttons/filter21.png", "v2/buttons/filter22.png")

	filter:registerScriptTapHandler(createFilterLayer)
	filter:setPosition(cellSize.width * 0.6, cellSize.height * 0.5)
	menuArray:addObject(filter)

	local menu = CCMenu:createWithArray(menuArray)

	menu:setPosition(CCPointMake(0, 0))
	parent:addChild(menu)

	local function setPosMenuPriority()
		menu:setHandlerPriority(-126)
	end
end

local headerMenuSize = d_ms.d_u.ccSizeMake(0.7, 0.1)

local function getPackageCellsDataSource(packageItemsInfo)
	local packageTag = currentPackageDataTable.packageTag
	local cellSize = CCSizeMake(0.7 * scrSize.width, 0.21 * scrSize.height)
	local bkgPic = "v2/packageUI/xinxilan.png"
	local dataSource = {}
	local num = #packageItemsInfo

	function dataSource.tableViewNumberOfRows()
		if packageTag ~= packageTagDef.props and packageTag ~= packageTagDef.stone then
			return num + 1
		else
			return num
		end
	end

	currentPackageDataTable.currentShowItems = packageItemsInfo

	function dataSource.drawCellAtIndex(index)
		local cell = CCNode:create()

		if packageTag ~= packageTagDef.props and packageTag ~= packageTagDef.stone then
			if index == 1 then
				createHeaderMenu(cell, packageTag, headerMenuSize)
			elseif packageItemsInfo[index - 1] then
				createCellOnPackage(cell, packageTag, packageItemsInfo[index - 1], bkgPic, cellSize)
			end
		elseif packageItemsInfo[index] then
			createCellOnPackage(cell, packageTag, packageItemsInfo[index], bkgPic, cellSize)
		end

		return cell
	end

	function dataSource.heightForRowAtIndex(index)
		if index == 1 and packageTag ~= packageTagDef.props and packageTag ~= packageTagDef.stone then
			return headerMenuSize.height
		else
			return cellSize.height
		end
	end

	return dataSource
end

function ensureFilter(filter)
	local packageTableView = currentPackageDataTable.packageTableView

	if not packageTableView then
		return
	end

	local check = d_ms.d_filterLayer.check
	currentPackageDataTable.currentFilter = filter
	local currentPackageItems = currentPackageDataTable.currentPackageItems
	local afterFilterItems = {}

	for i = 1, #currentPackageItems do
		if check and check(currentPackageItems[i], filter) then
			afterFilterItems[#afterFilterItems + 1] = currentPackageItems[i]
		end
	end

	local dataSource = getPackageCellsDataSource(afterFilterItems)

	packageTableView:reloadData(dataSource)
end

local function getItemsByPackageTag(packageTag)
	if not g_isPackageSorted then
		sortItems()
	end

	local packageItemsInfo = g_packageItemsInfo

	if packageTag == packageTagDef.weapon then
		packageItemsInfo = g_reorgItemsInfo[o_t.item][m_t.weapon]
	elseif packageTag == packageTagDef.armor then
		packageItemsInfo = g_reorgItemsInfo[o_t.item][m_t.guard]
	elseif packageTag == packageTagDef.fabao then
		packageItemsInfo = g_reorgItemsInfo[o_t.item][m_t.talismans]
	elseif packageTag == packageTagDef.skill then
		packageItemsInfo = g_reorgItemsInfo[o_t.skill] or {}
		local count = #packageItemsInfo

		for i = count, 1, -1 do
			if packageItemsInfo[i].protogenic ~= 0 then
				table.remove(packageItemsInfo, i)
			end
		end
	elseif packageTag == packageTagDef.props then
		getAllProps()

		packageItemsInfo = g_propsTable
	elseif packageTag == packageTagDef.stone then
		packageItemsInfo = g_reorgItemsInfo[o_t.item][m_t.stone]
	end

	packageItemsInfo = packageItemsInfo or {}

	return packageItemsInfo
end

function showPackage(packageTag)
	cclog("show package, packageTag: %d", packageTag)

	if g_lastSelectedItemButton ~= 0 then
		g_itemButton[g_lastSelectedItemButton]:setEnabled(true)
	end

	g_itemButton[packageTag]:setEnabled(false)

	g_lastSelectedItemButton = packageTag
	local packageLayerTag = tagDef.packageLayerTag
	local packageLayer = g_packageUI.board_layer:getChildByTag(packageLayerTag)

	if not packageLayer then
		packageLayer = CCLayer:create()

		g_packageUI.board_layer:addChild(packageLayer)
		packageLayer:setTag(packageLayerTag)
	end

	packageLayer:removeAllChildrenWithCleanup(true)

	local function sceneEventHandler(eventType)
		if eventType.name == "exit" then
			currentPackageDataTable = {}
		end
	end

	packageLayer:registerScriptHandler(sceneEventHandler)

	currentPackageDataTable.packageTag = packageTag
	packageItemsInfo = getItemsByPackageTag(packageTag)
	currentPackageDataTable.currentPackageItems = packageItemsInfo

	if #packageItemsInfo <= 0 then
		return
	end

	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local board_size = g_packageUI.board_size
	local touchArea = {
		x = scrSize.width * 0.24,
		y = board_size.y,
		width = scrSize.width * 0.7,
		height = board_size.height * 0.97
	}
	local packageTableView = d_ms.d_tableView.tableView(packageLayer, touchArea)
	currentPackageDataTable.packageTableView = packageTableView
	local dataSource = getPackageCellsDataSource(packageItemsInfo)

	packageTableView:startScroll()
	packageTableView:setDataSource(dataSource)
end

function updateItemCellInfo(type_id)
	local packageTableView = currentPackageDataTable.packageTableView

	if not packageTableView then
		return
	end

	local packageTag = currentPackageDataTable.packageTag

	if not packageTag or packageTag ~= packageTagDef.props then
		return
	end

	local item = nil

	getAllProps()

	for k, v in pairs(g_propsTable) do
		if v.type_id == type_id then
			item = v

			break
		end
	end

	if not item then
		refreshPackage()

		return
	end

	local currentShowItems = currentPackageDataTable.currentShowItems

	if not currentShowItems then
		return
	end

	local updateIndex = nil

	for i = 1, #currentShowItems do
		if currentShowItems[i].id == item.id and currentShowItems[i].type_id == item.type_id then
			updateIndex = i

			break
		end
	end

	if updateIndex then
		packageTableView:updateCellAtIndex(updateIndex)
	end
end

function addNewPropsToPackage(itemInfo)
	if g_isInPackage and g_packageTag == packageTagDef.props then
		local type_id = itemInfo.type_id
		local object_type = itemInfo.attach_type

		if object_type ~= o_t.item then
			return
		end

		local csvInfo = g_itemAttrTable[type_id]

		if not csvInfo or not csvInfo.mainType then
			return
		end

		if csvInfo.mainType <= m_t.talismans then
			return
		end

		local scrSize = CCDirector:sharedDirector():getVisibleSize()
		local cells_height = g_packageUI.cells_layer.cells_height
		local position_x = 0.23
		local position_y = 0.66 - cells_height / scrSize.height
		itemInfo.csvInfo = csvInfo
		local heightOffset = 0.02 * scrSize.height
		local cell, size = createCell(itemInfo, position_x, position_y, packageTagDef.props, 1)

		g_packageUI.cells_layer:addCell(cell, {
			width = size.width,
			height = size.height + heightOffset
		})
	end
end

function refreshPackage()
	local packageTableView = currentPackageDataTable.packageTableView

	if not packageTableView then
		return
	end

	local packageTag = currentPackageDataTable.packageTag

	if not packageTag then
		return
	end

	packageItemsInfo = getItemsByPackageTag(packageTag)

	if #packageItemsInfo >= 0 then
		local dataSource = getPackageCellsDataSource(packageItemsInfo)

		cclog("refreshPackage success, reloadData!!!!")
		packageTableView:reloadData(dataSource)
	end
end

function createSkillLabel(parent, type_id, position, level, color, has_wake, eff_value)
	d_ms.d_skillUpgradeUI.initSkillCsv()

	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local effect_type = d_ms.d_skillUpgradeUI.g_self.csv_map_skill[type_id]
	local pro = 0
	local num = 0
	local powerSprite = nil
	local itemInfo_level = level
	local is_intensity = false

	d_ms.d_wakeUI.initCsv()

	if type_id == 21 then
		powerSprite = CCSprite:create("v2/introUI/xi.png")
		num = d_ms.d_skillUpgradeUI.g_self.csv_map_rulai_skill[level][2]

		if has_wake then
			num = num * 1.1 + d_ms.d_charPositionUI.g_charPosUI.current_characterInfo.magic / 800
		else
			num = num + d_ms.d_charPositionUI.g_charPosUI.current_characterInfo.magic / 800
		end
	elseif effect_type[8] == "1" then
		powerSprite = CCSprite:create("v2/introUI/damage.png")
		num = tonumber(effect_type[9]) + tonumber(effect_type[14]) * (itemInfo_level - 1)
	elseif effect_type[8] == "2" then
		powerSprite = CCSprite:create("v2/introUI/defence.png")
		num = tonumber(effect_type[10]) + tonumber(effect_type[14]) * (itemInfo_level - 1)
	elseif effect_type[8] == "3" then
		powerSprite = CCSprite:create("v2/introUI/mana.png")
		num = tonumber(effect_type[11]) + tonumber(effect_type[14]) * (itemInfo_level - 1)
	elseif effect_type[8] == "5" then
		powerSprite = CCSprite:create("v2/introUI/health.png")
		num = tonumber(effect_type[13]) + tonumber(effect_type[14]) * (itemInfo_level - 1)
	else
		is_intensity = true
		powerSprite = CCSprite:create("v2/introUI/skill_strong.png")

		if eff_value then
			num = eff_value
		else
			num = tonumber(effect_type[12]) + tonumber(effect_type[14]) * (itemInfo_level - 1)
		end
	end

	if has_wake and not is_intensity and type_id ~= 21 then
		num = num * (1 + d_ms.d_wakeUI.g_csv.rate[type_id] / 100)
	end

	if type_id == 21 then
		num = string.format("%.1f", num)
		pro = num .. "%"
	elseif effect_type[8] == "4" then
		pro = math.floor(num)
	else
		num = string.format("%.1f", num)
		pro = num .. "%"
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

	if color then
		powerLabel:setColor(ccc3(color[1], color[2], color[3]))
	end

	parent:addChild(powerSprite, 5)
	parent:addChild(powerLabel, 5)

	return powerLabel
end

function removeItemsFromPackage(msg_table)
	local removedItemTable = {}

	for i = 1, #msg_table.object_list do
		for j = 1, #g_packageItemsInfo do
			if msg_table.object_list[i] == g_packageItemsInfo[j].id and g_packageItemsInfo[j].attach_type == msg_table.obj_type then
				removedItemTable[#removedItemTable + 1] = g_packageItemsInfo[j]

				table.remove(g_packageItemsInfo, j)

				break
			end
		end
	end

	if removedItemTable and #removedItemTable > 0 then
		for i = 1, #removedItemTable do
			local removedItem = removedItemTable[i]
			local object_type = removedItem.attach_type
			local type_id = removedItem.type_id
			local packge = nil

			if object_type == o_t.item then
				local main_type = removedItem.csvInfo.mainType

				if main_type then
					packge = g_reorgItemsInfo[object_type][main_type]
				end
			elseif object_type == o_t.skill then
				packge = g_reorgItemsInfo[object_type]
			end

			if packge then
				for i = 1, #packge do
					if removedItem.id == packge[i].id then
						table.remove(packge, i)

						break
					end
				end
			end
		end
	end
end

function addStarLockInfo(parent, item, hasBtn)
	local parent = parent or g_packageUI.itemIntroLayer
	local item = item or g_packageUI.last_show_item

	if not parent or not item then
		return
	end

	local layer = d_ms.d_u.clearLayer(g_packageUI.itemIntroLayer, 10, 1234)
	local itemSprite = d_ms.d_wakeUI.getStarSprite(item.type_id, item.level or 1, nil, item.is_lock == 1)

	layer:addChild(d_ms.d_u.setStyles(itemSprite, {
		scale = 0.18,
		x = 0.36,
		y = 0.68
	}))

	if hasBtn then
		local function pressLock()
			local t_msg_lock_item = {
				des_id = item.id,
				flag = item.is_lock == 1 and 2 or 1
			}

			d_ms.d_u.main_server_send_msg(d_ms.d_msg_def.gscl_msg_id.msg_lock_item, t_msg_lock_item)
		end

		local pics = item.is_lock == 1 and "ulock" or "alock"
		local menu_btn_list = {
			{
				y = 0.22,
				x = 0.5,
				npic = "v2/wakeUI/" .. pics .. "1.png",
				spic = "v2/wakeUI/" .. pics .. "2.png",
				call_back = pressLock
			},
			x = 0,
			y = 0
		}

		layer:addChild(d_ms.d_u.createMenu(menu_btn_list), 1)
	end
end

function createItemIntroLayer(itemInfo, introLayerCallback, isShowEnhance, closeCallBack)
	local default_color = {
		254,
		235,
		192
	}
	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local introLayer = CCLayer:create()
	g_packageUI.itemIntroLayer = introLayer
	g_packageUI.last_show_item = itemInfo
	local menuArr = CCArray:create()
	local maskLayer = CCLayerColor:create(ccc4(0, 0, 0, 100))

	introLayer:addChild(maskLayer, -10)

	function closeAndRemoveIntroLayer()
		d_ms.d_u.remove(introLayer)

		introLayer = nil

		if closeCallBack then
			closeCallBack()
		end

		return true
	end

	local bkg = CCSprite:create("v2/messageUI/frame1.png")

	d_ms.d_u.setStyles(bkg, {
		scaleY = 0.83,
		x = 0.5,
		y = 0.55
	})
	introLayer:addChild(bkg)

	local params = {
		outFunc = closeAndRemoveIntroLayer,
		rect = d_ms.d_u.getRealRect(bkg)
	}

	d_ms.d_u.createSwallowTouchLayerFunc(introLayer, params)

	local closeMenuItem = CCMenuItemImage:create("v2/introUI/close1.png", "v2/introUI/close2.png")

	closeMenuItem:setTag(g_introButtonType.close)
	d_ms.d_u.setStyles(closeMenuItem, {
		x = 0.73,
		y = 0.93
	})
	closeMenuItem:registerScriptTapHandler(introLayerCallback)

	local closeMenu = CCMenu:createWithItem(closeMenuItem)

	closeMenu:setPosition(CCPointMake(0, 0))
	introLayer:addChild(closeMenu, 10)

	local touchArea = {
		x = 0.25 * scrSize.width,
		y = 0.16 * scrSize.height,
		width = 0.48 * scrSize.width,
		height = 0.787 * scrSize.height
	}
	local position = {
		x = touchArea.x,
		y = touchArea.y
	}
	local contentSize = {
		width = touchArea.width,
		height = touchArea.height
	}
	local totalHeight = 0
	local content = d_ms.d_inertiaLayer.inertiaLayer.new(contentSize, position, touchArea)

	introLayer:addChild(content.scrollView, 100)

	local contentNode = CCNode:create()

	contentNode:setPosition(-position.x, -position.y)

	local headBkg = CCSprite:create("v2/newIntroUI/head_bkg.png")

	d_ms.d_u.setStyles(headBkg, {
		x = 0.5,
		y = 0.89
	})
	contentNode:addChild(headBkg)

	local introLabel = CCSprite:create("v2/introUI/intro_label.png")

	d_ms.d_u.setStyles(introLabel, {
		x = 0.5,
		y = 0.9
	})
	contentNode:addChild(introLabel)

	local headContent = headBkg:getContentSize()
	totalHeight = totalHeight + headContent.height

	if not itemInfo.attach_type and itemInfo.csvInfo and itemInfo.csvInfo.quality == 0 then
		itemInfo.attach_type = d_ms.d_common_def.object_type.item
	end

	local isAsc = itemInfo.reborn_bit and itemInfo.reborn_bit > 0
	local packageTag = itemInfo.csvInfo.packageTag
	local plus_type = {
		"v2/introUI/damage.png",
		"v2/introUI/defence.png",
		"v2/introUI/health.png"
	}

	local function getIconWithStars()
		local itemSprite = d_ms.d_data.getCertainSmallSprite(itemInfo.attach_type, itemInfo.type_id or itemInfo.buyInfo.type_id, itemInfo.level or 1, isAsc, itemInfo.star_level)

		if packageTag ~= packageTagDef.props and packageTag ~= packageTagDef.stone then
			local size = itemSprite:getContentSize()
			local quality = itemInfo.csvInfo.quality

			if itemInfo.star_level == 1 then
				local star = CCSprite:create("v2/shengxing/sixstar.png")

				d_ms.d_u.setStyles(star, {
					scale = 0.06
				})
				star:setPosition(0.1 * size.width, 0.1 * size.height)
				star:setAnchorPoint(CCPointMake(0, 0))
				itemSprite:addChild(star)
			else
				local emptyStar = CCSprite:create("v2/newIntroUI/star_bkg.png")
				local starSize = emptyStar:getContentSize()

				emptyStar:setPosition(0.1 * size.width, 0.1 * size.height)
				emptyStar:setAnchorPoint(CCPointMake(0, 0))
				emptyStar:setScale(0.8 * size.width / starSize.width)
				itemSprite:addChild(emptyStar)

				if quality and quality > 0 then
					local qualityRatio = itemInfo.csvInfo.quality / 5
					local starsLevelSprite = CCSprite:create("v2/introUI/stars.png")
					local starsContentSize = starsLevelSprite:getContentSize()

					starsLevelSprite:setTextureRect(CCRectMake(0, 0, starsContentSize.width * qualityRatio, starsContentSize.height))
					starsLevelSprite:setPosition(0.1 * size.width, 0.1 * size.height)
					starsLevelSprite:setAnchorPoint(CCPointMake(0, 0))
					starsLevelSprite:setScale(0.8 * size.width / starsContentSize.width)
					itemSprite:addChild(starsLevelSprite)
				end
			end
		end

		return itemSprite
	end

	local bkgSize = nil

	if packageTag == packageTagDef.props or packageTag == packageTagDef.skill or packageTag == packageTagDef.stone then
		local itemSprite = getIconWithStars()

		d_ms.d_u.setStyles(itemSprite, {
			scale = 0.18,
			x = 0.36,
			y = 0.68
		})

		if itemInfo.csvInfo.mainType ~= m_t.awaken_star then
			contentNode:addChild(itemSprite)
		end

		if itemInfo.upgrade_level and itemInfo.upgrade_level ~= 0 then
			local size = itemSprite:getContentSize()
			local advanceLabel = CCSprite:create("v2/enhanceUI/wu.png")

			itemSprite:addChild(advanceLabel)
			advanceLabel:setAnchorPoint(ccp(1, 0))
			advanceLabel:setPosition(0.95 * size.width, 0.05 * size.height)
		end

		local infoBkg = CCSprite:create("v2/newIntroUI/bkg1.png")

		d_ms.d_u.setStyles(infoBkg, {
			x = 0.58,
			y = 0.68
		})
		contentNode:addChild(infoBkg, -2)

		bkgSize = infoBkg:getContentSize()
		local name = nil

		if itemInfo.upgrade_level and itemInfo.upgrade_level > 0 then
			local HpSprite = CCSprite:create("v2/introUI/health.png")

			HpSprite:setPosition(bkgSize.width * 0.56, bkgSize.height * 0.5)
			HpSprite:setAnchorPoint(CCPointMake(0, 0.5))
			infoBkg:addChild(HpSprite, 5)

			local Hp = 12
			local HpLabel = d_ms.d_u.createByStyle({
				font = "arial",
				fontsize = 26,
				type = "label",
				string = tostring(Hp) .. "%"
			})

			HpLabel:setPosition(bkgSize.width * 0.68, bkgSize.height * 0.5)
			HpLabel:setAnchorPoint(CCPointMake(0, 0.5))
			HpLabel:setColor(ccc3(default_color[1], default_color[2], default_color[3]))
			infoBkg:addChild(HpLabel, 5)

			advanceposition = HpSprite:getPositionLua()
			name = d_ms.d_u.createByStyle({
				y = 0.78,
				font = "arial",
				type = "label",
				x = 0.58,
				fontsize = 30,
				string = itemInfo.csvInfo.name,
				color = default_color
			})
		elseif packageTag == packageTagDef.stone and itemInfo.level == 11 then
			name = d_ms.d_u.createByStyle({
				y = 0.77,
				type = "label",
				x = 0.58,
				fontsize = 30,
				string = d_ms.d_hz.gethz("stone_ascName" .. itemInfo.csvInfo.sub_type),
				color = default_color
			})
		elseif packageTag == packageTagDef.stone and itemInfo.level == 12 then
			name = d_ms.d_u.createByStyle({
				y = 0.77,
				type = "label",
				x = 0.58,
				fontsize = 30,
				string = d_ms.d_hz.gethz("stone_tilianName" .. itemInfo.csvInfo.sub_type),
				color = default_color
			})
		elseif packageTag == packageTagDef.stone and itemInfo.level == 13 then
			name = d_ms.d_u.createByStyle({
				y = 0.77,
				type = "label",
				x = 0.58,
				fontsize = 30,
				string = d_ms.d_hz.gethz("stone_tilianNameB" .. itemInfo.csvInfo.sub_type),
				color = default_color
			})
		elseif packageTag == packageTagDef.stone and itemInfo.level == 14 then
			name = d_ms.d_u.createByStyle({
				y = 0.77,
				type = "label",
				x = 0.58,
				fontsize = 30,
				string = d_ms.d_hz.gethz("stone_tilianNameC" .. itemInfo.csvInfo.sub_type),
				color = default_color
			})
		else
			name = d_ms.d_u.createByStyle({
				y = 0.77,
				font = "arial",
				type = "label",
				x = 0.58,
				fontsize = 30,
				string = itemInfo.csvInfo.name,
				color = default_color
			})
		end

		contentNode:addChild(name)
	end

	local y2 = 0.36

	if packageTag == packageTagDef.props then
		local propsColor = {
			253,
			190,
			37
		}
		local offset = d_ms.d_u.getSingleHzWidthBySize(30)
		local order = 0

		if itemInfo.count then
			local count = d_ms.d_hz.gethz("number") .. ": " .. itemInfo.count
			local countLabel = d_ms.d_u.createByStyle({
				font = "arial",
				type = "label",
				fontsize = 30,
				string = count,
				x = 0.58 - 2 * offset,
				y = 0.7 - order * 0.05,
				color = propsColor,
				anchor = {
					0,
					0.5
				}
			})

			contentNode:addChild(countLabel, 10)

			order = order + 1
		end

		if itemInfo.csvInfo and itemInfo.csvInfo.show_level and itemInfo.csvInfo.show_level > 0 and (itemInfo.csvInfo.show_level > 7984 or itemInfo.csvInfo.show_level < 7981) then
			local show_level = d_ms.d_hz.gethz("skill_up_level") .. ": " .. itemInfo.csvInfo.show_level
			local showLevelLabel = d_ms.d_u.createByStyle({
				font = "arial",
				type = "label",
				fontsize = 30,
				string = show_level,
				x = 0.58 - 2 * offset,
				y = 0.7 - order * 0.05,
				color = propsColor,
				anchor = {
					0,
					0.5
				}
			})

			contentNode:addChild(showLevelLabel, 10)

			order = order + 1
		end

		if itemInfo.csvInfo and itemInfo.csvInfo.base_experience_plus and itemInfo.csvInfo.base_experience_plus > 0 then
			local exp = d_ms.d_hz.gethz("exp") .. ": " .. itemInfo.csvInfo.base_experience_plus
			local expLabel = d_ms.d_u.createByStyle({
				font = "arial",
				type = "label",
				fontsize = 30,
				string = exp,
				x = 0.58 - 2 * offset,
				y = 0.7 - order * 0.05,
				color = propsColor,
				anchor = {
					0,
					0.5
				}
			})

			contentNode:addChild(expLabel, 10)

			order = order + 1
		end

		if itemInfo.csvInfo and itemInfo.csvInfo.mainType == m_t.ext_skill then
			local level = itemInfo.level or 1

			contentNode:addChild(d_ms.d_u.createByStyle({
				pic = "v2/introUI/level.png",
				x = 0.56,
				y = 0.63
			}))
			contentNode:addChild(d_ms.d_u.createByStyle({
				font = "arial",
				y = 0.63,
				type = "label",
				x = 0.59,
				fontsize = 26,
				string = tostring(itemInfo.level or 1),
				anchor = {
					0,
					0.5
				},
				color = default_color
			}))
		end

		if itemInfo.csvInfo.mainType == m_t.awaken_star then
			if isShowEnhance then
				contentNode:addChild(d_ms.d_u.createByStyle({
					y = 0.3,
					type = "label",
					x = 0.5,
					fontsize = 26,
					string = gethz("wake35"),
					color = default_color
				}))
			end

			addStarLockInfo(introLayer, itemInfo, isShowEnhance)
		end
	elseif packageTag == packageTagDef.skill or packageTag == packageTagDef.stone then
		if itemInfo.upgrade_level and itemInfo.upgrade_level > 0 then
			contentNode:addChild(d_ms.d_u.createByStyle({
				pic = "v2/introUI/level.png",
				x = 0.5,
				y = 0.74
			}))
			contentNode:addChild(d_ms.d_u.createByStyle({
				font = "arial",
				y = 0.74,
				type = "label",
				x = 0.53,
				fontsize = 26,
				string = tostring(itemInfo.level or 1),
				anchor = {
					0,
					0.5
				},
				color = default_color
			}))
		elseif packageTag ~= packageTagDef.stone or itemInfo.level <= 10 then
			contentNode:addChild(d_ms.d_u.createByStyle({
				pic = "v2/introUI/level.png",
				x = 0.52,
				y = 0.7
			}))
			contentNode:addChild(d_ms.d_u.createByStyle({
				font = "arial",
				y = 0.7,
				type = "label",
				x = 0.54,
				fontsize = 26,
				string = tostring(itemInfo.level or 1),
				anchor = {
					0,
					0.5
				},
				color = default_color
			}))
		end

		if packageTag == packageTagDef.skill then
			local cor = default_color

			if d_ms.d_wakeUI.isAwaken(itemInfo.awaken) then
				cor = {
					0,
					255,
					0
				}
			end

			if itemInfo.upgrade_level and itemInfo.upgrade_level > 0 then
				createSkillLabel(contentNode, itemInfo.type_id or itemInfo.buyInfo.type_id, d_ms.d_u.makePoint(0.5, 0.68), itemInfo.level, cor, d_ms.d_wakeUI.isAwaken(itemInfo.awaken), itemInfo.effect_value)
			else
				createSkillLabel(contentNode, itemInfo.type_id or itemInfo.buyInfo.type_id, d_ms.d_u.makePoint(0.62, 0.7), itemInfo.level, cor, d_ms.d_wakeUI.isAwaken(itemInfo.awaken), itemInfo.effect_value)
			end

			if itemInfo.type_id == 21 then
				d_ms.d_skillUpgradeUI.initSkillCsv()

				local num = d_ms.d_skillUpgradeUI.g_self.csv_map_rulai_skill[itemInfo.level][3]
				local cor = {
					255,
					255,
					255
				}

				if d_ms.d_wakeUI.isAwaken(itemInfo.awaken) then
					d_ms.d_wakeUI.initCsv()

					num = num * (1 + d_ms.d_wakeUI.g_csv.rate[itemInfo.type_id] / 100)
					cor = {
						0,
						255,
						0
					}
				end

				local tmp = string.format("%0.1f", num) .. "%"

				contentNode:addChild(d_ms.d_u.createByStyle({
					pic = "v2/introUI/dun.png",
					x = 0.62,
					y = 0.63
				}))
				contentNode:addChild(d_ms.d_u.createByStyle({
					font = "arial",
					y = 0.63,
					type = "label",
					x = 0.64,
					fontsize = 26,
					string = tmp,
					anchor = {
						0,
						0.5
					},
					color = cor
				}))
			end
		else
			local sub_type = itemInfo.csvInfo.sub_type
			local attr_x = 0.62

			if packageTag == packageTagDef.stone and itemInfo.level > 10 then
				attr_x = 0.55
			end

			contentNode:addChild(d_ms.d_u.createByStyle({
				y = 0.7,
				pic = plus_type[sub_type],
				x = attr_x
			}))

			local attrStr = nil

			if itemInfo.level and itemInfo.level > 10 then
				d_ms.d_stoneCastUI.initConfig()

				attrStr = d_ms.d_stoneCastUI.g_self.csv[sub_type][itemInfo.level].plus
			else
				attrStr = d_ms.d_data.g_stoneAttrTable[sub_type][itemInfo.level or 1].base
			end

			contentNode:addChild(d_ms.d_u.createByStyle({
				font = "arial",
				y = 0.7,
				type = "label",
				fontsize = 26,
				string = string.format("%.1f", attrStr * 100) .. "%",
				anchor = {
					0,
					0.5
				},
				color = default_color,
				x = attr_x + 0.02
			}))
		end

		if itemInfo.upgrade_level and itemInfo.upgrade_level > 0 then
			-- Nothing
		end

		if isShowEnhance then
			local enhance = nil

			if packageTag == packageTagDef.skill then
				if itemInfo.csvInfo.quality == 5 and d_ms.d_skillUpgradeUI.isCanAdvance(itemInfo.type_id) then
					enhance = CCMenuItemImage:create("v2/enhanceUI/up_2.png", "v2/enhanceUI/up_2.png")

					enhance:setTag(g_introButtonType.enhanceSkill)
					d_ms.d_u.setStyles(enhance, {
						x = 0.58,
						y = 0.6
					})
					enhance:registerScriptTapHandler(introLayerCallback)
					menuArr:addObject(enhance)

					if itemInfo.level < 10 or not itemInfo.upgrade_level or itemInfo.upgrade_level ~= 0 then
						d_ms.d_u.grayMenuItem(enhance)
					end
				end
			else
				if packageTag == packageTagDef.stone and itemInfo.level == 10 then
					enhance = CCMenuItemImage:create("v2/stoneCastUI/asc1.png", "v2/stoneCastUI/asc2.png")
				elseif packageTag == packageTagDef.stone and itemInfo.level >= 11 then
					enhance = CCMenuItemImage:create("v2/stoneCastUI/tilian.png", "v2/stoneCastUI/tilian2.png")
				else
					enhance = CCMenuItemImage:create("v2/newIntroUI/upgrade1.png", "v2/newIntroUI/upgrade2.png")
				end

				enhance:setTag(g_introButtonType.stoneUpgrade)
				d_ms.d_u.setStyles(enhance, {
					x = 0.58,
					y = 0.6
				})
				enhance:registerScriptTapHandler(introLayerCallback)
				menuArr:addObject(enhance)
			end
		end
	else
		local level = itemInfo.level or 1
		local advance_level = itemInfo.advance_level or 0
		local star_count = itemInfo.star_count or 0
		local cur_spirit_count = itemInfo.cur_spirit_count or 0
		local cast_level = itemInfo.cast_level or 0
		local reborn_bit = itemInfo.reborn_bit or 0
		local mainBkg = CCSprite:create("v2/newIntroUI/big_bkg.png")

		d_ms.d_u.setStyles(mainBkg, {
			scale = 0.44296875,
			x = 0.5,
			y = 0.85,
			anchor = {
				0.5,
				1
			}
		})
		contentNode:addChild(mainBkg)

		local w, h = d_ms.d_u.getRealScale(mainBkg)
		y2 = h + 0.02
		local origin_x = 0.5 - 0.5 * w
		local origin_y = 0.85 - h
		local itemSprite = getIconWithStars()

		d_ms.d_u.setStyles(itemSprite, {
			x = origin_x + 0.18 * w,
			y = origin_y + 0.75 * h,
			scaleH = 0.45 * h
		})
		contentNode:addChild(itemSprite)

		local nameStr = d_ms.d_data.getNameByTypeId(o_t.item, itemInfo.type_id, isAsc)
		local name = d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			fontsize = 30,
			string = nameStr,
			x = origin_x + 0.45 * w,
			y = origin_y + 0.9 * h,
			anchor = {
				0,
				0.5
			},
			color = default_color
		})

		contentNode:addChild(name)

		if cast_level > 0 and cast_level < 5 then
			local nameW = d_ms.d_u.getRealScale(name)

			contentNode:addChild(d_ms.d_u.createByStyle({
				pic = "v2/ascCast/cast_lv" .. cast_level .. ".png",
				x = origin_x + 0.45 * w + nameW,
				y = origin_y + 0.9 * h,
				anchor = {
					-0.1,
					0.5
				}
			}))
		elseif advance_level > 0 then
			local nameW = d_ms.d_u.getRealScale(name)

			contentNode:addChild(d_ms.d_u.createByStyle({
				pic = "v2/equipAdvanceUI/ad" .. advance_level .. ".png",
				x = origin_x + 0.45 * w + nameW,
				y = origin_y + 0.9 * h,
				anchor = {
					-0.1,
					0.5
				}
			}))
		end

		contentNode:addChild(d_ms.d_u.createByStyle({
			pic = "v2/introUI/level.png",
			x = origin_x + 0.45 * w,
			y = origin_y + 0.63 * h,
			anchor = {
				1.1,
				0.5
			}
		}))
		contentNode:addChild(d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			fontsize = 26,
			string = tostring(level),
			anchor = {
				0,
				0.5
			},
			color = default_color,
			x = origin_x + 0.45 * w,
			y = origin_y + 0.63 * h
		}))

		local cur_y = origin_y + 0.255 * h
		local value_y = origin_y + 0.085 * h
		local left_x = origin_x + 0.113 * w
		local offset_x = 0.2 * w
		local value_offset_x = 0.03 * w
		local percentPlus = 0
		local levelTab = d_ms.d_data.g_stoneAttrTable[packageTag]
		local star_level = itemInfo.star_level

		if not itemInfo.star_level then
			star_level = 0
		end

		local MAXSLOT = d_ms.d_stoneUI.g_self.Slots[itemInfo.csvInfo.quality] + star_level
		local sloted = itemInfo.drill_count or 0

		for i = 1, 4 do
			local cur_x = left_x + (i - 1) * offset_x
			local stone_level = itemInfo["stone" .. i .. "_level"] or 0

			if stone_level > 0 then
				local value = nil

				if stone_level > 10 then
					d_ms.d_stoneCastUI.initConfig()

					value = d_ms.d_stoneCastUI.g_self.csv[packageTag][stone_level].plus
				else
					value = levelTab[stone_level].base
				end

				percentPlus = percentPlus + value
				local stoneSprite = d_ms.d_data.getCertainSmallSprite(itemInfo.attach_type, d_ms.d_stoneUI.getStoneTypeID(packageTag), stone_level, itemInfo.star_level)

				d_ms.d_u.setStyles(stoneSprite, {
					x = cur_x,
					y = cur_y,
					scaleH = 0.2 * h
				})
				contentNode:addChild(stoneSprite)
				contentNode:addChild(d_ms.d_u.createByStyle({
					pic = "v2/newIntroUI/stone_value_bkg.png",
					x = cur_x,
					y = value_y
				}))
				contentNode:addChild(d_ms.d_u.createByStyle({
					pic = plus_type[packageTag],
					x = cur_x - value_offset_x,
					y = value_y,
					scaleH = 0.07 * h,
					anchor = {
						1,
						0.5
					}
				}))
				contentNode:addChild(d_ms.d_u.createByStyle({
					font = "arial",
					type = "label",
					fontsize = 26,
					string = string.format(" %.1f%%", value * 100),
					x = cur_x - value_offset_x,
					y = value_y,
					anchor = {
						0,
						0.5
					},
					color = default_color
				}))
			elseif i <= MAXSLOT then
				contentNode:addChild(d_ms.d_u.createByStyle({
					pic = "v2/stoneUI/unsee.png",
					scaleH = 0.2 * h,
					x = cur_x,
					y = cur_y
				}))

				if sloted < i then
					contentNode:addChild(d_ms.d_u.createByStyle({
						pic = "v2/stoneUI/lock.png",
						x = cur_x,
						y = cur_y,
						scaleH = 0.2 * h
					}))
				end
			end
		end

		local slot = CCMenuItemImage:create("v2/shengxing/dianji.png", "v2/shengxing/dianji.png")

		d_ms.d_u.setStyles(slot, {
			scaleX = 0.45,
			x = origin_x + 0.5 * w,
			y = origin_y + 0.2 * h
		})
		slot:setTag(g_introButtonType.slot)
		slot:registerScriptTapHandler(introLayerCallback)
		menuArr:addObject(slot)

		if isShowEnhance then
			local enhance = CCMenuItemImage:create("v2/newIntroUI/enhance1.png", "v2/newIntroUI/enhance2.png")

			if d_ms.d_equipmentUpgradeUI.checkEquipmentCanUpgrade(false, itemInfo.level, itemInfo.csvInfo.quality, itemInfo.reborn_bit) == 2 then
				d_ms.d_u.grayMenuItem(enhance)
			end

			d_ms.d_u.setStyles(enhance, {
				x = origin_x + 0.825 * w,
				y = origin_y + 0.63 * h
			})
			enhance:setTag(g_introButtonType.enhance)
			enhance:setScale(0.9)
			enhance:registerScriptTapHandler(introLayerCallback)
			menuArr:addObject(enhance)
		end

		local ad_effect, asc_effect = nil

		if d_ms.d_equipAdvanceUI.g_self.is_open and itemInfo.csvInfo.quality >= 4 then
			local AdUI = d_ms.d_equipAdvanceUI

			AdUI.getConsts()

			ad_effect = AdUI.g_self.Value[itemInfo.csvInfo.quality][itemInfo.csvInfo.mainType][advance_level][star_count]

			if reborn_bit > 0 or isShowEnhance and d_ms.d_equipAscUI.canAsc(itemInfo) and d_ms.d_mainUI.g_playerInfo.level >= 70 then
				if reborn_bit == 0 and isShowEnhance then
					introLayer:addChild(d_ms.d_u.createByStyle({
						pic = "v2/ascCast/asc_bkg.png",
						x = 0.765,
						y = 0.55
					}), 1009)

					local ascMenuItem = CCMenuItemImage:create("v2/ascCast/asc1.png", "v2/ascCast/asc2.png")

					ascMenuItem:setTag(g_introButtonType.asc)
					d_ms.d_u.setStyles(ascMenuItem, {
						x = 0.765,
						y = 0.55
					})
					ascMenuItem:registerScriptTapHandler(introLayerCallback)

					local ascMenu = CCMenu:createWithItem(ascMenuItem)

					ascMenu:setPosition(CCPointMake(0, 0))
					introLayer:addChild(ascMenu, 100001)
				elseif cast_level >= 4 then
					local sp = d_ms.d_u.createByStyle({
						pic = "v2/ascCast/asc_bkg.png",
						x = 0.765,
						y = 0.55
					})

					d_ms.d_u.setStyles(sp, {
						scale = 0.15
					})
					introLayer:addChild(sp, 1009)

					if itemInfo.star_level ~= 1 then
						function callbackShengxing()
							local star_level = itemInfo.star_level
							local cur_reborn = d_ms.d_mainUI.g_playerInfo.reborn_layer or 0

							if cur_reborn < 4 then
								d_ms.d_info.show(gethz("asc30"))

								return
							end

							if star_level == 1 then
								d_ms.d_info.show(d_ms.d_hz.gethz("shengxing5"))

								return
							end

							local params = {
								skill_info = itemInfo,
								from_btn = 120,
								parent_layer = introLayer.parent,
								isNeedUpdate = true
							}

							d_ms.d_skillUpgradeUI.create_wshengxing(params)
							closeAndRemoveIntroLayer()
						end

						local asc_bkg = CCMenuItemImage:create("v2/shengxing/comfirm_sx.png", "v2/shengxing/comfirm_sx.png")

						asc_bkg:setTag(g_introButtonType.close)
						d_ms.d_u.setStyles(asc_bkg, {
							x = 0.765,
							y = 0.55
						})
						asc_bkg:registerScriptTapHandler(callbackShengxing)

						local closeMenu = CCMenu:createWithItem(asc_bkg)

						closeMenu:setPosition(CCPointMake(0, 0))
						introLayer:addChild(closeMenu, 10002)
					end
				else
					introLayer:addChild(d_ms.d_u.createByStyle({
						pic = "v2/ascCast/asc_bkg.png",
						x = 0.765,
						y = 0.55
					}), 1009)
				end
			end

			if reborn_bit > 0 then
				asc_effect = d_ms.d_equipCastUI.getCastEffect(itemInfo.csvInfo.mainType, cast_level)
				mainBkg = CCSprite:create("v2/newIntroUI/cast_bkg.png")

				d_ms.d_u.setStyles(mainBkg, {
					scale = 0.453125,
					x = 0.5,
					anchor = {
						0.5,
						1
					},
					y = origin_y
				})
				contentNode:addChild(mainBkg)

				local w2, h2 = d_ms.d_u.getRealScale(mainBkg)
				y2 = y2 + h2

				contentNode:addChild(d_ms.d_u.createByStyle({
					pic = plus_type[packageTag],
					x = 0.5 - 0.3 * w2,
					y = origin_y - 0.75 * h2,
					anchor = {
						1.1,
						0.5
					}
				}))

				local eStr = "+" .. math.floor(asc_effect.percent * 100) .. "% +" .. asc_effect.plus

				contentNode:addChild(d_ms.d_u.createByStyle({
					type = "label",
					font = "arial",
					fontsize = 26,
					x = 0.5 - 0.3 * w2,
					y = origin_y - 0.75 * h2,
					anchor = {
						0,
						0.5
					},
					string = eStr,
					color = {
						155,
						155,
						23
					}
				}))

				if isShowEnhance then
					local advance = CCMenuItemImage:create("v2/ascCast/btn21.png", "v2/ascCast/btn22.png")

					d_ms.d_u.setStyles(advance, {
						x = 0.5 + 0.32 * w2,
						y = origin_y - 0.75 * h2
					})
					advance:setTag(g_introButtonType.cast)
					advance:setScale(0.9)
					advance:registerScriptTapHandler(introLayerCallback)
					menuArr:addObject(advance)
				end
			else
				local descTab = AdUI.getExtraInfo(itemInfo.csvInfo.quality, itemInfo.csvInfo.mainType)
				local descCount = #descTab
				mainBkg = CCSprite:create("v2/newIntroUI/ad_bkg.png")

				d_ms.d_u.setStyles(mainBkg, {
					x = 0.5,
					anchor = {
						0.5,
						1
					},
					y = origin_y
				})

				if descCount > 4 then
					descCount = 4
				end

				contentNode:addChild(mainBkg)

				local w2, h2 = d_ms.d_u.getRealScale(mainBkg)
				y2 = y2 + h2
				local ys = {
					origin_y - 0.21 * h2,
					origin_y - 0.3 * h2,
					origin_y - 0.4 * h2,
					origin_y - 0.5 * h2,
					origin_y - 0.85 * h2
				}
				local Color = {
					greenow = {
						155,
						155,
						23
					},
					gray = {
						125,
						125,
						125
					},
					paper = {
						254,
						235,
						192
					}
				}
				local str, label, ww, leftx = nil
				leftx = 0.5 - 0.45 * w2
				str = AdUI.getNumHZ(advance_level) .. d_ms.d_hz.gethz("jie_hz") .. "  "
				label = d_ms.d_u.createByStyle({
					type = "label",
					font = "arial",
					fontsize = 26,
					x = leftx,
					y = ys[1],
					anchor = {
						0,
						0.5
					},
					string = str,
					color = Color.greenow
				})
				ww = d_ms.d_u.getRealScale(label)

				contentNode:addChild(label)

				leftx = leftx + ww

				for i = 1, AdUI.g_self.MAX_STAR_COUNT do
					local curx = leftx + (i - 1) * 0.062 * w
					label = d_ms.d_u.createByStyle({
						pic = "v2/equipAdvanceUI/star_emp.png",
						x = curx,
						y = ys[1],
						anchor = {
							0,
							0.5
						}
					})

					label:setScale(0.8)
					contentNode:addChild(label)

					if i <= star_count or advance_level == AdUI.g_self.MAX_ADVANCE_LEVEL then
						label = d_ms.d_u.createByStyle({
							pic = "v2/equipAdvanceUI/star_fill.png",
							x = curx,
							y = ys[1],
							anchor = {
								0,
								0.5
							}
						})

						label:setScale(0.8)
						contentNode:addChild(label)
					elseif i == star_count + 1 then
						str = cur_spirit_count / AdUI.g_self.StarCost[itemInfo.csvInfo.quality][itemInfo.csvInfo.mainType][advance_level + 1][star_count + 1]
						label = d_ms.d_u.createByStyle({
							pic = "v2/equipAdvanceUI/star_fill.png",
							x = curx,
							y = ys[1],
							anchor = {
								0,
								0.5
							}
						})
						local starsContentSize = label:getContentSize()

						label:setTextureRect(CCRectMake(0, 0, starsContentSize.width * str, starsContentSize.height))
						label:setScale(0.8)
						contentNode:addChild(label)
					end
				end

				str = "+" .. math.floor(100 * ad_effect.percent) .. "% +" .. ad_effect.plus
				label = d_ms.d_u.createByStyle({
					type = "label",
					font = "arial",
					fontsize = 26,
					x = 0.5 + 0.2 * w,
					y = ys[1],
					anchor = {
						0,
						0.5
					},
					string = str,
					color = Color.greenow
				})

				contentNode:addChild(label)

				local offsetY = (ys[5] - ys[4]) / 3
				leftx = 0.5 - 0.4 * w2

				for i = 1, descCount do
					local theColor = advance_level < descTab[i].level and Color.gray or Color.paper
					label = d_ms.d_u.createByStyle({
						type = "label",
						font = "arial",
						fontsize = 22,
						x = leftx,
						y = ys[4] + (i - 1) * offsetY,
						anchor = {
							0,
							0.5
						},
						string = descTab[i][1],
						color = theColor
					})
					ww = d_ms.d_u.getRealScale(label)

					contentNode:addChild(label)

					label = d_ms.d_u.createByStyle({
						type = "label",
						font = "arial",
						fontsize = 22,
						x = leftx + 1.2 * ww,
						y = ys[4] + (i - 1) * offsetY,
						anchor = {
							0,
							0.5
						},
						string = descTab[i][2],
						color = theColor
					})

					contentNode:addChild(label)
				end

				if isShowEnhance then
					local advance = CCMenuItemImage:create("v2/equipAdvanceUI/advance1.png", "v2/equipAdvanceUI/advance2.png")

					if not d_ms.d_equipAdvanceUI.canJoin() then
						d_ms.d_u.grayMenuItem(advance)
					end

					d_ms.d_u.setStyles(advance, {
						x = 0.5 + 0.32 * w2,
						y = ys[4]
					})
					advance:setTag(g_introButtonType.advance)
					advance:setScale(0.9)
					advance:registerScriptTapHandler(introLayerCallback)
					menuArr:addObject(advance)
				end
			end
		end

		contentNode:addChild(d_ms.d_u.createByStyle({
			pic = plus_type[packageTag],
			x = origin_x + 0.45 * w,
			y = origin_y + 0.78 * h,
			anchor = {
				1.1,
				0.5
			}
		}))

		local value_tab = {}
		local powerBase = d_ms.d_stoneUI.getEquipBaseEffect(itemInfo, nil, itemInfo.star_level)

		table.insert(value_tab, math.floor(powerBase))
		table.insert(value_tab, math.floor(powerBase * percentPlus))

		if ad_effect then
			local advance_effect_value = ad_effect.plus + powerBase * ad_effect.percent

			table.insert(value_tab, math.floor(advance_effect_value))
		end

		if asc_effect then
			local asc_effect_value = asc_effect.plus + powerBase * asc_effect.percent

			table.insert(value_tab, math.floor(asc_effect_value))
		end

		local powerStr = nil

		for i = #value_tab, 2, -1 do
			if powerStr or value_tab[i] > 0 then
				powerStr = "+" .. value_tab[i] .. (powerStr or "")
			end
		end

		powerStr = tostring(value_tab[1]) .. (powerStr or "")

		contentNode:addChild(d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			fontsize = 26,
			string = powerStr,
			x = origin_x + 0.45 * w,
			y = origin_y + 0.78 * h,
			anchor = {
				0,
				0.5
			},
			color = default_color
		}))
	end

	local y1 = 0.87
	local decStr = itemInfo.csvInfo.description or ""

	if itemInfo.csvInfo and itemInfo.csvInfo.mainType == m_t.ext_skill then
		local level = itemInfo.level or 1

		if itemInfo.csvInfo.ext_skill_desc and itemInfo.csvInfo.ext_skill_desc[level] then
			decStr = itemInfo.csvInfo.ext_skill_desc[level]
		end
	end

	if itemInfo.csvInfo and itemInfo.csvInfo.mainType == m_t.awaken_star then
		decStr = d_ms.d_wakeUI.getStarDesc(itemInfo.type_id, itemInfo.level)
	end

	local decStrLabel = CCLabelTTF:create(decStr, "arial", 26, CCSizeMake(scrSize.width * 0.4, 0), kCCTextAlignmentLeft)

	decStrLabel:setAnchorPoint(CCPointMake(0.5, 1))
	d_ms.d_u.setStyles(decStrLabel, {
		x = 0.5,
		y = y1 - y2
	})
	contentNode:addChild(decStrLabel)

	local _, descH = d_ms.d_u.getRealScale(decStrLabel)
	y2 = y2 + descH + 0.01
	local product_desc = itemInfo.csvInfo.product_desc or ""

	if #product_desc > 0 then
		local productStrLabel = CCLabelTTF:create(d_ms.d_hz.gethz("product_from") .. product_desc, "arial", 22, CCSizeMake(scrSize.width * 0.4, 0), kCCTextAlignmentLeft)

		d_ms.d_u.setStyles(productStrLabel, {
			x = 0.5,
			anchor = {
				0.5,
				1
			},
			y = y1 - y2,
			color = {
				80,
				180,
				80
			}
		})
		contentNode:addChild(productStrLabel)

		local _, proH = d_ms.d_u.getRealScale(productStrLabel)
		y2 = y2 + proH + 0.01
	end

	local function createInnerBkg(height, pos)
		local up = CCSprite:create("v2/newIntroUI/big_bkg1.png")
		local upSize = up:getContentSize()

		contentNode:addChild(up, -5)

		local mid = CCSprite:create("v2/newIntroUI/big_bkg2.png")
		local midSize = mid:getContentSize()
		local midScaleY = (height - upSize.height * 2) / midSize.height

		mid:setScaleY(midScaleY)
		contentNode:addChild(mid, -5)

		local down = CCSprite:create("v2/newIntroUI/big_bkg1.png")

		down:setFlipY(true)
		contentNode:addChild(down, -5)
		up:setAnchorPoint(CCPointMake(0.5, 1))
		up:setPosition(pos.x, pos.y)
		mid:setAnchorPoint(CCPointMake(0.5, 1))
		mid:setPosition(pos.x, pos.y - upSize.height)
		down:setAnchorPoint(CCPointMake(0.5, 1))
		down:setPosition(pos.x, pos.y + upSize.height - height)
	end

	if itemInfo.csvInfo.packageTag ~= packageTagDef.props and itemInfo.csvInfo.packageTag ~= packageTagDef.stone then
		local height = y2 * scrSize.height
		totalHeight = totalHeight + height

		createInnerBkg(height, {
			x = 0.5 * scrSize.width,
			y = 0.85 * scrSize.height
		})

		local startPos = {
			x = 0.5 * scrSize.width,
			y = (y1 - y2 - 0.02) * scrSize.height
		}
		local headBkg2 = CCSprite:create("v2/newIntroUI/head_bkg.png")

		headBkg2:setPosition(startPos.x, startPos.y)
		contentNode:addChild(headBkg2)
		headBkg2:setAnchorPoint(CCPointMake(0.5, 1))

		local headBkgSize = headBkg2:getContentSize()
		totalHeight = totalHeight + headBkgSize.height
		local hzLabel = CCSprite:create("v2/introUI/yuanfen_label.png")

		hzLabel:setPosition(startPos.x, startPos.y - headBkgSize.height * 0.4)
		contentNode:addChild(hzLabel)

		local typeID = itemInfo.type_id
		local itemConnection = d_ms.d_lineupUI.g_fateAttrTable.item[typeID]
		local connectPos = {
			x = scrSize.width * 0.28,
			y = startPos.y - headBkgSize.height
		}
		local spaceY = 0.02 * scrSize.height

		if itemConnection ~= nil then
			local connectionHZ = d_ms.d_hz.gethz("connection")
			local connectionDescLabel = CCLabelTTF:create(connectionHZ .. ":", "arial", 30)
			local posY = connectPos.y - spaceY

			connectionDescLabel:setPosition(connectPos.x, posY)
			connectionDescLabel:setAnchorPoint(CCPointMake(0, 1))
			contentNode:addChild(connectionDescLabel)
			connectionDescLabel:setColor(ccc3(253, 190, 37))

			local size = connectionDescLabel:getContentSize()
			local characterName = nil

			for i = 1, #itemConnection do
				local name = d_ms.d_lineupUI.g_characterAttrTable[itemConnection[i].character].name

				if i > 1 then
					characterName = characterName .. d_ms.d_hz.gethz("comma")
				end

				if characterName == nil then
					characterName = name
				else
					characterName = characterName .. name
				end
			end

			local connectionListLabel = CCLabelTTF:create(characterName, "arial", 26, CCSizeMake(scrSize.width * 0.4, 0), kCCTextAlignmentLeft)
			posY = posY - 0.02 * scrSize.height - size.height

			connectionListLabel:setPosition(connectPos.x, posY)
			connectionListLabel:setAnchorPoint(CCPointMake(0, 1))
			contentNode:addChild(connectionListLabel)

			size = connectionListLabel:getContentSize()
			local connectionIntroLabel = CCLabelTTF:create(d_ms.d_hz.gethz("connectEffect") .. ":", "arial", 30)

			connectionIntroLabel:setAnchorPoint(CCPointMake(0, 1))

			posY = posY - 0.02 * scrSize.height - size.height

			connectionIntroLabel:setPosition(connectPos.x, posY)
			connectionIntroLabel:setColor(ccc3(253, 190, 37))
			contentNode:addChild(connectionIntroLabel)

			size = connectionIntroLabel:getContentSize()
			local connectionEffectStr = d_ms.d_hz.gethz("increase")
			local connectionType = itemConnection[1].effectField
			local connectionValue = itemConnection[1].effectValue

			if connectionType == 1 then
				connectionEffectStr = d_ms.d_hz.gethz("healthPoint") .. connectionEffectStr .. tostring(connectionValue) .. "%"
			elseif connectionType == 2 then
				connectionEffectStr = d_ms.d_hz.gethz("neili") .. connectionEffectStr .. tostring(connectionValue) .. "%"
			elseif connectionType == 3 then
				connectionEffectStr = d_ms.d_hz.gethz("damage") .. connectionEffectStr .. tostring(connectionValue) .. "%"
			elseif connectionType == 4 then
				connectionEffectStr = d_ms.d_hz.gethz("defense") .. connectionEffectStr .. tostring(connectionValue) .. "%"
			end

			local connectionEffectLabel = CCLabelTTF:create(connectionEffectStr, "arial", 26)
			posY = posY - 0.02 * scrSize.height - size.height

			connectionEffectLabel:setPosition(connectPos.x, posY)
			connectionEffectLabel:setAnchorPoint(CCPointMake(0, 1))
			contentNode:addChild(connectionEffectLabel)

			size = connectionIntroLabel:getContentSize()
		else
			local connectionHZ = d_ms.d_hz.gethz("noConnect")
			local connectionDescLabel = CCLabelTTF:create(connectionHZ, "arial", 30)

			connectionDescLabel:setPosition(connectPos.x, connectPos.y - 0.02 * scrSize.height)
			connectionDescLabel:setAnchorPoint(CCPointMake(0, 1))
			contentNode:addChild(connectionDescLabel)
			connectionDescLabel:setColor(ccc3(253, 190, 37))
		end

		local height2 = 0.35 * scrSize.height

		createInnerBkg(height2, {
			x = startPos.x,
			y = startPos.y - 0.7 * headBkgSize.height
		})

		totalHeight = totalHeight + height2

		if isShowEnhance and d_ms.d_loginUI.g_currentSence == d_ms.d_loginUI.senceID.mainUI then
			local cy = y1 - y2 - 0.02 - 0.35 - headBkgSize.height / scrSize.height
			local handbook = CCMenuItemImage:create("v2/handbook/tj_btn1.png", "v2/handbook/tj_btn2.png")

			d_ms.d_u.setStyles(handbook, {
				x = 0.5,
				y = cy,
				anchor = {
					0.5,
					1
				}
			})
			handbook:setTag(g_introButtonType.handbook)
			handbook:registerScriptTapHandler(introLayerCallback)
			menuArr:addObject(handbook)

			totalHeight = totalHeight + handbook:getContentSize().height
		end

		content:createInertiaMove()
	else
		local height = (y2 + 0.3) * scrSize.height

		createInnerBkg(height, {
			x = 0.5 * scrSize.width,
			y = 0.85 * scrSize.height
		})

		totalHeight = totalHeight + height
	end

	local menu = CCMenu:createWithArray(menuArr)

	menu:setPosition(CCPointMake(0, 0))
	contentNode:addChild(menu, 5)
	content:addCell(contentNode, {
		width = contentSize.width,
		height = totalHeight
	})

	return introLayer
end

function useItem(tag)
	local tmp_tab = g_currentPackageItems[tag]

	requestUseItem(tmp_tab)
end

function requestUseItem(item)
	if item.count <= 0 then
		d_ms.d_info.show(d_ms.d_hz.gethz("noCount"))

		return
	end

	g_lastRequestUsedItem = {}

	local function sendUseItemRequest(count)
		if not item.id then
			item.id = getPropIDByTypeId(item.type_id)
		end

		cclog("item_main_type.gift_bag , id = %f", item.id)

		if item.type_id == 1031 and d_ms.d_mainUI.g_playerInfo.vip_level < 1 then
			d_ms.d_info.show(d_ms.d_hz.gethz("not_vip"))

			return
		end

		g_lastRequestUsedItem.item = item
		g_lastRequestUsedItem.count = count or 1
		local t_msg_use_item = {
			des_id = 0,
			item_type = item.type_id,
			item_id = item.id,
			des_type = d_ms.d_common_def.object_type.role,
			item_count = count or 1
		}

		d_ms.d_u.main_server_send_msg(d_ms.d_msg_def.gscl_msg_id.msg_use_item, t_msg_use_item)
	end

	if item.type_id == 1150 or item.type_id == 1151 then
		sendUseItemRequest()
	elseif item.type_id == 1005 then
		d_ms.d_commonLayerUI.showModityNameCard(g_packageUI.parent, 40)
	elseif item.type_id == 1246 then
		d_ms.d_kickUI.showFruitUseLayer(g_packageUI.parent, 30)
	elseif item.type_id == 1249 then
		d_ms.d_xianlingShopUI.showBoxUseLayer(g_packageUI.parent, 30)
	elseif item.type_id == 1367 or item.type_id == 1368 then
		d_ms.d_turntableUI.showBoxUseLayer(g_packageUI.parent, 30, item.type_id)
	elseif item.csvInfo.mainType == m_t.gift_bag or item.csvInfo.mainType == m_t.lottery_bag or item.csvInfo.mainType == m_t.vip_bag or item.type_id == 1036 then
		if item.count >= 10 then
			local defs = {
				min = 1,
				max = math.min(15, item.count)
			}

			d_ms.d_data.createBatchUse(d_ms.d_mainUI.g_mainUI.main_layer, defs, sendUseItemRequest)
		else
			sendUseItemRequest()
		end
	elseif item.type_id == 1029 then
		if d_ms.d_mainUI.g_playerInfo.union_id > 0 then
			if item.count >= 10 then
				local defs = {
					min = 1,
					max = math.min(15, item.count)
				}

				d_ms.d_data.createBatchUse(d_ms.d_mainUI.g_mainUI.main_layer, defs, sendUseItemRequest)
			else
				sendUseItemRequest()
			end
		else
			d_ms.d_info.show(d_ms.d_hz.gethz("contribution_need_union"))
		end
	elseif item.type_id == 1021 or item.type_id == 1022 or item.type_id == 1020 or item.type_id == 1023 or item.type_id == 1096 or item.type_id == 1036 or item.type_id == 1133 or item.type_id == 1132 or item.type_id == 1131 or item.type_id == 1130 then
		sendUseItemRequest()
	elseif item.type_id == 1002 then
		d_ms.d_inheritUI.showInheritLayer(g_packageUI.parent, 30)
	elseif item.type_id == 1003 then
		d_ms.d_forgeUI.show()
	elseif item.type_id == 1004 then
		if d_ms.d_mainUI.g_playerInfo.level < 8 then
			d_ms.d_info.show(d_ms.d_hz.gethz("canUseWorldMsg"))

			return
		end

		d_ms.d_newChatUI.show()
	elseif item.type_id == 1024 then
		if d_ms.d_mainUI.g_playerInfo.level < 16 then
			d_ms.d_info.show(d_ms.d_hz.gethz("canNotUseHyd"))

			return
		end

		d_ms.d_activityUI.show()
		d_ms.d_activityUI.backToCortCallUI()
	elseif item.csvInfo.base_experience_plus > 0 then
		if item.csvInfo.sub_type == d_ms.d_common_def.item_sub_type.exp_pill then
			if d_ms.d_mainUI.g_playerInfo.level < 65 then
				d_ms.d_info.show(string.format(d_ms.d_hz.gethz("abyss_tip6"), 65))

				return
			end

			d_ms.d_expbookUI.showExpbookLayer(g_packageUI.parent, 40, 2)
		elseif item.csvInfo.sub_type == d_ms.d_common_def.item_sub_type.roll then
			d_ms.d_expbookUI.showExpbookLayer(g_packageUI.parent, 40, 1)
		elseif item.csvInfo.sub_type == d_ms.d_common_def.item_sub_type.exp_drug then
			if d_ms.d_mainUI.g_playerInfo.level < 70 then
				d_ms.d_info.show(string.format(d_ms.d_hz.gethz("abyss_tip6"), 70))

				return
			end

			d_ms.d_yaoshendianUI.showExpDrugLayer(g_packageUI.parent)
		end
	elseif item.type_id == 1093 then
		if d_ms.d_stoneUI.canJoin(true) then
			d_ms.d_stoneUI.showStoneLayer(g_packageUI.parent, 40)
		end
	elseif item.type_id == 1095 then
		d_ms.d_qiankunnizhuan.show()
	elseif item.type_id == 1342 then
		local function getLimitLevel()
			d_ms.d_jpChangeUI.initCsvConfig()

			for m, n in pairs(d_ms.d_jpChangeUI.g_self.csv) do
				if n then
					return n.min_role_level
				end
			end
		end

		local limit_level = getLimitLevel() or 0

		if d_ms.d_mainUI.g_playerInfo.level < limit_level then
			d_ms.d_info.show(string.format(d_ms.d_hz.gethz("abyss_tip6"), limit_level))

			return
		end

		d_ms.d_jpChangeUI.show(g_packageUI.parent)
	elseif item.type_id == 1376 then
		d_ms.d_mxTransformUI.show(g_packageUI.parent)
	elseif item.type_id == 1100 then
		d_ms.d_equipTransUI.show()
	elseif item.csvInfo.mainType == m_t.compose_material then
		d_ms.d_equipPieceUI.show(g_packageUI.parent, item.type_id)
	elseif item.type_id == 1310 or item.type_id == 1311 or item.type_id == 1312 then
		showAdvance()
	elseif item.type_id == 1035 then
		-- Nothing
	elseif item.type_id == 1016 then
		-- Nothing
	elseif item.type_id <= 1440 and item.type_id >= 1431 then
		d_ms.d_treasureMapUI.requestUseTreasureMap(g_packageUI.parent, item.type_id)
	elseif item.type_id == 1363 then
		local defs = {
			min = 1,
			max = math.min(15, item.count)
		}

		d_ms.d_data.createBatchUse(d_ms.d_mainUI.g_mainUI.main_layer, defs, sendUseItemRequest)
	else
		cclog("play used other item")
	end
end

function getPropIDByTypeId(type_id)
	for i = 1, #g_propsTable do
		if g_propsTable[i].type_id == type_id and g_propsTable[i].count > 0 then
			return g_propsTable[i].id
		end
	end

	return 0
end

function onGetSaleResult(data_table)
	d_ms.d_info.show(d_ms.d_hz.gethz("getHZ") .. d_ms.d_hz.gethz("money") .. data_table.silver_count, 2)
	refreshPackage()
end

function getDateFormServer(msg_table)
	cclog("call getDateFormServer")
	d_ms.d_alert.stop_wait()

	for i = 1, #msg_table.attach_list do
		if msg_table.attach_list[i] ~= nil and msg_table.attach_list[i].star_level then
			cclog("")
		end
	end

	if msg_table.first_send == true then
		cclog("getDateFormServer:first_send is true")

		g_packageItemsInfo = {}
		g_packageItemsInfo = msg_table.attach_list
	elseif g_packageItemsInfo == nil then
		cclog("g_packageItemsInfo is nil request again")

		local tmp_req = {
			flag = -1
		}

		cclog("send ST_msg_query_cortege_list_1033 to BS.")
		d_ms.d_u.main_server_send_msg(d_ms.d_msg_def.gscl_msg_id.msg_query_cortege_list, tmp_req)

		return
	else
		cclog("get g_packageItemsInfo data")

		for i = 1, #msg_table.attach_list do
			g_packageItemsInfo[#g_packageItemsInfo + 1] = msg_table.attach_list[i]
		end
	end

	cclog("getDateFormServer1035 get data end")

	local next_event_type = d_ms.d_event_mgr.getNextPackageType()

	if next_event_type == 1035 then
		cclog("1035, next is 1035, go on...")

		g_isPackageSorted = false
	else
		sortItems()

		d_ms.d_event_mgr.g_next_msg_type = nil
	end

	cclog("getDateFormServer1035 end ")
end

function getAllProps()
	local itemPackage = g_reorgItemsInfo[o_t.item]
	g_propsTable = {}

	for i, v in pairs(m_t) do
		if m_t.talismans < v and v ~= m_t.stone and v ~= m_t.adaptive_spirit and v ~= m_t.fragment and v ~= m_t.ext_skill and v ~= m_t.summer_card and v ~= m_t.awaken_star and v ~= m_t.invisible_card and v ~= m_t.dan_bagua then
			local props = itemPackage[v]

			if props then
				for i = 1, #props do
					g_propsTable[#g_propsTable + 1] = props[i]
				end
			end
		end
	end

	table.sort(g_propsTable, sortProps)
end

function sortItems()
	cclog("in sortItems")

	local itemTable = g_packageItemsInfo

	if itemTable == nil then
		cclog("can use item table")

		return
	end

	g_reorgItemsInfo = {
		[o_t.item] = {},
		[o_t.skill] = {}
	}
	local attributeStr = nil
	g_usedItems = {
		{},
		{},
		{},
		{},
		{},
		{},
		{},
		{}
	}
	g_cheer_items = {
		{},
		{},
		{},
		{},
		{},
		{},
		{},
		{},
		{},
		{},
		{},
		{},
		{},
		{},
		{},
		{}
	}

	cclog("start get csvInfo")
	getPackageCSVConfig()
	getItembasePriceCSVConfig()
	getItemLevelPriceCSVConfig()
	cclog("end get csvInfo")
	cclog("start reorgItemsInfo")

	for i = 1, #itemTable do
		local object_type = itemTable[i].attach_type
		local type_id = itemTable[i].type_id

		if object_type == o_t.item then
			itemTable[i].csvInfo = g_itemAttrTable[type_id]
			local main_type = itemTable[i].csvInfo.mainType
			local reorgItemsInfo = g_reorgItemsInfo[object_type]

			if not reorgItemsInfo[main_type] then
				reorgItemsInfo[main_type] = {}
			end

			local itemsTableCount = #reorgItemsInfo[main_type]
			reorgItemsInfo[main_type][itemsTableCount + 1] = itemTable[i]
		elseif object_type == o_t.skill then
			itemTable[i].csvInfo = g_itemSkillTable[type_id]
			local reorgItemsInfo = g_reorgItemsInfo[object_type]
			local skillTableCount = #reorgItemsInfo
			reorgItemsInfo[skillTableCount + 1] = itemTable[i]
		end

		if itemTable[i].equip_order > 0 and itemTable[i].equip_order <= 8 then
			local order = itemTable[i].equip_order
			local usedItemTable = g_usedItems[order]
			local usedItem = {
				item = itemTable[i],
				index = i
			}
			usedItemTable[#usedItemTable + 1] = usedItem
		elseif itemTable[i].equip_order > 8 and itemTable[i].equip_order <= 24 then
			local order = itemTable[i].equip_order
			local usedItemTable = g_cheer_items[order - 8]
			usedItemTable[#usedItemTable + 1] = itemTable[i]
		end
	end

	cclog("end reorgItemsInfo")

	d_ms.d_lineupUI.g_displayLineupInfo.allUsedItems = g_usedItems

	cclog("start sort")
	sortPackage()
	cclog("end sort")
end

function sortProps(a, b)
	local orderA = a.csvInfo.sortOrder or 0
	local orderB = b.csvInfo.sortOrder or 0

	return orderA < orderB
end

function sortPackage()
	if g_reorgItemsInfo[o_t.item][m_t.weapon] then
		table.sort(g_reorgItemsInfo[o_t.item][m_t.weapon], packageSortFunc)
	end

	if g_reorgItemsInfo[o_t.item][m_t.guard] then
		table.sort(g_reorgItemsInfo[o_t.item][m_t.guard], packageSortFunc)
	end

	if g_reorgItemsInfo[o_t.item][m_t.talismans] then
		table.sort(g_reorgItemsInfo[o_t.item][m_t.talismans], packageSortFunc)
	end

	if g_reorgItemsInfo[o_t.item][m_t.stone] then
		table.sort(g_reorgItemsInfo[o_t.item][m_t.stone], stoneSort)
	end

	if g_reorgItemsInfo[o_t.skill] then
		table.sort(g_reorgItemsInfo[o_t.skill], skillSortFunc)
	end

	g_isPackageSorted = true
end

function stoneSort(a, b)
	if a.owner_id > 0 and b.owner_id == 0 then
		return true
	elseif a.owner_id == 0 and b.owner_id > 0 then
		return false
	elseif a.level == b.level then
		return a.csvInfo.sub_type < b.csvInfo.sub_type
	else
		return b.level < a.level
	end
end

function packageSortFunc(a, b)
	local isEquipA = a.equip_order > 0
	local isEquipB = b.equip_order > 0

	if isEquipA and not isEquipB then
		return true
	elseif not isEquipA and isEquipB then
		return false
	elseif a.csvInfo.quality == b.csvInfo.quality then
		if a.advance_level == b.advance_level then
			if a.level == b.level then
				return b.csvInfo.name < a.csvInfo.name
			else
				return b.level < a.level
			end
		else
			return b.advance_level < a.advance_level
		end
	else
		return b.csvInfo.quality < a.csvInfo.quality
	end
end

function skillSortFunc(a, b)
	local a_equip_o = a.equip_order
	local b_equip_o = b.equip_order

	if a_equip_o ~= b_equip_o then
		if a_equip_o == 0 then
			return false
		elseif b_equip_o == 0 then
			return true
		else
			return a_equip_o < b_equip_o
		end
	end

	if a.csvInfo.quality == b.csvInfo.quality then
		if a.level == b.level then
			if a.csvInfo.effectField == b.csvInfo.effectField then
				return b.csvInfo.name < a.csvInfo.name
			else
				return a.csvInfo.effectField < b.csvInfo.effectField
			end
		else
			return b.level < a.level
		end
	else
		return b.csvInfo.quality < a.csvInfo.quality
	end
end

function compareHZ(hz1, hz2)
	local len1 = string.len(hz1)
	local len2 = string.len(hz2)
	local byte1 = string.byte(hz1, len1)
	local byte2 = string.byte(hz2, len2)

	return byte1 - byte2
end

function findItemUser(item)
	if item.equip_order and item.equip_order > 0 then
		local owner = d_ms.d_lineupUI.g_usedCharacters[item.equip_order].character.csvInfo.name

		return owner
	end

	return " "
end

function getItemLevelPriceCSVConfig()
	if g_itemLevelPriceTable == nil then
		local item_level_tab_csv = d_ms.d_csv.open("csv_config/equip_enhance_cost.csv")
		g_itemLevelPriceTable = {}
		local item_level_tab = g_itemLevelPriceTable

		for i, v in pairs(item_level_tab_csv.records) do
			local level = tonumber(v[1])

			if not item_level_tab[level] then
				item_level_tab[level] = {}
			end

			local item_level = item_level_tab[level]
			item_level[1] = tonumber(v[2])
			item_level[2] = tonumber(v[3])
			item_level[3] = tonumber(v[4])
			item_level[4] = tonumber(v[5])
			item_level[5] = tonumber(v[6])
		end
	end
end

function getItembasePriceCSVConfig()
	if g_itemBasePriceTable == nil then
		local item_base_tab_csv = d_ms.d_csv.open("csv_config/item_sell_config.csv")
		g_itemBasePriceTable = {}
		local item_base_tab = g_itemBasePriceTable

		for i, v in pairs(item_base_tab_csv.records) do
			local quality = tonumber(v[1])

			if not item_base_tab[quality] then
				item_base_tab[quality] = {}
			end

			local item_base = item_base_tab[quality]
			item_base.base = tonumber(v[2])
			item_base.ratio = tonumber(v[3])
		end
	end
end

function getPackageCSVConfig()
	if g_itemAttrTable == nil then
		local itemHZ_tab_csv = d_ms.d_csv.open("csv_config/item_name.csv")
		local itemTableHZ = {}

		for i, v in pairs(itemHZ_tab_csv.records) do
			local id = tonumber(v[1])

			if not itemTableHZ[id] then
				itemTableHZ[id] = {}
			end

			local itemHZ = itemTableHZ[id]
			itemHZ.name = v[2]
			itemHZ.description = v[3]
			itemHZ.introduction = v[4]
			itemHZ.sortOrder = tonumber(v[5])
			itemHZ.product_desc = v[6] or ""
		end

		local item_attr_tab_csv = d_ms.d_csv.open("csv_config/item_base.csv")
		g_itemAttrTable = {}
		local item_attr_tab = g_itemAttrTable

		for i, v in pairs(item_attr_tab_csv.records) do
			local id = tonumber(v[1])

			if not item_attr_tab[id] then
				item_attr_tab[id] = {}
			end

			local item_attr = item_attr_tab[id]
			item_attr.name = itemTableHZ[id].name
			item_attr.sortOrder = itemTableHZ[id].sortOrder
			item_attr.file = v[2]
			item_attr.quality = tonumber(v[3])
			item_attr.mainType = tonumber(v[4])
			item_attr.sub_type = tonumber(v[5])
			item_attr.top_level = tonumber(v[6])
			item_attr.isStackable = tonumber(v[7])
			item_attr.equipPos = tonumber(v[8])
			item_attr.effectField = tonumber(v[9])
			item_attr.base_gongji_plus = tonumber(v[10])
			item_attr.base_fangyu_plus = tonumber(v[11])
			item_attr.base_maxhp_plus = tonumber(v[12])
			item_attr.base_strength_plus = tonumber(v[13])
			item_attr.base_energy_plus = tonumber(v[14])
			item_attr.base_top_fight_count_plus = tonumber(v[15])
			item_attr.base_experience_plus = tonumber(v[16])
			item_attr.script_id = tonumber(v[17])
			item_attr.effect_plus = tonumber(v[18])
			item_attr.ownerType = tonumber(v[19])
			item_attr.random_weight = tonumber(v[20])
			item_attr.use_limit = tonumber(v[21])
			item_attr.show_level = tonumber(v[22])
			item_attr.base_contrib_plus = tonumber(v[23])
			item_attr.introduction = itemTableHZ[id].introduction
			item_attr.description = itemTableHZ[id].description
			item_attr.product_desc = itemTableHZ[id].product_desc

			if id > 10000 and id < 10300 and item_attr.mainType == 15 then
				item_attr.ext_skill_desc = getExtSkillDesc(id)
			end

			if m_t.talismans < item_attr.mainType and item_attr.mainType ~= m_t.stone then
				item_attr.packageTag = packageTagDef.props
			elseif item_attr.mainType == m_t.stone then
				item_attr.packageTag = packageTagDef.stone
			else
				item_attr.packageTag = item_attr.mainType
			end
		end
	end

	if g_itemSkillTable == nil then
		local skillHZ_tab_csv = d_ms.d_csv.open("csv_config/skill_name.csv")
		local skillTableHZ = {}

		for i, v in pairs(skillHZ_tab_csv.records) do
			local id = tonumber(v[1])

			if not skillTableHZ[id] then
				skillTableHZ[id] = {}
			end

			local skillHZ = skillTableHZ[id]
			skillHZ.name = v[2]
			skillHZ.description = v[3]
			skillHZ.introduction = v[4]
			skillHZ.product_desc = v[5] or ""
		end

		local skill_attr_tab_csv = d_ms.d_csv.open("csv_config/skill_base.csv")
		g_itemSkillTable = {}
		local skill_attr_tab = g_itemSkillTable

		for i, v in pairs(skill_attr_tab_csv.records) do
			local id = tonumber(v[1])

			if not skill_attr_tab[id] then
				skill_attr_tab[id] = {}
			end

			local skill_attr = skill_attr_tab[id]
			skill_attr.name = skillTableHZ[id].name
			skill_attr.file = v[2]
			skill_attr.quality = tonumber(v[3])
			skill_attr.formula_id = tonumber(v[4])
			skill_attr.formula_id_ext = tonumber(v[5])
			skill_attr.skillType = tonumber(v[6])
			skill_attr.attackType = tonumber(v[7])
			skill_attr.effectField = tonumber(v[8])
			skill_attr.base_gongji_plus = tonumber(v[9])
			skill_attr.base_fangyu_plus = tonumber(v[10])
			skill_attr.base_maxmagic_plus = tonumber(v[11])
			skill_attr.base_intensity = tonumber(v[12])
			skill_attr.hp_plus = tonumber(v[13])
			skill_attr.effect_plus = tonumber(v[14])
			skill_attr.startLevel = tonumber(v[15])
			skill_attr.highestLevel = tonumber(v[16])
			skill_attr.procRate = tonumber(v[17])
			skill_attr.description = skillTableHZ[id].description
			skill_attr.introduction = skillTableHZ[id].introduction
			skill_attr.product_desc = skillTableHZ[id].product_desc
			skill_attr.packageTag = packageTagDef.skill
		end
	end
end

g_ext_skill_desc = nil

function initExtSkillDesc()
	local csv = d_ms.d_csv.open2("csv_config/ext_skill.csv")
	g_ext_skill_desc = {}

	for k, v in pairs(csv) do
		if #v.id > 0 then
			local t_id = tonumber(v.id)
			local PARAM_COUNT_MAX = 5
			local MAX_LV = d_ms.d_jpmkUI.MAX_LV
			local params = {}

			for i = 1, PARAM_COUNT_MAX do
				params[i] = {}
			end

			local canshu_table = d_ms.d_str.split(v.parameter, "/")

			for i = 1, #canshu_table do
				local level_ = d_ms.d_str.split(canshu_table[i], "|")

				for j = 1, #level_ do
					params[i][j] = level_[j]
				end
			end

			local desc = {}

			for i = 1, MAX_LV do
				desc[i] = string.format(v.introduction, params[1][i] or "", params[2][i] or "", params[3][i] or "", params[4][i] or "", params[5][i] or "")
			end

			g_ext_skill_desc[t_id] = desc
		end
	end
end

function getExtSkillDesc(id)
	if not g_ext_skill_desc then
		initExtSkillDesc()
	end

	return g_ext_skill_desc[id] or {}
end

function getItemInfoByTypeId(type_id)
	for i, v in pairs(g_packageItemsInfo) do
		if v.type_id == type_id then
			return v
		end
	end

	return nil
end
