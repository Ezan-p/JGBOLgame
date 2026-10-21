"""Reproduce the character reference and its source audit from local game data."""
import argparse
import collections
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from game_config import ROOT, load_config
from local_game.assets import CATEGORIES, Resources, character_sprite, is_handbook_hero


def build_report():
    resources = Resources(load_config()["game_root"])
    tables = {}

    def rows(name):
        if name not in tables:
            tables[name] = resources.rows(name)
        return tables[name]

    base_name = "csv_config/cortege/cortege_base_0.csv"
    bases = rows(base_name)
    names = {int(r["type_id"]): r for r in rows(base_name.replace("base", "name"))}
    roster = sorted((r for r in bases if is_handbook_hero(r)),
                    key=lambda r: (-int(r["quality"]), int(r["type_id"])))
    roster_ids = {int(r["type_id"]) for r in roster}
    skills = {int(r["type_id"]): r for r in rows("csv_config/skill_name.csv")}
    skill_bases = {int(r["type_id"]): r for r in rows("csv_config/skill_base.csv")}
    items = {r["Ftype_id"]: r for r in rows("csv_config/item_name.csv")}
    fates = rows("csv_config/fate_config.csv")
    reborn = {int(r["cortege_type"]): r for r in rows("csv_config/cortege_reborn_config.csv")}
    collections_table = rows("csv_config/collector_cortege.csv")
    summon = rows("csv_config/summon_cortege_set.csv")

    sheets = []

    def add_sheet(name, title, note, columns, data, widths):
        assert all(len(row) == len(columns) for row in data), name
        sheets.append(dict(name=name, title=title, note=note,
                           columns=columns, rows=data, widths=widths))

    grouped_fates = collections.defaultdict(list)
    for row in fates:
        grouped_fates[int(row["cortege_type[effected_cortege]"])].append(row)
    hero_rows = []
    for row in roster:
        ident = int(row["type_id"])
        skill_id = int(row["chushijineng"])
        hero_rows.append([
            str(ident), names[ident]["name"].strip(), int(row["quality"]),
            CATEGORIES[int(row["category"])], names[ident]["desc"],
            skills[skill_id]["name"], skills[skill_id]["desc"],
            *[int(row[k]) for k in ("base_gongji", "base_fangyu", "base_max_hp", "base_max_magic")],
            *[float(row[k]) for k in ("base_gongji_plus", "base_fangyu_plus", "base_maxhp_plus", "base_maxmagic_plus")],
            len(grouped_fates[ident]),
            reborn.get(ident, {}).get("name", "无配置"),
            "、".join(r["desc"] for r in summon if str(ident) in r["type_set(id1/id2/id3...)"].split("/")) or "召唤表未列入",
            "、".join(r["name"] for r in collections_table
                    if str(ident) in [x.split("|")[0] for x in r["line_up(object_type|attach_type|attach_count|attach_level|attch_weight)"].split("/")]) or "无配置",
            600, "初始拥有" if ident in (5022, 5004) else "可招募",
            str(skill_id), character_sprite(row),
        ])
    add_sheet("神仙介绍", "金箍棒神仙角色介绍表",
              "原包1061＋已下载更新1263：166位图鉴角色；原文属性与技能仅作资料，本地战斗使用独立公式。每位招募600银两，已拥有者不重复显示。",
              ["角色ID", "神仙名称", "星级", "阵营", "原文简介", "原生技能", "原文技能说明",
               "基础攻击", "基础防御", "基础生命", "基础法力", "攻击成长", "防御成长", "生命成长", "法力成长",
               "仙缘数量", "转生名称", "原版召唤集合", "收集组合", "本地招募银两", "新存档状态", "技能ID", "立绘路径"],
              hero_rows, [12, 20, 8, 8, 65, 20, 50, 13, 13, 13, 13, 13, 13, 13, 13, 13, 22, 25, 30, 16, 16, 12, 32])

    skill_rows = []
    for ident, row in sorted(skill_bases.items()):
        info = skills[ident]
        owners = [names[int(r["type_id"])]["name"].strip() for r in roster if int(r["chushijineng"]) == ident]
        skill_rows.append([
            str(ident), info["name"], info["desc"], info["introduce"], info["product_desc"],
            "、".join(owners) or "未被图鉴角色设为初始技能", int(row["quality"]),
            {"1": "主动", "2": "被动"}.get(row["use_mode(1-active，2-passive)"], "未知"),
            {"1": "单体", "2": "群体"}.get(row["effect_target(1-single，2-multi)"], "未知"),
            row["formula"], row["intensity"], row["use_probability"],
        ])
    add_sheet("技能资料", "原包技能配置", "保留全部技能及原始字段。公式编号和概率是客户端配置值，不推测原服实现。",
              ["技能ID", "名称", "技能说明", "介绍", "策划说明", "初始拥有神仙", "品质", "使用方式", "目标",
               "公式编号", "强度原值", "概率原值"], skill_rows,
              [12, 20, 55, 55, 50, 70, 10, 12, 12, 14, 14, 14])

    fate_rows = []
    for row in fates:
        ident = int(row["cortege_type[effected_cortege]"])
        kind = row["tartege_type[4-cortege/5-equip/6-skill]"]
        target_ids = row["target_object_type[1/2/3]"].split("/")
        target_table = {"4": {str(k): v for k, v in names.items()},
                        "5": items, "6": {str(k): v for k, v in skills.items()}}.get(kind, {})
        fate_rows.append([
            row["fate_type"], str(ident), names.get(ident, {}).get("name", "未匹配"),
            row["fate_name"], row["fate_desc"],
            {"4": "角色", "5": "装备/物品", "6": "技能"}.get(kind, kind),
            row["target_object_type[1/2/3]"],
            "、".join(target_table.get(i, {}).get("name", "未匹配ID " + i) for i in target_ids),
            {"1": "生命", "2": "法力", "3": "攻击", "4": "防御"}[row["effect_field[1-maxhp/2-maxmagic/3-gongji/4-fangyu]"]],
            int(row["effect_value"]),
        ])
    add_sheet("仙缘", "全部仙缘关系", "效果值按原表记录；百分比含义见原文说明。本地版尚未启用仙缘加成。",
              ["仙缘ID", "角色ID", "神仙名称", "仙缘名称", "触发条件与效果", "关联类型", "关联ID", "关联名称", "加成属性", "效果原值"],
              fate_rows, [12, 12, 20, 20, 75, 16, 32, 55, 14, 14])

    reborn_rows = []
    for ident, row in reborn.items():
        sprite = "chars/5/5_" + row["source_id"] + ".png"
        available = sprite in resources.names()
        reborn_rows.append([str(ident), names[ident]["name"], row["name"], row["plus_type"], sprite,
                            "已提取" if available else "更新索引有记录，但缓存未下载",
                            "原角色转生形态，不是独立角色ID"])
    add_sheet("转生形态", "转生名称与立绘", "25条转生配置按原角色ID关联；11张转生立绘未下载。转生功能未接入本地战斗。",
              ["原角色ID", "原名称", "转生名称", "加成类型原值", "立绘路径", "资源状态", "身份说明"],
              reborn_rows, [14, 22, 24, 18, 32, 42, 42])

    dialogue_rows = []
    for name in ("csv_config/tollgate_diag.csv", "csv_config/battle_diag.csv"):
        for i, row in enumerate(rows(name), 2):
            dialogue_rows.append([row["npc_id"], row["name"], row["map_id"], row.get("tollgate_id", ""),
                                  row.get("diag_time", row.get("step", "")), row["content"], name, i])
    add_sheet("剧情对白", "角色剧情原文", "按npc_id保留对白与旁白；不按同名强行合并身份。行号包含CSV表头。",
              ["角色ID", "说话者", "地图ID", "关卡ID", "时机/步骤", "对白原文", "来源资源", "行号"],
              dialogue_rows, [14, 22, 12, 12, 16, 110, 45, 10])

    instance_rows = []
    all_base_names = [n for n in resources.names()
                      if n.startswith("csv_config/cortege/cortege_base_")
                      or n in ("csv_config/elite/elite_cortege_base.csv", "csv_config/elite/specter_cortege_base.csv")]
    for name in all_base_names:
        name_table = {r["type_id"]: r for r in rows(name.replace("_base", "_name"))}
        for line, row in enumerate(rows(name), 2):
            ident = int(row["type_id"])
            info = name_table.get(str(ident), {})
            classification = ("图鉴神仙" if is_handbook_hero(row) else
                              "主角占位" if ident in (1, 2) else
                              "普通兵种" if name == base_name and 1000 <= ident < 2000 else "关卡/活动实例")
            instance_rows.append([
                str(ident), info.get("name", "").strip(), row["base_type_id"], classification,
                int(row["quality"]), CATEGORIES.get(int(row["category"]), row["category"]),
                *[int(row[k]) for k in ("base_gongji", "base_fangyu", "base_max_hp", "base_max_magic")],
                row["chushijineng"], info.get("desc", ""), character_sprite(row), name, line,
            ])
    add_sheet("全部角色实例", "完整角色配置索引", "保留基础表、67组普通关卡表、精英与幽冥配置；重复实例按来源＋ID区分，招募仅使用166个图鉴ID。",
              ["实例ID", "名称", "基础角色ID", "分类", "品质", "阵营", "攻击", "防御", "生命", "法力", "技能ID",
               "原文说明", "立绘路径", "来源资源", "行号"],
              instance_rows, [14, 24, 16, 20, 10, 10, 14, 14, 14, 14, 14, 70, 35, 65, 10])

    # Retain complete related tables in machine-readable evidence, including growth rules.
    for name in resources.names():
        if name.startswith("csv_config/") and any(token in name for token in (
            "cortege", "skill", "fate", "tollgate", "map_name", "awaken")):
            rows(name)
    source_rows = []
    sources = []
    for name in sorted(tables):
        source = resources.source(name)
        sources.append(source)
        source_rows.append([name, source["version"], len(tables[name]), source["filename"], source["sha256"]])
    add_sheet("来源索引", "配置来源与校验", "更新快照优先，未更新资源来自原包。目录中的character_report.json保留已提取配置的全部字段。",
              ["逻辑资源路径", "索引版本", "数据行数", "原始资源文件", "SHA-256"],
              source_rows, [65, 16, 14, 50, 80])
    notes = [
        ["统计口径", "图鉴神仙166位：5星46位、4星66位、3星35位、2星19位。阵营包括神、妖、人、魔、佛。"],
        ["筛选证据", "原版handbookUI.lua：100 < type_id < 6000，quality > 1，book_hide == 1。字段虽名为hide，值1表示图鉴收录。"],
        ["版本变化", "1061基础包图鉴164位；1263更新使元始天尊进入图鉴，并新增如来佛祖。"],
        ["同名与形态", "转生形态25条挂在原角色ID下。普通兵种、试炼阎王、仙盟守护树及关卡变体保留在实例附录，不算新增可招募神仙。"],
        ["当前招募", "166位全部进入本地招募白名单；新存档孙悟空、沙悟净已拥有，因此显示164位待招募。老存档自动排除已拥有角色。"],
        ["招募规则", "每位600银两，无品质或关卡门槛；最多3位出战，拥有数量不受此限制。没有修改真实玩家银两或已拥有角色。"],
        ["战斗限制", "原表技能、仙缘、法力、转生、成长系数为逆向资料，未接入本地规则。界面技能名称仅为原生技能信息。"],
        ["本地公式", "属性＝基础值×(1＋0.14×(等级－1))；普通伤害=max(1,round(攻击－0.45×防御))；每第三回合攻击系数1.45。"],
        ["资源缺口", "11张转生立绘5_63至5_73仅有索引记录，未下载；166位基础神仙立绘均已验证可读取。"],
        ["索引差异", "部分更新图片及Lua的索引大小与缓存实际大小不同。快照同时保存index_size、实际size和SHA-256，不把索引值当成已验证文件内容。"],
        ["文本原貌", "简介和对白保留游戏原文（包括原文错别字）；缺失字段不补写神话设定，不推测原服掉率或未提供的公式。"],
        ["再生成", "在cloud_android执行python3 scripts/export_character_report.py；Excel由scripts/build_character_workbook.mjs生成。"],
    ]
    add_sheet("阅读说明", "提取口径与本地实现", "核对日期：2026-10-20。仅分析本项目原包及本机已下载更新。",
              ["事项", "说明"], notes, [22, 125])
    return dict(summary=dict(heroes=len(roster), qualities=dict(collections.Counter(r["quality"] for r in roster)),
                             instances=len(instance_rows), skills=len(skill_rows), fates=len(fate_rows),
                             dialogues=len(dialogue_rows), reborn=len(reborn_rows)),
                sheets=sheets, sources=sources, raw_tables=tables)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=ROOT / "outputs/characters-20261020")
    args = parser.parse_args()
    report = build_report()
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output / "character_report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2))
    print(json.dumps(report["summary"], ensure_ascii=False))


if __name__ == "__main__":
    main()
