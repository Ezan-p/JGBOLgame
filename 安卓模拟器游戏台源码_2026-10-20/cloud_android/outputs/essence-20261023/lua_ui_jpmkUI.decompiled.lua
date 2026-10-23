local require = require
local string = string
local math = math
local os = os
local io = io
local table = table
local tolua = tolua
local tonumber = tonumber
local tostring = tostring
local ccp = ccp
local main_server = main_server
local math = math
local pairs = pairs
local ccc4 = ccc4
local package = package
local CCMenuItemImage = CCMenuItemImage
local CCMenu = CCMenu
local CCNode = CCNode
local CCSprite = CCSprite
local CCLayer = CCLayer
local CCScrollView = CCScrollView
local CCLuaLog = CCLuaLog
local CCRectMake = CCRectMake
local CCPointMake = CCPointMake
local CCSizeMake = CCSizeMake
local CCDirector = CCDirector
local CCLayerColor = CCLayerColor

module("ui.jpmkUI")

d_ms = require("ms")

if not d_ms then
	CCLuaLog("load d_ms fail.")
end

local function cclog(...)
	CCLuaLog(string.format("jpmkUI %s", string.format(...)))
end

g_only_tag = 66005
local o_t = d_ms.d_common_def.object_type
local m_t = d_ms.d_common_def.item_main_type
local MAX_JP = 4
local scrSize = CCDirector:sharedDirector():getVisibleSize()
MAX_LV = 5
local UPGRADE_COST = {
	500,
	1000,
	1500,
	3000
}
g_self = {}

function show(layer, z_order, cort_id)
	g_self.p_layer = layer
	g_self.z_order = z_order
	g_self.cort_id = cort_id

	if d_ms.d_mainUI.g_playerInfo.level < 38 then
		d_ms.d_info.show(d_ms.d_hz.gethz("jpmk_no_38"))

		return
	end

	if not g_self.LockPrice then
		d_ms.d_data.getExtSkillLockPrice()

		g_self.LockPrice = d_ms.d_data.g_ext_skill_lock_price
	end

	create()
end

function onJPChanged(item)
	cclog("call onJPChanged")

	if item then
		g_self.selected_jp_id = item.id
		g_self.selected_type_id = item.type_id
		g_self.selected_jp_name = item.csvInfo.name
	else
		g_self.selected_jp_id = nil
		g_self.selected_type_id = nil
		g_self.selected_jp_name = nil
	end

	if g_self.selected_jp_id and g_self.selected_type_id and g_self.selected_jp_name then
		g_self.main_layer:removeChildByTag(10002, true)
		g_self.main_layer:removeChildByTag(10001, true)
		g_self.main_layer:removeChildByTag(10003, true)

		local jp_sprite = d_ms.d_data.getSmallItemSprite(g_self.selected_type_id)

		if jp_sprite then
			d_ms.d_u.setStyles(jp_sprite, {
				tag = 10001,
				x = 0.5 + 0.36 * g_self.w,
				y = 0.5 + 0.032 * g_self.h,
				scale = g_self.w * 0.12
			})
			g_self.main_layer:addChild(jp_sprite, 200)
			g_self.main_layer:addChild(d_ms.d_u.createByStyle({
				tag = 10003,
				type = "label",
				fontsize = 26,
				string = g_self.selected_jp_name,
				x = 0.5 + 0.36 * g_self.w,
				y = 0.5 - 0.11 * g_self.h,
				color = {
					224,
					174,
					111
				}
			}), 201)
		else
			cclog("ERROR: selected_jp_id error = " .. (g_self.selected_jp_id or "nil"))

			g_self.selected_jp_id = nil
		end
	end
end

function reBuild()
	create()
end

function create()
	cclog("call create")

	local layer = g_self.p_layer
	local z_order = g_self.z_order
	local blackmask = CCLayerColor:create(ccc4(0, 0, 0, 100))

	d_ms.d_u.addOnlyChild(layer, blackmask, g_only_tag, z_order)

	g_self.main_layer = blackmask

	blackmask:addChild(d_ms.d_u.createByStyle({
		opacity = 200,
		pic = "v2/guideUI/mask.png",
		y = 0.5,
		scaleX = 1,
		x = 0.5,
		scaleY = 1
	}))
	d_ms.d_u.createSwallowTouchLayer(blackmask)

	local frame_bkg = d_ms.d_u.createByStyle({
		pic = "v2/jpmkUI/bkg.png",
		x = 0.5,
		y = 0.5
	})

	blackmask:addChild(frame_bkg, 2)

	local w, h = d_ms.d_u.getRealScale(frame_bkg)
	g_self.w = w
	g_self.h = h
	local title = d_ms.d_u.createByStyle({
		pic = "v2/jpmkUI/title.png",
		x = 0.5,
		y = 0.5 + h * 0.42
	})

	blackmask:addChild(title, 3)

	local lub_bkg_down = d_ms.d_u.createByStyle({
		pic = "v2/jpmkUI/bkg2.png",
		x = 0.5 + w * 0.355,
		y = 0.5 + h * 0.01
	})

	blackmask:addChild(lub_bkg_down, 3)

	local this_char = getCharInfoById(g_self.cort_id)

	if this_char and this_char.equiped_ext_skill_limit < 4 and this_char.next_ext_skill_luck_point and this_char.next_ext_skill_luck_point >= 0 then
		local luck_tink = d_ms.d_hz.gethz("jpmk_luck_point") .. this_char.next_ext_skill_luck_point

		blackmask:addChild(d_ms.d_u.createByStyle({
			type = "label",
			fontsize = 26,
			string = luck_tink,
			x = 0.5 + w * 0.355,
			y = 0.5 + h * 0.23,
			color = {
				154,
				254,
				111
			}
		}), 5)
	end

	blackmask:addChild(d_ms.d_u.createByStyle({
		type = "label",
		fontsize = 26,
		string = d_ms.d_hz.gethz("jpmk_tink1"),
		x = 0.5 - w * 0.45,
		y = 0.5 - h * 0.4,
		anchor = {
			0,
			0.5
		},
		font_rect = {
			w * 0.9,
			0
		},
		color = {
			210,
			180,
			140
		}
	}), 5)

	local function close_me()
		if g_self.p_layer:getChildByTag(d_ms.d_mainUI.boardID.charPosition) then
			d_ms.d_charPositionUI.reloadItemSkillInfo()
		elseif g_self.p_layer:getChildByTag(d_ms.d_mainUI.boardID.lineup) then
			d_ms.d_lineupUI.showJingpo()
		end

		g_self.selected_jp_id = nil
		g_self.selected_type_id = nil
		g_self.selected_jp_name = nil

		d_ms.d_u.remove(blackmask)
		clean_code_win32()
	end

	local function pressSelectMK()
		cclog("call pressSelectMK")
	end

	local btns = {}
	local menu_btn_list = {
		{
			scalexx = 0.1,
			npic = "v2/common/close1.png",
			spic = "v2/common/close2.png",
			x = 0.5 + w * 0.45,
			y = 0.5 + h * 0.45,
			call_back = close_me
		},
		{
			scalexx = 0.1,
			npic = "v2/jpmkUI/mk1.png",
			spic = "v2/jpmkUI/mk2.png",
			x = 0.5 + w * 0.36,
			y = 0.5 - h * 0.21,
			call_back = pressConfirmJP
		},
		{
			opacity = 0,
			scale = 0.13,
			spic = "v2/empty_mask.png",
			npic = "v2/empty_mask.png",
			x = 0.5 + 0.36 * w,
			y = 0.5 + 0.032 * h,
			call_back = pressSelectJP
		},
		x = 0,
		y = 0
	}
	local jp_data = getJP(g_self.cort_id)
	g_self.installed_jp_map = {}

	for i = 1, 4 do
		local y_ = 0.5 + h * 0.26 - (i - 1) * h * 0.17

		if i < 4 then
			local jp_sprite = d_ms.d_u.createByStyles({
				pic = "v2/jpmkUI/inter.png",
				x = 0.5 - w * 0.12,
				y = y_ - h * 0.08,
				scaleX = w * 0.66
			})

			blackmask:addChild(jp_sprite, 11)
		end

		if jp_data[i] then
			local jp_sprite = d_ms.d_u.createByStyles({
				pic = "skill/ext/" .. jp_data[i].csvInfo.file .. ".png",
				x = 0.5 - w * 0.4,
				y = y_,
				scale = h * 0.08
			})

			blackmask:addChild(jp_sprite, 11)

			local jp_sprite_w, jp_sprite_h = d_ms.d_u.getRealScale(jp_sprite)

			blackmask:addChild(d_ms.d_u.createByStyle({
				type = "label",
				fontsize = 26,
				string = "lv" .. (jp_data[i].level or 1),
				x = 0.5 - w * 0.4 - 0.4 * jp_sprite_w,
				y = y_ + 0.45 * jp_sprite_h,
				color = {
					178,
					255,
					63
				},
				anchor = {
					0,
					1
				}
			}), 12)
			blackmask:addChild(d_ms.d_u.createByStyle({
				type = "label",
				fontsize = 26,
				string = jp_data[i].csvInfo.name,
				x = 0.5 - w * 0.35,
				y = y_ + h * 0.05,
				color = {
					224,
					174,
					111
				},
				anchor = {
					0,
					0.5
				}
			}), 5)
			blackmask:addChild(d_ms.d_u.createByStyle({
				type = "label",
				fontsize = 22,
				string = d_ms.d_hz.gethz("jpmk_update"),
				x = 0.5 - w * 0.2,
				y = y_ + h * 0.048,
				color = {
					224,
					174,
					181
				},
				anchor = {
					0,
					0.5
				}
			}), 5)

			local rate = 0

			if jp_data[i].level < 1 then
				jp_data[i].level = 1
			end

			local progress_tink = nil
			local jp_mat_need = 0

			if MAX_LV <= jp_data[i].level then
				rate = 1
				progress_tink = UPGRADE_COST[MAX_LV - 1] .. "/" .. UPGRADE_COST[MAX_LV - 1] .. "    100%"
			else
				rate = jp_data[i].prob_compen / UPGRADE_COST[jp_data[i].level]
				jp_mat_need = UPGRADE_COST[jp_data[i].level] - jp_data[i].prob_compen
				progress_tink = jp_data[i].prob_compen .. "/" .. UPGRADE_COST[jp_data[i].level] .. "    " .. math.floor(rate * 100) .. "%"
			end

			blackmask:addChild(d_ms.d_u.createByStyle({
				pic = "v2/jpmkUI/progress2.png",
				x = 0.5 - w * 0.1,
				y = y_ + h * 0.048,
				scaleX = w * 0.18,
				anchor = {
					0,
					0.5
				}
			}), 10)
			blackmask:addChild(d_ms.d_u.createByStyle({
				pic = "v2/jpmkUI/progress1.png",
				x = 0.5 - w * 0.1,
				y = y_ + h * 0.048,
				scaleX = w * 0.18 * rate,
				anchor = {
					0,
					0.5
				}
			}), 10)
			blackmask:addChild(d_ms.d_u.createByStyle({
				type = "label",
				fontsize = 22,
				string = progress_tink,
				x = 0.5 - w * 0.08,
				y = y_ + h * 0.048,
				color = {
					224,
					174,
					181
				},
				anchor = {
					0,
					0.5
				}
			}), 15)

			local decStr = jp_data[i].csvInfo.ext_skill_desc[jp_data[i].level] or ""
			local txt = d_ms.d_u.createByStyle({
				h_align = 0,
				type = "label",
				fontsize = 22,
				font = "arial",
				string = decStr,
				anchor = {
					0,
					1
				},
				x = 0.5 - w * 0.35,
				y = y_ + h * 0.01,
				font_rect = {
					0.42 * w,
					0
				},
				color = {
					180,
					160,
					150
				}
			})

			blackmask:addChild(txt, 5)

			g_self.installed_jp_map[i] = jp_data[i]

			table.insert(menu_btn_list, {
				scalexx = 0.1,
				npic = "v2/jpmkUI/up1.png",
				spic = "v2/jpmkUI/up2.png",
				x = 0.5 + w * 0.16,
				y = y_ + h * 0.03,
				tag = i,
				call_back = pressUpdateJP
			})

			local jp_mat_count = d_ms.d_data.getItemCountByType(o_t.item, 10000)
			jp_mat_need = math.min(jp_mat_need, jp_mat_count, 500)
			local mat_count_color = jp_mat_need <= jp_mat_count and {
				0,
				255,
				0
			} or {
				255,
				0,
				0
			}
			local form_style_inner1 = {
				{
					font = "arial",
					intval_len = 0.001,
					type = "label",
					fontsize = 22,
					string = d_ms.d_hz.gethz("enhance_consume"),
					anchor = {
						0,
						0.5
					},
					color = {
						250,
						250,
						150
					}
				},
				{
					pic = "v2/jpmkUI/jp4.png",
					intval_len = 0.001,
					scaleH = h * 0.06,
					anchor = {
						0,
						0.5
					}
				},
				{
					font = "arial",
					intval_len = 0.001,
					type = "label",
					fontsize = 22,
					string = "x" .. jp_mat_need,
					anchor = {
						0,
						0.5
					},
					color = {
						245,
						170,
						80
					}
				},
				{
					font = "arial",
					intval_len = 0.001,
					type = "label",
					fontsize = 22,
					string = "/" .. jp_mat_count,
					anchor = {
						0,
						0.5
					},
					color = mat_count_color
				},
				type = "x__",
				z = 30,
				x = 0.5 + w * 0.08,
				y = y_ - h * 0.05,
				layer = blackmask
			}

			d_ms.d_form.createSeq(form_style_inner1)
		else
			local not_set_pic = "v2/jpmkUI/jp_no_open.png"

			if this_char.equiped_ext_skill_limit and i <= this_char.equiped_ext_skill_limit and d_ms.d_mainUI.g_playerInfo.level >= 38 then
				not_set_pic = "v2/jpmkUI/jp_bkg.png"
			else
				local open_tink2 = string.format(d_ms.d_hz.gethz("jpmk_tink2"), i * 6 - 6)

				if i == 4 then
					open_tink2 = d_ms.d_hz.gethz("jpmk_tink3")
				end

				blackmask:addChild(d_ms.d_u.createByStyle({
					type = "label",
					fontsize = 26,
					string = open_tink2,
					x = 0.5 - w * 0.35,
					y = y_,
					anchor = {
						0,
						0.5
					},
					color = {
						254,
						194,
						111
					}
				}), 5)
			end

			local jp_sprite = d_ms.d_u.createByStyles({
				pic = not_set_pic,
				x = 0.5 - w * 0.4,
				y = y_,
				scale = h * 0.08
			})

			blackmask:addChild(jp_sprite, 11)
		end
	end

	blackmask:addChild(d_ms.d_u.createMenu(menu_btn_list, btns), 10)
	onJPChanged()
end

function createJpmkCell(parentNode, info, bkgPic, cellSize)
	local bkgSprite = CCSprite:create(bkgPic)

	bkgSprite:setPosition(ccp(cellSize.width * 0.5, cellSize.height * 0.5))
	parentNode:addChild(bkgSprite, -1)

	local bkgScaleX = cellSize.width / bkgSprite:getContentSize().width

	bkgSprite:setScaleX(bkgScaleX)

	local type_id = info.type_id
	local csvInfo = info.csvInfo or d_ms.d_data.getCertainInfo(o_t.item, type_id)
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

	local quality = csvInfo.quality

	if quality and quality > 0 then
		local qualityRatio = csvInfo.quality / 5
		local starsLevelSprite = CCSprite:create("v2/introUI/stars.png")

		parentNode:addChild(starsLevelSprite, 1)
		starsLevelSprite:setPosition(cellSize.width * 0.43, cellSize.height * 0.7)
		starsLevelSprite:setAnchorPoint(ccp(0, 0.5))

		local starsContentSize = starsLevelSprite:getContentSize()

		starsLevelSprite:setTextureRect(CCRectMake(0, 0, starsContentSize.width * qualityRatio, starsContentSize.height))
	end

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
	end

	parentNode:addChild(d_ms.d_u.createByStyle({
		pic = "v2/introUI/level.png",
		pos_x = cellSize.width * 0.22,
		pos_y = cellSize.height * 0.33
	}))
	parentNode:addChild(d_ms.d_u.createByStyle({
		type = "label",
		font = "arial",
		fontsize = 26,
		string = "" .. (info.level or 1),
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

	local iconSprite1 = d_ms.d_data.getCertainSmallSprite(o_t.item, type_id)
	local iconSprite2 = d_ms.d_data.getCertainSmallSprite(o_t.item, type_id)

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

	local menuItemsDefs = {
		menuItems = {
			{
				nSprite = iconSprite1,
				sSprite = iconSprite2,
				tapHandler = showDetail,
				pos = ccp(cellSize.width * 0.1, cellSize.height * 0.5)
			}
		},
		priority = -128,
		usedDefaultRect = true
	}
	local menuLayer = d_ms.d_tableView.createTableViewMenu(menuItemsDefs)

	parentNode:addChild(menuLayer)
end

function pressSelectJP()
	cclog("pressSelectJP")
	g_self.p_layer:removeChild(g_self.main_layer, true)

	g_self.main_layer = nil

	d_ms.d_jpUI.show(g_self.p_layer, g_self.z_order, g_self.cort_id)
end

function pressConfirmJP()
	cclog("pressConfirmJP")
	pressSelectJP()

	return

	if not g_self.selected_jp_id or not g_self.selected_jp_name or not g_self.selected_type_id then
		pressSelectJP()
	else
		local jp_data = getJP(g_self.cort_id)
		local cort_info = getCharInfoById(g_self.cort_id)
		local tipInfo = nil
		local canLock = false

		if #jp_data == cort_info.equiped_ext_skill_limit then
			local hasHigh = false
			local mustReplace = false

			for k, v in pairs(jp_data) do
				if v.csvInfo.quality == 5 then
					hasHigh = true
				end

				if v.type_id == g_self.selected_type_id - 100 then
					mustReplace = true
				end
			end

			if mustReplace then
				tipInfo = d_ms.d_hz.gethz("jpmk_tink5")
			elseif hasHigh then
				canLock = true
			end
		end

		if tipInfo then
			local params_table = {
				string = tipInfo
			}

			d_ms.d_quitUI.createYesNoByStyle(g_self.main_layer, params_table, send_change_jp_req)
		elseif canLock then
			showJPLockLayer(jp_data)
		else
			send_change_jp_req()
		end
	end
end

function send_change_jp_req(lock_list)
	cclog("call send_change_jp_req")

	lock_list = lock_list or {}
	local tmp_request = {
		ext_skill_id = g_self.selected_jp_id,
		des_cortege_id = g_self.cort_id,
		lock_list = table.tostring(lock_list)
	}

	d_ms.d_u.main_server_send_msg(d_ms.d_msg_def.gscl_msg_id.msg_equip_ext_skill, tmp_request)
end

function callback_change_jp_req(data)
	d_ms.d_jpUI.callback_change_jp_req(data)
end

function callback_update_jp_req(data)
	cclog("callback_update_jp_req ")

	if data.result ~= 0 then
		d_ms.d_info.show(d_ms.d_hz.gethz("operation_failed"))
	end

	reBuild()
end

function pressUpdateJP(tag)
	cclog("call pressUpdateJP, tag=" .. tag)

	if g_self.installed_jp_map and g_self.installed_jp_map[tag] then
		local jp_data = g_self.installed_jp_map[tag]

		if MAX_LV <= jp_data.level then
			d_ms.d_info.show(d_ms.d_hz.gethz("skill_up_level_top"))

			return
		end

		local own = d_ms.d_data.getItemCountByType(o_t.item, 10000)

		if own == 0 then
			d_ms.d_info.show(d_ms.d_hz.gethz("jpmk_no_mat3"))

			return
		end

		local need = UPGRADE_COST[jp_data.level] - jp_data.prob_compen
		local tmp_request = {
			ext_skill_id = jp_data.id,
			cost_count = math.min(500, own, need)
		}

		d_ms.d_u.main_server_send_msg(d_ms.d_msg_def.gscl_msg_id.msg_upgrade_ext_skill, tmp_request)
	else
		cclog("ERROR, call pressUpdateJP, but can not find jp_id by tag=" .. tag)
	end
end

function sameAsInstalled(jp)
	for i, v in pairs(g_self.installed_jp_map) do
		if v.csvInfo.file == jp.csvInfo.file then
			return true
		end
	end

	return false
end

function createSkillMutilSelectLayer(parent_layer)
	g_self.cortegeInfos = {}
	local data = d_ms.d_c.table_copy(d_ms.d_packageUI.g_reorgItemsInfo[o_t.item][m_t.ext_skill] or {})

	local function hasInBox(jp)
		for i, v in pairs(g_self.cortegeInfos) do
			if v.csvInfo.file == jp.csvInfo.file then
				v.count = v.count + 1

				return true
			end
		end

		return false
	end

	for i, v in pairs(data) do
		if v.owner_id > 0 then
			-- Nothing
		elseif v.count <= 0 then
			cclog("0")
		elseif sameAsInstalled(v) then
			-- Nothing
		elseif not hasInBox(v) then
			table.insert(g_self.cortegeInfos, v)
		end
	end

	if #g_self.cortegeInfos <= 0 then
		d_ms.d_info.show(d_ms.d_hz.gethz("jpmk_no_mat"))

		return
	end

	table.sort(g_self.cortegeInfos, jpSort)

	local layer = CCLayer:create()

	layer:setTag(10002)
	g_self.main_layer:addChild(layer, 200)
	d_ms.d_u.createSwallowTouchLayer(layer)

	local bkg_small = CCSprite:create("v2/common/frame3.png")

	d_ms.d_u.setStyles(bkg_small, {
		scaleY = 0.95,
		scaleX = 0.54,
		x = 0.5,
		y = 0.5
	})
	layer:addChild(bkg_small)
	layer:addChild(d_ms.d_u.createByStyle({
		y = 0.925,
		font = "arial",
		type = "label",
		x = 0.26,
		fontsize = 26,
		string = d_ms.d_hz.gethz("jpmk_tink4"),
		anchor = {
			0,
			0.5
		},
		color = {
			255,
			200,
			100
		}
	}))

	local function call_back_close()
		d_ms.d_u.remove(layer)

		layer = nil
	end

	local item_menu_list = {
		{
			npic = "v2/introUI/close1.png",
			spic = "v2/introUI/close2.png",
			y = 0.95,
			x = 0.77,
			call_back = call_back_close
		},
		x = 0,
		y = 0
	}

	layer:addChild(d_ms.d_u.createMenu(item_menu_list), 10)

	local function equipSelected(tag)
		d_ms.d_u.remove(layer)

		layer = nil

		onJPChanged(allEquips[tag])
	end

	local touchArea = {
		x = 0.25 * scrSize.width,
		y = 0.05 * scrSize.height,
		width = 0.5 * scrSize.width,
		height = 0.85 * scrSize.height
	}
	local slotTableView = d_ms.d_tableView.tableView(layer, touchArea)
	local cellSize = CCSizeMake(0.5 * scrSize.width, 0.2 * scrSize.height)
	local dataSource = getEquipDataSource(g_self.cortegeInfos, cellSize)

	slotTableView:startScroll()
	slotTableView:setDataSource(dataSource)
end

function getEquipDataSource(list, cellSize)
	local bkgPic = "v2/charPositionUI/item_bkg.png"
	local dataSource = {}
	local num = #list

	function dataSource.tableViewNumberOfRows()
		return num
	end

	function dataSource.drawCellAtIndex(index)
		local cell = CCNode:create()

		if list[index] then
			createCellOnSlot(cell, list[index], bkgPic, cellSize)
		end

		return cell
	end

	function dataSource.heightForRowAtIndex(index)
		return cellSize.height
	end

	return dataSource
end

function createCellOnSlot(parent, itemInfo, bkgPic, cellSize)
	d_ms.d_createCell.createCellWithOwnerNoBtn(parent, itemInfo, bkgPic, cellSize)

	local parentNode = parent
	local info = itemInfo
	local csvInfo = itemInfo.csvInfo
	local quality = csvInfo.quality

	if quality and quality > 0 then
		local qualityRatio = csvInfo.quality / 5
		local starsLevelSprite = CCSprite:create("v2/introUI/stars.png")

		parentNode:addChild(starsLevelSprite, 1)
		starsLevelSprite:setPosition(cellSize.width * 0.43, cellSize.height * 0.7)
		starsLevelSprite:setAnchorPoint(ccp(0, 0.5))

		local starsContentSize = starsLevelSprite:getContentSize()

		starsLevelSprite:setTextureRect(CCRectMake(0, 0, starsContentSize.width * qualityRatio, starsContentSize.height))
	end

	parentNode:addChild(d_ms.d_u.createByStyle({
		pic = "v2/introUI/level.png",
		pos_x = cellSize.width * 0.45,
		pos_y = cellSize.height * 0.31
	}))
	parentNode:addChild(d_ms.d_u.createByStyle({
		type = "label",
		font = "arial",
		fontsize = 30,
		string = "" .. (info.level or 1),
		anchor = {
			0,
			0.5
		},
		color = {
			253,
			190,
			37
		},
		pos_x = cellSize.width * 0.5,
		pos_y = cellSize.height * 0.31
	}))

	local function changeEquip()
		onJPChanged(itemInfo)
	end

	local changeButtonItem = CCMenuItemImage:create("v2/introUI/choose1.png", "v2/introUI/choose2.png")

	changeButtonItem:setPosition(cellSize.width * 0.85, cellSize.height * 0.25)
	changeButtonItem:registerScriptTapHandler(changeEquip)

	local changeMenu = CCMenu:createWithItem(changeButtonItem)

	changeMenu:setPosition(0, 0)
	parent:addChild(changeMenu, 5)
end

function clean_code_win32()
	if d_ms.d_u.isWin32() then
		package.loaded["ui.jpmkUI"] = nil
		d_ms.d_levelUpBuffUI = require("ui.jpmkUI")
	end
end

function jpSort(a, b)
	local a_pri = 10000
	local b_pri = 10000

	if a.owner_id > 0 then
		a_pri = a_pri - 1000
	end

	if b.owner_id > 0 then
		b_pri = b_pri - 1000
	end

	a_pri = a_pri - a.csvInfo.quality * 100 - a.level * 10
	b_pri = b_pri - b.csvInfo.quality * 100 - b.level * 10

	if a.type_id < b.type_id then
		b_pri = b_pri + 1
	end

	return a_pri < b_pri
end

function getJP(cort_id)
	cclog("call getJP")

	local ret = {}

	if d_ms.d_packageUI.g_reorgItemsInfo[o_t.item] and d_ms.d_packageUI.g_reorgItemsInfo[o_t.item][m_t.ext_skill] then
		local ext_skill_table = d_ms.d_packageUI.g_reorgItemsInfo[o_t.item][m_t.ext_skill]

		for i, v in pairs(ext_skill_table) do
			if v.owner_id > 0 and v.owner_id == cort_id then
				table.insert(ret, v)
			end
		end
	end

	table.sort(ret, sort_jp)

	return ret
end

function sort_jp(a, b)
	if a.ext_skill_pos and b.ext_skill_pos then
		return a.ext_skill_pos < b.ext_skill_pos
	end

	return false
end

function getCharInfoById(cort_id)
	for i, v in pairs(d_ms.d_lineupUI.g_characterInfo) do
		if v.id == cort_id then
			return v
		end
	end

	cclog("ERROR: getCharInfoById error, id =" .. (cort_id or "nil"))

	return nil
end

function showJPLockLayer(jp_data)
	local layer = CCLayer:create()

	d_ms.d_u.createSwallowTouchLayer(layer)
	layer:addChild(CCLayerColor:create(ccc4(0, 0, 0, 100)), -1)

	local bkg_big = CCSprite:create("v2/messageUI/frame1.png")

	d_ms.d_u.setStyles(bkg_big, {
		x = 0.5,
		y = 0.5
	})
	layer:addChild(bkg_big)

	local w, h = d_ms.d_u.getRealScale(bkg_big)

	layer:addChild(d_ms.d_u.createByStyle({
		pic = "v2/messageUI/frame2.png",
		x = 0.5,
		y = 0.5
	}))
	layer:addChild(d_ms.d_u.createByStyle({
		pic = "v2/messageUI/tishi.png",
		x = 0.5,
		y = 0.5 + 0.42 * h
	}))
	layer:addChild(d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		x = 0.5,
		fontsize = 26,
		string = d_ms.d_hz.gethz("jpmk_tink6"),
		y = 0.5 + 0.25 * h,
		color = {
			225,
			207,
			185
		}
	}))
	layer:addChild(d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		x = 0.5,
		fontsize = 26,
		string = d_ms.d_hz.gethz("jpmk_tink8"),
		y = 0.5 + 0.15 * h,
		color = {
			255,
			100,
			100
		}
	}))

	local lock_list = {}
	local btns = {}

	local function getLockCount()
		local count = 0
		local total = 0

		for k, v in pairs(lock_list) do
			if v.isLock then
				count = count + 1
			end

			total = total + 1
		end

		if total == MAX_JP then
			total = MAX_JP - 1
		end

		return count, total
	end

	local function showCost()
		local count, total = getLockCount()

		layer:removeChildByTag(11, true)

		local node = CCNode:create()
		local left = d_ms.d_u.createByStyle({
			font = "arial",
			fontsize = 26,
			type = "label",
			string = d_ms.d_hz.gethz("enhance_consume")
		})
		local mid = CCSprite:create("v2/money_gold.png")
		local right = d_ms.d_u.createByStyle({
			font = "arial",
			fontsize = 26,
			type = "label",
			string = "X" .. (g_self.LockPrice[count] or 0) .. "   (" .. d_ms.d_hz.gethz("jpmk2") .. ": "
		})
		local lockColor = count == total and {
			0,
			255,
			0
		} or {
			255,
			100,
			100
		}
		local localDesc = d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			fontsize = 26,
			string = tostring(count) .. "/" .. total,
			color = lockColor
		})
		local clouse = d_ms.d_u.createByStyle({
			string = ")",
			font = "arial",
			fontsize = 26,
			type = "label"
		})

		d_ms.d_u.layoutSprites({
			left,
			mid,
			right,
			localDesc,
			clouse
		}, {
			x = 0,
			y = 0
		})
		node:addChild(left)
		node:addChild(mid)
		node:addChild(right)
		node:addChild(localDesc)
		node:addChild(clouse)
		d_ms.d_u.setStyles(node, {
			x = 0.5,
			y = 0.5 - 0.27 * h
		})
		layer:addChild(node, 1, 11)
	end

	local function dismiss()
		d_ms.d_u.remove(layer)
	end

	local function slot()
		local count = 0
		local total = 0
		local list = {}

		for k, v in pairs(lock_list) do
			if v.isLock then
				count = count + 1

				table.insert(list, v.index)
			end

			total = total + 1
		end

		if total == MAX_JP then
			total = MAX_JP - 1
		end

		if g_self.LockPrice[count] and d_ms.d_mainUI.g_playerInfo.gold_coin < g_self.LockPrice[count] then
			d_ms.d_summonUI.needGold(layer, false)
		else
			local function send()
				table.sort(list)
				send_change_jp_req(list)
			end

			if count == total then
				send()
			else
				local params_table = {
					string = d_ms.d_hz.gethz("jpmk_tink9")
				}

				d_ms.d_quitUI.createYesNoByStyle(g_self.main_layer, params_table, send)
			end
		end
	end

	local function lock(tag)
		local record = lock_list[tag]
		local count = getLockCount()

		if count == MAX_JP - 1 and not record.isLock then
			d_ms.d_info.show(string.format(d_ms.d_hz.gethz("jpmk_tink7"), MAX_JP - 1))

			return
		end

		record.isLock = not record.isLock
		local file = nil

		if record.isLock then
			count = count + 1
			file = "v2/jpmkUI/lock.png"
		else
			count = count - 1
			file = "v2/jpmkUI/unlock.png"
		end

		btns[2 + tag]:setNormalImage(CCSprite:create(file))
		btns[2 + tag]:setSelectedImage(CCSprite:create(file))
		showCost()
	end

	local menu_btn_list = {
		{
			npic = "v2/multi-selectUI/ensure1.png",
			spic = "v2/multi-selectUI/ensure2.png",
			x = 0.5 + w * 0.25,
			y = 0.5 - h * 0.41,
			call_back = slot
		},
		{
			npic = "v2/buttons/cancel1.png",
			spic = "v2/buttons/cancel2.png",
			x = 0.5 - w * 0.25,
			y = 0.5 - h * 0.41,
			call_back = dismiss
		},
		x = 0,
		y = 0
	}
	local dx = 0.2 * w
	local ys = {
		0.5 + 0 * h,
		0.5 - 0.15 * h
	}

	for i = 1, MAX_JP do
		local mx = 0.5 + (i - 0.5 * (1 + MAX_JP)) * dx

		if jp_data[i] then
			local jp_sprite = d_ms.d_u.createByStyles({
				pic = "skill/ext/" .. jp_data[i].csvInfo.file .. ".png",
				x = mx,
				y = ys[1],
				scale = 0.16 * w
			})

			layer:addChild(jp_sprite, 11)

			if jp_data[i].csvInfo.quality == 5 then
				table.insert(lock_list, {
					isLock = false,
					index = i
				})
				table.insert(menu_btn_list, {
					npic = "v2/jpmkUI/unlock.png",
					spic = "v2/jpmkUI/unlock.png",
					x = mx,
					y = ys[2],
					scale = 0.12 * w,
					tag = #lock_list,
					call_back = lock
				})
			end
		else
			local jp_sprite = d_ms.d_u.createByStyles({
				pic = "v2/jpmkUI/jp_no_open.png",
				x = mx,
				y = ys[1],
				scale = 0.16 * w
			})

			layer:addChild(jp_sprite, 11)
		end
	end

	layer:addChild(d_ms.d_u.createMenu(menu_btn_list, btns), 10)
	showCost()
	g_self.main_layer:addChild(layer, 200)
end
