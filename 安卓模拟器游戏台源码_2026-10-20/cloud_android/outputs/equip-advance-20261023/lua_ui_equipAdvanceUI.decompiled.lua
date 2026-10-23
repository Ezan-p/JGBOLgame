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
local CCSequence = CCSequence
local CCScaleTo = CCScaleTo
local CCCallFuncN = CCCallFuncN

module("ui.equipAdvanceUI")

d_ms = require("ms")

if not d_ms then
	CCLuaLog("equipAdvanceUI load d_ms fail.\n")
end

local function cclog(...)
	CCLuaLog(string.format("Lua : equipAdvanceUI >>%s", string.format(...)))
end

o_t = d_ms.d_common_def.object_type
m_t = d_ms.d_common_def.item_main_type
e_a_t = d_ms.d_common_def.equip_advance_type
g_self = {
	btnPicsList = {
		choose = {
			"v2/introUI/choose1.png",
			"v2/introUI/choose2.png"
		},
		change = {
			"v2/introUI/change1.png",
			"v2/introUI/change2.png"
		}
	},
	tags = {
		Fake = 5,
		Advance = 3,
		Status = 4,
		ExpAdd = 1,
		ExpAddDetail = 2
	},
	ExpMaterial = {
		[m_t.weapon] = {
			attach_level = 1,
			attach_count = 5,
			attach_type = 1310,
			object_type = o_t.item
		},
		[m_t.guard] = {
			attach_level = 1,
			attach_count = 5,
			attach_type = 1311,
			object_type = o_t.item
		},
		[m_t.talismans] = {
			attach_level = 1,
			attach_count = 5,
			attach_type = 1312,
			object_type = o_t.item
		}
	}
}
g_AdvanceUI = {}
scrSize = CCDirector:sharedDirector():getVisibleSize()

function canJoin(isShowMsg)
	if not g_self.is_open then
		if isShowMsg then
			d_ms.d_info.show(d_ms.d_hz.gethz("tmp_not_open"), 2)
		end

		return false
	end

	if d_ms.d_mainUI.g_playerInfo.level < g_self.MIN_LEVEL then
		if isShowMsg then
			d_ms.d_info.show(string.format(d_ms.d_hz.gethz("stone_lv_limit"), g_self.MIN_LEVEL), 2)
		end

		return false
	else
		return true
	end
end

function refreshFrame()
	if not g_AdvanceUI.main_layer then
		return false
	end

	g_AdvanceUI.main_layer:removeAllChildrenWithCleanup(true)
	create()

	return true
end

function getConfig(data_table)
	cclog("hehe")

	if not data_table then
		return
	end

	for k, v in pairs(g_self.ExpMaterial) do
		v.attach_count = data_table.pour_star_count
	end

	g_self.MIN_LEVEL = data_table.min_role_level
	g_self.MAX_ADVANCE_LEVEL = data_table.max_advance_level
	g_self.MAX_STAR_COUNT = data_table.max_star_level
	g_self.is_open = data_table.is_open
end

function getConsts()
	if not g_self.StarCost then
		d_ms.d_data.getEquipAdvanceExp()

		g_self.StarCost = d_ms.d_data.g_equipAdvanceExpTab
	end

	if not g_self.AdvanceCost then
		d_ms.d_data.getEquipAdvanceCost()

		g_self.AdvanceCost = d_ms.d_data.g_equipAdvanceCostTab
	end

	if not g_self.Value then
		d_ms.d_data.getEquipAdvanceValue()

		g_self.Value = d_ms.d_data.g_equipAdvanceValueTab
	end
end

function showAdvanceLayer(parentLayer, zOrder, equipInfo)
	if not parentLayer then
		cclog("params missed")

		return
	end

	getConsts()

	g_AdvanceUI.equipInfo = equipInfo
	g_AdvanceUI.main_layer = CCLayer:create()
	local main_layer = g_AdvanceUI.main_layer

	local function sceneEventHandler(eventType)
		if eventType.name == "exit" then
			g_AdvanceUI = {}
		end
	end

	main_layer:registerScriptHandler(sceneEventHandler)
	create()
	parentLayer:addChild(main_layer, zOrder)
end

function pressClose()
	cclog("call close AdvanceUI")
	d_ms.d_u.remove(g_AdvanceUI.main_layer)

	g_AdvanceUI = {}

	if not d_ms.d_charPositionUI.g_isQuitBoard then
		d_ms.d_charPositionUI.reloadItemSkillLevel()
	elseif d_ms.d_mainUI.g_currentBoard == d_ms.d_mainUI.boardID.package then
		d_ms.d_packageUI.refreshPackage()
	end
end

function create()
	local layer = g_AdvanceUI.main_layer
	local equipInfo = g_AdvanceUI.equipInfo

	if not layer then
		return
	end

	d_ms.d_u.createSwallowTouchLayer(layer)

	local colorLayer = CCLayerColor:create(ccc4(0, 0, 0, 180))

	layer:addChild(colorLayer, -1)

	local bkg = d_ms.d_u.createByStyle({
		pic = "v2/equipAdvanceUI/bkg.png",
		x = 0.5,
		y = 0.5
	})

	layer:addChild(bkg)

	local w, h = d_ms.d_u.getRealScale(bkg)
	local icony = 0.5 + 0.295 * h
	local namey = 0.5 + 0.14 * h
	g_self.h = h
	g_self.w = w
	g_self.namey = namey
	g_self.icony = icony
	g_self.ys_exp_add = {
		0.5 + 0.05 * h,
		0.5 + 0 * h,
		0.5 - 0.07 * h,
		0.5 - 0.14 * h,
		0.5 - 0.18 * h,
		0.5 - 0.23 * h,
		0.5 - 0.27 * h,
		0.5 - 0.3 * h,
		0.5 - 0.4 * h
	}
	g_self.ys_advance = {
		0.5 + 0.07 * h,
		0.5 + 0.01 * h,
		0.5 - 0.025 * h,
		0.5 - 0.05 * h,
		0.5 - 0.11 * h,
		0.5 - 0.23 * h,
		0.5 - 0.3 * h,
		0.5 - 0.33 * h,
		0.5 - 0.41 * h
	}

	layer:addChild(d_ms.d_u.createByStyle({
		pic = "v2/equipAdvanceUI/icon_bkg.png",
		x = 0.5,
		y = icony
	}))
	layer:addChild(d_ms.d_u.createByStyle({
		pic = "v2/equipAdvanceUI/name_bkg.png",
		x = 0.5,
		y = namey
	}))

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
			y = icony,
			scale = 0.3 * w,
			call_back = pressChooseEquip
		},
		x = 0,
		y = 0
	}

	if equipInfo then
		local equipSprite = d_ms.d_data.getCertainSmallSprite(equipInfo.attach_type, equipInfo.type_id)

		d_ms.d_u.setStyles(equipSprite, {
			x = 0.5,
			y = icony,
			scale = 0.3 * w
		})
		layer:addChild(equipSprite, 10)

		local equip_w, equip_h = d_ms.d_u.getRealScale(equipSprite)
		local emptyStar = CCSprite:create("v2/newIntroUI/star_bkg.png")

		d_ms.d_u.setStyles(emptyStar, {
			x = 0.5,
			y = icony - 0.4 * equip_h,
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
			y = icony - 0.4 * equip_h,
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

	layer:addChild(d_ms.d_u.createMenu(item_menu_list), 5)

	if equipInfo then
		layer:addChild(d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			fontsize = 26,
			string = equipInfo.csvInfo.name,
			color = {
				216,
				167,
				48
			},
			x = 0.5 - 0.08 * w,
			y = namey
		}), 5)
		showAdvanceInfoLayer()
	else
		layer:addChild(d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			x = 0.5,
			fontsize = 26,
			string = d_ms.d_hz.gethz("choose_equip"),
			color = {
				216,
				167,
				48
			},
			y = namey
		}), 5)
	end
end

function afterFakeShow()
	if not g_AdvanceUI.main_layer then
		return
	end

	showAdvanceInfoLayer()
end

function showFakeInfo()
	if not g_AdvanceUI.main_layer or not g_AdvanceUI.equipInfo then
		return
	end

	local parent = g_AdvanceUI.main_layer

	if not parent then
		return
	end

	parent = parent:getChildByTag(g_self.tags.ExpAdd)

	if not parent then
		return
	end

	parent = parent:getChildByTag(g_self.tags.ExpAddDetail)

	if not parent then
		return
	end

	local equipInfo = g_AdvanceUI.equipInfo
	local oldExp = g_AdvanceUI.oldExp
	local layer = CCLayer:create()

	d_ms.d_u.createSwallowTouchLayer(layer)

	local fakeExp = d_ms.d_u.createByStyle({
		pic = "v2/equipAdvanceUI/exp.png",
		x = oldExp.x + 0.012,
		y = oldExp.y,
		anchor = {
			0.036,
			0.5
		}
	})

	fakeExp:setScaleX(oldExp.percent)
	layer:addChild(fakeExp)

	local final_scale = 1

	if oldExp.star_count == equipInfo.star_count then
		local need_exp = g_self.StarCost[equipInfo.csvInfo.quality][equipInfo.csvInfo.mainType][equipInfo.advance_level + 1][equipInfo.star_count + 1]
		final_scale = equipInfo.cur_spirit_count / need_exp
	end

	local interval = 0.5 * (0.01 + final_scale - oldExp.percent)

	local function showStarAnim()
		if oldExp.star_count == equipInfo.star_count then
			afterFakeShow()
		else
			d_ms.d_u.createAnimation_new("shengjie.ccbi", {
				scale = 0.5,
				z = 3,
				x = 0.5,
				y = g_self.ys_exp_add[3]
			}, 0.5, afterFakeShow, layer)
		end
	end

	local tmp_array = CCArray:create()

	tmp_array:addObject(CCScaleTo:create(interval, final_scale))
	tmp_array:addObject(CCCallFuncN:create(showStarAnim))
	fakeExp:runAction(CCSequence:create(tmp_array))
	parent:addChild(layer, 4, g_self.tags.Fake)
end

function onGetAdvanceResult(data_table)
	cclog("hehe")

	if data_table.result == 1 then
		if data_table.flag == e_a_t.pour_equip then
			d_ms.d_info.show(d_ms.d_hz.gethz("advance11"))

			if g_AdvanceUI.oldExp then
				showFakeInfo()
			end
		elseif data_table.flag == e_a_t.advance_equip then
			d_ms.d_info.show(d_ms.d_hz.gethz("advance12"))
			d_ms.d_u.createAnimation_new("shengjie02.ccbi", {
				scale = 1,
				z = 100,
				x = 0.5,
				y = g_self.icony
			}, 0.75, showAdvanceInfoLayer, g_AdvanceUI.main_layer)
		end
	else
		cclog("hehe")
	end
end

function showAdvanceInfoLayer()
	local parent = g_AdvanceUI.main_layer
	local equipInfo = g_AdvanceUI.equipInfo

	if not parent or not equipInfo then
		return
	end

	local statusLayer = d_ms.d_u.clearLayer(parent, 20, g_self.tags.Status)
	local w = g_self.w
	local h = g_self.h
	local statusStr = getNumHZ(equipInfo.advance_level) .. d_ms.d_hz.gethz("jie_hz")

	if equipInfo.advance_level < g_self.MAX_ADVANCE_LEVEL then
		statusStr = statusStr .. equipInfo.star_count .. d_ms.d_hz.gethz("star")
	end

	statusLayer:addChild(d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		fontsize = 26,
		string = statusStr,
		color = {
			177,
			177,
			177
		},
		x = 0.5 + 0.12 * w,
		y = g_self.namey
	}), 5)

	if g_self.MAX_STAR_COUNT == equipInfo.star_count and equipInfo.advance_level < g_self.MAX_ADVANCE_LEVEL then
		parent:removeChildByTag(g_self.tags.ExpAdd, true)
		showExpFullInfo()
	else
		parent:removeChildByTag(g_self.tags.Advance, true)
		showExpAddInfo()
	end
end

function showExpAddInfo()
	local parent = g_AdvanceUI.main_layer

	if not parent then
		return
	end

	local layer = parent:getChildByTag(g_self.tags.ExpAdd)

	if not layer then
		layer = CCLayer:create()
		local w = g_self.w
		local h = g_self.h
		local ys = g_self.ys_exp_add
		local theColor = {
			187,
			86,
			42
		}
		local str, label = nil
		str = d_ms.d_hz.gethz("advance_attr" .. g_AdvanceUI.equipInfo.csvInfo.mainType) .. d_ms.d_hz.gethz("advance3") .. ": "

		layer:addChild(d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			x = 0.5,
			fontsize = 26,
			string = str,
			color = theColor,
			anchor = {
				1,
				0.5
			},
			y = ys[1]
		}))

		str = d_ms.d_hz.gethz("advance4") .. d_ms.d_hz.gethz("advance_attr" .. g_AdvanceUI.equipInfo.csvInfo.mainType) .. ": "

		layer:addChild(d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			x = 0.5,
			fontsize = 26,
			string = str,
			color = theColor,
			anchor = {
				1,
				0.5
			},
			y = ys[2]
		}))

		for i = 1, g_self.MAX_STAR_COUNT do
			layer:addChild(d_ms.d_u.createByStyle({
				pic = "v2/equipAdvanceUI/star_emp.png",
				x = 0.5 + 0.075 * w * (i - 0.5 * (1 + g_self.MAX_STAR_COUNT)),
				y = ys[3]
			}))
		end

		layer:addChild(d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			x = 0.5,
			fontsize = 26,
			string = d_ms.d_hz.gethz("advance5"),
			color = theColor,
			y = ys[4]
		}))
		layer:addChild(d_ms.d_u.createByStyle({
			pic = "v2/equipAdvanceUI/exp_bkg.png",
			x = 0.5,
			y = ys[5]
		}))
		layer:addChild(d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			x = 0.5,
			fontsize = 22,
			string = d_ms.d_hz.gethz("tip_hz") .. ": " .. d_ms.d_hz.gethz("advance14"),
			color = {
				178,
				255,
				63
			},
			y = ys[6]
		}))
		layer:addChild(d_ms.d_u.createByStyle({
			pic = "v2/equipAdvanceUI/line.png",
			x = 0.5,
			y = ys[7]
		}))
		parent:addChild(layer, 20, g_self.tags.ExpAdd)
	end

	showExpAddDetail()
end

function showExpAddDetail()
	local parent = g_AdvanceUI.main_layer

	if not parent then
		return
	end

	parent = parent:getChildByTag(g_self.tags.ExpAdd)

	if not parent then
		return
	end

	local layer = d_ms.d_u.clearLayer(parent, 20, g_self.tags.ExpAddDetail)
	local equipInfo = g_AdvanceUI.equipInfo
	local w = g_self.w
	local h = g_self.h
	local ys = g_self.ys_exp_add
	local theColor = {
		155,
		155,
		23
	}
	local str, label = nil
	local powerBase = d_ms.d_stoneUI.getEquipBaseEffect(equipInfo)
	local effect = g_self.Value[equipInfo.csvInfo.quality][equipInfo.csvInfo.mainType][equipInfo.advance_level][equipInfo.star_count]
	str = "+" .. math.floor(effect.percent * powerBase) .. "(" .. math.floor(effect.percent * 100) .. "%)"

	layer:addChild(d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		x = 0.5,
		fontsize = 26,
		string = str,
		color = theColor,
		anchor = {
			0,
			0.5
		},
		y = ys[1]
	}))

	str = "+" .. math.floor(effect.plus)

	layer:addChild(d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		x = 0.5,
		fontsize = 26,
		string = str,
		color = theColor,
		anchor = {
			0,
			0.5
		},
		y = ys[2]
	}))

	local isFullAdvance = equipInfo.advance_level == g_self.MAX_ADVANCE_LEVEL
	local gotStar = isFullAdvance and g_self.MAX_STAR_COUNT or equipInfo.star_count

	for i = 1, gotStar do
		layer:addChild(d_ms.d_u.createByStyle({
			pic = "v2/equipAdvanceUI/star_fill.png",
			x = 0.5 + 0.075 * w * (i - 0.5 * (1 + g_self.MAX_STAR_COUNT)),
			y = ys[3]
		}), 5)
	end

	local cur_exp = equipInfo.cur_spirit_count
	local need_exp = nil

	if not isFullAdvance then
		need_exp = g_self.StarCost[equipInfo.csvInfo.quality][equipInfo.csvInfo.mainType][equipInfo.advance_level + 1][equipInfo.star_count + 1]
		local curx = 0.5 + 0.075 * w * (equipInfo.star_count + 1 - 0.5 - 0.5 * (1 + g_self.MAX_STAR_COUNT))
		local starSprite = d_ms.d_u.createByStyle({
			pic = "v2/equipAdvanceUI/star_fill.png",
			x = curx,
			y = ys[3],
			anchor = {
				0,
				0.5
			}
		})
		local starsContentSize = starSprite:getContentSize()

		starSprite:setTextureRect(CCRectMake(0, 0, starsContentSize.width * cur_exp / need_exp, starsContentSize.height))
		layer:addChild(starSprite, 5)
	end

	label = d_ms.d_u.createByStyle({
		pic = "v2/equipAdvanceUI/exp.png",
		x = 0.5 - 0.3466666666666667 * w,
		y = ys[5],
		anchor = {
			0,
			0.5
		}
	})

	if not isFullAdvance then
		str = cur_exp .. "/" .. need_exp
		local labelContentSize = label:getContentSize()

		label:setTextureRect(CCRectMake(0, 0, labelContentSize.width * cur_exp / need_exp, labelContentSize.height))

		g_AdvanceUI.oldExp = {
			star_count = equipInfo.star_count,
			percent = cur_exp / need_exp,
			x = 0.5 - 0.3466666666666667 * w,
			y = ys[5]
		}
	else
		str = "0/0"
	end

	layer:addChild(label)
	layer:addChild(d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		x = 0.5,
		fontsize = 26,
		string = str,
		color = {
			200,
			200,
			200
		},
		y = ys[5]
	}), 5)

	if isFullAdvance then
		layer:addChild(d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			x = 0.5,
			fontsize = 26,
			string = d_ms.d_hz.gethz("advance8"),
			color = {
				200,
				200,
				200
			},
			y = 0.5 * (ys[8] + ys[9])
		}), 5)
	else
		str = d_ms.d_hz.gethz("enhance_consume")

		layer:addChild(d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			fontsize = 26,
			string = str,
			color = {
				187,
				86,
				42
			},
			x = 0.5 - 0.2 * w,
			y = ys[8]
		}))

		local material = g_self.ExpMaterial[equipInfo.csvInfo.mainType]
		local icon = d_ms.d_data.getCertainSmallSprite(material.object_type, material.attach_type)

		d_ms.d_u.setStyles(icon, {
			x = 0.5 - 0.1 * w,
			y = ys[8],
			scale = 0.05 * w
		})
		layer:addChild(icon, 10)

		local need = material.attach_count
		local name = d_ms.d_data.getItemName(material.attach_type)
		local costStr = name .. "X" .. need
		local own = d_ms.d_data.getItemCountByType(material.object_type, material.attach_type)
		local label1 = d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			fontsize = 22,
			string = costStr,
			color = {
				200,
				200,
				200
			}
		})
		local label2 = d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			fontsize = 22,
			string = " (" .. d_ms.d_hz.gethz("advance6"),
			color = {
				200,
				200,
				200
			}
		})
		local label3 = d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			fontsize = 22,
			string = own,
			color = own < need and {
				241,
				67,
				21
			} or {
				178,
				255,
				63
			}
		})
		local label4 = d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			string = ")",
			fontsize = 22,
			color = {
				200,
				200,
				200
			}
		})

		d_ms.d_u.layoutSprites({
			label1,
			label2,
			label3,
			label4
		}, {
			x = 0.5 + 0.15 * w,
			y = ys[8]
		})
		layer:addChild(label1, 10)
		layer:addChild(label2, 10)
		layer:addChild(label3, 10)
		layer:addChild(label4, 10)

		local function pressExp(tag)
			if need <= own then
				local tmp_request = {
					flag = e_a_t.pour_equip,
					equip_order = equipInfo.equip_order,
					is_one_key = tag == 2,
					equip_id = equipInfo.id
				}

				d_ms.d_u.main_server_send_msg(d_ms.d_msg_def.gscl_msg_id.msg_equip_advance, tmp_request)
			else
				local infoStr = d_ms.d_hz.gethz("advance13") .. name

				d_ms.d_info.show(infoStr)
			end
		end

		local btns = {}
		local item_menu_list = {
			{
				npic = "v2/equipAdvanceUI/exp1.png",
				spic = "v2/equipAdvanceUI/exp2.png",
				y = 0,
				tag = 1,
				x = -0.25 * w,
				call_back = pressExp
			},
			{
				npic = "v2/equipAdvanceUI/aexp1.png",
				spic = "v2/equipAdvanceUI/aexp2.png",
				y = 0,
				tag = 2,
				x = 0.25 * w,
				call_back = pressExp
			},
			x = 0.5,
			y = ys[9]
		}

		layer:addChild(d_ms.d_u.createMenu(item_menu_list, btns), 5)

		if own < 5 then
			for k, v in pairs(btns) do
				d_ms.d_u.grayMenuItem(v)
			end
		end
	end
end

function showExpFullInfo()
	local layer = d_ms.d_u.clearLayer(g_AdvanceUI.main_layer, 20, g_self.tags.Advance)

	if not layer then
		return
	end

	local equipInfo = g_AdvanceUI.equipInfo
	local CostList = g_self.AdvanceCost[equipInfo.csvInfo.quality][equipInfo.csvInfo.mainType][equipInfo.advance_level + 1]
	local w = g_self.w
	local h = g_self.h
	local ys = g_self.ys_advance
	local xs = {
		0.5 - 0.2 * w,
		0.5 - 0.05 * w,
		0.5 + 0.075 * w,
		0.5 + 0.2 * w
	}
	local Color = {
		greenow = {
			155,
			155,
			23
		},
		brown = {
			187,
			86,
			42
		},
		light = {
			213,
			194,
			99
		},
		gray = {
			200,
			200,
			200
		},
		red = {
			241,
			67,
			21
		},
		green = {
			178,
			255,
			63
		}
	}
	local str, label = nil
	local menu_btn_list = {
		x = 0,
		y = 0
	}
	local effectTab = g_self.Value[equipInfo.csvInfo.quality][equipInfo.csvInfo.mainType]
	local curEffect = effectTab[equipInfo.advance_level][equipInfo.star_count]
	local nextEffect = effectTab[equipInfo.advance_level + 1][0]

	layer:addChild(d_ms.d_u.createByStyle({
		pic = "v2/equipAdvanceUI/inner.png",
		x = 0.5,
		y = ys[3]
	}))

	str = getNumHZ(equipInfo.advance_level) .. d_ms.d_hz.gethz("jie_hz")

	layer:addChild(d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		fontsize = 26,
		string = str,
		color = Color.gray,
		x = xs[2],
		y = ys[1]
	}), 5)

	str = getNumHZ(equipInfo.advance_level + 1) .. d_ms.d_hz.gethz("jie_hz")

	layer:addChild(d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		fontsize = 26,
		string = str,
		color = Color.greenow,
		x = xs[4],
		y = ys[1]
	}), 5)

	str = d_ms.d_hz.gethz("advance_attr" .. equipInfo.csvInfo.mainType) .. d_ms.d_hz.gethz("advance3") .. ":"

	layer:addChild(d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		fontsize = 26,
		string = str,
		color = Color.brown,
		anchor = {
			1,
			0.5
		},
		x = xs[1],
		y = ys[2]
	}))
	layer:addChild(d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		fontsize = 26,
		string = "+" .. math.floor(curEffect.percent * 100) .. "%",
		color = Color.gray,
		x = xs[2],
		y = ys[2]
	}), 5)
	layer:addChild(d_ms.d_u.createByStyle({
		pic = "v2/trainingUI/up.png",
		rotation = 90,
		x = xs[3],
		y = ys[2]
	}), 5)
	layer:addChild(d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		fontsize = 26,
		string = "+" .. math.floor(nextEffect.percent * 100) .. "%",
		color = Color.greenow,
		x = xs[4],
		y = ys[2]
	}), 5)

	str = d_ms.d_hz.gethz("advance4") .. d_ms.d_hz.gethz("advance_attr" .. equipInfo.csvInfo.mainType) .. ":"

	layer:addChild(d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		fontsize = 26,
		string = str,
		color = Color.brown,
		anchor = {
			1,
			0.5
		},
		x = xs[1],
		y = ys[4]
	}))
	layer:addChild(d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		fontsize = 26,
		string = "+" .. math.floor(curEffect.plus),
		color = Color.gray,
		x = xs[2],
		y = ys[4]
	}), 5)
	layer:addChild(d_ms.d_u.createByStyle({
		pic = "v2/trainingUI/up.png",
		rotation = 90,
		x = xs[3],
		y = ys[4]
	}), 5)
	layer:addChild(d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		fontsize = 26,
		string = "+" .. math.floor(nextEffect.plus),
		color = Color.greenow,
		x = xs[4],
		y = ys[4]
	}), 5)

	if nextEffect.extra and nextEffect.extra > 0 then
		layer:addChild(d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			fontsize = 26,
			string = d_ms.d_hz.gethz("advance7") .. ":",
			color = Color.light,
			anchor = {
				1,
				0.5
			},
			x = xs[1],
			y = ys[5]
		}))

		local descStr = d_ms.d_hz.gethz("advance9") .. d_ms.d_hz.gethz("advance_attr" .. equipInfo.csvInfo.mainType)
		local desc = d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			fontsize = 26,
			string = descStr,
			color = Color.gray
		})
		local num = d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			fontsize = 26,
			string = math.floor(nextEffect.extra * 100) .. "%  ",
			color = Color.greenow
		})
		local up = CCSprite:create("v2/trainingUI/up.png")

		d_ms.d_u.layoutSprites({
			desc,
			num,
			up
		}, {
			x = xs[3],
			y = ys[5]
		})
		layer:addChild(desc, 10)
		layer:addChild(num, 10)
		layer:addChild(up, 10)
	end

	str = d_ms.d_hz.gethz("enhance_consume")

	layer:addChild(d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		fontsize = 26,
		string = str,
		color = Color.brown,
		x = 0.5 - 0.35 * w,
		y = ys[6]
	}))

	local function showIntro(tag)
		local item = CostList[tag]

		if item then
			d_ms.d_data.showDetail(layer, item, 100)
		end
	end

	local isEnough = true
	local material_status = {}

	for i = 1, #CostList do
		local curx = 0.5 - 0.45 * w + i * 0.3 * w
		label = d_ms.d_data.getCertainSmallSprite(CostList[i].object_type, CostList[i].attach_type)

		table.insert(menu_btn_list, {
			x = curx,
			y = ys[6],
			scale = 0.12 * w,
			nsprite = label,
			ssprite = label,
			call_back = showIntro,
			tag = i
		})

		local name = d_ms.d_data.getItemName(CostList[i].attach_type)
		str = name .. "X" .. CostList[i].attach_count

		layer:addChild(d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			fontsize = 22,
			string = str,
			color = Color.brown,
			x = curx,
			y = ys[7]
		}))

		local own = d_ms.d_data.getItemCountByType(CostList[i].object_type, CostList[i].attach_type)
		local need = CostList[i].attach_count
		material_status[i] = {
			name = name,
			isEnough = need <= own
		}
		isEnough = isEnough and need <= own
		local label1 = d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			fontsize = 22,
			string = " (" .. d_ms.d_hz.gethz("advance6"),
			color = Color.gray
		})
		local label2 = d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			fontsize = 22,
			string = own,
			color = need <= own and Color.green or Color.red
		})
		local label3 = d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			string = ")",
			fontsize = 22,
			color = Color.gray
		})

		d_ms.d_u.layoutSprites({
			label1,
			label2,
			label3
		}, {
			x = curx,
			y = ys[8]
		})
		layer:addChild(label1, 10)
		layer:addChild(label2, 10)
		layer:addChild(label3, 10)
	end

	local function pressAdvance()
		if isEnough then
			local tmp_request = {
				flag = e_a_t.advance_equip,
				equip_order = equipInfo.equip_order,
				is_one_key = false,
				equip_id = equipInfo.id
			}

			d_ms.d_u.main_server_send_msg(d_ms.d_msg_def.gscl_msg_id.msg_equip_advance, tmp_request)
		else
			local infoStr = d_ms.d_hz.gethz("advance13")

			for i = 1, #material_status do
				if not material_status[i].isEnough then
					infoStr = infoStr .. material_status[i].name

					break
				end
			end

			d_ms.d_info.show(infoStr)
		end
	end

	local btns = {}

	table.insert(menu_btn_list, 1, {
		npic = "v2/equipAdvanceUI/advance1.png",
		spic = "v2/equipAdvanceUI/advance2.png",
		x = 0.5,
		y = ys[9],
		call_back = pressAdvance
	})
	layer:addChild(d_ms.d_u.createMenu(menu_btn_list, btns), 5)

	if not isEnough then
		d_ms.d_u.grayMenuItem(btns[1])
	end
end

function pressChooseEquip()
	local allEquips = getAdvancableEquipsExcept(g_AdvanceUI.equipInfo and g_AdvanceUI.equipInfo.id)

	if #allEquips == 0 then
		local str = g_AdvanceUI.equipInfo and "advance2" or "advance1"

		d_ms.d_info.show(d_ms.d_hz.gethz(str))

		return
	end

	local layer = CCLayer:create()

	g_AdvanceUI.main_layer:addChild(layer, 200)
	d_ms.d_u.createSwallowTouchLayer(layer)

	local bkg_small = CCSprite:create("v2/common/frame3.png")

	d_ms.d_u.setStyles(bkg_small, {
		scaleY = 0.95,
		scaleX = 0.55,
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

	local touchArea = {
		x = 0.25 * scrSize.width,
		y = 0.05 * scrSize.height,
		width = 0.5 * scrSize.width,
		height = 0.9 * scrSize.height
	}
	local advanceTableView = d_ms.d_tableView.tableView(layer, touchArea)
	local dataSource = getAdvanceCellsDataSource(allEquips)

	advanceTableView:startScroll()
	advanceTableView:setDataSource(dataSource)
end

function getAdvancableEquipsExcept(id)
	local allEquips = {}
	local allItems = d_ms.d_packageUI.g_reorgItemsInfo[o_t.item]

	for k, v in pairs(allItems) do
		if k <= m_t.talismans then
			for m, n in pairs(v) do
				if (not id or n.id ~= id) and n.csvInfo.quality >= 4 then
					table.insert(allEquips, n)
				end
			end
		end
	end

	table.sort(allEquips, d_ms.d_packageUI.packageSortFunc)

	return allEquips
end

function getAdvanceCellsDataSource(equips)
	local cellSize = CCSizeMake(0.5 * scrSize.width, 0.2 * scrSize.height)
	local bkgPic = "v2/charPositionUI/item_bkg.png"
	local dataSource = {}
	local num = #equips

	function dataSource.tableViewNumberOfRows()
		return num
	end

	function dataSource.drawCellAtIndex(index)
		local cell = CCNode:create()

		if equips[index] then
			createCellOnAdvance(cell, equips[index], bkgPic, cellSize)
		end

		return cell
	end

	function dataSource.heightForRowAtIndex(index)
		return cellSize.height
	end

	return dataSource
end

function createCellOnAdvance(parent, itemInfo, bkgPic, cellSize)
	d_ms.d_createCell.createCellWithOwnerNoBtn(parent, itemInfo, bkgPic, cellSize)

	local function changeEquip()
		g_AdvanceUI.equipInfo = itemInfo

		refreshFrame()
	end

	local btnPic = g_AdvanceUI.equipInfo and g_self.btnPicsList.change or g_self.btnPicsList.choose
	local changeButtonItem = CCMenuItemImage:create(btnPic[1], btnPic[2])

	changeButtonItem:setPosition(cellSize.width * 0.85, cellSize.height * 0.25)
	changeButtonItem:registerScriptTapHandler(changeEquip)

	local changeMenu = CCMenu:createWithItem(changeButtonItem)

	changeMenu:setPosition(0, 0)
	parent:addChild(changeMenu, 5)
end

function getNumHZ(num)
	if not g_self.NumHZ then
		g_self.NumHZ = {}
		local str = d_ms.d_hz.gethz("numHZ")

		for i = 1, #str / 3 do
			g_self.NumHZ[i - 1] = string.sub(str, 3 * i - 2, 3 * i)
		end
	end

	return g_self.NumHZ[num]
end

function getExtraInfo(quality, mainType)
	d_ms.d_data.getEquipAdvanceValue()

	local value = d_ms.d_data.g_equipAdvanceValueTab
	value = value[quality][mainType]
	local descTab = {}

	for i = 1, #value do
		if value[i][0] and value[i][0].extra and value[i][0].extra > 0 then
			local desc = {
				"(" .. getNumHZ(i) .. d_ms.d_hz.gethz("jie_hz") .. ")",
				d_ms.d_hz.gethz("advance9") .. d_ms.d_hz.gethz("advance_attr" .. mainType) .. d_ms.d_hz.gethz("increase") .. math.floor(value[i][0].extra * 100) .. "%",
				level = i
			}

			table.insert(descTab, desc)
		end
	end

	return descTab
end
