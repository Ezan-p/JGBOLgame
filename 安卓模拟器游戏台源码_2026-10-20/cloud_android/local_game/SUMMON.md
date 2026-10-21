# 召唤模块逆向与本地规则

## 原版依据

| 项目 | 来源 |
|---|---|
| 界面与交互 | 原包 `lua/ui/summonUI.lua`（更新版索引 1263 中为 70,525 字节） |
| 召唤类型 | `common/common_def.lua`：`cortege_pick_grade = {normal=1, advanced=2, super=3}` |
| 消耗 | `startSummon()`：普通 10、高级 100、超级 300 |
| 每日普通免费上限 | `g_maxNormalSummon = 5` |
| 免费倒计时 | 服务端下发 `normal_time / advanced_time / super_time`，客户端显示 `HH:MM:SS后免费` |
| 高级/超级池 | `csv_config/summon_cortege_set.csv` 的 index 1 / 2，分别为 128 / 93 位神仙 |
| 普通池 | 图鉴可招募角色中 2—4 星，共 120 位 |
| 公告 | `updateSummonNews()`：最多保留 7 条，新公告置顶 |
| 上次召唤 | `getLastSummonType()` 与 `updateLastSummonLabel()`，显示“上次召唤：角色名” |
| 星级区间 | `bkg_bottom1/2/3.png` 分别为 2—4、3—5、4—5 星 |

原客户端不包含抽卡概率表，概率由原服务器计算，APK 中无法还原。本实现不臆测原服概率，使用下列明确标注的本地规则。高级/超级召唤符道具（1006/1007）未接入本地包裹，改为元宝与免费冷却。

## 界面还原

画布为 960 × 540，原版坐标为 1280 × 720，本地统一乘以 0.75。

- 底板沿用神仙/包裹模块的 `intro_bkg` 与 `packageUI/board_edge*` 木框。
- 三张卡使用原版 `v2/summonUI/summon_bkg_1..3.png`，中心 x
  分别为 395.25 / 615.375 / 835.875，y = 351；原图尺寸按 0.75 缩放。
- 召唤按钮使用 `summon_btn_1..3.png`，按下图 `summon_btn.png`。
- 星级条 `bkg_bottom1..3.png` 以卡片底边为锚点。
- 卡下深色消耗板 `bottom_bkg.png`，依据原版公式
  `bottomScale = (cardBottom - boardBottom) * 3 / 4 / 120` 计算高度。
- 免费/倒计时文字位于消耗板下方，颜色沿用原版
  `(255,200,214)`；免费态隐藏金币图标与价格。
- 左侧“召唤喜讯公告”使用 `newsHZ.png`，行背景 `info_bkg.png`
  按原版 `.25` 屏宽比例缩放为 236×84，四条铺满左侧面板，避免下方空白；
  头像取自原版头像图集，最多显示 7 条并可上下拖动。
- 底部“上次召唤：南山大王”取自 `updateLastSummonLabel()` 的
  `x=0.55, y=0.2` 与颜色 `(255,181,115)`。
- 结果页按原版 `getSummonResult()` 还原：全屏 `normal_bkg / advance_bkg / super_bkg`
  背景、居中大立绘、底部属性条、左侧名称图集与星级、右侧仙缘列表，
  以及原版底部“详情 / 继续”按钮。名称图集按原生 100×100 格显示，不再放大，
  避免模糊；参考素材图 `素材图/IMG_3362.JPG`。
  “详情”打开原版式简介/技能/仙缘面板，“继续”关闭结果页。
- 重复神仙时按原版 `extraSpiritLayer` 叠加左侧魂魄面板：`soul_bkg.png`
  居中于 `x=.12, y=.56`，头像 `y=.67`，`get_soul.png` 于 `y=.51`，
  获得数 `y=.44`，共有数 `y=.39`；数值来自 `cortege_quality.csv`。

## 本地规则

- 召唤消耗 `元宝`：10 / 100 / 300。新存档 500 元宝；元宝只用于召唤，
  本地版没有充值入口。
- 免费冷却：普通 10 分钟、高级 2 小时、超级 72 小时。
- 普通召唤每天最多 5 次免费，用完后仍可花 10 元宝继续。
- 本地概率：

  | 类型 | 星级区间 | 概率 |
  |---|---|---|
  | 普通召唤 | 2—4 星 | 2★ 70%，3★ 25%，4★ 5% |
  | 高级召唤 | 3—5 星 | 3★ 70%，4★ 25%，5★ 5% |
  | 超级召唤 | 4—5 星 | 4★ 80%，5★ 20% |

- 重复神仙按原版 `cortege_quality.csv` 转化为神仙魂魄：

  | 品质 | `spirit_convert_count` 重复获得 | `spirit_compose_count` 还魂所需 |
  |---|---|---|
  | 2★ | 4 | 10 |
  | 3★ | 9 | 20 |
  | 4★ | 12 | 30 |
  | 5★ | 15 | 40 |

- 魂魄按角色 ID 永久保存在本地存档；重复召唤时累加，并在结果页左侧
  `soul_bkg` 面板显示“神仙名、魂魄获得 X、共有 X”。
- 本地版暂未开放还魂/飞升消耗入口，魂魄数量与还魂需求已完整保留。
- 新神仙自动加入名册；阵容未满时自动补入，满四人时不挤占现有阵容。
- 所有扣费、冷却、公告与角色写入在同一个 SQLite 事务内完成，
  重复请求编号只结算一次。

## 代码与验证

| 文件 | 作用 |
|---|---|
| `local_game/summon.py` | 原版池、星级区间、费用、冷却、概率、公告与结算 |
| `local_game/summon.lua` | 960 × 540 界面、倒计时、拖动公告、原版结果页与详情面板 |
| `local_game/service.py` | `summon` 操作、元宝、存档迁移与幂等响应 |
| `tests/test_summon.py` | 池覆盖、资源、免费/付费、日限、魂魄转化与累加、公告与持久化 |
| `scripts/build_local_game.py` | 打包 `local_summon.lua`、`local_summon_data.lua` 与 178 项素材 |

验证命令：

```sh
.runtime/venv/bin/python -m unittest tests.test_summon -v
.runtime/venv/bin/python -m unittest discover -s tests -p 'test_*.py'
node --check web/app.js
```
