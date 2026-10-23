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
local CCLuaLog = CCLuaLog
local class = class
local CCArray = CCArray
local CCDirector = CCDirector
local CCLayer = CCLayer
local CCMenu = CCMenu
local CCMenuItemImage = CCMenuItemImage
local CCSprite = CCSprite
local CCTOUCHBEGAN = CCTOUCHBEGAN
local CCTOUCHMOVED = CCTOUCHMOVED
local CCMenuItemSprite = CCMenuItemSprite
local CCMenuItemImage = CCMenuItemImage
local CCPointMake = CCPointMake
local CCMoveBy = CCMoveBy
local CCDelayTime = CCDelayTime
local ccc3 = ccc3
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
local CCScaleTo = CCScaleTo
local CCNode = CCNode
local CCRectMake = CCRectMake
local CCSpriteBatchNode = CCSpriteBatchNode
local CCFadeIn = CCFadeIn
local CCSpawn = CCSpawn
local CCEaseInOut = CCEaseInOut
local CCScaleBy = CCScaleBy
local CCFadeOut = CCFadeOut
local ccpDistance = ccpDistance
local CCTOUCHBEGAN = CCTOUCHBEGAN
local CCTOUCHMOVED = CCTOUCHMOVED
local ccp = ccp
local ccpSub = ccpSub
local CCFadeTo = CCFadeTo

module("ui.charPositionUI")

d_ms = require("ms")

if not d_ms then
	print("charPositionUI load d_ms fail.\n")
end

local function cclog(...)
	CCLuaLog(string.format("Lua : charPositionUI >> %s", string.format(...)))
end

local o_t = d_ms.d_common_def.object_type
local m_t = d_ms.d_common_def.item_main_type
local scrSize = CCDirector:sharedDirector():getVisibleSize()
local gethz = d_ms.d_hz.gethz
tagDef = {
	posHZ = 47,
	groundLight = 59,
	itemLevel = 7,
	chgCharButton = 37,
	enterInMenu = 1001,
	itemChange = 31,
	powerNum = 67,
	headSelect = 17,
	usedItemIntro = 29,
	charInfo = 19,
	charCells = 53,
	Tier = 1002,
	headButton = 13,
	chgCharHZ = 43,
	posButton = 41,
	wake_guide = 1003,
	charSprite = 23
}
guestureDef = {
	right = 2,
	left = 1,
	none = 0
}
g_lastShowOrder = 0
g_isQuitBoard = true
isDirectShow = false
g_lastCombat = {}

function loadData()
	if not d_ms.d_packageUI.g_isPackageSorted then
		d_ms.d_packageUI.sortItems()
	end

	g_charPosUI = {
		usedCharacters = d_ms.d_lineupUI.g_usedCharacters,
		cheerCharacters = d_ms.d_lineupUI.g_cheerCharacters,
		allUsedItems = d_ms.d_packageUI.g_usedItems,
		all_cheer_skills = d_ms.d_packageUI.g_cheer_items,
		cortege_count = d_ms.d_mainUI.g_playerInfo.cortege_count,
		isReadOnly = false
	}
end

function show()
	local dMainUI = d_ms.d_mainUI
	local mainUI = dMainUI.g_mainUI
	local main_layer = mainUI.main_layer
	local childBoard = main_layer:getChildByTag(d_ms.d_mainUI.boardID.charPosition)

	if childBoard then
		return
	end

	loadData()

	g_charPosUI.main_layer = main_layer

	create(main_layer)

	local board_layer = g_charPosUI.board_layer

	board_layer:setTag(dMainUI.boardID.charPosition)
	board_layer:setPosition(d_ms.d_u.makePoint(0, 1))
	d_ms.d_mainUI.showBoard(board_layer)

	dMainUI.g_boardlayer[dMainUI.boardID.charPosition] = board_layer
	dMainUI.g_currentBoard = dMainUI.boardID.charPosition

	dMainUI.g_mainUI.player_layer:setVisible(false)

	if dMainUI.g_mainUI.menu_other_layer ~= nil then
		dMainUI.g_mainUI.main_layer:removeChild(dMainUI.g_mainUI.menu_other_layer, true)

		dMainUI.g_mainUI.menu_other_layer = nil
	end
end

function create(parent, closeCallBack)
	resetData()

	g_scaleW = d_ms.d_mainUI.g_scaleW
	g_scaleH = d_ms.d_mainUI.g_scaleH
	local board_layer = CCLayer:create()

	parent:addChild(board_layer, 5)

	local function sceneEventHandler(eventType)
		if eventType.name == "exit" then
			g_isQuitBoard = true
			g_charPosUI = {}
			g_touchCharInfo = {}
			g_lastShowOrder = 0

			d_ms.d_cheerSquadUI.forceClose()
		end
	end

	board_layer:registerScriptHandler(sceneEventHandler)

	g_isQuitBoard = false
	g_charPosUI.board_layer = board_layer
	g_charPosUI.parent = parent
	local position = {
		x = 0.5,
		y = 0.56
	}
	local scaleXY = {
		scaleY = 0.82,
		scaleX = 0.97
	}
	local board_size = d_ms.d_mainUI.createBoardBkg(board_layer, position, scaleXY, false, {
		noLeftBkg = true,
		noSplit = true,
		noClose = true
	})
	g_charPosUI.board_size = board_size
	g_charPosUI.boardRect = CCRectMake(board_size.x, board_size.y, board_size.width, board_size.height)
	local chgSkillItemLayer = CCLayer:create()
	g_charPosUI.chgSkillItemLayer = chgSkillItemLayer

	board_layer:addChild(chgSkillItemLayer, 2)

	local container = CCLayer:create()
	local allLayer = CCScrollView:create(CCSizeMake(board_size.width, board_size.height), container)

	allLayer:setPosition(board_size.x, board_size.y)

	if d_ms.d_u.isLuaC() and d_ms.d_u.isIOS() or d_ms.d_u.isWP8() then
		allLayer:setTouchEnabled(false)
	end

	g_charPosUI.allLayer = allLayer
	g_charPosUI.allLayerContainer = container

	board_layer:addChild(allLayer, 2)

	local charLayer = CCLayer:create()
	g_charPosUI.charLayer = charLayer
	local parentPos = allLayer:getPositionLua()

	charLayer:setPosition(-parentPos.x, -parentPos.y)
	allLayer:addChild(charLayer)

	local positionLayer = CCLayer:create()
	g_charPosUI.positionLayer = positionLayer

	allLayer:addChild(positionLayer, 2)

	local chgCharLayer = CCLayer:create()
	g_charPosUI.chgCharLayer = chgCharLayer

	allLayer:addChild(chgCharLayer, 2)
	createCloseMenu(closeCallBack)
	createCharLayer()
	showCheerGuide(board_layer)
end

function showCheerGuide(parent)
	if not g_charPosUI.isReadOnly and d_ms.d_mainUI.hasCheerGuide() then
		local layer = CCLayer:create()

		parent:addChild(layer, 200)
		cclog("is showing cheer_guide!!!!!!!")

		local data = {}
		local cell = {
			str = {},
			pic_table = {}
		}
		local pic_cell = {
			pic = {
				pic = "v2/pethuntUI/guide2.png",
				x = 0.868,
				y = 0.87
			}
		}

		table.insert(cell.pic_table, pic_cell)

		local str_cell = {
			str = "cheer_tip13",
			str_style = {
				x = 0.868,
				y = 0.87 - 110 / scrSize.height
			}
		}

		table.insert(cell.str, str_cell)
		table.insert(data, cell)
		d_ms.d_abyssUI.showAbyssGuideFrame(layer, data)

		return
	else
		return
	end
end

function resetData()
	g_lastTouchItemTag = nil
end

function createCloseMenu(closeCallBack)
	local closeButton = CCMenuItemImage:create("v2/introUI/close1.png", "v2/introUI/close2.png")

	d_ms.d_u.setStyles(closeButton, {
		x = 0.96,
		y = 0.95
	})
	closeButton:setScale(g_scaleW)

	if closeCallBack then
		closeButton:registerScriptTapHandler(closeCallBack)
	else
		closeButton:registerScriptTapHandler(d_ms.d_mainUI.clickVoiceDestroyBoard)
	end

	local closeMenu = CCMenu:createWithItem(closeButton)

	closeMenu:setPosition(CCPointMake(0, 0))
	g_charPosUI.board_layer:addChild(closeMenu, 10)

	g_charPosUI.close_board = closeButton
end

function createCharLayer()
	local scaleW = g_scaleW
	local positionLayer = g_charPosUI.positionLayer
	local posArrow = CCSprite:create("v2/charPositionUI/arrow.png")

	d_ms.d_u.setStyles(posArrow, {
		x = 0.06,
		y = 0.41
	})
	posArrow:setScale(g_scaleH)
	positionLayer:addChild(posArrow)

	local posButtonItem = CCMenuItemImage:create("v2/charPositionUI/arrow_menu.png", "v2/charPositionUI/arrow_menu.png")

	d_ms.d_u.setStyles(posButtonItem, {
		x = 0.06,
		y = 0.41
	})
	posButtonItem:setScale(g_scaleH)
	posButtonItem:registerScriptTapHandler(showPosLayer)

	g_charPosUI.posButtonItem = posButtonItem
	g_charPosUI.posArrow = posArrow
	local posMenu = CCMenu:createWithItem(posButtonItem)

	posMenu:setPosition(0, 0)
	posMenu:setTag(tagDef.posButton)
	positionLayer:addChild(posMenu)

	local posHZ = CCSprite:create("v2/charPositionUI/position_label.png")

	d_ms.d_u.setStyles(posHZ, {
		x = 0.06,
		y = 0.41
	})
	posHZ:setScale(scaleW)
	posHZ:setTag(tagDef.posHZ)
	positionLayer:addChild(posHZ)

	local chgCharLayer = g_charPosUI.chgCharLayer
	local chgCharArrow = CCSprite:create("v2/charPositionUI/arrow.png")

	chgCharArrow:setFlipX(true)
	d_ms.d_u.setStyles(chgCharArrow, {
		x = 0.91,
		y = 0.41
	})
	chgCharArrow:setScale(g_scaleH)
	chgCharLayer:addChild(chgCharArrow)

	local chgCharButtonItem = CCMenuItemImage:create("v2/charPositionUI/arrow_menu.png", "v2/charPositionUI/arrow_menu.png")

	d_ms.d_u.setStyles(chgCharButtonItem, {
		x = 0.91,
		y = 0.41
	})
	chgCharButtonItem:setScale(g_scaleH)
	chgCharButtonItem:registerScriptTapHandler(showChgCharLayer)

	g_charPosUI.chgCharButtonItem = chgCharButtonItem
	g_charPosUI.chgCharHandler = showChgCharLayer
	local chgCharMenu = CCMenu:createWithItem(chgCharButtonItem)

	chgCharMenu:setPosition(0, 0)
	chgCharMenu:setTag(tagDef.chgCharButton)
	chgCharLayer:addChild(chgCharMenu)

	local chgCharHZ = CCSprite:create("v2/charPositionUI/changeHZ.png")

	d_ms.d_u.setStyles(chgCharHZ, {
		x = 0.91,
		y = 0.41
	})
	chgCharHZ:setScale(scaleW)
	chgCharHZ:setTag(tagDef.chgCharHZ)
	chgCharLayer:addChild(chgCharHZ)

	local maskSprite = CCSprite:create("v2/charPositionUI/arrow_mask.png")

	d_ms.d_u.setStyles(maskSprite, {
		x = 0.9,
		y = 0.55
	})
	maskSprite:setScale(g_scaleH)
	maskSprite:setFlipX(true)
	g_charPosUI.charLayer:addChild(maskSprite, 5)

	local maskSprite2 = CCSprite:create("v2/charPositionUI/arrow_mask.png")

	d_ms.d_u.setStyles(maskSprite2, {
		x = 0.12,
		y = 0.55
	})
	maskSprite2:setScale(g_scaleH)
	g_charPosUI.charLayer:addChild(maskSprite2, 5)

	local find = nil

	if d_ms.d_mainUI.hasWakeGuide(true) then
		for i = 1, 8 do
			local useItem = g_charPosUI.allUsedItems[i]
			local useChar = g_charPosUI.usedCharacters[i] and g_charPosUI.usedCharacters[i].character

			if useChar and useChar.reborn_layer and useChar.reborn_layer > 0 then
				for k, v in pairs(useItem) do
					if v.item.protogenic == 1 and v.item.equip_pos == 1 and v.item.awaken and v.item.awaken == 0 and d_ms.d_wakeUI.checkSkillLevel(v.item) then
						g_lastShowOrder = i
						find = true

						break
					end
				end
			end

			if find then
				break
			end
		end
	end

	createHeader(g_lastShowOrder, find)
end

function createHeader(showOrder, isRefresh, hideHeadFrame)
	local parent = g_charPosUI.charLayer

	parent:removeAllChildrenWithCleanup(true)

	local usedCharacters = g_charPosUI.usedCharacters
	local cortege_count = g_charPosUI.cortege_count
	local usedCharactersNum = #usedCharacters
	local showExtraCharacter = false
	g_headButtons = {}
	g_headSprite = {}
	local offset = 0.105
	local startX = 0.13

	if g_charPosUI.isReadOnly then
		offset = 0.09
		startX = 0.26
	end

	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local headBkg = CCSprite:create("v2/charPositionUI/head_bkg.png")

	if g_charPosUI.isReadOnly then
		d_ms.d_u.setStyles(headBkg, {
			y = 0.87,
			scaleX = 0.73,
			x = 0.57,
			scaleY = 0.095 * scrSize.width / scrSize.height
		})
	else
		d_ms.d_u.setStyles(headBkg, {
			y = 0.87,
			scaleX = 0.95,
			x = 0.485,
			scaleY = 0.095 * scrSize.width / scrSize.height
		})
	end

	parent:addChild(headBkg, -5)

	if not g_charPosUI.isReadOnly and d_ms.d_cheerSquadUI.canJoin(d_ms.d_mainUI.g_playerInfo.level + 10) then
		offset = 0.09
		local cheerMenuItem = CCMenuItemImage:create("v2/cheerUI/cheer_head1.png", "v2/cheerUI/cheer_head2.png")

		cheerMenuItem:registerScriptTapHandler(gotoCheerSquadUI)
		d_ms.d_u.setStyles(cheerMenuItem, {
			y = 0.87,
			x = startX + 8.2 * offset
		})

		local menu = CCMenu:createWithItem(cheerMenuItem)

		menu:setPosition(CCPointMake(0, 0))
		parent:addChild(menu)
	end

	local emptyPostion = nil

	for i = 1, 8 do
		local headMenuItem = CCMenuItemImage:create("v2/charPositionUI/square_bkg.png", "v2/charPositionUI/square_bkg.png")

		headMenuItem:registerScriptTapHandler(tapHeadButton)

		g_headButtons[i] = headMenuItem

		d_ms.d_u.setStyles(headMenuItem, {
			y = 0.87,
			x = startX + (i - 1) * offset
		})

		local menu = CCMenu:createWithItem(headMenuItem)

		menu:setPosition(CCPointMake(0, 0))
		parent:addChild(menu, -1)

		local frame = CCSprite:create("v2/charPositionUI/frame1.png")

		d_ms.d_u.setStyles(frame, {
			y = 0.87,
			x = startX + (i - 1) * offset
		})
		parent:addChild(frame)

		local lockSprite = nil

		if i <= usedCharactersNum then
			local characterOrder = usedCharacters[i].character.order

			if characterOrder ~= 0 then
				headMenuItem:setTag(i)

				local headSprite = d_ms.d_data.getHeadSprite(usedCharacters[i].character.type, usedCharacters[i].character.reborn_layer > 0)

				d_ms.d_u.setStyles(headSprite, {
					scale = 0.09,
					y = 0.87,
					x = startX + (i - 1) * offset
				})
				parent:addChild(headSprite)
				headSprite:setOpacity(120)

				g_headSprite[i] = headSprite
			end
		elseif usedCharactersNum < cortege_count and showExtraCharacter == false and not g_charPosUI.isReadOnly then
			emptyPostion = emptyPostion or i

			headMenuItem:setTag(i)

			showExtraCharacter = true
		else
			headMenuItem:setTag(-1)

			lockSprite = CCSprite:create("v2/charPositionUI/lock.png")

			d_ms.d_u.setStyles(lockSprite, {
				y = 0.87,
				x = startX + (i - 1) * offset
			})
			parent:addChild(lockSprite)
		end

		if not lockSprite and g_charPosUI.grid_count and g_charPosUI.grid_count < i then
			lockSprite = CCSprite:create("v2/charPositionUI/lock.png")

			d_ms.d_u.setStyles(lockSprite, {
				opacity = 200,
				y = 0.87,
				x = startX + (i - 1) * offset
			})
			parent:addChild(lockSprite)
		end
	end

	if g_charPosUI.isReadOnly and not hideHeadFrame then
		local hbkg = d_ms.d_u.createByStyles({
			pic = "v2/charPositionUI/hbkg.png",
			x = 0.11,
			y = 0.88
		})

		parent:addChild(hbkg, -5)

		local new_tag = 100
		local headMenuItem = CCMenuItemImage:create("v2/charPositionUI/hframe.png", "v2/charPositionUI/hframe.png")

		headMenuItem:registerScriptTapHandler(tapHeadButton)
		headMenuItem:setTag(new_tag)

		g_headButtons[new_tag] = headMenuItem

		d_ms.d_u.setStyles(headMenuItem, {
			x = 0.11,
			y = 0.87
		})

		local hbkg2 = d_ms.d_u.createByStyles({
			pos_x = 0,
			pic = "v2/charPositionUI/hbkg2.png",
			pos_y = 0,
			anchor = {
				0,
				0
			}
		})

		headMenuItem:addChild(hbkg2)

		local menu = CCMenu:createWithItem(headMenuItem)

		menu:setPosition(CCPointMake(0, 0))
		parent:addChild(menu, -1)

		local headSprite = CCSprite:create("v2/namingUI/head_" .. g_charPosUI.playerInfo.head_type .. ".png")
		headSprite = headSprite or CCSprite:create("v2/namingUI/head_101.png")

		d_ms.d_u.setStyles(headSprite, {
			opacity = 120,
			scale_pic2 = 1.1,
			x = 0.11,
			y = 0.874
		})
		parent:addChild(headSprite)

		g_headSprite[new_tag] = headSprite
		local split = d_ms.d_u.createByStyles({
			pic = "v2/charPositionUI/split2.png",
			x = 0.5,
			y = 0.8
		})

		parent:addChild(split, 0)
	end

	if showOrder and showOrder > 0 then
		tapHeadButton(showOrder, isRefresh)
	else
		if emptyPostion then
			tapHeadButton(emptyPostion)

			local slayer = d_ms.d_u.createSwallowTouchLayer(parent, 0)

			d_ms.d_u.delay(slayer, 0.3, function ()
				slayer:getParent():removeChild(slayer, true)
				showChgCharLayer()
			end)

			return
		end

		tapHeadButton(1)
	end
end

function tapHeadButton(tag, isRefresh)
	if isRefresh == nil then
		isRefresh = false
	end

	if g_lastShowOrder ~= 0 and g_lastShowOrder == tag and not isDirectShow and not isRefresh then
		return
	end

	local parent = g_charPosUI.charLayer

	if tag == -1 then
		if not g_charPosUI.isReadOnly then
			if #g_charPosUI.usedCharacters < g_charPosUI.cortege_count then
				d_ms.d_info.show(gethz("enterInFirst"))
			else
				local cortege_count = g_charPosUI.cortege_count
				local level = d_ms.d_mainUI.g_cortegeCountTable[cortege_count + 1]

				if level then
					d_ms.d_info.show(string.format(gethz("openLevel"), level))
				end
			end
		end

		return
	end

	if g_lastShowOrder and g_lastShowOrder ~= 0 then
		local lastSelectedFrame = parent:getChildByTag(tagDef.headSelect)

		if g_headSprite[g_lastShowOrder] then
			g_headSprite[g_lastShowOrder]:setOpacity(120)
		end

		if lastSelectedFrame then
			parent:removeChild(lastSelectedFrame, true)
		end
	end

	local currentSelected = g_headButtons[tag]
	g_lastShowOrder = tag

	if g_headSprite[tag] then
		g_headSprite[tag]:setOpacity(255)
	end

	local buttonPos = currentSelected:getPositionLua()
	local cpic = tag == 100 and "v2/charPositionUI/choose2.png" or "v2/charPositionUI/choose.png"
	local selectSprite = CCSprite:create(cpic)

	selectSprite:setScale(currentSelected:getScale())

	if tag == 100 then
		selectSprite:setPosition(buttonPos.x, buttonPos.y + 5)
	else
		selectSprite:setPosition(buttonPos)
	end

	parent:addChild(selectSprite, 5)
	selectSprite:setTag(tagDef.headSelect)

	local charInfoLayer = parent:getChildByTag(tagDef.charInfo)

	if charInfoLayer then
		charInfoLayer:removeAllChildrenWithCleanup(true)
	else
		charInfoLayer = CCLayer:create()

		parent:addChild(charInfoLayer, 10)
		charInfoLayer:setTag(tagDef.charInfo)
	end

	g_charPosUI.charInfoLayer = charInfoLayer

	if g_charPosUI.isReadOnly then
		d_ms.d_u.setStyles(g_charPosUI.charInfoLayer, {
			x = 0.08,
			y = 0
		})
	end

	createCharInfo(tag, charInfoLayer)

	if d_ms.d_mainUI.g_isNeedGuide then
		d_ms.d_guideUI.show()
	elseif d_ms.d_enGuideUI.g_isEnhanceGuide then
		d_ms.d_enGuideUI.show()
	end
end

local function moveCharEnd()
	if g_touchCharInfo.guesture == guestureDef.none or not g_touchCharInfo.delta then
		return
	end

	local parentLayer = g_charPosUI.charInfoLayer
	g_touchCharInfo.isTouchBegin = true
	local chgCharThreshold = g_touchCharInfo.chgCharThreshold
	local currentChar = g_touchCharInfo.currentChar
	local nextCharInfo = g_touchCharInfo.nextCharInfo
	local deltaTime = 0.1
	local delta = math.min(g_touchCharInfo.delta, 1)

	if g_touchCharInfo.delta then
		deltaTime = math.max(0.5 * (1 - delta), 0.1)
	end

	if math.abs(g_touchCharInfo.lastX - g_touchCharInfo.startX) < chgCharThreshold or g_touchCharInfo.guesture == g_touchCharInfo.guestureRestrict then
		local function afterMove()
			g_touchCharInfo.isTouchBegin = false
		end

		if currentChar then
			local tmp_array = CCArray:create()
			local scaleAction = CCScaleTo:create(deltaTime, g_touchCharInfo.nCurrentScale)
			local moveAction = CCMoveTo:create(deltaTime, g_touchCharInfo.startPoint)
			local fadeAction = CCFadeTo:create(deltaTime, 255)

			tmp_array:addObject(scaleAction)
			tmp_array:addObject(moveAction)
			tmp_array:addObject(fadeAction)

			local spawnAction = CCSpawn:create(tmp_array)
			local callback = CCCallFuncN:create(afterMove)

			currentChar:runAction(CCSequence:createWithTwoActions(spawnAction, callback))
		end

		if nextCharInfo then
			local tmp_array = CCArray:create()
			local scaleAction = CCScaleTo:create(deltaTime, nextCharInfo.sScale)
			local moveAction = CCMoveTo:create(deltaTime, nextCharInfo.startPoint)
			local fadeAction = CCFadeTo:create(deltaTime, 0)

			tmp_array:addObject(scaleAction)
			tmp_array:addObject(moveAction)
			tmp_array:addObject(fadeAction)

			local spawnAction = CCSpawn:create(tmp_array)
			local callback = CCCallFuncN:create(afterMove)

			nextCharInfo.character:runAction(CCSequence:createWithTwoActions(spawnAction, callback))
		end
	else
		if currentChar then
			local tmp_array = CCArray:create()
			local scaleAction = CCScaleTo:create(deltaTime, g_touchCharInfo.sCurrentScale)
			local movePoint = nil
			local totalMove = g_touchCharInfo.totalMove

			if g_touchCharInfo.guesture == guestureDef.left then
				movePoint = CCPointMake(g_touchCharInfo.startPoint.x - totalMove.x, g_touchCharInfo.startPoint.y + totalMove.y)
			else
				movePoint = CCPointMake(g_touchCharInfo.startPoint.x + totalMove.x, g_touchCharInfo.startPoint.y + totalMove.y)
			end

			local moveAction = CCMoveTo:create(deltaTime, movePoint)
			local fadeAction = CCFadeTo:create(deltaTime, 0)

			tmp_array:addObject(scaleAction)
			tmp_array:addObject(moveAction)
			tmp_array:addObject(fadeAction)

			local spawnAction = CCSpawn:create(tmp_array)

			currentChar:runAction(spawnAction)
		end

		if nextCharInfo then
			local tmp_array = CCArray:create()
			local scaleAction = CCScaleTo:create(deltaTime, nextCharInfo.nScale)
			local moveAction = CCMoveTo:create(deltaTime, d_ms.d_u.makePoint(0.5, 0.26))
			local fadeAction = CCFadeTo:create(deltaTime, 255)

			tmp_array:addObject(scaleAction)
			tmp_array:addObject(moveAction)
			tmp_array:addObject(fadeAction)
			nextCharInfo.character:runAction(CCSpawn:create(tmp_array))
		end

		local function afterAction()
			if g_touchCharInfo.guesture == guestureDef.left then
				local usedCharactersCount = #g_charPosUI.usedCharacters

				if g_lastShowOrder <= usedCharactersCount then
					tapHeadButton(g_lastShowOrder + 1)
				end
			elseif g_touchCharInfo.guesture == guestureDef.right and g_lastShowOrder > 1 then
				tapHeadButton(g_lastShowOrder - 1)
			end

			if d_ms.d_mainUI.g_isNeedGuide then
				d_ms.d_guideUI.show()
			end
		end

		d_ms.d_u.delay(g_charPosUI.charInfoLayer, deltaTime, afterAction)
	end
end

function onTouchBegan(x, y)
	if g_touchCharInfo.isTouchBegin then
		return false
	end

	if not g_charPosUI.charInfoLayer then
		return false
	end

	local point = g_charPosUI.charInfoLayer:convertToNodeSpace(CCPointMake(x, y))
	local frame = g_touchCharInfo.touchRect

	if not frame:containsPoint(point) then
		return false
	end

	g_touchCharInfo.lastX = x
	g_touchCharInfo.guesture = guestureDef.none
	g_touchCharInfo.startX = x
	g_touchCharInfo.isMoved = false
	g_touchCharInfo.isTouchBegin = true

	return true
end

local function resetCharSprite()
	if g_touchCharInfo.leftCharInfo then
		g_touchCharInfo.leftCharInfo.character:setVisible(false)
		g_touchCharInfo.leftCharInfo.character:setPosition(g_touchCharInfo.leftCharInfo.startPoint)
		g_touchCharInfo.leftCharInfo.character:setScale(g_touchCharInfo.leftCharInfo.sScale)
	end

	if g_touchCharInfo.rightCharInfo then
		g_touchCharInfo.rightCharInfo.character:setVisible(false)
		g_touchCharInfo.rightCharInfo.character:setPosition(g_touchCharInfo.rightCharInfo.startPoint)
		g_touchCharInfo.rightCharInfo.character:setScale(g_touchCharInfo.rightCharInfo.sScale)
	end

	if g_touchCharInfo.currentChar then
		g_touchCharInfo.currentChar:setPosition(g_touchCharInfo.startPoint)
		g_touchCharInfo.currentChar:setScale(g_touchCharInfo.nCurrentScale)
	end
end

function onTouchMoved(x, y)
	local point = g_charPosUI.charInfoLayer:convertToNodeSpace(CCPointMake(x, y))
	local frame = g_touchCharInfo.touchRect
	local isGuideTouch = d_ms.d_guideUI.g_currentGuide == d_ms.d_guideUI.guideState.guideChgChar3 + 1

	if isGuideTouch and d_ms.d_mainUI.g_isNeedGuide then
		return true
	end

	if not frame:containsPoint(point) then
		moveCharEnd()

		return true
	end

	if not g_touchCharInfo.startX then
		return false
	end

	if math.abs(x - g_touchCharInfo.startX) < scrSize.width * 0.02 and not g_touchCharInfo.isMoved then
		g_touchCharInfo.isMoved = false
	else
		local guesture, nextCharInfo = nil

		if g_touchCharInfo.startX < x then
			nextCharInfo = g_touchCharInfo.leftCharInfo
			guesture = guestureDef.right
		elseif x < g_touchCharInfo.startX then
			nextCharInfo = g_touchCharInfo.rightCharInfo
			guesture = guestureDef.left
		else
			guesture = guestureDef.none
		end

		if guesture == guestureDef.none then
			resetCharSprite()
		elseif g_touchCharInfo.guesture and guesture ~= g_touchCharInfo.guesture then
			resetCharSprite()
		end

		g_touchCharInfo.guesture = guesture
		g_touchCharInfo.nextCharInfo = nextCharInfo

		if guesture ~= guestureDef.none then
			local isNeedRestrict = false

			if guesture == g_touchCharInfo.guestureRestrict then
				isNeedRestrict = true
			end

			local _delta = (x - g_touchCharInfo.startX) / g_touchCharInfo.totalMove.x
			_delta = math.min(1, _delta)
			_delta = math.max(-1, _delta)
			local delta = math.abs(_delta)
			g_touchCharInfo.delta = delta
			local moveY = delta * g_touchCharInfo.totalMove.y
			local moveX = _delta * g_touchCharInfo.totalMove.x
			local currentChar = g_touchCharInfo.currentChar

			if currentChar then
				local movedDisX = math.abs(moveX)

				if not isNeedRestrict or g_touchCharInfo.chgCharThreshold > movedDisX then
					local scale = g_touchCharInfo.nCurrentScale - g_touchCharInfo.dCurrentScale * delta

					currentChar:setScale(scale)
					currentChar:setOpacity(255 * (1 - delta))
					currentChar:setPosition(g_touchCharInfo.startPoint.x + moveX, g_touchCharInfo.startPoint.y + moveY)
				end
			end

			if nextCharInfo and nextCharInfo.character then
				local nextChar = nextCharInfo.character

				nextChar:setVisible(true)
				nextChar:setOpacity(255 * delta)

				local nextCharScale = nextCharInfo.sScale + nextCharInfo.dScale * delta

				nextChar:setScale(nextCharScale)
				nextChar:setPosition(nextCharInfo.startPoint.x + moveX, nextCharInfo.startPoint.y - moveY)
			end
		end

		g_touchCharInfo.isMoved = true
	end

	g_touchCharInfo.lastX = x
end

function onTouchEnded(x, y)
	g_touchCharInfo.isTouchBegin = false
	local isGuide = d_ms.d_mainUI.g_isNeedGuide
	local isGuideMove = d_ms.d_guideUI.g_currentGuide == d_ms.d_guideUI.guideState.guideChgChar2 + 1
	local parentLayer = g_charPosUI.charInfoLayer
	local usedCharacters = g_charPosUI.usedCharacters
	local cortege_count = g_charPosUI.cortege_count

	if not g_touchCharInfo.isMoved then
		if isGuide and isGuideMove then
			return
		end

		local bNode = parentLayer:getChildByTag(tagDef.charSprite)

		if bNode and not g_charPosUI.isOtherPage then
			d_ms.d_formationUI.showDetailLayer(g_charPosUI.parent, usedCharacters[g_lastShowOrder], g_charPosUI.isReadOnly)
		end

		return true
	end

	if isGuide and isGuideTouch then
		return true
	end

	moveCharEnd()
end

function onTouchChar(eventType, x, y)
	if eventType == CCTOUCHBEGAN then
		return onTouchBegan(x, y)
	elseif eventType == CCTOUCHMOVED then
		return onTouchMoved(x, y)
	else
		return onTouchEnded(x, y)
	end
end

local function requestTitleInfo()
	local tmp_req = {
		des_id = g_charPosUI.playerInfo.id,
		flag = g_charPosUI.playerInfo.client_flag
	}

	d_ms.d_u.main_server_send_msg(d_ms.d_msg_def.gscl_msg_id.msg_title_op, tmp_req)
end

local function createOtherMainInfoWithoutPet(layer)
	local mx = 0.5
	local my = 0.56
	local w = g_charPosUI.board_bkg_w
	local h = g_charPosUI.board_bkg_h
	local scaleW = g_scaleW
	local characterInfo = g_charPosUI.playerInfo
	local dec = d_ms.d_u.createByStyles({
		pic = "v2/charPositionUI/dec.png",
		x = mx - w * 0.17,
		y = my - h * 0.12
	})

	layer:addChild(dec)

	local head_type = g_charPosUI.playerInfo.head_type
	local body, head = d_ms.d_runeUI.getUserBodySprite(head_type)
	local style = {
		x = mx - 0.17 * w,
		y = my + h * 0.27,
		anchor = {
			0.5,
			1
		},
		scale = w * 0.3
	}

	if head_type < 200 then
		style.y = my + h * 0.22
	end

	head = head or CCSprite:create("v2/namingUI/101.png")

	layer:addChild(d_ms.d_u.setStyles(body, style))
	layer:addChild(d_ms.d_u.setStyles(head, style))

	local down_y = my - h * 0.42
	local scale_ratio = 1.1
	local levelSprite = d_ms.d_u.createByStyles({
		pic = "v2/charPositionUI/level_bkg.png",
		x = mx - w * 0.35,
		y = down_y
	})

	layer:addChild(levelSprite)
	levelSprite:setScale(scaleW * scale_ratio)
	createLevelSprite(characterInfo.level, levelSprite)

	local expBar1 = d_ms.d_u.createByStyles({
		pic = "v2/CharaterUI/expbar1.png",
		x = mx - 0.11 * w,
		y = down_y,
		scale_pic2 = scaleW * scale_ratio
	})

	layer:addChild(expBar1)

	local exp_info = d_ms.d_data.getExpInfo(characterInfo.level)
	local next_exp = characterInfo.cur_exp + tonumber(exp_info.upgrade_exp)
	local expRatio = characterInfo.cur_exp / next_exp
	local expBar2 = d_ms.d_u.createByStyles({
		pic = "v2/CharaterUI/expbar2.png",
		x = mx - 0.11 * w,
		y = down_y,
		scale_pic2 = scaleW * scale_ratio
	})
	local expSize = expBar2:getContentSize()

	expBar2:setTextureRect(CCRectMake(0, 0, expSize.width * expRatio, expSize.height))

	local position = expBar2:getPositionLua()
	local offset = (1 - expRatio) * expSize.width * scaleW * scale_ratio / 2

	expBar2:setPosition(position.x - offset, position.y)
	layer:addChild(expBar2)

	local expNum = characterInfo.cur_exp .. "/" .. next_exp
	local expNumLabel = d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		fontsize = 22,
		string = expNum,
		x = mx - 0.11 * w,
		y = down_y
	})

	layer:addChild(expNumLabel)

	local corner1 = d_ms.d_u.createByStyles({
		pic = "v2/charPositionUI/corner1.png",
		x = mx - w * 0.37,
		y = my + h * 0.24
	})

	layer:addChild(corner1, -1)

	local corner2 = d_ms.d_u.createByStyles({
		pic = "v2/charPositionUI/corner1.png",
		FlipX = true,
		x = mx + w * 0.39,
		y = my + h * 0.24
	})

	layer:addChild(corner2, -1)

	local corner3 = d_ms.d_u.createByStyles({
		pic = "v2/charPositionUI/corner2.png",
		x = mx - w * 0.37,
		y = my - h * 0.44
	})

	layer:addChild(corner3, -1)

	local corner4 = d_ms.d_u.createByStyles({
		pic = "v2/charPositionUI/corner2.png",
		FlipX = true,
		x = mx + w * 0.39,
		y = my - h * 0.44
	})

	layer:addChild(corner4, -1)

	local plate = d_ms.d_u.createByStyles({
		pic = "v2/charPositionUI/plate.png",
		x = mx + w * 0.215,
		y = my - h * 0.12
	})

	layer:addChild(plate)

	mx = mx + w * 0.49
	local title = d_ms.d_u.createByStyles({
		pic = "v2/honorUI/title1.png",
		x = mx - w * 0.312,
		y = my + h * 0.15
	})

	layer:addChild(title)

	local rbkg = d_ms.d_u.createByStyles({
		pic = "v2/charPositionUI/rbkg.png",
		x = mx - w * 0.21,
		y = my + h * 0.15
	})

	layer:addChild(rbkg)

	local realm = characterInfo.reborn_layer or 0
	local rpic = d_ms.d_u.createByStyles({
		pic = "v2/charPositionUI/realm" .. realm .. ".png",
		x = mx - w * 0.215,
		y = my + h * 0.146
	})

	layer:addChild(rpic)

	local r_p = d_ms.d_common_def.role_property
	local wear_id = characterInfo.title_info[r_p.title_id]
	local title_info = d_ms.d_honorUI.g_self.titles[wear_id]

	if title_info then
		local csvInfo = title_info.csvInfo
		local pic = d_ms.d_u.createByStyles({
			pic = "v2/honorUI/title/" .. csvInfo.title_id .. ".png",
			x = mx - w * 0.21,
			y = my - h * 0.1
		})

		layer:addChild(pic)

		local qualityRatio = tonumber(csvInfo.level) / 5
		local starsLevelSprite = d_ms.d_u.createByStyles({
			pic = "v2/CharaterUI/stars.png",
			x = mx - w * 0.18,
			y = my - h * 0.1,
			scale_pic2 = scaleW
		})
		local starsContentSize = starsLevelSprite:getContentSize()

		starsLevelSprite:setTextureRect(CCRectMake(0, 0, starsContentSize.width, starsContentSize.height * qualityRatio))
		layer:addChild(starsLevelSprite)

		if csvInfo.plus_list == "" then
			local tip = d_ms.d_u.createByStyle({
				type = "label",
				fontsize = 26,
				string = gethz("no") .. gethz("honor4"),
				x = mx - 0.305 * w,
				y = my - h * 0.1,
				color = {
					197,
					175,
					162
				}
			})

			layer:addChild(tip)
		else
			local plus_list = d_ms.d_str.split(csvInfo.plus_list, "|")

			for i = 1, 3 do
			end

			local yyy = {
				my - h * 0.13,
				my - h * 0.1,
				my - h * 0.07,
				my - h * 0.04
			}
			local ssy = yyy[#plus_list]
			local tip = d_ms.d_u.createByStyle({
				type = "label",
				fontsize = 26,
				string = gethz("honor4") .. ": ",
				x = mx - 0.305 * w,
				y = ssy + h * 0.08,
				color = {
					197,
					175,
					162
				}
			})

			layer:addChild(tip)

			local sss = {
				"damage",
				"defence",
				"health",
				"mana"
			}

			for i = 1, #plus_list do
				local cy = ssy - (i - 1) * h * 0.08
				local icon = d_ms.d_u.createByStyles({
					pic = "v2/introUI/" .. sss[tonumber(plus_list[i])] .. ".png",
					x = mx - w * 0.335,
					y = cy
				})

				layer:addChild(icon)

				local str = "+" .. csvInfo.plus_value
				local add = d_ms.d_u.createByStyle({
					type = "label",
					fontsize = 26,
					string = str,
					x = mx - w * 0.315,
					y = cy,
					anchor = {
						0,
						0.5
					},
					color = {
						197,
						175,
						162
					}
				})

				layer:addChild(add)
			end
		end
	else
		local pic = d_ms.d_u.createByStyles({
			pic = "v2/honorUI/title/0.png",
			x = mx - w * 0.21,
			y = my - h * 0.1
		})

		layer:addChild(pic)

		local str = {
			gethz("honor9"),
			gethz("honor10")
		}

		d_ms.d_lineupUI.downwardDisplayHZ(layer, str[1], 22, 1, {
			x = mx - w * 0.29,
			y = my + h * 0.04
		}, ccc3(197, 175, 162))

		local dot = d_ms.d_u.createByStyles({
			pic = "v2/CharaterUI/hongdian.png",
			x = mx - w * 0.35,
			y = my + h * 0.01
		})

		d_ms.d_lineupUI.downwardDisplayHZ(layer, str[2], 22, 1, {
			x = mx - w * 0.33,
			y = my + h * 0.04
		}, ccc3(197, 175, 162))
	end
end

local function createOtherMainInfo(layer)
	if not d_ms.d_petUI.pet_is_open then
		createOtherMainInfoWithoutPet(layer)

		return
	end

	local mx = 0.5
	local my = 0.56
	local w = g_charPosUI.board_bkg_w
	local h = g_charPosUI.board_bkg_h
	local scaleW = g_scaleW
	local characterInfo = g_charPosUI.playerInfo
	local head_type = g_charPosUI.playerInfo.head_type
	local body, head = d_ms.d_runeUI.getUserBodySprite(head_type)
	local style = {
		x = mx - 0.05 * w,
		y = my + h * 0.27,
		anchor = {
			0.5,
			1
		},
		scale = w * 0.3
	}

	if head_type < 200 then
		style.y = my + h * 0.22
	end

	layer:addChild(d_ms.d_u.setStyles(body, style))

	if head then
		layer:addChild(d_ms.d_u.setStyles(head, style))
	end

	local down_y = my - h * 0.44
	local scale_ratio = 1.1
	local levelSprite = d_ms.d_u.createByStyles({
		pic = "v2/charPositionUI/level_bkg.png",
		x = mx - w * 0.24,
		y = down_y
	})

	layer:addChild(levelSprite)
	levelSprite:setScale(scaleW * scale_ratio)
	createLevelSprite(characterInfo.level, levelSprite)

	local expBar1 = d_ms.d_u.createByStyles({
		pic = "v2/CharaterUI/expbar1.png",
		x = mx,
		y = down_y,
		scale_pic2 = scaleW * scale_ratio
	})

	layer:addChild(expBar1)

	local exp_info = d_ms.d_data.getExpInfo(characterInfo.level)
	local next_exp = characterInfo.cur_exp + tonumber(exp_info.upgrade_exp)
	local expRatio = characterInfo.cur_exp / next_exp
	local expBar2 = d_ms.d_u.createByStyles({
		pic = "v2/CharaterUI/expbar2.png",
		x = mx,
		y = down_y,
		scale_pic2 = scaleW * scale_ratio
	})
	local expSize = expBar2:getContentSize()

	expBar2:setTextureRect(CCRectMake(0, 0, expSize.width * expRatio, expSize.height))

	local position = expBar2:getPositionLua()
	local offset = (1 - expRatio) * expSize.width * scaleW * scale_ratio / 2

	expBar2:setPosition(position.x - offset, position.y)
	layer:addChild(expBar2)

	local expNum = characterInfo.cur_exp .. "/" .. next_exp
	local expNumLabel = d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		fontsize = 22,
		string = expNum,
		x = mx,
		y = down_y
	})

	layer:addChild(expNumLabel)

	for i, v in pairs(characterInfo.hole_train) do
		local index = i - 615
		local yy = 0.5 + h * 0.25 - (index - 1) * h * 0.18
		local lx = 0.5 - w * 0.35

		layer:addChild(d_ms.d_u.createByStyles({
			scale_pic2 = 0.7,
			pic = "v2/homeUI/attr" .. index .. "1.png",
			x = lx,
			y = yy
		}))
		layer:addChild(d_ms.d_u.createByStyles({
			scale_pic2 = 0.82,
			FlipY = true,
			pic = "v2/wakeUI/icon/q5.png",
			x = lx,
			y = yy
		}), 2)

		local level_label = d_ms.d_u.createByStyle({
			type = "label",
			fontsize = 22,
			string = v,
			x = lx + w * 0.028,
			y = yy - h * 0.06
		})

		layer:addChild(level_label, 2)
	end

	local title = d_ms.d_u.createByStyles({
		pic = "v2/honorUI/title1.png",
		x = mx - w * 0.26,
		y = my + h * 0.15
	})

	layer:addChild(title)

	local rbkg = d_ms.d_u.createByStyles({
		pic = "v2/charPositionUI/rbkg.png",
		x = mx - w * 0.18,
		y = my + h * 0.15
	})

	layer:addChild(rbkg)

	local realm = characterInfo.reborn_layer or 0
	local rpic = d_ms.d_u.createByStyles({
		pic = "v2/charPositionUI/realm" .. realm .. ".png",
		x = mx - w * 0.185,
		y = my + h * 0.146
	})

	layer:addChild(rpic)

	local r_p = d_ms.d_common_def.role_property
	local wear_id = characterInfo.title_info[r_p.title_id]
	local title_info = d_ms.d_honorUI.g_self.titles[wear_id]

	if title_info then
		local csvInfo = title_info.csvInfo

		cclog(csvInfo.title_id)

		local pic = d_ms.d_u.createByStyles({
			pic = "v2/honorUI/title/" .. csvInfo.title_id .. ".png",
			x = mx - w * 0.18,
			y = my - h * 0.1
		})

		layer:addChild(pic)

		local qualityRatio = tonumber(csvInfo.level) / 5
		local starsLevelSprite = d_ms.d_u.createByStyles({
			pic = "v2/CharaterUI/stars.png",
			x = mx - w * 0.15,
			y = my - h * 0.1,
			scale_pic2 = scaleW
		})
		local starsContentSize = starsLevelSprite:getContentSize()

		starsLevelSprite:setTextureRect(CCRectMake(0, 0, starsContentSize.width, starsContentSize.height * qualityRatio))
		layer:addChild(starsLevelSprite)

		if csvInfo.plus_list == "" then
			local tip = d_ms.d_u.createByStyle({
				type = "label",
				fontsize = 26,
				string = gethz("no") .. gethz("honor4"),
				x = mx - 0.26 * w,
				y = my - h * 0.1,
				color = {
					197,
					175,
					162
				}
			})

			layer:addChild(tip)
		else
			local plus_list = d_ms.d_str.split(csvInfo.plus_list, "|")

			for i = 1, 3 do
			end

			local yyy = {
				my - h * 0.13,
				my - h * 0.1,
				my - h * 0.07,
				my - h * 0.04
			}
			local ssy = yyy[#plus_list]
			local tip = d_ms.d_u.createByStyle({
				type = "label",
				fontsize = 26,
				string = gethz("honor4") .. ": ",
				x = mx - 0.245 * w,
				y = ssy + h * 0.08,
				color = {
					197,
					175,
					162
				}
			})

			layer:addChild(tip)

			local sss = {
				"damage",
				"defence",
				"health",
				"mana"
			}

			for i = 1, #plus_list do
				local cy = ssy - (i - 1) * h * 0.08
				local icon = d_ms.d_u.createByStyles({
					pic = "v2/introUI/" .. sss[tonumber(plus_list[i])] .. ".png",
					x = mx - w * 0.275,
					y = cy
				})

				layer:addChild(icon)

				local str = "+" .. csvInfo.plus_value
				local add = d_ms.d_u.createByStyle({
					type = "label",
					fontsize = 26,
					string = str,
					x = mx - w * 0.255,
					y = cy,
					anchor = {
						0,
						0.5
					},
					color = {
						197,
						175,
						162
					}
				})

				layer:addChild(add)
			end
		end
	else
		local pic = d_ms.d_u.createByStyles({
			pic = "v2/honorUI/title/0.png",
			x = mx - w * 0.18,
			y = my - h * 0.1
		})

		layer:addChild(pic)

		local str = {
			gethz("honor9"),
			gethz("honor10")
		}

		d_ms.d_lineupUI.downwardDisplayHZ(layer, str[1], 22, 1, {
			x = mx - w * 0.24,
			y = my + h * 0.04
		}, ccc3(197, 175, 162))

		local dot = d_ms.d_u.createByStyles({
			pic = "v2/CharaterUI/hongdian.png",
			x = mx - w * 0.35,
			y = my + h * 0.01
		})

		d_ms.d_lineupUI.downwardDisplayHZ(layer, str[2], 22, 1, {
			x = mx - w * 0.28,
			y = my + h * 0.04
		}, ccc3(197, 175, 162))
	end

	local pet_info = characterInfo.pet_info

	d_ms.d_data.getPetCSVConfig()

	local pet_type = pet_info.type_id
	local pet_quality = pet_info.quality
	local pet_level = pet_info.level
	local plus_list = pet_info.plus_list
	local pet_star = pet_info.star_level or 0
	local csvInfo = d_ms.d_data.g_pet_base[pet_type]

	if pet_type ~= 0 then
		local pet_body = d_ms.d_petUI.getBodySprite(pet_type)

		layer:addChild(d_ms.d_u.setStyles(pet_body, {
			scale_pic2 = 0.8,
			x = mx + 0.11 * w,
			y = my - h * 0.24
		}))
	end

	local pbkg = d_ms.d_u.createByStyles({
		pic = "v2/charPositionUI/pbkg.png",
		x = mx + w * 0.28,
		y = my - h * 0.1
	})

	layer:addChild(pbkg)

	local pw, ph = d_ms.d_u.getRealScale(pbkg)
	local title = d_ms.d_u.createByStyles({
		pic = "v2/honorUI/title2.png",
		x = pw * 0.5,
		y = ph * 1
	})

	pbkg:addChild(title)

	local nbkg = d_ms.d_petUI.getNameBkgByQuality(pet_quality)

	pbkg:addChild(d_ms.d_u.setStyles(nbkg, {
		x = pw * 0.5,
		y = ph * 0.84
	}))

	local name = d_ms.d_u.createByStyle({
		type = "label",
		fontsize = 26,
		string = csvInfo and csvInfo.name or gethz("noResult"),
		x = pw * 0.5,
		y = ph * 0.84
	})

	pbkg:addChild(name)

	local llabel = d_ms.d_u.createByStyle({
		type = "label",
		fontsize = 24,
		string = "LV." .. pet_level,
		x = pw * 0.5,
		y = ph * 0.72
	})

	pbkg:addChild(llabel)

	if pet_type ~= 0 then
		local next_level_exp = d_ms.d_data.g_pet_expNeed[csvInfo.main_type][pet_level]

		if not pet_info.cur_exp then
			pet_info.cur_exp = math.random(0, next_level_exp)
		end

		pbkg:addChild(d_ms.d_u.createByStyle({
			pic = "v2/petUI/exp1.png",
			x = pw * 0.5,
			y = ph * 0.64
		}))

		local expBar = CCSprite:create("v2/petUI/exp2.png")
		local ssz = expBar:getContentSize()
		local percent = pet_info.cur_exp / next_level_exp

		if percent > 1 then
			percent = 1
		end

		expBar:setTextureRect(CCRectMake(0, 0, percent * ssz.width, ssz.height))
		d_ms.d_u.setStyles(expBar, {
			x = pw * 0.5,
			y = ph * 0.64,
			anchor = {
				0.5 / percent,
				0.5
			}
		})
		pbkg:addChild(expBar)
	else
		pbkg:addChild(d_ms.d_u.createByStyle({
			pic = "v2/petUI/exp1.png",
			x = pw * 0.5,
			y = ph * 0.64
		}))
	end

	local sx = pw * 0.1
	local sy = ph * 0.55
	local MAX_STAR = 9

	for i = 1, MAX_STAR do
		local pic = "v2/petUI/star" .. math.ceil(i / 3) .. ".png"
		local scale_coe = 0.07 * pw

		if pet_star < i then
			pic = "v2/equipAdvanceUI/star_emp.png"
			scale_coe = 0.062 * pw
		end

		pbkg:addChild(d_ms.d_u.createByStyle({
			pic = pic,
			x = sx + pw * 0.09 * (i - 1),
			y = sy,
			anchor = {
				0,
				0.5
			},
			scale = scale_coe
		}))
	end

	if pet_type ~= 0 then
		for i, v in pairs(plus_list) do
			local attrStr = string.format(gethz("pet_test3"), gethz("pet_direction" .. i), gethz("asc_attr" .. v.plus_field))
			local cx = 0.1 * pw
			local cy = ph * 0.44 - (i - 1) * pw * 0.212

			pbkg:addChild(d_ms.d_u.createByStyle({
				pic = "v2/petUI/attr_bkg5.png",
				x = cx,
				y = cy,
				anchor = {
					0,
					0.5
				}
			}))
			pbkg:addChild(d_ms.d_u.createByStyle({
				type = "label",
				fontsize = 22,
				string = attrStr,
				x = cx + 0.055 * w,
				y = cy
			}))
			pbkg:addChild(d_ms.d_u.createByStyle({
				type = "label",
				fontsize = 22,
				string = v.plus_value,
				x = cx + 0.16 * w,
				y = cy
			}))
		end
	else
		for i = 1, 4 do
			local attrStr = string.format(gethz("pet_test3"), gethz("pet_direction" .. i), gethz("asc_attr" .. i))
			local cx = 0.1 * pw
			local cy = ph * 0.44 - (i - 1) * pw * 0.212

			pbkg:addChild(d_ms.d_u.createByStyle({
				pic = "v2/petUI/attr_bkg5.png",
				x = cx,
				y = cy,
				anchor = {
					0,
					0.5
				}
			}))
			pbkg:addChild(d_ms.d_u.createByStyle({
				type = "label",
				fontsize = 22,
				string = attrStr,
				x = cx + 0.055 * w,
				y = cy
			}))
		end
	end
end

function createCharInfo(tag, parentLayer)
	if tag == 100 then
		createOtherMainInfo(parentLayer)
	end

	g_currentCharFate = nil
	local scaleW = g_scaleW
	local ground = CCSprite:create("v2/CharaterUI/xiaguang.png")

	d_ms.d_u.setStyles(ground, {
		x = 0.5,
		y = 0.4
	})
	ground:setScale(scaleW)
	ground:setTag(tagDef.groundLight)
	parentLayer:addChild(ground, -10)

	if not g_charPosUI.isReadOnly and not g_charPosUI.usedCharacters[tag] then
		local enterInMenuItem = CCMenuItemImage:create("v2/charPositionUI/touch_enter.png", "v2/charPositionUI/touch_enter.png")

		enterInMenuItem:registerScriptTapHandler(showChgCharLayer)
		d_ms.d_u.setStyles(enterInMenuItem, {
			x = 0.5,
			y = 0.5
		})

		g_enterInMenuItem = enterInMenuItem

		enterInMenuItem:setTag(tagDef.enterInMenu)

		local enterInMenu = CCMenu:createWithItem(enterInMenuItem)

		enterInMenu:setPosition(0, 0)
		parentLayer:addChild(enterInMenu)
	end

	g_touchCharInfo = {
		touchRect = CCRectMake(0.25 * scrSize.width, 0.26 * scrSize.height, 0.5 * scrSize.width, 0.5 * scrSize.height),
		totalMove = d_ms.d_u.makePoint(0.2, 0.2),
		chgCharThreshold = 0.08 * scrSize.width,
		isTouchBegin = false
	}
	local usedCharacters = g_charPosUI.usedCharacters
	local cortege_count = g_charPosUI.cortege_count
	local usedCharactersCount = #usedCharacters
	local isExtraSpot = cortege_count > usedCharactersCount

	if tag == usedCharactersCount and not isExtraSpot then
		g_touchCharInfo.guestureRestrict = guestureDef.left
	end

	if tag == 1 then
		g_touchCharInfo.guestureRestrict = guestureDef.right
	end

	local rightCharacterInfo = usedCharacters[tag + 1]

	if rightCharacterInfo then
		local rightCharInfo = {}
		local rightChar = d_ms.d_data.getBodySprite(rightCharacterInfo.character.type, rightCharacterInfo.character.reborn_layer > 0)

		rightChar:setVisible(false)
		rightChar:setAnchorPoint(CCPointMake(0.5, 0))
		d_ms.d_u.setStyles(rightChar, {
			scaleH = 0.2,
			x = 0.7,
			y = 0.46
		})
		parentLayer:addChild(rightChar, -1)

		rightCharInfo.character = rightChar
		rightCharInfo.nScale = 0.5 * scrSize.height / rightChar:getContentSize().height
		rightCharInfo.sScale = rightChar:getScale()
		rightCharInfo.dScale = rightCharInfo.nScale - rightCharInfo.sScale
		rightCharInfo.startPoint = rightChar:getPositionLua()
		g_touchCharInfo.rightCharInfo = rightCharInfo
	end

	local leftCharacterInfo = g_charPosUI.usedCharacters[tag - 1]

	if leftCharacterInfo then
		local leftCharInfo = {}
		local leftChar = d_ms.d_data.getBodySprite(leftCharacterInfo.character.type, leftCharacterInfo.character.reborn_layer > 0)

		leftChar:setVisible(false)
		leftChar:setAnchorPoint(CCPointMake(0.5, 0))
		d_ms.d_u.setStyles(leftChar, {
			scaleH = 0.2,
			x = 0.3,
			y = 0.46
		})
		parentLayer:addChild(leftChar, -1)

		leftCharInfo.character = leftChar
		leftCharInfo.nScale = 0.5 * scrSize.height / leftChar:getContentSize().height
		leftCharInfo.sScale = leftChar:getScale()
		leftCharInfo.startPoint = leftChar:getPositionLua()
		leftCharInfo.dScale = leftCharInfo.nScale - leftCharInfo.sScale
		g_touchCharInfo.leftCharInfo = leftCharInfo
	end

	if not usedCharacters[tag] then
		return
	end

	local characterInfo = g_charPosUI.usedCharacters[tag].character
	characterInfo.ext_star_list = d_ms.d_checkLineupUI.displayLineupInfo.ext_star_list and d_ms.d_checkLineupUI.displayLineupInfo.ext_star_list[tag]
	g_charPosUI.current_characterInfo = characterInfo
	local usedItems = g_charPosUI.allUsedItems[tag]
	local characterSprite = d_ms.d_data.getBodySprite(characterInfo.type, characterInfo.reborn_layer > 0)

	characterSprite:setAnchorPoint(CCPointMake(0.5, 0))
	characterSprite:setTag(tagDef.charSprite)
	parentLayer:addChild(characterSprite, -1)

	local characterSize = characterSprite:getContentSize()

	d_ms.d_u.setStyles(characterSprite, {
		scaleH = 0.5,
		x = 0.5,
		y = 0.26
	})

	g_touchCharInfo.currentChar = characterSprite
	g_touchCharInfo.nCurrentScale = characterSprite:getScale()
	g_touchCharInfo.sCurrentScale = 0.2 * scrSize.height / characterSize.height
	g_touchCharInfo.dCurrentScale = g_touchCharInfo.nCurrentScale - g_touchCharInfo.sCurrentScale
	g_touchCharInfo.startPoint = characterSprite:getPositionLua()
	local charType = characterInfo.csvInfo.category
	local characterTypeSprite = CCSprite:create("v2/charPositionUI/type_" .. charType .. ".png")

	parentLayer:addChild(characterTypeSprite)
	characterTypeSprite:setScale(scaleW)
	d_ms.d_u.setStyles(characterTypeSprite, {
		x = 0.27,
		y = 0.68
	})

	local charSpriteSize = characterTypeSprite:getContentSize()
	local combat = characterInfo.combat_power or 0
	local combat_pos = {
		y = 0.76,
		x = 0.27 - 0.5 * charSpriteSize.width / scrSize.width
	}

	d_ms.d_playerInfoUI.showCortegeCombatLayer(parentLayer, combat_pos, combat)

	if not g_charPosUI.isReadOnly then
		local lastCombat = g_lastCombat[tag]
		local plus = nil

		if lastCombat and lastCombat < combat then
			plus = d_ms.d_u.createByStyle({
				font = "arial",
				type = "label",
				y = 0.76,
				fontsize = 30,
				string = "+" .. combat - lastCombat,
				color = {
					178,
					255,
					63
				},
				anchor = {
					0,
					1
				},
				x = combat_pos.x + 0.16
			})
		elseif lastCombat and combat < lastCombat then
			plus = d_ms.d_u.createByStyle({
				font = "arial",
				type = "label",
				y = 0.76,
				fontsize = 30,
				string = "-" .. lastCombat - combat,
				color = {
					241,
					67,
					21
				},
				anchor = {
					0,
					1
				},
				x = combat_pos.x + 0.16
			})
		end

		if plus then
			parentLayer:addChild(plus, 10)

			local myActions = CCArray:create()

			myActions:addObject(CCDelayTime:create(0.4))
			myActions:addObject(CCMoveBy:create(1, d_ms.d_u.makePoint(0, 0.03)))
			myActions:addObject(CCCallFuncN:create(d_ms.d_u.remove))
			plus:runAction(CCSequence:create(myActions))
		end

		updateCombatList()
	end

	local characterNameSprite = d_ms.d_data.getNameSprite(characterInfo.type, characterInfo.reborn_layer > 0)

	parentLayer:addChild(characterNameSprite)
	characterNameSprite:setScale(scaleW * 2)

	local centerPoint = 0.46

	d_ms.d_u.setStyles(characterNameSprite, {
		x = 0.27,
		y = centerPoint
	})

	local qualityRatio = characterInfo.csvInfo.quality / 5
	local starsLevelSprite = CCSprite:create("v2/CharaterUI/stars.png")

	d_ms.d_u.setStyles(starsLevelSprite, {
		x = 0.305,
		y = centerPoint
	})

	local starsContentSize = starsLevelSprite:getContentSize()

	starsLevelSprite:setTextureRect(CCRectMake(0, 0, starsContentSize.width, starsContentSize.height * qualityRatio))
	parentLayer:addChild(starsLevelSprite)
	starsLevelSprite:setScale(scaleW)

	local yuanfenSprite = CCSprite:create("v2/introUI/yuanfen_label.png")

	d_ms.d_u.setStyles(yuanfenSprite, {
		x = 0.71,
		y = 0.7
	})
	parentLayer:addChild(yuanfenSprite)
	yuanfenSprite:setScale(scaleW)

	local fate_table = nil
	local fateAttrTable = d_ms.d_lineupUI.g_fateAttrTable

	if fateAttrTable.character ~= nil then
		local type = characterInfo.type

		if fateAttrTable.character[type] ~= nil then
			fate_table = fateAttrTable.character[type]
		end
	end

	local info_level = 0

	if g_charPosUI.isReadOnly then
		info_level = g_charPosUI.playerInfo.level
	else
		info_level = d_ms.d_mainUI.g_playerInfo.level
	end

	if info_level >= 38 then
		local jp_data = {}

		if characterInfo.id then
			jp_data = d_ms.d_jpmkUI.getJP(characterInfo.id)
		elseif d_ms.d_checkLineupUI.displayLineupInfo.ext_skill_list[tag] then
			for i = 1, #d_ms.d_checkLineupUI.displayLineupInfo.ext_skill_list[tag] do
				local file_num = d_ms.d_data.getFileIdByExtSkillType(d_ms.d_checkLineupUI.displayLineupInfo.ext_skill_list[tag][i].type_id)
				local tmp_t = {
					csvInfo = {
						file = file_num
					}
				}

				table.insert(jp_data, tmp_t)
			end
		end

		local jp_sprite_bkg = d_ms.d_u.createByStyles({
			pic = "v2/jpmkUI/bkg3.png",
			x = 0.5,
			y = 0.26,
			anchor = {
				0.5,
				0
			}
		})
		local w_jp, h_jp = d_ms.d_u.getRealScale(jp_sprite_bkg)

		parentLayer:addChild(jp_sprite_bkg, 10)

		local total_count = (characterInfo.equiped_ext_skill_limit or 0) + (characterInfo.fate_rebullding_jp_slots or 0)

		for i = 1, 5 do
			if jp_data[i] then
				local jp_sprite = d_ms.d_u.createByStyles({
					pic = "skill/ext/" .. jp_data[i].csvInfo.file .. ".png",
					x = 0.495 - w_jp * 0.44 + (i - 1) * w_jp * 0.185,
					y = 0.26 + h_jp * 0.1,
					scale = w_jp * 0.18,
					anchor = {
						0,
						0
					}
				})

				parentLayer:addChild(jp_sprite, 11)
			else
				local not_set_pic = "v2/jpmkUI/jp_no_open2.png"

				if i <= total_count and info_level >= 38 then
					not_set_pic = "v2/jpmkUI/jp_bkg.png"
				end

				local jp_sprite = d_ms.d_u.createByStyles({
					pic = not_set_pic,
					x = 0.495 - w_jp * 0.44 + (i - 1) * w_jp * 0.185,
					y = 0.26 + h_jp * 0.1,
					scale = w_jp * 0.18,
					anchor = {
						0,
						0
					}
				})

				parentLayer:addChild(jp_sprite, 11)
			end
		end
	end

	if fate_table ~= nil then
		local positionX = 0.73
		local positionY = 0.62

		for i = 1, #fate_table do
			local color = ccc3(112, 112, 112)

			if not fate_table[i].targetListTable then
				local fateItemList = d_ms.d_lineupUI.parseFateTargetStr(fate_table[i].targetList)
				fate_table[i].targetListTable = fateItemList
			end

			currentFataTable = fate_table[i].targetListTable
			local fateStr = "/" .. fate_table[i].targetList .. "/"

			if fate_table[i].targetType == 5 or fate_table[i].targetType == 6 then
				local count = 0

				for i = 1, #usedItems do
					local mode = "/" .. usedItems[i].item.type_id .. "/"

					if string.find(fateStr, mode) then
						count = count + 1
					end

					if count == #currentFataTable then
						color = ccc3(255, 255, 255)

						break
					end
				end
			else
				local count = 0
				local fateRelated = {
					usedCharacters,
					g_charPosUI.cheerCharacters
				}
				local isActivated = false

				for _, list in pairs(fateRelated) do
					for _, v in pairs(list) do
						local mode = "/" .. v.character.type .. "/"

						if string.find(fateStr, mode) then
							count = count + 1
						end

						if count == #currentFataTable then
							isActivated = true

							break
						end
					end

					if isActivated then
						color = ccc3(255, 255, 255)

						break
					end
				end
			end

			d_ms.d_lineupUI.downwardDisplayHZ(parentLayer, fate_table[i].description, 20, 0.2, {
				x = positionX,
				y = positionY
			}, color)

			local hintPointSprite1 = CCSprite:create("v2/CharaterUI/hongdian.png")

			d_ms.d_u.setStyles(hintPointSprite1, {
				scale = 0.005,
				x = positionX,
				y = positionY + 0.02
			})
			parentLayer:addChild(hintPointSprite1)

			positionX = positionX - 0.02

			if i == 3 then
				positionX = 0.73
				positionY = 0.4
			end
		end
	end

	g_currentCharFate = fate_table

	if characterInfo.evolve_level and characterInfo.evolve_level > 0 then
		d_ms.d_data.addFSccbi(characterSprite, characterInfo.evolve_level)

		local node = getEvolveNums(characterInfo.evolve_level)

		d_ms.d_u.setStyles(node, {
			x = 0.614,
			y = 0.7
		})
		parentLayer:addChild(node, 10)
	end

	if characterInfo.reborn_layer and characterInfo.reborn_layer > 0 then
		parentLayer:addChild(d_ms.d_u.createByStyle({
			pic = "v2/ascUI/0.png",
			x = 0.32,
			y = 0.68
		}), 10)

		local rebornSp = CCSprite:create("v2/ascUI/" .. characterInfo.reborn_layer .. ".png")

		if rebornSp then
			d_ms.d_u.setStyles(rebornSp, {
				x = 0.32,
				y = 0.68
			})
			parentLayer:addChild(rebornSp, 11)
		end
	end

	local levelSprite = CCSprite:create("v2/charPositionUI/level_bkg.png")

	d_ms.d_u.setStyles(levelSprite, {
		x = 0.28,
		y = 0.18
	})
	parentLayer:addChild(levelSprite)
	levelSprite:setScale(scaleW)
	createLevelSprite(characterInfo.level, levelSprite)

	local stats = {
		health = characterInfo.hp,
		damage = characterInfo.gongji,
		defence = characterInfo.fangyu,
		mana = characterInfo.magic
	}
	local statsBkg, statsTable = d_ms.d_trainingUI.createCharaterStatsBar(stats, scaleW)

	d_ms.d_u.setStyles(statsBkg, {
		x = 0.5,
		y = 0.23
	})
	parentLayer:addChild(statsBkg)

	g_statsTable = statsTable
	local expBar1 = CCSprite:create("v2/CharaterUI/expbar1.png")

	d_ms.d_u.setStyles(expBar1, {
		x = 0.5,
		y = 0.18
	})
	parentLayer:addChild(expBar1)
	expBar1:setScale(scaleW)

	if characterInfo.cur_exp < 0 then
		characterInfo.cur_exp = characterInfo.next_exp
	end

	local expRatio = characterInfo.cur_exp / characterInfo.next_exp
	expRatio = math.max(0, expRatio)
	expRatio = math.min(1, expRatio)
	local expBar2 = CCSprite:create("v2/CharaterUI/expbar2.png")

	d_ms.d_u.setStyles(expBar2, {
		x = 0.5,
		y = 0.18
	})

	local expSize = expBar2:getContentSize()

	expBar2:setTextureRect(CCRectMake(0, 0, expSize.width * expRatio, expSize.height))

	local position = expBar2:getPositionLua()
	local offset = (1 - expRatio) * expSize.width * scaleW / 2

	expBar2:setPosition(position.x - offset, position.y)
	expBar2:setScale(scaleW)
	parentLayer:addChild(expBar2)

	if not g_charPosUI.isReadOnly then
		local expNum = characterInfo.cur_exp .. "/" .. characterInfo.next_exp
		local expNumLabel = d_ms.d_u.createByStyle({
			y = 0.18,
			font = "arial",
			type = "label",
			x = 0.5,
			fontsize = 16,
			string = expNum
		})

		parentLayer:addChild(expNumLabel)
	end

	g_itemsSprite = {
		[o_t.skill] = {},
		[o_t.item] = {}
	}
	local talent_skill = nil

	for i = 1, #usedItems do
		local theItem = usedItems[i].item
		local isAsc = theItem.reborn_bit and theItem.reborn_bit > 0
		local itemSprite = d_ms.d_data.getCertainSmallSprite(theItem.attach_type, theItem.type_id, theItem.level, isAsc, theItem.star_level)

		parentLayer:addChild(itemSprite, 10)

		g_itemsSprite[theItem.attach_type][theItem.equip_pos] = itemSprite
		local nameBkg = CCSprite:create("v2/charPositionUI/char_name_bkg.png")
		local nameStr = d_ms.d_data.getNameByTypeId(theItem.attach_type, theItem.type_id, isAsc)
		local name_color = {
			255,
			255,
			255
		}

		if d_ms.d_wakeUI.isAwaken(theItem.awaken) then
			name_color = {
				255,
				255,
				0
			}
			local ww, hh = d_ms.d_u.getRealScale(itemSprite)
			local ccbi = d_ms.d_u.createLoopAnimation("feisheng3f.ccbi")

			ccbi:setScale(0.4)
			itemSprite:addChild(d_ms.d_u.setStyles(ccbi, {
				x = 0.5 * ww,
				y = 0.5 * hh
			}), 10)
		end

		local nameLabel = d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			fontsize = 22,
			string = nameStr,
			color = name_color
		})
		local equip_pos = theItem.equip_pos

		if theItem.attach_type == o_t.skill then
			d_ms.d_u.setStyles(itemSprite, {
				scale = 0.09,
				x = 0.19,
				y = 0.89 - equip_pos * 0.2
			})
		elseif theItem.attach_type == o_t.item then
			d_ms.d_u.setStyles(itemSprite, {
				scale = 0.09,
				x = 0.8,
				y = 0.89 - equip_pos * 0.2
			})
		end

		local levelLabel = d_ms.d_u.createByStyle({
			font = "arial",
			fontsize = 22,
			type = "label",
			string = theItem.level
		})

		itemSprite:addChild(levelLabel)

		local size = itemSprite:getContentSize()
		local itemPos = itemSprite:getPositionLua()

		levelLabel:setTag(tagDef.itemLevel)
		levelLabel:setAnchorPoint(CCPointMake(0, 0.5))
		levelLabel:setPosition(0.1 * size.width, 0.8 * size.height)

		if theItem.attach_type == o_t.item then
			local advanceLabel = nil

			if theItem.cast_level and theItem.cast_level > 0 then
				advanceLabel = CCSprite:create("v2/ascCast/cast_" .. theItem.cast_level .. ".png")
			elseif theItem.advance_level and theItem.advance_level > 0 then
				advanceLabel = CCSprite:create("v2/equipAdvanceUI/ad" .. theItem.advance_level .. ".png")
			end

			if advanceLabel then
				if theItem.star_level ~= 1 then
					itemSprite:addChild(advanceLabel)
					advanceLabel:setAnchorPoint(CCPointMake(1, 0))
					advanceLabel:setPosition(0.93 * size.width, 0.07 * size.height)
				end

				d_ms.d_data.addAdvanceCcbi(itemSprite, theItem.advance_level)
			end
		end

		nameBkg:setPosition(itemPos.x, itemPos.y - 70)
		nameLabel:setPosition(itemPos.x, itemPos.y - 70)

		if theItem.attach_type == o_t.skill then
			if theItem.equip_pos == 1 and theItem.protogenic == 1 then
				talent_skill = theItem
			end

			if theItem.upgrade_level and theItem.upgrade_level > 0 then
				local size = itemSprite:getContentSize()
				local advanceLabel = CCSprite:create("v2/enhanceUI/wu.png")

				itemSprite:addChild(advanceLabel)
				advanceLabel:setAnchorPoint(ccp(1, 0))
				advanceLabel:setPosition(0.95 * size.width, 0.05 * size.height)
			end
		end

		parentLayer:addChild(nameBkg, 10)
		parentLayer:addChild(nameLabel, 10)
	end

	for i = 1, 6 do
		local itemMenu = CCMenuItemImage:create("v2/charPositionUI/square_bkg.png", "v2/charPositionUI/square_bkg.png")

		itemMenu:registerScriptTapHandler(touchCharacterItem)

		local introSprite = nil

		if d_ms.d_mainUI.g_isNeedGuide and g_guideChangeItem == nil then
			g_guideChangeItem = itemMenu
		end

		if i > 3 then
			d_ms.d_u.setStyles(itemMenu, {
				x = 0.19,
				y = 0.89 - (i - 3) * 0.2
			})

			introSprite = CCSprite:create("v2/charPositionUI/skillHZ.png")
		else
			d_ms.d_u.setStyles(itemMenu, {
				x = 0.8,
				y = 0.89 - i * 0.2
			})

			introSprite = CCSprite:create("v2/charPositionUI/itemHZ_" .. i .. ".png")
		end

		itemMenu:setTag(i)

		if i == 1 then
			g_guideChangeItem = itemMenu
		end

		local menu = CCMenu:createWithItem(itemMenu)

		menu:setPosition(CCPointMake(0, 0))
		parentLayer:addChild(menu)

		local menuPos = itemMenu:getPositionLua()
		local frame = CCSprite:create("v2/charPositionUI/frame1.png")

		frame:setPosition(menuPos)
		introSprite:setPosition(menuPos)
		parentLayer:addChild(frame, 5)
		parentLayer:addChild(introSprite)
	end

	parentLayer:registerScriptTouchHandler(onTouchChar, false, -128, false)
	parentLayer:setTouchEnabled(true)

	local role = nil

	if g_charPosUI.isReadOnly then
		role = g_charPosUI.playerInfo
	else
		role = d_ms.d_mainUI.g_playerInfo
	end

	local cheer_position = role and d_ms.d_cheerSquadUI.getBackUpIndex(role, characterInfo.order)

	if cheer_position then
		local function gotoCheer()
			gotoCheerSquadUI(cheer_position)
		end

		local pic = "v2/cheerUI/" .. cheer_position .. "4.png"
		local sprite1 = CCSprite:create(pic)
		local sprite2 = CCSprite:create(pic)

		sprite2:setColor(ccc3(100, 100, 100))

		local cheerMenuItem = CCMenuItemSprite:create(sprite1, sprite2)

		cheerMenuItem:registerScriptTapHandler(gotoCheer)
		d_ms.d_u.setStyles(cheerMenuItem, {
			x = 0.292,
			scale = 0.07,
			y = 0.27,
			anchor = {
				0,
				0
			}
		})

		local menu = CCMenu:createWithItem(cheerMenuItem)

		menu:setPosition(CCPointMake(0, 0))
		parentLayer:addChild(menu, 10)
	end

	if d_ms.d_equipAscUI.g_is_open and (g_charPosUI.isReadOnly and g_charPosUI.playerInfo.level >= 70 or not g_charPosUI.isReadOnly and d_ms.d_mainUI.g_playerInfo.level >= 70) then
		local hasTier = d_ms.d_equipAscUI.getCortTierInfo(usedItems, false)
		local castInfo = d_ms.d_equipCastUI.getCortCastInfo(usedItems)
		local tierMenuItem = nil

		if hasTier or castInfo.cur.name then
			tierMenuItem = CCMenuItemImage:create("v2/ascCast/tier1.png", "v2/ascCast/tier2.png")
		else
			tierMenuItem = CCMenuItemImage:create("v2/ascCast/tier3.png", "v2/ascCast/tier2.png")
		end

		tierMenuItem:registerScriptTapHandler(showTier)
		d_ms.d_u.setStyles(tierMenuItem, {
			x = 0.67,
			y = 0.27,
			anchor = {
				1,
				0
			}
		})

		local menu = CCMenu:createWithItem(tierMenuItem)

		menu:setPosition(CCPointMake(0, 0))
		parentLayer:addChild(menu, 10)
	end

	if not g_charPosUI.isReadOnly and d_ms.d_wakeUI.canWake(characterInfo, talent_skill) and d_ms.d_mainUI.hasWakeGuide(true) then
		local layer = CCLayer:create()

		d_ms.d_guideUI.showHintArrow(layer, d_ms.d_u.makePoint(0.32, 0.69), d_ms.d_guideUI.HintDir.left)

		local frame = d_ms.d_u.createByStyles({
			pic = "v2/guideUI/hint.png",
			scale = 0.11,
			x = 0.19,
			y = 0.69
		})

		layer:addChild(frame)
		parentLayer:addChild(layer, 11, tagDef.wake_guide)
	end

	if g_lastItemIntro then
		local isFind = false

		for i = 1, #usedItems do
			if usedItems[i].item.equip_pos == g_lastItemIntro.equip_pos and usedItems[i].item.attach_type == g_lastItemIntro.attach_type then
				showItemIntro(usedItems[i].item, true)

				isFind = true

				break
			end
		end

		if not isFind then
			g_lastItemIntro = nil
		end
	end
end

function getEvolveNums(level)
	local level = level or 0
	level = math.min(level, 999)
	local parent = CCNode:create()
	local bkg = d_ms.d_u.createByStyle({
		pic = "v2/feishengUI/seal.png",
		x = 0,
		y = 0
	})

	parent:addChild(bkg)

	local sprites = {}

	if level <= 10 then
		parent:addChild(d_ms.d_u.createByStyle({
			pic = "v2/feishengUI/" .. level .. ".png"
		}))
	elseif level < 20 then
		parent:addChild(d_ms.d_u.createByStyle({
			scale_pic2 = 0.8,
			pic = "v2/feishengUI/10.png",
			anchor = {
				0.8,
				0.5
			}
		}))
		parent:addChild(d_ms.d_u.createByStyle({
			scale_pic2 = 0.8,
			pic = "v2/feishengUI/" .. level % 10 .. ".png",
			anchor = {
				0.2,
				0.5
			}
		}))
	elseif level < 100 then
		local first = math.floor(level / 10)
		local second = level % 10

		parent:addChild(d_ms.d_u.createByStyle({
			scale_pic2 = 0.8,
			pic = "v2/feishengUI/" .. (first < 2 and 10 or first) .. ".png",
			anchor = {
				0.8,
				0.5
			}
		}))
		parent:addChild(d_ms.d_u.createByStyle({
			scale_pic2 = 0.8,
			pic = "v2/feishengUI/" .. level % 10 .. ".png",
			anchor = {
				0.2,
				0.5
			}
		}))
	else
		local num1 = math.floor(level / 100)
		local num2 = math.floor((level - num1 * 100) / 10)
		local num3 = level % 10

		parent:addChild(d_ms.d_u.createByStyle({
			scale_pic2 = 0.8,
			pic = "v2/feishengUI/" .. num1 .. ".png",
			anchor = {
				1,
				0.5
			}
		}))
		parent:addChild(d_ms.d_u.createByStyle({
			scale_pic2 = 0.8,
			pic = "v2/feishengUI/" .. num2 .. ".png"
		}))
		parent:addChild(d_ms.d_u.createByStyle({
			scale_pic2 = 0.8,
			pic = "v2/feishengUI/" .. num3 .. ".png",
			anchor = {
				0,
				0.5
			}
		}))
		d_ms.d_u.setStyles(bkg, {
			scaleX = 0.1
		})
	end

	return parent
end

function showTier()
	if not g_charPosUI.charInfoLayer or not g_lastShowOrder or not g_charPosUI.allUsedItems[g_lastShowOrder] then
		return
	end

	local layer = d_ms.d_u.clearLayer(g_charPosUI.charInfoLayer, 11, tagDef.Tier)
	local mx = 0.67
	local my = 0.36
	local bkg = d_ms.d_u.createByStyle({
		pic = "v2/ascCast/bkg4.png",
		anchor = {
			1,
			0
		},
		x = mx,
		y = my
	})

	layer:addChild(bkg)

	local w, h = d_ms.d_u.getRealScale(bkg)

	local function dismiss()
		d_ms.d_u.remove(layer)

		return true
	end

	local params = {
		outFunc = dismiss,
		rect = d_ms.d_u.getRealRect(bkg)
	}

	d_ms.d_u.createSwallowTouchLayerFunc(layer, params)

	local colors = {
		{
			216,
			167,
			48
		},
		{
			255,
			200,
			100
		},
		{
			150,
			150,
			150
		}
	}
	local usedItems = g_charPosUI.allUsedItems[g_lastShowOrder]
	local hasTier, tierInfo = d_ms.d_equipAscUI.getCortTierInfo(usedItems, true)
	local tierName = nil

	if tierInfo then
		tierName = d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			fontsize = 26,
			string = tierInfo.name,
			color = colors[2]
		})

		layer:addChild(tierName, 1)
		layer:addChild(d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			fontsize = 22,
			string = tierInfo.equipStr,
			color = colors[1],
			x = mx - 0.5 * w,
			y = my + 0.7 * h
		}), 1)
		layer:addChild(d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			fontsize = 22,
			string = tierInfo.descStr,
			color = colors[1],
			x = mx - 0.5 * w,
			y = my + 0.62 * h
		}), 1)
	else
		tierName = d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			fontsize = 26,
			string = gethz("no"),
			color = colors[2]
		})

		layer:addChild(tierName, 1)
	end

	layer:addChild(d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		fontsize = 22,
		string = gethz("cast17"),
		color = colors[3],
		x = mx - 0.5 * w,
		y = my + 0.53 * h
	}), 1)

	if d_ms.d_loginUI.g_currentSence == d_ms.d_loginUI.senceID.mainUI and not g_charPosUI.isReadOnly then
		d_ms.d_u.setStyles(tierName, {
			x = mx - 0.75 * w,
			y = my + 0.81 * h
		})

		local menu_btn_list = {
			{
				npic = "v2/ascCast/hand1.png",
				spic = "v2/ascCast/hand2.png",
				tag = 8,
				x = mx - 0.25 * w,
				y = my + h * 0.81,
				call_back = d_ms.d_packageUI.pressHandBook
			},
			x = 0,
			y = 0
		}

		layer:addChild(d_ms.d_u.createMenu(menu_btn_list), 1)
	else
		d_ms.d_u.setStyles(tierName, {
			x = mx - 0.5 * w,
			y = my + 0.79 * h
		})
	end

	local castInfo = d_ms.d_equipCastUI.getCortCastInfo(usedItems)

	for i = 1, 6 do
		if usedItems[i] ~= nil then
			cclog(usedItems[i].item.type_id)
		end
	end

	local fuckflag = 0

	for i = 1, 6 do
		if usedItems[i] ~= nil and usedItems[i].item.star_level ~= nil then
			fuckflag = fuckflag + usedItems[i].item.star_level
		end
	end

	if fuckflag == 3 then
		fuckflag = true
	else
		fuckflag = false
	end

	local cy = my + 0.34 * h
	local dy = 0.07 * h

	layer:addChild(d_ms.d_u.createByStyle({
		type = "label",
		font = "arial",
		fontsize = 22,
		x = mx - 0.95 * w,
		y = cy,
		anchor = {
			0,
			0.5
		},
		string = d_ms.d_hz.gethz("cast10"),
		color = colors[1]
	}))

	if fuckflag == false then
		layer:addChild(d_ms.d_u.createByStyle({
			type = "label",
			font = "arial",
			fontsize = 22,
			x = mx - 0.7 * w,
			y = cy,
			anchor = {
				0,
				0.5
			},
			string = castInfo.cur.name or d_ms.d_hz.gethz("no"),
			color = colors[1]
		}))

		if castInfo.cur.desc then
			cy = cy - dy

			layer:addChild(d_ms.d_u.createByStyle({
				type = "label",
				font = "arial",
				fontsize = 18,
				x = mx - 0.05 * w,
				y = cy,
				anchor = {
					1,
					0.5
				},
				string = castInfo.cur.desc,
				color = colors[1]
			}))
		end
	else
		layer:addChild(d_ms.d_u.createByStyle({
			type = "label",
			font = "arial",
			fontsize = 22,
			x = mx - 0.7 * w,
			y = cy,
			anchor = {
				0,
				0.5
			},
			string = castInfo.next.name or d_ms.d_hz.gethz("no"),
			color = colors[1]
		}))

		if castInfo.next.desc then
			cy = cy - dy

			layer:addChild(d_ms.d_u.createByStyle({
				type = "label",
				font = "arial",
				fontsize = 18,
				x = mx - 0.05 * w,
				y = cy,
				anchor = {
					1,
					0.5
				},
				string = castInfo.next.desc,
				color = colors[1]
			}))
		end
	end

	cy = cy - dy

	if fuckflag == false then
		layer:addChild(d_ms.d_u.createByStyle({
			type = "label",
			font = "arial",
			fontsize = 22,
			x = mx - 0.95 * w,
			y = cy,
			anchor = {
				0,
				0.5
			},
			string = d_ms.d_hz.gethz("cast11"),
			color = colors[3]
		}))
		layer:addChild(d_ms.d_u.createByStyle({
			type = "label",
			font = "arial",
			fontsize = 22,
			x = mx - 0.7 * w,
			y = cy,
			anchor = {
				0,
				0.5
			},
			string = castInfo.next.name or d_ms.d_hz.gethz("no"),
			color = colors[3]
		}))

		if castInfo.next.desc then
			cy = cy - dy

			layer:addChild(d_ms.d_u.createByStyle({
				type = "label",
				font = "arial",
				fontsize = 18,
				x = mx - 0.05 * w,
				y = cy,
				anchor = {
					1,
					0.5
				},
				string = castInfo.next.desc,
				color = colors[3]
			}))
		end
	end
end

local chgTargetItemPos = 0

function touchCharacterItem(tag)
	local object_type, main_type, targetPos = nil

	if tag > 3 then
		object_type = o_t.skill
		targetPos = tag - 3
	else
		object_type = o_t.item
		targetPos = tag

		if tag == 1 then
			main_type = m_t.weapon
		elseif tag == 2 then
			main_type = m_t.guard
		elseif tag == 3 then
			main_type = m_t.talismans
		end
	end

	g_touchItemInfo = {}
	local isEquiped = false
	local usedItems = g_charPosUI.allUsedItems[g_lastShowOrder]
	local equipedItem = nil

	for i = 1, #usedItems do
		if usedItems[i].item.attach_type == object_type and usedItems[i].item.equip_pos == targetPos then
			isEquiped = true
			equipedItem = usedItems[i].item
			g_selectItem = {
				sprite = g_itemsSprite[object_type][targetPos],
				object_type = object_type,
				equip_pos = targetPos
			}
			g_touchItemInfo.isEquiped = isEquiped
			g_touchItemInfo.equipedItem = equipedItem

			break
		end
	end

	g_touchItemInfo.main_type = main_type
	g_touchItemInfo.object_type = object_type
	g_touchItemInfo.equipedItem = equipedItem
	g_touchItemInfo.targetPos = targetPos
	g_isShowItemChangeLayer = false
	chgTargetItemPos = targetPos

	if isEquiped then
		showItemIntro(equipedItem)
	elseif not g_charPosUI.isReadOnly then
		showItemChangeLayer(object_type, main_type, targetPos)
	end
end

function showItemIntro(item, noAction)
	g_lastItemIntro = item
	local parent = g_charPosUI.charInfoLayer
	local object_type = item.attach_type
	local targetPos = item.equip_pos
	local lastItemChgLayer = parent:getChildByTag(tagDef.itemChange)

	if lastItemChgLayer then
		parent:removeChild(lastItemChgLayer, true)
	end

	local lastItemIntroLayer = parent:getChildByTag(tagDef.usedItemIntro)

	if lastItemIntroLayer then
		parent:removeChild(lastItemIntroLayer, true)
	end

	local itemIntroLayer = CCLayer:create()

	itemIntroLayer:setTag(tagDef.usedItemIntro)
	parent:addChild(itemIntroLayer, 20)

	local positionX = 0
	local positionY = 0

	if object_type == o_t.item then
		positionX = 0.645 * scrSize.width
	elseif object_type == o_t.skill then
		positionX = 0.34 * scrSize.width
	end

	if targetPos == 1 then
		positionY = 0.55 * scrSize.height
	elseif targetPos == 2 then
		positionY = 0.48 * scrSize.height
	elseif targetPos == 3 then
		positionY = 0.4 * scrSize.height
	end

	local introBkg = CCSprite:create("v2/charPositionUI/skill_small_bkg.png")

	itemIntroLayer:addChild(introBkg)
	introBkg:setPosition(positionX, positionY)

	local bkgSize = introBkg:getContentSize()
	local isNeedNextShow = false
	local touchRect = CCRectMake(positionX - 0.5 * bkgSize.width, positionY - 0.5 * bkgSize.height, bkgSize.width, bkgSize.height)

	local function onItemChangeTouch(eventType, x, y)
		if not touchRect:containsPoint(CCPointMake(x, y)) then
			for i = 1, #g_headButtons do
				if g_headButtons[i]:boundingBox():containsPoint(CCPointMake(x, y)) then
					if i ~= g_lastShowOrder then
						isNeedNextShow = true

						return false
					else
						break
					end
				end
			end

			itemIntroLayer:getParent():removeChild(itemIntroLayer, true)

			g_lastItemIntro = nil
		end

		return true
	end

	itemIntroLayer:registerScriptTouchHandler(onItemChangeTouch, false, -128, true)
	itemIntroLayer:setTouchEnabled(true)

	local function sceneEventHandler(eventType)
		if eventType.name == "exit" and not isNeedNextShow then
			g_lastItemIntro = nil
		end
	end

	itemIntroLayer:registerScriptHandler(sceneEventHandler)

	local arrowSprite = CCSprite:create("v2/charPositionUI/small_arrow.png")
	local arrowPosY = (0.89 - targetPos * 0.2) * scrSize.height

	if object_type == o_t.skill then
		arrowSprite:setAnchorPoint(CCPointMake(1, 0.5))
		arrowSprite:setPosition(positionX - bkgSize.width * 0.5, arrowPosY)
	elseif object_type == o_t.item then
		arrowSprite:setAnchorPoint(CCPointMake(0, 0.5))
		arrowSprite:setPosition(positionX + bkgSize.width * 0.5, arrowPosY)
		arrowSprite:setFlipX(true)
	end

	itemIntroLayer:addChild(arrowSprite, 10)

	local nameLabel = d_ms.d_u.createByStyle({
		font = "arial",
		fontsize = 30,
		type = "label",
		string = item.csvInfo.name
	})

	nameLabel:setPosition(0.5 * bkgSize.width, 0.9 * bkgSize.height)
	introBkg:addChild(nameLabel)

	local level = item.level

	if item.type_id == 21 then
		d_ms.d_skillUpgradeUI.initSkillCsv()

		local HpSprite = CCSprite:create("v2/introUI/xi.png")

		HpSprite:setPosition(bkgSize.width * 0.29, bkgSize.height * 0.78)
		HpSprite:setAnchorPoint(CCPointMake(0, 0.5))
		introBkg:addChild(HpSprite, 5)

		local xishu = 0

		if g_charPosUI.current_characterInfo ~= nil then
			xishu = g_charPosUI.current_characterInfo.magic / 800
		end

		local num = d_ms.d_skillUpgradeUI.g_self.csv_map_rulai_skill[level][2]
		local cor = {
			255,
			255,
			255
		}

		if d_ms.d_wakeUI.isAwaken(item.awaken) then
			d_ms.d_wakeUI.initCsv()

			num = num * 1.1 + xishu
			cor = {
				0,
				255,
				0
			}
		else
			num = num + xishu
		end

		local tmp = string.format("%.1f", num) .. "%"
		local HpLabel = d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			fontsize = 26,
			string = tmp,
			color = cor
		})

		HpLabel:setPosition(bkgSize.width * 0.49, bkgSize.height * 0.78)
		HpLabel:setAnchorPoint(CCPointMake(0, 0.5))
		introBkg:addChild(HpLabel, 5)
	elseif object_type == o_t.skill and item.upgrade_level and item.upgrade_level > 0 then
		local HpSprite = CCSprite:create("v2/introUI/health.png")

		HpSprite:setPosition(bkgSize.width * 0.29, bkgSize.height * 0.78)
		HpSprite:setAnchorPoint(CCPointMake(0, 0.5))
		introBkg:addChild(HpSprite, 5)

		local Hp = 12
		local HpLabel = d_ms.d_u.createByStyle({
			font = "arial",
			fontsize = 26,
			type = "label",
			string = tostring(Hp) .. "%"
		})

		HpLabel:setPosition(bkgSize.width * 0.56, bkgSize.height * 0.78)
		HpLabel:setAnchorPoint(CCPointMake(0, 0.5))
		introBkg:addChild(HpLabel, 5)
	else
		local levelSprite = CCSprite:create("v2/introUI/level.png")

		levelSprite:setPosition(bkgSize.width * 0.07, bkgSize.height * 0.73)
		levelSprite:setAnchorPoint(CCPointMake(0, 0.5))
		introBkg:addChild(levelSprite, 5)

		local levelLabel = d_ms.d_u.createByStyle({
			font = "arial",
			fontsize = 26,
			type = "label",
			string = tostring(level)
		})

		levelLabel:setPosition(bkgSize.width * 0.26, bkgSize.height * 0.73)
		levelLabel:setAnchorPoint(CCPointMake(0, 0.5))
		introBkg:addChild(levelLabel, 5)
	end

	if object_type == o_t.skill then
		if item.type_id == 21 then
			createSkillLabel(introBkg, level, item.type_id, CCPointMake(bkgSize.width * 0.38, bkgSize.height * 0.66), d_ms.d_wakeUI.isAwaken(item.awaken), item.effect_value)
		elseif item.upgrade_level and item.upgrade_level > 0 then
			createSkillLabel(introBkg, level, item.type_id, CCPointMake(bkgSize.width * 0.38, bkgSize.height * 0.66), d_ms.d_wakeUI.isAwaken(item.awaken), item.effect_value)
		else
			createSkillLabel(introBkg, level, item.type_id, CCPointMake(bkgSize.width * 0.56, bkgSize.height * 0.73), d_ms.d_wakeUI.isAwaken(item.awaken), item.effect_value)
		end
	else
		createItemLabel(introBkg, item, CCPointMake(bkgSize.width * 0.6, bkgSize.height * 0.73))
	end

	local introLayer = nil

	function introLayerCallback(buttonTag)
		cclog("tag is %d", buttonTag)

		local function suicide()
			if introLayer ~= nil then
				g_charPosUI.parent:removeChild(introLayer, true)

				introLayer = nil
			end
		end

		local buttonType = d_ms.d_packageUI.g_introButtonType

		if buttonTag == buttonType.enhance then
			if object_type == o_t.item then
				if d_ms.d_equipmentUpgradeUI.checkEquipmentCanUpgrade(true, item.level, item.csvInfo.quality, item.reborn_bit) > 1 then
					return
				end

				suicide()
				d_ms.d_equipmentUpgradeUI.showEnhanceLayer(g_charPosUI.parent, item, 40, true)
			else
				cclog("ERROR: charposition show intro layer not equip and enhance button pressed")
			end
		elseif buttonTag == buttonType.slot then
			if d_ms.d_stoneUI.canJoin(true) then
				suicide()
				d_ms.d_stoneUI.showStoneLayer(g_charPosUI.parent, 40, item)
			end
		elseif buttonTag == buttonType.enhanceSkill then
			if object_type == o_t.skill then
				if item.upgrade_level and item.upgrade_level ~= 0 then
					d_ms.d_info.show(gethz("advance16"))
				elseif item.level < 10 then
					d_ms.d_info.show(gethz("advance15"))
				else
					suicide()

					local params = {
						skill_info = item,
						from_btn = 100,
						parent_layer = g_charPosUI.parent,
						isNeedUpdate = true
					}

					d_ms.d_skillUpgradeUI.show(params)
				end
			else
				cclog("ERROR: charposition show intro layer not skill and skillEnhance button pressed")
			end
		elseif buttonTag == buttonType.advance then
			if object_type == o_t.item then
				if not d_ms.d_equipAdvanceUI.canJoin(true) then
					return
				end

				suicide()
				d_ms.d_equipAdvanceUI.showAdvanceLayer(g_charPosUI.parent, 40, item)
			else
				cclog("ERROR: charposition show intro layer not equip and advance button pressed")
			end
		elseif buttonTag == buttonType.asc then
			suicide()
			d_ms.d_equipAscUI.show(g_charPosUI.parent, 40, item)
		elseif buttonTag == buttonType.cast then
			suicide()
			d_ms.d_equipCastUI.show(g_charPosUI.parent, 40, item)
		elseif buttonTag == buttonType.handbook then
			suicide()
			d_ms.d_packageUI.pressHandBook(object_type)
		else
			suicide()
		end
	end

	local function createItemIntroLayer()
		if not g_charPosUI.isReadOnly then
			introLayer = d_ms.d_packageUI.createItemIntroLayer(item, introLayerCallback, true)
		else
			introLayer = d_ms.d_packageUI.createItemIntroLayer(item, introLayerCallback, false)
		end

		itemIntroLayer:getParent():removeChild(itemIntroLayer, true)
		g_charPosUI.parent:addChild(introLayer, 50)
	end

	local introMenuItem = CCMenuItemImage:create("v2/charPositionUI/detail1.png", "v2/charPositionUI/detail2.png")

	introMenuItem:setPosition(bkgSize.width * 0.5, bkgSize.height * 0.31)
	introMenuItem:registerScriptTapHandler(createItemIntroLayer)

	local introMenu = CCMenu:createWithItem(introMenuItem)

	introMenu:setPosition(0, 0)
	introBkg:addChild(introMenu, 5)

	local enhanceMenuItem = nil

	if not g_charPosUI.isReadOnly then
		local charInfo = g_charPosUI.current_characterInfo

		local function showChangeItemIntroLayer()
			showItemChangeLayer(object_type, item.csvInfo.mainType, targetPos, item)
		end

		if item.protogenic ~= 1 then
			local changeMenuItem = CCMenuItemImage:create("v2/charPositionUI/change1.png", "v2/charPositionUI/change2.png")

			changeMenuItem:setPosition(bkgSize.width * 0.5, bkgSize.height * 0.12)
			changeMenuItem:registerScriptTapHandler(showChangeItemIntroLayer)

			local changeMenu = CCMenu:createWithItem(changeMenuItem)

			changeMenu:setPosition(0, 0)
			introBkg:addChild(changeMenu, 5)
		elseif d_ms.d_wakeUI.hasBtn(charInfo, item) then
			local function pressWake(tag)
				d_ms.d_wakeUI.g_self.des_skill = item
				d_ms.d_wakeUI.g_self.des_char = charInfo
				d_ms.d_wakeUI.g_wakeUI.parent_layer = g_charPosUI.parent
				local lastItemIntroLayer = parent:getChildByTag(tagDef.usedItemIntro)

				if lastItemIntroLayer then
					parent:removeChild(lastItemIntroLayer, true)
				end

				if tag == 2 then
					d_ms.d_wakeUI.enter(g_charPosUI.parent, item, charInfo)
				else
					d_ms.d_wakeUI.showAfterWake(g_charPosUI.parent, item)
				end
			end

			local wakeMenuItem = nil

			cclog("item.awakenitem.awakenitem.awaken = %s", item.awaken)

			if d_ms.d_wakeUI.isAwaken(item.awaken) then
				wakeMenuItem = CCMenuItemImage:create("v2/wakeUI/wash1.png", "v2/wakeUI/wash2.png")

				wakeMenuItem:setTag(1)
			else
				wakeMenuItem = CCMenuItemImage:create("v2/wakeUI/wake21.png", "v2/wakeUI/wake22.png")

				wakeMenuItem:setTag(2)
			end

			wakeMenuItem:setPosition(bkgSize.width * 0.5, bkgSize.height * 0.12)
			wakeMenuItem:registerScriptTapHandler(pressWake)

			local changeMenu = CCMenu:createWithItem(wakeMenuItem)

			changeMenu:setPosition(0, 0)
			introBkg:addChild(changeMenu, 5)
		end

		local function showItemEnhance()
			if object_type == o_t.item and item.level >= d_ms.d_mainUI.g_playerInfo.level * 2 then
				d_ms.d_info.show(gethz("enhance_cannot2"), 4, 0.5)

				return
			elseif object_type == o_t.skill and item.upgrade_level > 0 then
				d_ms.d_info.show(gethz("advance16"), 4, 0.5)

				return
			end

			local parent = g_charPosUI.charInfoLayer
			local scrSize = CCDirector:sharedDirector():getVisibleSize()
			local lastItemChgLayer = parent:getChildByTag(tagDef.itemChange)

			if lastItemChgLayer then
				parent:removeChild(lastItemChgLayer, true)
			end

			local lastItemIntroLayer = parent:getChildByTag(tagDef.usedItemIntro)

			if lastItemIntroLayer then
				parent:removeChild(lastItemIntroLayer, true)
			end

			if object_type == 6 then
				local params = {
					skill_info = item
				}

				if item.level < 10 or not d_ms.d_skillUpgradeUI.isCanAdvance(item.type_id) then
					params.from_btn = 2
				else
					params.from_btn = 100
				end

				params.parent_layer = g_charPosUI.parent
				params.isNeedUpdate = true

				d_ms.d_skillUpgradeUI.show(params)
			elseif object_type == 5 then
				d_ms.d_equipmentUpgradeUI.showEnhanceLayer(g_charPosUI.parent, item, 40, true)
			end
		end

		if object_type == o_t.item then
			enhanceMenuItem = CCMenuItemImage:create("v2/charPositionUI/enhance1.png", "v2/charPositionUI/enhance2.png")
		elseif object_type == o_t.skill then
			if item.level == 10 and d_ms.d_skillUpgradeUI.isCanAdvance(item.type_id) then
				enhanceMenuItem = CCMenuItemImage:create("v2/enhanceUI/up_2.png", "v2/enhanceUI/up_2.png")
			else
				enhanceMenuItem = CCMenuItemImage:create("v2/newIntroUI/upgrade1.png", "v2/newIntroUI/upgrade2.png")
			end
		end

		enhanceMenuItem:setPosition(bkgSize.width * 0.5, bkgSize.height * 0.5)
		enhanceMenuItem:registerScriptTapHandler(showItemEnhance)

		if d_ms.d_enGuideUI.g_isEnhanceGuide then
			g_enhanceMenuItem = enhanceMenuItem
			local pos1 = enhanceMenuItem:getPositionLua()
			local pos2 = introBkg:convertToWorldSpace(pos1)
			g_enhanceMenuItemPos = pos2
		end

		local enhanceMenu = CCMenu:createWithItem(enhanceMenuItem)

		enhanceMenu:setPosition(0, 0)
		introBkg:addChild(enhanceMenu, 5)

		if object_type == o_t.item and item.level >= d_ms.d_mainUI.g_playerInfo.level * 2 then
			d_ms.d_u.grayMenuItem(enhanceMenuItem)
		end

		if d_ms.d_wakeUI.canWake(charInfo, item) and d_ms.d_mainUI.hasWakeGuide(true) then
			d_ms.d_guideUI.showHintArrow(introBkg, ccp(bkgSize.width * 1.5, bkgSize.height * 0.12), d_ms.d_guideUI.HintDir.left)

			local frame = d_ms.d_u.createByStyles({
				pic = "v2/guideUI/hint.png",
				pos_x = bkgSize.width * 0.5,
				pos_y = bkgSize.height * 0.12,
				scaleX = bkgSize.width / scrSize.width * 0.9,
				scaleY = bkgSize.height / scrSize.height * 0.23
			})

			introBkg:addChild(frame, 5)
		end
	else
		local charInfo = g_charPosUI.current_characterInfo

		if d_ms.d_wakeUI.isAwaken(item.awaken) and not g_charPosUI.playerInfo.isMe then
			local function pressWake()
				d_ms.d_wakeUI.g_self.des_skill = item
				d_ms.d_wakeUI.g_self.des_char = charInfo
				d_ms.d_wakeUI.g_wakeUI.parent_layer = g_charPosUI.parent
				local lastItemIntroLayer = parent:getChildByTag(tagDef.usedItemIntro)

				if lastItemIntroLayer then
					parent:removeChild(lastItemIntroLayer, true)
				end

				d_ms.d_wakeUI.showAfterWake(g_charPosUI.parent, item, nil, true)
			end

			local wakeMenuItem = CCMenuItemImage:create("v2/wakeUI/wash1.png", "v2/wakeUI/wash2.png")

			wakeMenuItem:setPosition(bkgSize.width * 0.5, bkgSize.height * 0.12)
			wakeMenuItem:registerScriptTapHandler(pressWake)

			local wakeMenu = CCMenu:createWithItem(wakeMenuItem)

			wakeMenu:setPosition(0, 0)
			introBkg:addChild(wakeMenu, 5)
		end
	end

	if not noAction then
		itemIntroLayer:setScale(0.2)

		local actionArray = CCArray:create()
		local fadeAction = CCFadeIn:create(0.3)

		actionArray:addObject(fadeAction)

		local scaleAction = CCScaleTo:create(0.3, 1)

		actionArray:addObject(scaleAction)
		itemIntroLayer:runAction(CCSpawn:create(actionArray))
	end

	if d_ms.d_mainUI.g_isNeedGuide then
		d_ms.d_guideUI.show()
	elseif d_ms.d_enGuideUI.g_isEnhanceGuide then
		d_ms.d_enGuideUI.show()
	end
end

local chgItemDataTable = {}
local headerMenuSize = CCSizeMake(0.52 * scrSize.width, 0.12 * scrSize.height)

local function createHeaderMenu(parent)
	d_ms.d_data.createCommonFilterMenu(parent, d_ms.d_filterLayer.TAG.Equip_All, ccp(headerMenuSize.width * 0.85, headerMenuSize.height * 0.5), ensureFilter, chgItemDataTable.currentFilter)
end

local function createCellOnChgItem(parent, itemInfo, bkgPic, cellSize)
	d_ms.d_createCell.createCellWithOwnerNoBtn(parent, itemInfo, bkgPic, cellSize)

	if isHaveFateWithCurrentChar(itemInfo.attach_type, itemInfo.type_id) then
		local fateSprite = CCSprite:create("v2/charPositionUI/fate.png")

		fateSprite:setPosition(cellSize.width * 0.12, cellSize.height * 0.35)
		fateSprite:setScale(0.7)
		parent:addChild(fateSprite, 10)
	end

	local function requestChangeItemWrap()
		requestChangeItem(itemInfo)
	end

	local changeButtonItem = CCMenuItemImage:create("v2/charPositionUI/a_change1.png", "v2/charPositionUI/a_change2.png")

	changeButtonItem:setPosition(cellSize.width * 0.85, cellSize.height * 0.25)
	changeButtonItem:registerScriptTapHandler(requestChangeItemWrap)

	local changeMenu = CCMenu:createWithItem(changeButtonItem)

	changeMenu:setPosition(0, 0)
	parent:addChild(changeMenu, 5)
end

local function getChgItemCellsDataSource(chgItems)
	local cellSize = CCSizeMake(0.52 * scrSize.width, 0.2 * scrSize.height)
	local bkgPic = "v2/charPositionUI/item_bkg.png"
	local dataSource = {}
	local num = #chgItems

	function dataSource.tableViewNumberOfRows()
		return num + 1
	end

	chgItemDataTable.currentChgItems = chgItems

	function dataSource.drawCellAtIndex(index)
		local cell = CCNode:create()

		if index == 1 then
			createHeaderMenu(cell)
		elseif chgItems[index - 1] then
			createCellOnChgItem(cell, chgItems[index - 1], bkgPic, cellSize)
		end

		return cell
	end

	function dataSource.heightForRowAtIndex(index)
		if index == 1 then
			return headerMenuSize.height
		else
			return cellSize.height
		end
	end

	return dataSource
end

function updateChgItemCellByItem(item)
	local chgItemTableView = chgItemDataTable.chgItemTableView

	if not chgItemTableView then
		return
	end

	local currentChgItems = chgItemDataTable.currentChgItems

	if not currentChgItems then
		return
	end

	local updateIndex = nil

	for i = 1, #currentChgItems do
		if currentChgItems[i].id == item.id and currentChgItems[i].type_id == item.type_id then
			updateIndex = i

			break
		end
	end

	if updateIndex then
		chgItemTableView:updateCellAtIndex(updateIndex + 1)
	end
end

function ensureFilter(filter)
	local chgItemTableView = chgItemDataTable.chgItemTableView

	if not chgItemTableView then
		return
	end

	local check = d_ms.d_filterLayer.check
	chgItemDataTable.currentFilter = filter
	local forChgItems = chgItemDataTable.forChgItems

	if not forChgItems then
		return
	end

	local afterFilterItems = {}

	for i = 1, #forChgItems do
		if check and check(forChgItems[i], filter) then
			afterFilterItems[#afterFilterItems + 1] = forChgItems[i]
		end
	end

	local dataSource = getChgItemCellsDataSource(afterFilterItems)

	chgItemTableView:reloadData(dataSource)
end

function showItemChangeLayer(object_type, main_type, targetPos, targetItem, isNoAction)
	g_isShowItemChangeLayer = true
	local parent = g_charPosUI.charInfoLayer
	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local lastItemChgLayer = parent:getChildByTag(tagDef.itemChange)

	if lastItemChgLayer then
		parent:removeChild(lastItemChgLayer, true)
	end

	local lastItemIntroLayer = parent:getChildByTag(tagDef.usedItemIntro)

	if lastItemIntroLayer then
		parent:removeChild(lastItemIntroLayer, true)
	end

	local itemChangeLayer = CCLayer:create()

	itemChangeLayer:setTag(tagDef.itemChange)
	parent:addChild(itemChangeLayer, 20)

	local bkgLayer = CCLayer:create()

	itemChangeLayer:addChild(bkgLayer, -1)

	local changeLayer = CCLayer:create()

	itemChangeLayer:addChild(changeLayer)

	local scaleW = g_scaleW
	local maskSprite = CCSprite:create("v2/charPositionUI/change_skill_bkg.png")
	local maskSize = maskSprite:getContentSize()
	local maskScaleY = g_charPosUI.board_size.height / maskSize.height

	maskSprite:setScaleX(scaleW)
	maskSprite:setScaleY(maskScaleY)
	bkgLayer:addChild(maskSprite, -1)
	d_ms.d_u.setStyles(maskSprite, {
		x = 0.5,
		y = 0.56
	})

	if targetItem then
		local type_id = targetItem.type_id
		local level = targetItem.level
		local isAsc = targetItem.reborn_bit and targetItem.reborn_bit > 0
		local targetSprite = d_ms.d_data.getCertainSmallSprite(object_type, type_id, level, isAsc)

		if object_type == o_t.skill then
			d_ms.d_u.setStyles(targetSprite, {
				scale = 0.09,
				x = 0.19,
				y = 0.89 - targetPos * 0.2
			})
		elseif object_type == o_t.item then
			d_ms.d_u.setStyles(targetSprite, {
				scale = 0.09,
				x = 0.8,
				y = 0.89 - targetPos * 0.2
			})
		end

		bkgLayer:addChild(targetSprite, 10)

		local levelLabel = d_ms.d_u.createByStyle({
			font = "arial",
			fontsize = 22,
			type = "label",
			string = tostring(level)
		})

		targetSprite:addChild(levelLabel)

		local size = targetSprite:getContentSize()
		local itemPos = targetSprite:getPositionLua()

		levelLabel:setAnchorPoint(CCPointMake(0, 0.5))
		levelLabel:setPosition(0.1 * size.width, 0.8 * size.height)

		if object_type == o_t.item then
			local advanceLabel = nil

			if isAsc and targetItem.cast_level and targetItem.cast_level > 0 then
				advanceLabel = CCSprite:create("v2/ascCast/cast_" .. targetItem.cast_level .. ".png")
			elseif not isAsc and targetItem.advance_level and targetItem.advance_level > 0 then
				advanceLabel = CCSprite:create("v2/equipAdvanceUI/ad" .. targetItem.advance_level .. ".png")
			end

			if advanceLabel then
				targetSprite:addChild(advanceLabel, 10)
				advanceLabel:setAnchorPoint(CCPointMake(1, 0))
				advanceLabel:setPosition(0.93 * size.width, 0.07 * size.height)
				d_ms.d_data.addAdvanceCcbi(targetSprite, targetItem.advance_level)
			end
		end
	end

	local itemBkg = CCSprite:create("v2/charPositionUI/square_bkg.png")
	local introSprite = nil

	if object_type == o_t.skill then
		d_ms.d_u.setStyles(itemBkg, {
			x = 0.19,
			y = 0.89 - targetPos * 0.2
		})

		introSprite = CCSprite:create("v2/charPositionUI/skillHZ.png")
	elseif object_type == o_t.item then
		d_ms.d_u.setStyles(itemBkg, {
			x = 0.8,
			y = 0.89 - targetPos * 0.2
		})

		introSprite = CCSprite:create("v2/charPositionUI/itemHZ_" .. targetPos .. ".png")
	end

	local itemBkgPos = itemBkg:getPositionLua()
	local frame = CCSprite:create("v2/charPositionUI/frame1.png")

	frame:setPosition(itemBkgPos)
	introSprite:setPosition(itemBkgPos)
	bkgLayer:addChild(itemBkg, 4)
	bkgLayer:addChild(frame, 5)
	bkgLayer:addChild(introSprite, 5)

	local layerHeight = g_charPosUI.board_size.height * 0.98
	local positionY = 0.17 * scrSize.height
	local positionX = 0

	if object_type == o_t.skill then
		positionX = 0.26 * scrSize.width
	elseif object_type == o_t.item then
		positionX = 0.13 * scrSize.width
	end

	local upBkg = CCSprite:create("v2/charPositionUI/chg_bkg_up.png")
	local midBkg = CCSprite:create("v2/charPositionUI/chg_bkg_mid.png")
	local downBkg = CCSprite:create("v2/charPositionUI/chg_bkg_up.png")

	downBkg:setFlipY(true)

	local upSize = upBkg:getContentSize()
	local midSize = midBkg:getContentSize()
	local midScaleY = (layerHeight - upSize.height * 2) / midSize.height

	midBkg:setScaleY(midScaleY)
	midBkg:setScaleX(scaleW)
	upBkg:setScale(scaleW)
	downBkg:setScale(scaleW)
	downBkg:setAnchorPoint(CCPointMake(0, 0))
	downBkg:setPosition(positionX, positionY)
	midBkg:setAnchorPoint(CCPointMake(0, 0))
	midBkg:setPosition(positionX, positionY + upSize.height)
	upBkg:setAnchorPoint(CCPointMake(0, 0))
	upBkg:setPosition(positionX, positionY + layerHeight - upSize.height)
	changeLayer:addChild(downBkg)
	changeLayer:addChild(midBkg)
	changeLayer:addChild(upBkg)

	local arrowSprite = CCSprite:create("v2/charPositionUI/small_arrow.png")
	local arrowPosY = (0.89 - targetPos * 0.2) * scrSize.height

	if object_type == o_t.skill then
		arrowSprite:setAnchorPoint(CCPointMake(1, 0.5))
		arrowSprite:setPosition(positionX, arrowPosY)
	elseif object_type == o_t.item then
		arrowSprite:setAnchorPoint(CCPointMake(0, 0.5))
		arrowSprite:setPosition(positionX + midSize.width, arrowPosY)
		arrowSprite:setFlipX(true)
	end

	changeLayer:addChild(arrowSprite, 10)

	local touchRect = CCRectMake(positionX, positionY, midSize.width, layerHeight)
	local startPoint = nil
	local isMoved = false
	local isLayerDel = false

	local function onTouchBegan(x, y)
		isMoved = false
		startPoint = CCPointMake(x, y)

		return true
	end

	local function onTouchMoved(x, y)
		local distance = math.abs(ccpDistance(startPoint, CCPointMake(x, y)))

		if distance > 0.02 * scrSize.width then
			isMoved = true
		end
	end

	local function onTouchEnded(x, y)
		if not isMoved and not touchRect:containsPoint(CCPointMake(x, y)) then
			itemChangeLayer:getParent():removeChild(itemChangeLayer, true)

			g_isShowItemChangeLayer = false
			g_chgItemlayerPos = nil
		end
	end

	local function onItemChangeTouch(eventType, x, y)
		if eventType == CCTOUCHBEGAN then
			return onTouchBegan(x, y)
		elseif eventType == CCTOUCHMOVED then
			return onTouchMoved(x, y)
		else
			return onTouchEnded(x, y)
		end

		return true
	end

	changeLayer:registerScriptTouchHandler(onItemChangeTouch, false, -128, true)
	changeLayer:setTouchEnabled(true)

	local function sceneEventHandler(eventType)
		if eventType.name == "exit" then
			chgItemDataTable = {}
		end
	end

	changeLayer:registerScriptHandler(sceneEventHandler)

	if not d_ms.d_packageUI.g_isPackageSorted then
		d_ms.d_packageUI.sortItems()
	end

	local rawData = d_ms.d_packageUI.g_reorgItemsInfo[object_type] or {}

	if object_type == o_t.item then
		rawData = rawData[main_type]
	end

	rawData = rawData or {}
	local packageItemsInfo = d_ms.d_c.table_copy(rawData)

	filterPackageItems(packageItemsInfo, targetItem)

	if main_type == m_t.skill then
		table.sort(packageItemsInfo, skillSortFunc)
	elseif main_type == m_t.weapon or main_type == m_t.guard or main_type == m_t.talismans then
		table.sort(packageItemsInfo, d_ms.d_packageUI.packageSortFunc)
	end

	if #packageItemsInfo <= 0 then
		local hintLabel = nil

		if object_type == o_t.item then
			hintLabel = d_ms.d_u.createByStyle({
				y = 0.6,
				font = "arial",
				type = "label",
				x = 0.44,
				fontsize = 26,
				string = gethz("noUsableEquip")
			})
		else
			hintLabel = d_ms.d_u.createByStyle({
				y = 0.6,
				font = "arial",
				type = "label",
				x = 0.56,
				fontsize = 26,
				string = gethz("noUsableSkill")
			})
		end

		changeLayer:addChild(hintLabel, 10)
	else
		local touchArea = {
			x = positionX + 0.05 * scrSize.width,
			y = positionY,
			width = midSize.width,
			height = layerHeight
		}
		local chgItemTableView = d_ms.d_tableView.tableView(changeLayer, touchArea)
		chgItemDataTable.chgItemTableView = chgItemTableView
		chgItemDataTable.forChgItems = packageItemsInfo
		local dataSource = getChgItemCellsDataSource(packageItemsInfo)

		chgItemTableView:startScroll()
		chgItemTableView:setDataSource(dataSource)
	end

	if not isNoAction then
		changeLayer:setScale(0.2)

		local actionArray = CCArray:create()
		local fadeAction = CCFadeIn:create(0.3)

		actionArray:addObject(fadeAction)

		local scaleAction = CCScaleTo:create(0.3, 1)

		actionArray:addObject(scaleAction)
		changeLayer:runAction(CCSpawn:create(actionArray))
	end

	if d_ms.d_mainUI.g_isNeedGuide then
		d_ms.d_guideUI.show()
	end
end

function filterPackageItems(packageItemsInfo, targetItem)
	local count = #packageItemsInfo

	for i = count, 1, -1 do
		if filterItems(packageItemsInfo[i], targetItem) then
			table.remove(packageItemsInfo, i)
		end
	end
end

function sortItems(a, b)
	d_ms.d_packageUI.packageSortFunc(a, b)
end

function reOrgTable(itemsInfo)
	local itemsTable = {}

	for k, v in pairs(itemsInfo) do
		itemsTable[#itemsTable + 1] = v
	end

	return itemsTable
end

function filterItems(item, targetItem)
	if item.protogenic == 1 then
		return true
	end

	if item.equip_order == g_lastShowOrder or item.equip_order > 8 then
		return true
	end

	if item.attach_type == o_t.skill then
		local usedItems = g_charPosUI.allUsedItems[g_lastShowOrder]

		if targetItem and item.type_id == targetItem.type_id then
			return false
		end

		for i = 1, #usedItems do
			if item.type_id == usedItems[i].item.type_id then
				return true
			end
		end
	end

	return false
end

function showTargetItemIntro(tag)
	local item = g_changeItemsList[tag]
	local object_type = item.attach_type
	g_targetItemTag = tag
	local introLayer = nil

	function introLayerCallback(buttonTag)
		cclog("tag is %d", buttonTag)
		g_charPosUI.parent:removeChild(introLayer, true)

		if buttonTag == -1 then
			introLayer = nil
		elseif buttonTag == d_ms.d_packageUI.g_introButtonType.enhance then
			if object_type == 6 then
				local params = {
					skill_info = item,
					from_btn = 2,
					parent_layer = g_charPosUI.parent
				}

				d_ms.d_skillUpgradeUI.show(params)
			elseif object_type == 5 then
				d_ms.d_equipmentUpgradeUI.showEnhanceLayer(g_charPosUI.parent, item, 40)
			end
		end
	end

	introLayer = d_ms.d_packageUI.createItemIntroLayer(item, introLayerCallback, false)

	g_charPosUI.parent:addChild(introLayer, 50)
end

function requestChangeItem(changeItem)
	if d_ms.d_mainUI.g_isNeedGuide then
		local tmpRequest = {
			stage = d_ms.d_common_def.new_role_guide.change_equip,
			name = string.format("%0.0f", changeItem.id),
			head_type = 0
		}

		cclog("\\xb3\\xf5\\xb4θ\\xfc\\xbb\\xbbװ\\xb1\\xb8")
		d_ms.d_u.main_server_send_msg(d_ms.d_msg_def.gscl_msg_id.msg_new_role_guide, tmpRequest)

		return
	end

	if not changeItem then
		return
	end

	local tmp_req = {
		flag = 3,
		obj_type = changeItem.attach_type,
		src_id = changeItem.id,
		src_order = changeItem.equip_order,
		des_order = g_lastShowOrder,
		des_equip_pos = chgTargetItemPos
	}

	cclog("send ST_msg_bind_object_1037 to BS.")
	d_ms.d_u.main_server_send_msg(d_ms.d_msg_def.gscl_msg_id.msg_bind_object, tmp_req)
end

function updateItemSucceed()
	local lastItemChgLayer = g_charPosUI.charInfoLayer:getChildByTag(tagDef.itemChange)

	if lastItemChgLayer then
		g_charPosUI.charInfoLayer:removeChild(lastItemChgLayer, true)
	end

	local lastItemIntroLayer = g_charPosUI.charInfoLayer:getChildByTag(tagDef.usedItemIntro)

	if lastItemIntroLayer then
		g_charPosUI.charInfoLayer:removeChild(lastItemIntroLayer, true)
	end

	reloadData()
	tapHeadButton(g_lastShowOrder, true)
end

function createItemLabel(parent, item, position)
	local powerSprite = nil
	local scrSize = CCDirector:sharedDirector():getVisibleSize()

	if item.csvInfo.mainType == m_t.weapon then
		powerSprite = CCSprite:create("v2/introUI/damage.png")
	elseif item.csvInfo.mainType == m_t.guard then
		powerSprite = CCSprite:create("v2/introUI/defence.png")
	elseif item.csvInfo.mainType == m_t.talismans then
		powerSprite = CCSprite:create("v2/introUI/health.png")
	end

	local powerLabel = d_ms.d_u.createByStyle({
		font = "arial",
		fontsize = 26,
		type = "label",
		string = tostring(math.floor(item.effect_value))
	})

	powerSprite:setPosition(position)
	powerLabel:setPosition(position.x + 0.018 * scrSize.width, position.y)
	powerLabel:setAnchorPoint(CCPointMake(0, 0.5))
	powerLabel:setTag(tagDef.powerNum)
	parent:addChild(powerSprite, 5)
	parent:addChild(powerLabel, 5)

	return powerLabel
end

function createSkillLabel(parent, level, type_id, position, has_wake, eff_value)
	d_ms.d_skillUpgradeUI.initSkillCsv()

	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local effect_type = d_ms.d_skillUpgradeUI.g_self.csv_map_skill[type_id]
	local pro = 0
	local num = 0
	local cor = {
		255,
		255,
		255
	}
	local powerSprite = nil
	local itemInfo_level = level
	local is_intensity = false

	d_ms.d_wakeUI.initCsv()

	if type_id == 21 then
		powerSprite = CCSprite:create("v2/introUI/dun.png")
		num = d_ms.d_skillUpgradeUI.g_self.csv_map_rulai_skill[itemInfo_level][3]
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

	if has_wake then
		if not is_intensity then
			num = num * (1 + d_ms.d_wakeUI.g_csv.rate[type_id] / 100)
		end

		cor = {
			0,
			255,
			0
		}
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
		type = "label",
		fontsize = 26,
		string = pro,
		color = cor
	})

	powerSprite:setPosition(position)
	powerLabel:setPosition(position.x + 0.018 * scrSize.width, position.y)
	powerLabel:setAnchorPoint(CCPointMake(0, 0.5))
	powerLabel:setTag(tagDef.powerNum)
	parent:addChild(powerSprite, 5)
	parent:addChild(powerLabel, 5)

	return powerLabel
end

function createLevelSprite(level, parent)
	local levelStr = tostring(level)
	local size = parent:getContentSize()
	local level_num = {}
	local totalWidth = 0

	for i = 1, string.len(levelStr) do
		local _levelNum = string.sub(levelStr, i, i)
		level_num[i] = CCSprite:create("v2/vip/" .. _levelNum .. ".png")
		local contentSize = level_num[i]:getContentSize()

		parent:addChild(level_num[i], 1)

		totalWidth = totalWidth + contentSize.width
	end

	local center = {
		x = size.width * 0.5,
		y = size.height * 0.5
	}
	local offset = totalWidth * 0.5

	for i = 1, #level_num do
		local contentSize = level_num[i]:getContentSize()

		level_num[i]:setAnchorPoint(CCPointMake(0, 0.5))
		level_num[i]:setPosition(center.x - offset, center.y)

		offset = offset - contentSize.width
	end
end

function showPosLayer()
	cclog("show position layer")

	if g_isShowChgCharLayer then
		return
	end

	g_charPosUI.close_board:setVisible(false)
	g_charPosUI.chgCharLayer:setVisible(false)

	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local positionLayer = g_charPosUI.positionLayer
	local posButtonItem = g_charPosUI.posButtonItem
	local posArrow = g_charPosUI.posArrow

	posButtonItem:setEnabled(false)
	posArrow:setVisible(false)

	g_isShowPosLayer = true
	local bkg = createPosbkg()
	local moveDis = 0.96 * scrSize.width
	local board_size = g_charPosUI.board_size
	local board_layer = g_charPosUI.board_layer
	local chgPosContainer = CCLayer:create()
	local chgPosLayer = CCScrollView:create(CCSizeMake(scrSize.width, scrSize.height), chgPosContainer)

	chgPosLayer:setPosition(board_size.x, 0)
	chgPosContainer:setPosition(-moveDis, 0)
	board_layer:addChild(chgPosLayer, 10)
	createChgPos(chgPosContainer)

	local backArrow = CCSprite:create("v2/charPositionUI/arrow.png")

	backArrow:setFlipX(true)
	positionLayer:addChild(backArrow, 5)
	backArrow:setScale(g_scaleH)
	d_ms.d_u.setStyles(backArrow, {
		x = -0.06,
		y = 0.41
	})

	local backArrowPos = backArrow:getPositionLua()
	local backHZ = CCSprite:create("v2/charPositionUI/backHZ.png")

	backHZ:setPosition(backArrowPos)
	positionLayer:addChild(backHZ, 5)

	local backMenu = nil

	local function closePositionLayer()
		local moveAction1 = CCMoveBy:create(0.3, CCPointMake(-moveDis, 0))
		local moveAction2 = CCMoveBy:create(0.3, CCPointMake(-moveDis, 0))

		g_charPosUI.close_board:setVisible(true)
		g_charPosUI.chgCharLayer:setVisible(true)

		local function cleanFunction()
			positionLayer:removeChild(backMenu, true)
			positionLayer:removeChild(backArrow, true)
			positionLayer:removeChild(backHZ, true)
			positionLayer:setTouchEnabled(false)
			posButtonItem:setEnabled(true)
			posArrow:setVisible(true)

			local chgCharMenuItem = nil

			board_layer:removeChild(chgPosLayer, true)

			g_isShowPosLayer = false
		end

		positionLayer:runAction(CCSequence:createWithTwoActions(moveAction1, CCCallFuncN:create(cleanFunction)))
		chgPosContainer:runAction(moveAction2)
	end

	local backMenuItem = CCMenuItemImage:create("v2/charPositionUI/arrow_menu.png", "v2/charPositionUI/arrow_menu.png")

	backMenuItem:setPosition(backArrowPos)
	backMenuItem:setScale(g_scaleH)
	backMenuItem:registerScriptTapHandler(closePositionLayer)

	local backPos = backMenuItem:getPositionLua()
	local backSize = backMenuItem:getContentSize()
	backMenu = CCMenu:createWithItem(backMenuItem)

	backMenu:setPosition(0, 0)
	positionLayer:addChild(backMenu, 5)
	backMenu:setEnabled(false)

	local function enableNewMenu()
		backMenu:setEnabled(true)
	end

	local moveAction1 = CCMoveBy:create(0.3, CCPointMake(moveDis, 0))
	local moveAction2 = CCMoveBy:create(0.3, CCPointMake(moveDis, 0))

	positionLayer:runAction(CCSequence:createWithTwoActions(moveAction1, CCCallFuncN:create(enableNewMenu)))
	chgPosContainer:runAction(moveAction2)
end

function createPosbkg()
	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local scaleW = g_scaleW
	local scaleH = g_scaleH
	local positionLayer = g_charPosUI.positionLayer
	local posButtonItem = g_charPosUI.posButtonItem
	local width = scrSize.width * 0.96
	local bkg = CCSprite:create("v2/charPositionUI/max_bkg.png")
	local bkgSize = bkg:getContentSize()
	local position = posButtonItem:getPositionLua()
	local buttonSize = posButtonItem:getContentSize()
	local scaleX = width / bkgSize.width

	bkg:setScaleX(scaleX)
	bkg:setScaleY(scaleH)
	bkg:setPosition(position.x - 0.5 * buttonSize.width, position.y)
	bkg:setAnchorPoint(CCPointMake(1, 0.5))
	positionLayer:addChild(bkg)
end

headsPosition = {
	{
		x = -0.3,
		y = 0.02
	},
	{
		x = 0.37,
		y = 0.02
	},
	{
		x = 0.03,
		y = 0.37
	},
	{
		x = 0.03,
		y = -0.34
	},
	{
		x = -0.54,
		y = 0
	},
	{
		x = 0.12,
		y = 0
	},
	{
		x = -0.21,
		y = 0.37
	},
	{
		x = -0.21,
		y = -0.36
	}
}

function onTouchChaPosBegan(x, y)
	if g_ChgPosInfo.isTouchEnded == false then
		return false
	end

	g_ChgPosInfo.isTouchEnded = false

	return true
end

function onTouchChaPosMoved(x, y)
	local parent = g_ChgPosInfo.parent
	local point = parent:convertToNodeSpace(CCPointMake(x, y))

	if g_ChgPosInfo.activeHead then
		g_ChgPosInfo.activeHead:setPosition(point)
	else
		for i = 1, #g_ChgPosInfo.heads do
			local head = g_ChgPosInfo.heads[i]

			if head:boundingBox():containsPoint(point) then
				g_ChgPosInfo.activeHead = head
				g_ChgPosInfo.activeIndex = i
				g_ChgPosInfo.originalPos = g_ChgPosInfo.activeHead:getPositionLua()

				parent:reorderChild(head, 10)

				break
			end
		end
	end
end

function onTouchChaPosEnded(x, y)
	if g_ChgPosInfo.activeHead then
		local parent = g_ChgPosInfo.parent
		local point = parent:convertToNodeSpace(CCPointMake(x, y))
		local isFoundHead = false

		for i = 1, #g_ChgPosInfo.heads do
			local head = g_ChgPosInfo.heads[i]

			if i ~= g_ChgPosInfo.activeIndex and head:boundingBox():containsPoint(point) then
				changeHeads(g_ChgPosInfo.activeIndex, i)
				changeNames(g_ChgPosInfo.activeIndex, i)

				isFoundHead = true

				break
			end
		end

		if not isFoundHead then
			g_ChgPosInfo.activeHead:setPosition(g_ChgPosInfo.originalPos)
		end
	end

	g_ChgPosInfo.isTouchEnded = true
	g_ChgPosInfo.activeHead = nil
end

function changeHeads(srcIndex, desIndex)
	local src = g_ChgPosInfo.heads[srcIndex]
	local des = g_ChgPosInfo.heads[desIndex]
	local srcScale = src:getScale()
	local srcOpacity = src:getOpacity()
	local desScale = des:getScale()
	local desPosition = des:getPositionLua()
	local desOpacity = des:getOpacity()

	g_ChgPosInfo.parent:reorderChild(src, 0)
	src:setPosition(desPosition)
	src:setOpacity(desOpacity)
	src:setScale(desScale)
	des:setPosition(g_ChgPosInfo.originalPos)
	des:setOpacity(srcOpacity)
	des:setScale(srcScale)

	g_ChgPosInfo.targetOrder[desIndex] = g_ChgPosInfo.targetOrder[srcIndex]
	g_ChgPosInfo.targetOrder[srcIndex] = g_ChgPosInfo.targetOrder[desIndex]
end

function changeNames(srcIndex, desIndex)
	local srcName = g_ChgPosInfo.nameLabels[srcIndex]
	local srcNamePosition = srcName:getPositionLua()
	local desName = g_ChgPosInfo.nameLabels[desIndex]
	local desNamePosition = desName:getPositionLua()

	srcName:setPosition(desNamePosition)
	desName:setPosition(srcNamePosition)
end

function onTouchChgPos(eventType, x, y)
	local scrSize = CCDirector:sharedDirector():getVisibleSize()

	cclog("x=%f, y=%f", x / scrSize.width, y / scrSize.height)

	if not g_charPosUI.boardRect:containsPoint(CCPointMake(x, y)) then
		if g_ChgPosInfo.activeHead then
			g_ChgPosInfo.activeHead:setPosition(g_ChgPosInfo.originalPos)

			g_ChgPosInfo.isTouchEnded = true
		end

		return false
	end

	if eventType == CCTOUCHBEGAN then
		return onTouchChaPosBegan(x, y)
	elseif eventType == CCTOUCHMOVED then
		return onTouchChaPosMoved(x, y)
	else
		return onTouchChaPosEnded(x, y)
	end
end

function requestChangeOrder()
	local changeCount = 0
	local characterInfo = g_ChgPosInfo.characterInfo
	local targetOrder = g_ChgPosInfo.targetOrder
	local change_info = {}

	for i = 1, #characterInfo do
		if characterInfo[i].order ~= targetOrder[i] then
			changeCount = changeCount + 1

			table.insert(change_info, {
				id = characterInfo[i].id,
				new_order = targetOrder[i]
			})
		end
	end

	if changeCount > 0 then
		local tmpMsg = {
			flag = 5,
			count = changeCount,
			change_info = change_info
		}

		d_ms.d_u.main_server_send_msg(d_ms.d_msg_def.gscl_msg_id.msg_change_cortege_order, tmpMsg)
	end
end

function updateCombatList()
	g_lastCombat = {}

	for i = 1, 8 do
		local char = d_ms.d_lineupUI.g_usedCharacters[i]

		if char and char.character then
			g_lastCombat[i] = char.character.combat_power
		end
	end
end

function changeCharOrderSucceed()
	updateCombatList()

	if not g_isQuitBoard then
		reloadData()
		createHeader(g_lastShowOrder, true)
	end
end

function createChgPos(parent)
	g_ChgPosInfo = {}
	local chgBkg = CCSprite:create("v2/charPositionUI/position.png")

	d_ms.d_u.setStyles(chgBkg, {
		x = 0.48,
		y = 0.55
	})
	chgBkg:setScale(g_scaleW)
	parent:addChild(chgBkg)
	parent:registerScriptTouchHandler(onTouchChgPos, false, -128, true)
	parent:setTouchEnabled(true)

	g_ChgPosInfo.parent = parent
	local bkgPos = chgBkg:getPositionLua()
	local bkgSize = chgBkg:getContentSize()

	local function sceneEventHandler(eventType)
		if eventType.name == "exit" then
			requestChangeOrder()
		end
	end

	parent:registerScriptHandler(sceneEventHandler)

	local heads = {}
	local nameLabels = {}
	local targetOrder = {}
	local characterInfo = {}
	local introLabel = CCSprite:create("v2/charPositionUI/position_intro_label.png")

	d_ms.d_u.setStyles(introLabel, {
		x = 0.2,
		y = 0.9
	})
	parent:addChild(introLabel)

	for i = 1, 8 do
		local offsetX = headsPosition[i].x
		local offsetY = headsPosition[i].y
		local placePoint = CCPointMake(bkgPos.x + offsetX * bkgSize.width, bkgPos.y + offsetY * bkgSize.height)
		local cortege_count = g_charPosUI.cortege_count

		if i <= 4 then
			local headBkg = CCSprite:create("v2/charPositionUI/position_light.png")

			headBkg:setPosition(placePoint)
			parent:addChild(headBkg)
		end

		if i <= cortege_count then
			if g_charPosUI.usedCharacters[i] then
				local character = g_charPosUI.usedCharacters[i].character
				local head = d_ms.d_data.getHeadSprite(character.type, character.reborn_layer > 0)

				if i > 4 then
					head:setScale(0.8)
					head:setOpacity(150)
				end

				local headSize = head:getContentSize()
				local headScale = head:getScale()
				heads[#heads + 1] = head
				targetOrder[#targetOrder + 1] = character.order
				characterInfo[#characterInfo + 1] = character

				head:setTag(i)
				parent:addChild(head, 5)
				head:setPosition(placePoint)

				local nameBkg = CCSprite:create("v2/charPositionUI/char_name_bkg.png")

				nameBkg:setPosition(placePoint.x, placePoint.y - headSize.height * 0.7 * headScale)
				parent:addChild(nameBkg)

				local nameStr = d_ms.d_data.getNameTxt(character.type, character.reborn_layer > 0)
				local nameLabel = d_ms.d_u.createByStyle({
					font = "arial",
					fontsize = 22,
					type = "label",
					string = nameStr
				})

				nameLabel:setPosition(placePoint.x, placePoint.y - headSize.height * 0.7 * headScale)
				parent:addChild(nameLabel, 5)

				nameLabels[#nameLabels + 1] = nameLabel
			end
		else
			local isShowLock = true

			if i > 4 and cortege_count <= 4 then
				isShowLock = false
			end

			if isShowLock then
				local lock = CCSprite:create("v2/charPositionUI/lock.png")
				local square = CCSprite:create("v2/charPositionUI/square_bkg.png")
				local frame = CCSprite:create("v2/charPositionUI/frame1.png")

				lock:setPosition(placePoint)
				square:setPosition(placePoint)
				frame:setPosition(placePoint)

				if i > 4 then
					lock:setScale(0.7)
					lock:setOpacity(180)
					square:setScale(0.7)
					square:setOpacity(180)
					frame:setScale(0.7)
					frame:setOpacity(180)
				end

				parent:addChild(lock, 7)
				parent:addChild(square, 5)
				parent:addChild(frame, 5)
			end
		end
	end

	g_ChgPosInfo.heads = heads
	g_ChgPosInfo.nameLabels = nameLabels
	g_ChgPosInfo.targetOrder = targetOrder
	g_ChgPosInfo.characterInfo = characterInfo
end

local chgCharDataTable = {}
local charHeaderMenuSize = CCSizeMake(0.5 * scrSize.width, 0.15 * scrSize.height)

function sortChar(a, b)
	if a.csvInfo.quality == b.csvInfo.quality then
		if a.level == b.level then
			return b.csvInfo.name < a.csvInfo.name
		else
			return b.level < a.level
		end
	else
		return b.csvInfo.quality < a.csvInfo.quality
	end
end

local function createChgCharHeaderMenu(parent)
	d_ms.d_data.createCommonFilterMenu(parent, d_ms.d_filterLayer.TAG.Cortege_Idle, ccp(charHeaderMenuSize.width * 0.8, charHeaderMenuSize.height * 0.5), ensureChgCharFilter, chgCharDataTable.currentFilter)
end

local function createCellOnChgChar(parent, charInfo, bkgPic, cellSize)
	d_ms.d_createCell.createCommonCharCells(parent, charInfo, bkgPic, cellSize)

	if isHaveFateWithCurrentChar(o_t.cortege, charInfo.type) then
		local fateSprite = CCSprite:create("v2/charPositionUI/fate.png")

		fateSprite:setPosition(cellSize.width * 0.12, cellSize.height * 0.35)
		fateSprite:setScale(0.7)
		parent:addChild(fateSprite, 10)
	end

	if charInfo.cheer_order and charInfo.cheer_order > 0 then
		local tip = gethz("cheer_str5_pre" .. math.floor((charInfo.cheer_order - 1) / d_ms.d_cheerSquadUI.g_self.COUNT)) .. string.format(gethz("cheer_str5"), d_ms.d_cheerSquadUI.getCheerLetter(charInfo.cheer_order))
		local tipLabel = d_ms.d_u.createByStyle({
			font = "arial",
			fontsize = 26,
			type = "label",
			string = tip
		})

		tipLabel:setPosition(cellSize.width * 0.85, cellSize.height * 0.7)
		parent:addChild(tipLabel, 5)
	end

	local function requestChangeCharWrap()
		requestChangeChar(charInfo)
	end

	local changeCharItem = nil

	if g_charPosUI.usedCharacters[g_lastShowOrder] then
		changeCharItem = CCMenuItemImage:create("v2/charPositionUI/a_change1.png", "v2/charPositionUI/a_change2.png")
	else
		changeCharItem = CCMenuItemImage:create("v2/introUI/replace1.png", "v2/introUI/replace2.png")
	end

	changeCharItem:setPosition(cellSize.width * 0.85, cellSize.height * 0.25)
	changeCharItem:registerScriptTapHandler(requestChangeCharWrap)

	local changeMenu = CCMenu:createWithItem(changeCharItem)

	changeMenu:setPosition(0, 0)
	parent:addChild(changeMenu, 5)
end

local function getChgCharCellsDataSource(charsInfo)
	local cellSize = CCSizeMake(0.5 * scrSize.width, 0.2 * scrSize.height)
	local bkgPic = "v2/charPositionUI/char_info.png"
	local dataSource = {}
	local num = #charsInfo

	function dataSource.tableViewNumberOfRows()
		return num + 1
	end

	chgCharDataTable.currentChgChars = charsInfo

	function dataSource.drawCellAtIndex(index)
		local cell = CCNode:create()

		if index == 1 then
			createChgCharHeaderMenu(cell)
		elseif charsInfo[index - 1] then
			createCellOnChgChar(cell, charsInfo[index - 1], bkgPic, cellSize)
		end

		return cell
	end

	function dataSource.heightForRowAtIndex(index)
		if index == 1 then
			return charHeaderMenuSize.height
		else
			return cellSize.height
		end
	end

	return dataSource
end

function ensureChgCharFilter(filter)
	local chgCharTableView = chgCharDataTable.chgCharTableView

	if not chgCharTableView then
		return
	end

	local check = d_ms.d_filterLayer.check
	chgCharDataTable.currentFilter = filter
	local forChgChars = chgCharDataTable.forChgChars

	if not forChgChars then
		return
	end

	local afterFilterChars = {}

	for i = 1, #forChgChars do
		if check and check(forChgChars[i], filter) then
			afterFilterChars[#afterFilterChars + 1] = forChgChars[i]
		end
	end

	local dataSource = getChgCharCellsDataSource(afterFilterChars)

	chgCharTableView:reloadData(dataSource)
end

function showChgCharLayer()
	cclog("show chg char layer")

	if g_isShowPosLayer then
		return
	end

	g_charPosUI.close_board:setVisible(false)

	g_isShowChgCharLayer = true
	local board_layer = g_charPosUI.board_layer
	local charLayer = g_charPosUI.charLayer
	local positionLayer = g_charPosUI.positionLayer
	local chgCharLayer = g_charPosUI.chgCharLayer
	local rect = g_charPosUI.boardRect
	rect.size.width = scrSize.width
	rect.origin.x = 0

	local function onSwallowTouch(eventType, x, y)
		if not rect:containsPoint(CCPointMake(x, y)) then
			return false
		end

		return true
	end

	chgCharLayer:registerScriptTouchHandler(onSwallowTouch, false, -128, true)
	chgCharLayer:setTouchEnabled(true)

	local chgCharButtonItem = g_charPosUI.chgCharButtonItem
	local chgCharHZ = chgCharLayer:getChildByTag(tagDef.chgCharHZ)

	chgCharHZ:setVisible(false)
	chgCharButtonItem:setEnabled(false)

	local bkg = createChgCharbkg()
	local charsInfo = d_ms.d_c.table_copy(d_ms.d_lineupUI.g_characterInfo)
	local count = #charsInfo

	for i = count, 1, -1 do
		charsInfo[i].object_type = o_t.cortege

		if charsInfo[i].order ~= 0 then
			table.remove(charsInfo, i)
		end
	end

	table.sort(charsInfo, sortChar)

	local board_size = g_charPosUI.board_size
	local board_layer = g_charPosUI.board_layer
	local forChgCharsLayer = CCLayer:create()

	board_layer:addChild(forChgCharsLayer, 10)

	local function sceneEventHandler(eventType)
		if eventType.name == "exit" then
			chgCharDataTable = {}
		end
	end

	forChgCharsLayer:registerScriptHandler(sceneEventHandler)

	local touchArea = {
		x = scrSize.width * 0.47,
		y = board_size.y,
		width = board_size.width * 0.52,
		height = board_size.height
	}
	local chgCharTableView = d_ms.d_tableView.tableView(forChgCharsLayer, touchArea)
	local cellsContainer = chgCharTableView:getContainerLayer()
	local containerPos = cellsContainer:getPositionLua()

	cellsContainer:setPosition(touchArea.width, containerPos.y)

	if #charsInfo <= 0 then
		local hintLabel = d_ms.d_u.createByStyle({
			font = "arial",
			fontsize = 26,
			type = "label",
			string = gethz("noUsableGod")
		})

		hintLabel:setPosition(touchArea.width * 0.5, touchArea.height * 0.5)
		cellsContainer:addChild(hintLabel, 10)
	else
		chgCharDataTable.chgCharTableView = chgCharTableView
		chgCharDataTable.forChgChars = charsInfo
		local dataSource = getChgCharCellsDataSource(charsInfo)

		if not d_ms.d_mainUI.g_isNeedGuide then
			chgCharTableView:startScroll()
		end

		chgCharTableView:setDataSource(dataSource)
	end

	local backHZ = CCSprite:create("v2/charPositionUI/backHZ.png")

	d_ms.d_u.setStyles(backHZ, {
		x = 0.91,
		y = 0.41
	})
	chgCharLayer:addChild(backHZ, 5)

	local backMenu = nil

	local function closeChgCharLayer()
		backMenu:setEnabled(false)
		board_layer:removeChild(charMask, true)

		local moveAction1 = CCMoveBy:create(0.3, d_ms.d_u.makePoint(0.22, 0))
		local moveAction2 = CCMoveBy:create(0.3, d_ms.d_u.makePoint(0.52, 0))
		local moveAction3 = CCMoveBy:create(0.3, d_ms.d_u.makePoint(0.22, 0))
		local moveAction4 = CCMoveBy:create(0.3, CCPointMake(touchArea.width, 0))

		charLayer:runAction(moveAction1)
		chgCharLayer:runAction(moveAction2)
		positionLayer:runAction(moveAction3)

		local swallowLayer = d_ms.d_u.createSwallowTouchLayer(chgCharLayer)

		chgCharTableView:explictUnscheduleHandler()

		local function afterMoveCleanup()
			g_isShowChgCharLayer = false

			board_layer:removeChild(forChgCharsLayer, true)
			chgCharButtonItem:setEnabled(true)
			chgCharHZ:setVisible(true)
			chgCharLayer:setTouchEnabled(false)

			if g_charPosUI.close_board then
				g_charPosUI.close_board:setVisible(true)
			end

			chgCharLayer:removeChild(backHZ, true)
			chgCharLayer:removeChild(bkg, true)
			chgCharLayer:removeChild(backMenu, true)
			chgCharLayer:removeChild(swallowLayer, true)
		end

		cellsContainer:runAction(CCSequence:createWithTwoActions(moveAction4, CCCallFuncN:create(afterMoveCleanup)))
	end

	local backButtonItem = CCMenuItemImage:create("v2/charPositionUI/arrow_menu.png", "v2/charPositionUI/arrow_menu.png")

	d_ms.d_u.setStyles(backButtonItem, {
		x = 0.92,
		y = 0.41
	})
	backButtonItem:setScale(g_scaleH)
	backButtonItem:registerScriptTapHandler(closeChgCharLayer)

	backMenu = CCMenu:createWithItem(backButtonItem)

	backMenu:setPosition(0, 0)
	chgCharLayer:addChild(backMenu)

	g_charPosUI.chgCharCloseMenuItem = backButtonItem

	backButtonItem:setEnabled(false)

	local swallowLayer = d_ms.d_u.createSwallowTouchLayer(chgCharLayer)

	local function afterShow()
		if d_ms.d_mainUI.g_isNeedGuide then
			d_ms.d_guideUI.show()
		end

		chgCharLayer:removeChild(swallowLayer, true)
		backButtonItem:setEnabled(true)
	end

	local moveAction1 = CCMoveBy:create(0.3, d_ms.d_u.makePoint(-0.22, 0))
	local moveAction2 = CCMoveBy:create(0.3, d_ms.d_u.makePoint(-0.52, 0))
	local moveAction3 = CCMoveBy:create(0.3, d_ms.d_u.makePoint(-0.22, 0))
	local moveAction4 = CCMoveBy:create(0.3, CCPointMake(-touchArea.width, 0))

	charLayer:runAction(moveAction1)
	positionLayer:runAction(moveAction3)
	chgCharLayer:runAction(CCSequence:createWithTwoActions(moveAction2, CCCallFuncN:create(afterShow)))
	cellsContainer:runAction(moveAction4)
end

function createChgCharbkg()
	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local scaleW = g_scaleW
	local scaleH = g_scaleH
	local chgCharLayer = g_charPosUI.chgCharLayer
	local chgCharButtonItem = g_charPosUI.chgCharButtonItem
	local width = scrSize.width * 0.54
	local bkg = CCSprite:create("v2/charPositionUI/max_bkg.png")
	local bkgSize = bkg:getContentSize()
	local position = chgCharButtonItem:getPositionLua()
	local buttonSize = chgCharButtonItem:getContentSize()
	local scaleX = width / bkgSize.width

	bkg:setScaleX(scaleX)
	bkg:setScaleY(scaleH)
	bkg:setPosition(position.x + 0.5 * buttonSize.width, position.y)
	bkg:setAnchorPoint(CCPointMake(0, 0.5))
	chgCharLayer:addChild(bkg)

	return bkg
end

local function createCharCell(charInfo, cellPosX, cellPosY, cellsLayer)
	local cellNode = CCNode:create()
	local bkg = CCSprite:create("v2/charPositionUI/char_info.png")
	local bkgSize = bkg:getContentSize()

	cellNode:setPosition(cellPosX - bkgSize.width * 0.5, cellPosY - bkgSize.height)
	bkg:setPosition(bkgSize.width * 0.5, 0.5 * bkgSize.height)
	cellNode:addChild(bkg)

	g_changeCharList[#g_changeCharList + 1] = charInfo
	local charSprite1 = d_ms.d_data.getHeadSprite(charInfo.type, charInfo.reborn_layer > 0)
	local charSprite2 = d_ms.d_data.getHeadSprite(charInfo.type, charInfo.reborn_layer > 0)
	local charMenuItem = CCMenuItemSprite:create(charSprite1, charSprite2)

	charMenuItem:registerScriptTapHandler(showCharDetail)
	charMenuItem:setTag(#g_changeCharList)
	charMenuItem:setPosition(bkgSize.width * 0.15, bkgSize.height * 0.5)

	local charMenu = CCMenu:createWithItem(charMenuItem)

	charMenu:setPosition(0, 0)
	cellNode:addChild(charMenu, 5)

	local charName = charInfo.csvInfo.name
	local charNameLabel = d_ms.d_u.createByStyle({
		font = "arial",
		fontsize = 26,
		type = "label",
		string = charName
	})

	charNameLabel:setPosition(bkgSize.width * 0.3, bkgSize.height * 0.75)
	charNameLabel:setAnchorPoint(CCPointMake(0, 0.5))
	cellNode:addChild(charNameLabel, 5)

	local qualityRatio = charInfo.csvInfo.quality / 5
	local starsLevelSprite = CCSprite:create("v2/introUI/stars.png")

	starsLevelSprite:setPosition(bkgSize.width * 0.3, bkgSize.height * 0.5)
	starsLevelSprite:setAnchorPoint(CCPointMake(0, 0.5))

	local starsContentSize = starsLevelSprite:getContentSize()

	starsLevelSprite:setTextureRect(CCRectMake(0, 0, starsContentSize.width * qualityRatio, starsContentSize.height))
	cellNode:addChild(starsLevelSprite)

	local levelSprite = CCSprite:create("v2/introUI/level.png")

	levelSprite:setPosition(bkgSize.width * 0.3, bkgSize.height * 0.25)
	levelSprite:setAnchorPoint(CCPointMake(0, 0.5))
	cellNode:addChild(levelSprite, 5)

	local level = charInfo.level
	local levelLabel = d_ms.d_u.createByStyle({
		font = "arial",
		fontsize = 26,
		type = "label",
		string = tostring(level)
	})

	levelLabel:setPosition(bkgSize.width * 0.37, bkgSize.height * 0.25)
	levelLabel:setAnchorPoint(CCPointMake(0, 0.5))
	cellNode:addChild(levelLabel, 5)

	local changeCharItem = nil

	if g_charPosUI.usedCharacters[g_lastShowOrder] then
		changeCharItem = CCMenuItemImage:create("v2/charPositionUI/a_change1.png", "v2/charPositionUI/a_change2.png")
	else
		changeCharItem = CCMenuItemImage:create("v2/introUI/replace1.png", "v2/introUI/replace2.png")
	end

	changeCharItem:setPosition(bkgSize.width * 0.8, bkgSize.height * 0.25)
	changeCharItem:registerScriptTapHandler(requestChangeChar)

	if d_ms.d_mainUI.g_isNeedGuide then
		local pos1 = changeCharItem:getPositionLua()
		local pos2 = cellNode:convertToWorldSpace(pos1)
		local pos3 = cellsLayer.scrollView:convertToWorldSpace(pos2)
		g_changeCharMenuPos = pos3
		g_changeCharMenu = changeCharItem
		local bkgPos1 = bkg:getPositionLua()
		bkgPos1 = cellNode:convertToWorldSpace(bkgPos1)
		local bkgPos2 = cellsLayer.C:convertToWorldSpace(bkgPos1)
		g_chgCharBkgSize = bkgSize
		g_chgCharBkgWorldPos = bkgPos2
	end

	local changeMenu = CCMenu:createWithItem(changeCharItem)

	changeMenu:setPosition(0, 0)
	cellNode:addChild(changeMenu, 5)

	if isHaveFateWithCurrentChar(o_t.cortege, charInfo.type) then
		local menuSize = charMenuItem:getContentSize()
		local menuPos = charMenuItem:getPositionLua()
		local fateSprite = CCSprite:create("v2/charPositionUI/fate.png")

		fateSprite:setPosition(menuPos.x + menuSize.width * 0.26, menuPos.y - menuSize.height * 0.27)
		cellNode:addChild(fateSprite, 10)
	end

	changeCharItem:setTag(#g_changeCharList)

	return cellNode, bkgSize
end

function createChgCharCells(cellsLayer, totalWidth, totalHeight)
	local charInfo = d_ms.d_c.table_copy(d_ms.d_lineupUI.g_characterInfo)
	local scrSize = CCDirector:sharedDirector():getVisibleSize()

	table.sort(charInfo, sortChar)

	local width = totalWidth
	local height = totalHeight
	local offset = 0.01 * scrSize.height
	local cellPosY = height - 2 * offset
	local cellPosX = width * 0.5
	g_changeCharList = {}
	local cellsCount = 0
	local firstShow = 16
	local count = math.min(firstShow, #charInfo)

	for i = 1, count do
		if charInfo[i].order == 0 then
			cellsCount = cellsCount + 1

			if charInfo[i] then
				local node, size = createCharCell(charInfo[i], cellPosX, cellPosY, cellsLayer)
				cellPosY = cellPosY - size.height - offset

				cellsLayer:addCell(node, {
					width = size.width,
					height = size.height + offset
				})
			end
		end
	end

	local showIndex = firstShow + 1

	function d_ms.d_inertiaLayer.scrollViewHelper.scrollViewDidScroll()
		if showIndex > #charInfo then
			return
		end

		if charInfo[showIndex] and charInfo[showIndex].order == 0 then
			local node, size = createCharCell(charInfo[showIndex], cellPosX, cellPosY, cellsLayer)
			cellPosY = cellPosY - size.height - offset

			cellsLayer:addCell(node, {
				width = size.width,
				height = size.height + offset
			})
		end

		showIndex = showIndex + 1
	end

	return cellsCount
end

function showCharDetail(tag)
	if not g_charPosUI.isOtherPage then
		d_ms.d_formationUI.showIntroduceLayer(g_charPosUI.main_layer, g_changeCharList[tag], 40)
	end
end

function requestChangeChar(charInfo)
	if d_ms.d_mainUI.g_isNeedGuide == true then
		local tmpRequest = {
			stage = d_ms.d_common_def.new_role_guide.change_cortege,
			name = string.format("%0.0f", charInfo.id),
			head_type = 0
		}

		cclog("\\xb3\\xf5\\xb4θ\\xfc\\xbb\\xbb\\xb5\\xdc\\xd7\\xd3")
		d_ms.d_u.main_server_send_msg(d_ms.d_msg_def.gscl_msg_id.msg_new_role_guide, tmpRequest)

		return
	end

	local tmpMsg = {
		flag = 4,
		count = 1,
		change_info = {
			{
				id = charInfo.id,
				new_order = g_lastShowOrder
			}
		}
	}

	d_ms.d_u.main_server_send_msg(d_ms.d_msg_def.gscl_msg_id.msg_change_cortege_order, tmpMsg)
end

function changeCharSucceed()
	reloadData()
	g_charPosUI.chgCharCloseMenuItem:activate()
	createHeader(g_lastShowOrder, true)
end

function reloadData()
	if not d_ms.d_packageUI.g_isPackageSorted then
		d_ms.d_packageUI.sortItems()
	end

	if g_charPosUI then
		g_charPosUI.usedCharacters = d_ms.d_lineupUI.g_usedCharacters
		g_charPosUI.allUsedItems = d_ms.d_packageUI.g_usedItems
		g_charPosUI.all_cheer_skills = d_ms.d_packageUI.g_cheer_items
		g_charPosUI.cheerCharacters = d_ms.d_lineupUI.g_cheerCharacters
		g_charPosUI.cortege_count = d_ms.d_mainUI.g_playerInfo.cortege_count
		g_charPosUI.isReadOnly = false
	end
end

function reLoadStatsBar()
	if not g_isQuitBoard then
		reloadData()

		local characterInfo = g_charPosUI.usedCharacters[g_lastShowOrder].character

		g_statsTable[1]:setString(tostring(characterInfo.hp))
		g_statsTable[2]:setString(tostring(characterInfo.gongji))
		g_statsTable[3]:setString(tostring(characterInfo.fangyu))
		g_statsTable[4]:setString(tostring(characterInfo.magic))
	end
end

function reloadItemSkillInfo()
	if not g_isShowItemChangeLayer then
		reloadItemSkillLevel()
	end
end

function reloadItemSkillLevel()
	reloadData()
	createHeader(g_lastShowOrder, true)
end

function reloadItemSkillAllInfo()
	return
end

function getMyInfo()
	local displayLineupInfo = {
		parent = d_ms.d_checkLineupUI.displayLineupInfo.parent,
		info = d_ms.d_mainUI.g_playerInfo,
		usedCharacters = d_ms.d_lineupUI.g_usedCharacters,
		cheerCharacters = d_ms.d_lineupUI.g_cheerCharacters,
		allUsedItems = d_ms.d_packageUI.g_usedItems,
		all_cheer_skills = d_ms.d_packageUI.g_cheer_items,
		cortege_count = d_ms.d_mainUI.g_playerInfo.cortege_count
	}
	displayLineupInfo.info.isMe = true

	if d_ms.d_checkLineupUI.displayLineupInfo.info.grid_count and d_ms.d_landUI.g_self.prey_info and d_ms.d_landUI.g_self.prey_info.grid_count then
		displayLineupInfo.info.grid_count = d_ms.d_landUI.g_self.prey_info.grid_count
	end

	return displayLineupInfo
end

function gotoCheerSquadUI(tag)
	local parent = g_charPosUI.parent

	if g_charPosUI.isReadOnly then
		d_ms.d_cheerSquadUI.processOthersInfo()
	elseif not d_ms.d_cheerSquadUI.canJoin(d_ms.d_mainUI.g_playerInfo.level, true) then
		return
	end

	if false and d_ms.d_u.isWin32() then
		local t = d_ms.d_cheerSquadUI.g_self
		local p = d_ms.d_cheerSquadUI.g_cheerSquadUI.readOnly

		d_ms.d_u.reload_lua(d_ms.d_cheerSquadUI, "ui.cheerSquadUI")

		d_ms.d_cheerSquadUI.g_self = t
		d_ms.d_cheerSquadUI.g_cheerSquadUI.readOnly = p
	end

	d_ms.d_cheerSquadUI.show(parent, tag)
end

function compareCharPosition()
	if g_charPosUI.playerInfo.isMe then
		showOthersCharIntro(d_ms.d_checkLineupUI.displayLineupInfo)
	else
		showOthersCharIntro(getMyInfo())
	end
end

function showOthersInfo(info)
	local isMe = g_charPosUI.playerInfo.isMe
	local union_name = info.union_name or gethz("no")
	local tao_point = info.tao_point or 0
	local combat_power = info.role_combat_power or 0
	local board_layer = g_charPosUI.board_layer
	local lframe = d_ms.d_u.createByStyle({
		pic = "v2/charPositionUI/lframe.png",
		y = 0.805,
		x = 0.11,
		scaleY = 0.64,
		anchor = {
			0.5,
			1
		}
	})

	board_layer:addChild(lframe, 0)

	local nameLabel = d_ms.d_u.createByStyle({
		font = "arial",
		y = 0.72,
		type = "label",
		x = 0.11,
		fontsize = 26,
		string = info.name or info.role_name,
		color = {
			255,
			242,
			187
		}
	})

	board_layer:addChild(nameLabel, 1)

	local height = nameLabel:getContentSize().height * nameLabel:getScale()

	if info.vip_level ~= nil and info.vip_level > 0 then
		local vip_label = CCSprite:create("v2/vip/vip_label.png")
		local vip_label_width = vip_label:getContentSize().width
		local vip_level_sp, vip_level_width = d_ms.d_data.getNumberSprite(info.vip_level)

		d_ms.d_u.setStyles(vip_label, {
			y = 0.76,
			x = 0.11 - 0.5 * vip_level_width / 1280 - 0.003
		})
		d_ms.d_u.setStyles(vip_level_sp, {
			y = 0.76,
			x = 0.11 + 0.5 * vip_label_width / 1280 + 0.003
		})
		board_layer:addChild(vip_label)
		board_layer:addChild(vip_level_sp)
	end

	if info.union_rank and info.union_rank > 0 and info.union_rank <= d_ms.d_common_def.union_rank_type.super then
		local hzs = {
			"mengzhu",
			"hufa",
			"zhanglao",
			"jingying"
		}

		board_layer:addChild(d_ms.d_u.createByStyles({
			pic = "v2/charPositionUI/rank_bkg.png",
			scaleY = 0.05,
			x = 0.11,
			y = 0.66
		}))
		board_layer:addChild(d_ms.d_u.createByStyle({
			y = 0.66,
			font = "arial",
			type = "label",
			x = 0.11,
			fontsize = 26,
			string = gethz(hzs[info.union_rank]),
			color = {
				200,
				104,
				2
			}
		}))
	end

	local left_x = {
		0.04,
		0.065
	}
	local my = 0.51
	local dy = 0.05

	board_layer:addChild(d_ms.d_u.createByStyles({
		pic = "v2/charPositionUI/mid_frame.png",
		scaleY = 0.22,
		x = 0.11,
		y = my
	}), 1)
	board_layer:addChild(d_ms.d_u.createByStyles({
		pic = "v2/charPositionUI/level_label.png",
		x = left_x[1],
		y = my + 1.5 * dy,
		anchor = {
			0,
			0.5
		}
	}), 1)
	board_layer:addChild(d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		fontsize = 26,
		string = info.level,
		color = {
			181,
			181,
			181
		},
		x = left_x[2],
		y = my + 1.5 * dy,
		anchor = {
			0,
			0.5
		}
	}), 1)
	board_layer:addChild(d_ms.d_u.createByStyles({
		pic = "v2/charPositionUI/combat.png",
		x = left_x[1],
		y = my + 0.5 * dy,
		anchor = {
			0,
			0.5
		}
	}), 1)
	board_layer:addChild(d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		fontsize = 26,
		string = combat_power,
		color = {
			181,
			181,
			181
		},
		x = left_x[2],
		y = my + 0.5 * dy,
		anchor = {
			0,
			0.5
		}
	}), 1)
	board_layer:addChild(d_ms.d_u.createByStyles({
		pic = "v2/achievementsUI/tao.png",
		x = left_x[1],
		y = my - 0.5 * dy,
		anchor = {
			0,
			0.5
		}
	}), 1)
	board_layer:addChild(d_ms.d_u.createByStyle({
		font = "arial",
		type = "label",
		fontsize = 26,
		string = tao_point,
		color = {
			181,
			181,
			181
		},
		x = left_x[2],
		y = my - 0.5 * dy,
		anchor = {
			0,
			0.5
		}
	}), 1)

	if not isMe then
		board_layer:addChild(d_ms.d_u.createByStyles({
			pic = "v2/charPositionUI/union_label.png",
			x = left_x[1],
			y = my - 1.5 * dy,
			anchor = {
				0,
				0.5
			}
		}), 1)
		board_layer:addChild(d_ms.d_u.createByStyle({
			font = "arial",
			type = "label",
			fontsize = 22,
			string = union_name,
			x = left_x[2],
			y = my - 1.5 * dy,
			anchor = {
				0,
				0.5
			},
			color = {
				181,
				181,
				181
			}
		}), 1)
	end

	local function gotoAchieveUI()
		d_ms.d_achieveUI.g_self.otherAchieveShow.info = info

		d_ms.d_achieveUI.show(false, g_charPosUI.board_layer, 100)
	end

	local function checkOthersAchieve()
		d_ms.d_achieveUI.g_self.otherCallBack = gotoAchieveUI

		if info and info.id then
			local tmp = {
				des_role_id = info.id,
				flag = info.isCrossRank and 1 or 0
			}

			d_ms.d_u.main_server_send_msg(d_ms.d_msg_def.gscl_msg_id.msg_query_achievements, tmp)
		end
	end

	local function compareCharposition()
		if isMe then
			showOthersCharIntro(d_ms.d_checkLineupUI.displayLineupInfo)
		else
			showOthersCharIntro(getMyInfo(), nil, true)
		end
	end

	local menu_btn_list = {
		x = 0,
		y = 0
	}

	if isMe then
		table.insert(menu_btn_list, {
			npic = "v2/charPositionUI/yours1.png",
			spic = "v2/charPositionUI/yours2.png",
			y = 0.87,
			x = 0.11,
			call_back = compareCharposition
		})
	else
		table.insert(menu_btn_list, {
			npic = "v2/charPositionUI/mine1.png",
			spic = "v2/charPositionUI/mine2.png",
			y = 0.24,
			x = 0.11,
			call_back = compareCharposition
		})

		if info and info.id and info.id ~= d_ms.d_mainUI.g_playerInfo.role_id then
			table.insert(menu_btn_list, {
				npic = "v2/charPositionUI/check_achieve1.png",
				spic = "v2/charPositionUI/check_achieve2.png",
				y = 0.34,
				x = 0.11,
				call_back = checkOthersAchieve
			})
		end
	end

	board_layer:addChild(d_ms.d_u.createMenu(menu_btn_list), 10)
end

function resetInputBox(isMoveAway)
	cclog("move away input box0")

	if not d_ms.d_u.isIOS() then
		return
	end

	cclog("move away input box1")

	local followUI = d_ms.d_followUI
	local isInFollowPage = followUI.g_isInThisBoard
	local isInSearchLayer = followUI.g_isInOtherPlayerPage

	if isInFollowPage and isInSearchLayer then
		cclog("move away input box2")

		local inputBox = d_ms.d_followUI.g_inputbox

		if inputBox then
			cclog("move away input box3")

			if isMoveAway then
				cclog("move away input box")
				d_ms.d_u.setStyles(inputBox, {
					x = 0.5,
					y = 1.91
				})
			else
				d_ms.d_u.setStyles(inputBox, {
					x = 0.5,
					y = 0.91
				})
			end
		end
	end
end

function showOthersCharIntro(displayLineupInfo, showOrder, hideHeadFrame)
	local parent = displayLineupInfo.parent
	local checkLayerTag = d_ms.d_data.getTagFromDef("checkLineup")

	parent:removeChildByTag(checkLayerTag, true)

	local checkLayer = CCLayer:create()

	checkLayer:setTag(checkLayerTag)
	parent:addChild(checkLayer, 100)

	local function onSwallowTouch(eventType, x, y)
		cclog("onTouch others char layer")

		return true
	end

	checkLayer:registerScriptTouchHandler(onSwallowTouch, false, -128, true)
	checkLayer:setTouchEnabled(true)

	g_charPosUI = {
		playerInfo = displayLineupInfo.info,
		usedCharacters = displayLineupInfo.usedCharacters,
		cheerCharacters = displayLineupInfo.cheerCharacters,
		allUsedItems = displayLineupInfo.allUsedItems,
		cortege_count = displayLineupInfo.cortege_count,
		all_cheer_skills = displayLineupInfo.all_cheer_skills,
		isReadOnly = true,
		parent = checkLayer
	}

	if displayLineupInfo.info.grid_count then
		g_charPosUI.grid_count = displayLineupInfo.info.grid_count
	end

	local info = displayLineupInfo.info

	for i = 1, #g_charPosUI.usedCharacters do
		local char = g_charPosUI.usedCharacters[i].character

		if not char.cur_exp or not char.next_exp then
			local exp_tab = d_ms.d_data.g_characterExpTable
			char.next_exp = exp_tab[char.csvInfo.quality][char.level]
			char.cur_exp = math.floor(char.next_exp * math.random(1, 99) / 100)
		end
	end

	g_scaleW = d_ms.d_mainUI.g_scaleW
	g_scaleH = d_ms.d_mainUI.g_scaleH
	local board_layer = CCLayer:create()

	checkLayer:addChild(board_layer)

	g_charPosUI.board_layer = board_layer

	resetInputBox(true)

	local function sceneEventHandler(eventType)
		if eventType.name == "exit" then
			g_charPosUI = {}
			g_lastShowOrder = 0

			resetInputBox(false)
		end
	end

	board_layer:registerScriptHandler(sceneEventHandler)

	local position = {
		x = 0.5,
		y = 0.56
	}
	local scaleXY = {
		scaleY = 0.82,
		scaleX = 0.97
	}
	local board_size = d_ms.d_mainUI.createBoardBkg(board_layer, position, scaleXY, false, {
		noLeftBkg = true,
		noSplit = true,
		noClose = true
	})
	g_charPosUI.board_size = board_size
	g_charPosUI.boardRect = CCRectMake(board_size.x, board_size.y, board_size.width, board_size.height)
	g_charPosUI.board_bkg_h = board_size.height / scrSize.height
	g_charPosUI.board_bkg_w = board_size.width / scrSize.width
	local charLayer = CCLayer:create()
	g_charPosUI.charLayer = charLayer

	board_layer:addChild(charLayer, 2)

	local function closeCallBack()
		d_ms.d_music_mgr.playClickEffect()

		local function removeCallBack()
			parent:removeChild(checkLayer, true)
		end

		d_ms.d_mainUI.foldBoardAction(board_layer, removeCallBack)
	end

	g_lastShowOrder = showOrder or 0

	showOthersInfo(info)
	createCloseMenu(closeCallBack)
	createHeader(nil, nil, hideHeadFrame)
	d_ms.d_mainUI.runBoardAction(board_layer)
end

function tapOtherHeadButton(tag)
	local parent = g_charPosUI.charLayer

	if tag == -1 and not g_charPosUI.isReadOnly then
		return
	end

	if g_lastShowOrder and g_lastShowOrder ~= 0 then
		local lastSelectedFrame = parent:getChildByTag(tagDef.headSelect)

		if g_headSprite[g_lastShowOrder] then
			g_headSprite[g_lastShowOrder]:setOpacity(120)
		end

		if lastSelectedFrame then
			parent:removeChild(lastSelectedFrame, true)
		end
	end

	local currentSelected = g_headButtons[tag]
	g_lastShowOrder = tag

	if g_headSprite[tag] then
		g_headSprite[tag]:setOpacity(255)
	end

	local buttonPos = currentSelected:getPositionLua()
	local selectSprite = CCSprite:create("v2/charPositionUI/choose.png")

	selectSprite:setScale(currentSelected:getScale())
	selectSprite:setPosition(buttonPos)
	parent:addChild(selectSprite, 5)
	selectSprite:setTag(tagDef.headSelect)

	local charInfoLayer = parent:getChildByTag(tagDef.charInfo)

	if charInfoLayer then
		charInfoLayer:removeAllChildrenWithCleanup(true)
	else
		charInfoLayer = CCLayer:create()

		parent:addChild(charInfoLayer, 10)
		charInfoLayer:setTag(tagDef.charInfo)
	end

	g_charPosUI.charInfoLayer = charInfoLayer

	createOtherCharInfo(tag, charInfoLayer)
end

function isHaveFateWithCurrentChar(object_type, type_id)
	local currentCharFate = g_currentCharFate

	if not g_currentCharFate then
		return
	end

	for i = 1, #currentCharFate do
		if object_type == currentCharFate[i].targetType then
			for j = 1, #currentCharFate[i].targetListTable do
				if type_id == tonumber(currentCharFate[i].targetListTable[j]) then
					return true
				end
			end
		end
	end

	return false
end

function packageSortFunc(a, b)
	if a.csvInfo.quality == b.csvInfo.quality then
		if a.level == b.level then
			return b.csvInfo.name < a.csvInfo.name
		else
			return b.level < a.level
		end
	else
		return b.csvInfo.quality < a.csvInfo.quality
	end
end

function skillSortFunc(a, b)
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
