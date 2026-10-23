local _G = _G
local require = require
local bits = bits
local sqlite = sqlite
local type = type
local print = print
local tostring = tostring
local pairs = pairs
local string = string
local tostring = tostring
local table = table
local math = math
local os = os
local tonumber = tonumber
local tolua = tolua
local main_server = main_server
local package = package
local class = class
local CCArray = CCArray
local CCDirector = CCDirector
local CCScene = CCScene
local CCLayer = CCLayer
local CCLayerColor = CCLayerColor
local CCLabelTTF = CCLabelTTF
local CCRect = CCRect
local CCPoint = CCPoint
local CCNode = CCNode
local CCSprite = CCSprite
local CCRectMake = CCRectMake
local CCPointMake = CCPointMake
local CCSizeMake = CCSizeMake
local ccc3 = ccc3
local ccc4 = ccc4
local CCMoveTo = CCMoveTo
local CCMoveBy = CCMoveBy
local CCEaseOut = CCEaseOut
local CCSequence = CCSequence
local CCScrollView = CCScrollView
local CCLuaLog = CCLuaLog
local CCTOUCHBEGAN = CCTOUCHBEGAN
local CCTOUCHMOVED = CCTOUCHMOVED
local CCTOUCHENDED = CCTOUCHENDED
local CCTOUCHCANCELLED = CCTOUCHCANCELLED
local kCCTextAlignmentLeft = kCCTextAlignmentLeft
local CCMenuItemImage = CCMenuItemImage
local CCMenu = CCMenu
local CCMenuItemLabel = CCMenuItemLabel

module("ui.formationUI")

d_ms = require("ms")

if not d_ms then
	CCLuaLog("Lua : formationUI >> formationUI load d_ms fail.")
end

local function cclog(...)
	CCLuaLog(string.format("Lua : formationUI >>%s", string.format(...)))
end

local function errlog(...)
	CCLuaLog(string.format("Lua Error : formationUI >>%s", string.format(...)))
end

g_formationUI = {
	changeLayer = {},
	detailLayer = {},
	selectLayer = {},
	introduceLayer = {}
}
local kMcs = d_ms.d_c.g_contants.MaxCharactors

function destroyLayerDL()
	if not g_formationUI.detailLayer.mainLayer then
		return
	end

	g_formationUI.detailLayer.mainLayer:removeFromParentAndCleanup(true)

	g_formationUI.detailLayer = {}
end

function menuCancelDL()
	d_ms.d_music_mgr.playClickEffect()
	destroyLayerDL()
end

function menuTrainingDL()
	d_ms.d_music_mgr.playClickEffect()
	d_ms.d_trainingUI.show(g_formationUI.detailLayer.charInfoTab, g_detailLayerParent)
	destroyLayerDL()
end

function menuInheritDL()
	d_ms.d_music_mgr.playClickEffect()

	if g_argInfoTab.character.level > 2 * d_ms.d_mainUI.g_playerInfo.level then
		d_ms.d_info.show(d_ms.d_hz.gethz("cannotInherit"))

		return
	end

	d_ms.d_inheritUI.showInheritLayer(d_ms.d_mainUI.g_mainUI.main_layer, 50, g_argInfoTab.character.id)
	destroyLayerDL()
end

function menuChangeDL()
	d_ms.d_music_mgr.playClickEffect()
	showSelectLayer(d_ms.d_lineupUI.g_lineupUI.main_layer)
end

function menuCancelSL()
	d_ms.d_music_mgr.playClickEffect()

	if not g_formationUI.selectLayer.mainLayer then
		return
	end

	g_formationUI.selectLayer.mainLayer:removeFromParentAndCleanup(true)

	g_formationUI.selectLayer = {}
end

function menuOKSL()
	d_ms.d_music_mgr.playClickEffect()

	if not g_formationUI.selectLayer.selectNum then
		menuCancelSL()

		return
	end

	sendReplacePosToServer()
end

function menuTrainingIL()
	d_ms.d_music_mgr.playClickEffect()
	d_ms.d_trainingUI.show(g_formationUI.introduceLayer.charInfoTab)
	destroyLayerIL()
end

function menuInheritIL()
	d_ms.d_music_mgr.playClickEffect()

	if g_argInfoTab.level > 2 * d_ms.d_mainUI.g_playerInfo.level then
		d_ms.d_info.show(d_ms.d_hz.gethz("cannotInherit"))

		return
	end

	d_ms.d_inheritUI.showInheritLayer(d_ms.d_mainUI.g_mainUI.main_layer, 50, g_argInfoTab.id)
	destroyLayerIL()
end

function menuConjureIL()
	d_ms.d_music_mgr.playClickEffect()

	local soultypeid = g_formationUI.introduceLayer.soulType

	sendConjureCharacterToServer(soultypeid)
end

function menuReplaceIL()
	d_ms.d_music_mgr.playClickEffect()

	local gil = g_formationUI.introduceLayer

	processCharacterBeSelected(gil.fromSLIndex, true)
	menuCancelIL()
end

function menuCancelIL()
	d_ms.d_music_mgr.playClickEffect()
	destroyLayerIL()

	if d_ms.d_u.isWin32() then
		package.loaded["ui.formationUI"] = nil
		d_ms.d_formationUI = require("ui.formationUI")
	end
end

function destroyLayerIL()
	if not g_formationUI.introduceLayer.mainLayer then
		return
	end

	g_formationUI.introduceLayer.mainLayer:removeFromParentAndCleanup(true)

	g_formationUI.introduceLayer = {}
end

local lt_changeLayerList = {
	holeBkgFile1 = "formationUI/front.png",
	holeBkgFile2 = "formationUI/back.png",
	trayFile = "formationUI/tray.png",
	trays = {
		{
			numfile = "formationUI/1.png",
			traypos = {
				x = 0.2265625,
				y = 0.3888888888888889
			},
			numpos = {
				x = 0.2265625,
				y = 0.3194444444444444
			}
		},
		{
			numfile = "formationUI/2.png",
			traypos = {
				x = 0.80078125,
				y = 0.3888888888888889
			},
			numpos = {
				x = 0.80078125,
				y = 0.3194444444444444
			}
		},
		{
			numfile = "formationUI/3.png",
			traypos = {
				x = 0.5,
				y = 0.6388888888888888
			},
			numpos = {
				x = 0.5,
				y = 0.5694444444444444
			}
		},
		{
			numfile = "formationUI/4.png",
			traypos = {
				x = 0.5,
				y = 0.1388888888888889
			},
			numpos = {
				x = 0.5,
				y = 0.06944444444444445
			}
		}
	}
}
local lt_detailMenuList = {
	{
		npic = "v2/trainingUI/training1.png",
		spic = "v2/trainingUI/training2.png",
		y = 0.125,
		x = 0.153125,
		call_back = menuTrainingDL
	},
	{
		npic = "v2/buttons/inherit1.png",
		spic = "v2/buttons/inherit2.png",
		y = 0.125,
		x = 0.35625,
		call_back = menuInheritDL
	},
	{
		npic = "v2/introUI/close1.png",
		spic = "v2/introUI/close2.png",
		y = 0.9583333333333334,
		x = 0.9765625,
		call_back = menuCancelDL
	},
	x = 0,
	y = 0
}
local lt_selectLayerList = {
	selectMenuList = {
		{
			npic = "v2/multi-selectUI/back1.png",
			spic = "v2/multi-selectUI/back2.png",
			y = 0.1111111111111111,
			x = 0.390625,
			call_back = menuCancelSL
		},
		{
			npic = "v2/introUI/close1.png",
			spic = "v2/introUI/close2.png",
			y = 0.9583333333333334,
			x = 0.9765625,
			call_back = menuCancelSL
		},
		x = 0,
		y = 0
	}
}
local lt_introduceMenuList = {
	{
		npic = "v2/trainingUI/training1.png",
		spic = "v2/trainingUI/training2.png",
		y = 0.125,
		x = 0.153125,
		call_back = menuTrainingIL
	},
	{
		npic = "v2/buttons/inherit1.png",
		spic = "v2/buttons/inherit2.png",
		y = 0.125,
		x = 0.35625,
		call_back = menuInheritIL
	},
	{
		npic = "v2/introUI/close1.png",
		spic = "v2/introUI/close2.png",
		y = 0.9583333333333334,
		x = 0.9765625,
		call_back = menuCancelIL
	},
	x = 0,
	y = 0
}
local lt_CLHolesPosition = {
	{
		scaleH = 0.2,
		x = 0.3,
		y = 0.5
	},
	{
		scaleH = 0.2,
		x = 0.875,
		y = 0.5
	},
	{
		scaleH = 0.2,
		x = 0.575,
		y = 0.75
	},
	{
		scaleH = 0.2,
		x = 0.575,
		y = 0.25
	},
	{
		scaleH = 0.2,
		x = 0.15,
		y = 0.5
	},
	{
		scaleH = 0.2,
		x = 0.725,
		y = 0.5
	},
	{
		scaleH = 0.2,
		x = 0.425,
		y = 0.75
	},
	{
		scaleH = 0.2,
		x = 0.425,
		y = 0.25
	}
}

local function onTouchBeganCL(argX, argY)
	local gcl = g_formationUI.changeLayer

	if gcl.touchPoint >= 1 and gcl.touchPoint <= 8 then
		return
	end

	gcl.touchPoint = 0
	local pspPos = gcl.mainLayer:convertToNodeSpace(CCPointMake(argX, argY))

	for i = 1, #gcl.charactors do
		local objRect = gcl.charactors[i].ImgSprite:boundingBox()
		local isCon = objRect:containsPoint(pspPos)

		if isCon == true then
			charactorRespondTouchBeganInCL(i, pspPos.x, pspPos.y)

			return true
		end
	end

	return true
end

local function onTouchMovedCL(argX, argY)
	local gcl = g_formationUI.changeLayer

	if gcl.touchPoint == 0 then
		return
	end

	local pspPos = gcl.mainLayer:convertToNodeSpace(CCPointMake(argX, argY))

	charactorRespondTouchMoveInCL(0, pspPos.x, pspPos.y)
end

local function onTouchEndedCL(argX, argY)
	local gcl = g_formationUI.changeLayer

	if gcl.touchPoint == 0 then
		return
	end

	local pspPos = gcl.mainLayer:convertToNodeSpace(CCPointMake(argX, argY))

	for i = 1, #gcl.charactors do
		if gcl.touchPoint ~= i then
			local objRect = gcl.charactors[i].ImgSprite:boundingBox()
			local isCon = objRect:containsPoint(pspPos)

			if isCon == true then
				charactorRespondTouchEndedInCL(i, pspPos.x, pspPos.y)

				gcl.touchPoint = 0

				return
			end
		end
	end

	d_ms.d_u.setProperties(gcl.mainLayer, gcl.charactors[gcl.touchPoint].ImgSprite, lt_CLHolesPosition[gcl.touchPoint])

	gcl.touchPoint = 0
end

function charactorRespondTouchBeganInCL(argIndex, argX, argY)
	local gcl = g_formationUI.changeLayer
	gcl.touchPoint = argIndex
	gcl.lastPos = {
		x = argX,
		y = argY
	}

	gcl.mainLayer:reorderChild(gcl.charactors[argIndex].ImgSprite, 2)
end

function charactorRespondTouchMoveInCL(argIndex, argX, argY)
	local gcl = g_formationUI.changeLayer
	local tx = argX - gcl.lastPos.x
	local ty = argY - gcl.lastPos.y
	local fx, fy = gcl.charactors[gcl.touchPoint].ImgSprite:getPosition()

	gcl.charactors[gcl.touchPoint].ImgSprite:setPosition(fx + tx, fy + ty)

	gcl.lastPos = {
		x = argX,
		y = argY
	}
end

function charactorRespondTouchEndedInCL(argIndex, argX, argY)
	local gcl = g_formationUI.changeLayer
	local t_idx = gcl.touchPoint

	gcl.mainLayer:reorderChild(gcl.charactors[t_idx].ImgSprite, 1)

	local tmpCharactor = gcl.charactors[argIndex]
	gcl.charactors[argIndex] = gcl.charactors[t_idx]
	gcl.charactors[t_idx] = tmpCharactor

	d_ms.d_u.setProperties(gcl.mainLayer, gcl.charactors[argIndex].ImgSprite, lt_CLHolesPosition[argIndex])
	d_ms.d_u.setProperties(gcl.mainLayer, gcl.charactors[t_idx].ImgSprite, lt_CLHolesPosition[t_idx])
end

local function onTouchBeganSL(x, y)
	local gsl = g_formationUI.selectLayer

	gsl.cellsView:stopAllActions()

	gsl.isMoved = false
	gsl.lastPos = {
		x = x,
		y = y
	}
	gsl.beganPos = {
		bs = 0,
		bx = x,
		by = y
	}

	return true
end

local function onTouchMovedSL(x, y)
	local gsl = g_formationUI.selectLayer
	gsl.dy = y - gsl.lastPos.y

	cclog("dy = %d", gsl.dy)

	local sy = gsl.cellsView:getPositionY()

	gsl.cellsView:setPositionY(gsl.dy + sy)

	gsl.lastPos = {
		x = x,
		y = y
	}
	local nowbx = math.abs(x - gsl.beganPos.bx)
	local nowby = math.abs(y - gsl.beganPos.by)
	local nowbs = nowbx * nowbx + nowby * nowby

	if gsl.beganPos.bs < nowbs then
		gsl.beganPos.bs = nowbs
	end

	if gsl.beganPos.bs > 25 then
		gsl.isMoved = true
	end
end

local function onTouchEndedSL(x, y)
	local gsl = g_formationUI.selectLayer

	if gsl.isMoved then
		d_ms.d_u.followupActionsOfScrollView(gsl.cellsView, gsl.dy)
	else
		clickTouchEndedSL(x, y)
	end
end

function clickTouchEndedSL(argX, argY)
	local gsl = g_formationUI.selectLayer

	for i = 1, #gsl.characters do
		local lyRect = gsl.characters[i].BkgSprite:boundingBox()
		local nodSp = gsl.cellsView:convertToNodeSpace(CCPointMake(argX, argY))
		local ic = lyRect:containsPoint(nodSp)

		if ic then
			local ImgRect = gsl.characters[i].ImgSprite:boundingBox()
			local nodSp2 = gsl.characters[i].BkgSprite:convertToNodeSpace(CCPointMake(argX, argY))
			local isc = ImgRect:containsPoint(nodSp2)

			if isc then
				local charTab = d_ms.d_godBlessUI.getCharTableByUID(gsl.characters[i].id)

				showIntroduceLayer(d_ms.d_lineupUI.g_lineupUI.main_layer, charTab, i)
			else
				processCharacterBeSelected(i, false)

				if d_ms.d_mainUI.g_isNeedGuide then
					d_ms.d_guideUI.guideLineup5()
				end
			end

			return
		end
	end
end

function processCharacterBeSelected(index, bFromIL)
	local gsc = g_formationUI.selectLayer.characters
	local sn = g_formationUI.selectLayer.selectNum

	if gsc[index].order ~= 0 then
		return
	end

	if sn == index and not bFromIL then
		gsc[sn].BkgSprite:removeChildByTag(1, true)

		g_formationUI.selectLayer.selectNum = nil

		return
	end

	if sn and sn ~= 0 then
		gsc[sn].BkgSprite:removeChildByTag(1, true)
	end

	gsc[index].BkgSlcSprite = CCSprite:create("v2/multi-selectUI/check.png")

	d_ms.d_u.setProperties(gsc[index].BkgSprite, gsc[index].BkgSlcSprite, {
		x = 0.85,
		y = 0.5
	})
	gsc[index].BkgSprite:addChild(gsc[index].BkgSlcSprite, 0, 1)

	g_formationUI.selectLayer.selectNum = index
end

function onTouchBeganPublic(x, y, cellsView, mainTable)
	if x < CCDirector:sharedDirector():getVisibleSize().width / 2 then
		mainTable.isInRight = false

		return true
	else
		mainTable.isInRight = true
	end

	cellsView:stopAllActions()

	mainTable.isMoved = false
	mainTable.lastPos = {
		x = x,
		y = y
	}
	mainTable.beganPos = {
		bs = 0,
		bx = x,
		by = y
	}

	return true
end

function onTouchMovedPublic(x, y, cellsView, mainTable)
	if not mainTable.isInRight then
		return
	end

	mainTable.dy = y - mainTable.lastPos.y
	local sy = cellsView:getPositionY()

	cellsView:setPositionY(mainTable.dy + sy)

	mainTable.lastPos = {
		x = x,
		y = y
	}
	local nowbx = math.abs(x - mainTable.beganPos.bx)
	local nowby = math.abs(y - mainTable.beganPos.by)
	local nowbs = nowbx * nowbx + nowby * nowby

	if mainTable.beganPos.bs < nowbs then
		mainTable.beganPos.bs = nowbs
	end

	if mainTable.beganPos.bs > 25 then
		mainTable.isMoved = true
	end
end

function onTouchEndedPublic(cellsView, mainTable)
	if mainTable.isMoved then
		d_ms.d_u.followupActionsOfScrollView(cellsView, mainTable.dy)

		mainTable.isMoved = false
		mainTable.isInRight = false
	end
end

local function onTouchInChangeLayer(touchType, argX, argY)
	cclog("onTouchInChangeLayer(), (%d,%d), touchType = %d ", argX, argY, touchType)

	if touchType == CCTOUCHBEGAN then
		return onTouchBeganCL(argX, argY)
	elseif touchType == CCTOUCHMOVED then
		return onTouchMovedCL(argX, argY)
	elseif touchType == CCTOUCHCANCELLED or touchType == CCTOUCHENDED then
		return onTouchEndedCL(argX, argY)
	else
		errlog("onTouchInCL What is this touchType = %d . ", touchType)
	end
end

local function onTouchInSelectLayer(touchType, argX, argY)
	if touchType == CCTOUCHBEGAN then
		return onTouchBeganSL(argX, argY)
	elseif touchType == CCTOUCHMOVED then
		return onTouchMovedSL(argX, argY)
	else
		return onTouchEndedSL(argX, argY)
	end
end

function showChangeLayer(parentLayer)
	createChangeLayer(parentLayer)
	loadingCharactorsHeadImage()
end

function showDetailLayer(parentLayer, argInfoTab, isReadOnly)
	g_detailLayerParent = parentLayer
	g_argInfoTab = argInfoTab
	local gdl = g_formationUI.detailLayer
	local tmptab = lt_detailMenuList

	if isReadOnly then
		tmptab = {
			{
				npic = "v2/multi-selectUI/back1.png",
				spic = "v2/multi-selectUI/back2.png",
				y = 0.125,
				x = 0.2546875,
				call_back = menuCancelDL
			},
			{
				npic = "v2/introUI/close1.png",
				spic = "v2/introUI/close2.png",
				y = 0.9583333333333334,
				x = 0.9609375,
				call_back = menuCancelDL
			},
			x = 0,
			y = 0
		}
	end

	argInfoTab.character.isReadOnly = isReadOnly

	createCharacterIntroduceLayer(gdl, parentLayer, argInfoTab.character, 40, false, tmptab, false)

	gdl.dIndex = argInfoTab.character.order
end

function showSelectLayer(parentLayer, argHoleNum)
	createSelectLayer(parentLayer)

	if not argHoleNum or argHoleNum == 0 then
		argHoleNum = g_formationUI.detailLayer.dIndex
	end

	loadingAllCharacters(argHoleNum)
end

function showIntroduceLayer(parentLayer, argInfoTab, idx)
	local gil = g_formationUI.introduceLayer
	g_argInfoTab = argInfoTab
	local tmptab = lt_introduceMenuList
	local isSoul = false

	if idx == 0 then
		tmptab = {
			{
				npic = "v2/trainingUI/training1.png",
				spic = "v2/trainingUI/training2.png",
				y = 0.125,
				x = 0.153125,
				call_back = menuTrainingIL
			},
			{
				npic = "v2/buttons/inherit1.png",
				spic = "v2/buttons/inherit2.png",
				y = 0.125,
				x = 0.35625,
				call_back = menuInheritIL
			},
			{
				npic = "v2/introUI/close1.png",
				spic = "v2/introUI/close2.png",
				y = 0.9583333333333334,
				x = 0.9609375,
				call_back = menuCancelIL
			},
			x = 0,
			y = 0
		}
	elseif idx == -1 then
		tmptab = {
			{
				npic = "v2/introUI/conjure1.png",
				spic = "v2/introUI/conjure2.png",
				y = 0.125,
				x = 0.153125,
				call_back = menuConjureIL
			},
			{
				npic = "v2/multi-selectUI/back1.png",
				spic = "v2/multi-selectUI/back2.png",
				y = 0.125,
				x = 0.35625,
				call_back = menuCancelIL
			},
			{
				npic = "v2/introUI/close1.png",
				spic = "v2/introUI/close2.png",
				y = 0.9583333333333334,
				x = 0.9609375,
				call_back = menuCancelIL
			},
			x = 0,
			y = 0
		}
		isSoul = true
		gil.soulType = argInfoTab.type
	end

	createCharacterIntroduceLayer(gil, parentLayer, argInfoTab, 60, isSoul, tmptab, false)

	gil.fromSLIndex = idx
end

function createCharacterIntroduceLayer(mainTable, parentLayer, characterInfoTable, zOrder, isSoul, menuList, isSecond)
	mainTable.charInfoTab = characterInfoTable

	function onTouch(touchType, x, y)
		cclog("call onTouch....")

		return true
	end

	local introTag = nil

	if isSecond then
		introTag = d_ms.d_data.getTagFromDef("introLayer2")

		if introTag == parentLayer:getTag() then
			parentLayer = parentLayer:getParent()
		end
	else
		introTag = d_ms.d_data.getTagFromDef("introLayer")
	end

	parentLayer:removeChildByTag(introTag, true)

	local mainLayer = CCLayer:create()
	mainTable.mainLayer = mainLayer

	mainLayer:setTag(introTag)
	parentLayer:addChild(mainLayer, zOrder)
	mainLayer:registerScriptTouchHandler(onTouch, false, -128, true)
	mainLayer:setTouchEnabled(true)
	addSpritesInDILayer(mainLayer, mainTable, characterInfoTable)
	mainLayer:addChild(d_ms.d_u.createMenu(menuList), 10)
	loadCharacterInfo(mainLayer, characterInfoTable, isSoul)
end

function createChangeLayer(parentLayer)
	g_formationUI.changeLayer.mainLayer = CCLayer:create()
	local gcl = g_formationUI.changeLayer
	gcl.touchPoint = 0
	local plsz = parentLayer:getContentSize()

	gcl.mainLayer:setContentSize(CCSizeMake(plsz.width * 0.75, plsz.height * 0.775))
	d_ms.d_u.setProperties(parentLayer, gcl.mainLayer, {
		x = 0.228125,
		y = 0.18055555555555555
	})
	parentLayer:addChild(gcl.mainLayer, 1)

	local teamTowardImg = CCSprite:create("formationUI/teamToward.png")

	d_ms.d_u.setProperties(gcl.mainLayer, teamTowardImg, {
		x = 0.2,
		y = 0.85
	})
	gcl.mainLayer:addChild(teamTowardImg, 0)

	for i = 1, 4 do
		local numImg = CCSprite:create(lt_changeLayerList.trays[i].numfile)

		d_ms.d_u.setProperties(gcl.mainLayer, numImg, lt_changeLayerList.trays[i].numpos)
		d_ms.d_u.setProperties(gcl.mainLayer, numImg, {
			scale = 0.03333333333333333
		})
		gcl.mainLayer:addChild(numImg, 0)

		local trayImg = CCSprite:create(lt_changeLayerList.trayFile)

		d_ms.d_u.setProperties(gcl.mainLayer, trayImg, lt_changeLayerList.trays[i].traypos)
		d_ms.d_u.setProperties(gcl.mainLayer, trayImg, {
			scale = 0.31875
		})
		gcl.mainLayer:addChild(trayImg, 0)
	end

	gcl.holes = {}

	for i = 1, kMcs do
		local f_str = i < 5 and lt_changeLayerList.holeBkgFile1 or lt_changeLayerList.holeBkgFile2
		gcl.holes[i] = CCSprite:create(f_str)

		d_ms.d_u.setProperties(gcl.mainLayer, gcl.holes[i], lt_CLHolesPosition[i])
		gcl.mainLayer:addChild(gcl.holes[i], 0)
	end

	gcl.mainLayer:registerScriptTouchHandler(onTouchInChangeLayer, false, 0, true)
	gcl.mainLayer:setTouchEnabled(true)
end

function createSelectLayer(parentLayer)
	g_formationUI.selectLayer.mainLayer = CCLayer:create()
	local gsl = g_formationUI.selectLayer

	parentLayer:addChild(gsl.mainLayer, 50)
	gsl.mainLayer:registerScriptTouchHandler(onTouchInSelectLayer, false, -128, true)
	gsl.mainLayer:setTouchEnabled(true)

	local position = {
		x = 0.5,
		y = 0.5
	}
	local scaleXY = {
		scaleY = 0.95,
		scaleX = 0.95
	}
	local board_size = d_ms.d_mainUI.createBoardBkg(gsl.mainLayer, position, scaleXY, true)
	local menuTable = {}
	local menu_btn_list = lt_selectLayerList.selectMenuList

	for i = 1, #menu_btn_list do
		local menuItem = CCMenuItemImage:create(menu_btn_list[i].npic, menu_btn_list[i].spic)

		d_ms.d_u.setStyles(menuItem, {
			scale = menu_btn_list[i].scale,
			x = menu_btn_list[i].x,
			y = menu_btn_list[i].y
		})
		menuItem:registerScriptTapHandler(menu_btn_list[i].call_back)

		menuTable[i] = menuItem
		local menu = CCMenu:createWithItem(menuItem)

		menu:setPosition(0, 0)
		gsl.mainLayer:addChild(menu, 10)
	end

	g_guideEnsureSelect = menuTable[2]
end

function addSpritesInDILayer(parNode, mainTable, argInfoTab)
	local vsz = parNode:getContentSize()
	local position = {
		x = 0.5,
		y = 0.5
	}
	local scaleXY = {
		scaleY = 0.95,
		scaleX = 0.95
	}
	local board_size = d_ms.d_mainUI.createBoardBkg(parNode, position, scaleXY, true)
	local flHighLight = CCSprite:create("v2/introUI/floorHighLight.png")
	local fhlsz = flHighLight:getContentSize()

	d_ms.d_u.setProperties(parNode, flHighLight, {
		scaleY = 0.5222222222222223,
		scaleX = 0.571875,
		x = 0.259375,
		y = (140 + fhlsz.height / 2) / 720
	})
	parNode:addChild(flHighLight)

	local charBox = CCSprite:create("v2/introUI/introBkg2.png")

	d_ms.d_u.setProperties(parNode, charBox, {
		scaleY = 0.8944444444444445,
		scaleX = 0.4609375,
		x = 0.259375,
		y = 0.5
	})
	parNode:addChild(charBox)

	local rightBkg = CCSprite:create("v2/introUI/rightBkg.png")

	d_ms.d_u.setProperties(parNode, rightBkg, {
		scaleY = 0.8888888888888888,
		scaleX = 0.46875,
		x = 0.734375,
		y = 0.5
	})
	parNode:addChild(rightBkg)

	mainTable.cellsView = CCLayer:create()
	local all_h = add_intro_relate_talent_sprites(mainTable.cellsView, argInfoTab, parNode)
	local layer_scroll = CCScrollView:create(d_ms.d_u.ccSizeMake(0.5, 0.86), mainTable.cellsView)

	d_ms.d_u.setStyles(layer_scroll, {
		x = 0.5,
		y = 0.07
	})
	parNode:addChild(layer_scroll)

	local slide_params = {
		y_limit_down = 0,
		y_limit_top = all_h - 0.6,
		limit_springback = 0.3,
		isSwallow = false
	}
	local tmp_rect = d_ms.d_u.ccRectMake(0, 0.07, 1, 0.86)

	d_ms.d_touch_event.enableSlideY(mainTable.cellsView, tmp_rect, slide_params)

	local leftLight = CCSprite:create("v2/introUI/left_scroll.png")

	d_ms.d_u.setProperties(parNode, leftLight, {
		scaleY = 0.8916666666666667,
		x = 0.5,
		y = 0.5
	})
	parNode:addChild(leftLight)

	local rightLight = CCSprite:create("v2/introUI/right_scroll.png")

	d_ms.d_u.setProperties(parNode, rightLight, {
		scaleY = 0.8916666666666667,
		x = 0.96875,
		y = 0.5
	})
	parNode:addChild(rightLight)
end

function createScrollViewInDI(parNode, containView, all_h)
	local vsz = parNode:getContentSize()
	containView = containView or CCLayer:create()
	local scrollView = CCScrollView:create(CCSizeMake(vsz.width * 620 / 1280, vsz.height * 660 / 720), tolua.cast(containView, "CCNode"))

	containView:setContentSize(CCSizeMake(vsz.width * 620 / 1280, vsz.height * all_h))
	containView:setPositionY(vsz.height * (0.9166666666666666 - all_h))
	scrollView:setPosition(CCPointMake(vsz.width * 640 / 1280, vsz.height * 30 / 720))
	parNode:addChild(scrollView)

	return containView
end

function add_intro_relate_talent_sprites(parNode, argInfoTab, introLayer)
	local w_begin = 0
	local h_begin = 0.8
	local h_now = h_begin
	local introBkg = d_ms.d_u.createByStyles({
		pic = "v2/introUI/small_label.png",
		scale = 0.4,
		x = w_begin + 0.25,
		y = h_now
	})

	parNode:addChild(introBkg)

	local w_title, h_title = d_ms.d_u.getPicScale(introBkg)
	local introTitle = d_ms.d_u.createByStyles({
		pic = "v2/introUI/intro_label_ql.png",
		x = w_begin + 0.25,
		y = h_now,
		scaleY = h_title - 0.02
	})

	parNode:addChild(introTitle)

	h_now = h_now - h_title / 2 - 0.03
	local tmp_user_pro = {}

	if argInfoTab.csvInfo and argInfoTab.csvInfo.manaOffset then
		tmp_user_pro.mp = argInfoTab.csvInfo.manaOffset
		tmp_user_pro.hp = argInfoTab.csvInfo.hpOffset
		tmp_user_pro.ad = argInfoTab.csvInfo.damageOffset
		tmp_user_pro.def = argInfoTab.csvInfo.defenceOffset
	else
		tmp_user_pro.mp = argInfoTab.magic
		tmp_user_pro.hp = argInfoTab.hp
		tmp_user_pro.ad = argInfoTab.gongji
		tmp_user_pro.def = argInfoTab.fangyu
	end

	tmp_user_pro.mp_rate = tmp_user_pro.mp / d_ms.d_lineupUI.g_characterMaxGrowth.mana
	tmp_user_pro.hp_rate = tmp_user_pro.hp / d_ms.d_lineupUI.g_characterMaxGrowth.health
	tmp_user_pro.ad_rate = tmp_user_pro.ad / d_ms.d_lineupUI.g_characterMaxGrowth.damage
	tmp_user_pro.def_rate = tmp_user_pro.def / d_ms.d_lineupUI.g_characterMaxGrowth.defence
	local per_icon1 = d_ms.d_u.createByStyles({
		pic = "v2/introUI/health.png",
		scale = 0.025,
		x = w_begin + 0.03,
		y = h_now - 0
	})
	local per_icon2 = d_ms.d_u.createByStyles({
		pic = "v2/introUI/damage.png",
		scale = 0.025,
		x = w_begin + 0.03,
		y = h_now - 0.05
	})
	local per_icon3 = d_ms.d_u.createByStyles({
		pic = "v2/introUI/defence.png",
		scale = 0.025,
		x = w_begin + 0.03,
		y = h_now - 0.1
	})
	local per_icon4 = d_ms.d_u.createByStyles({
		pic = "v2/introUI/mana.png",
		scale = 0.025,
		x = w_begin + 0.03,
		y = h_now - 0.15000000000000002
	})
	local per_bkg1 = d_ms.d_u.createByStyles({
		pic = "v2/introUI/property_bkg.png",
		scale = 0.4,
		x = w_begin + 0.25,
		y = h_now - 0
	})
	local per_bkg2 = d_ms.d_u.createByStyles({
		pic = "v2/introUI/property_bkg.png",
		scale = 0.4,
		x = w_begin + 0.25,
		y = h_now - 0.05
	})
	local per_bkg3 = d_ms.d_u.createByStyles({
		pic = "v2/introUI/property_bkg.png",
		scale = 0.4,
		x = w_begin + 0.25,
		y = h_now - 0.1
	})
	local per_bkg4 = d_ms.d_u.createByStyles({
		pic = "v2/introUI/property_bkg.png",
		scale = 0.4,
		x = w_begin + 0.25,
		y = h_now - 0.15000000000000002
	})
	local w_bkg, h_bkg = d_ms.d_u.getPicScale(per_bkg1)
	local h_per_value = h_bkg - 0.006
	local w_per_1 = 0.4 * tmp_user_pro.hp_rate
	local w_per_2 = 0.4 * tmp_user_pro.ad_rate
	local w_per_3 = 0.4 * tmp_user_pro.def_rate
	local w_per_4 = 0.4 * tmp_user_pro.mp_rate
	local per_value1 = d_ms.d_u.createByStyles({
		pic = "v2/introUI/property_up.png",
		x = w_begin + 0.05 + w_per_1 / 2,
		y = h_now - 0,
		scaleX = w_per_1,
		scaleY = h_per_value
	})
	local per_value2 = d_ms.d_u.createByStyles({
		pic = "v2/introUI/property_up.png",
		x = w_begin + 0.05 + w_per_2 / 2,
		y = h_now - 0.05,
		scaleX = w_per_2,
		scaleY = h_per_value
	})
	local per_value3 = d_ms.d_u.createByStyles({
		pic = "v2/introUI/property_up.png",
		x = w_begin + 0.05 + w_per_3 / 2,
		y = h_now - 0.1,
		scaleX = w_per_3,
		scaleY = h_per_value
	})
	local per_value4 = d_ms.d_u.createByStyles({
		pic = "v2/introUI/property_up.png",
		x = w_begin + 0.05 + w_per_4 / 2,
		y = h_now - 0.15000000000000002,
		scaleX = w_per_4,
		scaleY = h_per_value
	})
	local per_mid1 = d_ms.d_u.createByStyles({
		pic = "v2/introUI/property_mid.png",
		x = w_begin + 0.05 + w_per_1,
		y = h_now - 0,
		scaleY = h_per_value
	})
	local per_mid2 = d_ms.d_u.createByStyles({
		pic = "v2/introUI/property_mid.png",
		x = w_begin + 0.05 + w_per_2,
		y = h_now - 0.05,
		scaleY = h_per_value
	})
	local per_mid3 = d_ms.d_u.createByStyles({
		pic = "v2/introUI/property_mid.png",
		x = w_begin + 0.05 + w_per_3,
		y = h_now - 0.1,
		scaleY = h_per_value
	})
	local per_mid4 = d_ms.d_u.createByStyles({
		pic = "v2/introUI/property_mid.png",
		x = w_begin + 0.05 + w_per_4,
		y = h_now - 0.15000000000000002,
		scaleY = h_per_value
	})

	parNode:addChild(per_icon1, 10)
	parNode:addChild(per_icon2, 10)
	parNode:addChild(per_icon3, 10)
	parNode:addChild(per_icon4, 10)
	parNode:addChild(per_bkg1, 10)
	parNode:addChild(per_bkg2, 10)
	parNode:addChild(per_bkg3, 10)
	parNode:addChild(per_bkg4, 10)
	parNode:addChild(per_value1, 10)
	parNode:addChild(per_value2, 10)
	parNode:addChild(per_value3, 10)
	parNode:addChild(per_value4, 10)
	parNode:addChild(per_mid1, 10)
	parNode:addChild(per_mid2, 10)
	parNode:addChild(per_mid3, 10)
	parNode:addChild(per_mid4, 10)

	h_now = h_now - 0.2 - 0.03
	local sensorLayer = CCLayer:create()

	parNode:addChild(sensorLayer)

	local propIntroTag = 107
	local boundingBox = per_bkg4:boundingBox()
	local sensorRect = CCRectMake(boundingBox.origin.x, boundingBox.origin.y, boundingBox.size.width, boundingBox.size.height * 5)
	local isSensorTouchEnd = true

	local function onTouchSensorBegan(x, y)
		if not isSensorTouchEnd then
			return
		end

		local pos = CCPointMake(x, y)
		pos = parNode:convertToNodeSpace(pos)

		if sensorRect:containsPoint(pos) then
			local propIntro = CCSprite:create("v2/introUI/prop_intro.png")

			introLayer:addChild(propIntro, 15)
			propIntro:setAnchorPoint(CCPointMake(1, 1))
			propIntro:setPosition(CCPointMake(x, y))
			propIntro:setTag(propIntroTag)
			d_ms.d_u.setStyles(propIntro, {
				scale = 0.4
			})

			isSensorTouchEnd = false

			return true
		end

		return false
	end

	local function onTouchSensorMoved(x, y)
		return true
	end

	local function onTouchSensorEnded(x, y)
		introLayer:removeChildByTag(propIntroTag, true)

		isSensorTouchEnd = true

		return true
	end

	local function onTouchSensor(touchType, x, y)
		if touchType == CCTOUCHBEGAN then
			return onTouchSensorBegan(x, y)
		elseif touchType == CCTOUCHMOVED then
			return onTouchSensorMoved(x, y)
		else
			return onTouchSensorEnded(x, y)
		end
	end

	sensorLayer:registerScriptTouchHandler(onTouchSensor, false, -128, false)
	sensorLayer:setTouchEnabled(true)

	local info_level = d_ms.d_mainUI.g_playerInfo.level

	if info_level >= 0 and (argInfoTab.id and argInfoTab.id > 0 or argInfoTab.isReadOnly) then
		local jpmk_Bkg = d_ms.d_u.createByStyles({
			pic = "v2/introUI/small_label.png",
			scale = 0.4,
			x = w_begin + 0.25,
			y = h_now
		})

		parNode:addChild(jpmk_Bkg)

		local w_title, h_title = d_ms.d_u.getPicScale(jpmk_Bkg)
		local jpmk_Title = d_ms.d_u.createByStyles({
			pic = "v2/introUI/intro_label_jpmk.png",
			x = w_begin + 0.25,
			y = h_now,
			scaleY = h_title * 0.75
		})

		parNode:addChild(jpmk_Title)

		h_now = h_now - h_title / 2 - 0.03
		local jp_data = {}

		if argInfoTab.id then
			jp_data = d_ms.d_jpmkUI.getJP(argInfoTab.id)
		else
			local tag = argInfoTab.order

			if d_ms.d_checkLineupUI.displayLineupInfo.ext_skill_list[tag] then
				for i = 1, #d_ms.d_checkLineupUI.displayLineupInfo.ext_skill_list[tag] do
					local file_t, name_t = d_ms.d_data.getFileIdByExtSkillType(d_ms.d_checkLineupUI.displayLineupInfo.ext_skill_list[tag][i].type_id)
					local tmp_t = {
						level = d_ms.d_checkLineupUI.displayLineupInfo.ext_skill_list[tag][i].level,
						csvInfo = {
							file = file_t,
							name = name_t
						}
					}

					table.insert(jp_data, tmp_t)
				end
			end
		end

		local jp_btn_list = {
			x = 0,
			y = 0
		}

		function pressMK(tag)
			cclog("pressMK, tag=" .. tag)

			if argInfoTab.isReadOnly == true then
				-- Nothing
			else
				local p_layer = introLayer:getParent()

				d_ms.d_jpmkUI.show(p_layer, 1000, argInfoTab.id)
				p_layer:removeChildByTag(d_ms.d_data.getTagFromDef("introLayer"), true)

				if g_formationUI.detailLayer and g_formationUI.detailLayer.mainLayer then
					g_formationUI.detailLayer.mainLayer = nil
				end
			end
		end

		for i = 1, 4 do
			local bkg_pic_name = "v2/jpmkUI/jp_no_open.png"

			if argInfoTab.equiped_ext_skill_limit and i <= argInfoTab.equiped_ext_skill_limit and info_level >= 38 and argInfoTab.id then
				bkg_pic_name = "v2/jpmkUI/jp_bkg.png"
			end

			if jp_data[i] then
				bkg_pic_name = "v2/jpmkUI/jp_bkg.png"
				local jp_name = d_ms.d_u.createByStyle({
					type = "label",
					fontsize = 26,
					string = jp_data[i].csvInfo.name,
					x = w_begin + 0.11 * i - 0.04,
					y = h_now - h_title * 1.7,
					color = {
						251,
						180,
						120
					}
				})

				parNode:addChild(jp_name, 3)

				local jp_sprite = d_ms.d_u.createByStyles({
					scale = 0.07,
					pic = "skill/ext/" .. jp_data[i].csvInfo.file .. ".png",
					x = w_begin + 0.11 * i - 0.04,
					y = h_now - h_title * 0.7
				})

				parNode:addChild(jp_sprite, 2)

				local jp_sprite_w, jp_sprite_h = d_ms.d_u.getRealScale(jp_sprite)

				parNode:addChild(d_ms.d_u.createByStyle({
					type = "label",
					fontsize = 26,
					string = "lv" .. jp_data[i].level,
					x = w_begin + 0.11 * i - 0.04 - 0.4 * jp_sprite_w,
					y = h_now - h_title * 0.7 + 0.45 * jp_sprite_h,
					color = {
						178,
						255,
						63
					},
					anchor = {
						0,
						1
					}
				}), 3)
			end

			table.insert(jp_btn_list, {
				scale = 0.09,
				x = w_begin + 0.11 * i - 0.04,
				y = h_now - h_title * 0.7,
				npic = bkg_pic_name,
				spic = bkg_pic_name,
				tag = i,
				call_back = pressMK
			})
		end

		if argInfoTab.isReadOnly ~= true then
			table.insert(jp_btn_list, {
				npic = "v2/jpmkUI/jp_mk1.png",
				spic = "v2/jpmkUI/jp_mk2.png",
				tag = 5,
				x = w_begin + 0.25,
				y = h_now - h_title * 2.5,
				call_back = pressMK
			})
		end

		local main_menu = d_ms.d_u.createMenu(jp_btn_list)

		parNode:addChild(main_menu, 1)

		h_now = h_now - 0.32
	end

	local jpmk_inter = d_ms.d_u.createByStyles({
		pic = "v2/jpmkUI/formation_inter.png",
		scale = 0.4,
		x = w_begin + 0.23,
		y = h_now
	})

	parNode:addChild(jpmk_inter)

	h_now = h_now - 0.02

	if argInfoTab.csvInfo and argInfoTab.csvInfo.introduction then
		local introTTF = CCLabelTTF:create(argInfoTab.csvInfo.introduction, "arial", 26, d_ms.d_u.ccSizeMake(0.4, 0), kCCTextAlignmentLeft)
		local w_introTTF, h_introTTF = d_ms.d_u.getPicScale(introTTF)

		d_ms.d_u.setStyle(introTTF, {
			x = w_begin + w_introTTF / 2 + 0.02,
			y = h_now - h_introTTF / 2
		})
		parNode:addChild(introTTF)

		h_now = h_now - h_introTTF - 0.02
	end

	h_now = h_now - 0.1
	local introBkg = d_ms.d_u.createByStyles({
		pic = "v2/introUI/small_label.png",
		scale = 0.4,
		x = w_begin + 0.25,
		y = h_now
	})

	parNode:addChild(introBkg)

	local w_title, h_title = d_ms.d_u.getPicScale(introBkg)
	local introTitle = d_ms.d_u.createByStyles({
		pic = "v2/introUI/yuanfen_label.png",
		x = w_begin + 0.25,
		y = h_now,
		scaleY = h_title
	})

	parNode:addChild(introTitle)

	h_now = h_now - h_title / 2 - 0.02
	local fateTab = d_ms.d_lineupUI.g_fateAttrTable.character[argInfoTab.type]

	if fateTab ~= nil then
		for i = 1, #fateTab do
			local fateNameTTF = CCLabelTTF:create(fateTab[i].description, "arial", 30, d_ms.d_u.ccSizeMake(0.4, 0), kCCTextAlignmentLeft)

			fateNameTTF:setColor(ccc3(248, 189, 48))

			local w_fateNameTTF, h_fateNameTTF = d_ms.d_u.getPicScale(fateNameTTF)

			d_ms.d_u.setStyle(fateNameTTF, {
				x = w_begin + w_fateNameTTF / 2 + 0.06,
				y = h_now - h_fateNameTTF / 2
			})
			parNode:addChild(fateNameTTF)

			local redPoint = CCSprite:create("v2/CharaterUI/hongdian.png")

			d_ms.d_u.setStyle(redPoint, {
				x = w_begin + 0.03,
				y = h_now - h_fateNameTTF / 2
			})
			parNode:addChild(redPoint)

			h_now = h_now - h_fateNameTTF - 0.01
			local fateIntroTTF = CCLabelTTF:create(fateTab[i].introduction, "arial", 26, d_ms.d_u.ccSizeMake(0.4, 0), kCCTextAlignmentLeft)
			local w_fateIntroTTF, h_fateIntroTTF = d_ms.d_u.getPicScale(fateIntroTTF)
			local introduction = fateTab[i].introduction

			if not fateTab[i].targetListTable then
				local fateItemList = d_ms.d_lineupUI.parseFateTargetStr(fateTab[i].targetList)
				fateTab[i].targetListTable = fateItemList
			end

			local currentFataTable = fateTab[i].targetListTable
			menu_item_list = {
				x = 0,
				y = 0
			}

			local function pressUnderline(tag)
				if tag == nil or tag <= 0 then
					return
				end

				local fate_list_id = math.floor(tag / 10)
				local fate_id = math.mod(tag, 10)
				local currentFate, targetType, targetId = nil

				if fateTab[fate_list_id] ~= nil then
					currentFate = fateTab[fate_list_id].targetListTable
					targetType = fateTab[fate_list_id].targetType
				end

				if currentFate ~= nil then
					targetId = currentFate[fate_id]
				end

				if targetId == nil then
					cclog("targetId is nil, tag=" .. tag)

					return
				end

				clickUnderlineShowDetail(introLayer, targetType, tonumber(targetId))
			end

			for j = 1, #currentFataTable do
				local fate_id = tonumber(currentFataTable[j])
				local fate_name = ""

				if fateTab[i].targetType == 4 then
					fate_name = d_ms.d_data.getCharNameById(fate_id)
				elseif fateTab[i].targetType == 5 then
					fate_name = d_ms.d_data.getItemName(fate_id)
				elseif fateTab[i].targetType == 6 then
					fate_name = d_ms.d_data.getSkillName(fate_id)
				end

				local str_pos_s, str_pos_e = string.find(introduction, fate_name)

				if str_pos_s ~= nil and str_pos_s ~= 0 then
					local single_hz_w = d_ms.d_u.getSingleHzWidthBySize(26)
					local underline_x = w_begin + 0.06 + single_hz_w * (str_pos_s - 1) / 3
					local underline_y = h_now + 0.01
					local underline_scalex = single_hz_w * (str_pos_e - str_pos_s + 1) / 3

					table.insert(menu_item_list, {
						spic = "v2/CharaterUI/underline2.png",
						npic = "v2/CharaterUI/underline1.png",
						x = underline_x,
						y = underline_y,
						scaleX = underline_scalex,
						scaleY = h_fateNameTTF * 1.3,
						tag = 10 * i + j,
						call_back = pressUnderline,
						anchor = {
							0,
							1
						}
					})
				end
			end

			local underline_menu = d_ms.d_u.createMenu(menu_item_list)

			if #currentFataTable <= 1 then
				local menuItemLabel = CCMenuItemLabel:create(fateIntroTTF)

				menuItemLabel:setTag(10 * i + 1)
				menuItemLabel:registerScriptTapHandler(pressUnderline)

				local label_menu = CCMenu:createWithItem(menuItemLabel)

				label_menu:setPosition(CCPointMake(0, 0))
				d_ms.d_u.setStyle(menuItemLabel, {
					x = w_begin + w_fateIntroTTF / 2 + 0.06,
					y = h_now - h_fateIntroTTF / 2
				})
				parNode:addChild(label_menu, 11)
			else
				d_ms.d_u.setStyle(fateIntroTTF, {
					x = w_begin + w_fateIntroTTF / 2 + 0.06,
					y = h_now - h_fateIntroTTF / 2
				})
				parNode:addChild(fateIntroTTF, 11)
			end

			parNode:addChild(underline_menu, 12)

			h_now = h_now - h_fateIntroTTF - 0.01
		end
	end

	h_now = h_now - 0.1
	local talentBkg = d_ms.d_u.createByStyles({
		pic = "v2/introUI/small_label.png",
		scale = 0.4,
		x = w_begin + 0.25,
		y = h_now
	})

	parNode:addChild(talentBkg)

	local w_title, h_title = d_ms.d_u.getPicScale(talentBkg)
	local talentImg = d_ms.d_u.createByStyles({
		pic = "v2/introUI/talent_label.png",
		x = w_begin + 0.25,
		y = h_now,
		scaleY = h_title - 0.02
	})

	parNode:addChild(talentImg)

	h_now = h_now - h_title / 2 - 0.05

	if argInfoTab.csvInfo then
		local sk_id = argInfoTab.csvInfo.originalSkill
		local sk_tab = d_ms.d_packageUI.g_itemSkillTable[sk_id]

		if sk_tab then
			local sk_icon = d_ms.d_data.getSmallSkillSprite(sk_id)

			d_ms.d_u.setStyle(sk_icon, {
				scale = 0.1
			})

			local w_sk_icon, h_sk_icon = d_ms.d_u.getPicScale(sk_icon)

			d_ms.d_u.setStyle(sk_icon, {
				x = w_begin + 0.03 + w_sk_icon / 2,
				y = h_now - h_sk_icon / 2
			})
			parNode:addChild(sk_icon)

			local sk_name = CCLabelTTF:create(sk_tab.name, "arial", 30)

			sk_name:setColor(ccc3(248, 189, 48))

			local w_sk_name, h_sk_name = d_ms.d_u.getPicScale(sk_name)

			d_ms.d_u.setStyle(sk_name, {
				x = w_begin + w_sk_icon + w_sk_name / 2 + 0.045,
				y = h_now - h_sk_name / 2
			})
			parNode:addChild(sk_name)

			h_now = h_now - h_sk_name
			local sk_intro = CCLabelTTF:create(sk_tab.introduction, "arial", 26, d_ms.d_u.ccSizeMake(0.28, 0), kCCTextAlignmentLeft)
			local w_sk_intro, h_sk_intro = d_ms.d_u.getPicScale(sk_intro)

			d_ms.d_u.setStyle(sk_intro, {
				x = w_begin + w_sk_icon + w_sk_intro / 2 + 0.045,
				y = h_now - h_sk_intro / 2
			})
			parNode:addChild(sk_intro)

			h_now = h_now - h_sk_intro
		end
	end

	h_now = h_now - 0.1

	return h_begin - h_now
end

function loadingCharactorsHeadImage()
	local gcl = g_formationUI.changeLayer
	gcl.charactors = {}
	gcl.srcCharList = {}
	local tabc = d_ms.d_lineupUI.g_characterInfo
	local kNcs = 0

	for i = 1, #tabc do
		kNcs = tabc[i].order < kNcs and kNcs or tabc[i].order
	end

	for i = 1, kNcs do
		for j = 1, #tabc do
			if tabc[j].order == i then
				local str = tabc[j].csvInfo.file
				gcl.charactors[i] = {
					ImgSprite = d_ms.d_data.getHeadSprite(tabc[j].type),
					id = tabc[j].id
				}
				gcl.srcCharList[i] = tabc[j].id

				d_ms.d_u.setProperties(gcl.mainLayer, gcl.charactors[i].ImgSprite, lt_CLHolesPosition[i])
				gcl.mainLayer:addChild(gcl.charactors[i].ImgSprite, 1)

				break
			end
		end
	end

	local cc = d_ms.d_mainUI.g_playerInfo.cortege_count

	for i = 1 + cc, kMcs do
		local lockImg = CCSprite:create("v2/CharaterUI/suo.png")

		d_ms.d_u.setProperties(gcl.mainLayer, lockImg, lt_CLHolesPosition[i])
		gcl.mainLayer:addChild(lockImg)
	end
end

function loadCharacterInfo(parNode, argTab, isSoul)
	local vsz = CCDirector:sharedDirector():getVisibleSize()
	local container = CCLayer:create()
	local characterLayer = CCScrollView:create(CCSizeMake(vsz.width * 0.44, vsz.height), tolua.cast(container, "CCNode"))

	characterLayer:setPosition(vsz.width * 0.037, 0)
	parNode:addChild(characterLayer, 2)

	local characterSprite = d_ms.d_data.getBodySprite(argTab.type)

	d_ms.d_u.setStyles(characterSprite, {
		scaleH = 0.6,
		x = 0.23,
		y = 0.27
	})
	characterSprite:setAnchorPoint(CCPointMake(0.5, 0))
	container:addChild(characterSprite, 1)

	local cNameImg = d_ms.d_data.getNameSprite(argTab.type)
	local tcnsz = cNameImg:getContentSize()

	d_ms.d_u.setProperties(parNode, cNameImg, {
		scaleW = 0.0390625,
		x = 0.084375,
		y = 0.5
	})
	parNode:addChild(cNameImg, 5)

	local tmp_cate = tonumber(argTab.csvInfo.category)

	if tmp_cate < 1 or tmp_cate > 5 then
		cclog("ERROR: category=" .. tmp_cate)

		tmp_cate = 1
	end

	local typeImg = CCSprite:create("v2/charPositionUI/type_" .. tmp_cate .. ".png")

	d_ms.d_u.setProperties(parNode, typeImg, {
		x = 0.05625,
		y = 0.875
	})
	parNode:addChild(typeImg)

	if argTab.evolve_level and argTab.evolve_level > 0 then
		local feishengseal = CCSprite:create("v2/feishengUI/seal.png")

		d_ms.d_u.setStyles(feishengseal, {
			x = 0.4,
			y = 0.85
		})
		parNode:addChild(feishengseal, 10)
		d_ms.d_data.addFSccbi(characterSprite, argTab.evolve_level)

		if argTab.evolve_level <= 10 then
			local feishengCount = CCSprite:create("v2/feishengUI/" .. argTab.evolve_level .. ".png")

			d_ms.d_u.setStyles(feishengCount, {
				x = 0.4,
				y = 0.85
			})
			parNode:addChild(feishengCount, 10)
		else
			local first = math.floor(argTab.evolve_level / 10)
			local second = argTab.evolve_level - first * 10
			local firstCount = nil

			if first == 1 then
				firstCount = CCSprite:create("v2/feishengUI/" .. "10" .. ".png")
			else
				firstCount = CCSprite:create("v2/feishengUI/" .. first .. ".png")
			end

			d_ms.d_u.setStyles(firstCount, {
				x = 0.4,
				y = 0.85
			})
			firstCount:setScale(0.8)
			firstCount:setAnchorPoint(CCPointMake(0.8, 0.5))
			parNode:addChild(firstCount, 10)

			local secondCount = CCSprite:create("v2/feishengUI/" .. second .. ".png")

			d_ms.d_u.setStyles(secondCount, {
				x = 0.4,
				y = 0.85
			})
			secondCount:setScale(0.8)
			secondCount:setAnchorPoint(CCPointMake(0.2, 0.5))
			parNode:addChild(secondCount, 10)
		end
	end

	if argTab.csvInfo.quality then
		local starsSprite = CCSprite:create("v2/CharaterUI/stars.png")
		local ssz = starsSprite:getContentSize()

		starsSprite:setTextureRect(CCRectMake(0, 0, ssz.width, ssz.height * argTab.csvInfo.quality / 5))
		d_ms.d_u.setProperties(parNode, starsSprite, {
			x = 0.05625,
			y = 0.5
		})
		parNode:addChild(starsSprite, 5)
	end

	local levelSprite = CCSprite:create("v2/charPositionUI/level_bkg.png")

	d_ms.d_u.setStyles(levelSprite, {
		x = 0.06812499999999999,
		y = 0.20833333333333334
	})
	parNode:addChild(levelSprite)
	levelSprite:setScale(d_ms.d_mainUI.g_scaleW)
	d_ms.d_charPositionUI.createLevelSprite(argTab.level, levelSprite)

	if isSoul then
		local soulLabel = CCSprite:create("v2/introUI/soul_label.png")

		soulLabel:setAnchorPoint(CCPointMake(1, 1))
		d_ms.d_u.setProperties(parNode, soulLabel, {
			scaleW = 0.0703125,
			x = 0.46875,
			y = 0.8888888888888888
		})
		parNode:addChild(soulLabel)
	end

	local expBkg = CCSprite:create("v2/CharaterUI/expbar1.png")

	expBkg:setAnchorPoint(CCPointMake(0, 0.5))

	local expsz = expBkg:getContentSize()

	d_ms.d_u.setProperties(parNode, expBkg, {
		scaleW = expsz.width / 1280 / 1.2
	})

	local expsc = expBkg:getScale()

	d_ms.d_u.setProperties(parNode, expBkg, {
		y = 0.20833333333333334,
		px = vsz.width * 332 / 1280 - expsz.width * expsc / 2
	})
	parNode:addChild(expBkg)

	if argTab.cur_exp and argTab.next_exp then
		local expImg = CCSprite:create("v2/CharaterUI/expbar2.png")
		local episz = expImg:getContentSize()

		expImg:setTextureRect(CCRectMake(0, 0, episz.width * argTab.cur_exp / argTab.next_exp, episz.height))
		expImg:setAnchorPoint(CCPointMake(0, 0.5))
		expImg:setScale(expsc)
		d_ms.d_u.setProperties(parNode, expImg, {
			y = 0.20833333333333334,
			px = vsz.width * 332 / 1280 - expsz.width * expsc / 2 + vsz.width * 10 / 1280
		})
		parNode:addChild(expImg)

		if not argTab.isReadOnly then
			local expLabel = CCLabelTTF:create(tostring(argTab.cur_exp) .. "/" .. tostring(argTab.next_exp), "arial", 26)

			d_ms.d_u.setProperties(parNode, expLabel, {
				x = 0.259375,
				y = 0.20833333333333334
			})
			parNode:addChild(expLabel)
		end
	end

	local states = {
		health = argTab.hp,
		damage = argTab.gongji,
		defence = argTab.fangyu,
		mana = argTab.magic
	}
	local proBar, proTab = d_ms.d_trainingUI.createCharaterStatsBar(states, 1)

	d_ms.d_u.setProperties(parNode, proBar, {
		scaleW = 0.3359375,
		x = 0.259375,
		y = 0.2569444444444444
	})
	parNode:addChild(proBar, 2)
end

function loadingAllCharacters(argHoleNum)
	local vsz = CCDirector:sharedDirector():getVisibleSize()
	local gsl = g_formationUI.selectLayer
	gsl.holeNum = argHoleNum
	local singleHigh = vsz.height * 120 / 720
	gsl.characters = sortCharTableInSelectLayer()
	local sum = #gsl.characters
	local sview = createScrollViewInSL(gsl.mainLayer, sum, singleHigh)

	for i = 1, sum do
		local guideCheck = createCharacterItem(sview, gsl.characters[i], i, sum, singleHigh)

		if i == 1 then
			g_guideCheck = guideCheck
		end
	end
end

function createScrollViewInSL(parentLayer, count, sglH)
	local frame_size = d_ms.d_mainUI.createSecondaryLayBkg(parentLayer)
	local scrollviewSize = {
		width = frame_size.width,
		height = frame_size.height * 0.98
	}
	local gsl = g_formationUI.selectLayer
	gsl.cellsView = CCLayer:create()
	gsl.scrollView = CCScrollView:create(CCSizeMake(scrollviewSize.width, scrollviewSize.height), tolua.cast(gsl.cellsView, "CCNode"))

	gsl.cellsView:setContentSize(CCSizeMake(scrollviewSize.width, count * sglH))
	gsl.cellsView:setPositionY(scrollviewSize.height - count * sglH)
	gsl.scrollView:setPosition(CCPointMake(frame_size.x, frame_size.y * 1.05))
	parentLayer:addChild(gsl.scrollView)

	return gsl.cellsView
end

function sortCharTableInSelectLayer()
	local l_ctab = d_ms.d_lineupUI.g_characterInfo
	local retab = {}

	for i = 1, #l_ctab do
		local ele = makeCharacterTable(i)

		if ele then
			if #retab ~= 0 then
				if ele.quality < retab[#retab].quality or ele.quality == retab[#retab].quality and ele.lv <= retab[#retab].lv then
					table.insert(retab, ele)
				else
					for j = 1, #retab do
						if retab[j].quality < ele.quality then
							table.insert(retab, j, ele)

							break
						elseif ele.quality == retab[j].quality and retab[j].lv < ele.lv then
							table.insert(retab, j, ele)

							break
						end
					end
				end
			else
				table.insert(retab, ele)
			end
		end
	end

	return retab
end

function makeCharacterTable(idx)
	local l_ctab = d_ms.d_lineupUI.g_characterInfo

	if l_ctab[idx].order ~= 0 then
		return nil
	end

	local ret = {
		type = l_ctab[idx].type,
		id = l_ctab[idx].id,
		lv = l_ctab[idx].level,
		name = l_ctab[idx].csvInfo.name,
		file = l_ctab[idx].csvInfo.file,
		quality = l_ctab[idx].csvInfo.quality,
		order = l_ctab[idx].order
	}

	return ret
end

function createCharacterItem(cellsView, tab, idx, count, sglH)
	local vsz = CCDirector:sharedDirector():getVisibleSize()
	local cssz = cellsView:getContentSize()
	local py = cssz.height - idx * sglH + sglH / 2
	local bkgSprite = CCSprite:create("v2/packageUI/xinxilan.png")
	local tbsSize = bkgSprite:getContentSize()
	local scl = sglH / tbsSize.height

	if scl > 1.2 then
		bkgSprite:setScale(0.97 * cssz.width / tbsSize.width)
	else
		bkgSprite:setScale(scl)
	end

	bkgSprite:setPosition(cssz.width / 2, py)
	cellsView:addChild(bkgSprite)

	tab.BkgSprite = bkgSprite
	local parNode = bkgSprite
	local imgSprite = d_ms.d_data.getHeadSprite(tab.type)

	d_ms.d_u.setProperties(parNode, imgSprite, {
		scaleH = 0.8,
		x = 0.07608695652173914,
		y = 0.5
	})
	parNode:addChild(imgSprite)

	tab.ImgSprite = imgSprite
	local nameSprite = CCLabelTTF:create(tab.name, "arial", 30)

	nameSprite:setAnchorPoint(CCPointMake(0, 0.5))
	nameSprite:setColor(ccc3(253, 125, 86))
	d_ms.d_u.setProperties(parNode, nameSprite, {
		x = 0.16304347826086957,
		y = 0.5
	})
	parNode:addChild(nameSprite)

	local lvLabel = CCSprite:create("v2/introUI/level.png")

	d_ms.d_u.setProperties(parNode, lvLabel, {
		x = 0.42,
		y = 0.5
	})
	parNode:addChild(lvLabel)

	local lvSprite = CCLabelTTF:create(tostring(tab.lv), "arial", 30)

	d_ms.d_u.setProperties(parNode, lvSprite, {
		x = 0.47,
		y = 0.5
	})
	parNode:addChild(lvSprite)

	if tab.quality then
		local starsSprite = CCSprite:create("v2/introUI/stars.png")
		local ssz = starsSprite:getContentSize()

		starsSprite:setTextureRect(CCRectMake(0, 0, ssz.width * tab.quality / 5, ssz.height))
		starsSprite:setAnchorPoint(CCPointMake(0, 0.5))
		d_ms.d_u.setProperties(parNode, starsSprite, {
			x = 0.55,
			y = 0.5
		})
		parNode:addChild(starsSprite)
	end

	local numSprite = CCLabelTTF:create(tostring(idx), "arial", 22)

	d_ms.d_u.setProperties(parNode, numSprite, {
		x = 0.15,
		y = 0.8
	})
	parNode:addChild(numSprite)

	if tab.order ~= 0 then
		local fightTTF = CCLabelTTF:create(d_ms.d_hz.gethz("fighting"), "arial", 22)

		fightTTF:setAnchorPoint(CCPointMake(0, 0))
		d_ms.d_u.setProperties(parNode, fightTTF, {
			x = 0.16304347826086957,
			y = 0.15
		})
		parNode:addChild(fightTTF)
	end

	local cframeSprite = CCSprite:create("v2/multi-selectUI/check_frame.png")

	d_ms.d_u.setProperties(parNode, cframeSprite, {
		x = 0.85,
		y = 0.5
	})
	parNode:addChild(cframeSprite)

	return cframeSprite
end

function sendReplacePosToServer()
	if d_ms.d_mainUI.g_isNeedGuide == true then
		local tmpRequest = {
			stage = d_ms.d_common_def.new_role_guide.change_cortege,
			name = tostring(d_ms.d_guideUI.g_secondCharID),
			head_type = 0
		}

		cclog("\\xb3\\xf5\\xb4θ\\xfc\\xbb\\xbb\\xb5\\xdc\\xd7\\xd3")
		d_ms.d_u.main_server_send_msg(d_ms.d_msg_def.gscl_msg_id.msg_new_role_guide, tmpRequest)

		return
	end

	local gsl = g_formationUI.selectLayer
	local sn = gsl.selectNum
	local hn = gsl.holeNum
	local g_Cinfo = gsl.characters
	local tmpMsg = {
		flag = 4,
		count = 1,
		change_info = {
			{
				id = g_Cinfo[sn].id,
				new_order = hn
			}
		}
	}

	d_ms.d_u.main_server_send_msg(d_ms.d_msg_def.gscl_msg_id.msg_change_cortege_order, tmpMsg)
end

function sendChangePosToServer(argFlag)
	if argFlag == nil then
		argFlag = 0
	end

	local gcl = g_formationUI.changeLayer
	local tmpMsg = {
		count = 0,
		flag = argFlag,
		change_info = {}
	}

	for i = 1, #gcl.srcCharList do
		if gcl.srcCharList[i] ~= gcl.charactors[i].id then
			tmpMsg.count = tmpMsg.count + 1

			table.insert(tmpMsg.change_info, {
				id = gcl.charactors[i].id,
				new_order = i
			})
		end
	end

	if #tmpMsg.change_info ~= 0 then
		d_ms.d_u.main_server_send_msg(d_ms.d_msg_def.gscl_msg_id.msg_change_cortege_order, tmpMsg)

		return true
	else
		return false
	end
end

function reloadSrcCharList()
	local tabc = d_ms.d_lineupUI.g_characterInfo
	local kNcs = 0

	for i = 1, #tabc do
		kNcs = tabc[i].order < kNcs and kNcs or tabc[i].order
	end

	local gcl = g_formationUI.changeLayer

	if not gcl.mainLayer then
		return
	end

	for i = 1, kNcs do
		for j = 1, #tabc do
			if tabc[j].order == i then
				gcl.srcCharList[i] = tabc[j].id

				break
			end
		end
	end
end

function replaceCharSucceed()
	menuCancelSL()
	menuCancelDL()
end

function judgeChangePos(willShowMenuTag)
	if not g_formationUI.changeLayer.mainLayer then
		return false
	else
		local re = sendChangePosToServer(5)

		if re then
			g_formationUI.willShow = willShowMenuTag
		end

		return re
	end
end

function sendConjureCharacterToServer(soultypeid)
	if d_ms.d_allLineupUI.checkSoulComposeCountEnough(soultypeid) then
		local tmpMsg = {
			type_id = soultypeid
		}

		d_ms.d_u.main_server_send_msg(d_ms.d_msg_def.gscl_msg_id.msg_compose_spirit, tmpMsg)
	end
end

function clickUnderlineShowDetail(parent_layer, obj_type, obj_id)
	cclog("call clickUnderlineShowDetail,obj_type=%d, obj_id=%d", obj_type, obj_id)

	function menuCancel()
		d_ms.d_music_mgr.playClickEffect()

		if g_charintro_layer.mainLayer then
			g_charintro_layer.mainLayer:removeFromParentAndCleanup(true)
		end

		g_charintro_layer.mainLayer = nil
		g_charintro_layer = {}
	end

	function menuItemCancel()
		d_ms.d_music_mgr.playClickEffect()

		if g_item_layer.mainLayer then
			g_item_layer.mainLayer:removeFromParentAndCleanup(true)
		end

		g_item_layer.mainLayer = nil
		g_item_layer = {}
	end

	if obj_type == 4 then
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
		local book_hide = nil

		if d_ms.d_lineupUI.g_characterAttrTable[obj_id] then
			book_hide = d_ms.d_lineupUI.g_characterAttrTable[obj_id].book_hide
		end

		if book_hide == nil or book_hide < 1 then
			d_ms.d_info.show(d_ms.d_hz.gethz("has_not_get_item"), 1, 0.7)

			return
		end

		g_charintro_layer = {}
		local argInfoTab = {
			csvInfo = d_ms.d_c.table_copy(d_ms.d_lineupUI.g_characterAttrTable[obj_id]),
			type = obj_id,
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

		d_ms.d_formationUI.createCharacterIntroduceLayer(g_charintro_layer, parent_layer, argInfoTab, 70, false, lt_IntroMenuList, true)
	elseif obj_type == 5 then
		g_item_layer = {
			mainLayer = d_ms.d_subLevelUI.createPriItemIntroLayer(5, obj_id, menuItemCancel)
		}

		if g_item_layer.mainLayer then
			parent_layer:addChild(g_item_layer.mainLayer, 70)
		end
	elseif obj_type == 6 then
		g_item_layer = {
			mainLayer = d_ms.d_subLevelUI.createPriItemIntroLayer(6, obj_id, menuItemCancel)
		}

		if g_item_layer.mainLayer then
			parent_layer:addChild(g_item_layer.mainLayer, 70)
		end
	else
		cclog("showHandbookDetail find last_tag error=%d", obj_type)
	end
end
