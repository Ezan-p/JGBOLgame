# 培养模块逆向说明（潜能点 / 蟠桃 / 培养结果）

本模块按原包 `lua/ui/trainingUI.lua`、`lua/common/common_def.lua`、`v2/String.plist` 与
两张原版参考图重建。客户端只负责显示和发请求，随机的培养结果由已经停服的服务器计算；
APK 内没有服务器公式，因此下文把“原版确定值”和“本地重建值”分开标注。

## 界面入口与资源

- 神仙详情底部 `v2/trainingUI/training1.png` 打开本页，关闭后回到进入前的图鉴/阵容详情。
- 原版 `trainingUI.show()` 使用 `introBkg2.png` 左半屏立绘、右侧 `rightBkg.png` 纵向拼接、
  `left_scroll/right_scroll` 卷轴边、四行 `property_bkg/property_up` 成长条。
- 四选一使用 `choose_frame.png` / `choose.png`；底部大按钮为 `training1/2.png`。
- 结果页使用 `data_bkg.png`、`title_bkg.png`、`resultHZ.png`（原文“培养结果”）、
  `accept1/2.png`、`giveup1/2.png` 与 `up/down.png`。
- 所有资源均来自原包，`lineup.py` 会校验 PNG 并在构建本地 APK 时打包。

## 原版确定值

### 四个培养选项

`trainingUI.createStartTrainingInfo()` 固定生成四项，顺序与原图一致：

| 选项 | 蟠桃 | 元宝 | 次数 | 请求字段 |
|---|---:|---:|---:|---|
| 培养 | 5 | 0 | 1 | `train_type=one_count, intensive=false` |
| 培养 10 次 | 50 | 0 | 10 | `train_type=ten_count, intensive=false` |
| 精心培养 | 0 | 1 | 1 | `train_type=one_count, intensive=true` |
| 精心培养 10 次 | 0 | 10 | 10 | `train_type=ten_count, intensive=true` |

`trainingUI.startTraining()` 的校验顺序也是原版确定值：

1. 10 次普通培养要求潜能点至少 10；10 次精心培养要求至少 30。
2. 潜能点为 0 时，10 次培养允许用“两个已培养属性都达到 10/30”代替。
3. 任意一项培养都先检查 5 个蟠桃；10 次检查 50 个。
4. 精心培养不检查蟠桃，只检查元宝 1/10。

对应提示文本来自 `v2/String.plist`：`leftPotential=剩余潜能点: `、`training=培养`、
`tenTimes=10次`、`wellTraining=精心培养`、`peachHZ=蟠桃`、`goldHZ=元宝`、
`noPeach=蟠桃不足`、`noProtential=潜能点不足`、
`cort_training_tip=提示：使用精心培养可以节省大量蟠桃`、
`confirmTraining=培养成功`、`giveupTraining=放弃培养`。

### 潜能点与培养属性字段

`common_def.cortege_property` 中与本模块直接相关的字段：

- `culture_point = 90`：当前剩余潜能点。
- `culture_max_hp_plus = 86`、`culture_wuligongji_plus = 88`、
  `culture_wulifangyu_plus = 89`、`culture_max_magic_plus = 87`：四项已培养值。
- `train_increase_field` / `train_decrease_field` / `train_change_value`：服务器返回的本次
  增加属性、减少属性与点数。
- `level_culture_point = 83`、`evolve_culture_point = 84`、`total_culture_point = 85`：
  等级/飞升/合计潜能点。

结果页显示规则：左侧为当前 `属性 (已培养值)`，中间为本次 `+n/-n`，右侧为
`属性+n (已培养值+n)`；增加为绿色上箭头，减少为红色下箭头，0 为灰色。
`createTrainResult()` 只接受一个增加属性与一个减少属性，因此一次培养（含 10 次）
最终汇总到一个主属性和一个来源属性。

### 参考图数值

两张原版参考图（`素材图/IMG_3361.JPG`、`IMG_3375.PNG`、`IMG_3327.JPG`）给出：

- 15 级、四星铁扇公主：剩余潜能点 146，四项培养值均为 0。
- 84 级、五星菩提祖师：剩余潜能点 179，蟠桃 169，元宝 0。
- 95 级孙悟空：剩余潜能点 0，已培养值合计 `277+970+123+0=1370`；
  一次培养 10 次结果为生命 `-40`、攻击 `+40`，即潜能点耗尽后从其他属性转移。
- 单次普通培养参考结果：法力 `264(0) → 268(4)`，消耗 4 点潜能，蟠桃剩 6。

## 本地重建值

服务器随机分布不在 APK 内。本地按上表的确定边界重建：

- 普通培养每次随机 `1..5` 点；精心培养每次随机 `3/6/9/12/15` 点（普通结果 ×3）。
- 1 次培养 = 1 次随机；10 次培养 = 10 次随机求和，并汇总到一个随机主属性。
- 潜能点足够时先扣潜能点；不足时从另一项已培养属性转移，转移总值守恒。
  这与 95 级参考图的 `-40 / +40` 以及客户端的 `train_decrease_field` 语义一致。
- 10 次培养的最小值因此正好是普通 10、精心 30；精心每次为普通 3 倍点数，
  与 `checkTenTimeTraining()` 的 10/30 门槛完全吻合。
- 培养成本在请求时扣除；接受前只保存待确认结果，放弃不会返还蟠桃/元宝，
  但不会改变潜能点和四项培养值。
- 所有神仙详情/图鉴/阵容入口都已改为打开本页，不再调用旧的银两 `upgrade` 事务；
  该事务仅为历史存档与自动测试兼容保留。

潜能点池没有出现在任何 APK 配置表中。`cortege_evolve_config.csv` 是飞升每级增加的
潜能点（`feishengUI` 读取 `evolve_level+1`），不是等级潜能表。本地用两张参考图建立
线性插值，并集中在 `local_game/training.py:potential_total()`：

```text
potential(level) = max(30, 146 + floor((level - 15) * 153 / 10))
```

校验点：15 级 = 146、95 级 = 1370；84 级 = 1201。若后续取得服务器抓包，只需替换
这一个函数。现有存档首次进入时给每位已拥有神仙补发该潜能点，并向已领取包裹的玩家
一次性补发 169 个蟠桃；新手包裹也固定包含 169 个蟠桃。

## 本地存档与请求

状态写入 `state["training"][神仙ID]`：

```json
{
  "bonus": {"hp": 0, "attack": 0, "defense": 0, "magic": 4},
  "potential": 26,
  "level": 2,
  "pending": {
    "kind": 2, "rolls": 10, "value": 17,
    "increase": "defense", "potential_used": 17,
    "decrease": "culture_point", "decrease_value": 0,
    "cost": {"peaches": 50, "gold": 0}
  }
}
```

请求均为幂等 SQLite 事务：

- `train {hero, kind}`：校验成本与潜能，扣除蟠桃/元宝并生成 `pending`。
- `train_accept {hero}`：把 `pending` 写入四项培养值并扣潜能/来源属性。
- `train_giveup {hero}`：丢弃 `pending`，不改变属性。

`view()` 的每位神仙会附带 `culture_point`、`hp_plus/attack_plus/defense_plus/magic_plus`
和 `train_pending`；四项培养值在装备、法术、仙缘、助阵百分比全部计算后作为固定值加入
最终属性，因此 1 点潜能严格等于 1 点最终属性，符合 `createTrainResult()` 的显示方式。

## 验证

`python -m unittest discover -s tests -p 'test_*.py'`：113 项通过。新增 8 项培养测试覆盖
潜能校验点、169 蟠桃、单次/10 次成本、精心培养元宝、潜能耗尽转移、放弃不返还、
培养值进入阵容最终属性。实机验证见 `.runtime/local_game/` 截图与 `game*.png`。
