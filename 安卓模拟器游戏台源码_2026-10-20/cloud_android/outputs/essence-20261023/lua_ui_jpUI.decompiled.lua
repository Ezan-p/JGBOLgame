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
local CCLabelTTF = CCLabelTTF
local CCTextFieldTTF = CCTextFieldTTF
local CCLayerColor = CCLayerColor

module("ui.jpUI")

d_ms = require("ms")

if not d_ms then
	CCLuaLog("load d_ms fail.")
end

local function cclog(...)
	CCLuaLog(string.format("jpUI %s", string.format(...)))
end

local o_t = d_ms.d_common_def.object_type
local m_t = d_ms.d_common_def.item_main_type
local MAX_JP = 4
local scrSize = CCDirector:sharedDirector():getVisibleSize()
local TAG = {
	Left = 1,
	Chosen = 3,
	Right = 2,
	Lock = 4
}
g_jpUI = {}
g_self = {}

function show(layer, z_order, cort_id)
	g_jpUI.cort_id = cort_id

	create()
	layer:addChild(g_jpUI.main_layer, z_order)

	if not g_self.LockPrice then
		d_ms.d_data.getExtSkillLockPrice()

		g_self.LockPrice = d_ms.d_data.g_ext_skill_lock_price
	end
end

function create()
	local layer = CCLayer:create()

	d_ms.d_u.createSwallowTouchLayer(layer)

	local blackmask = CCLayerColor:create(ccc4(0, 0, 0, 100))

	layer:addChild(blackmask, -1)

	local bkg = d_ms.d_u.createByStyle({
		pic = "v2/jpUI/bkg.png",
		x = 0.5,
		y = 0.5
	})

	layer:addChild(bkg)

	local w, h = d_ms.d_u.getRealScale(bkg)
	g_jpUI.h = h
	g_jpUI.w = w

	layer:addChild(d_ms.d_u.createByStyle({
		pic = "v2/jpUI/title.png",
		x = 0.5,
		y = 0.5 + h * 0.42
	}))
	layer:addChild(d_ms.d_u.createByStyle({
		pic = "v2/jpUI/bkg2.png",
		x = 0.5 + 0.3 * w,
		y = 0.5 - h * 0.03
	}))

	local menu_btn_list = {
		{
			npic = "v2/common/close1.png",
			spic = "v2/common/close2.png",
			x = 0.5 + w * 0.45,
			y = 0.5 + h * 0.45,
			call_back = pressClose
		},
		{
			npic = "v2/jpUI/btn11.png",
			spic = "v2/jpmkUI/btn12.png",
			x = 0.5 + w * 0.3,
			y = 0.5 - h * 0.28,
			call_back = pressConfirmJP
		},
		x = 0,
		y = 0
	}

	layer:addChild(d_ms.d_u.createMenu(menu_btn_list))

	g_jpUI.main_layer = layer

	showLeft()
	showRight()
end

function showRight()
	local layer = d_ms.d_u.clearLayer(g_jpUI.main_layer, 5, TAG.Right)

	if not layer then
		return
	end

	local w = g_jpUI.w
	local h = g_jpUI.h
	local this_char = d_ms.d_jpmkUI.getCharInfoById(g_jpUI.cort_id)

	if this_char and this_char.equiped_ext_skill_limit < 4 and this_char.next_ext_skill_luck_point and this_char.next_ext_skill_luck_point >= 0 then
		local luck_tink = d_ms.d_hz.gethz("jpmk_luck_point") .. this_char.next_ext_skill_luck_point

		layer:addChild(d_ms.d_u.createByStyle({
			type = "label",
			fontsize = 26,
			string = luck_tink,
			x = 0.5 + w * 0.3,
			y = 0.5 + h * 0.15,
			color = {
				154,
				254,
				111
			}
		}))
	end

	local jp_data = d_ms.d_jpmkUI.getJP(g_jpUI.cort_id)
	local jp_y = 0.5 + 0.26 * h
	local lv_y = 0.5 + 0.19 * h
	local jp_dx = 0.06 * w

	for i = 1, 4 do
		local jp_x = 0.5 + w * 0.3 + (i - 2.5) * jp_dx
		local jp_skill = jp_data[i]

		if jp_skill then
			local jp_sprite = d_ms.d_u.createByStyles({
				pic = "skill/ext/" .. jp_skill.csvInfo.file .. ".png",
				x = jp_x,
				y = jp_y,
				scale = jp_dx * 0.9
			})

			layer:addChild(jp_sprite)
			layer:addChild(d_ms.d_u.createByStyle({
				type = "label",
				fontsize = 26,
				string = "Lv " .. jp_skill.level,
				x = jp_x,
				y = lv_y,
				color = {
					154,
					254,
					111
				}
			}))
		else
			local not_set_pic = "v2/jpmkUI/jp_no_open.png"

			if this_char.equiped_ext_skill_limit and i <= this_char.equiped_ext_skill_limit then
				not_set_pic = "v2/jpmkUI/jp_bkg.png"
			end

			layer:addChild(d_ms.d_u.createByStyles({
				pic = not_set_pic,
				x = jp_x,
				y = jp_y,
				scale = jp_dx * 0.9
			}))
		end
	end

	showChosenJP()
end

function showLeft()
	if not g_jpUI.main_layer then
		return
	end

	local w = g_jpUI.w
	local h = g_jpUI.h
	local short_list = getShortList()
	local layer = g_jpUI.main_layer:getChildByTag(TAG.Left)

	if layer and g_jpUI.shortTableView then
		local dataSource = getJpDataSource(short_list)

		g_jpUI.shortTableView:reloadData(dataSource)
	else
		layer = CCLayer:create()

		g_jpUI.main_layer:addChild(layer, 5, TAG.Left)

		local touchArea = {
			x = (0.5 - 0.44 * w) * scrSize.width,
			y = (0.5 - 0.41 * h) * scrSize.height,
			width = 0.59 * w * scrSize.width,
			height = 0.75 * h * scrSize.height
		}

		if not g_jpUI.touchRect then
			g_jpUI.touchRect = CCRectMake(touchArea.x, touchArea.y, touchArea.width, touchArea.height)
			local cellSize = {
				width = touchArea.width,
				height = 0.22 * touchArea.height
			}
			g_jpUI.cellSize = cellSize
		end

		local shortTableView = d_ms.d_tableView.tableView(layer, touchArea)
		local dataSource = getJpDataSource(short_list)

		shortTableView:setDataSource(dataSource)
		shortTableView:startScroll()

		g_jpUI.shortTableView = shortTableView
	end
end

function showChosenJP()
	if not g_jpUI.main_layer then
		return
	end

	local p_layer = g_jpUI.main_layer:getChildByTag(TAG.Right)

	if not p_layer then
		return
	end

	local layer = d_ms.d_u.clearLayer(p_layer, 5, TAG.Chosen)
	local w = g_jpUI.w
	local h = g_jpUI.h

	if g_jpUI.chosenType then
		local csvInfo = d_ms.d_data.getCertainInfo(o_t.item, g_jpUI.chosenType)
		local icon = d_ms.d_data.getCertainSmallSprite(o_t.item, g_jpUI.chosenType)

		layer:addChild(d_ms.d_u.setStyles(icon, {
			x = 0.5 + 0.3 * w,
			y = 0.5 - h * 0.03
		}))
		layer:addChild(d_ms.d_u.createByStyle({
			type = "label",
			fontsize = 26,
			string = csvInfo.name,
			x = 0.5 + w * 0.3,
			y = 0.5 - h * 0.16,
			color = {
				154,
				254,
				111
			}
		}))
	end
end

function createJpCell(parentNode, info, cellSize)
	local line = CCSprite:create("v2/richmanUI/split2.png")

	line:setPosition(ccp(cellSize.width * 0.5, cellSize.height * 0))
	parentNode:addChild(line, -1)

	local lineScaleX = cellSize.width / line:getContentSize().width

	line:setScaleX(lineScaleX)

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
	nameLabel:setPosition(cellSize.width * 0.21, cellSize.height * 0.7)

	local starsLevelSprite = CCSprite:create("v2/introUI/stars.png")

	parentNode:addChild(starsLevelSprite, 1)
	starsLevelSprite:setPosition(cellSize.width * 0.46, cellSize.height * 0.7)

	local starsContentSize = starsLevelSprite:getContentSize()

	starsLevelSprite:setTextureRect(CCRectMake(0, 0, starsContentSize.width * csvInfo.quality / 5, starsContentSize.height))

	local numLabel = d_ms.d_u.createByStyle({
		fontsize = 22,
		type = "label",
		string = d_ms.d_hz.gethz("number") .. ": " .. info.count,
		pos_x = cellSize.width * 0.21,
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
	parentNode:addChild(d_ms.d_u.createByStyle({
		pic = "v2/introUI/level.png",
		anchor = {
			1,
			0.5
		},
		pos_x = cellSize.width * 0.5,
		pos_y = cellSize.height * 0.3
	}))
	parentNode:addChild(d_ms.d_u.createByStyle({
		type = "label",
		font = "arial",
		fontsize = 26,
		string = " " .. info.level,
		anchor = {
			0,
			0.5
		},
		color = {
			241,
			218,
			182
		},
		pos_x = cellSize.width * 0.5,
		pos_y = cellSize.height * 0.3
	}))

	local iconSprite1 = d_ms.d_data.getCertainSmallSprite(info.attach_type, info.type_id)
	local iconSprite2 = d_ms.d_data.getCertainSmallSprite(info.attach_type, info.type_id)
	local iconSize = iconSprite1:getContentSize()

	iconSprite1:setScale(0.9 * cellSize.height / iconSize.height)
	iconSprite2:setScale(0.9 * cellSize.height / iconSize.height)

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

	local function gotoForge()
		d_ms.d_u.remove(g_jpUI.main_layer)

		g_jpUI = {}
		local transInfo = d_ms.d_data.g_convertTable[info.type_id]

		d_ms.d_smithUI.show(transInfo)
	end

	local function use()
		g_jpUI.chosenId = info.id
		g_jpUI.chosenType = info.type_id

		showChosenJP()
	end

	local menuItems = {
		{
			nSprite = iconSprite1,
			sSprite = iconSprite2,
			tapHandler = showDetail,
			pos = ccp(cellSize.width * 0.1, cellSize.height * 0.5)
		},
		{
			npic = "v2/jpUI/btn21.png",
			spic = "v2/jpUI/btn22.png",
			tapHandler = gotoForge,
			pos = ccp(cellSize.width * 0.66, cellSize.height * 0.5)
		},
		{
			npic = "v2/jpUI/btn31.png",
			spic = "v2/jpUI/btn32.png",
			tapHandler = use,
			pos = ccp(cellSize.width * 0.88, cellSize.height * 0.5)
		}
	}
	local menuItemsDefs = {
		menuItems = menuItems,
		touchRect = g_jpUI.touchRect
	}
	local menuLayer = d_ms.d_tableView.createTableViewMenu(menuItemsDefs)

	parentNode:addChild(menuLayer)
end

function getJpDataSource(list)
	local dataSource = {}
	local num = #list
	local cellSize = g_jpUI.cellSize

	function dataSource.tableViewNumberOfRows()
		return num
	end

	function dataSource.drawCellAtIndex(index)
		local cell = CCNode:create()

		if list[index] then
			createJpCell(cell, list[index], cellSize)
		end

		return cell
	end

	function dataSource.heightForRowAtIndex(index)
		return cellSize.height
	end

	return dataSource
end

local function sortJP(a, b)
	if a.csvInfo.quality == b.csvInfo.quality then
		return b.count < a.count
	else
		return b.csvInfo.quality < a.csvInfo.quality
	end
end

function getShortList()
	local jp_data = d_ms.d_jpmkUI.getJP(g_jpUI.cort_id)
	local list = d_ms.d_packageUI.g_reorgItemsInfo[o_t.item][m_t.ext_skill] or {}
	local short_list = {}

	for k, v in pairs(list) do
		if v.owner_id == 0 then
			local same = false

			for _, n in pairs(jp_data) do
				if v.type_id == n.type_id then
					same = true

					break
				end
			end

			if not same then
				table.insert(short_list, d_ms.d_c.table_copy(v))
			end
		end
	end

	table.sort(short_list, sortJP)

	return short_list
end

function pressConfirmJP()
	if not g_jpUI.chosenId or not g_jpUI.chosenType then
		d_ms.d_info.show(d_ms.d_hz.gethz("jpmk_no_target"))
	else
		local jp_data = d_ms.d_jpmkUI.getJP(g_jpUI.cort_id)
		local cort_info = d_ms.d_jpmkUI.getCharInfoById(g_jpUI.cort_id)
		local tipInfo = nil
		local canLock = false

		if #jp_data == cort_info.equiped_ext_skill_limit then
			local hasHigh = false
			local mustReplace = false

			for k, v in pairs(jp_data) do
				if v.csvInfo.quality == 5 then
					hasHigh = true
				end

				if v.type_id == g_jpUI.chosenType - 100 then
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

			d_ms.d_quitUI.createYesNoByStyle(g_jpUI.main_layer, params_table, send_change_jp_req)
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
		ext_skill_id = g_jpUI.chosenId,
		des_cortege_id = g_jpUI.cort_id,
		lock_list = table.tostring(lock_list)
	}

	d_ms.d_u.main_server_send_msg(d_ms.d_msg_def.gscl_msg_id.msg_equip_ext_skill, tmp_request)
end

function callback_change_jp_req(data)
	cclog("callback_change_jp_req ")

	if data.result ~= 0 then
		d_ms.d_info.show(d_ms.d_hz.gethz("operation_failed"))
	end

	g_jpUI.chosenId = nil
	g_jpUI.chosenType = nil

	showLeft()
	showRight()
end

function showJPLockLayer(jp_data)
	if not g_jpUI.main_layer then
		return
	end

	local p_layer = g_jpUI.main_layer:getChildByTag(TAG.Right)

	if not p_layer then
		return
	end

	local layer = d_ms.d_u.clearLayer(p_layer, 20, TAG.Lock)

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

				d_ms.d_quitUI.createYesNoByStyle(g_jpUI.main_layer, params_table, send)
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
end

function pressClose()
	d_ms.d_u.remove(g_jpUI.main_layer)

	g_jpUI = {}

	d_ms.d_jpmkUI.reBuild()
end
