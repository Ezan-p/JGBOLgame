# 金箍棒安卓游戏台

当前默认使用 **Android 6.0 / ARM32 本地可玩版**，无需联想账号，角色与进度保存在本机。已依据原客户端布局与美术资源还原仙山首页，并接通角色培养、阵容、招募、召唤和十个本地 PvE 关卡；使用独立本地规则，并非原官服完整复刻。

“召唤”已按原版 `ui/summonUI.lua` 还原三栏卡片、左侧“召唤喜讯公告”、星级区间、免费倒计时、上次召唤与全屏结果；普通/高级/超级池分别覆盖 120/128/93 位神仙，消耗 10/100/300 元宝，普通每日 5 次免费。结果页采用原版 `getSummonResult()` 的居中立绘、属性条、名称/星级、仙缘与“详情/继续”结构；重复神仙按原版 `cortege_quality.csv` 获得 4/9/12/15 魂魄，左侧显示本次获得与共有数量。原服概率未包含在 APK 中，本地概率与冷却口径见 [召唤逆向与本地规则](local_game/SUMMON.md)。

招募现已覆盖原版图鉴全部 **166 位神仙**，支持品质筛选和双向翻页。原文介绍、属性成长、技能、仙缘、转生及剧情详见 [神仙角色介绍表](outputs/characters-20261020/神仙角色介绍表.xlsx)，提取口径见 [角色资料说明](local_game/README.md#神仙角色介绍表与提取依据)。

底部“神仙”已还原为原版 `ui/lineupUI.lua` 的伙伴面板：木纹边框、四张卷轴分类（神仙、魂魄、精魄、五法界魂）和下方“图鉴”按钮。图鉴使用原版 `handbookUI.lua` 的四类（神仙、装备、法术、精魄）、六列三行头像及纵向滚动，已拥有条目点亮、未拥有条目变暗。神仙与魂魄可打开详情，并可培养或幻魂。装备、法术与精魄分类提供原版资料查阅，成长与装备玩法仍在包裹中。详见 [神仙模块逆向说明](local_game/CORTEGE.md)。

本地版的运行、构建、备份及返回渠道版方法见 [本地版说明](local_game/README.md)。原联想渠道版 3.75（`com.sygame.jingubang.lenovo`）仍独立安装，数据保留。

浏览器入口：<http://127.0.0.1:8766>。双击本目录的 `启动游戏台.command` 启动，或使用下方命令。

“旅途”已还原为原版连续大地图与可横向拖动的小关卡面板，包含67个大关、597个小关资料与奖励预览。已有十个本地关卡仍可挑战，其余为资料预览；解析依据、参考图对应关系及玩法边界见 [旅途逆向说明](local_game/JOURNEY.md)。

## 当前运行方案

| 项目 | 配置 |
|---|---|
| 系统镜像 | Google 官方 Android 6.0 / API 23 / armeabi-v7a r06 |
| Android ABI | `armeabi-v7a,armeabi`，包含游戏需要的 32 位 ARM |
| 模拟器 | Android Emulator 37.2.12 内附的 ARM32 引擎，本地独立副本 |
| Apple Silicon 执行方式 | 原生 arm64 macOS 引擎，软件仿真 ARM32 CPU（`-accel off`），无需 Rosetta |
| 图形 | Host GPU 渲染，960×540 |
| 资源 | 1 个虚拟 CPU、1536 MB 内存、2 GB 安卓数据分区 |
| 独立设备 | `jingubang32native` / `emulator-5560` |
| 端口 | 网页 8766、gRPC 8560、安卓控制/ADB 5560/5561 |

已更换为真实的 ARM32 Android 系统，并配套 ARM32 CPU 引擎。软件仿真启动和加载较慢，首次初始化可能需要数分钟；网页显示画面后，仍要等待“32 位安卓环境已就绪”再启动游戏。网页传输 FPS 不代表游戏渲染 FPS。

原来的 Android 11 ARM64 AVD `jingubang` 保留在 `.runtime/avd/`，原配置备份在 `.runtime/compat32/previous-game.json`。Noctilucent 游戏台的 8765/8554/5554 端口与数据没有更改。

原渠道版的镜像兼容验证记录：系统完成启动、APK 安装成功、渠道入口进入 `xiyoujilua` 主 Activity、Cocos2d-x 加载资源并显示《金箍棒 online》画面。首次加载曾显示网络重连，随后已进入选区页面，显示“巅峰三界-39服【新服】”和“进入游戏”按钮。点击进入后，游戏要求下载约 137.77 MB 资源；已确认更新并实测开始下载，验证时显示 1% / 242 KB/s。Android 通用网络连通性已实测通过。日志仍有联想渠道 `gr.lenovomm.com` 域名解析失败记录；尚未验证账号登录或战斗。游戏台不包含原游戏服务器。

## 日常命令

以下命令在本 README 所在目录执行：

```sh
cd '/Users/ezan/Desktop/vibeCoidng/JGBolgame/安卓模拟器游戏台源码_2026-10-20/cloud_android'
python3 manage.py start
python3 manage.py doctor
python3 manage.py launch
```

- `start`：启动当前配置的安卓设备、网页及本地游戏服务（本地模式下为 8770 端口）；不会重复创建或清空数据。
- `doctor` / `status`：报告 Android 版本、实际 ABI、开机状态和端口；未就绪或不兼容返回非零退出码。
- `launch`：启动已安装的游戏。也可以在网页点击“启动游戏”。
- `restart-web`：只重启网页服务，保留安卓进程。
- `stop`：停止本项目的模拟器、网页和本地游戏服务，不卸载游戏，不关闭外部 ADB 设备。

网页中点击“连接画面”。Esc 返回，Enter 确认；中文请使用设备内输入法。声音需手动点击“开启声音”。关闭浏览器不会关闭模拟器，也不保证游戏进度已保存。

初次安装或有意更新测试 APK 时才执行：

```sh
python3 manage.py install
```

若要安装原始渠道 APK，先按本地版说明切回渠道配置，再保留原签名安装：

```sh
python3 manage.py install --apk '/实际路径/原始游戏.apk'
```

## 配置及重建

`game.json` 中的 `runtime_profile` 选择成套引擎和镜像；参数定义在 `runtime_profiles.py`。当前为：

```json
{
  "title": "金箍棒",
  "game_root": "../..",
  "package": "com.sygame.jingubang.localg",
  "activity": "com.sygame.jingubang.lenovo.xiyoujilua",
  "local_game": true,
  "avd_name": "jingubang32native",
  "runtime_profile": "arm32-native",
  "mode": "emulator",
  "serial": "emulator-5560",
  "console_port": 5560,
  "grpc_port": 8560,
  "web_port": 8766,
  "adb_path": ".runtime/sdk/platform-tools/adb"
}
```

相对路径以 `cloud_android` 为基准。`game_root: ../..` 指向当前游戏解包目录。改变运行方案前先 `stop`；网页小改动使用 `restart-web`。

本机运行依赖已部署。需要在相同 macOS 环境重新部署 32 位引擎和镜像时，停止 ARM32 模拟器后执行：

```sh
python3 scripts/setup_compat32.py
```

脚本下载固定官方 ARM32 镜像并核验 SHA-1，从 SDK 复制独立 ARM32 引擎，补充 SDK 动态库路径并进行本地 ad-hoc 签名，以赋予该副本 JIT 所需权限。无需修改系统安全设置，也不会替换 SDK 原始引擎。镜像校验记录位于 `.runtime/compat32/receipt.json`，引擎摘要及签名设置位于 `native-engine/`。脚本保留已有安卓数据。

该方案在本机 Apple M4 / Emulator 37.2.12 上验证，直接调用 SDK 内部引擎，属于本地兼容适配；升级 SDK 后应重新验证。之前测试的 Intel / Rosetta 路线未完成开机，保留为实验配置 `arm32-software`，当前不使用。

从只有源码的副本部署，还需要 ADB、Android build-tools 35、Java 17 和 Python 依赖。原 `download_runtime.py` / `setup_runtime.py` 可以准备这些工具，但同时会下载旧 ARM64 镜像。随后再执行 `setup_compat32.py`，并建立 Python 环境：

```sh
python3 -m venv .runtime/venv
.runtime/venv/bin/python -m pip install -r requirements.lock.txt
python3 scripts/setup_compat32.py
python3 scripts/prepare_apk.py
python3 scripts/build_local_game.py
python3 manage.py start
```

`prepare_avd.py` 按当前 `runtime_profile` 创建 AVD，检测到已有配置时拒绝覆盖；不要为已有设备重复运行。

本地版构建使用 `python3 scripts/build_local_game.py`，生成 `.runtime/local_game/jingubang-local.apk`；`manage.py install` 按当前模式选择对应 APK。

`prepare_apk.py` 只读取 Manifest、DEX、resources.arsc、assets、lib、res，排除旧签名和游戏台目录，生成 `.runtime/apk/jingubang-test.apk`。原游戏文件不修改。签名验证、摘要记录在 `.runtime/apk/receipt.json`；`--unsigned-only` 生成的 ZIP 仅用于检查，不能直接安装。

测试重签名可能影响渠道签名校验。安装发生签名冲突时不会自动卸载已有游戏；优先使用原始 APK 或独立测试设备。

## 外部设备方式

仍支持 `mode: adb`，通过 `serial` 明确选择外部设备，并将 `adb_path` 指向可用的 adb。设备必须提供 `armeabi`，并授权 USB 调试。这种方式不启动本地 AVD，可使用更快的兼容安卓环境。

ADB 模式通过截图显示画面，上限 5 FPS。仅支持单指点击、长按及抬起后执行直线滑动，不支持实时拖动、多点手势或浏览器音频；声音从设备播放。`JGB_MODE`、`JGB_SERIAL`、`JGB_ADB_PATH` 可临时覆盖三个字段，双击启动长期使用建议修改 `game.json`。

## 验证与排查

```sh
.runtime/venv/bin/python -m unittest discover -s tests -p 'test_*.py' -v
node --check web/app.js
.runtime/venv/bin/python scripts/check_browser.py
```

浏览器检查需要 Chrome 和已启动的网页服务，生成 `.runtime/browser-check.json` / `.png` 和手机布局截图。当前 115 项自动测试通过，覆盖本地存档、重复结算保护、十关推进、全部角色招募、召唤池与免费/付费结算、原版魂魄转化、幻魂与五法界魂转化、图鉴数据与素材。此前实机完成战斗、培养与招募，正式安装包及本地服务重启后进度保留；浏览器画面传输正常，无 JavaScript 错误、无移动端横向溢出。本地版初始验收记录在 `.runtime/local_game/validation.json`，神仙模块验收在 `.runtime/local_game/handbook-validation/`，原渠道版的镜像验证截图和日志另存于 `.runtime/compat32/game-screen.png`、`game-logcat.txt`。这些验证不代表原服功能已完整恢复。原 Noctilucent MOD 文件保留作历史资料，未接入金箍棒网页。

- 开机慢：ARM32 使用软件仿真；查看 `doctor` 的 `booted`，不要删除数据或反复重装 APK。
- 引擎或镜像缺失：运行 `setup_compat32.py`，不要只改 `abi.type`。
- 架构不兼容：确认配置为 `arm32-native`、AVD 为 `jingubang32native`，且 `doctor` 实测含 `armeabi`。
- Activity 不存在：确认游戏已安装、包名和配置一致。
- 画面服务失败：查看 `.runtime/logs/emulator.log`、`gateway.log`；本次原生引擎首轮日志另见 `.runtime/compat32/native-boot.log`。
- 登录、服务器列表或更新失败：另行检查原游戏服务，不能据此判断镜像仍是 64 位。

如需回退到旧 Android 11 环境，先 `python3 manage.py stop`，将 `.runtime/compat32/previous-game.json` 复制回 `game.json`，再 `start`。旧环境不支持本游戏的 ARM32 原生库，但保留作为回退用途。此操作不删除新 ARM32 AVD。

所有服务只监听本机；不要公开 ADB、gRPC 或网页端口。远程访问可使用有权限的 SSH 隧道。`.runtime` 包含系统镜像、测试证书、日志及安卓数据，不应随源码分享。
