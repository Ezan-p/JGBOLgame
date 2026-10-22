"""Reproducible item reference table; no player-state access."""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from game_config import ROOT, load_config
from local_game.inventory import build_inventory, CATEGORIES, value

RULES = {
    "equip": "装备、卸下、强化、镶嵌、熔炼；属性参与战斗",
    "spell": "装备、卸下、升级、熔炼；主动替换技能，被动增加对应属性",
    "gem": "3颗同类同级合成1颗高一级；最高10级；镶嵌、无损卸下",
    "fragment": "10片同名碎片合成对应装备",
    "energy": "恢复配置strength_plus点体力；上限60，已满不消耗",
    "experience": "增加配置experience_plus点行者经验（本地映射）",
    "train": "魂缘丹提升所选神仙1级，最高20级（本地规则）",
    "material": "精魄石可每颗兑换20银两（本地规则）",
    "reference": "资料可查；所属系统未接入，不提供兑换或消耗",
}


def main():
    result = build_inventory(load_config()["game_root"])
    output = ROOT / "outputs/inventory-20261021"
    output.mkdir(parents=True, exist_ok=True)
    (output/"包裹逆向数据.json").write_text(json.dumps(result, ensure_ascii=False, indent=2))
    sheets = []
    for category, title in CATEGORIES.items():
        rows = []
        for item in sorted(result["items"].values(), key=lambda i: (-i["quality"], i["id"])):
            if item["category"] != category:
                continue
            b = item["original"]
            effect = ({1: "攻击", 2: "防御", 3: "生命"}.get(category, "")
                      if category != 4 else {1: "攻击%", 2: "防御%", 3: "法力%", 4: "技能强度", 5: "生命%"}.get(int(b["effect_field"])))
            icon = item["icon"] or {}
            rows.append([item["id"], item["name"], item["quality"], item["description"],
                effect or "见原文", value(item, 1), float(b["upgrade_plus"]), item["top_level"],
                item["obtain"], RULES[item["action"]], item["price"] or None,
                icon.get("file", item.get("missing_icon", "")), icon.get("index", 1),
                item["main_type"], "是" if item["original_bag"] else "否（附录归入道具）"])
        sheets.append(dict(name=title, title=f"包裹资源介绍：{title}（{len(rows)}项）",
            note="来源：APK 1061 + 更新缓存1263；完整原字段与SHA-256见同目录逆向数据JSON。",
            columns=["原ID", "名称", "星级", "原文介绍", "属性类型", "一级基础值", "每级增量", "原等级上限",
                     "原获取途径", "本地功能", "本地兑换银两", "图标资源", "图格序号", "原主类型", "原包裹显示"],
            widths=[12, 26, 8, 64, 16, 15, 14, 15, 48, 58, 18, 42, 14, 14, 25], rows=rows))
    explanation = [
        ["数据范围", "829项物品和64项法术，共893项。装备109件，灵石3类，道具附录717项。"],
        ["原版显示", "getAllProps排除主类10、11、13、15；这些仍收录在道具附录，原包裹显示列标为否。"],
        ["截图核对", "筋斗云4002、曼陀罗4012、定风珠4013；火眼金睛43、一气化三清42；精魄石10000、魂缘丹1024。"],
        ["同名区分", "1350也是定风珠，但属于活动道具；4013是法宝。物品i与法术s使用独立命名空间。"],
        ["素材", "全部893条有图标，表内记录图集与1起始格号。灵石图标格号随等级递增。"],
        ["强化", "装备基础值＋upgrade_plus×(等级−1)；费用读取equip_enhance_cost。高阶加成未接入。"],
        ["法术", "主动法术每第三回合释放，伤害系数1.45＋0.05×(等级−1)；被动攻防生命按原配置百分比。"],
        ["法术边界", "9项依赖法力或未实现属性的法术只作资料；仙缘、突破和原服概率未接入。"],
        ["法术费用", "100×星级×当前等级银两，为明确的本地规则。原消耗表完整保留在JSON。"],
        ["灵石", "一物一对象，owner_uid/equip_pos记录镶嵌；孔位按品质1/1/1/2/3；打孔消耗金刚钻；每孔百分比读取stone_cost_worth.base并相加；升级消耗同名同类灵石与银两，成功率读取cost/worth与prob_compen。"],
        ["熔炼", "仅允许未装备且无灵石的装备/法术，产出max(1,星级)×等级颗精魄石；本地规则。"],
        ["合成", "10个同名装备碎片合成1件对应装备；本地规则。原随机合成配置仅作原始资料。"],
        ["兑换", "资源图录仅出售已接入玩法物品；每件max(40,星级×100)，法术最低100银两。"],
        ["存档", "旧存档保留资产，首次使用增加空包裹；入门物资需主动领取一次。扣费与材料消费同一事务提交。"],
        ["未接入系统", "原服活动礼包、VIP、转生、精魄技能、法力等资料保留；未接入者不扣物品、不出售。"],
    ]
    explanation.extend([s["resource"], f'版本{s["version"]}；SHA-256 {s["sha256"]}'] for s in result["sources"])
    sheets.append(dict(name="规则与来源", title="提取依据与本地规则",
        note="原版名称、美术和配置与本地玩法分别标注；不推测未提供的原服务器算法。",
        columns=["项目", "说明"], widths=[48, 120], rows=explanation))
    (output/"inventory_report.json").write_text(json.dumps({"sheets": sheets}, ensure_ascii=False, indent=2))
    print(output)


if __name__ == "__main__":
    main()
