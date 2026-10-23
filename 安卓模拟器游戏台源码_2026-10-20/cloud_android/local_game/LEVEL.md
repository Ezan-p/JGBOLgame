# 神仙等级 / 经验条 / 主角等级限制（逆向说明）

本篇记录本地版「神仙等级」的逆向依据与实现，覆盖三件事：神仙的等级与经验、
不同等级的经验条数值、主角（行者）等级对神仙等级的限制。

## 一、原版依据

### 1. 等级经验表 `cortege_experience.csv`

`ui/data.lua:getCharacterExperienceCSVConfig`：

```lua
local char_exp_tab_csv = d_ms.d_csv.open("csv_config/cortege_experience.csv")
char_exp_tab[quality][level] = value
```

- 三列：`quality, level, experience`。
- 1～5 档品质各有 1～600 级，共 3000 行。
- `experience` 是**从该级升到下一级**所需的经验，即该级显示的 `next_exp`。
  - 例：1★ `level 1 = 120`、`level 2 = 250`；5★ `level 1 = 132`、`level 2 = 275`。
- 本地版在 `assets.catalog()` 里读入并作为 `exp_table` 下发给 `service.py`。

### 2. 等级属性公式

`ui/inheritUI.lua:1133-1141` 与 `ui/expbookUI.lua:setCharacterPropertis` 一致：

```lua
health = csvInfo.hp       + csvInfo.hpOffset       * (level - 1)
damage = csvInfo.damage   + csvInfo.damageOffset   * (level - 1)
defence = csvInfo.defence + csvInfo.defenceOffset  * (level - 1)
mana    = csvInfo.magic   + csvInfo.manaOffset     * (level - 1)
```

即 **基础属性 + 基础成长 × (等级−1)**，四个成长值来自 `cortege_base_0.csv` 的
`base_*_plus`，是英雄模板固定值，玩家无法练高（见《成长潜力与培养值相关》）。
本地版据此替换了早期简化规则 `基础属性 × (1 + 0.14 × (等级−1))`。

### 3. 主角等级限制神仙等级 `lvLimit`

`ui/expbookUI.lua:g_self.lvLimit`：

```lua
lvLimit = {
  { lv = 0,   rate = 1   },  -- 低于 主角等级*0      （全阶段基准）
  { lv = 2.5, rate = 0.2 },  -- 主角等级*2.5 起，经验收益降为 20%
  { lv = 3,   rate = 0   },  -- 主角等级*3   起，不再获得经验（硬上限）
}
```

`getExpResult` / `filterSelectedList` 把 `limit.level = floor(主角等级 * limit.lv)`，
逐级判断所处档位并乘上 `rate`。因此：

- 神仙等级 < `floor(主角等级 × 2.5)`：经验全额（100%）。
- `floor(主角等级 × 2.5)` ≤ 神仙等级 < `floor(主角等级 × 3)`：经验仅 20%。
- 神仙等级 ≥ `floor(主角等级 × 3)`：不再获得经验，同时受品质上限 600 级约束。

### 4. 阵容面板的经验条

`ui/charPositionUI.lua`（阵容）与 `ui/formationUI.lua`（详情）都采用同一套：

- `v2/charPositionUI/level_bkg.png` 放等级数字；
- `v2/CharaterUI/expbar1.png` 为底条，`v2/CharaterUI/expbar2.png` 为进度；
- 进度按 `cur_exp / next_exp` 裁切 `expbar2` 的纹理矩形，向左锚定；
- 条内文字为 `cur_exp .. "/" .. next_exp`。

## 二、本地实现（经验书严格按原版）

- `local_game/assets.py`：`catalog()` 提供 `exp_table`（quality → level → experience）。
- `local_game/inventory.py`：`experience_plus > 0` 且 `sub_type ∈ {99,100}`
  （仙佛密卷 / 培元丹）标记为 `action="experience"`；药灵丹（101，炼药）保持
  `reference`。神仙经验书不再加行者经验。
- `local_game/service.py`：
  - `next_exp(quality, level)`：读 `cortege_experience.csv`，得到该级升到下一级所需经验。
  - `role_level(state)`：主角等级（2026-10-23 起按原版 `role_level_config.upgrade_exp` 逐级计算），用于 `lvLimit` 分档。旧存档转换及旅途经验推测见 [JOURNEY.md](JOURNEY.md)。
  - `level_cap(state, quality)`：`min(floor(主角*3), 品质经验表最高级)`。
  - `apply_hero_exp()`：完整复刻 `expbookUI.getExpResult` 的
    `rate 1 / 0.2 / 0`、逐级进位、经验不丢失（仅在硬上限处浪费）。
  - `use_exp_book {hero, items:[{uid,count}]}`：校验拥有/数量 → 扣书 → 结算 →
    返回“提升至 N 级 / 当前 x/y / 浪费 N”提示。
  - `hero()`：`cur_exp` 从 `state["hero_exp"]` 读取，`next_exp` 由经验表计算；
    按 `基础属性 + 基础成长 × (等级−1)` 计算四维。
- `local_game/exp_book.lua`：严格按 `ui/expbookUI.lua` 布局重建，原版 1280×720
  坐标统一 ×0.75 映射到本地 960×540：
  - `v2/expbookUI/bkg.png` 全屏底板；左侧人物卡为品质光
    （`inheritUI/three|four|five_star.jpg`）+ 立绘（390×326 等比缩放）+ 星级
    （`introUI/stars.png`）+ 竖排名 + 四维（`trainingUI/stats_bkg.png`）+
    经验条（`expbookUI/exp_bkg.png` + `exp.png` + `vip/<数字>.png`）。
  - 右侧为逐本卷轴列表（`expbookUI/item_bkg.png`，图标 15% 宽、名称 166/685、
    等级 186/685、经验 280/685、勾选框 85%），用 `CCScrollView` 裁剪滚动。
  - 底部 `expbookUI/ensure1.png`（使用）、`buttons/choose_all1.png`（全选）、
    右上 `introUI/close1.png`；左下显示实际获得经验与
    `Lv1 → Lv2`（`expbookUI/arrow.png`）。
  - 点击左侧人物卡打开 `v2/common/frame3.png` 神仙选择层（4×2 头像格、分页、
    `buttons/ensure1.png` 确认），只列出 `level < floor(主角*3)` 的神仙。
  - 经验会浪费时弹出 `v2/rechargeUI/tip.png` 确认框：
    `expbook_tip1/2/3`（消耗仙佛密卷经验 / 实际获得经验 / 是否继续）。
  - `local_game/inventory.lua`：包裹“使用”经验书 → 打开该面板；draw/touch/back/
    afterUpdate/close 全部接管。
- `local_game/lineup.lua`、`local_game/hero_detail.lua`、`local_game/training.lua`、
  `local_game/cheer.lua`：经验条统一为原版样式——等级数字在左，`expbar1` 底条 +
  `expbar2` 进度（按 `cur_exp/next_exp` 裁切、向左锚定），条内文字为
  `cur_exp/next_exp`；经验书升级后自动填充。

## 三、本地边界

- 主角等级沿用本地 `1 + 累计修为 // 200`；原版 `role_level_config.upgrade_exp`
  逐级表尚未接入（后续可替换 `role_level`）。
- 战斗 / 扫荡的神仙经验（`rewards.cor_exp`）由服务端决定，本地暂不发放；
  本轮只接入经验书（仙佛密卷 / 培元丹）。
- `apply_hero_exp` 的 20% 档会产生小数，存档按 `floor` 取整；原版服务端同样只显示整数。
- 仙佛密卷 / 培元丹的经验值严格取自 `item_base.experience_plus`；药灵丹（101）
  属于炼药系统，不参与神仙经验。
- 本地仍保留银两「升级」事务（`service.upgrade`）作为离线便利入口，
  与经验制的 600 级上限是两套不同规则。
