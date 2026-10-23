local main_server = main_server
local adb = adb
local print = print

module("common.msg_def")

const = {
	MAX_SHOW_CORTEGE_COUNT = 3,
	MAX_CONSUME_EQUIP_COUNT = 50,
	MAX_FRIEND_SERIAL_LEN = 11,
	MAX_TASK_FLAG = 10,
	MAX_WORLD_MATCH_COUNT = 5,
	LONG_IP_LEN = 255,
	ARENA_CONFIG_BUFFER_SIZE = 49152,
	MAX_FIGHT_COUNT = 8,
	MAX_ROLE_COUNT = 5,
	MIN_REGISTER_ACCOUNT_LEN = 6,
	MAX_SEND_ACCOUNT_LEN = 33,
	MAX_MOBILE_ACCOUNT_LEN = 64,
	MIN_MOBILE_ACCOUNT_LEN = 16,
	UNNEED_SERIAL_NUM = 0,
	MAX_SKILL_COUNT = 3,
	COMMON_CONFIG_BUFFER_SIZE = 12288,
	MAX_NAME_LEN = 14,
	MAX_PP_TOKEN_KEN_LEN = 64,
	MAX_EQUIPMENT_COUNT = 3,
	FORMAT_DATE_LEN = 14,
	SERVER_SERIAL_BEGIN_NUM = 200000,
	MAX_BULLETIN_TITLE_LEN = 48,
	MAX_PF_COUPON_SN_LEN = 12,
	WORLD_CONFIG_BUFFER_SIZE = 49152,
	CHECK_STRING_LEN = 7,
	MAX_REG_IDENTITY_COUNT = 18,
	MIN_REG_IDENTITY_COUNT = 15,
	MAX_TB_TOKEN_KEN_LEN = 64,
	MAX_REGISTER_ACCOUNT_LEN = 16,
	SHORT_TOKEN_LEN = 16,
	EQUIPED_EXT_SKILL_LIMIT = 4,
	MAX_SEND_COUNT_STAR = 400,
	MAX_SEND_NAME_LEN = 32,
	MAX_SEND_COUNT = 255,
	PASS_WORD_LEN = 16,
	MAX_METERIAL_COUNT = 10,
	MAX_COUPON_LEN = 18,
	BASE_CONFIG_BUFFER_SIZE = 12288,
	CLIENT_SERIAL_BEGIN_NUM = 100000,
	MAX_ACCOUNT_LEN = 32,
	MIN_REG_NAME_COUNT = 2,
	SHORT_IP_LEN = 16,
	MAX_BULLETIN_CONTENT_LEN = 900,
	SPECIAL_FIGHT_COUNT = 9,
	ENCRYPT_SERIAL_KEY_MSG_LEN = 81,
	MIN_NAME_LEN = 4,
	MD5_STRING_LEN = 32
}
common_id = {
	type_tollgate_data = 109,
	event_connect_accept = 3,
	event_http_response = 12,
	event_close_server = 2,
	event_voice_recognition = 23,
	type_cortege_data = 114,
	type_fight_lineup = 106,
	event_fps = 8,
	type_pp_http_response = 202,
	type_change_info = 112,
	event_client_update_info = 21,
	event_client_info = 20,
	type_top_data = 110,
	type_title_list = 128,
	type_label_info = 104,
	event_log_to_client_msg = 11,
	type_player_info = 101,
	event_init_server = 1,
	type_special_fight_result = 129,
	type_attr = 108,
	event_server_disconnect = 5,
	type_skill_data = 115,
	type_attach_pos = 116,
	type_compose_data = 119,
	event_timer_for_connect = 6,
	type_object_data = 118,
	msg_update_config = 956,
	msg_dynamic_update_ret = 954,
	type_attach_data = 117,
	type_compose_material_data = 127,
	type_enum_role = 103,
	type_server_info = 102,
	type_search_player = 107,
	type_fight_result = 105,
	type_pp_http_request = 201,
	event_third_party_platform = 22,
	event_timer_for_world = 7,
	type_spirit_data = 120,
	type_cortege_spirit = 122,
	type_map_data = 111,
	type_attr_double = 130,
	event_http_request_failed = 14,
	msg_base = 100,
	msg_db_request = 951,
	msg_db_response = 952,
	event_http_request = 13,
	msg_dynamic_update = 953,
	event_client_disconnect = 4,
	type_area = 113,
	type_single_top_data = 126,
	achievements_list = 123,
	msg_query_config = 955,
	event_stat_to_client_msg = 10,
	type_lottery_data = 121,
	msg_gm_common_event = 999,
	msg_heartbeat = 1000,
	event_integral_point = 9,
	type_prize_data = 124,
	type_got_prize_data = 125
}
msg_id_segment = {
	lscl_msg_begin = 3001,
	gsdba_msg_begin = 3201,
	lsdba_msg_end = 3400,
	gsls_msg_end = 3200,
	wsdba_msg_end = 3700,
	csdba_msg_begin = 3701,
	lsdti_msg_begin = 3401,
	gsbs_msg_begin = 4001,
	gsbs_msg_end = 5000,
	clgs_msg_end = 3000,
	clgs_msg_begin = 1001,
	lscl_msg_end = 3100,
	gsls_msg_begin = 3101,
	csdba_msg_end = 3800,
	wsdba_msg_begin = 3601,
	lsdba_msg_begin = 3301,
	gsdba_msg_end = 3300,
	gsdti_msg_begin = 3501,
	common_msg_begin = 1,
	gsdti_msg_end = 3600,
	common_msg_end = 1000,
	lsdti_msg_end = 3500
}
gscl_msg_id = {
	msg_exchange_caishen_prize = 1211,
	msg_update_tollgate_list = 1020,
	msg_update_sweep_rsp = 1063,
	msg_client_gold_rush = 1207,
	msg_cortege_train_request = 1081,
	msg_common_activity = 1127,
	msg_login_rsp = 1002,
	msg_amrita = 1133,
	msg_bind_object = 1037,
	msg_change_head_type = 1069,
	msg_cortege_train_confirm = 1082,
	msg_search_player_request = 1091,
	msg_pickup_mail_attach = 1103,
	msg_report_player = 1096,
	msg_quit_game_ret = 1015,
	msg_spring_charge_prize = 1215,
	msg_cortege_consume = 1086,
	msg_new_role_guide = 1204,
	msg_role_property = 1307,
	msg_query_lineup_info = 1039,
	msg_upgrade_ext_star = 1340,
	msg_update_checkin_info = 1206,
	msg_stone_event = 1054,
	msg_attention_player = 1093,
	msg_update_top_list = 1022,
	msg_specter_event = 1329,
	msg_compose_equip = 1053,
	msg_change_cortege_order = 1024,
	msg_skip_rape_back = 1060,
	msg_force_quit = 1013,
	msg_cortege_ramdom_get = 1042,
	msg_use_item = 1051,
	msg_title_op = 1078,
	msg_keep_alive = 2999,
	msg_update_attention_list = 1095,
	msg_update_activity_info = 1221,
	msg_sky_pavilion = 1227,
	msg_query_achievements = 1067,
	msg_sweep_request = 1061,
	msg_query_single_win_prize = 1231,
	msg_query_match_info = 1232,
	msg_flush_challenge_enemy = 1234,
	msg_material_transform = 1074,
	msg_update_map_list = 1023,
	msg_change_rape_info = 1041,
	msg_enhance_skill = 1071,
	msg_buy_mystery_item = 1130,
	msg_query_single_toplist = 1236,
	msg_update_label_status = 1045,
	msg_reconnect = 1016,
	msg_single_toplist_response = 1237,
	msg_take_singlerank_prize = 1238,
	msg_update_lottery_list = 1047,
	msg_group_buy = 1239,
	msg_take_consume_gold_prize = 1218,
	msg_panic_buy = 1241,
	msg_cortege_orient_train = 1089,
	msg_query_panic_buy_info = 1242,
	msg_random_monday_prize = 1243,
	msg_union_event = 1301,
	msg_modify_title = 1077,
	msg_prey_event = 1302,
	msg_collector_cortege = 1305,
	msg_use_map_flush = 1129,
	msg_update_feed_info = 1040,
	msg_spirit_gossip = 1310,
	msg_pickup_mail_content = 1102,
	msg_roll_labourday_miles = 1224,
	msg_longevity_hill = 1323,
	msg_pile_snowman = 1324,
	msg_analysis_dream = 1325,
	msg_update_version = 1326,
	msg_fight_lineup = 1028,
	msg_reborn_event = 1328,
	msg_cheer_req = 1087,
	msg_equip_advance = 1073,
	msg_daily_active = 1347,
	msg_yuanshi_activity = 1334,
	msg_vip_shop = 1336,
	msg_update_cortege_list = 1034,
	msg_update_attach_order = 1036,
	msg_divination_event = 1337,
	msg_equip_ext_star = 1338,
	msg_train_boss = 1064,
	msg_unload_ext_star = 1339,
	msg_search_player_result = 1092,
	msg_rape_sweep_request = 1072,
	msg_enhance_equip = 1052,
	msg_animal_event = 1330,
	msg_remove_A_to_B = 1099,
	msg_update_sweep_req = 1062,
	msg_cross_fight = 1344,
	msg_hero_back = 1345,
	msg_query_top_list = 1021,
	msg_query_map_list = 1018,
	msg_inside_game = 1017,
	msg_autumn_activity = 1333,
	msg_update_tollgate_info = 1050,
	msg_hole_event = 1348,
	msg_save_monkey = 1346,
	msg_undergo_ordeal_event = 1349,
	msg_activate_cortege = 1306,
	msg_summer_activity = 1331,
	msg_reconnect_notify = 2996,
	msg_query_attention_list = 1094,
	msg_rulai_activity = 1351,
	msg_valentine_activity = 1132,
	msg_item_transform = 1225,
	msg_babel_tower = 1353,
	msg_newbie_scores_awards = 1354,
	msg_update_rape_info = 1029,
	msg_newbie_purchase = 1356,
	msg_fate_rebuilding_op = 1357,
	msg_newbie_create = 1358,
	msg_upgrade_buffer = 1076,
	msg_modify_player_name = 1031,
	msg_fate_star_switch = 1359,
	msg_send_tip_info = 2995,
	msg_modify_attr_double = 1360,
	msg_update_spirit_list = 1046,
	msg_free_fight_event = 1350,
	msg_nine_sky = 1309,
	msg_cortege_impart = 1025,
	msg_kick_player = 2997,
	msg_activate_account = 1012,
	msg_lock_item = 1343,
	msg_fight_request = 1026,
	msg_compress_data = 3000,
	msg_search_gold = 1208,
	msg_team_event = 1303,
	msg_update_tollgate_data = 1019,
	msg_order_prebuy = 1112,
	msg_buy_item_in_batch = 1057,
	msg_process_done = 1106,
	msg_compose_items = 1075,
	msg_query_lineup_data = 1233,
	msg_restore_awaken_skill = 1342,
	msg_sell_items = 1088,
	msg_query_consume_gold_prize = 1217,
	msg_update_caishen_prize = 1209,
	msg_compose_spirit = 1083,
	msg_register_real = 1304,
	msg_modify_achievements = 1066,
	msg_query_charge_prize = 1216,
	msg_special_fight_result = 1140,
	msg_monster_nian = 1327,
	msg_take_win_streak_prize = 1235,
	msg_sell_equip_in_batch = 1056,
	msg_query_cortege_list = 1033,
	msg_pickup_gift_attach = 1104,
	msg_common_query_request = 1049,
	msg_update_label_list = 1044,
	msg_chat_info_to_server = 1097,
	msg_visit_land_father = 1068,
	msg_exchange_tangwang_prize = 1213,
	msg_newbie_daily_act_awards = 1355,
	msg_awaken_skill = 1332,
	msg_query_event_status = 1205,
	msg_invite_request = 1101,
	msg_take_prize = 1201,
	msg_query_champion_list = 1128,
	msg_common_event = 2998,
	msg_exchange_tools = 1212,
	msg_buy_streangth_energy = 1058,
	msg_spirit_pray = 1085,
	msg_decompose_ext_star = 1341,
	msg_order_request = 1111,
	msg_week_activity = 1219,
	msg_query_fight_record = 1244,
	msg_quit_game = 1014,
	msg_fight_result = 1027,
	msg_change_password = 1010,
	msg_visit_caishen = 1210,
	msg_furnace = 1134,
	msg_lantern_activity = 1214,
	msg_query_activity_info = 1220,
	msg_update_visit_info = 1030,
	msg_update_attach_list = 1035,
	msg_retrans_req = 1105,
	msg_register_account = 1011,
	msg_cortege_evolve = 1084,
	msg_hunt_soul = 1226,
	msg_query_labourday_info = 1222,
	msg_query_last_pick = 1065,
	msg_exchange_labourday_prize = 1223,
	msg_exchange_top_score = 1203,
	msg_add_party_plus = 1202,
	msg_weekend_event = 1308,
	msg_change_genius = 1070,
	msg_consume_fairy_roll = 1059,
	msg_daily_pay = 1352,
	msg_query_compose_list = 1055,
	msg_baozongzi = 1126,
	msg_update_duty_info = 1043,
	msg_equip_ext_skill = 1311,
	msg_special_fight_lineup = 1141,
	msg_equip_rising_star = 1079,
	msg_world_imperial = 1335,
	msg_upgrade_ext_skill = 1322,
	msg_query_take_item = 1131,
	msg_chat_info_to_client = 1098,
	msg_remove_object = 1038,
	msg_friend_vip_upgrade = 1240,
	msg_query_label_list = 1048,
	msg_modify_attr = 1032,
	msg_login_req = msg_id_segment.clgs_msg_begin
}
lscl_msg_id = {
	msg_login_rsp = 3002,
	msg_common_event = msg_id_segment.lscl_msg_begin
}
gsls_msg_id = {
	msg_prelogin = 3103,
	msg_update_online_count = 3115,
	msg_update_status = 3114,
	msg_login_rsp = 3102,
	msg_client_logined = 3109,
	msg_client_logouted = 3110,
	msg_create_role_ok = 3105,
	msg_prelogin_ret = 3104,
	msg_client_released = 3111,
	msg_login_req = msg_id_segment.gsls_msg_begin
}
gsdba_msg_id = {
	msg_login_rsp = 3202,
	msg_login_req = msg_id_segment.gsdba_msg_begin
}
lsdba_msg_id = {
	msg_login_rsp = 3302,
	msg_login_req = msg_id_segment.lsdba_msg_begin
}
lsdti_msg_id = {
	msg_login_rsp = 3402,
	msg_login_req = msg_id_segment.lsdti_msg_begin
}
gsdti_msg_id = {
	msg_common_event = 3503,
	msg_login_rsp = 3502,
	msg_login_req = msg_id_segment.gsdti_msg_begin
}
wsdba_msg_id = {
	msg_login_rsp = 3602,
	msg_login_req = msg_id_segment.wsdba_msg_begin
}
csdba_msg_id = {
	msg_login_rsp = 3702,
	msg_login_req = msg_id_segment.csdba_msg_begin
}
gsbs_msg_id = {
	msg_disconnect_client = 4005,
	msg_client_disconnected = 4006,
	msg_login_rsp = 4002,
	msg_login_req = msg_id_segment.gsbs_msg_begin
}
type_def = {
	uint = "I",
	objguid = "d",
	word = "W",
	byte = "B",
	int = "i"
}
common_def = {
	{
		def = "id=I",
		id = common_id.type_area
	},
	{
		def = "type=W,size=I,connection_id=I",
		id = common_id.msg_base
	},
	{
		id = common_id.type_player_info,
		def = "id=" .. type_def.objguid .. ",name=S[" .. const.MAX_SEND_NAME_LEN .. "]"
	},
	{
		id = common_id.type_server_info,
		def = "area=I,status=i,area_name=S[" .. const.MAX_SEND_NAME_LEN .. "]"
	},
	{
		id = common_id.type_enum_role,
		def = "role_name=S[" .. const.MAX_SEND_NAME_LEN .. "],role_id=" .. type_def.objguid .. ",level=B,delete_time=I"
	},
	{
		def = "type_id=I,status=B",
		id = common_id.type_label_info
	},
	{
		id = common_id.type_fight_result,
		def = "self_use=l,skill_type=I,is_src=l,result=B,src_order=B,des_order=B,cur_round=B,damage_count=B,damage_list=" .. type_def.int .. "[" .. const.MAX_FIGHT_COUNT .. "]"
	},
	{
		id = common_id.type_special_fight_result,
		def = "self_use=l,skill_type=I,is_src=l,result=B,src_order=B,des_order=I,cur_round=B,damage_count=B,damage_list=" .. type_def.int .. "[" .. const.SPECIAL_FIGHT_COUNT .. "]"
	},
	{
		def = "src_type=I,src_evolve=I,src_hp=I,src_max_hp=I,src_magic=I,src_reborn=B,des_type=I,des_evolve=I,des_max_hp=I,des_hp=I,des_magic=I,des_level=I,des_reborn=B",
		id = common_id.type_fight_lineup
	},
	{
		id = common_id.type_search_player,
		def = "id=" .. type_def.objguid .. ",level=B,name=S[" .. const.MAX_SEND_NAME_LEN .. "]"
	},
	{
		def = "type=W,value=i",
		id = common_id.type_attr
	},
	{
		def = "type=W,value=d",
		id = common_id.type_attr_double
	},
	{
		def = "tollgate_type=B,map_id=B,tollgate_id=I,day_count=W,flush_count=W,pass_star=B",
		id = common_id.type_tollgate_data
	},
	{
		id = common_id.type_top_data,
		def = "order=W,type=B,id=" .. type_def.objguid .. ",level=W,name=S[" .. const.MAX_SEND_NAME_LEN .. "],win_me=l,top_relation=b,cortege=I,cortege_layer=B"
	},
	{
		def = "tollgate_type=B,map_id=B,pass_map=I",
		id = common_id.type_map_data
	},
	{
		id = common_id.type_change_info,
		def = "id=" .. type_def.objguid .. ",new_order=B"
	},
	{
		id = common_id.type_cortege_data,
		def = "id=" .. type_def.objguid .. ",order=B,cheer_order=B,type=I,level=W,cur_exp=d,next_exp=d,hp=I,magic=I,gongji=I,fangyu=I,combat_power=I" .. ",culture_point=W,hp_plus=I,magic_plus=I,gongji_plus=I,fangyu_plus=I,train_increase_field=I,train_decrease_field=I,train_change_value=I,evolve_level=W" .. ",equiped_ext_skill_limit=B,equiped_ext_star_limit=B,next_ext_skill_luck_point=W,reborn_layer=B,reborn_vein_level=B,reborn_plus_type=B"
	},
	{
		id = common_id.type_skill_data,
		def = "id=" .. type_def.objguid .. ",order=B,equip_pos=B,skill_type=I,level=B,effect_value=I"
	},
	{
		id = common_id.type_attach_pos,
		def = "id=" .. type_def.objguid .. ",order=I,equip_pos=I"
	},
	{
		id = common_id.type_attach_data,
		def = "id=" .. type_def.objguid .. ",attach_type=B,type_id=I,count=I,level=I,equip_order=B,equip_pos=B,protogenic=B,effect_value=I,drill_count=B,stone1_level=B,stone1_level=B," .. "stone2_level=B,stone3_level=B,stone4_level=B,prob_compen=I,advance_level=B,star_count=B,cur_spirit_count=I,ext_skill_pos=B,ext_awaken_pos=B,upgrade_level=B,reborn_bit=B,cast_level=I,awaken=b,is_lock=B,absorb_rate=I,shield_rate=I,owner_id=" .. type_def.objguid .. ",star_level=B"
	},
	{
		id = common_id.type_object_data,
		def = "id=" .. type_def.objguid
	},
	{
		def = "equip_type=I,need_money=I,need_count=B,quality=B",
		id = common_id.type_compose_data
	},
	{
		def = "type_id=I,count=I",
		id = common_id.type_spirit_data
	},
	{
		id = common_id.type_cortege_spirit,
		def = "object_type=B,object_id=" .. type_def.objguid .. ",count=I"
	},
	{
		id = common_id.type_lottery_data,
		def = "type_id=I,time=I,name=S[" .. const.MAX_SEND_NAME_LEN .. "]"
	},
	{
		def = "id=W,times=W,progress=W",
		id = common_id.achievements_list
	},
	{
		def = "id=W,begintime=I,endtime=I",
		id = common_id.type_title_list
	},
	{
		def = "prize_id=I,qianbi_count=W,object_type=W,attach_type=I,attach_count=W,attach_level=W",
		id = common_id.type_prize_data
	},
	{
		def = "object_type=W,attach_type=I,attach_count=W,attach_level=W",
		id = common_id.type_got_prize_data
	},
	{
		id = common_id.type_single_top_data,
		def = "player_id=" .. type_def.objguid .. ",score=I,rank=W,player_name=S[" .. const.MAX_SEND_NAME_LEN .. "],area=S[" .. const.MAX_SEND_NAME_LEN .. "]"
	},
	{
		id = common_id.type_compose_material_data,
		def = "id=" .. type_def.objguid
	},
	{
		id = common_id.type_pp_http_request,
		base = common_id.msg_base,
		def = "len=I,command=I,token_key=N[" .. const.SHORT_TOKEN_LEN .. "]"
	},
	{
		id = common_id.type_pp_http_response,
		base = common_id.msg_base,
		def = "len=I,command=I,status=I,user_name=S[" .. const.MAX_SEND_NAME_LEN .. ",uid=" .. type_def.objguid
	},
	{
		def = "thread_id=I,request_id=d,event_id=I,ex_eventid=I,data=s",
		id = common_id.msg_db_request,
		base = common_id.msg_base
	},
	{
		def = "request_id=d,event_id=I,err_code=I,data=s",
		id = common_id.msg_db_response,
		base = common_id.msg_base
	},
	{
		def = "source_code=s",
		id = common_id.msg_dynamic_update,
		base = common_id.msg_base
	},
	{
		def = "ret=B,err_msg=s",
		id = common_id.msg_dynamic_update_ret,
		base = common_id.msg_base
	},
	{
		id = common_id.msg_query_config,
		base = common_id.msg_base,
		def = "process_name=S[" .. const.MAX_SEND_NAME_LEN .. "]"
	},
	{
		id = common_id.msg_update_config,
		base = common_id.msg_base,
		def = "common_config=S[" .. const.COMMON_CONFIG_BUFFER_SIZE .. "],world_config=S[" .. const.WORLD_CONFIG_BUFFER_SIZE .. "],arena_config=S[" .. const.ARENA_CONFIG_BUFFER_SIZE .. "],fixed_config=S[" .. const.BASE_CONFIG_BUFFER_SIZE .. "]"
	},
	{
		def = "id=B,data=s",
		id = common_id.msg_gm_common_event,
		base = common_id.msg_base
	},
	{
		def = "type=B",
		id = common_id.msg_heartbeat,
		base = common_id.msg_base
	},
	{
		id = common_id.event_client_info,
		base = common_id.msg_base,
		def = "type=i,size=i,totalSize=" .. type_def.objguid .. ",status=i,filename=S[" .. const.LONG_IP_LEN .. "]"
	},
	{
		id = common_id.event_client_update_info,
		base = common_id.msg_base,
		def = "type=i,size=i,totalSize=" .. type_def.objguid .. ",status=i,filename=S[" .. const.LONG_IP_LEN .. "]"
	},
	{
		def = "eventID=i,status=i",
		id = common_id.event_third_party_platform,
		base = common_id.msg_base
	}
}
gscl_msg = {
	{
		id = gscl_msg_id.msg_login_req,
		base = common_id.msg_base,
		def = "hash_account=I,auth_key=I,seed=I,client_ip=S[" .. const.SHORT_IP_LEN .. "],account=S[" .. const.MAX_SEND_ACCOUNT_LEN .. "]"
	},
	{
		def = "result=B",
		id = gscl_msg_id.msg_login_rsp,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_change_password,
		base = common_id.msg_base,
		def = "serial_num=I,old_password=N[" .. const.MD5_STRING_LEN .. "],new_password=N[" .. const.MD5_STRING_LEN .. "]"
	},
	{
		id = gscl_msg_id.msg_register_account,
		base = common_id.msg_base,
		def = "serial_num=I,account=S[" .. const.MAX_SEND_ACCOUNT_LEN .. "],password=N[" .. const.MD5_STRING_LEN .. "]"
	},
	{
		id = gscl_msg_id.msg_register_real,
		base = common_id.msg_base,
		def = "serial_num=I,name=S[" .. const.MAX_SEND_ACCOUNT_LEN .. "],identity_card=s"
	},
	{
		def = "serial_num=I",
		id = gscl_msg_id.msg_collector_cortege,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,index=I,value=I",
		id = gscl_msg_id.msg_activate_cortege,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,flag=B",
		id = gscl_msg_id.msg_role_property,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_activate_account,
		base = common_id.msg_base,
		def = "serial_num=I,account=S[" .. const.MAX_SEND_ACCOUNT_LEN .. "],password=N[" .. const.MD5_STRING_LEN .. "]"
	},
	{
		id = gscl_msg_id.msg_force_quit,
		base = common_id.msg_base,
		def = "quit_reason=I,client_ip=S[" .. const.LONG_IP_LEN .. "]"
	},
	{
		def = "flag=B",
		id = gscl_msg_id.msg_quit_game,
		base = common_id.msg_base
	},
	{
		def = "flag=B",
		id = gscl_msg_id.msg_quit_game_ret,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_reconnect,
		base = common_id.msg_base,
		def = "hash_account=I,random_key=I,account=S[" .. const.MAX_SEND_ACCOUNT_LEN .. "]"
	},
	{
		id = gscl_msg_id.msg_inside_game,
		base = common_id.msg_base,
		def = "area_id=I,cross_area_id=I,role_id=" .. type_def.objguid .. ",role_name=S[" .. const.MAX_SEND_NAME_LEN .. "],gm_level=W,vip_level=W,level=W,rule_index=W,new_role_gift=I" .. ",register_account=S[" .. const.MAX_MOBILE_ACCOUNT_LEN .. "],mobile_account=S[" .. const.MAX_MOBILE_ACCOUNT_LEN .. "],pf_account=S[" .. const.MAX_MOBILE_ACCOUNT_LEN .. "]" .. ",cur_exp=I,next_exp=I,cortege_count=B,silver_coin=I,gold_coin=I,strength=I,energy=I,random_key=I,reconnect=l,max_hp_plus=I,max_magic_plus=I" .. ",gongji_plus=I,fangyu_plus=I,renew_time1=B,renew_time2=B,server_time=I,normal_time=I,advanced_time=I,super_time=I,advanced_first_pick_time=I,super_first_pick_time=I,normal_count=B,first_charge=B,vip_gift=I" .. ",party_order=I,party_take_prize=B,party_fight_count=I,party_fight_count_plus=I,guide_progress=I,top_order=I,top_day_prize_time=I,top_first_promote_time=I,top_first_promote_prize=I" .. ",strength_item_count=B,energy_item_count=B,strength_item_time=I,energy_item_time=I,strength_item_limit=B,energy_item_limit=B,top_fight_limit=B,rape_flush_limit=B" .. ",day_take_gold_limit=I,spirit_retain=I,fight_lose_count=I,feed_time1=I,feed_time2=I,can_visit=l,checkin_time=I,tollgate_flush_limit=I,tollgate_flush_count=I,tollgate_flush_time=I" .. ",sweep_flush_limit=I,sweep_flush_count=I,last_sweep_time=I,month_card_time=I,month_card_record=I,first_charge_gift=I" .. ",task_progress=I,task_prize=I,take_vip_gold_time=I,take_charge_gift_time=I,vip_buy_cheap_item=I,vip_buy_cheap_item_time=I,enhance_inbatch_limit=I,next_charge_gold=I,pray_spirit_times=I" .. ",convert_fight_limit=I,convert_fight_count=I,convert_fight_time=I,online_prize_index=B,tao_point=I,last_report_time=I,last_report_count=B,union_id=d,union_rank=I,union_contrib=I,union_store_flush_time=I,cur_union_contrib=I" .. ",last_feast_grab_time=I,last_feast_grab_count=I,last_rece_award_time=I,cheer_count=B,cheer_heaven_level=B,cheer_earth_level=B,cheer_heaven_effect=B,cheer_earth_effect=B,cheer_sunda_level=B,cheer_sunda_effect=B,cheer_water_level=B,cheer_water_effect=B" .. ",cheer_fire_level=B,cheer_fire_effect=B,heaven_hp=I,heaven_fangyu=I,heaven_gongji=I,heaven_magic=I,heaven_hp_plus=I,heaven_magic_plus=I,heaven_fangyu_plus=I,heaven_gongji_plus=I,earth_hp=I,earth_magic=I,earth_fangyu=I,earth_gongji=I,cheer_pool_level=B,cheer_pool_effect=B" .. ",earth_hp_plus=I,earth_magic_plus=I,earth_fangyu_plus=I,earth_gongji_plus=I,win_streak_count=I,single_score=I,single_free_challenge=I,single_charge_challenge=I,single_next_flush_time=I" .. ",single_charge_flush_time=I,single_charge_flush_count=I,single_rank=I,max_win_streak_count=I,last_chat_time=I,last_chat_count=I,last_west_book_time=I,west_book_count=B" .. ",last_stop_book_time=I,stop_book_count=B,head_type=B,cur_genius_type=I,role_combat_power=I,reg_card_finish=I,monthcard_act_time=I,monthcard_unact_count=B" .. ",cheer_shake_level=B,cheer_shake_effect=B,shake_hp=I,shake_fangyu=I,shake_gongji=I,shake_magic=I,shake_hp_plus=I,shake_magic_plus=I,shake_fangyu_plus=I,shake_gongji_plus=I" .. ",elite_tollgate_flush_count=I,elite_tollgate_flush_time=I,elite_fight_count=I,elite_fight_time=I,buy_growup=B,single_free_flush_count=B" .. ",sunda_hp=I,sunda_magic=I,sunda_fangyu=I,sunda_gongji=I,sunda_hp_plus=I,sunda_magic_plus=I,sunda_fangyu_plus=I,sunda_gongji_plus=I" .. ",water_hp=I,water_magic=I,water_fangyu=I,water_gongji=I,water_hp_plus=I,water_magic_plus=I,water_fangyu_plus=I,water_gongji_plus=I" .. ",fire_hp=I,fire_magic=I,fire_fangyu=I,fire_gongji=I,fire_hp_plus=I,fire_magic_plus=I,fire_fangyu_plus=I,fire_gongji_plus=I" .. ",hill_hp=I,hill_magic=I,hill_fangyu=I,hill_gongji=I,hill_hp_plus=I,hill_magic_plus=I,hill_fangyu_plus=I,hill_gongji_plus=I,cheer_hill_level=B,cheer_hill_effect=B" .. ",pool_hp=I,pool_magic=I,pool_fangyu=I,pool_gongji=I,pool_hp_plus=I,pool_magic_plus=I,pool_fangyu_plus=I,pool_gongji_plus=I" .. ",relation_player=" .. type_def.objguid .. ",union_name=S[" .. const.MAX_SEND_NAME_LEN .. "]" .. ",reborn_layer=B" .. ",maxlayer_reborn_count=B,drug_level=B,drug_exp=I,drug_study_flag=I,drug_study_flag2=I" .. ",heaven_skill_level=I,earth_skill_level=I,shake_skill_level=I,sunda_skill_level=I,water_skill_level=I,fire_skill_level=I,hill_skill_level=I,pool_skill_level=I,cheer_skill_open=I" .. ",cheer_skill_ni_open=I,unheaven_skill_level=B,unearth_skill_level=B,unshake_skill_level=B,unsunda_skill_level=B,unwater_skill_level=B,unfire_skill_level=B,unhill_skill_level=B,unpool_skill_level=B" .. ",cheer_unheaven_level=B,cheer_unearth_level=B,cheer_unshake_level=B,cheer_unsunda_level=B,cheer_unwater_level=B,cheer_unfire_level=B,cheer_unhill_level=B,cheer_unpool_level=B" .. ",cheer_unheaven_effect=B,cheer_unearth_effect=B,cheer_unshake_effect=B,cheer_unsunda_effect=B,cheer_unwater_effect=B,cheer_unfire_effect=B,cheer_unhill_effect=B,cheer_unpool_effect=B" .. ",unheaven_hp=I,unheaven_magic=I,unheaven_fangyu=I,unheaven_gongji=I,unheaven_hp_plus=I,unheaven_magic_plus=I,unheaven_fangyu_plus=I,unheaven_gongji_plus=I" .. ",unearth_hp=I,unearth_magic=I,unearth_fangyu=I,unearth_gongji=I,unearth_hp_plus=I,unearth_magic_plus=I,unearth_fangyu_plus=I,unearth_gongji_plus=I" .. ",unshake_hp=I,unshake_magic=I,unshake_fangyu=I,unshake_gongji=I,unshake_hp_plus=I,unshake_magic_plus=I,unshake_fangyu_plus=I,unshake_gongji_plus=I" .. ",unsunda_hp=I,unsunda_magic=I,unsunda_fangyu=I,unsunda_gongji=I,unsunda_hp_plus=I,unsunda_magic_plus=I,unsunda_fangyu_plus=I,unsunda_gongji_plus=I" .. ",unwater_hp=I,unwater_magic=I,unwater_fangyu=I,unwater_gongji=I,unwater_hp_plus=I,unwater_magic_plus=I,unwater_fangyu_plus=I,unwater_gongji_plus=I" .. ",unfire_hp=I,unfire_magic=I,unfire_fangyu=I,unfire_gongji=I,unfire_hp_plus=I,unfire_magic_plus=I,unfire_fangyu_plus=I,unfire_gongji_plus=I" .. ",unhill_hp=I,unhill_magic=I,unhill_fangyu=I,unhill_gongji=I,unhill_hp_plus=I,unhill_magic_plus=I,unhill_fangyu_plus=I,unhill_gongji_plus=I" .. ",unpool_hp=I,unpool_magic=I,unpool_fangyu=I,unpool_gongji=I,unpool_hp_plus=I,unpool_magic_plus=I,unpool_fangyu_plus=I,unpool_gongji_plus=I"
	},
	{
		def = "serial_num=I,flag=B",
		id = gscl_msg_id.msg_query_map_list,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,map_id=B,pass_map=I,tollgate_id=I,day_count=W,flush_count=W,pass_star=B,tollgate_type=B",
		id = gscl_msg_id.msg_update_tollgate_data,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_update_tollgate_list,
		base = common_id.msg_base,
		def = "serial_num=I,first_send=l,tollgate_count=B,tollgate_list=$" .. common_id.type_tollgate_data .. "{" .. const.MAX_SEND_COUNT .. "}"
	},
	{
		def = "serial_num=I,flag=B",
		id = gscl_msg_id.msg_query_top_list,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_update_top_list,
		base = common_id.msg_base,
		def = "serial_num=I,need_update=l,self_order=W,self_score=I,promote_time=I,promote_prize=I,fight_count=W,show_count=B,show_list=$" .. common_id.type_top_data .. "{" .. const.MAX_SEND_COUNT .. "}"
	},
	{
		id = gscl_msg_id.msg_update_map_list,
		base = common_id.msg_base,
		def = "serial_num=I,map_count=B,map_list=$" .. common_id.type_map_data .. "{" .. const.MAX_SEND_COUNT .. "}"
	},
	{
		id = gscl_msg_id.msg_change_cortege_order,
		base = common_id.msg_base,
		def = "serial_num=I,flag=B,count=B,change_info=$" .. common_id.type_change_info .. "{" .. const.MAX_FIGHT_COUNT .. "}"
	},
	{
		id = gscl_msg_id.msg_cortege_impart,
		base = common_id.msg_base,
		def = "serial_num=I,src_id=" .. type_def.objguid .. ",des_id=" .. type_def.objguid
	},
	{
		id = gscl_msg_id.msg_fight_request,
		base = common_id.msg_base,
		def = "serial_num=I,fight_type=B,des_value=I,des_type=B,des_id=" .. type_def.objguid
	},
	{
		id = gscl_msg_id.msg_fight_result,
		base = common_id.msg_base,
		def = "serial_num=I,fight_id=I,fight_type=B,guide_stage=B,final_result=B,fight_round=B,fight_result=$" .. common_id.type_fight_result .. "{" .. const.MAX_SEND_COUNT .. "}"
	},
	{
		id = gscl_msg_id.msg_fight_lineup,
		base = common_id.msg_base,
		def = "serial_num=I,fight_id=I,first_hand=B,des_name=S[" .. const.MAX_SEND_NAME_LEN .. "],lineup_count=B,lineup=$" .. common_id.type_fight_lineup .. "{" .. const.MAX_FIGHT_COUNT .. "}"
	},
	{
		id = gscl_msg_id.msg_special_fight_result,
		base = common_id.msg_base,
		def = "serial_num=I,fight_id=I,fight_type=B,guide_stage=B,final_result=B,fight_round=B,fight_result=$" .. common_id.type_special_fight_result .. "{" .. const.MAX_SEND_COUNT .. "}"
	},
	{
		id = gscl_msg_id.msg_special_fight_lineup,
		base = common_id.msg_base,
		def = "serial_num=I,fight_id=I,first_hand=B,des_name=S[" .. const.MAX_SEND_NAME_LEN .. "],lineup_count=B,lineup=$" .. common_id.type_fight_lineup .. "{" .. const.SPECIAL_FIGHT_COUNT .. "}"
	},
	{
		def = "serial_num=I,flag=B",
		id = gscl_msg_id.msg_update_rape_info,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,visit_index=B,op_type=B",
		id = gscl_msg_id.msg_update_visit_info,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_modify_player_name,
		base = common_id.msg_base,
		def = "serial_num=I,new_name=S[" .. const.MAX_SEND_NAME_LEN .. "]"
	},
	{
		id = gscl_msg_id.msg_modify_attr,
		base = common_id.msg_base,
		def = "serial_num=I,id=" .. type_def.objguid .. ",unit_type=B,attr_count=B,attr_list=$" .. common_id.type_attr .. "{" .. const.MAX_SEND_COUNT .. "}"
	},
	{
		id = gscl_msg_id.msg_modify_attr_double,
		base = common_id.msg_base,
		def = "serial_num=I,id=" .. type_def.objguid .. ",unit_type=B,attr_count=B,attr_list=$" .. common_id.type_attr_double .. "{" .. const.MAX_SEND_COUNT .. "}"
	},
	{
		def = "serial_num=I,flag=I",
		id = gscl_msg_id.msg_query_cortege_list,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_update_cortege_list,
		base = common_id.msg_base,
		def = "serial_num=I,first_send=l,cortege_count=B,cortege_list=$" .. common_id.type_cortege_data .. "{" .. const.MAX_SEND_COUNT .. "}"
	},
	{
		id = gscl_msg_id.msg_update_attach_list,
		base = common_id.msg_base,
		def = "serial_num=I,first_send=l,attach_count=b,attach_list=$" .. common_id.type_attach_data .. "{" .. const.MAX_SEND_COUNT .. "}"
	},
	{
		id = gscl_msg_id.msg_update_attach_order,
		base = common_id.msg_base,
		def = "serial_num=I,attach_type=B,attach_count=B,attach_list=$" .. common_id.type_attach_pos .. "{" .. const.MAX_SEND_COUNT .. "}"
	},
	{
		id = gscl_msg_id.msg_bind_object,
		base = common_id.msg_base,
		def = "serial_num=I,flag=B,obj_type=B,src_id=" .. type_def.objguid .. ",src_order=B,des_order=B,des_equip_pos=B"
	},
	{
		def = "serial_num=I,data=s",
		id = gscl_msg_id.msg_remove_object,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_query_lineup_info,
		base = common_id.msg_base,
		def = "serial_num=I,fight_id=I,des_type=B,des_id=" .. type_def.objguid .. ",flag=B"
	},
	{
		def = "serial_num=I,feed_count=I",
		id = gscl_msg_id.msg_update_feed_info,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_change_rape_info,
		base = common_id.msg_base,
		def = "serial_num=I,form_index=B,object_type=B,object_id=" .. type_def.objguid
	},
	{
		def = "serial_num=I,pick_grade=B,pick_type=B,ten_pick=B",
		id = gscl_msg_id.msg_cortege_ramdom_get,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,plus_type=B,plus_index=B,flag=B",
		id = gscl_msg_id.msg_update_duty_info,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_update_label_list,
		base = common_id.msg_base,
		def = "serial_num=I,first_send=l,object_type=B,label_count=B,label_list=$" .. common_id.type_label_info .. "{" .. const.MAX_SEND_COUNT .. "}"
	},
	{
		def = "serial_num=I,object_type=B,type_id=I,status=B",
		id = gscl_msg_id.msg_update_label_status,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_update_spirit_list,
		base = common_id.msg_base,
		def = "serial_num=I,first_send=l,spirit_count=B,spirit_list=$" .. common_id.type_spirit_data .. "{" .. const.MAX_SEND_COUNT .. "}"
	},
	{
		id = gscl_msg_id.msg_update_lottery_list,
		base = common_id.msg_base,
		def = "serial_num=I,first_send=l,lottery_count=B,lottery_list=$" .. common_id.type_lottery_data .. "{" .. const.MAX_SEND_COUNT .. "}"
	},
	{
		def = "serial_num=I,flag=B",
		id = gscl_msg_id.msg_query_label_list,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,query_type=B,flag=B",
		id = gscl_msg_id.msg_common_query_request,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,tollgate_type=B,tollgate_id=I",
		id = gscl_msg_id.msg_update_tollgate_info,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_use_item,
		base = common_id.msg_base,
		def = "serial_num=I,item_type=I,item_id=" .. type_def.objguid .. ",item_count=I,des_type=B,des_id=" .. type_def.objguid
	},
	{
		id = gscl_msg_id.msg_enhance_equip,
		base = common_id.msg_base,
		def = "serial_num=I,equip_order=B,inbatch=l,equip_id=" .. type_def.objguid
	},
	{
		id = gscl_msg_id.msg_compose_equip,
		base = common_id.msg_base,
		def = "serial_num=I,compose_type=B,equip_type=I,equip_quality=I,material_quality=B,material_count=B,material_list=$" .. common_id.type_object_data .. "{" .. const.MAX_CONSUME_EQUIP_COUNT .. "}"
	},
	{
		id = gscl_msg_id.msg_compose_items,
		base = common_id.msg_base,
		def = "serial_num=I,compose_type=B,material_count=B,material_list=$" .. common_id.type_compose_material_data .. "{" .. const.MAX_METERIAL_COUNT .. "}"
	},
	{
		id = gscl_msg_id.msg_stone_event,
		base = common_id.msg_base,
		def = "serial_num=I,flag=B,des_id=" .. type_def.objguid .. ",equip_order=B,stone_pos=B,src_count=B,src_list=$" .. common_id.type_object_data .. "{" .. const.MAX_SEND_COUNT .. "}"
	},
	{
		def = "serial_num=I,flag=B",
		id = gscl_msg_id.msg_query_compose_list,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,data=s",
		id = gscl_msg_id.msg_sell_equip_in_batch,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,index=B,type_id=I,count=I,first_send=B,page_id=B",
		id = gscl_msg_id.msg_buy_item_in_batch,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,type_id=I",
		id = gscl_msg_id.msg_buy_streangth_energy,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_consume_fairy_roll,
		base = common_id.msg_base,
		def = "serial_num=I,first_send=l,flag=B,cortege_id=" .. type_def.objguid .. ",roll_count=B,roll_list=$" .. common_id.type_spirit_data .. "{" .. const.MAX_SEND_COUNT .. "}"
	},
	{
		def = "serial_num=I,request_id=d",
		id = gscl_msg_id.msg_skip_rape_back,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_sweep_request,
		base = common_id.msg_base,
		def = "serial_num=I,tollgate_type=B,sweep_count=B,tollgate_id=" .. type_def.objguid
	},
	{
		def = "serial_num=I",
		id = gscl_msg_id.msg_rape_sweep_request,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,cost_gold=I",
		id = gscl_msg_id.msg_update_sweep_req,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,error_code=I,sweep_flush_limit=I,sweep_flush_count=I,last_sweep_time=I",
		id = gscl_msg_id.msg_update_sweep_rsp,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_train_boss,
		base = common_id.msg_base,
		def = "serial_num=I,flag=B,id=" .. type_def.objguid
	},
	{
		def = "serial_num=I,flag=B",
		id = gscl_msg_id.msg_query_last_pick,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_modify_achievements,
		base = common_id.msg_base,
		def = "serial_num=I,new=B,role_id=" .. type_def.objguid .. ",tao_point=I,achievement_count=B,achievements=$" .. common_id.achievements_list .. "{" .. const.MAX_SEND_COUNT .. "}"
	},
	{
		id = gscl_msg_id.msg_query_achievements,
		base = common_id.msg_base,
		def = "serial_num=I,des_role_id=" .. type_def.objguid .. ",flag=B"
	},
	{
		def = "serial_num=I,index=B,count=B",
		id = gscl_msg_id.msg_visit_land_father,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,head_type=I,flag=B",
		id = gscl_msg_id.msg_change_head_type,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,type_id=I",
		id = gscl_msg_id.msg_change_genius,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,data=s",
		id = gscl_msg_id.msg_enhance_skill,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_upgrade_buffer,
		base = common_id.msg_base,
		def = "serial_num=I,upgrade_type=B,des_id=" .. type_def.objguid .. ",material_count=B,material_list=$" .. common_id.type_object_data .. "{" .. const.MAX_SEND_COUNT .. "}"
	},
	{
		id = gscl_msg_id.msg_awaken_skill,
		base = common_id.msg_base,
		def = "serial_num=I,awaken_type=B,des_id=" .. type_def.objguid .. ",material_count=B,material_list=$" .. common_id.type_object_data .. "{" .. const.MAX_SEND_COUNT .. "}"
	},
	{
		id = gscl_msg_id.msg_restore_awaken_skill,
		base = common_id.msg_base,
		def = "serial_num=I,des_id=" .. type_def.objguid .. ""
	},
	{
		id = gscl_msg_id.msg_lock_item,
		base = common_id.msg_base,
		def = "serial_num=I,des_id=" .. type_def.objguid .. ",flag=B"
	},
	{
		def = "serial_num=I,id=B,data=s",
		id = gscl_msg_id.msg_cross_fight,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,id=B,data=s",
		id = gscl_msg_id.msg_hero_back,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,id=B,data=s",
		id = gscl_msg_id.msg_daily_active,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_modify_title,
		base = common_id.msg_base,
		def = "serial_num=I,new=B,wear_id=W,role_id=" .. type_def.objguid .. ",title_count=B,titles=$" .. common_id.type_title_list .. "{" .. const.MAX_SEND_COUNT .. "}"
	},
	{
		id = gscl_msg_id.msg_title_op,
		base = common_id.msg_base,
		def = "serial_num=I,des_id=" .. type_def.objguid .. ",flag=B"
	},
	{
		id = gscl_msg_id.msg_equip_advance,
		base = common_id.msg_base,
		def = "serial_num=I,flag=B,equip_order=B,is_one_key=l,equip_id=" .. type_def.objguid
	},
	{
		id = gscl_msg_id.msg_equip_rising_star,
		base = common_id.msg_base,
		def = "serial_num=I,equipid=" .. type_def.objguid .. ",equip_order=B,material_equipid=" .. type_def.objguid
	},
	{
		id = gscl_msg_id.msg_material_transform,
		base = common_id.msg_base,
		def = "serial_num=I,flag=B,num=B,des_type=I,count=B,id_list=$" .. common_id.type_object_data .. "{" .. const.MAX_SEND_COUNT .. "}"
	},
	{
		id = gscl_msg_id.msg_cortege_train_request,
		base = common_id.msg_base,
		def = "serial_num=I,cortege_id=" .. type_def.objguid .. ",train_type=B,intensive=l"
	},
	{
		id = gscl_msg_id.msg_cortege_train_confirm,
		base = common_id.msg_base,
		def = "serial_num=I,cortege_id=" .. type_def.objguid .. ",confirm=l"
	},
	{
		id = gscl_msg_id.msg_cortege_orient_train,
		base = common_id.msg_base,
		def = "serial_num=I,cortege_id=" .. type_def.objguid .. ",train_field=I,train_point=I"
	},
	{
		def = "serial_num=I,type_id=I",
		id = gscl_msg_id.msg_compose_spirit,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_cortege_evolve,
		base = common_id.msg_base,
		def = "serial_num=I,flag=B,cortege_id=" .. type_def.objguid
	},
	{
		id = gscl_msg_id.msg_spirit_pray,
		base = common_id.msg_base,
		def = "serial_num=I,object_count=B,object_list=$" .. common_id.type_cortege_spirit .. "{" .. const.MAX_SEND_COUNT .. "}"
	},
	{
		id = gscl_msg_id.msg_cortege_consume,
		base = common_id.msg_base,
		def = "serial_num=I,flag=B,c1=" .. type_def.objguid .. ",c2=" .. type_def.objguid .. ",c3=" .. type_def.objguid .. ",c4=" .. type_def.objguid .. ",c5=" .. type_def.objguid
	},
	{
		id = gscl_msg_id.msg_cheer_req,
		base = common_id.msg_base,
		def = "serial_num=I,flag=B,id=" .. type_def.objguid .. ",order=B,client_flag=B"
	},
	{
		def = "serial_num=I,data=s",
		id = gscl_msg_id.msg_sell_items,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_search_player_request,
		base = common_id.msg_base,
		def = "serial_num=I,search_type=B,search_index=W,search_string=S[" .. const.MAX_SEND_NAME_LEN .. "]"
	},
	{
		id = gscl_msg_id.msg_search_player_result,
		base = common_id.msg_base,
		def = "serial_num=I,result=B,search_index=W,player_count=B,player_list=$" .. common_id.type_search_player .. "{" .. const.MAX_SEND_COUNT .. "}"
	},
	{
		id = gscl_msg_id.msg_attention_player,
		base = common_id.msg_base,
		def = "serial_num=I,des_id=" .. type_def.objguid .. ",des_name=S[" .. const.MAX_SEND_NAME_LEN .. "],des_level=B,op_type=B"
	},
	{
		def = "serial_num=I,flag=B",
		id = gscl_msg_id.msg_query_attention_list,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_update_attention_list,
		base = common_id.msg_base,
		def = "serial_num=I,first_send=l,op_type=B,attention_count=B,attention_list=$" .. common_id.type_search_player .. "{" .. const.MAX_SEND_COUNT .. "}"
	},
	{
		id = gscl_msg_id.msg_report_player,
		base = common_id.msg_base,
		def = "serial_num=I,id=" .. type_def.objguid .. ",name=S[" .. const.MAX_SEND_NAME_LEN .. "],chat_time=I,chat_msg=s"
	},
	{
		id = gscl_msg_id.msg_chat_info_to_server,
		base = common_id.msg_base,
		def = "serial_num=I,channel=B,id=" .. type_def.objguid .. ",name=S[" .. const.MAX_SEND_NAME_LEN .. "],chat_msg=s"
	},
	{
		id = gscl_msg_id.msg_chat_info_to_client,
		base = common_id.msg_base,
		def = "serial_num=I,channel=B,sub_channel=B,is_friend=l,is_friend_serial=l,head_type=B,vip_level=B,single_score=I,level=B,time=I,id=" .. type_def.objguid .. ",union_name=S[" .. const.MAX_SEND_NAME_LEN .. "],name=S[" .. const.MAX_SEND_NAME_LEN .. "],chat_msg=s"
	},
	{
		def = "serial_num=I",
		id = gscl_msg_id.msg_remove_A_to_B,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_invite_request,
		base = common_id.msg_base,
		def = "serial_num=I,request_type=B,invite_code=S[" .. const.MAX_COUPON_LEN .. "]"
	},
	{
		id = gscl_msg_id.msg_pickup_mail_content,
		base = common_id.msg_base,
		def = "serial_num=I,mail_id=" .. type_def.objguid .. ",flag=B"
	},
	{
		id = gscl_msg_id.msg_pickup_mail_attach,
		base = common_id.msg_base,
		def = "serial_num=I,mail_id=" .. type_def.objguid .. ",flag=B"
	},
	{
		id = gscl_msg_id.msg_pickup_gift_attach,
		base = common_id.msg_base,
		def = "serial_num=I,sn=S[" .. const.MAX_SEND_NAME_LEN .. "],flag=B"
	},
	{
		def = "req_serial_num=I",
		id = gscl_msg_id.msg_retrans_req,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,req_serial_num=I",
		id = gscl_msg_id.msg_process_done,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,event_id=B,data=s",
		id = gscl_msg_id.msg_order_request,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,event_id=B,data=s",
		id = gscl_msg_id.msg_order_prebuy,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,flag=B,id=I",
		id = gscl_msg_id.msg_take_prize,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,flag=B",
		id = gscl_msg_id.msg_add_party_plus,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,exchange_type=B",
		id = gscl_msg_id.msg_exchange_top_score,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,stage=B,head_type=I,name=s",
		id = gscl_msg_id.msg_new_role_guide,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,flag=B",
		id = gscl_msg_id.msg_query_event_status,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,checkin_type=B,day_index=I",
		id = gscl_msg_id.msg_update_checkin_info,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,state=B",
		id = gscl_msg_id.msg_client_gold_rush,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,count=I,type_id=I",
		id = gscl_msg_id.msg_search_gold,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_update_caishen_prize,
		base = common_id.msg_base,
		def = "serial_num=I,last_visit_time=I,prize_list=$" .. common_id.type_got_prize_data .. "{" .. const.MAX_SEND_COUNT .. "}"
	},
	{
		def = "serial_num=I,flag=B",
		id = gscl_msg_id.msg_visit_caishen,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,prize_id=I,count=I",
		id = gscl_msg_id.msg_exchange_caishen_prize,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_exchange_tools,
		base = common_id.msg_base,
		def = "serial_num=I,state=B,skill_id=" .. type_def.objguid
	},
	{
		id = gscl_msg_id.msg_item_transform,
		base = common_id.msg_base,
		def = "serial_num=I,state=B,item_id=" .. type_def.objguid
	},
	{
		def = "serial_num=I,flag=B,count=I,index=I",
		id = gscl_msg_id.msg_hunt_soul,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,flag=B,count=I,index=I,ten_card=I,five_card=I",
		id = gscl_msg_id.msg_sky_pavilion,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_exchange_tangwang_prize,
		base = common_id.msg_base,
		def = "serial_num=I,count=B,card_list=$" .. common_id.type_object_data .. "{" .. const.MAX_SEND_COUNT .. "}"
	},
	{
		id = gscl_msg_id.msg_lantern_activity,
		base = common_id.msg_base,
		def = "serial_num=I,flag=B,index=B,answer=S[" .. const.MAX_SEND_NAME_LEN .. "]"
	},
	{
		def = "serial_num=I,prize_id=I",
		id = gscl_msg_id.msg_spring_charge_prize,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,flag=B",
		id = gscl_msg_id.msg_query_charge_prize,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,first_send=B",
		id = gscl_msg_id.msg_query_consume_gold_prize,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,prize_id=I",
		id = gscl_msg_id.msg_take_consume_gold_prize,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,op_type=B,flag=B,level=B",
		id = gscl_msg_id.msg_week_activity,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_query_activity_info,
		base = common_id.msg_base,
		def = "serial_num=I,activity_id=" .. type_def.objguid
	},
	{
		def = "serial_num=I,success=B,activity=s",
		id = gscl_msg_id.msg_update_activity_info,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,first_send=B",
		id = gscl_msg_id.msg_query_labourday_info,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,prize_id=I,count=I",
		id = gscl_msg_id.msg_exchange_labourday_prize,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,roll_type=B,roll_times=B",
		id = gscl_msg_id.msg_roll_labourday_miles,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_baozongzi,
		base = common_id.msg_base,
		def = "serial_num=I,compose_type=B,material_count=B,material_list=$" .. common_id.type_compose_material_data .. "{" .. const.MAX_METERIAL_COUNT .. "}"
	},
	{
		def = "serial_num=I,flag=B,data=s",
		id = gscl_msg_id.msg_furnace,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I",
		id = gscl_msg_id.msg_query_champion_list,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I",
		id = gscl_msg_id.msg_use_map_flush,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,list_type=B,list_index=B",
		id = gscl_msg_id.msg_buy_mystery_item,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,op_type=B,flag=B,id=I",
		id = gscl_msg_id.msg_query_take_item,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_valentine_activity,
		base = common_id.msg_base,
		def = "serial_num=I,flag=B,index=B,answer=S[" .. const.MAX_SEND_NAME_LEN .. "]"
	},
	{
		def = "serial_num=I,buy_count=B",
		id = gscl_msg_id.msg_group_buy,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,buy_index=B",
		id = gscl_msg_id.msg_panic_buy,
		base = common_id.msg_base
	},
	{
		def = "sale_time=I",
		id = gscl_msg_id.msg_query_panic_buy_info,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,index=B",
		id = gscl_msg_id.msg_random_monday_prize,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_query_fight_record,
		base = common_id.msg_base,
		def = "serial_num=I,fight_type=B,log_time=I,match_type=B,src_id=" .. type_def.objguid
	},
	{
		def = "serial_num=I",
		id = gscl_msg_id.msg_friend_vip_upgrade,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,op_type=I,index=I,count=I",
		id = gscl_msg_id.msg_amrita,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,act_type=B,index=B,flag=B",
		id = gscl_msg_id.msg_common_activity,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I",
		id = gscl_msg_id.msg_query_single_win_prize,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I",
		id = gscl_msg_id.msg_query_match_info,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_query_lineup_data,
		base = common_id.msg_base,
		def = "serial_num=I,des_id=" .. type_def.objguid
	},
	{
		def = "serial_num=I,is_charge=I",
		id = gscl_msg_id.msg_flush_challenge_enemy,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,streak_count=I",
		id = gscl_msg_id.msg_take_win_streak_prize,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I",
		id = gscl_msg_id.msg_query_single_toplist,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_single_toplist_response,
		base = common_id.msg_base,
		def = "serial_num=I,top_count=B,top_list=$" .. common_id.type_single_top_data .. "{" .. const.MAX_SEND_COUNT .. "}"
	},
	{
		def = "serial_num=I",
		id = gscl_msg_id.msg_take_singlerank_prize,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,id=B,data=s",
		id = gscl_msg_id.msg_union_event,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,id=B,data=s",
		id = gscl_msg_id.msg_hole_event,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,id=B,data=s",
		id = gscl_msg_id.msg_undergo_ordeal_event,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,id=B,data=s",
		id = gscl_msg_id.msg_free_fight_event,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,id=B,data=s",
		id = gscl_msg_id.msg_summer_activity,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,id=B,data=s",
		id = gscl_msg_id.msg_rulai_activity,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,id=B,data=s",
		id = gscl_msg_id.msg_daily_pay,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,id=B,data=s",
		id = gscl_msg_id.msg_babel_tower,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,index=B",
		id = gscl_msg_id.msg_newbie_scores_awards,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,days=B,index=B",
		id = gscl_msg_id.msg_newbie_daily_act_awards,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,index=B",
		id = gscl_msg_id.msg_newbie_purchase,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,id=B,data=s",
		id = gscl_msg_id.msg_fate_rebuilding_op,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,index=B",
		id = gscl_msg_id.msg_newbie_create,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,star_id=d,des_type=B",
		id = gscl_msg_id.msg_fate_star_switch,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,flag=B,src_type=I",
		id = gscl_msg_id.msg_autumn_activity,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,flag=B,index=B",
		id = gscl_msg_id.msg_yuanshi_activity,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,id=B,data=s",
		id = gscl_msg_id.msg_world_imperial,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,event_type=B,data=s",
		id = gscl_msg_id.msg_divination_event,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,flag=B,index=B,count=I",
		id = gscl_msg_id.msg_vip_shop,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,id=B,data=s",
		id = gscl_msg_id.msg_prey_event,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,id=B,data=s",
		id = gscl_msg_id.msg_weekend_event,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,id=B,data=s",
		id = gscl_msg_id.msg_nine_sky,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,id=B,data=s",
		id = gscl_msg_id.msg_save_monkey,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,id=B,data=s",
		id = gscl_msg_id.msg_spirit_gossip,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,reborn_type=B,id=B,data=s",
		id = gscl_msg_id.msg_reborn_event,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,id=B,data=s",
		id = gscl_msg_id.msg_specter_event,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,flag=B,id=B,data=s",
		id = gscl_msg_id.msg_animal_event,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,id=B,op_type=B,data=s",
		id = gscl_msg_id.msg_team_event,
		base = common_id.msg_base
	},
	{
		id = gscl_msg_id.msg_equip_ext_skill,
		base = common_id.msg_base,
		def = "serial_num=I,ext_skill_id=" .. type_def.objguid .. ",des_cortege_id=" .. type_def.objguid .. ",lock_list=s"
	},
	{
		id = gscl_msg_id.msg_upgrade_ext_skill,
		base = common_id.msg_base,
		def = "serial_num=I,ext_skill_id=" .. type_def.objguid .. ",cost_count=I"
	},
	{
		id = gscl_msg_id.msg_equip_ext_star,
		base = common_id.msg_base,
		def = "serial_num=I,des_cortege_id=" .. type_def.objguid .. ",ext_star_id=" .. type_def.objguid .. ",element_id=I,replace=B"
	},
	{
		id = gscl_msg_id.msg_unload_ext_star,
		base = common_id.msg_base,
		def = "serial_num=I,des_cortege_id=" .. type_def.objguid .. ",element_id=I"
	},
	{
		id = gscl_msg_id.msg_upgrade_ext_star,
		base = common_id.msg_base,
		def = "serial_num=I,ext_star_id=" .. type_def.objguid .. ",cost_count=I"
	},
	{
		id = gscl_msg_id.msg_decompose_ext_star,
		base = common_id.msg_base,
		def = "serial_num=I,count=B,star_list=$" .. common_id.type_object_data .. "{" .. const.MAX_SEND_COUNT .. "}"
	},
	{
		def = "serial_num=I,id=B,data=s",
		id = gscl_msg_id.msg_longevity_hill,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,id=B,data=s",
		id = gscl_msg_id.msg_pile_snowman,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,id=B,data=s",
		id = gscl_msg_id.msg_analysis_dream,
		base = common_id.msg_base
	},
	{
		def = "version=I",
		id = gscl_msg_id.msg_update_version,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,id=B,data=s",
		id = gscl_msg_id.msg_monster_nian,
		base = common_id.msg_base
	},
	{
		def = "tip_type=I,tip_info=s",
		id = gscl_msg_id.msg_send_tip_info,
		base = common_id.msg_base
	},
	{
		def = "ret=B",
		id = gscl_msg_id.msg_reconnect_notify,
		base = common_id.msg_base
	},
	{
		def = "area_id=I,reason=B",
		id = gscl_msg_id.msg_kick_player,
		base = common_id.msg_base
	},
	{
		def = "serial_num=I,id=B,data=s",
		id = gscl_msg_id.msg_common_event,
		base = common_id.msg_base
	},
	{
		def = "time=I,random_key=I,delay_time=I",
		id = gscl_msg_id.msg_keep_alive,
		base = common_id.msg_base
	},
	{
		def = "data_size=i,data=s",
		id = gscl_msg_id.msg_compress_data,
		base = common_id.msg_base
	}
}
lscl_msg = {
	{
		def = "id=B,data=s",
		id = lscl_msg_id.msg_common_event,
		base = common_id.msg_base
	},
	{
		id = lscl_msg_id.msg_login_rsp,
		base = common_id.msg_base,
		def = "auth_key=I,seed=I,server_port=I,account=S[" .. const.MAX_SEND_ACCOUNT_LEN .. "],server_ip=s"
	}
}
gsls_msg = {
	{
		id = gsls_msg_id.msg_login_req,
		base = common_id.msg_base,
		def = "area=I,server_port=I,server_ip=S[" .. const.LONG_IP_LEN .. "],area_count=B,area_list=$" .. common_id.type_area .. "{" .. const.MAX_SEND_COUNT .. "}"
	},
	{
		id = gsls_msg_id.msg_login_rsp,
		base = common_id.msg_base,
		def = "result=B,dba_port=I,dba_ip=S[" .. const.LONG_IP_LEN .. "]"
	},
	{
		id = gsls_msg_id.msg_prelogin,
		base = common_id.msg_base,
		def = "connect_id=I,auth_key=I,hash_account=I,account_id=" .. type_def.objguid .. ",gm_level=I,last_login=I,last_logout=I,account_name=S[" .. const.MAX_SEND_ACCOUNT_LEN .. "]" .. ",pf_type=I,pf_account=S[" .. const.MAX_MOBILE_ACCOUNT_LEN .. "],pf_username=S[" .. const.MAX_MOBILE_ACCOUNT_LEN .. "],mobile_account=S[" .. const.MAX_MOBILE_ACCOUNT_LEN .. "]" .. ",ad_id=I,mac=S[" .. const.MAX_MOBILE_ACCOUNT_LEN .. "],idfa=S[" .. const.MAX_MOBILE_ACCOUNT_LEN .. "],ad_channel=S[" .. const.MAX_MOBILE_ACCOUNT_LEN .. "],area_id=I,access_token=s"
	},
	{
		id = gsls_msg_id.msg_prelogin_ret,
		base = common_id.msg_base,
		def = "connect_id=I,account=I,hash_account=I,auth_key=I,seed=I,listen_port=I,listen_ip=S[" .. const.LONG_IP_LEN .. "]"
	},
	{
		id = gsls_msg_id.msg_create_role_ok,
		base = common_id.msg_base,
		def = "account_id=I,hash_account=I,account_name=S[" .. const.MAX_SEND_ACCOUNT_LEN .. "],role_id=" .. type_def.objguid .. ",role_name=S[" .. const.MAX_SEND_NAME_LEN .. "]"
	},
	{
		def = "account_id=I,hash_account=I,area=I",
		id = gsls_msg_id.msg_client_logined,
		base = common_id.msg_base
	},
	{
		def = "account_id=I,hash_account=I,area=I",
		id = gsls_msg_id.msg_client_logouted,
		base = common_id.msg_base
	},
	{
		def = "account_id=I,hash_account=I,area=I",
		id = gsls_msg_id.msg_client_released,
		base = common_id.msg_base
	},
	{
		def = "status=b",
		id = gsls_msg_id.msg_update_status,
		base = common_id.msg_base
	},
	{
		def = "count=I",
		id = gsls_msg_id.msg_update_online_count,
		base = common_id.msg_base
	}
}
gsdba_msg = {
	{
		def = "area=I,session=I,reconnect=b",
		id = gsdba_msg_id.msg_login_req,
		base = common_id.msg_base
	},
	{
		def = "result=b,reset_count=w",
		id = gsdba_msg_id.msg_login_rsp,
		base = common_id.msg_base
	}
}
lsdba_msg = {
	{
		def = "reconnect=b",
		id = lsdba_msg_id.msg_login_req,
		base = common_id.msg_base
	},
	{
		def = "result=b,reset_count=w",
		id = lsdba_msg_id.msg_login_rsp,
		base = common_id.msg_base
	}
}
lsdti_msg = {
	{
		def = "reconnect=b",
		id = lsdti_msg_id.msg_login_req,
		base = common_id.msg_base
	},
	{
		def = "result=b",
		id = lsdti_msg_id.msg_login_rsp,
		base = common_id.msg_base
	}
}
gsdti_msg = {
	{
		def = "reconnect=b",
		id = gsdti_msg_id.msg_login_req,
		base = common_id.msg_base
	},
	{
		def = "result=b",
		id = gsdti_msg_id.msg_login_rsp,
		base = common_id.msg_base
	},
	{
		def = "id=B,data=s",
		id = gsdti_msg_id.msg_common_event,
		base = common_id.msg_base
	}
}
wsdba_msg = {
	{
		def = "reconnect=b",
		id = wsdba_msg_id.msg_login_req,
		base = common_id.msg_base
	},
	{
		def = "result=b,reset_count=w",
		id = wsdba_msg_id.msg_login_rsp,
		base = common_id.msg_base
	}
}
gsbs_msg = {
	{
		id = gsbs_msg_id.msg_login_req,
		base = common_id.msg_base,
		def = "first_connect=l,server_id=I,listen_port=I,listen_ip=S[" .. const.LONG_IP_LEN .. "]"
	},
	{
		def = "result=B",
		id = gsbs_msg_id.msg_login_rsp,
		base = common_id.msg_base
	},
	{
		def = "client_index=I",
		id = gsbs_msg_id.msg_disconnect_client,
		base = common_id.msg_base
	},
	{
		def = "client_index=I,disconnect_reason=B,disconnect_msg=W",
		id = gsbs_msg_id.msg_client_disconnected,
		base = common_id.msg_base
	}
}

local function register_all_common_msgs()
	for i = 1, #common_def do
		main_server.register_type(common_def[i].id, common_def[i].def)
	end
end

local function register_all_client_msgs_for_gs()
	for i = 1, #gscl_msg do
		main_server.register_type(gscl_msg[i].id, gscl_msg[i].def)
	end
end

local function register_all_client_msgs_for_ls()
	for i = 1, #lscl_msg do
		main_server.register_type(lscl_msg[i].id, lscl_msg[i].def)
	end
end

local function register_all_ls_msgs_for_gs()
	for i = 1, #gsls_msg do
		main_server.register_type(gsls_msg[i].id, gsls_msg[i].def)
	end
end

local function register_all_bs_msgs_for_gs()
	for i = 1, #gsbs_msg do
		main_server.register_type(gsbs_msg[i].id, gsbs_msg[i].def)
	end
end

local function register_all_dba_msgs_for_gs()
	for i = 1, #gsdba_msg do
		main_server.register_type(gsdba_msg[i].id, gsdba_msg[i].def)
	end
end

local function register_all_dba_msgs_for_ls()
	for i = 1, #lsdba_msg do
		main_server.register_type(lsdba_msg[i].id, lsdba_msg[i].def)
	end
end

local function register_all_dti_msgs_for_ls()
	for i = 1, #lsdti_msg do
		main_server.register_type(lsdti_msg[i].id, lsdti_msg[i].def)
	end
end

local function register_all_dti_msgs_for_gs()
	for i = 1, #gsdti_msg do
		main_server.register_type(gsdti_msg[i].id, gsdti_msg[i].def)
	end
end

local function register_all_dba_msgs_for_ws()
	for i = 1, #wsdba_msg do
		main_server.register_type(wsdba_msg[i].id, wsdba_msg[i].def)
	end
end

function register_all_msg()
	register_all_common_msgs()
	register_all_client_msgs_for_gs()
	register_all_client_msgs_for_ls()
	register_all_ls_msgs_for_gs()
	register_all_dba_msgs_for_gs()
	register_all_dba_msgs_for_ls()
	register_all_dba_msgs_for_ws()
	register_all_dti_msgs_for_ls()
	register_all_dti_msgs_for_gs()
	register_all_bs_msgs_for_gs()
end
