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
local ccp = ccp
local package = package
local main_server = main_server
local _G = _G
local bits = bits
local tonumber = tonumber
local os = os
local io = io
local tolua = tolua
local ccc4 = ccc4
local ccc3 = ccc3
local ccpAdd = ccpAdd
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
local CCMenuItemFont = CCMenuItemFont
local kCCMenuHandlerPriority = kCCMenuHandlerPriority
local CCSpawn = CCSpawn
local CCLuaLog = CCLuaLog
local CCFileUtils = CCFileUtils
local CCVerticalTextAlignment = CCVerticalTextAlignment
local CCSizeMake = CCSizeMake
local CCScrollView = CCScrollView
local CCTargetedAction = CCTargetedAction
local CCNode = CCNode
local CCLabelTTF = CCLabelTTF
local kCCTextAlignmentLeft = kCCTextAlignmentLeft

module("ui.stoneUI")

d_ms = require("ms")

if not d_ms then
	CCLuaLog("stoneUI load d_ms fail.\n")
end

local function cclog(...)
	CCLuaLog(string.format("Lua : stoneUI >>%s", string.format(...)))
end

o_t = d_ms.d_common_def.object_type
m_t = d_ms.d_common_def.item_main_type
resultTab = d_ms.d_common_def.stone_event_type
resultType = d_ms.d_common_def.stone_result_type
g_stoneUI = {}
g_self = {
	isOpen = true,
	Lvlimit = 10,
	DrillMaterial = {
		type_id = 1093
	},
	StoneTypeID = {
		1090,
		1091,
		1092
	},
	Slots = {
		1,
		1,
		1,
		2,
		3
	},
	btnPicsList = {
		choose = {
			"v2/introUI/choose1.png",
			"v2/introUI/choose2.png"
		},
		change = {
			"v2/introUI/change1.png",
			"v2/introUI/change2.png"
		}
	}
}

function canJoin(isShowMsg)
	if not g_self.isOpen then
		if isShowMsg then
			d_ms.d_info.show(d_ms.d_hz.gethz("tmp_not_open"), 2)
		end

		return false
	end

	if d_ms.d_mainUI.g_playerInfo.level < g_self.Lvlimit then
		if isShowMsg then
			d_ms.d_info.show(string.format(d_ms.d_hz.gethz("stone_lv_limit"), g_self.Lvlimit), 2)
		end

		return false
	else
		return true
	end
end

function onEquipChanged(equipInfo)
	g_stoneUI.equipInfo = equipInfo

	refreshFrame()
end

function pressChooseEquip()
	local allEquips, btnPics = nil

	if g_stoneUI.equipInfo then
		btnPics = g_self.btnPicsList.change
		allEquips = getAllEquipsExcept(g_stoneUI.equipInfo.id)
	else
		btnPics = g_self.btnPicsList.choose
		allEquips = getAllEquipsExcept()
	end

	local layer = CCLayer:create()

	g_stoneUI.main_layer:addChild(layer, 200)
	d_ms.d_u.createSwallowTouchLayer(layer)

	local bkg_small = CCSprite:create("v2/common/frame3.png")

	d_ms.d_u.setStyles(bkg_small, {
		scaleY = 0.95,
		scaleX = 0.54,
		x = 0.5,
		y = 0.5
	})
	layer:addChild(bkg_small)

	local function call_back_close()
		d_ms.d_u.remove(layer)
	end

	local item_menu_list = {
		{
			npic = "v2/introUI/close1.png",
			spic = "v2/introUI/close2.png",
			y = 0.97,
			x = 0.77,
			call_back = call_back_close
		},
		x = 0,
		y = 0
	}

	layer:addChild(d_ms.d_u.createMenu(item_menu_list), 10)

	local function equipSelected(tag)
		onEquipChanged(allEquips[tag])
	end

	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local touchArea = {
		x = 0.25 * scrSize.width,
		y = 0.05 * scrSize.height,
		width = 0.5 * scrSize.width,
		height = 0.9 * scrSize.height
	}
	local slotTableView = d_ms.d_tableView.tableView(layer, touchArea)
	local cellSize = CCSizeMake(0.5 * scrSize.width, 0.2 * scrSize.height)
	local dataSource = getEquipDataSource(allEquips, btnPics, cellSize)

	slotTableView:startScroll()
	slotTableView:setDataSource(dataSource)
end

function pressStoneUpgrade(tag)
	local equipInfo = g_stoneUI.equipInfo
	local stone = getStoneByOwner(equipInfo.id, tag)

	if d_ms.d_stoneUpgradeUI.canUpgrade(stone, true) then
		d_ms.d_stoneUpgradeUI.show(g_stoneUI.main_layer, 200, stone)
	end
end

function pressStoneAsc(tag)
	local equipInfo = g_stoneUI.equipInfo
	local stone = getStoneByOwner(equipInfo.id, tag)

	d_ms.d_stoneCastUI.pressCast(g_stoneUI.main_layer, stone)
end

function pressChooseStone(tag)
	local stoneIndex = tag
	local typicalStones = getUnusedStoneByType(g_stoneUI.stone_type_id)

	if #typicalStones == 0 then
		d_ms.d_info.show(d_ms.d_hz.gethz("no_unused_stone"), 2)

		return
	end

	local layer = CCLayer:create()

	g_stoneUI.main_layer:addChild(layer, 200)
	d_ms.d_u.createSwallowTouchLayer(layer)

	local bkg_small = CCSprite:create("v2/common/frame3.png")

	d_ms.d_u.setStyles(bkg_small, {
		scaleY = 0.95,
		scaleX = 0.54,
		x = 0.5,
		y = 0.5
	})
	layer:addChild(bkg_small)

	local function call_back_close()
		d_ms.d_u.remove(layer)
	end

	local item_menu_list = {
		{
			npic = "v2/introUI/close1.png",
			spic = "v2/introUI/close2.png",
			y = 0.97,
			x = 0.77,
			call_back = call_back_close
		},
		x = 0,
		y = 0
	}

	layer:addChild(d_ms.d_u.createMenu(item_menu_list), 10)

	local rect_bkg_small = d_ms.d_u.ccRectMake(0.25, 0.04999999999999999, 0.5, 0.9)
	local frame_size = {
		x = rect_bkg_small.origin.x,
		y = rect_bkg_small.origin.y,
		width = rect_bkg_small.size.width,
		height = rect_bkg_small.size.height
	}
	local viewPosition = {
		x = rect_bkg_small.origin.x,
		y = rect_bkg_small.origin.y
	}
	local viewSize = {
		width = rect_bkg_small.size.width,
		height = rect_bkg_small.size.height
	}

	local function stoneSlected(tag)
		call_back_close()
		pressMosaicStone(typicalStones[tag].id, stoneIndex)
	end

	local cellsLayer = d_ms.d_inertiaLayer.inertiaLayer.new(viewSize, viewPosition, frame_size, nil)

	layer:addChild(cellsLayer.scrollView, 5)
	createSingleChooseLayer(cellsLayer, typicalStones, stoneSlected, g_self.btnPicsList.choose, createSingleStoneCell)
	cellsLayer:createInertiaMove()
end

function pressSlot(noEnsure)
	local equipInfo = g_stoneUI.equipInfo

	if not equipInfo then
		d_ms.d_info.show(d_ms.d_hz.gethz("choose_equip"), 2)

		return
	end

	if equipInfo.drill_count >= g_self.Slots[equipInfo.csvInfo.quality] + equipInfo.star_level then
		d_ms.d_info.show(d_ms.d_hz.gethz("full_drill"), 2)

		return
	end

	local function sendSlotRequest()
		local tmp_req = {
			flag = d_ms.d_common_def.stone_event_type.drill_stone,
			des_id = equipInfo.id,
			equip_order = equipInfo.equip_order,
			stone_pos = 0,
			src_count = 0,
			src_list = {}
		}

		d_ms.d_u.main_server_send_msg(d_ms.d_msg_def.gscl_msg_id.msg_stone_event, tmp_req)
	end

	if d_ms.d_data.getItemCountByType(o_t.item, g_self.DrillMaterial.type_id) == 0 then
		local buyItemLayer = d_ms.d_data.createBuyFixedItem(o_t.item, g_self.DrillMaterial.type_id)

		if buyItemLayer then
			g_stoneUI.main_layer:addChild(buyItemLayer, 100)
		end
	elseif noEnsure > 0 then
		sendSlotRequest()
	else
		local hintStr1 = string.format(d_ms.d_hz.gethz("ensure_use_drill_material"), equipInfo.csvInfo.name)

		createPropsUseConfirmLayer(g_stoneUI.main_layer, 100, o_t.item, g_self.DrillMaterial.type_id, hintStr1, sendSlotRequest)
	end
end

function pressTakeoutStone(tag)
	local equipInfo = g_stoneUI.equipInfo

	if not equipInfo then
		d_ms.d_info.show(d_ms.d_hz.gethz("choose_equip"), 2)

		return
	end

	local stone = getStoneByOwner(equipInfo.id, tag)

	if not stone then
		d_ms.d_info.show(d_ms.d_hz.gethz("operation_failed"), 2)

		return
	end

	local tmp_req = {
		flag = d_ms.d_common_def.stone_event_type.unload_stone,
		des_id = equipInfo.id,
		equip_order = equipInfo.equip_order,
		stone_pos = stone.equip_pos,
		src_count = 1,
		src_list = {
			{
				id = stone.id
			}
		}
	}

	d_ms.d_u.main_server_send_msg(d_ms.d_msg_def.gscl_msg_id.msg_stone_event, tmp_req)
end

function pressMosaicStone(stone_id, pos)
	local equipInfo = g_stoneUI.equipInfo

	if not equipInfo then
		d_ms.d_info.show(d_ms.d_hz.gethz("choose_equip"), 2)

		return
	end

	if equipInfo.drill_count < pos then
		d_ms.d_info.show(d_ms.d_hz.gethz("not_enough_locate"), 2)

		return
	end

	local tmp_req = {
		flag = d_ms.d_common_def.stone_event_type.mosaic_stone,
		des_id = equipInfo.id,
		equip_order = equipInfo.equip_order,
		stone_pos = pos,
		src_count = 1,
		src_list = {
			{
				id = stone_id
			}
		}
	}

	d_ms.d_u.main_server_send_msg(d_ms.d_msg_def.gscl_msg_id.msg_stone_event, tmp_req)
end

function onGetResponse(msgtable)
	showResultInfo(msgtable.flag, msgtable.result)

	if msgtable.flag == resultTab.mosaic_stone then
		-- Nothing
	end

	if msgtable.result == resultType.success then
		refreshFrame()
	end
end

function showResultInfo(flag, result, pos_y)
	local info = ""

	if result == resultType.success then
		if flag == resultTab.drill_stone then
			info = "success_drill_stone"
		elseif flag == resultTab.mosaic_stone then
			info = "success_mosaic_stone"
		elseif flag == resultTab.upgrade_stone then
			info = "success_upgrade_stone"
		elseif flag == resultTab.unload_stone then
			info = "success_unload_stone"
		end
	elseif result == resultType.empty_drill then
		info = "empty_drill"
	elseif result == resultType.full_drill then
		info = "full_drill"
	elseif result == resultType.not_match then
		info = "not_match"
	elseif result == resultType.not_enough_locate then
		info = "not_enough_locate"
	elseif result == resultType.failed then
		if flag == resultTab.upgrade_stone then
			info = "fail_upgrade_stone"
		else
			info = "operation_failed"
		end
	elseif result == resultType.level_limit then
		info = string.format(d_ms.d_hz.gethz("stone_lv_limit"), g_self.Lvlimit)

		d_ms.d_info.show(info, 2, pos_y)

		return
	end

	d_ms.d_info.show(d_ms.d_hz.gethz(info), 2, pos_y)
end

function refreshFrame()
	if not g_stoneUI.main_layer then
		return false
	end

	g_stoneUI.main_layer:removeAllChildrenWithCleanup(true)
	create(g_stoneUI.main_layer, g_stoneUI.equipInfo)

	return true
end

function showStoneLayer(parentLayer, zOrder, equipInfo)
	if not parentLayer then
		cclog("params missed")

		return
	end

	g_self.MAXLV = #d_ms.d_data.g_stoneAttrTable[1]
	g_stoneUI = {
		main_layer = CCLayer:create()
	}
	local main_layer = g_stoneUI.main_layer

	local function sceneEventHandler(eventType)
		if eventType.name == "exit" then
			if not d_ms.d_charPositionUI.g_isQuitBoard then
				d_ms.d_charPositionUI.reloadItemSkillLevel()
			elseif d_ms.d_mainUI.g_currentBoard == d_ms.d_mainUI.boardID.package then
				d_ms.d_packageUI.refreshPackage()
			end

			g_stoneUI = {}
		end
	end

	main_layer:registerScriptHandler(sceneEventHandler)
	create(main_layer, equipInfo)
	parentLayer:addChild(main_layer, zOrder)
end

function pressClose()
	cclog("call close stoneUI")
	d_ms.d_u.remove(g_stoneUI.main_layer)
end

function create(layer, equipInfo)
	d_ms.d_u.createSwallowTouchLayer(layer)

	local colorLayer = CCLayerColor:create(ccc4(0, 0, 0, 180))

	layer:addChild(colorLayer, -1)

	g_stoneUI.equipInfo = equipInfo

	if equipInfo then
		g_stoneUI.stone_type_id = getStoneTypeID(equipInfo.csvInfo.mainType)
	end

	local bkg = d_ms.d_u.createByStyle({
		pic = "v2/stoneUI/bkg.png",
		x = 0.5,
		y = 0.5
	})

	layer:addChild(bkg)

	local w, h = d_ms.d_u.getRealScale(bkg)
	local item_menu_list = {
		{
			npic = "v2/introUI/close1.png",
			spic = "v2/introUI/close2.png",
			x = 0.5 + 0.44 * w,
			y = 0.5 + 0.46 * h,
			call_back = pressClose
		},
		{
			npic = "v2/stoneUI/unsee.png",
			spic = "v2/stoneUI/unsee.png",
			x = 0.5,
			y = 0.5 + 0.33 * h,
			scale = 0.2 * w,
			call_back = pressChooseEquip
		},
		x = 0,
		y = 0
	}

	if equipInfo then
		local equipSprite = d_ms.d_data.getCertainSmallSprite(equipInfo.attach_type, equipInfo.type_id, equipInfo.level, equipInfo.reborn_bit > 0, equipInfo.star_level)

		d_ms.d_u.setStyles(equipSprite, {
			x = 0.5,
			y = 0.5 + 0.33 * h,
			scale = 0.2 * w
		})
		layer:addChild(equipSprite, 10)

		local equip_w, equip_h = d_ms.d_u.getRealScale(equipSprite)

		if equipInfo.star_level == 1 then
			local star = CCSprite:create("v2/shengxing/sixstar.png")

			d_ms.d_u.setStyles(star, {
				x = 0.5,
				y = 0.5 + 0.335 * h - 0.4 * equip_h,
				anchor = {
					0.5,
					0
				},
				scale = 0.8 * equip_w
			})
			layer:addChild(star, 20)
		else
			local emptyStar = CCSprite:create("v2/newIntroUI/star_bkg.png")

			d_ms.d_u.setStyles(emptyStar, {
				x = 0.5,
				y = 0.5 + 0.335 * h - 0.4 * equip_h,
				anchor = {
					0.5,
					0
				},
				scale = 0.8 * equip_w
			})
			layer:addChild(emptyStar, 15)

			local qualityRatio = equipInfo.csvInfo.quality / 5
			local starsLevelSprite = CCSprite:create("v2/introUI/stars.png")

			d_ms.d_u.setStyles(starsLevelSprite, {
				x = 0.5 - 0.4 * equip_w,
				y = 0.5 + 0.335 * h - 0.4 * equip_h,
				anchor = {
					0,
					0
				},
				scale = 0.8 * equip_w
			})

			local starsContentSize = starsLevelSprite:getContentSize()

			starsLevelSprite:setTextureRect(CCRectMake(0, 0, starsContentSize.width * qualityRatio, starsContentSize.height))
			layer:addChild(starsLevelSprite, 20)
		end
	end

	local equipName = equipInfo and d_ms.d_data.getItemName(equipInfo.type_id, equipInfo.reborn_bit > 0) or d_ms.d_hz.gethz("choose_equip")

	layer:addChild(d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		x = 0.5,
		fontsize = 26,
		string = equipName,
		color = {
			216,
			167,
			48
		},
		y = 0.5 + 0.21 * h
	}), 5)

	if equipInfo then
		local MAX_SLOT = g_self.Slots[equipInfo.csvInfo.quality] + equipInfo.star_level
		local sloted = equipInfo.drill_count
		local stones = {
			equipInfo.stone1_level,
			equipInfo.stone2_level,
			equipInfo.stone3_level,
			equipInfo.stone4_level
		}
		local effect_types = {
			"enhance_attack",
			"enhance_defence",
			"enhance_hp"
		}
		local effect_hz = d_ms.d_hz.gethz(effect_types[equipInfo.csvInfo.mainType])
		local effect_tab = d_ms.d_data.g_stoneAttrTable[equipInfo.csvInfo.mainType]
		local equip_original = getEquipBaseEffect(equipInfo)

		for i = 1, MAX_SLOT do
			layer:addChild(d_ms.d_u.createByStyle({
				pic = "v2/stoneUI/unsee.png",
				scaleH = 0.14 * h,
				x = 0.5 - 0.35 * w,
				y = 0.5 - 0.155 * (i - 1) * h + 0.08 * h
			}), 2)

			if stones[i] > 0 then
				local stoneSprite = d_ms.d_data.getCertainSmallSprite(equipInfo.attach_type, g_stoneUI.stone_type_id, stones[i])

				d_ms.d_u.setStyles(stoneSprite, {
					x = 0.5 - 0.35 * w,
					y = 0.5 - 0.155 * (i - 1) * h + 0.08 * h,
					scaleH = 0.14 * h
				})
				layer:addChild(stoneSprite, 5)

				local effect_attr = nil

				if stones[i] > 10 then
					d_ms.d_stoneCastUI.initConfig()

					effect_attr = d_ms.d_stoneCastUI.g_self.csv[equipInfo.csvInfo.mainType][stones[i]].plus
				else
					effect_attr = effect_tab[stones[i]].base
				end

				local eff_name = math.floor(equip_original * effect_attr)

				if equipInfo.star_level == 1 then
					eff_name = math.floor(equip_original * effect_attr * 2)
				end

				local effectStr = effect_hz .. " +" .. eff_name .. "(" .. string.format("%.1f", effect_attr * 100) .. "%)"

				layer:addChild(d_ms.d_u.createByStyle({
					font = "arial",
					type = "label",
					fontsize = 26,
					string = effectStr,
					color = {
						186,
						219,
						66
					},
					anchor = {
						0,
						1
					},
					x = 0.5 - 0.13 * w,
					y = 0.5 + 0.08 * h - 0.155 * (i - 1) * h + 0.08 * h
				}), 5)
				table.insert(item_menu_list, {
					npic = "v2/stoneUI/takeout1.png",
					spic = "v2/stoneUI/takeout2.png",
					x = 0.5,
					y = 0.5 - 0.02 * h - 0.155 * (i - 1) * h + 0.08 * h,
					tag = i,
					call_back = pressTakeoutStone
				})

				if stones[i] == 10 then
					table.insert(item_menu_list, {
						npic = "v2/stoneCastUI/asc1.png",
						spic = "v2/stoneCastUI/asc2.png",
						x = 0.5 + 0.325 * w,
						y = 0.5 - 0.02 * h - 0.155 * (i - 1) * h + 0.08 * h,
						tag = i,
						call_back = pressStoneAsc
					})
				elseif stones[i] >= 11 then
					table.insert(item_menu_list, {
						npic = "v2/stoneCastUI/tilian.png",
						spic = "v2/stoneCastUI/tilian2.png",
						x = 0.5 + 0.325 * w,
						y = 0.5 - 0.02 * h - 0.155 * (i - 1) * h + 0.08 * h,
						tag = i,
						call_back = pressStoneAsc
					})
				else
					table.insert(item_menu_list, {
						npic = "v2/stoneUI/stone_upgrade1.png",
						spic = "v2/stoneUI/stone_upgrade2.png",
						x = 0.5 + 0.325 * w,
						y = 0.5 - 0.02 * h - 0.155 * (i - 1) * h + 0.08 * h,
						tag = i,
						call_back = pressStoneUpgrade
					})
				end
			elseif i <= sloted then
				table.insert(item_menu_list, {
					npic = "v2/stoneUI/unsee.png",
					spic = "v2/stoneUI/unsee.png",
					x = 0.5 - 0.35 * w,
					y = 0.5 - 0.155 * (i - 1) * h + 0.08 * h,
					scaleH = 0.14 * h,
					tag = i,
					call_back = pressChooseStone
				})
				table.insert(item_menu_list, {
					npic = "v2/stoneUI/stone_choose1.png",
					spic = "v2/stoneUI/stone_choose2.png",
					x = 0.5 + 0.325 * w,
					y = 0.5 - 0.02 * h - 0.155 * (i - 1) * h + 0.08 * h,
					tag = i,
					call_back = pressChooseStone
				})
			elseif sloted == i - 1 then
				layer:addChild(d_ms.d_u.createByStyle({
					pic = "v2/stoneUI/lock.png",
					x = 0.5 - 0.35 * w,
					y = 0.5 - 0.155 * (i - 1) * h + 0.08 * h,
					scaleH = 0.14 * h
				}), 5)
				table.insert(item_menu_list, {
					npic = "v2/stoneUI/slot1.png",
					spic = "v2/stoneUI/slot2.png",
					x = 0.5,
					y = 0.5 - 0.02 * h - 0.155 * (i - 1) * h + 0.08 * h,
					call_back = pressSlot
				})

				local choose_pic = d_ms.d_u.createByStyle({
					pic = "v2/stoneUI/stone_choose1.png",
					x = 0.5 + 0.325 * w,
					y = 0.5 - 0.02 * h - 0.155 * (i - 1) * h + 0.08 * h
				})

				choose_pic:setMaskEff("v2/gray.shader")
				layer:addChild(choose_pic, 5)
			else
				layer:addChild(d_ms.d_u.createByStyle({
					pic = "v2/stoneUI/lock.png",
					x = 0.5 - 0.35 * w,
					y = 0.5 - 0.155 * (i - 1) * h + 0.08 * h
				}), 5)

				local slot_pic = d_ms.d_u.createByStyle({
					pic = "v2/stoneUI/slot1.png",
					x = 0.5,
					y = 0.5 - 0.02 * h - 0.155 * (i - 1) * h + 0.08 * h
				})

				slot_pic:setMaskEff("v2/gray.shader")
				layer:addChild(slot_pic, 5)

				local choose_pic = d_ms.d_u.createByStyle({
					pic = "v2/stoneUI/stone_choose1.png",
					x = 0.5 + 0.325 * w,
					y = 0.5 - 0.02 * h - 0.155 * (i - 1) * h + 0.08 * h
				})

				choose_pic:setMaskEff("v2/gray.shader")
				layer:addChild(choose_pic, 5)
			end
		end
	end

	layer:addChild(d_ms.d_u.createMenu(item_menu_list), 5)
end

function getStoneTypeID(type)
	return g_self.StoneTypeID[type]
end

function getStoneTypeByID(type_id)
	for k, v in pairs(g_self.StoneTypeID) do
		if v == type_id then
			return k
		end
	end
end

function getAllEquipsExcept(id)
	local allEquips = {}
	local allItems = d_ms.d_packageUI.g_packageItemsInfo or {}

	for k, v in pairs(allItems) do
		if v.attach_type == o_t.item and v.csvInfo.mainType <= m_t.talismans and (not id or v.id ~= id) then
			table.insert(allEquips, v)
		end
	end

	table.sort(allEquips, d_ms.d_packageUI.packageSortFunc)

	return allEquips
end

function getEquipDataSource(list, btnPics, cellSize)
	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local bkgPic = "v2/charPositionUI/item_bkg.png"
	local dataSource = {}
	local num = #list

	function dataSource.tableViewNumberOfRows()
		return num
	end

	function dataSource.drawCellAtIndex(index)
		local cell = CCNode:create()

		if list[index] then
			createCellOnSlot(cell, list[index], bkgPic, btnPics, cellSize)
		end

		return cell
	end

	function dataSource.heightForRowAtIndex(index)
		return cellSize.height
	end

	return dataSource
end

function createCellOnSlot(parent, itemInfo, bkgPic, btnPics, cellSize)
	d_ms.d_createCell.createCellWithOwnerNoBtn(parent, itemInfo, bkgPic, cellSize)

	local function changeEquip()
		onEquipChanged(itemInfo)
	end

	local changeButtonItem = CCMenuItemImage:create(btnPics[1], btnPics[2])

	changeButtonItem:setPosition(cellSize.width * 0.85, cellSize.height * 0.25)
	changeButtonItem:registerScriptTapHandler(changeEquip)

	local changeMenu = CCMenu:createWithItem(changeButtonItem)

	changeMenu:setPosition(0, 0)
	parent:addChild(changeMenu, 5)
end

function createSingleChooseLayer(cellsLayer, showList, selectedCallback, btnPics, createCellFunc)
	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local width = cellsLayer.touchArea.width
	local height = cellsLayer.touchArea.height
	local offset = 0.01 * scrSize.height
	local cellPosY = height - 2 * offset
	local firstShow = 10
	local count = math.min(firstShow, #showList)

	for i = 1, count do
		local item = showList[i]
		local node, size = createCellFunc(item, i, {
			x = 0,
			y = cellPosY,
			width = width
		}, btnPics, selectedCallback)
		cellPosY = cellPosY - size.height - offset

		cellsLayer:addCell(node, {
			width = size.width,
			height = size.height + offset
		})
	end

	local showIndex = firstShow + 1

	function d_ms.d_inertiaLayer.scrollViewHelper.scrollViewDidScroll()
		if showIndex > #showList then
			return
		end

		if showList[showIndex] then
			local item = showList[showIndex]
			local node, size = createCellFunc(item, showIndex, {
				x = 0,
				y = cellPosY,
				width = width
			}, btnPics, selectedCallback)
			cellPosY = cellPosY - size.height - offset

			cellsLayer:addCell(node, {
				width = size.width,
				height = size.height + offset
			})
		end

		showIndex = showIndex + 1
	end
end

function createEquipCell(item, tag, rect, btnPics, btnClicked)
	local posX = rect.x
	local posY = rect.y
	local width = rect.width
	local cellNode = CCNode:create()
	local bkg = CCSprite:create("v2/charPositionUI/item_bkg.png")
	local bkgSize = bkg:getContentSize()

	bkg:setScale(width / bkgSize.width)
	cellNode:addChild(bkg)
	cellNode:setPosition(posX, posY - bkgSize.height)
	bkg:setPosition(0.5 * bkgSize.width, 0.5 * bkgSize.height)

	local itemName = item.csvInfo.name
	local itemNameLabel = d_ms.d_u.createByStyle({
		font = "arial",
		fontsize = 26,
		type = "label",
		string = itemName
	})

	itemNameLabel:setPosition(bkgSize.width * 0.23, bkgSize.height * 0.75)
	itemNameLabel:setAnchorPoint(CCPointMake(0, 0.5))
	cellNode:addChild(itemNameLabel, 5)

	local qualityRatio = item.csvInfo.quality / 5
	local starsLevelSprite = CCSprite:create("v2/introUI/stars.png")

	starsLevelSprite:setPosition(bkgSize.width * 0.22, bkgSize.height * 0.5)
	starsLevelSprite:setAnchorPoint(CCPointMake(0, 0.5))

	local starsContentSize = starsLevelSprite:getContentSize()

	starsLevelSprite:setTextureRect(CCRectMake(0, 0, starsContentSize.width * qualityRatio, starsContentSize.height))
	cellNode:addChild(starsLevelSprite)

	local levelSprite = CCSprite:create("v2/introUI/level.png")

	levelSprite:setPosition(bkgSize.width * 0.22, bkgSize.height * 0.25)
	levelSprite:setAnchorPoint(CCPointMake(0, 0.5))
	cellNode:addChild(levelSprite, 5)

	local level = item.level
	local levelLabel = d_ms.d_u.createByStyle({
		font = "arial",
		fontsize = 26,
		type = "label",
		string = tostring(level)
	})

	levelLabel:setPosition(bkgSize.width * 0.29, bkgSize.height * 0.25)
	levelLabel:setAnchorPoint(CCPointMake(0, 0.5))
	cellNode:addChild(levelLabel, 5)
	d_ms.d_charPositionUI.createItemLabel(cellNode, item, CCPointMake(bkgSize.width * 0.4, bkgSize.height * 0.25))

	local changeButtonItem = CCMenuItemImage:create(btnPics[1], btnPics[2])

	changeButtonItem:setPosition(bkgSize.width * 0.8, bkgSize.height * 0.25)
	changeButtonItem:registerScriptTapHandler(btnClicked)
	changeButtonItem:setTag(tag)

	local changeMenu = CCMenu:createWithItem(changeButtonItem)

	changeMenu:setPosition(0, 0)
	cellNode:addChild(changeMenu, 5)

	local function showDetail()
		local introLayer = nil

		local function close()
			d_ms.d_u.remove(introLayer)
		end

		introLayer = d_ms.d_packageUI.createItemIntroLayer(item, close, false)

		g_stoneUI.main_layer:addChild(introLayer, 500)
	end

	local itemSprite = d_ms.d_data.getCertainSmallSprite(item.attach_type, item.type_id)
	local itemSprite2 = d_ms.d_data.getCertainSmallSprite(item.attach_type, item.type_id)
	local itemMenuSprite = CCMenuItemSprite:create(itemSprite, itemSprite2)

	itemMenuSprite:registerScriptTapHandler(showDetail)
	itemMenuSprite:setPosition(bkgSize.width * 0.1, bkgSize.height * 0.5)

	local itemMenu = CCMenu:createWithItem(itemMenuSprite)

	itemMenu:setPosition(0, 0)
	cellNode:addChild(itemMenu, 5)

	if item.equip_order > 0 then
		local owner = d_ms.d_lineupUI.g_usedCharacters[item.equip_order].character.csvInfo.name
		local hintLabel = d_ms.d_u.createByStyle({
			font = "arial",
			fontsize = 22,
			type = "label",
			string = d_ms.d_hz.gethz("equip") .. owner
		})

		hintLabel:setPosition(bkgSize.width * 0.8, bkgSize.height * 0.75)
		cellNode:addChild(hintLabel, 5)
	end

	return cellNode, {
		width = bkgSize.width,
		height = bkgSize.height
	}
end

function getTypicalStone(level, type_id, includeAsc)
	local allStones = d_ms.d_packageUI.g_reorgItemsInfo[o_t.item][m_t.stone] or {}
	local unusedStones = {}

	for k, v in pairs(allStones) do
		if (not type_id or v.type_id == type_id) and (not level or level <= v.level) and v.owner_id == 0 then
			if includeAsc then
				table.insert(unusedStones, v)
			elseif v.level <= 11 then
				table.insert(unusedStones, v)
			end
		end
	end

	table.sort(unusedStones, function (a, b)
		if a.level == b.level then
			return a.csvInfo.sub_type < b.csvInfo.sub_type
		else
			return a.level < b.level
		end
	end)

	return unusedStones
end

function getUnusedStoneByType(type_id)
	local allStones = d_ms.d_packageUI.g_reorgItemsInfo[o_t.item][m_t.stone] or {}
	local unusedStones = {}

	for k, v in pairs(allStones) do
		if (not type_id or v.type_id == type_id) and v.owner_id == 0 then
			table.insert(unusedStones, v)
		end
	end

	table.sort(unusedStones, d_ms.d_packageUI.stoneSort)

	return unusedStones
end

function getOwnerNameByID(id, subType)
	local equips = d_ms.d_packageUI.g_reorgItemsInfo[o_t.item][subType]
	local pos = 0

	for _, v in pairs(equips) do
		if v.id == id then
			pos = v.equip_order

			break
		end
	end

	local char = d_ms.d_lineupUI.g_usedCharacters[pos]

	if char then
		return d_ms.d_data.getMyCortName(char.character.type)
	end
end

function getStoneByOwner(equip_id, pos)
	local allStones = d_ms.d_packageUI.g_reorgItemsInfo[o_t.item][m_t.stone] or {}

	for k, v in pairs(allStones) do
		if v.owner_id == equip_id and v.equip_pos == pos then
			return v
		end
	end

	return nil
end

function setOwnerID(stone_id, owner_id)
	local allStones = d_ms.d_packageUI.g_reorgItemsInfo[o_t.item][m_t.stone]

	for k, v in pairs(allStones) do
		if v.id == stone_id then
			v.owner_id = owner_id

			return
		end
	end
end

function getEquipBaseEffect(equipInfo, level, star_level)
	local csv = equipInfo.csvInfo
	local level = level or equipInfo.level
	local base = 0

	if csv.mainType <= d_ms.d_common_def.item_main_type.talismans then
		base = csv.base_gongji_plus + csv.base_fangyu_plus + csv.base_maxhp_plus
		base = base + (level - 1) * csv.effect_plus

		if equipInfo.reborn_bit and equipInfo.reborn_bit > 0 then
			local asc_effect = d_ms.d_data.g_equipAsc_baseTab[equipInfo.csvInfo.mainType].effect_value

			if asc_effect.type <= 4 then
				base = base + (level - 1) * csv.effect_plus * asc_effect.value / 100
			else
				base = base + (level - 1) * asc_effect.value
			end
		end
	end

	return base + (star_level or 0) * base
end

function createSingleStoneCell(item, tag, rect, btnPics, btnClicked)
	local posX = rect.x
	local posY = rect.y
	local width = rect.width
	local cellNode = CCNode:create()
	local bkg = CCSprite:create("v2/charPositionUI/item_bkg.png")
	local bkgSize = bkg:getContentSize()

	bkg:setScale(width / bkgSize.width)
	cellNode:addChild(bkg)
	cellNode:setPosition(posX, posY - bkgSize.height)
	bkg:setPosition(0.5 * bkgSize.width, 0.5 * bkgSize.height)

	local itemName = d_ms.d_data.getItemName(item.type_id, item.level > 10, item.level)
	local itemNameLabel = d_ms.d_u.createByStyle({
		font = "arial",
		fontsize = 26,
		type = "label",
		string = itemName
	})

	itemNameLabel:setPosition(bkgSize.width * 0.23, bkgSize.height * 0.75)
	itemNameLabel:setAnchorPoint(CCPointMake(0, 0.5))
	cellNode:addChild(itemNameLabel, 5)

	local levelSprite = CCSprite:create("v2/introUI/level.png")

	levelSprite:setPosition(bkgSize.width * 0.24, bkgSize.height * 0.25)
	cellNode:addChild(levelSprite, 5)

	local level = item.level
	local levelLabel = d_ms.d_u.createByStyle({
		font = "arial",
		fontsize = 26,
		type = "label",
		string = tostring(level)
	})

	levelLabel:setPosition(bkgSize.width * 0.27, bkgSize.height * 0.25)
	levelLabel:setAnchorPoint(CCPointMake(0, 0.5))
	cellNode:addChild(levelLabel, 5)

	local sub_type = item.csvInfo.sub_type
	local stoneAttrTab = d_ms.d_data.g_stoneAttrTable[sub_type]
	local plus_types = {
		"CHAR_gong",
		"CHAR_fang",
		"CHAR_ming"
	}
	local powerSprite = CCSprite:create("v2/packageUI/" .. plus_types[sub_type] .. ".png")

	powerSprite:setPosition(bkgSize.width * 0.4, bkgSize.height * 0.25)
	cellNode:addChild(powerSprite, 5)

	local attr = nil

	if level and level > 10 then
		d_ms.d_stoneCastUI.initConfig()

		attr = d_ms.d_stoneCastUI.g_self.csv[sub_type][level].plus
	else
		attr = stoneAttrTab[level].base
	end

	local powerLabel = d_ms.d_u.createByStyle({
		font = "arial",
		fontsize = 26,
		type = "label",
		string = string.format("%.1f", attr * 100) .. "%"
	})

	powerLabel:setPosition(bkgSize.width * 0.43, bkgSize.height * 0.25)
	powerLabel:setAnchorPoint(CCPointMake(0, 0.5))
	cellNode:addChild(powerLabel, 5)

	local changeButtonItem = CCMenuItemImage:create(btnPics[1], btnPics[2])

	changeButtonItem:setPosition(bkgSize.width * 0.8, bkgSize.height * 0.25)
	changeButtonItem:registerScriptTapHandler(btnClicked)
	changeButtonItem:setTag(tag)

	local changeMenu = CCMenu:createWithItem(changeButtonItem)

	changeMenu:setPosition(0, 0)
	cellNode:addChild(changeMenu, 5)

	local itemSprite = d_ms.d_data.getCertainSmallSprite(item.attach_type, item.type_id, item.level)

	itemSprite:setPosition(bkgSize.width * 0.01, bkgSize.height * 0.5)
	itemSprite:setAnchorPoint(CCPointMake(0, 0.5))
	cellNode:addChild(itemSprite, 5)

	return cellNode, {
		width = bkgSize.width,
		height = bkgSize.height
	}
end

function createPropsUseConfirmLayer(parent, zorder, object_type, type_id, hintStr, yes_func, no_func)
	if not parent or not zorder then
		return
	end

	local main_layer = CCLayer:create()
	local colorLayer = CCLayerColor:create(ccc4(0, 0, 0, 100))

	main_layer:addChild(colorLayer, -1)
	parent:addChild(main_layer, zorder)

	local menuArr = CCArray:create()
	local posTab = d_ms.d_loginGameUI.createPrizeBoxBkg(main_layer, 0.65, d_ms.d_loginGameUI.titleType.hint)
	local w = posTab.width
	local h = posTab.height
	local info = d_ms.d_data.getCertainInfo(object_type, type_id)

	local function showItemIntro()
		d_ms.d_data.showItemIntro(main_layer, {
			object_type = object_type,
			attach_type = type_id
		})
	end

	local sprite1 = d_ms.d_data.getCertainSmallSprite(object_type, type_id)
	local sprite2 = d_ms.d_data.getCertainSmallSprite(object_type, type_id)
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

	local propsCount = d_ms.d_data.getItemCountByType(object_type, type_id)
	local label_count = d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		x = 0.5,
		fontsize = 30,
		string = d_ms.d_hz.gethz("leftInPackage") .. propsCount,
		y = 0.5 - 0.22 * h,
		color = {
			46,
			138,
			92
		}
	})

	main_layer:addChild(label_count, 1)

	local label_hint = d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		x = 0.5,
		fontsize = 26,
		string = hintStr,
		y = 0.5 - 0.37 * h,
		color = {
			255,
			236,
			225
		}
	})

	main_layer:addChild(label_hint, 1)

	local function pressYes()
		d_ms.d_u.remove(main_layer)

		if yes_func then
			yes_func(shopItemInfo)
		end
	end

	local function pressNo()
		d_ms.d_u.remove(main_layer)

		if no_func then
			no_func(shopItemInfo)
		end
	end

	local cancelButton = CCMenuItemImage:create("v2/buttons/cancel1.png", "v2/buttons/cancel2.png")

	cancelButton:registerScriptTapHandler(pressNo)
	cancelButton:setPosition(posTab.first.x, posTab.first.y)
	menuArr:addObject(cancelButton)

	local buyButton = CCMenuItemImage:create("v2/packageUI/use1.png", "v2/packageUI/use2.png")

	buyButton:registerScriptTapHandler(pressYes)
	buyButton:setPosition(posTab.second.x, posTab.second.y)
	menuArr:addObject(buyButton)

	local menu = CCMenu:createWithArray(menuArr)

	menu:setPosition(CCPointMake(0, 0))
	main_layer:addChild(menu, 1)
end
