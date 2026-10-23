local require = require
local bits = bits
local sqlite = sqlite
local type = type
local print = print
local tostring = tostring
local pairs = pairs
local string = string
local table = table
local main_server = main_server
local _G = _G
local bits = bits
local CCLuaLog = CCLuaLog
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
local CCRotateBy = CCRotateBy
local CCRotateTo = CCRotateTo
local CCNode = CCNode
local CCRepeat = CCRepeat
local CCSequence = CCSequence
local CCCallFuncN = CCCallFuncN
local CCSpawn = CCSpawn
local CCMoveBy = CCMoveBy
local CCMoveTo = CCMoveTo
local CCPoint = CCPoint
local CCPointMake = CCPointMake
local CCDelayTime = CCDelayTime
local math = math
local CCBezierBy = CCBezierBy
local ccBezierConfig = ccBezierConfig
local CCBezierTo = CCBezierTo
local CCScaleBy = CCScaleBy
local ccColor3B = ccColor3B
local ccColor4B = ccColor4B
local CCBReader = CCBReader
local CCNodeLoaderLibrary = CCNodeLoaderLibrary
local CCBAnimationManager = CCBAnimationManager
local CCLayerColor = CCLayerColor
local CCRectMake = CCRectMake
local CCFadeOut = CCFadeOut
local ccc4 = ccc4
local CCFadeIn = CCFadeIn
local CCTargetedAction = CCTargetedAction
local CCScaleBy = CCScaleBy
local CCScaleTo = CCScaleTo
local CCLabelBMFont = CCLabelBMFont
local CCFadeTo = CCFadeTo
local CCBlink = CCBlink
local CCEaseOut = CCEaseOut
local CCEaseIn = CCEaseIn
local CCEaseBackOut = CCEaseBackOut
local CCEaseBackIn = CCEaseBackIn
local CCEaseElasticInOut = CCEaseElasticInOut
local CCEaseElasticOut = CCEaseElasticOut
local CCEaseElasticIn = CCEaseElasticIn

module("skill.skillExt")

d_ms = require("ms")

if not d_ms then
	CCLuaLog("skill.skillExt load d_ms fail.")
end

local function cclog(...)
	CCLuaLog(string.format(...))
end

g_is_crit = false
g_is_k = nil
k_ps = d_ms.d_c.k_params
local c_p = d_ms.d_common_def.cortege_property
local e_l_t = d_ms.d_common_def.elite_logic_type

function set_fight_step_begin_delay(time)
	if d_ms.d_fightUI.fight_step_begin_delay < time then
		d_ms.d_fightUI.fight_step_begin_delay = time
	end
end

function set_fight_step_after_delay(time)
	if d_ms.d_fightUI.fight_step_after_delay < time then
		d_ms.d_fightUI.fight_step_after_delay = time
	end
end

function set_fight_delay_time(begin_time, after_time)
	set_fight_step_begin_delay(begin_time)
	set_fight_step_after_delay(after_time)
end

function isStarSkill(type)
	if type > 103000 and type < 150000 then
		return true
	else
		return false
	end
end

function isKSkillExt(logic)
	if logic and logic <= e_l_t.s_clear_jiaosha and e_l_t.s_shizun <= logic then
		return true
	else
		return false
	end
end

function showSkillExt(v)
	cclog("call showSkillExt")

	local logic_type = v.logic_type % 1000

	if isStarSkill(v.logic_type) then
		if logic_type == 111 then
			g_is_crit = true
		elseif logic_type == 151 then
			showMiansi(v)
		else
			cclog("unhanded skill star ext, type=" .. (logic_type or "null"))
		end

		return
	elseif v.logic_type == 150152 then
		g_is_crit = true

		return
	end

	if isKSkillExt(v.logic_type) then
		if v.logic_type == e_l_t.s_shizun then
			cclog("*******************shizunshizunshizunshizunshizunshizunshizunshiz")
			showShizun(v)
		elseif v.logic_type == e_l_t.s_jiaosha then
			cclog("*******************jiaoshajiaoshajiaoshajiaoshajiaoshajiaoshajiaos")
			showJiaosha(v)
		elseif v.logic_type == e_l_t.s_clear_jiaosha then
			cclog("*******************s_clear_jiaoshas_clear_jiaoshas_clear_jiaosha")
			showJiaoshaClear(v)
		elseif v.logic_type == e_l_t.s_tianqian then
			cclog("*******************tianqiantianqiantianqiantianqiantianqiantianqian")
		else
			cclog("unhanded skill star ext, type=" .. (logic_type or "null"))
		end

		return
	end

	if v.logic_type >= 150000 and v.logic_type <= 160000 then
		if v.logic_type == 150031 then
			showHuifu(v)
		end

		if v.logic_type == 150061 then
			showFanShang(v)
		end

		if v.logic_type == 150081 or v.logic_type == 150082 or v.logic_type == 150083 then
			showZiBao(v)
		end

		if v.logic_type == 150111 then
			showZiBaoCure(v)
		end

		if v.logic_type == 150121 then
			showHuifu(v)
		end

		return
	end

	if logic_type == 11 then
		showWeiShe(v)
	elseif logic_type == 12 then
		showWeiSheReduceDmg(v)
	elseif logic_type == 13 then
		showWeiSheCancel(v)
	elseif logic_type == 21 then
		showPojia1(v)
	elseif logic_type == 31 then
		showFanji(v)
	elseif logic_type == 41 then
		showFanjiwuxiao(v)
	elseif logic_type == 51 then
		showXixue(v)
	elseif logic_type == 61 then
		showGedang(v)
	elseif logic_type == 71 then
		showLianji(v)
	elseif logic_type == 81 then
		showFaKang(v)
	elseif logic_type == 91 then
		showFaChuang(v)
	elseif logic_type == 101 then
		showHuifu(v)
	elseif logic_type == 111 then
		showQiangxi(v)
	elseif logic_type == 121 then
		showZhanyi(v)
	elseif logic_type == 131 then
		-- Nothing
	elseif logic_type == 141 then
		-- Nothing
	elseif logic_type == 142 then
		showXingyun(v)
	elseif logic_type == 151 then
		showBudao(v)
	elseif logic_type == 161 then
		showZhongdu(v)
	elseif logic_type == 162 then
		showZhongduHP(v)
	elseif logic_type == 163 then
		showZhongduTimeOver(v)
	elseif logic_type == 171 then
		showJiedu(v)
	elseif logic_type == 181 then
		showZhufu(v)
	elseif logic_type == 191 then
		showFuhuo(v)
	elseif logic_type == 200 then
		showDaZangJingChuFa(v)
	elseif logic_type == 201 then
		showDaZangJingXiShou(v)
	elseif logic_type == 202 then
		showDaZangJingTimeOver(v)
	elseif logic_type == 203 then
		showDaZangJingHuDun(v)
	else
		cclog("unhanded skill ext, type=" .. (logic_type or "null"))
	end
end

function showSkillExtPassive(skill_info)
	local logic_type = skill_info.attackInfo.skill_type % 1000

	cclog("call showSkillExtPassive  %d", logic_type)

	if logic_type == 131 then
		showQiangzhuang(skill_info)
	elseif logic_type == 181 then
		showZhufu(skill_info)
	else
		cclog("unhanded skill passive ext, type=" .. (logic_type or "null"))
	end
end

function showShizun(v)
	local hp_add = 0
	local hp_max_add = 0
	local des_order = nil

	for m, n in pairs(v.skill_result_list) do
		if n.field == c_p.hp then
			des_order = n.des_order
			hp_add = n.field_plus
		elseif n.field == c_p.max_hp_calc then
			hp_max_add = n.field_plus
		end
	end

	local tmp_v = {
		self_use = true,
		logic_type = v.logic_type,
		src_order = v.src_order,
		who_use = v.who_use,
		skill_result_list = {
			{
				field = 9999,
				des_order = des_order or v.src_order,
				field_plus = hp_add,
				hp_add = hp_add,
				hp_max_add = hp_max_add
			}
		}
	}

	showOnceCCbiEffect(tmp_v, "zhufu001.ccbi", 1, false, 4)
end

function showJiaosha(v)
	set_fight_delay_time(1.2, 2)
	addDebuff(v, 0)
end

function showJiaoshaClear(v)
	set_fight_delay_time(1.5, 0.5)
	removeDebuff(v, 0.3)
end

function showWeiShe(v)
	set_fight_delay_time(1.2, 1.5)
	addDebuff(v, 2.5)
end

function showWeiSheReduceDmg(v)
	return

	set_fight_delay_time(0, 0.8)

	local function show_me_later()
		showNameOnly(v, 0)
	end

	d_ms.d_u.delay(d_ms.d_fightUI.g_fightUI.layerFrontground, 1.3, show_me_later)
end

function showWeiSheCancel(v)
	set_fight_delay_time(1.5, 0.5)
	removeDebuff(v, 0.3)
end

function showPojia1(v)
	set_fight_delay_time(1.2, 1)

	g_fanjiwuxiao = true

	showOnceCCbiEffect(v, "pojia001.ccbi", 2.5)
end

function showFanji(v)
	g_fanjiwuxiao = true

	set_fight_delay_time(0.5, 0.2)
	showNameOnly(v, 0)
end

g_fanjiwuxiao = false

function showFanjiwuxiao(v)
	set_fight_delay_time(0, 0.2)

	g_fanjiwuxiao = true

	local function show_me_later()
		showOnceCCbiEffect(v, "fashufanghu.ccbi", 0, true)
	end

	d_ms.d_u.delay(d_ms.d_fightUI.g_fightUI.layerFrontground, 0.5, show_me_later)
end

function showXixue(v)
	set_fight_delay_time(1, 1)

	local function show_me_later()
		showOnceCCbiEffect(v, "xixue001.ccbi", 1.2, true, 3)
	end

	d_ms.d_u.delay(d_ms.d_fightUI.g_fightUI.layerFrontground, 1.5, show_me_later)
end

function showMiansi(v)
	g_fanjiwuxiao = true

	set_fight_delay_time(0, 0.2)

	local function show_me_later()
		showOnceCCbiEffect(v, "127_2.ccbi", 1, true, 3)
	end

	d_ms.d_u.delay(d_ms.d_fightUI.g_fightUI.layerFrontground, 0, show_me_later)

	for i, vv in pairs(v.skill_result_list) do
		if vv.field_plus and vv.field_plus > 0 then
			local des_name = getEffectName(v, vv)
			d_ms.d_fightUI.g_fight_events_freeDead[des_name] = vv.field_plus
		end
	end
end

function showGedang(v)
	g_fanjiwuxiao = true

	set_fight_delay_time(0, 0.2)

	local function show_me_later()
		showOnceCCbiEffect(v, "gedang001.ccbi", 0, true, 3)
	end

	d_ms.d_u.delay(d_ms.d_fightUI.g_fightUI.layerFrontground, 0, show_me_later)
end

function showLianji(v)
	g_fanjiwuxiao = true

	set_fight_delay_time(0.8, 0.3)
	showNameOnly(v, 0)
end

function showFaKang(v)
	set_fight_delay_time(0.5, 0.5)
	showOnceCCbiEffect(v, "fashufanghu001.ccbi", 0, true, 3)
end

function showFaChuang(v)
	set_fight_delay_time(2, 1)

	local function show_me_later()
		showOnceCCbiEffect(v, "fashuchuantou001.ccbi", 2, false, 3)
	end

	d_ms.d_u.delay(d_ms.d_fightUI.g_fightUI.layerFrontground, 1, show_me_later)
end

function showHuifu(v)
	local char_layer = d_ms.d_fightUI.g_fightUI.layerChar

	set_fight_delay_time(1, 0)

	for i, vv in pairs(v.skill_result_list) do
		local char = getTarget(v, vv)

		if char then
			local pos = char.posXYZ

			function call_me_later()
				d_ms.d_u.createAnimation("huifu001.ccbi", {
					scale = 2.5,
					x = pos.x,
					y = pos.y,
					z = pos.z + 1
				}, 2, nil, char_layer)
				showSkillExtAttr(v, char, char_layer, vv)
			end

			d_ms.d_u.delay(char_layer, 0, call_me_later)
		end
	end
end

function showQiangxi(v)
	g_fanjiwuxiao = true

	set_fight_delay_time(1, 0)
	showNameOnly(v, 0)

	local char_layer = d_ms.d_fightUI.g_fightUI.layerChar

	for i, vv in pairs(v.skill_result_list) do
		local char = getTarget(v, vv)

		if char then
			table.insert(char.last_ext_damage_list, vv.field_plus)
		end
	end
end

function showZhanyi(v)
	set_fight_delay_time(1.7, 0.3)

	local scale = g_is_k and 2 or 3

	showOnceCCbiEffect(v, "zhanyi001.ccbi", 1.5, false, scale)
end

function showQiangzhuang(v)
	local t_who_use = 1

	if v.attackInfo.is_src == false then
		t_who_use = 2
	end

	local t_field_plus = v.attackInfo.damage_list[v.attackInfo.des_order]
	local tmp_v = {
		self_use = true,
		logic_type = v.attackInfo.skill_type,
		src_order = v.attackInfo.src_order,
		who_use = t_who_use,
		skill_result_list = {
			{
				field = 71,
				des_order = v.attackInfo.des_order,
				field_plus = t_field_plus
			}
		}
	}

	showOnceCCbiEffect(tmp_v, "zhiliao001.ccbi", 0.5, true, 2.5)

	if v.call_back then
		local function call_me_later()
			v.call_back(v.attacker)
		end

		d_ms.d_u.delay(v.layer, 2, call_me_later)
	end
end

function showXingyun(v)
	g_fanjiwuxiao = true

	set_fight_delay_time(0, 0.8)

	local function show_me_later()
		showNameOnly(v, 0)
	end

	d_ms.d_u.delay(d_ms.d_fightUI.g_fightUI.layerFrontground, 1.3, show_me_later)
end

function showBudao(v)
	set_fight_delay_time(1.2, 0.5)
	showNameOnly(v, 0)
end

function showZhongdu(v)
	set_fight_delay_time(0, 1)
	addDebuff(v, 1.2)
end

function showZhongduHP(v)
	local begin_time = 0.5

	for i, vv in pairs(v.skill_result_list) do
		local char = getTarget(v, vv)

		if vv.field_plus and char.hp + vv.field_plus <= 0 then
			begin_time = 1.5

			break
		end
	end

	set_fight_delay_time(begin_time, 0.5)
	showAttrOnly(v, 0.2)
end

function showFanShang(v)
	for i, vv in pairs(v.skill_result_list) do
		local char = getTarget(v, vv)

		if vv.field_plus and char.hp + vv.field_plus <= 0 then
			-- Nothing
		end
	end

	showAttrOnly(v, 0.1)
end

function showZiBao(v)
	for i, vv in pairs(v.skill_result_list) do
		if vv.field_plus then
			local des_name = getEffectNameZB(v, vv)
			d_ms.d_fightUI.g_fight_events_zibao[des_name] = vv.field_plus + 1
		end
	end
end

function showZiBaoCure(v)
	for i, vv in pairs(v.skill_result_list) do
		if vv.field_plus then
			local des_name = getEffectName(v, vv)
			d_ms.d_fightUI.g_fight_events_zibaocure[des_name] = vv.field_plus + 1
		end
	end
end

function getEffectNameZB(v, vv)
	local des_name = nil
	v.who_use = v.who_use or 1
	v.self_use = v.self_use or false
	local des_order = nil

	if vv and vv.des_order then
		des_order = vv.des_order
	else
		des_order = v.des_order
	end

	if v.who_use == 1 and v.self_use == true then
		des_name = "o" .. des_order
	elseif v.who_use == 1 and v.self_use == false then
		des_name = "o" .. des_order
	elseif v.who_use == 2 and v.self_use == true then
		des_name = "o" .. des_order
	else
		des_name = "o" .. des_order
	end

	return des_name
end

function showZhongduTimeOver(v)
	set_fight_delay_time(0.2, 0.2)
	removeDebuff(v, 0.2)
end

function showJiedu(v)
	set_fight_delay_time(2, 0.5)
	showNameOnly(v, 0.3)
	removeDebuff(v, 1.3)
end

function showZhufu(v)
	local t_who_use = 1

	if v.attackInfo.is_src == false then
		t_who_use = 2
	end

	local t_field_plus = v.attackInfo.damage_list[v.attackInfo.des_order]
	local tmp_v = {
		self_use = true,
		logic_type = v.attackInfo.skill_type,
		src_order = v.attackInfo.src_order,
		who_use = t_who_use,
		skill_result_list = {
			{
				field = 999,
				des_order = v.attackInfo.des_order,
				field_plus = t_field_plus
			}
		}
	}

	showOnceCCbiEffect(tmp_v, "zhufu001.ccbi", 1, false, 4)

	if v.call_back then
		local function call_me_later()
			v.call_back(v.attacker)
		end

		d_ms.d_u.delay(v.layer, 2, call_me_later)
	end
end

g_fuhuo_func = nil

function showFuhuoName()
	if g_fuhuo_func then
		g_fuhuo_func()

		g_fuhuo_func = nil
	end
end

function showFuhuo(v)
	local function showFuhuoName()
		showNameOnly(v, 0)
	end

	g_fuhuo_func = showFuhuoName

	for i, vv in pairs(v.skill_result_list) do
		if vv.field_plus and vv.field_plus > 0 then
			local des_name = getEffectName(v, vv)
			d_ms.d_fightUI.g_fight_events_revive[des_name] = vv.field_plus
		end
	end
end

function getEffectName(v, vv)
	local des_name = nil
	v.who_use = v.who_use or 1
	v.self_use = v.self_use or false
	local des_order = nil

	if vv and vv.des_order then
		des_order = vv.des_order
	else
		des_order = v.des_order
	end

	if v.who_use == 1 and v.self_use == true then
		des_name = "o" .. des_order
	elseif v.who_use == 1 and v.self_use == false then
		des_name = "e" .. des_order
	elseif v.who_use == 2 and v.self_use == true then
		des_name = "e" .. des_order
	else
		des_name = "o" .. des_order
	end

	return des_name
end

function getCasterName(v)
	local src_name = nil
	v.who_use = v.who_use or 1

	if v.who_use == 1 then
		src_name = "o" .. v.src_order
	else
		src_name = "e" .. v.src_order
	end

	return src_name
end

function getCaster(v)
	local name = getCasterName(v)

	return d_ms.d_fightUI.g_fightUI.tableChar[name]
end

function getTarget(v, vv)
	local name = getEffectName(v, vv)

	return d_ms.d_fightUI.g_fightUI.tableChar[name]
end

function createCcbi(buff_type, posXYZ, layer)
	if buff_type == 101011 or buff_type == 102011 then
		d_ms.d_u.createAnimation_new("weisheshu_001.ccbi", {
			scale = 1.5,
			x = posXYZ.x,
			y = posXYZ.y,
			z = posXYZ.z + 2
		}, 2, nil, layer)
	elseif buff_type == 101161 or buff_type == 102161 then
		d_ms.d_u.createAnimation_new("zhongdushu_001.ccbi", {
			scale = 1.5,
			x = posXYZ.x,
			y = posXYZ.y,
			z = posXYZ.z + 2
		}, 2, nil, layer)
	elseif buff_type == 100200 then
		d_ms.d_u.createAnimation_new("dachengjinghudun.ccbi", {
			scale = 1.5,
			x = posXYZ.x,
			y = posXYZ.y,
			z = posXYZ.z + 2
		}, 2, nil, layer)
	elseif buff_type == e_l_t.s_jiaosha then
		cclog("s_jiaosha, no ccbi, ignore")
	else
		cclog("ERROR: unhandld ccbi_buff, type=" .. buff_type)
	end

	local ret = nil

	if buff_type == e_l_t.s_jiaosha then
		ret = d_ms.d_u.createByStyle({
			pic = "v2/fightUI/lock.png"
		})
	elseif buff_type == 100200 then
		ret = d_ms.d_data.getSmallSkillSprite(21)
	else
		ret = d_ms.d_data.getSmallItemSprite(math.floor(buff_type / 10))
	end

	return ret
end

function showCommonSpell(v)
	local char_layer = d_ms.d_fightUI.g_fightUI.layerChar
	local char = getCaster(v)
	local pos = char.posXYZ
	local node = nil

	function clean_me()
		d_ms.d_u.remove(node)

		node = nil
	end

	local scale = g_is_k and 1.6 or 2.5
	node = d_ms.d_u.createAnimation("qishouji001.ccbi", {
		scale = scale,
		x = pos.x,
		y = pos.y + 0.1,
		z = pos.z + 30
	}, 2, clean_me, char_layer)
end

function showSkillExtName(v, layer)
	local quality = 4

	if v.logic_type % 10000 > 2000 then
		quality = 5
	end

	local node = CCNode:create()
	local sprite_name = nil
	local pos = getCaster(v) and getCaster(v).posXYZ
	pos = pos or {
		x_head = 0.2,
		z = 1300,
		y = 0.25,
		y_head = 0.9,
		x = 0.2
	}
	local x_ = 0.5

	if v.who_use == 2 then
		x_ = -0.5
	end

	local ext_name_scale = g_is_k and k_ps.ext_name_scale or 0.1
	local ext_bg_scale = g_is_k and k_ps.ext_bg_scale or 0.3
	local ext_name_offy = g_is_k and k_ps.ext_name_offy or 0.3

	if v.logic_type % 10 == 1 or v.logic_type % 1000 == 142 then
		local skill_id = math.floor(v.logic_type / 10) % 100
		sprite_name = d_ms.d_u.createByStyle({
			pic = "skill/ext/" .. quality * 100 + skill_id .. "n.png",
			x = pos.x - x_,
			y = pos.y + ext_name_offy,
			scaleH = ext_name_scale
		})
	elseif not isStarSkill(v.logic_type) and not isKSkillExt(v.logic_type) then
		cclog("ERROR: unhandled logic_type=" .. v.logic_type)
	end

	local bg = d_ms.d_u.createByStyle({
		pic = "skill/ext/bg" .. quality .. ".png",
		x = pos.x - x_,
		y = pos.y + ext_name_offy,
		scale = ext_bg_scale
	})

	if isStarSkill(v.logic_type) then
		sprite_name = d_ms.d_u.createByStyle({
			pic = "skill/star/" .. v.logic_type % 1000 .. ".png",
			x = pos.x - x_,
			y = pos.y + ext_name_offy,
			scaleH = ext_name_scale
		})
		bg = d_ms.d_u.createByStyle({
			pic = "skill/star/bg.png",
			x = pos.x - x_,
			y = pos.y + ext_name_offy,
			scale = ext_bg_scale
		})
	end

	if isKSkillExt(v.logic_type) and v.logic_type == e_l_t.s_shizun then
		sprite_name = d_ms.d_u.createByStyle({
			pic = "skill/kfight/" .. v.logic_type .. ".png",
			x = pos.x - x_,
			y = pos.y + ext_name_offy,
			scaleH = ext_name_scale
		})
		bg = d_ms.d_u.createByStyle({
			pic = "skill/star/bg.png",
			x = pos.x - x_,
			y = pos.y + ext_name_offy,
			scale = ext_bg_scale,
			color = {
				0,
				255,
				0
			}
		})
	end

	if sprite_name then
		node:addChild(sprite_name, 2)
		node:addChild(bg, 1)

		local function cleanMe_later()
			d_ms.d_u.remove(node)

			node = nil
		end

		local len = 0.1
		local small2big_actions = {
			{
				{
					eff = "eo",
					moveby = {
						y = 0,
						t = 5 * len,
						x = x_
					},
					eff_t = 3 * len
				},
				{
					delay = 22 * len
				},
				{
					func = cleanMe_later
				}
			},
			{
				{
					delay = 17 * len
				},
				{
					eff = "ei",
					fadeout = 10 * len,
					eff_t = 7 * len
				}
			}
		}

		sprite_name:runAction(d_ms.d_u.create_action(small2big_actions))
		bg:runAction(d_ms.d_u.create_action(small2big_actions))
		layer:addChild(node, 100)
	end
end

local function isReduceSkillExt(type)
	local logic_type = type % 1000

	if logic_type == 21 then
		return true
	else
		return false
	end
end

function showSkillExtAttr(v, char, layer, vv)
	local posXYZ = char.posXYZ
	local save_hp = char.hp

	if vv and vv.field and vv.field_plus and vv.field > 0 and vv.field ~= c_p.dizzy_cortege then
		local node = CCNode:create()
		vv.field_plus = math.floor(vv.field_plus)
		local pic_path = nil

		if vv.field >= 65 and vv.field <= 68 then
			pic_path = "skill/ext/att" .. vv.field .. ".png"

			if vv.field == 65 then
				char.hp = char.hp + vv.field_plus

				if char.hp <= 0 then
					d_ms.d_fightUI.calAllHp(save_hp, char.isEnemy)
				else
					d_ms.d_fightUI.calAllHp(0 - vv.field_plus, char.isEnemy)
				end
			end
		elseif vv.field == 71 then
			pic_path = "skill/ext/att65.png"
			char.hp_max = char.hp_max + vv.field_plus
			char.hp = char.hp + vv.field_plus

			d_ms.d_fightUI.calAllHp(0 - vv.field_plus, char.isEnemy, vv.field_plus)
		elseif vv.field == 999 then
			pic_path = "skill/ext/att_all_up.png"
			char.hp_max = char.hp_max + vv.field_plus
			char.hp = char.hp + vv.field_plus

			d_ms.d_fightUI.calAllHp(0 - vv.field_plus, char.isEnemy, vv.field_plus)
		elseif vv.field == 9999 then
			pic_path = "skill/ext/att_all_up.png"
			char.hp_max = char.hp_max + vv.hp_max_add
			char.hp = char.hp + vv.hp_add

			d_ms.d_fightUI.calAllHp(0 - vv.hp_add, char.isEnemy, vv.hp_max_add)
		else
			pic_path = "v2/indicator_alert.png"

			cclog("ERROR: unknow property pic.")
		end

		local color_ = nil

		if vv.field_plus >= 0 then
			if vv.field_plus == 0 and isReduceSkillExt(v.logic_type) then
				color_ = {
					210,
					0,
					0
				}
			else
				color_ = {
					0,
					210,
					0
				}
			end
		else
			color_ = {
				210,
				0,
				0
			}
		end

		local add_offy = g_is_k and k_ps.add_offy or 0.21
		local add_scale = g_is_k and k_ps.add_scale or 0.09
		local head = d_ms.d_u.createByStyle({
			pic = pic_path,
			x = posXYZ.x - add_scale,
			y = posXYZ.y + add_offy,
			color = color_,
			anchor = {
				0,
				0.5
			}
		})

		if g_is_k and vv.field ~= 999 and vv.field ~= 9999 then
			d_ms.d_u.setStyles(head, {
				scale = 0.06,
				x = posXYZ.x - add_scale,
				y = posXYZ.y + add_offy
			})
		end

		local w, h = d_ms.d_u.getRealScale(head)
		local numb = nil

		if vv.field == 999 or vv.field == 9999 then
			numb = nil
		elseif vv.field_plus >= 0 then
			if vv.field_plus == 0 and isReduceSkillExt(v.logic_type) then
				numb = d_ms.d_hz.showNumber("-" .. vv.field_plus, {
					x = posXYZ.x + w - add_scale,
					y = posXYZ.y + add_offy,
					scale = add_scale,
					anchor = {
						0,
						0.5
					},
					color = color_
				})
			else
				numb = d_ms.d_hz.showAddNumber("+" .. vv.field_plus, {
					x = posXYZ.x + w - add_scale,
					y = posXYZ.y + add_offy,
					scale = add_scale,
					anchor = {
						0,
						0.5
					}
				})
			end
		else
			numb = d_ms.d_hz.showNumber(vv.field_plus, {
				x = posXYZ.x + w - add_scale,
				y = posXYZ.y + add_offy,
				scale = add_scale,
				anchor = {
					0,
					0.5
				},
				color = color_
			})
		end

		if not char then
			-- Nothing
		else
			char:resetBlood()

			if char.hp <= 0 then
				if save_hp > 0 then
					char:doDead()
				end
			end
		end

		if head then
			node:addChild(head)
		end

		if numb then
			node:addChild(numb)
		end

		if node then
			local function cleanMe_later()
				d_ms.d_u.remove(node)

				node = nil
			end

			local len = 0.1
			local up_actions = {
				{
					{
						delay = 2 * len
					},
					{
						eff = "ei",
						eff_t = 0.3,
						moveby = {
							y = 0.1,
							x = 0,
							t = 13 * len
						}
					},
					{
						func = cleanMe_later
					}
				},
				{
					{
						delay = 9 * len
					},
					{
						fadeout = 6 * len
					}
				}
			}

			if head then
				head:runAction(d_ms.d_u.create_action(up_actions))
			end

			if numb then
				numb:runAction(d_ms.d_u.create_action(up_actions))
			end

			layer:addChild(node, char.posXYZ.z + 50)
		end
	end
end

function showNameOnly(v, delay_time, no_show_spell)
	if no_show_spell ~= true then
		showCommonSpell(v)
	end

	local char_layer = d_ms.d_fightUI.g_fightUI.layerFrontground

	function call_show_name_later()
		showSkillExtName(v, char_layer)
	end

	d_ms.d_u.delay(char_layer, delay_time, call_show_name_later)
end

function showOnceCCbiEffect(v, ccbi_name, delay_time, no_show_spell, scale)
	local char_layer = d_ms.d_fightUI.g_fightUI.layerFrontground
	local ccbi_scale = scale or 2

	if no_show_spell ~= true then
		showCommonSpell(v)
	end

	local function call_show_name_later()
		showSkillExtName(v, char_layer)
	end

	d_ms.d_u.delay(char_layer, 0, call_show_name_later)

	for i, vv in pairs(v.skill_result_list) do
		local char = getTarget(v, vv)

		if char then
			local pos = char.posXYZ

			local function call_me_later()
				d_ms.d_u.createAnimation(ccbi_name, {
					scale = ccbi_scale,
					x = pos.x,
					y = pos.y,
					z = pos.z + 1
				}, 2, nil, char_layer)
				showSkillExtAttr(v, char, char_layer, vv)
			end

			d_ms.d_u.delay(char_layer, delay_time, call_me_later)
		end
	end
end

function addDebuff(v, delay_time)
	local char_layer = d_ms.d_fightUI.g_fightUI.layerFrontground

	showCommonSpell(v)

	function call_show_name_later()
		showSkillExtName(v, char_layer)
	end

	d_ms.d_u.delay(char_layer, 0, call_show_name_later)

	for i, vv in pairs(v.skill_result_list) do
		local char = getTarget(v, vv)

		function call_me_later()
			char:addCcbiBuff(v.logic_type)
			showSkillExtAttr(v, char, char.layer, vv)
		end

		d_ms.d_u.delay(char_layer, delay_time, call_me_later)
	end
end

function removeDebuff(v, delay_time)
	local char_layer = d_ms.d_fightUI.g_fightUI.layerFrontground

	for i, vv in pairs(v.skill_result_list) do
		local char = getTarget(v, vv)

		if char then
			function call_me_later()
				local logic_type = nil

				if v.logic_type == 101013 then
					char:removeCcbiBuff(101011)
					char:removeCcbiBuff(102011)
				elseif v.logic_type == 102013 then
					char:removeCcbiBuff(101011)
					char:removeCcbiBuff(102011)
				elseif v.logic_type == 101163 or v.logic_type == 101171 then
					char:removeCcbiBuff(101161)
					char:removeCcbiBuff(102161)
				elseif v.logic_type == 102163 or v.logic_type == 102171 then
					char:removeCcbiBuff(101161)
					char:removeCcbiBuff(102161)
				elseif v.logic_type == e_l_t.s_clear_jiaosha then
					char:removeCcbiBuff(e_l_t.s_jiaosha)
				elseif v.logic_type == 100202 then
					char:removeCcbiBuff(100200)
				else
					cclog("ERROR, can not find buff peer, type=" .. v.logic_type)
				end

				showSkillExtAttr(v, char, char.layer, vv)
			end

			d_ms.d_u.delay(char_layer, delay_time, call_me_later)
		end
	end
end

function showAttrOnly(v, delay_time)
	local char_layer = d_ms.d_fightUI.g_fightUI.layerFrontground

	for i, vv in pairs(v.skill_result_list) do
		local char = getTarget(v, vv)

		function call_me_later()
			showSkillExtAttr(v, char, char.layer, vv)
		end

		d_ms.d_u.delay(char_layer, delay_time, call_me_later)
	end
end

function showDaZangJingChuFa(v)
	set_fight_delay_time(0, 5)
	addDebuff(v, 1.2)
end

function showDaZangJingTimeOver(v)
	set_fight_delay_time(0.2, 0.2)
	removeDebuff(v, 0.2)
end

function showDaZangJingHuDun(v)
	g_fanjiwuxiao = true

	set_fight_delay_time(0, 0.2)

	local function show_me_later()
		showOnceCCbiEffect(v, "dazhangjing.ccbi", 0, true, 1.2)
	end

	d_ms.d_u.delay(d_ms.d_fightUI.g_fightUI.layerFrontground, 0, show_me_later)
end

function showDaZangJingXiShou(v)
	g_fanjiwuxiao = true

	set_fight_delay_time(0, 0.2)

	local function show_me_later()
		showOnceCCbiEffect(v, "dachengjin.ccbi", 0, true, 1.7)
	end

	d_ms.d_u.delay(d_ms.d_fightUI.g_fightUI.layerFrontground, 1, show_me_later)
end
