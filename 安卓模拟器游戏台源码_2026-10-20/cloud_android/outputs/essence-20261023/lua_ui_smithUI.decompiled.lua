local require = require
local bits = bits
local sqlite = sqlite
local type = type
local print = print
local tostring = tostring
local pairs = pairs
local ipairs = ipairs
local string = string
local table = table
local math = math
local main_server = main_server
local _G = _G
local bits = bits
local tonumber = tonumber
local os = os
local io = io
local tolua = tolua
local ccp = ccp
local ccc4 = ccc4
local ccc3 = ccc3
local class = class
local CCArray = CCArray
local CCDirector = CCDirector
local CCLayer = CCLayer
local CCMenu = CCMenu
local CCMenuItemImage = CCMenuItemImage
local CCSprite = CCSprite
local CCScene = CCScene
local CCLayerColor = CCLayerColor
local CCMenuItemSprite = CCMenuItemSprite
local CCMenuItemImage = CCMenuItemImage
local CCRectMake = CCRectMake
local CCPointMake = CCPointMake
local CCMenuItemFont = CCMenuItemFont
local CCLuaLog = CCLuaLog
local CCFileUtils = CCFileUtils
local CCSizeMake = CCSizeMake
local CCScrollView = CCScrollView
local CCNode = CCNode

module("ui.smithUI")

d_ms = require("ms")

if not d_ms then
	CCLuaLog("Lua : smithUI >> smithUI load d_ms fail.")
end

local function cclog(...)
	CCLuaLog(string.format("Lua : smithUI >>%s", string.format(...)))
end

local o_t = d_ms.d_common_def.object_type
local m_t = d_ms.d_common_def.item_main_type
local dMainUI = d_ms.d_mainUI
local scrSize = CCDirector:sharedDirector():getVisibleSize()
local m_t_t = d_ms.d_common_def.material_transform_type
g_smithUI = {}
g_self = {
	Tag = {
		Info = 1,
		Material = 3,
		Choose = 2
	},
	xs = {
		0.41796875,
		0.7875,
		0.33203125,
		0.78125
	},
	ys = {
		0.6361111111111111,
		0.4861111111111111,
		0.4097222222222222,
		0.3333333333333333,
		0.24305555555555555
	},
	Color = {
		gray = {
			135,
			113,
			100
		},
		purple = {
			188,
			35,
			81
		},
		brown = {
			160,
			120,
			89
		},
		green = {
			100,
			255,
			100
		},
		red = {
			255,
			100,
			100
		},
		paper = {
			215,
			171,
			146
		}
	},
	MaxCompose = 100
}

function show(transInfo)
	local main_layer = dMainUI.g_mainUI.main_layer
	local childBoard = main_layer:getChildByTag(d_ms.d_mainUI.boardID.smith)

	if childBoard then
		return
	end

	local player = d_ms.d_mainUI.g_playerInfo
	local board_layer = CCLayer:create()

	main_layer:addChild(board_layer, 5)
	board_layer:setTag(d_ms.d_mainUI.boardID.smith)

	dMainUI.g_boardlayer[dMainUI.boardID.smith] = board_layer
	g_smithUI.board_layer = board_layer
	g_smithUI.main_layer = main_layer

	local function sceneEventHandler(eventType)
		if eventType.name == "exit" then
			g_smithUI = {}
		end
	end

	board_layer:registerScriptHandler(sceneEventHandler)

	local position = {
		x = 0.5,
		y = 0.56
	}
	local scaleXY = {
		scaleY = 0.8,
		scaleX = 0.95
	}
	g_smithUI.board_size = d_ms.d_mainUI.createBoardBkg(board_layer, position, scaleXY, false)
	local xs = g_self.xs
	local ys = g_self.ys
	local item_menu_list = {
		{
			npic = "v2/smithUI/menu11.png",
			disPic = "v2/smithUI/menu12.png",
			y = 0.85,
			tag = 1,
			x = 0.12,
			call_back = categoryPressed
		},
		{
			npic = "v2/smithUI/menu21.png",
			disPic = "v2/smithUI/menu22.png",
			y = 0.7,
			tag = 2,
			x = 0.12,
			call_back = categoryPressed
		},
		{
			npic = "v2/handbook/unsee.png",
			spic = "v2/handbook/unsee.png",
			x = xs[1],
			y = ys[1],
			call_back = showChooseLayer
		},
		{
			npic = "v2/handbook/unsee.png",
			spic = "v2/handbook/unsee.png",
			x = xs[2],
			y = ys[1],
			call_back = showTargetMaterialInfo
		},
		x = 0,
		y = 0
	}
	g_smithUI.Buttons = {}

	board_layer:addChild(d_ms.d_u.createMenu(item_menu_list, g_smithUI.Buttons, true), 5)

	local bkg = d_ms.d_u.createByStyles({
		pic = "v2/smithUI/bkg.png",
		x = 0.5 * (xs[1] + xs[2]),
		y = ys[1],
		anchor = {
			0.5,
			0.54
		}
	})

	board_layer:addChild(bkg)
	board_layer:addChild(d_ms.d_u.createByStyles({
		pic = "v2/smithUI/left_name_bkg.png",
		x = xs[1],
		y = ys[2]
	}))
	board_layer:addChild(d_ms.d_u.createByStyles({
		pic = "v2/smithUI/right_name_bkg.png",
		x = xs[2],
		y = ys[2]
	}))
	board_layer:addChild(d_ms.d_u.createByStyles({
		pic = "v2/smithUI/tip_bkg.png",
		x = 0.5 * (xs[1] + xs[2]),
		y = ys[4]
	}))
	d_ms.d_mainUI.showBoard(board_layer)

	dMainUI.g_currentBoard = dMainUI.boardID.smith

	dMainUI.g_mainUI.player_layer:setVisible(false)

	if dMainUI.g_mainUI.menu_other_layer ~= nil then
		dMainUI.g_mainUI.main_layer:removeChild(dMainUI.g_mainUI.menu_other_layer, true)

		dMainUI.g_mainUI.menu_other_layer = nil
	end

	if transInfo then
		g_smithUI.transInfo = transInfo

		categoryPressed(g_self.MaxCompose < transInfo.category and 2 or 1, true)
	else
		categoryPressed(1, true)
	end
end

function categoryPressed(tag, isFirstTime)
	local btns = g_smithUI.Buttons

	if not btns then
		return
	end

	if g_smithUI.curCategory then
		btns[g_smithUI.curCategory]:setEnabled(true)
	end

	btns[tag]:setEnabled(false)

	g_smithUI.curCategory = tag

	if not isFirstTime then
		g_smithUI.transInfo = nil
	end

	showConvertInfo()
end

function showConvertInfo()
	local layer = d_ms.d_u.clearLayer(g_smithUI.board_layer, 10, g_self.Tag.Info)

	if not layer then
		return
	end

	local transInfo = g_smithUI.transInfo
	local xs = g_self.xs
	local ys = g_self.ys
	local tip_left = d_ms.d_u.createByStyles({
		font = "arial",
		type = "label",
		fontsize = 26,
		x = xs[3],
		y = ys[4],
		anchor = {
			1,
			0.5
		},
		string = d_ms.d_hz.gethz("tip_hz") .. ": ",
		color = g_self.Color.brown
	})
	local tip_right = d_ms.d_u.createByStyles({
		font = "arial",
		type = "label",
		fontsize = 22,
		x = xs[3],
		y = ys[4],
		anchor = {
			0,
			0.5
		},
		string = transInfo and transInfo.desc or d_ms.d_hz.gethz("smith2"),
		color = g_self.Color.gray
	})

	layer:addChild(tip_left)
	layer:addChild(tip_right)

	local menu_btn_list = {
		{
			tag = 1,
			x = xs[1],
			y = ys[5],
			npic = "v2/smithUI/btn" .. g_smithUI.curCategory .. "_1_" .. "1.png",
			spic = "v2/smithUI/btn" .. g_smithUI.curCategory .. "_1_" .. "2.png",
			call_back = pressConvert
		},
		{
			tag = 10,
			x = xs[2],
			y = ys[5],
			npic = "v2/smithUI/btn" .. g_smithUI.curCategory .. "_10_" .. "1.png",
			spic = "v2/smithUI/btn" .. g_smithUI.curCategory .. "_10_" .. "2.png",
			call_back = pressConvert
		},
		x = 0,
		y = 0
	}

	layer:addChild(d_ms.d_u.createMenu(menu_btn_list), 1)

	if not transInfo then
		return
	end

	local need_silver = transInfo.cost_material[1].attach_count
	local own_silver = d_ms.d_mainUI.g_playerInfo.silver_coin
	local countColor = need_silver <= own_silver and g_self.Color.green or g_self.Color.red
	local silverLabel = d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		fontsize = 22,
		string = " " .. need_silver .. "/" .. own_silver,
		color = countColor
	})
	local silver_icon = CCSprite:create("v2/money_silver.png")
	local consumeLabel = d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		fontsize = 26,
		string = d_ms.d_hz.gethz("consumeHZ") .. ": ",
		color = g_self.Color.brown
	})

	d_ms.d_u.layoutSprites({
		consumeLabel,
		silver_icon,
		silverLabel
	}, {
		x = xs[4],
		y = ys[4]
	})
	layer:addChild(consumeLabel)
	layer:addChild(silver_icon)
	layer:addChild(silverLabel)

	local itemCsvInfo = nil
	local src_material = transInfo.src_material
	itemCsvInfo = d_ms.d_packageUI.g_itemAttrTable[src_material.attach_type]
	local icon = d_ms.d_data.getCertainSmallSprite(src_material.object_type, src_material.attach_type)

	d_ms.d_u.setStyles(icon, {
		scale = 0.11,
		x = xs[1],
		y = ys[1]
	})
	layer:addChild(icon)

	local own = getMaterialCount(src_material.object_type, src_material.attach_type)
	local countLabelLeft = d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		fontsize = 26,
		string = d_ms.d_hz.gethz("soul_ex_str3"),
		color = g_self.Color.paper
	})
	local countLabel = d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		fontsize = 22,
		string = own,
		color = g_self.Color.paper
	})

	d_ms.d_u.layoutSprites({
		countLabelLeft,
		countLabel
	}, {
		x = xs[1],
		y = ys[3]
	})
	layer:addChild(countLabelLeft)
	layer:addChild(countLabel)

	local nameColor = src_material.attach_count <= own and g_self.Color.green or g_self.Color.red
	local nameLabel1 = d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		fontsize = 26,
		string = itemCsvInfo.name,
		color = {
			223,
			187,
			39
		}
	})
	local nameLabel2 = d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		fontsize = 26,
		string = "X" .. src_material.attach_count,
		color = nameColor
	})

	layer:addChild(nameLabel1)
	layer:addChild(nameLabel2)
	d_ms.d_u.layoutSprites({
		nameLabel1,
		nameLabel2
	}, {
		x = xs[1],
		y = ys[2]
	})

	local des_material = transInfo.des_material

	if transInfo.is_random then
		des_material = des_material[1]
		local nameStr = nil

		if des_material.object_type == o_t.item then
			itemCsvInfo = d_ms.d_packageUI.g_itemAttrTable[des_material.attach_type]

			if itemCsvInfo.mainType == m_t.ext_skill then
				nameStr = string.format(d_ms.d_hz.gethz("smith11"), d_ms.d_hz.gethz("qColor" .. itemCsvInfo.quality), d_ms.d_hz.gethz("mainType" .. itemCsvInfo.mainType .. "HZ"))
			else
				nameStr = string.format(d_ms.d_hz.gethz("smith1"), d_ms.d_equipAdvanceUI.getNumHZ(itemCsvInfo.quality), d_ms.d_hz.gethz("mainType" .. itemCsvInfo.mainType .. "HZ"))
			end
		else
			itemCsvInfo = d_ms.d_packageUI.g_itemSkillTable[des_material.attach_type]
			nameStr = string.format(d_ms.d_hz.gethz("smith1"), d_ms.d_equipAdvanceUI.getNumHZ(itemCsvInfo.quality), d_ms.d_hz.gethz("smith7"))
		end

		local nameLabel = d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			fontsize = 26,
			string = nameStr,
			x = xs[2],
			y = ys[2],
			color = g_self.Color.purple
		})

		layer:addChild(nameLabel)
	else
		itemCsvInfo = d_ms.d_packageUI.g_itemAttrTable[des_material.attach_type]
		icon = d_ms.d_data.getCertainSmallSprite(des_material.object_type, des_material.attach_type)

		d_ms.d_u.setStyles(icon, {
			scale = 0.11,
			x = xs[2],
			y = ys[1]
		})
		layer:addChild(icon)

		if itemCsvInfo.isStackable == 0 then
			nameStr = itemCsvInfo.name
		else
			nameStr = itemCsvInfo.name .. "X" .. des_material.attach_count
		end

		nameLabel = d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			fontsize = 26,
			string = nameStr,
			x = xs[2],
			y = ys[2],
			color = g_self.Color.purple
		})

		layer:addChild(nameLabel)

		if itemCsvInfo.isStackable ~= 0 then
			own = getMaterialCount(des_material.object_type, des_material.attach_type)
			countLabelLeft = d_ms.d_u.createByStyle({
				font = "arial",
				type = "label",
				fontsize = 26,
				string = d_ms.d_hz.gethz("soul_ex_str3"),
				color = g_self.Color.paper
			})
			countLabel = d_ms.d_u.createByStyle({
				font = "arial",
				type = "label",
				fontsize = 22,
				string = own,
				color = g_self.Color.paper
			})

			d_ms.d_u.layoutSprites({
				countLabelLeft,
				countLabel
			}, {
				x = xs[2],
				y = ys[3]
			})
			layer:addChild(countLabelLeft)
			layer:addChild(countLabel)
		end
	end
end

function closeChooseLayer()
	if not g_smithUI.board_layer then
		return
	end

	g_smithUI.board_layer:removeChildByTag(g_self.Tag.Choose, true)
end

function showChooseLayer()
	local typeOffset = g_smithUI.curCategory == 2 and 100 or 0
	local layer = d_ms.d_u.clearLayer(g_smithUI.board_layer, 20, g_self.Tag.Choose)

	if not layer then
		return
	end

	d_ms.d_u.createSwallowTouchLayer(layer)

	local colorLayer = CCLayerColor:create(ccc4(0, 0, 0, 180))

	layer:addChild(colorLayer, -1)

	local bkg = d_ms.d_u.createByStyles({
		pic = "v2/smithUI/choose_bkg.png",
		x = 0.5,
		y = 0.56
	})

	layer:addChild(bkg)

	local w, h = d_ms.d_u.getRealScale(bkg)
	g_smithUI.curChooseType = typeOffset + 1
	local touchArea = {
		x = (0.5 - 0.467 * w) * scrSize.width,
		y = (0.56 - 0.42 * h) * scrSize.height,
		width = 0.279 * w * scrSize.width,
		height = 0.848 * h * scrSize.height
	}
	local cellSize = CCSizeMake(touchArea.width, 0.2 * touchArea.height)
	local categoryTableView = d_ms.d_tableView.tableView(layer, touchArea)

	if not g_self.categoryHZ then
		g_self.categoryHZ = {
			{
				d_ms.d_hz.gethz("mainType1HZ"),
				d_ms.d_hz.gethz("mainType2HZ"),
				d_ms.d_hz.gethz("mainType3HZ"),
				d_ms.d_hz.gethz("smith3"),
				d_ms.d_hz.gethz("smith4"),
				d_ms.d_hz.gethz("smith6"),
				d_ms.d_hz.gethz("smith8")
			},
			{
				d_ms.d_hz.gethz("smith3"),
				d_ms.d_hz.gethz("smith9"),
				d_ms.d_hz.gethz("smith10")
			}
		}
	end

	local dataSource = getCategoryDataSource(g_self.categoryHZ[g_smithUI.curCategory], cellSize)

	categoryTableView:startScroll()
	categoryTableView:setDataSource(dataSource)

	if not g_self.touchArea2 then
		g_self.touchArea2 = {
			x = (0.5 - 0.167 * w) * scrSize.width,
			y = (0.56 - 0.425 * h) * scrSize.height,
			width = 0.631 * w * scrSize.width,
			height = 0.854 * h * scrSize.height
		}
	end

	local function changeCategory(index)
		if g_smithUI.curChooseType ~= index then
			g_smithUI.curChooseType = index + typeOffset

			categoryTableView:reloadData()
			showMaterials()
		end
	end

	local delegate = {
		touchCellAtIndex = changeCategory
	}

	categoryTableView:setDelegate(delegate)

	local menu_btn_list = {
		{
			npic = "v2/introUI/close1.png",
			spic = "v2/introUI/close2.png",
			x = 0.48 * w,
			y = 0.45 * h,
			call_back = closeChooseLayer
		},
		x = 0.5,
		y = 0.56
	}

	layer:addChild(d_ms.d_u.createMenu(menu_btn_list), 10)
	showMaterials()
end

function showMaterials()
	if not g_smithUI.board_layer or not g_smithUI.curChooseType then
		return
	end

	local layer = g_smithUI.board_layer:getChildByTag(g_self.Tag.Choose)

	if not layer then
		return
	end

	layer = d_ms.d_u.clearLayer(layer, 20, g_self.Tag.Material)
	local items = getAvailableMaterials(g_smithUI.curChooseType)

	if #items == 0 then
		return
	end

	local materialTableView = d_ms.d_tableView.tableView(layer, g_self.touchArea2)
	local cellSize = CCSizeMake(g_self.touchArea2.width, 0.3 * g_self.touchArea2.height)
	local dataSource = getMaterialDataSource(items, cellSize)

	materialTableView:startScroll()
	materialTableView:setDataSource(dataSource)
end

function getAvailableMaterials(category)
	local list = d_ms.d_data.g_materialTable[category]
	local result = {}

	if list then
		local itemInfo, item = nil

		for i = 1, #list do
			itemInfo = list[i].src_material
			item = getItemInfoByType(itemInfo.object_type, itemInfo.attach_type)

			if item then
				table.insert(result, item)
			end
		end
	end

	return result
end

function showTargetMaterialInfo()
	if not g_smithUI.main_layer or not g_smithUI.transInfo or g_smithUI.transInfo.is_random then
		return
	end

	d_ms.d_data.showItemIntro(g_smithUI.board_layer, g_smithUI.transInfo.des_material)
end

function onGetResult(msg_table)
	if msg_table.result == 1 then
		if msg_table.flag == m_t_t.equip_transform then
			d_ms.d_cortegeRecycleUI.onGetEquipRecycle(msg_table)
		else
			local layer = g_smithUI.board_layer

			if not layer then
				return
			end

			if msg_table.flag == m_t_t.spirit_transform then
				local sLayer = d_ms.d_u.createSwallowTouchLayer(layer)

				local function showPrize()
					d_ms.d_commonLayerUI.showPrizeResLayer(layer, msg_table.item_list, showConvertInfo)
					layer:removeChild(sLayer, true)
				end

				local function nextAnimation()
					d_ms.d_u.createAnimation_new("266_2.ccbi", {
						scale = 1,
						z = 100,
						x = g_self.xs[2] + 0.01,
						y = g_self.ys[1] + 0.01
					}, 1, showPrize, layer)
				end

				d_ms.d_u.createAnimation_new("266_1.ccbi", {
					scale = 1,
					z = 100,
					x = g_self.xs[1],
					y = g_self.ys[1]
				}, 2, nextAnimation, layer)
			else
				showConvertInfo()
				d_ms.d_u.createAnimation_new("302_1.ccbi", {
					scale = 1.25,
					z = 100,
					x = 0.5 * (g_self.xs[1] + g_self.xs[2]) / 1.25,
					y = (g_self.ys[1] - 0.125) / 1.25
				}, 2, nil, layer)
			end
		end
	end
end

function pressConvert(tag)
	local transInfo = g_smithUI.transInfo

	if not transInfo then
		d_ms.d_info.show(d_ms.d_hz.gethz("smith2"))

		return
	end

	if tag <= 0 then
		return
	end

	local need = {
		transInfo.src_material
	}

	for k, v in pairs(transInfo.cost_material) do
		need[k + 1] = v
	end

	for i = 1, #need do
		local item = need[i]
		local own = 0
		local tip = nil

		if item.object_type == o_t.gold_coin then
			own = d_ms.d_mainUI.g_playerInfo.gold_coin
			tip = d_ms.d_hz.gethz("shop_gold_not_enough")
		elseif item.object_type == o_t.silver_coin then
			own = d_ms.d_mainUI.g_playerInfo.silver_coin
			tip = d_ms.d_hz.gethz("noMoney")
		else
			own = getMaterialCount(item.object_type, item.attach_type)
		end

		if own < item.attach_count * tag then
			tip = tip or d_ms.d_hz.gethz("notEnough") .. d_ms.d_packageUI.g_itemAttrTable[item.attach_type].name

			d_ms.d_info.show(tip)

			return
		end
	end

	local src = getItemInfoByType(transInfo.src_material.object_type, transInfo.src_material.attach_type)
	local tmp_req = {
		flag = transInfo.is_random and m_t_t.spirit_transform or m_t_t.spar_transform,
		id_list = {
			{
				id = src.id
			}
		},
		count = 1,
		num = tag
	}

	d_ms.d_u.main_server_send_msg(d_ms.d_msg_def.gscl_msg_id.msg_material_transform, tmp_req)
end

function createMaterialCell(parent, itemInfo, bkgPic, cellSize)
	d_ms.d_createCell.createCommonItemCells(parent, itemInfo, bkgPic, cellSize)

	local function changeMaterial()
		closeChooseLayer()

		g_smithUI.transInfo = d_ms.d_data.g_convertTable[itemInfo.type_id]

		showConvertInfo()
	end

	local changeButtonItem = CCMenuItemImage:create("v2/introUI/choose1.png", "v2/introUI/choose2.png")

	changeButtonItem:setPosition(cellSize.width * 0.8, cellSize.height * 0.5)
	changeButtonItem:registerScriptTapHandler(changeMaterial)

	local changeMenu = CCMenu:createWithItem(changeButtonItem)

	changeMenu:setPosition(0, 0)
	parent:addChild(changeMenu, 5)
end

function getMaterialDataSource(list, cellSize)
	local bkgPic = "v2/smithUI/cell_bkg.png"
	local dataSource = {}
	local num = #list

	function dataSource.tableViewNumberOfRows()
		return num
	end

	function dataSource.drawCellAtIndex(index)
		local cell = CCNode:create()

		if list[index] then
			createMaterialCell(cell, list[index], bkgPic, cellSize)
		end

		return cell
	end

	function dataSource.heightForRowAtIndex(index)
		return cellSize.height
	end

	return dataSource
end

function createCategoryCell(parent, index, name, cellSize)
	local fontColor = {
		255,
		156,
		0
	}
	local bkg = "v2/actNoticeUI/btn1.png"

	if g_smithUI.curChooseType == index or g_smithUI.curChooseType == index + g_self.MaxCompose then
		fontColor = {
			242,
			202,
			166
		}
		bkg = "v2/actNoticeUI/btn3.png"
	end

	local nameLabel = d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		fontsize = 30,
		string = name,
		color = fontColor
	})

	nameLabel:setPosition(cellSize.width * 0.5, cellSize.height * 0.5)
	parent:addChild(nameLabel, 2)

	local bkgPic = CCSprite:create(bkg)

	bkgPic:setPosition(cellSize.width * 0.5, cellSize.height * 0.5)
	parent:addChild(bkgPic)

	local size = bkgPic:getContentSize()

	bkgPic:setScaleX(cellSize.width / size.width)
	bkgPic:setScaleY(cellSize.height / size.height)
end

function getCategoryDataSource(list, cellSize)
	local dataSource = {}
	local num = #list

	function dataSource.tableViewNumberOfRows()
		return num
	end

	function dataSource.drawCellAtIndex(index)
		local cell = CCNode:create()

		createCategoryCell(cell, index, list[index], cellSize)

		return cell
	end

	function dataSource.heightForRowAtIndex(index)
		return cellSize.height
	end

	return dataSource
end

function getMaterialCount(object_type, attach_type)
	local item = getItemInfoByType(object_type, attach_type)

	if item then
		return item.count
	else
		return 0
	end
end

function getItemInfoByType(object_type, attach_type)
	local info = d_ms.d_data.getCertainInfo(object_type, attach_type)
	local thePackage = d_ms.d_packageUI.g_reorgItemsInfo[object_type][info.mainType]

	if thePackage then
		if info.mainType == m_t.ext_skill then
			for _, v in pairs(thePackage) do
				if v.type_id == attach_type and v.owner_id == 0 then
					return v
				end
			end
		else
			for _, v in pairs(thePackage) do
				if v.type_id == attach_type then
					return v
				end
			end
		end
	end
end
