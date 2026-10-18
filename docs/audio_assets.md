# 音频资源规范

本规范仅适用于 `D:/godot/demo/demo2`（Lunar）。开发约束见 [AGENTS.md](../AGENTS.md)，运行结构见 [架构说明](architecture.md)，完成状态见 [项目状态](project_status.md)，项目入口见 [README](../README.md)。图片和字体继续维护在美术规范，音频使用独立目录及清单。

## 目录与来源

| 路径 | 职责 |
| --- | --- |
| `assets/audio/bgm/` | 背景音乐原 WAV 与 `.import` 设置 |
| `assets/audio/ambience/` | 室内、室外白噪音与 CG 大雨 |
| `assets/audio/sfx/` | 脚步、开门、投入、显词、水滴、uplifter 和按钮音效 |
| `assets/audio/manifest.json` | 稳定 ID、来源、项目路径、格式、帧数、循环范围与 SHA-256 |
| `scripts/audio/bgm_controller.gd` | 音乐上下文、环境层、剧情音频时序、音效和会话暂停 |
| `scripts/audio/audio_channel.gd` | 双播放器交叉淡化、断点、暂停及单次播放完成信号 |
| `default_bus_layout.tres`、`scripts/ui/game_settings.gd` | Master/BGM/SFX 总线、设置偏好的加载与应用 |
| `resources/audio/gameplay_bgm.tres` | 历史 Hide/SEEK 双 clip 资源，当前运行未引用 |

2026-10-19 按用户 `配乐都放在哪呢.docx` 交付 10-18 提供的 `配乐.rar` 与 `音效.rar` 内 22 份 WAV，均按原字节复制，运行仅使用项目内 `res://` 路径。微信目录只记录来源。清单保存每份原文件名、归档条目、格式与 SHA-256；音频不写入美术清单。新增说明覆盖此前 Hide/SEEK 分配与主菜单静音约定。

下表项目文件均相对 `assets/audio/`。9 首循环配乐、3 层循环环境声和 2 种循环脚步合计 14 份循环，另 8 份单次播放。

| 原文件 | 项目文件 | 循环 | 用途 |
| --- | --- | --- | --- |
| 主界面+解密.wav | `bgm/exploration.wav` | 是 | 主菜单、自由探索及普通查看/对白 |
| 水池.wav | `bgm/puzzle.wav` | 是 | 四处谜题的前置、操作、微剧情及抵抗对白 |
| 相识.wav | `bgm/acquaintance.wav` | 是 | 情节块 1 / `cg_01` |
| 矛盾.wav | `bgm/conflict.wav` | 是 | 情节块 2 前段 |
| 这是梦吗.wav | `bgm/dream.wav` | 是 | 情节块 2 后段、情节块 4 Luna 导向 |
| 宁静的日常.wav | `bgm/daily.wav` | 是 | 情节块 3，包含指定截断与续播 |
| 月球坠落.wav | `bgm/moon_fall.wav` | 是 | 情节块 4 真实导向及第五幕真回忆前段 |
| 引子.wav | `bgm/intro.wav` | 否 | 第五幕真回忆指定字幕后，强制完整播放一次 |
| lunar（fake）.wav | `bgm/lunar_fake.wav` | 是 | 假结局正文与终局 |
| lunar（true）.wav | `bgm/lunar_true.wav` | 是 | 真结局最终正文与终局 |
| 大雨.wav | `ambience/rain.wav` | 是 | 情节块 2 全段独立雨声层 |
| 室内白噪音.wav | `ambience/indoor.wav` | 是 | 室内探索、谜题与 CG 的持续环境层 |
| 室外白噪音.wav | `ambience/outdoor.wav` | 是 | 小院探索、谜题与 CG 的持续环境层 |
| 室内走路声.wav | `sfx/steps_indoor.wav` | 是 | 室内角色实际移动 |
| 室外走路声.wav | `sfx/steps_outdoor.wav` | 是 | 小院角色实际移动 |
| uplifter.wav | `sfx/uplifter.wav` | 否 | 情节块 3 指定景象转换页 |
| 开门.wav | `sfx/door_open.wav` | 否 | 成功通过房门或打开储物间门，楼梯不播放 |
| 投入水中.wav | `sfx/water_drop_in.wav` | 否 | 月相碎片成功投入目标 |
| 涌现声.wav | `sfx/words_emerge.wav` | 否 | 对应水面词出现，可与投入声叠播 |
| 水滴.wav | `sfx/water_drip.wav` | 否 | 情节块 3 uplifter 结束并切断音乐时 |
| 点击.wav | `sfx/click.wav` | 否 | 菜单图片按钮按下 |
| 选中.wav | `sfx/select.wav` | 否 | 菜单图片按钮悬停或获得焦点 |

原 `Hide.wav`、`SEEK.wav` 及 `gameplay_bgm.tres` 保留供历史追溯；清单标记 `legacy_unused/runtime_used=false`，当前控制器未加载它们。两份旧原文件各为 42,287,278 字节、48 kHz 双声道 PCM32、5,285,648 帧（约 110.1176667 秒）；旧 30 ms 双 clip 切换规则不再约束当前播放。

## 导入与循环

原 WAV 的字节、格式与采样数据保留，项目 `.gitattributes` 将 `*.wav` 标记为 `binary`。各文件的格式和采样帧数以音频清单为准，`.import` 随项目交付。

| 导入字段 | 当前值与含义 |
| --- | --- |
| `compress/mode` | `0`，无压缩运行 PCM16 |
| `edit/trim`、`edit/normalize` | 均为 `false`，不裁剪或归一化 |
| `force/8_bit`、`force/mono`、`force/max_rate` | 均为 `false`，不强制 8-bit、单声道或重采样 |
| 循环文件 `edit/loop_mode` | `2`，导入器 Forward；运行时 `AudioStreamWAV.loop_mode=1` |
| 循环文件 `edit/loop_begin/end` | `0 / -1`，首帧至全曲末尾，末帧索引见清单 |
| 单次文件 `edit/loop_mode` | `0`；引子、uplifter 和六种短音效不循环 |

探索曲与水池曲为配套版本，切换时保留共同播放秒数；替换这两份时继续核对采样率、帧长、音乐起点和循环范围。其他音乐按剧情明确切换，通常从 0 开始。原字节与静态参数一致不代表循环、乐句衔接或混音听感已验收。

## 播放与剧情时序

游戏常驻 `BGM` 节点挂 `bgm_controller.gd`。Music、Ambience、Rain 各用 `audio_channel.gd` 的两个 AudioStreamPlayer 交叉淡化，另有独立脚步、uplifter 与 8 个轮换短音效声部。默认切换时长为 0.75 秒，可在 0.5–1 秒范围调整，按线性振幅插值后换算为分贝，避免直接插值分贝造成交接中点的明显音量下凹；白噪音与雨声在循环末尾提前 0.75 秒启动另一声部，实现首尾交叉淡化；情节块 3 的指定截断直接停止音乐。

| 上下文或时机 | 已接入行为 |
| --- | --- |
| 主菜单及主菜单设置 | 菜单外壳的 `MenuAudio` 播放“主界面+解密”，不启用环境白噪音 |
| 新游戏 | 菜单曲淡出，加载失败恢复菜单配乐；开场未增加配乐或环境声，卧室淡入完成后启动新会话音乐与室内白噪音 |
| 自由探索、普通收集/查看/对白、装置选择 | “主界面+解密”；普通查看不重启同一曲目，地点切换只更新室内外环境层 |
| 四处谜题的前置、选碎片、填词、微剧情及前两次抵抗 | “水池”；微剧情/抵抗返回谜题保持，退出及原三处后续普通对白恢复探索曲 |
| `cg_01` | 正式剧情开始播放“相识” |
| `cg_02` | “矛盾”与独立“大雨”同时开始；零起 index 27 黑屏页淡出“矛盾”，index 28“小泠：好了，别再说了。”后切“这是梦吗”；雨声贯穿全段，离开 CG 后淡出 |
| `cg_03` | 开始“宁静的日常”；index 19“忽然，眼前的景象变了。”播放 uplifter，音效结束时保存音乐位置并立即截断，再播放水滴；index 22“小泠：喂，先去洗手。”从截断位置淡入，快速翻页时先等待 uplifter 完成 |
| `cg_04` Luna / 真实导向 | 分别播放“这是梦吗” / “月球坠落” |
| `cg_05_true` | 延续同一首“月球坠落”；index 7“你的最后一个想法是，要是能再和小泠看一次月亮就好了。”开始不循环的“引子” |
| 引子锁定期间 | 完成引子并离开真回忆正文后才恢复最新场景所需曲目；提前退出保留播放，曲终仍停留正文时保持音乐停止；期间继续记录最新上下文；快速重进真实分支的新一轮引子排队，旧一轮完整播完后再播 |
| `cg_05_false/end1`、`end2` | 分别播放 lunar（fake）、lunar（true），终局保持对应配乐 |
| 暂停、暂停来源设置、返回主菜单 | 冻结全部游戏音乐、环境声、雨声、脚步、短音效及淡化时间；继续恢复同一位置。返回主菜单由菜单外壳另播菜单曲 |

`memory_puzzle.gd` 按实例深拷贝的页数据触发 `audio_cue`；GameUI 转发谜题信号并为第五幕真回忆 index 7 添加引子 cue，`main.gd` 统一调用控制器。引子完成和离开真回忆分别记录，避免快速翻页或提前 Esc 截断。旧引子未结束时再次触发真实回忆，将新一轮引子排队并独立记录是否已离开正文，旧一轮结束后再播放新一轮。地点环境声在探索、谜题和 CG 中持续，情节块 2 大雨独立叠加；门声仅成功操作时触发，实际位移决定脚步启停，模态锁定后停止脚步。投入与显词通过独立声部叠播。菜单图片按钮通过 `ui_audio` 组路由点击与选中声，继续和暂停期间仍可操作菜单。

磁盘存档保存当前音乐、白噪音与雨声的播放位置，以及 CG3 截断／uplifter 状态、真回忆引子锁定和排队状态。读档先重建 UI，再恢复音频检查点，加载淡出完成后继续；短音效与脚步不重放。成功动画收敛到正式 CG 开头时通过 `resume_audio_context` 同步切曲，普通页仍保留原音频断点。相关接口位于两个音频脚本的 `export_save_data()/import_save_data()`，本批仅完成语法与静态核对，未试听。

## 设置与音量总线

Music 输出至 `BGM`，基准 `-6 dB`；环境白噪音、雨声、脚步、uplifter、门声、投入/显词及按钮声全部输出至 `SFX`。默认白噪音 `-18 dB`、雨声 `-14 dB`、脚步 `-16 dB`、uplifter `-6 dB`、短音效 `-8 dB`，用于初始混音，实际听感待用户试听。BGM、SFX 均汇入 Master。

菜单外壳创建 `game_settings.gd` 服务，音效音量、背景音乐和亮度为 `0–100` 整数，默认 `100`。音量使用 `数值 / 100` 线性总线增益，100 为 `0 dB` 总线增益，0 静音。拖动只调总线，不重建播放或恢复已暂停会话。

偏好独立写入 `user://settings.cfg` 的 `audio/sfx_volume`、`audio/music_volume` 和 `display/brightness`。加载接受有限整数或浮点数，四舍五入并限制 0–100，其余值恢复默认。设置跨新游戏保留；滑杆松开、键盘/滚轮调节、返回、重置和退出时保存，拖动不逐像素写盘。亮度由全屏遮罩按 `(100 - brightness) × 0.006` 应用，最低保留约 40% 显示亮度。

## 替换与验收

1. 使用用户确认的音频，原字节归档，核对 SHA-256 并更新音频清单；完整交付 WAV、`.import` 和脚本。
2. 区分循环与单次素材，维护指定页索引、完成信号、断点续播、引子锁定及暂停/重入行为。
3. 变更触发或播放语义时同步控制器、菜单/玩家/门户/UI/谜题挂点和相关文档。
4. 用户试听需覆盖室内外环境层、配乐与音效平衡、切换及循环边界、CG2 雨声、CG3 截断续播、引子完整播放、暂停恢复和 BGM/SFX 滑杆。

2026-10-19 本轮已按用户说明核对资源清单、循环分配、引用和音频挂点。Godot 4.7.2 `--check-only` 对 `audio_channel`、`bgm_controller`、`main_menu`、`menu_hover_button`、`main`、`game_ui`、`memory_puzzle`、`player`、`portal`、`storage_room_door` 共 10 个脚本解析，失败 0。资产静态审计核对 22 份 active 与 2 份 legacy 的 SHA、导入参数及 22 条运行路径引用，错误 0，报告为 `verification/audio_20261018/static_audit.json`。Godot `--headless --editor --import` 资源导入正常退出 0，`verification/audio_20261018/import.log` 无 ERROR、SCRIPT ERROR 或 Parse Error。循环淡化、引子队列和菜单加载失败恢复修订后，`audio_channel`、`bgm_controller`、`main_menu` 最终再次 `--check-only`，失败 0。未启动游戏、自动化场景或进行音频试听。此前 94 项图形回归早于本轮音频接入，未覆盖新增音频时序与听感。
