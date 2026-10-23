local require = require
local bits = bits
local sqlite = sqlite
local type = type
local print = print
local tostring = tostring
local pairs = pairs
local ipairs = ipairs
local string = string
local math = math
local CCLuaLog = CCLuaLog
local tolua = tolua
local os = os
local loadstring = loadstring
local xpcall = xpcall
local pcall = pcall
local assert = assert
local ccc3 = ccc3
local package = package
local CCArray = CCArray
local CCDirector = CCDirector
local CCLayer = CCLayer
local CCMenu = CCMenu
local CCScene = CCScene
local CCMenuItemImage = CCMenuItemImage
local CCSprite = CCSprite
local CCLabelTTF = CCLabelTTF
local CCTextFieldTTF = CCTextFieldTTF
local CCTOUCHBEGAN = CCTOUCHBEGAN
local CCTOUCHMOVED = CCTOUCHMOVED
local CCSpriteFrame = CCSpriteFrame
local CCTextureCache = CCTextureCache
local CCAnimate = CCAnimate
local CCAnimation = CCAnimation
local CCSequence = CCSequence
local CCRepeat = CCRepeat
local CCRepeatForever = CCRepeatForever
local CCActionInterval = CCActionInterval
local CCPointMake = CCPointMake
local CCRectMake = CCRectMake
local CCSizeMake = CCSizeMake
local ccColor3B = ccColor3B
local CCLabelBMFont = CCLabelBMFont
local CCApplication = CCApplication
local CCDictionary = CCDictionary
local CCDelayTime = CCDelayTime
local CCBReader = CCBReader
local CCNodeLoaderLibrary = CCNodeLoaderLibrary
local CCBAnimationManager = CCBAnimationManager
local CCCallFuncN = CCCallFuncN
local CCSequence = CCSequence
local CCMoveBy = CCMoveBy
local CCMoveTo = CCMoveTo
local ccBlendFunc = ccBlendFunc
local CCScaleTo = CCScaleTo
local CCScaleBy = CCScaleBy
local CCTintTo = CCTintTo
local CCSpriteFrameCache = CCSpriteFrameCache
local CCEaseOut = CCEaseOut
local CCEaseIn = CCEaseIn
local CCEaseInOut = CCEaseInOut
local CCEaseBackOut = CCEaseBackOut
local CCEaseBackIn = CCEaseBackIn
local CCEaseBackInOut = CCEaseBackInOut
local main_server = main_server
local CCMenuItemSprite = CCMenuItemSprite
local CCTextureCache = CCTextureCache
local CCLayerColor = CCLayerColor
local ccc4 = ccc4
local kCCTextAlignmentLeft = kCCTextAlignmentLeft
local PlatformUtility = PlatformUtility
local collectgarbage = collectgarbage
local CCSpawn = CCSpawn
local CCFadeOut = CCFadeOut
local CCFadeIn = CCFadeIn
local ccp = ccp
local table = table

module("common.utils")

local d_stat = require("common.statistics")
local d_hz = require("common.hz")
local d_music_mgr = require("effect.music_mgr")

local function cclog(...)
	CCLuaLog(string.format(...))
end

g_self = {}
g_client_req_serial_num = 100001
g_server_ret_serial_num = 0
g_server_lose_serial_num = 0
g_w = 1280
g_h = 720

function makePoint(x, y)
	local scrSize = CCDirector:sharedDirector():getVisibleSize()

	return CCPointMake(scrSize.width * x, scrSize.height * y)
end

g_sys_busy = false

function runScene(scene, is_show_black)
	local runingScene = CCDirector:sharedDirector():getRunningScene()

	main_server.change_speed(1)

	if runingScene then
		cclog("call replaceScene")
		CCDirector:sharedDirector():replaceScene(scene)
	else
		cclog("call runWithScene")
		CCDirector:sharedDirector():runWithScene(scene)
	end

	if is_show_black == true then
		local mask = CCLayerColor:create(ccc4(0, 0, 0, 128))

		scene:addChild(mask, 2000)
		mask:runAction(CCFadeOut:create(0.2))
	end

	if main_server.isMoivePlaying() == 0 then
		enableAndroidBack(scene)
	end

	unlock_btn(scene)

	g_sys_busy = false
end

function createScene()
	checkTextureCache()

	local new_scene = CCScene:create()

	return new_scene
end

g_checkTextureCache = 0
g_maxCleanTimes = 12

function checkTextureCache()
	g_checkTextureCache = g_checkTextureCache + 1

	if isADR() then
		cleanAndroidMem()
	elseif isIOS() then
		cleanIosMem()
	elseif isWin32() then
		removeAllCache()

		if CCTextureCache:sharedTextureCache().getCachedTextureInfo then
			local size, count = CCTextureCache:sharedTextureCache():getCachedTextureInfo()

			cclog("removeUnusedTextures, [size=%d],[rc=%d]", size, count)
		end
	else
		cclog("ERROR: unhandled os type.")
		removeAllCache()
	end
end

function removeAllCache()
	collectgarbage("collect")
	CCSpriteFrameCache:sharedSpriteFrameCache():removeSpriteFrames()
	CCTextureCache:sharedTextureCache():removeAllTextures()
end

function removeUnUsedCache()
	CCSpriteFrameCache:sharedSpriteFrameCache():removeUnusedSpriteFrames()
	CCTextureCache:sharedTextureCache():removeUnusedTextures()
end

function cleanAndroidMem()
	local free_rate = 0

	if main_server.get_free_mem_rate then
		free_rate = main_server.get_free_mem_rate()
	end

	if free_rate < 50 then
		removeAllCache()
	elseif g_maxCleanTimes < g_checkTextureCache then
		g_checkTextureCache = 0

		removeAllCache()
		cclog("reach g_maxCleanTimes, removeAllTextures")
	else
		removeUnUsedCache()
	end
end

function canSetAndroidMemInfo()
	local ret = false

	if main_server.doTPAction then
		main_server.doTPAction("get_mem_info", "")
	end

	if main_server.getTPValue then
		local max_mem = main_server.getTPValue("android_max_size") or ""

		cclog("max_mem = [" .. max_mem .. "]")

		if #max_mem > 0 then
			ret = true
		end
	end

	return ret
end

function cleanIosMem()
	if isLowIos() then
		removeAllCache()
	elseif g_maxCleanTimes < g_checkTextureCache then
		g_checkTextureCache = 0

		removeAllCache()
		cclog("reach g_maxCleanTimes, removeAllTextures")
	else
		removeUnUsedCache()
	end
end

ios_low_mt_types = {
	"iPhone1",
	"iPhone2",
	"iPad1"
}
g_isLowIos = nil

function isLowIos()
	if g_isLowIos ~= nil then
		cclog("call isLowIos, return")

		return g_isLowIos
	end

	g_isLowIos = false

	if main_server.get_mobile_type then
		local ios_mt = main_server.get_mobile_type()

		for i = 1, #ios_low_mt_types do
			if string.find(ios_mt, ios_low_mt_types[i]) ~= nil then
				g_isLowIos = true

				break
			end
		end
	end

	if g_isLowIos then
		cclog("call isLowIos, ret=true")
	else
		cclog("call isLowIos, ret=false")
	end
end

function checkShowLsof()
	if main_server.show_lsof then
		main_server.show_lsof()
	end
end

function enableAndroidBack(scene)
	if isADR() or isWin32() then
		g_self.quit_layer = CCLayer:create()

		scene:addChild(g_self.quit_layer, 9999)

		local function onTouchBack(e, x, y)
			if e == 1001 then
				cclog("press android quit btn...")

				if g_self.android_quit then
					g_self.android_quit()
				end

				return true
			elseif e == 1002 then
				cclog("press android menu btn...")

				if g_self.android_menu then
					g_self.android_menu()
				end

				return true
			end

			return false
		end

		g_self.quit_layer:registerScriptTouchHandler(onTouchBack)
		g_self.quit_layer:setKeypadEnabled(true)
	end
end

function cleanSence(call_back)
	local empty_scene = CCScene:create()

	runScene(empty_scene)

	if call_back then
		call_back()
	end
end

g_self.last_bkg_info = {}

function setStyle(obj, styles)
	return setStyles(obj, styles)
end

function getW()
	return 1280
end

g_self.g_scr_height = 0

function getH()
	if g_self.g_scr_height <= 0 then
		g_self.g_scr_height = CCDirector:sharedDirector():getVisibleSize().height
	end

	return g_self.g_scr_height
end

function getScaleW(x)
	return x / 1280
end

function getScaleH(y)
	return y / getH()
end

function setStyles(obj, styles)
	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local mapSize = obj:getContentSize()

	if styles.scale_x and styles.scale_y then
		obj:setScaleX(styles.scale_x)
		obj:setScaleY(styles.scale_y)
	elseif styles.scale then
		obj:setScale(styles.scale * scrSize.width / mapSize.width)
	else
		if styles.scaleH then
			obj:setScale(styles.scaleH * scrSize.height / mapSize.height)
		end

		if styles.scale_pic then
			styles.scaleX = mapSize.width / scrSize.width * styles.scale_pic
			styles.scaleY = mapSize.height / 720 * styles.scale_pic
		end

		if styles.scaleX then
			obj:setScaleX(styles.scaleX * scrSize.width / mapSize.width)
		end

		if styles.scaleY then
			obj:setScaleY(styles.scaleY * scrSize.height / mapSize.height)
		end

		if styles.scaleC then
			obj:setScale(styles.scaleC * scrSize.width / g_w)
		end
	end

	if styles.h_align then
		obj:setHorizontalAlignment(styles.h_align)
	end

	if styles.v_align then
		obj:setVerticalAlignment(styles.v_align)
	end

	if styles.color then
		local tmp_color = ccColor3B:new()

		if styles.color.r and styles.color.g and styles.color.b then
			tmp_color.r = styles.color.r
			tmp_color.g = styles.color.g
			tmp_color.b = styles.color.b
		else
			tmp_color.r = styles.color[1]
			tmp_color.g = styles.color[2]
			tmp_color.b = styles.color[3]
		end

		obj:setColor(tmp_color)
	end

	if styles.opacity then
		obj:setOpacity(styles.opacity)
	end

	if styles.blend_func then
		local bFunc = ccBlendFunc:new()
		bFunc.src = styles.blend_func.src
		bFunc.des = styles.blend_func.des

		obj:setBlendFunc(bFunc)
	end

	if styles.x == "follow" then
		styles.x = g_self.last_bkg_info.x + (g_self.last_bkg_info.w + mapSize.width) * styles.scaleC / (2 * g_w)
	end

	if styles.x and styles.y then
		if not styles.goback or styles.goback ~= true then
			g_self.last_bkg_info.x = styles.x
			g_self.last_bkg_info.y = styles.y
			g_self.last_bkg_info.w = mapSize.width
		end

		obj:setPosition(styles.x * scrSize.width, styles.y * scrSize.height)
	elseif styles.posXYZ then
		obj:setPosition(styles.posXYZ.x * scrSize.width, styles.posXYZ.y * scrSize.height)
	elseif styles.pos_x and styles.pos_y then
		obj:setPosition(styles.pos_x, styles.pos_y)
	end

	if styles.visible ~= nil then
		obj:setVisible(styles.visible)
	end

	if styles.FlipX then
		obj:setFlipX(styles.FlipX)
	end

	if styles.FlipY then
		obj:setFlipY(styles.FlipY)
	end

	if styles.rotation then
		obj:setRotation(styles.rotation)
	end

	if styles.rect then
		local ss = obj:getTexture():getContentSize()
		local w = ss.width
		local h = ss.height
		local map_rect = CCRectMake(w * styles.rect[1], h * styles.rect[2], w * styles.rect[3], h * styles.rect[4])

		obj:setTextureRect(map_rect)
	end

	if styles.anchor then
		local ax = styles.anchor[1]
		local bx = styles.anchor[2]

		obj:setAnchorPoint(CCPointMake(ax, bx))
	end

	if styles.anchorPoint then
		obj:setAnchorPoint(styles.anchorPoint)
	end

	if styles.tag then
		obj:setTag(styles.tag)
	end

	return obj
end

function print_table(p_table)
	for i, v in pairs(p_table) do
		if type(v) == "table" then
			print_table(v)
		else
			print(i, " = ", v)
		end
	end
end

function createMenuItem(menuItemInfo)
	local tmp_menu_item = nil

	if menuItemInfo.npic and menuItemInfo.spic then
		tmp_menu_item = CCMenuItemImage:create(menuItemInfo.npic, menuItemInfo.spic, menuItemInfo.dispic)
	elseif menuItemInfo.nsprite and menuItemInfo.ssprite then
		tmp_menu_item = CCMenuItemSprite:create(menuItemInfo.nsprite, menuItemInfo.ssprite, menuItemInfo.dissprite)
	end

	if menuItemInfo.tag then
		tmp_menu_item:setTag(menuItemInfo.tag)
	end

	if menuItemInfo.prompt then
		menuItemInfo.color = {
			g = 0,
			b = 69,
			r = 255
		}
	end

	setStyles(tmp_menu_item, menuItemInfo)

	if menuItemInfo.call_back then
		tmp_menu_item:registerScriptTapHandler(menuItemInfo.call_back)
	end

	return tmp_menu_item
end

function createMenuItemWithDisable(menuItemInfo)
	local tmp_menu_item = CCMenuItemImage:create(menuItemInfo.npic, menuItemInfo.disPic, menuItemInfo.disPic)

	if menuItemInfo.tag then
		tmp_menu_item:setTag(menuItemInfo.tag)
	end

	setStyles(tmp_menu_item, menuItemInfo)

	if menuItemInfo.call_back then
		tmp_menu_item:registerScriptTapHandler(menuItemInfo.call_back)
	end

	return tmp_menu_item
end

function createMenu(menusinfo, menuTable, isNeedDisableMenu)
	local tmp_array = CCArray:create()

	for i, v in pairs(menusinfo) do
		if type(v) == "table" then
			if menuTable then
				if isNeedDisableMenu ~= nil and isNeedDisableMenu == true then
					menuTable[#menuTable + 1] = createMenuItemWithDisable(v)
				else
					menuTable[#menuTable + 1] = createMenuItem(v)
				end

				tmp_array:addObject(menuTable[#menuTable])
			else
				local menuItem = nil

				if isNeedDisableMenu ~= nil and isNeedDisableMenu == true then
					menuItem = createMenuItemWithDisable(v)
				else
					menuItem = createMenuItem(v)
				end

				tmp_array:addObject(menuItem)
			end
		end
	end

	local tmp_menu = CCMenu:createWithArray(tmp_array)

	setStyles(tmp_menu, menusinfo)

	if menusinfo.pri then
		function delay_me()
			tmp_menu:setHandlerPriority(menusinfo.pri)
		end

		delay(tmp_menu, 0.1, delay_me)
	end

	tmp_menu:setTouchEnabled(true)

	return tmp_menu
end

function createByStyle(s)
	local scrSize = CCDirector:sharedDirector():getVisibleSize()

	if not s.type then
		s.type = "sprite"
	end

	local obj = nil

	if s.type == "label" then
		s.font = s.font or "arial"
		s.fontsize = math.floor(s.fontsize / 4) * 4 + 2

		if s.size then
			s.h_align = s.h_align or kCCTextAlignmentLeft
			obj = CCLabelTTF:create(s.string, s.font, s.fontsize, s.size, s.h_align)
		elseif s.font_rect then
			s.h_align = s.h_align or kCCTextAlignmentLeft
			local tmp_rect = ccSizeMake(s.font_rect[1], s.font_rect[2])
			obj = CCLabelTTF:create(s.string, s.font, s.fontsize, tmp_rect, s.h_align)
		else
			obj = CCLabelTTF:create(s.string, s.font, s.fontsize)
		end
	elseif s.type == "sprite" then
		obj = CCSprite:create(s.pic)
	elseif s.type == "lableFont" then
		obj = CCLabelBMFont:create(s.content, "v2/BitmapFont.fnt")
	elseif s.type == "mask" then
		obj = CCSprite:create(s.pic)

		obj:setMaskEff()
	else
		cclog("ERROR: unknown type...type=%s", s.type)
	end

	if not obj then
		cclog("ERROR: call createByStyle create obj fail.")
	end

	setStyles(obj, s)

	return obj
end

function createByStyles(s)
	return createByStyle(s)
end

function getPicScale(obj)
	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local mapSize = obj:getContentSize()
	local w = mapSize.width / scrSize.width
	local h = mapSize.height / scrSize.height

	return w, h
end

function getRealScale(obj)
	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local mapSize = obj:getContentSize()
	local w = mapSize.width / scrSize.width * obj:getScaleX()
	local h = mapSize.height / scrSize.height * obj:getScaleY()

	return w, h
end

function ccSizeMake(w, h)
	local s = CCDirector:sharedDirector():getVisibleSize()

	return CCSizeMake(s.width * w, s.height * h)
end

function ccRectMake(x, y, w, h)
	local s = CCDirector:sharedDirector():getVisibleSize()

	return CCRectMake(s.width * x, s.height * y, s.width * w, s.height * h)
end

function getRect(obj)
	local size = obj:getContentSize()
	local pos = obj:getPositionLua()

	return CCRectMake(pos.x - size.width / 2, pos.y - size.height / 2, size.width, size.height)
end

function getRealRect(obj)
	local size = obj:getContentSize()
	local pos = obj:getPositionLua()
	local anchor = obj:getAnchorPoint()
	size.width = size.width * obj:getScaleX()
	size.height = size.height * obj:getScaleY()

	return CCRectMake(pos.x - size.width * anchor.x, pos.y - size.height * anchor.y, size.width, size.height)
end

function getPostionByScale(obj)
	local size = obj:getContentSize()
	local pos = obj:getPositionLua()

	return pos.x / size.width, pos.y / size.height
end

function getRectBySaclePosAndWH(scale_x, scale_y, w, h)
	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local pos = {
		x = scale_x * scrSize.width,
		y = scale_y * scrSize.height
	}
	local size = {
		width = w * scrSize.width,
		height = h * scrSize.height
	}

	return CCRectMake(pos.x - size.width / 2, pos.y - size.height / 2, size.width, size.height)
end

function setColor(obj, color)
	if obj and color and obj.setColor then
		local tmp_color = ccColor3B:new()

		if color.r and color.g and color.b then
			tmp_color.r = color.r
			tmp_color.g = color.g
			tmp_color.b = color.b
		else
			tmp_color.r = color[1]
			tmp_color.g = color[2]
			tmp_color.b = color[3]
		end

		obj:setColor(tmp_color)
	end
end

function getHzWidthByScale(font_size, w_all)
	local ttf_content = CCLabelTTF:create(d_hz.gethz("setting1"), "arial", font_size, CCSizeMake(0, 0), kCCTextAlignmentLeft)
	local w, h = getPicScale(ttf_content)
	local hz_count = math.floor(w_all / (w / 2))

	return hz_count * w / 2
end

g_self.hz_width_cache = {}
g_self.letter_width_cache = {}

function getSingleHzWidthBySize(font_size)
	if g_self.hz_width_cache[font_size] then
		return g_self.hz_width_cache[font_size]
	end

	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local ttf_content = CCLabelTTF:create(d_hz.gethz("setting1"), "arial", font_size, CCSizeMake(0, 0), kCCTextAlignmentLeft)
	local ret = ttf_content:getContentSize().width * 0.5 / scrSize.width
	g_self.hz_width_cache[font_size] = ret

	return ret
end

function getSingleNumberWidthBySize(font_size)
	if g_self.letter_width_cache[font_size] then
		return g_self.letter_width_cache[font_size]
	end

	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local ttf_content = CCLabelTTF:create("99", "arial", font_size, CCSizeMake(0, 0), kCCTextAlignmentLeft)
	local ret = ttf_content:getContentSize().width * 0.5 / scrSize.width
	g_self.letter_width_cache[font_size] = ret

	return ret
end

function grayMenuItem(obj, need_disable)
	local n_image = obj:getNormalImage()
	local sprite_n_image = tolua.cast(n_image, "CCSprite")

	n_image:setMaskEff("v2/gray.shader")
	obj:setNormalImage(n_image)

	local s_image = CCSprite:createWithTexture(sprite_n_image:getTexture())

	s_image:setMaskEff("v2/gray.shader")
	obj:setSelectedImage(s_image)

	if need_disable ~= nil then
		obj:setEnabled(need_disable)
	end
end

function getEffectAnimate(filename, wl, hl, index_begin, index_end, delay_time)
	local texture = CCTextureCache:sharedTextureCache():addImage(filename)
	local w = texture:getContentSize().width / wl
	local h = texture:getContentSize().height / hl
	local sprite0 = nil
	local animFrames = CCArray:create()
	local index = 0

	for j = 0, hl - 1 do
		for i = 0, wl - 1 do
			if index_begin <= index and index <= index_end then
				local tmp_frame = CCSpriteFrame:createWithTexture(texture, CCRectMake(w * i + 1, h * j + 1, w - 2, h - 2))

				if sprite0 == nil then
					sprite0 = CCSprite:createWithSpriteFrame(tmp_frame)
				end

				animFrames:addObject(tmp_frame)
			end

			index = index + 1
		end
	end

	local animation = CCAnimation:createWithSpriteFrames(animFrames, delay_time)
	local animate = CCAnimate:create(animation)
	local ret = {
		animate = animate,
		sprite0 = sprite0
	}

	return ret
end

function getEffectAnimateByTime(filename, wl, hl, index_begin, index_end, delay_time_min, frames)
	local texture = CCTextureCache:sharedTextureCache():addImage(filename)
	local w = texture:getContentSize().width / wl
	local h = texture:getContentSize().height / hl
	local sprite0 = nil
	local animFrames = CCArray:create()
	local index = 0

	for j = 0, hl - 1 do
		for i = 0, wl - 1 do
			if index_begin <= index and index <= index_end then
				local tmp_frame = CCSpriteFrame:createWithTexture(texture, CCRectMake(w * i + 1, h * j + 1, w - 2, h - 2))

				if sprite0 == nil then
					sprite0 = CCSprite:createWithSpriteFrame(tmp_frame)
				end

				for k = 1, frames[index + 1] do
					animFrames:addObject(tmp_frame)
				end
			end

			index = index + 1
		end
	end

	local animation = CCAnimation:createWithSpriteFrames(animFrames, delay_time_min)
	local animate = CCAnimate:create(animation)
	local ret = {
		animate = animate,
		sprite0 = sprite0
	}

	return ret
end

function getAttributeFormPlist(plistFile, key, dict, keyPrefix)
	if dict == nil or #dict == 0 then
		dict = CCDictionary:createWithContentsOfFile(plistFile)
	end

	if keyPrefix ~= nil then
		key = keyPrefix .. key
	end

	return dict:valueForKey(key):getCString()
end

function parseAttribute(str)
	local t = {}
	local i = 0
	local j = 0
	local start = 1

	while true do
		i, j = string.find(str, "##", start)

		if i == nil then
			break
		end

		t[#t + 1] = string.sub(str, start, i - 1)
		start = j + 1
	end

	t[#t + 1] = string.sub(str, start, -1)

	return t
end

function getOS()
	return CCApplication:sharedApplication():getTargetPlatform()
end

function isWin32()
	local iOsType = getOS()

	if iOsType == 0 then
		return true
	else
		return false
	end
end

function isIOS()
	local iOsType = getOS()

	if iOsType == 2 or iOsType == 4 or iOsType == 5 then
		return true
	else
		return false
	end
end

function isADR()
	local iOsType = getOS()

	if iOsType == 3 then
		return true
	else
		return false
	end
end

function preLoadCCBI(file)
	local actionManager, node_ani = nil
	local ccNodeLoaderLibrary = CCNodeLoaderLibrary:newDefaultCCNodeLoaderLibrary()
	local ccbReader = CCBReader:new(ccNodeLoaderLibrary)
	node_ani, actionManager = ccbReader:readNodeGraphFromFile(file, nil, actionManager)

	ccbReader:autorelease()
end

function createAnimation(file, styles, duration, call_back, layer)
	if not layer then
		return
	end

	local actionManager, node_ani = nil
	local ccNodeLoaderLibrary = CCNodeLoaderLibrary:newDefaultCCNodeLoaderLibrary()
	local ccbReader = CCBReader:new(ccNodeLoaderLibrary)
	node_ani, actionManager = ccbReader:readNodeGraphFromFile(file, layer, actionManager)

	ccbReader:autorelease()

	local scrSize = CCDirector:sharedDirector():getVisibleSize()
	local anchor = node_ani:getAnchorPoint()

	if anchor and styles.x and styles.y then
		styles.x = styles.x - anchor.x
		styles.y = styles.y - anchor.y

		if styles.scale then
			styles.x = styles.x - (0.5 - anchor.x) * styles.scale
			styles.y = styles.y - (0.5 - anchor.y) * styles.scale
		end
	end

	setStyles(node_ani, styles)
	layer:addChild(node_ani, styles.z)

	function callbackCleanMe()
		node_ani:stopAllActions()
		layer:removeChild(node_ani, true)

		if call_back then
			call_back()
		end
	end

	if duration then
		local delay_actions = CCArray:create()

		delay_actions:addObject(CCDelayTime:create(duration))
		delay_actions:addObject(CCCallFuncN:create(callbackCleanMe))
		node_ani:runAction(CCSequence:create(delay_actions))
	end

	checkCcbiSound(node_ani, file)

	return node_ani
end

function createLoopAnimation(file)
	local actionManager, node_ani = nil
	local ccNodeLoaderLibrary = CCNodeLoaderLibrary:newDefaultCCNodeLoaderLibrary()
	local ccbReader = CCBReader:new(ccNodeLoaderLibrary)
	node_ani, actionManager = ccbReader:readNodeGraphFromFile(file, layer, actionManager)

	ccbReader:autorelease()
	checkCcbiSound(node_ani, file)

	return node_ani
end

function createAnimation_new(file, styles, duration, call_back, layer)
	if not layer then
		return
	end

	local actionManager, node_ani = nil
	local ccNodeLoaderLibrary = CCNodeLoaderLibrary:newDefaultCCNodeLoaderLibrary()
	local ccbReader = CCBReader:new(ccNodeLoaderLibrary)
	node_ani, actionManager = ccbReader:readNodeGraphFromFile(file, layer, actionManager)

	ccbReader:autorelease()

	local scrSize = CCDirector:sharedDirector():getVisibleSize()

	if styles.x and styles.y then
		styles.x = styles.x - 0.5
		styles.y = styles.y - 0.5
	end

	setStyles(node_ani, styles)

	if not styles.z then
		layer:addChild(node_ani)
	else
		layer:addChild(node_ani, styles.z)
	end

	function callbackCleanMe()
		node_ani:stopAllActions()
		layer:removeChild(node_ani, true)

		if call_back then
			call_back()
		end
	end

	if duration then
		delay(node_ani, duration, callbackCleanMe)
	end

	checkCcbiSound(node_ani, file)

	return node_ani
end

function checkCcbiSound(node, file_name)
	if node == nil then
		return
	end

	local sound_list = d_music_mgr.getCcbiSoundList(file_name)

	for i, v in pairs(sound_list) do
		local function play_music()
			d_music_mgr.playSound(v)
		end

		local delay_actions = CCArray:create()

		delay_actions:addObject(CCDelayTime:create(i / 1000))
		delay_actions:addObject(CCCallFuncN:create(play_music))
		node:runAction(CCSequence:create(delay_actions))
	end
end

function playSoundEffect(name)
	local node = CCDirector:sharedDirector():getRunningScene()

	checkCcbiSound(node, name)
end

function setProperties(prObj, chObj, pList)
	if prObj == nil then
		setStyles(chObj, pList)

		return
	end

	local psz = prObj:getContentSize()
	local csz = chObj:getContentSize()

	if pList.scale then
		chObj:setScale(psz.width * pList.scale / csz.width)
	else
		if pList.scaleH then
			chObj:setScale(psz.height * pList.scaleH / csz.height)
		elseif pList.scaleW then
			chObj:setScale(psz.width * pList.scaleW / csz.width)
		end

		if pList.scaleX then
			chObj:setScaleX(psz.width * pList.scaleX / csz.width)
		end

		if pList.scaleY then
			chObj:setScaleY(psz.height * pList.scaleY / csz.height)
		end
	end

	if pList.x then
		chObj:setPositionX(psz.width * pList.x)
	end

	if pList.y then
		chObj:setPositionY(psz.height * pList.y)
	end

	if pList.px then
		chObj:setPositionX(pList.px)
	end

	if pList.py then
		chObj:setPositionY(pList.py)
	end
end

function singleStretchOfBackground(bkgNode)
	local vSz = CCDirector:sharedDirector():getVisibleSize()
	local bSz = bkgNode:getContentSize()

	if vSz.height == 0 or bSz.height == 0 then
		return
	end

	local vRate = vSz.width / vSz.height
	local bRate = bSz.width / bSz.height
	local scale = vSz.height / bSz.height

	bkgNode:setScale(scale)
end

local function getWillScrollDistance(cellsView, dy)
	local svsz = cellsView:getContentSize()
	local y = math.abs(dy)
	local re = y * y * svsz.height * 0.01 * 0.05

	return re
end

local function getCanScrollDistance(cellsView, dy)
	local vy = cellsView:getPositionY()
	local vSz = cellsView:getParent():getViewSize()
	local svsz = cellsView:getContentSize()

	if vy > 0 or vy - vSz.height + svsz.height < 0 then
		return 0
	end

	if dy > 0 then
		return math.abs(vy)
	else
		return svsz.height - vSz.height - math.abs(vy)
	end
end

local function getScrollBackAction(cellsView, dy)
	local vSz = cellsView:getParent():getViewSize()
	local svsz = cellsView:getContentSize()
	local finY = 0

	if svsz.height < vSz.height or dy < 0 then
		finY = vSz.height - svsz.height
	elseif dy == 0 then
		local tmp_actScrollBack = CCEaseOut:create(CCMoveBy:create(0.1, CCPointMake(0, 0)), 1)

		return tmp_actScrollBack
	end

	local actScrollBack = CCEaseOut:create(CCMoveTo:create(0.3, CCPointMake(0, finY)), 3)

	return actScrollBack
end

function followupActionsOfScrollView(cellsView, dy)
	local vSz = cellsView:getParent():getViewSize()
	local svsz = cellsView:getContentSize()
	local vy = cellsView:getPositionY()
	local wdis = getWillScrollDistance(cellsView, dy)
	local cdis = getCanScrollDistance(cellsView, dy)

	if cdis == 0 then
		local act = getScrollBackAction(cellsView, dy)

		cellsView:runAction(act)
	elseif cdis <= wdis then
		local dt = 2 * cdis / wdis
		local finY = vSz.height / 3

		if dy < 0 then
			finY = vSz.height - svsz.height - finY
		end

		local act1 = CCEaseOut:create(CCMoveTo:create(dt + 0.2, CCPointMake(0, finY)), 3)
		local act3 = getScrollBackAction(cellsView, dy)
		local actArr = CCArray:create()

		actArr:addObject(act1)
		actArr:addObject(act3)
		cellsView:runAction(CCSequence:create(actArr))
	else
		local finY = wdis

		if dy < 0 then
			finY = 0 - finY
		end

		local act = CCEaseOut:create(CCMoveBy:create(2, CCPointMake(0, finY)), 3)

		cellsView:runAction(act)
	end
end

function remove(ccnode_obj)
	if ccnode_obj and ccnode_obj.getParent then
		local parent = ccnode_obj:getParent()

		if parent then
			parent:removeChild(ccnode_obj, true)
		end
	end

	ccnode_obj = nil
end

function hasChild(parent_layer, tag)
	if parent_layer == nil or tag == nil then
		return false
	elseif parent_layer:getChildByTag(tag) then
		return true
	end

	return false
end

function removeChild(parent_layer, tag)
	if parent_layer and tag then
		parent_layer:removeChildByTag(tag)
	end
end

function createTagLayer(parent_layer, tag, z_order)
	local ret = nil

	if parent_layer and tag then
		parent_layer:removeChildByTag(tag, true)

		ret = CCLayer:create()

		ret:setTag(tag)

		if z_order then
			parent_layer:addChild(ret, z_order)
		else
			parent_layer:addChild(ret)
		end
	else
		cclog("ERROR: parents_layer or tag not exist")
	end

	return ret
end

function addOnlyChild(parent, child, tag, z_order)
	if parent and child and tag then
		parent:removeChildByTag(tag, true)
		child:setTag(tag)

		if z_order then
			parent:addChild(child, z_order)
		else
			parent:addChild(child)
		end
	else
		cclog("ERROR: addOnlyChild, param error.")
	end
end

function runDelayFunc(ccnode, delay_time, func)
	if ccnode and func then
		local delay_actions = CCArray:create()

		delay_actions:addObject(CCDelayTime:create(delay_time))
		delay_actions:addObject(CCCallFuncN:create(func))
		ccnode:runAction(CCSequence:create(delay_actions))
	end
end

function delay(ccnode, delay_time, func)
	runDelayFunc(ccnode, delay_time, func)
end

function delay_node(delay_time, func)
	local runingScene = CCDirector:sharedDirector():getRunningScene()

	runDelayFunc(runingScene, delay_time, func)
end

function quit()
	cclog("call util quit game.")

	if main_server.doTPAction then
		main_server.doTPAction("quit", "bye")
	end

	if main_server.lua_quit then
		main_server.lua_quit()
	else
		CCDirector:sharedDirector():endToLua()
	end
end

function reload_lua(module_name, path_name)
	package.loaded[path_name] = nil
	module_name = require(path_name)
end

local d_alert = require("alert")
g_last_send_msg_id = 0
g_is_time_out = false
g_clock = {}
g_is_waiting_1106 = false
g_net_wait_action = false
g_last_req = {}

function sendLastSaveReq()
	if g_last_req and g_last_req.msg_id then
		main_server_send_msg(g_last_req.msg_id, g_last_req.msg, g_last_req.wait_time)

		g_last_req = {}
	end
end

function main_server_send_msg(msg_id, msg, wait_time)
	wait_time = wait_time or 10

	if wait_time > 0 then
		msg.serial_num = g_client_req_serial_num

		if g_net_wait_action == true then
			g_last_req = {
				msg_id = msg_id,
				msg = msg,
				wait_time = wait_time
			}

			return
		end
	else
		msg.serial_num = 0
	end

	if checkCanSendMsg(msg_id, wait_time) == true then
		d_alert.start_wait(nil, wait_time)

		if msg.serial_num > 0 then
			cclog(">----[%d]----s_id=[%d]---------->", msg_id, msg.serial_num)

			g_is_waiting_1106 = true
		end

		main_server.send_msg(msg_id, msg)
	end

	if wait_time > 0 then
		clock_begin(msg_id)
	end
end

function main_server_send_msg_server(msg_id, msg, socket_id, wait_time)
	if socket_id and socket_id == 0 then
		cclog("ERROR: socket_id == 0")

		return
	end

	wait_time = wait_time or 10
	msg.serial_num = 0

	if checkCanSendMsg(msg_id, wait_time) == true then
		main_server.send_msg_server(msg_id, msg, socket_id)
		cclog("send_msg_server, id=" .. msg_id)
		d_alert.start_wait(nil, wait_time)
	else
		cclog("checkCanSendMsg return false")
	end

	if wait_time > 0 then
		clock_begin(msg_id)
	end
end

function checkCanSendMsg(msg_id, wait_time)
	if wait_time <= 0 then
		return true
	end

	if g_is_waiting_1106 == false then
		g_last_send_msg_id = msg_id

		return true
	else
		if msg_id == 1016 or msg_id == 1105 then
			g_last_send_msg_id = msg_id

			return true
		end

		cclog("ERROR: wait for msg [%d] return", g_last_send_msg_id)
	end

	return false
end

function packageReturn(msg_id, server_net_id)
	cclog("call packageReturn [%d]", msg_id)
	clock_end(nil, msg_id)

	if server_net_id == nil or server_net_id == 0 then
		return true
	end

	if g_server_ret_serial_num == 0 then
		g_server_ret_serial_num = server_net_id

		return true
	elseif server_net_id == g_server_ret_serial_num + 1 then
		g_server_ret_serial_num = server_net_id
		g_server_lose_serial_num = 0

		return true
	elseif server_net_id <= g_server_ret_serial_num then
		cclog("ERROR: dup pakage: [%d]<=[%d]", server_net_id, g_server_ret_serial_num)
	else
		cclog("ERROR: g_server_ret_serial_num lost package, [%d] to [%d]", g_server_ret_serial_num, server_net_id)

		if g_server_lose_serial_num == 0 then
			g_server_lose_serial_num = server_net_id

			tryRetranReq()
		elseif server_net_id == g_server_lose_serial_num then
			g_server_ret_serial_num = server_net_id
			g_server_lose_serial_num = 0

			return true
		end
	end

	return false
end

function tryRetranReq()
	cclog("call tryRetranReq")

	local tmp_req = {
		req_serial_num = g_server_ret_serial_num
	}

	cclog("ERROR: ===========send msg_retrans_req 1105 to bs id=%d", g_server_ret_serial_num)
	main_server_send_msg(1105, tmp_req)
end

function isWifi()
	if g_self.last_network_state == nil then
		if PlatformUtility.getNetworkState then
			g_self.last_network_state = PlatformUtility:getNetworkState()
		else
			g_self.last_network_state = 0
		end
	end

	return g_self.last_network_state == 2
end

function packageTimeOut()
	cclog("call packageTimeOut [%d]", g_last_send_msg_id)
	d_stat.add_timeout_count()

	g_is_time_out = true
	g_self.last_network_state = nil
end

function codeForUrl(src_string)
	src_string = "" .. src_string

	if #src_string <= 0 then
		src_string = "null"
	end

	cclog("call codeForUrl, len=" .. #src_string)

	local ret = string.gsub("" .. src_string, " ", "_")
	ret = string.gsub(ret, "&", "_")
	ret = string.gsub(ret, "%%", "_")
	ret = string.gsub(ret, "?", "_")
	ret = string.gsub(ret, "=", "_")
	ret = string.gsub(ret, "<", "_")
	ret = string.gsub(ret, ">", "_")
	ret = string.gsub(ret, "@", "_")
	ret = string.gsub(ret, "\\", "/")
	ret = string.gsub(ret, "\n", "/n")
	ret = string.gsub(ret, "\r", "/n")
	ret = string.gsub(ret, "\t", "_")

	return ret
end

function codeBase64(src)
	local ret = 0

	if main_server.get_base64 then
		ret = main_server.get_base64(src)
	else
		cclog("ERROR: call main_server.get_base64 fail.")

		ret = codeForUrl(src)
	end

	return ret
end

function codeCharBase64(src)
	local ret = 0

	if main_server.get_charbase64 then
		ret = main_server.get_charbase64(src)
	else
		cclog("ERROR: call main_server.get_charbase64 fail.")

		ret = codeForUrl(src)
	end

	return ret
end

function formatBigNum(number)
	local n = tostring(number)
	local ret = ""
	local cc = 0

	for i = #n, 1, -1 do
		if cc > 1 and cc % 3 == 0 and n[i] ~= "-" then
			ret = "," .. ret
		end

		ret = string.sub(n, i, i) .. ret
		cc = cc + 1
	end

	return ret
end

function clock_begin(msg_id)
	local begin_counter = {}

	if main_server.time_us then
		begin_counter.sec, begin_counter.usec = main_server.time_us()

		cclog("time_us_begin: s=" .. begin_counter.sec .. ", us=" .. begin_counter.usec .. ", t=" .. os.time() .. ", msg=" .. msg_id)
	else
		begin_counter.sec = os.time()
		begin_counter.usec = 0
	end

	g_self.last_clock = begin_counter

	if msg_id then
		begin_counter.msg_id = msg_id

		d_stat.add_req_count()
	end

	return begin_counter
end

function clock_end(begin_counter, msg_id)
	begin_counter = begin_counter or g_self.last_clock

	if not begin_counter or not begin_counter.sec or not begin_counter.usec then
		return 0
	end

	local end_counter = {}

	if main_server.time_us then
		end_counter.sec, end_counter.usec = main_server.time_us()

		cclog("time_us_end: s=" .. end_counter.sec .. ", us=" .. end_counter.usec .. ", t=" .. os.time() .. ", msg=" .. msg_id)
	else
		end_counter.sec = os.time()
		end_counter.usec = 0
	end

	local time_cost = end_counter.sec - begin_counter.sec + (end_counter.usec - begin_counter.usec) / 1000000

	if time_cost <= 0 then
		cclog("ERROR: time_cost<0")

		time_cost = 0
	end

	if begin_counter.msg_id and msg_id then
		cclog("--------TIME_COST=[%03f], begin_msg=[%d], end_msg=[%d]", time_cost, begin_counter.msg_id, msg_id)
		d_stat.add_req_all_time(time_cost)
	end

	g_self.last_clock = {
		sec = os.time()
	}

	return time_cost
end

function funcShockBkg(layer, x_begin_pos, y_begin_pos)
	if layer then
		x_begin_pos = x_begin_pos or 0
		y_begin_pos = y_begin_pos or 0

		function bkgSetMiddle()
			setStyles(layer, {
				x = x_begin_pos,
				y = y_begin_pos
			})
		end

		local action_shockBkg = CCArray:create()

		action_shockBkg:addObject(CCMoveTo:create(0.02, makePoint(0.02, -0.02)))
		action_shockBkg:addObject(CCMoveTo:create(0.02, makePoint(-0.02, 0.02)))
		action_shockBkg:addObject(CCCallFuncN:create(bkgSetMiddle))
		action_shockBkg:addObject(CCMoveTo:create(0.02, makePoint(-0.02, 0.02)))
		action_shockBkg:addObject(CCMoveTo:create(0.02, makePoint(0.02, -0.02)))
		action_shockBkg:addObject(CCCallFuncN:create(bkgSetMiddle))
		action_shockBkg:addObject(CCMoveTo:create(0.02, makePoint(0.02, 0.02)))
		action_shockBkg:addObject(CCMoveTo:create(0.02, makePoint(-0.02, -0.02)))
		action_shockBkg:addObject(CCCallFuncN:create(bkgSetMiddle))
		action_shockBkg:addObject(CCMoveTo:create(0.02, makePoint(0.02, 0.02)))
		action_shockBkg:addObject(CCMoveTo:create(0.02, makePoint(-0.02, -0.02)))
		action_shockBkg:addObject(CCMoveTo:create(0.01, makePoint(0, 0)))
		action_shockBkg:addObject(CCCallFuncN:create(bkgSetMiddle))
		layer:runAction(CCSequence:create(action_shockBkg))
	end
end

function is_leaf_table(t)
	if type(t) == "table" then
		for i, v in pairs(t) do
			if type(v) ~= "table" then
				return true
			end
		end
	end

	return false
end

function createSwallowTouchLayer(parent, zOrder, tag)
	local z_order = zOrder or 50
	local sLayer = CCLayer:create()

	if tag then
		parent:addChild(sLayer, z_order, tag)
	else
		parent:addChild(sLayer, z_order)
	end

	function onTouch(eventType, x, y)
		return true
	end

	sLayer:registerScriptTouchHandler(onTouch, false, -128, true)
	sLayer:setTouchEnabled(true)

	return sLayer
end

function createSwallowTouchLayerColor(parent, zOrder, oppcity, touchFunc)
	local z_order = zOrder or 50
	local sLayer = CCLayerColor:create(ccc4(0, 0, 0, oppcity or 100))

	parent:addChild(sLayer, z_order)

	function onTouch(eventType, x, y)
		if touchFunc then
			touchFunc(eventType, x, y)
		end

		return true
	end

	sLayer:registerScriptTouchHandler(onTouch, false, -128, true)
	sLayer:setTouchEnabled(true)

	return sLayer
end

function addShadowBack(parent_layer, order)
	local blackmask = CCLayerColor:create(ccc4(0, 0, 0, 100))

	if oder then
		parent_layer:addChild(blackmask, order)
	else
		parent_layer:addChild(blackmask)
	end
end

function createSwallowTouchLayerFunc(parent, params)
	params.z = params.z or 100
	local sLayer = CCLayer:create()

	parent:addChild(sLayer, params.z)

	function onTouch(eventType, x, y)
		if params.rect then
			if params.rect:containsPoint(CCPointMake(x, y)) then
				if params.inFunc then
					return params.inFunc(eventType, x, y)
				end
			elseif params.outFunc then
				return params.outFunc(eventType, x, y)
			end
		end

		return true
	end

	sLayer:registerScriptTouchHandler(onTouch, false, -128, true)
	sLayer:setTouchEnabled(true)
end

function find_hint(str, find_str)
	local ret = string.find(str, find_str)

	return ret or -1
end

function isHttp404(buff)
	if content and find_hint(buff, "<") > 0 and find_hint(buff, ">") > 0 and find_hint(buff, "404") > 0 and (find_hint(buff, "html") > 0 or find_hint(buff, "HTML") > 0) then
		return true
	end

	return false
end

function loadstring_config(buff)
	local ret = {}

	if isWin32() and find_hint(buff, "<") > 0 and find_hint(buff, ">") > 0 and (find_hint(buff, "html") > 0 or find_hint(buff, "HTML") > 0) then
		cclog("ERROR: loadstring_config buff content error.")

		return nil
	end

	local func = loadstring("do local ret = {" .. buff .. "} return ret end")

	if func then
		ret = func()
	end

	if #ret == 1 then
		if is_leaf_table(ret[1]) then
			return ret
		end
	else
		return ret
	end

	ret = ret[1]

	return ret
end

function loadstring_config_new(buff)
	local ret = {}

	if isWin32() and find_hint(buff, "<") > 0 and find_hint(buff, ">") > 0 and (find_hint(buff, "html") > 0 or find_hint(buff, "HTML") > 0) then
		cclog("ERROR: loadstring_config_new buff content error.")

		return nil
	end

	local func = loadstring("do local ret = {" .. buff .. "} return ret end")

	if func then
		ret = func()
	end

	return ret
end

g_btn_locked = false

function try_lock_btn()
	if g_btn_locked == true then
		return false
	end

	g_btn_locked = true

	return true
end

function unlock_btn(sence)
	function releaseLock()
		g_btn_locked = false
	end

	if sence then
		delay(sence, 0.5, releaseLock)
	else
		releaseLock()
	end
end

function md5_tonumber(md5)
	return main_server.get_hash_account(md5)
end

function getCDStr(countDown)
	local time = countDown
	local hour = math.floor(time / 3600)
	time = time - hour * 3600
	local minute = math.floor(time / 60)
	time = time - minute * 60
	local second = math.max(0, time)

	return string.format("%02d:%02d:%02d", hour, minute, second)
end

function reload_pic()
	local runingScene = CCDirector:sharedDirector():getRunningScene()

	runingScene:removeChildByTag(880013, true)
	runingScene:removeChildByTag(880012, true)

	local syyx_pic = createByStyle({
		x = 0.5,
		pic = "v2/com_logo.png",
		y = 0.5,
		scaleX = 1.2,
		rotation = 90,
		scaleY = 2.2
	})

	syyx_pic:setTag(880012)
	runingScene:addChild(syyx_pic, 10000)

	local hz = createByStyle({
		y = 0.1,
		type = "label",
		x = 0.5,
		fontsize = 26,
		string = d_hz.gethz("loading_file")
	})

	hz:setTag(880013)
	runingScene:addChild(hz, 10001)
end

function reload_pic_clean()
	local runingScene = CCDirector:sharedDirector():getRunningScene()

	if runingScene then
		runingScene:removeChildByTag(880013, true)
		runingScene:removeChildByTag(880012, true)
	end
end

function create_action(data)
	local ret = CCArray:create()

	local function addObjs(tmp_obj_table)
		local tmp_seq = CCArray:create()

		for i = 1, #tmp_obj_table do
			if type(tmp_obj_table[i]) == "table" then
				tmp_seq:addObject(createActionByStyle(tmp_obj_table[i]))
			else
				tmp_seq:addObject(tmp_obj_table[i])
			end
		end

		ret:addObject(CCSequence:create(tmp_seq))
	end

	for j = 1, #data do
		addObjs(data[j])
	end

	return CCSpawn:create(ret)
end

function createActionByStyle(data)
	local ret = nil

	if data.func then
		ret = CCCallFuncN:create(data.func)
	elseif data.delay then
		ret = CCDelayTime:create(data.delay)
	elseif data.moveto then
		ret = CCMoveTo:create(data.moveto.t, makePoint(data.moveto.x, data.moveto.y))
	elseif data.moveby then
		ret = CCMoveBy:create(data.moveby.t, makePoint(data.moveby.x, data.moveby.y))
	elseif data.scaleto then
		ret = CCScaleTo:create(data.scaleto.t, data.scaleto.s)
	elseif data.scaleby then
		ret = CCScaleBy:create(data.scaleby.t, data.scaleby.s)
	elseif data.fadeout then
		ret = CCFadeOut:create(data.fadeout)
	elseif data.fadein then
		ret = CCFadeIn:create(data.fadein)
	elseif data.tintto then
		ret = CCTintTo:create(data.tintto.t, data.tintto.color[1], data.tintto.color[2], data.tintto.color[3])
	else
		cclog("ERROR, unhandle action.")
	end

	if data.eff then
		if data.eff == "ei" then
			ret = CCEaseIn:create(ret, data.eff_t)
		elseif data.eff == "eo" then
			ret = CCEaseOut:create(ret, data.eff_t)
		elseif data.eff == "eio" then
			ret = CCEaseInOut:create(ret, data.eff_t)
		elseif data.eff == "bi" then
			ret = CCEaseBackIn:create(ret)
		elseif data.eff == "bo" then
			ret = CCEaseBackOut:create(ret)
		elseif data.eff == "bio" then
			ret = CCEaseBackInOut:create(ret)
		else
			cclog("ERROR, unhandle action type=" .. data.type)
		end
	end

	return ret
end

function run_action_seq(node, tmp_obj_table)
	if node and #tmp_obj_table > 0 then
		local tmp_seq = CCArray:create()

		for i = 1, #tmp_obj_table do
			if type(tmp_obj_table[i]) == "table" then
				tmp_seq:addObject(createActionByStyle(tmp_obj_table[i]))
			else
				tmp_seq:addObject(tmp_obj_table[i])
			end
		end

		node:runAction(CCSequence:create(tmp_seq))
	end
end

function which_weeks(date_t)
	if date_t == nil then
		date_t = os.date("*t")
	end

	local wday = date_t.wday - 1

	if wday <= 0 then
		wday = 7
	end

	local yday = date_t.yday

	if not wday or not yday then
		return
	end

	local diff_days = yday - wday

	if diff_days < 0 then
		return 1
	end

	local weeks = math.floor(diff_days / 7)

	if diff_days % 7 == 0 then
		return weeks + 1
	else
		return weeks + 2
	end
end

function getPassDay(sec)
	local n = sec + 28800
	local day = n / 24 / 60 / 60

	return math.floor(day)
end

function getPassWeek(sec)
	local day = getPassDay(sec) + 3
	local week = day / 7

	return math.floor(week)
end

function downwardDisplayHZ(parent, hzStr, fontSize, defs)
	local heightTable = {}
	local labelTable = {}
	local totalHeight = 0

	for uchar in string.gfind(hzStr, "[%z-\\xc2-\\xf4][\\x80-\\xbf]*") do
		local label = createByStyle({
			font = "arial",
			type = "label",
			string = uchar,
			fontsize = fontSize
		})

		if defs.color then
			label:setColor(defs.color)
		end

		local height = label:getContentSize().height

		table.insert(labelTable, 1, label)
		table.insert(heightTable, 1, height)

		totalHeight = totalHeight + height

		if defs and defs.z then
			parent:addChild(label, defs.z)
		else
			parent:addChild(label)
		end
	end

	if defs.centerPos then
		local centerPos = defs.centerPos
		local startY = centerPos.y + totalHeight / 2
		local offset = 0

		for i = #labelTable, 1, -1 do
			local label = labelTable[i]

			label:setPosition(centerPos.x, startY - offset)

			offset = offset + heightTable[i]

			label:setAnchorPoint(ccp(0.5, 1))
		end
	elseif defs.upPos then
		local upPos = defs.upPos

		for i = #labelTable, 1, -1 do
			local label = labelTable[i]

			label:setPosition(upPos.x, upPos.y - offset)

			offset = offset + heightTable[i]

			label:setAnchorPoint(ccp(0.5, 1))
		end
	end
end

function first_week1_mday(wday, mday)
	if mday < wday then
		mday = mday + 7
	end

	local mod_value = (mday - wday + 1) % 7

	if mod_value == 0 then
		return 7
	else
		return mod_value
	end
end

local g_utf_min = {
	0,
	192,
	224,
	240,
	248,
	252
}

function splitUTF8String(str)
	local result = {}

	if str then
		local length = #str
		local num, wordLength = nil
		local pos = 1

		while length >= pos do
			num = string.byte(str, pos)
			wordLength = 1

			for k, v in ipairs(g_utf_min) do
				if v <= num then
					wordLength = k
				else
					break
				end
			end

			table.insert(result, string.sub(str, pos, pos + wordLength - 1))

			pos = pos + wordLength
		end
	end

	return result
end

function check_week_range(cur_wday, cur_mday, week_index)
	cur_wday = cur_wday - 1

	if cur_wday == 0 then
		cur_wday = 7
	end

	local week1_mday = first_week1_mday(cur_wday, cur_mday)
	local begin_mday = week1_mday + (week_index - 1) * 7
	local end_mday = week1_mday + (week_index - 0) * 7

	if begin_mday <= cur_mday and cur_mday < end_mday then
		return true
	else
		return false
	end
end

function layoutSprites(list, position, isVertical)
	local lengths = {}
	local total = 0

	for i = 1, #list do
		if isVertical then
			_, lengths[i] = getRealScale(list[i])
		else
			lengths[i], _ = getRealScale(list[i])
		end

		total = total + lengths[i]
	end

	local startA, startB, attrA, attrB, offset = nil

	if isVertical then
		attrA = "y"
		attrB = "x"
		startA = position.y + 0.5 * total
		startB = position.x
		offset = -1
	else
		attrA = "x"
		attrB = "y"
		startA = position.x - 0.5 * total
		startB = position.y
		offset = 1
	end

	for i = 1, #list do
		setStyles(list[i], {
			[attrA] = startA + 0.5 * lengths[i] * offset,
			[attrB] = startB
		})

		startA = startA + lengths[i] * offset
	end
end

function clearLayer(parent, zorder, tag)
	if not parent or not zorder or not tag then
		return
	end

	local layer = parent:getChildByTag(tag)

	if layer then
		layer:removeAllChildrenWithCleanup(true)
	else
		layer = CCLayer:create()

		parent:addChild(layer, zorder, tag)
	end

	return layer
end

function getGoldCostEnsureLayer(params, yes_func, no_func)
	local layer = CCLayer:create()

	createSwallowTouchLayer(layer)

	local bkg = createByStyle({
		pic = "v2/secretArea/info_bkg.png",
		x = 0.5,
		y = 0.5
	})

	layer:addChild(bkg)

	local w1, h1 = getRealScale(bkg)
	local str1 = d_hz.gethz("consumeHZ") .. ": " .. params.count .. " "
	local label_txt1 = createByStyle({
		font = "arial",
		type = "label",
		fontsize = 26,
		string = str1,
		color = {
			225,
			207,
			185
		}
	})

	layer:addChild(label_txt1, 1)

	local goldIcon = CCSprite:create("v2/money_gold.png")

	layer:addChild(goldIcon, 1)
	layoutSprites({
		label_txt1,
		goldIcon
	}, {
		x = 0.5,
		y = 0.5 + 0.06 * h1
	})

	local label_txt2 = createByStyle({
		font = "arial",
		type = "label",
		x = 0.5,
		fontsize = 26,
		string = params.string,
		y = 0.5 - 0.09 * h1,
		size = CCSizeMake(384, 0),
		color = {
			225,
			207,
			185
		}
	})

	layer:addChild(label_txt2, 1)

	local function pressYes()
		remove(layer)

		if yes_func then
			yes_func()
		end
	end

	local function pressNo()
		remove(layer)

		if no_func then
			no_func()
		end
	end

	local menu_btn_list = {
		{
			npic = "v2/multi-selectUI/ensure1.png",
			scale = 0.15,
			spic = "v2/multi-selectUI/ensure2.png",
			x = 0.5 + w1 * 0.25,
			y = 0.5 - 0.34 * h1,
			call_back = pressYes
		},
		{
			npic = "v2/buttons/cancel1.png",
			scale = 0.15,
			spic = "v2/buttons/cancel2.png",
			x = 0.5 - w1 * 0.25,
			y = 0.5 - 0.34 * h1,
			call_back = pressNo
		},
		x = 0,
		y = 0
	}

	layer:addChild(createMenu(menu_btn_list), 2)

	return layer
end

function popWarningLayer(params, yes_func, no_func)
	local layer = CCLayer:create()

	createSwallowTouchLayer(layer)

	local bkg = createByStyle({
		pic = "v2/secretArea/info_bkg.png",
		x = 0.5,
		y = 0.5
	})

	layer:addChild(bkg)

	local w1, h1 = getRealScale(bkg)
	local label_txt2 = createByStyle({
		font = "arial",
		type = "label",
		x = 0.5,
		fontsize = 26,
		string = params,
		y = 0.55 - 0.09 * h1,
		size = CCSizeMake(384, 0),
		color = {
			225,
			207,
			185
		}
	})

	layer:addChild(label_txt2, 100)

	local function pressYes()
		remove(layer)

		if yes_func then
			yes_func()
		end
	end

	local function pressNo()
		remove(layer)

		if no_func then
			no_func()
		end
	end

	local menu_btn_list = {
		{
			npic = "v2/multi-selectUI/ensure1.png",
			scale = 0.15,
			spic = "v2/multi-selectUI/ensure2.png",
			x = 0.5 + w1 * 0.25,
			y = 0.5 - 0.34 * h1,
			call_back = pressYes
		},
		{
			npic = "v2/buttons/cancel1.png",
			scale = 0.15,
			spic = "v2/buttons/cancel2.png",
			x = 0.5 - w1 * 0.25,
			y = 0.5 - 0.34 * h1,
			call_back = pressNo
		},
		x = 0,
		y = 0
	}

	layer:addChild(createMenu(menu_btn_list), 200)

	return layer
end
