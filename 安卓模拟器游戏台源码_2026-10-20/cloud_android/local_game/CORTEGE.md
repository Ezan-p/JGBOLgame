# 神仙模块逆向说明（魂魄 / 精魄 / 五法界魂 / 图鉴）

本篇记录底部“神仙”入口的还原依据。界面按原包 `ui/lineupUI.lua` 与
`ui/handbookUI.lua` 反编译结果重建，数据来自原版 CSV 与资源索引。

## 入口层级

原版底部“神仙”不是直接打开图鉴，而是先进入 `lineupUI` 的伙伴面板：

- 左侧四张卷轴标签：`v2/CharaterUI/shenxian1/2.png`（神仙）、
  `hunpo1/2.png`（魂魄）、`jingpo1/2.png`（精魄）、`common1/2.png`（五法界魂）。
- 标签下方为 `v2/handbook/tj_btn1/2.png`“图鉴”按钮。点击后调用
  `d_handbookUI.g_self.ready_open_tag = 4` 并打开 `handbookUI`。
- 图鉴页使用另一组标签：`shenxian`、`packageUI/equip`、
  `packageUI/Label_spell`、`handbook/btn7`，依次对应神仙、装备、法术、精魄。
- 面板沿用 `mainUI.createBoardBkg` 的尺寸：中心 `.5/.56`，缩放 `.95/.8`；
  本地 960×540 画布对应左栏 x≈24..218、内容区 x≈249.6..912。
- 列表行来自 `allLineupUI` / `soulExchangeUI` 的 cell：底图
  `v2/packageUI/xinxilan.png`，图标在行宽 10% 处，名称 20%、星级 43%，
  数量在名称下方，操作按钮在 85% 处。本地把 0.7×0.21 屏的 cell 映射为
  662×104、行距 118.8。

## 魂魄（神仙魂魄）

- 原版 `allLineupUI.showAllSoul` 读取 `d_data.g_soulsInfoTable`，该表只收录
  `count > 0` 的神仙魂魄（`data.recvSoulsDataFromServer`）。
- 排序 `sortSoul`：可幻魂优先、品质降序、数量降序、名称降序。
- 数量来源：
  - 重复召唤：`csv_config/cortege_quality.csv` 的 `spirit_convert_count`
    （2★4、3★9、4★12、5★15）。
  - 五法界魂转化：见下文。
- 幻魂（`spirit_compose_count`）：2★10、3★20、4★30、5★40。原版按钮为
  `v2/introUI/conjure1/2.png`；数量不足时灰化并提示 `need_souls`。
- 本地实现：`local_game/cortege.py:compose`，扣魂魄、加入神仙列表，阵位有空位
  时自动上场；重复拥有会被拒绝。对应 `state.souls`。

## 精魄

- 原版 `lineupUI.showJingpo` 取 `g_reorgItemsInfo[o_t.item][m_t.ext_skill]`
  （`common_def.item_main_type.ext_skill = 15`），即 `item_base.csv` 中
  main_type 15 的 38 项精魄（10101 起），图标为 `skill/ext/<resource>.png`。
- 行内显示名称、品质星级、等级（`introUI/level.png`）、数量；已装配时显示
  “装备”与神仙名，未装配时显示 `v2/transformUI/btn11/12.png`“打造”入口。
- 本地版保留资料查阅与数量/等级展示；装配、打造、进阶仍在包裹/后续玩法中，
  本页不伪造服务器公式。

## 五法界魂

- 原版 `lineupUI.showCommonSoul` 取 `m_t.adaptive_spirit = 11`，
  即 `item_base.csv` 中 main_type 11 的 10 项：5★/4★ × 神、妖、人、魔、佛。
  图标来自 `items/all_daoju1.png` 的 8×8 图集（resource 41..50）。
- 名称由 `item_name.csv` 提供：五星仙界魂、五星妖界魂、五星人界魂、
  五星魔界魂、五星佛界魂，以及对应的四星五件。
- 排序 `soulExchangeUI.adaptiveSpiritSort`：品质降序、`sub_type` 升序，
  所以同级顺序为 仙(1)、妖(2)、人(3)、魔(4)、佛(5)。
- 每行显示图标、名称、星级、`number: count` 与“转化”按钮；数量为 0 时图标
  变暗、按钮禁用（参考图中也保留了数量 0 的条目）。
- 转化规则：
  - `csv_config/adaptive_spirit_convert.csv` 列出全部 112 位 4★/5★神仙，
    `need_count` 均为 1。原版 `showCortegeSoulChooseLayer` 用
    `getTypicalCorteges(item.sub_type, item.quality)` 找同阵营、同品质神仙，
    因此本地限制为：界魂 `sub_type` 必须等于角色 `category`（1 神、2 妖、
    3 人、4 魔、5 佛），且星级一致。
  - 1 个界魂转化为所选神仙的 1 个魂魄；原版每次转化的银两价格来自服务器，
    APK 内不存在，本地规则暂不收费（`local_game/cortege.py:convert`）。
- 界魂来源（灵魂宝箱、五法界魂箱、捕魂达人等）尚未接入本地掉落，因此初始
  存档数量为 0；不影响列表与转化逻辑，获得物品后会立即显示。

## 图鉴与明暗

- `ui/handbookUI.lua` 的四个分类为 `cortege / equip / skill / jp`，标题分别使用
  `handbook/cortege_txt | equip_txt | skill_txt | jp_txt`。
- 原版对未拥有的条目使用 `v2/handbook/unsee.png` 遮罩；本地版按同一语义直接
  将未拥有图标调暗（`setColor(122,122,122)`），已拥有保持原色。
- 拥有判定来自服务端 `view().owned`（`local_game/inventory.py:owned`）：
  - 神仙：`state.heroes`；
  - 装备：包裹中 `i2000..i4999` 且数量 > 0；
  - 法术：包裹中 `s<id>` 且数量 > 0；
  - 精魄：包裹中 `i10xxx` 且数量 > 0。
- 图鉴详情页同样按该判定决定图标明暗；神仙仍可查看未拥有资料。

## 本地边界

- 未接入原服飞升、传承等级转移、精魄打造/镶嵌界面与界魂掉落。
- 神仙详情、阵容、培养共用 `hero_detail.lua`；从图鉴关闭会回到神仙模块，
  从神仙模块关闭才回到首页。
- 所有转化/幻魂走 SQLite 幂等请求，失败不扣材料。

## 实机验证（2026-10-21）

- 底部“神仙”进入伙伴面板，四张卷轴标签、图鉴按钮、行卡图标/名称/星级/数量/操作按钮均按参考图位置显示。
- 神仙页列出本地 16 位已拥有伙伴；魂魄页仅显示 `count > 0` 的灭法国国王（9 个）；精魄页 38 项；五法界魂页 10 项且数量为 0 时图标变暗、按钮显示“无界魂”。
- 点击“图鉴”依次验证神仙、装备、法术、精魄四类：已拥有的牛魔王、东海龙王等图标保持原色，未拥有条目调暗；返回后回到进入图鉴前的五法界魂页。
- 五法界魂数量为 0 时点击“转化”显示“数量不足”提示；临时注入 `i5001 x2` 后，转化面板列出同阵营五星神仙，点击“转化”扣除 1 个界魂并获得东海龙王魂魄 ×1。验证后已恢复原存档。
- 关闭按钮、安卓返回键顺序：图鉴详情 → 图鉴 → 神仙模块 → 首页。
- 自动测试：`python -m unittest discover -s tests -p 'test_*.py'`，105 项通过。

