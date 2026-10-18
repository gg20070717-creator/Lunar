# demo2 架构与扩展指南

## 文档职责

本文说明 Lunar 在 `D:/godot/demo/demo2` 内的运行结构、模块职责、接口及扩展方式。静态核对日期：2026-10-18，依据当前 `.gd`、`.tscn`、`.tres` 与项目配置整理。四处谜题共 32 条有序路由，阶段四以句型 3“【A】从【B】中涌现”接入五碎片、18 条微剧情与两条正式分支；电影票提供镜面，连续三次反向填写触发真实导向。完整 `cg_04` 后同黑屏衔接第五幕，真回忆后进入储物间与装置选择，最终解锁假结局 `end1` 或真结局 `end2`。原三处组合、后续对白、10.15 素材及音乐切换参数保留。主菜单与暂停共用独立偏好的设置页，剧情及收集/物件查看共用纸张对白框；返回门、仓库、装置与电影票已接入图片，详见下文。CG 位图继续待补。此前设置、对白框及环境资产接入先按静态核对；本轮反馈修订完成 94 项图形回归，范围见项目状态，音频听感仍待验收；2026-10-17 新游戏黑屏专项修复的历史运行范围见项目状态文档，其余模块继续按各节待验收说明处理。

- 开发操作、项目边界及验证要求见 [AGENTS.md](../AGENTS.md)。
- 当前接入内容、占位与后续事项见 [项目状态](project_status.md)。
- 素材命名、导入、裁图与原图保护见 [美术资产规范](art_assets.md)。
- 音轨归档、WAV 导入、循环和试听约定见 [音频资源规范](audio_assets.md)。
- 项目入口说明见 [README](../README.md)。

实现变动时更新对应章节，避免在本文累计记录每轮工作或复制完整资产清单。

## 入口与目录

`project.godot` 配置 Godot 4.7、GL Compatibility 渲染及 1920 x 1080 参考视口，项目名为 Lunar。项目逻辑使用 GDScript；`.NET` 程序集名配置不代表已有 C# 玩法模块。

| 路径 | 职责 |
| --- | --- |
| `project.godot` | 引擎设置、主场景、插件与运行时辅助节点配置 |
| `scenes/ui/main_menu.tscn`、`scripts/ui/main_menu.gd` | F5 主入口，会话创建、保留、暂停与菜单切换 |
| `scenes/ui/settings_menu.tscn`、`scripts/ui/settings_menu.gd`、`settings_slider.gd` | 主菜单及暂停共用的设置页、纹理滑杆与来源返回 |
| `scripts/ui/game_settings.gd`、`default_bus_layout.tres` | 独立设置偏好、即时应用、BGM/SFX 音量总线 |
| `scripts/ui/dialogue_paper.gd`、`resources/art/ui/dialogue_paper.tres` | 剧情、收集和物件查看共用的纸张皮肤及参考布局 |
| `main.tscn`、`scripts/main.gd` | 单次游戏会话，协调玩家、地点、状态与 UI |
| `scenes/` | 五个地点及玩家、白模、移动边界复用场景 |
| `scripts/` | 探索、交互、会话状态及共享显示组件 |
| `scripts/ui/`、`scenes/ui/` | 主菜单、暂停、开场、对白与一次性操作说明 |
| `scripts/puzzles/`、`scenes/puzzles/` | 共用记忆解谜状态机、拖拽、反馈与演出 |
| `scripts/audio/`、`resources/audio/` | 会话常驻 BGM 控制器、Hide/SEEK clip 与转换规则 |
| `resources/` | 解谜定义与 AtlasTexture、SpriteFrames 等配置资源 |
| `LunarTitleFX/`、`shaders/` | 菜单标题效果与交互光晕、暂停模糊着色器 |
| `assets/` | 游戏实际引用的原图、字体、音轨及各自资产清单 |
| `addons/godot_ai/` | 按项目启用的编辑器桥接插件及运行时辅助节点 |
| `tests/` | 已有专用验证场景和脚本，执行条件遵循项目规范 |

Godot AI 的 `_mcp_game_helper` 是工具辅助 autoload。玩法状态由 `main.tscn` 的 `GameState` 节点持有。

## 会话与场景生命周期

### 菜单、开场与暂停

`main_menu.gd` 保持在场景树中，通过 `GameHost` 持有 `_game`。主要流程为：

```text
主菜单 -> 新游戏 -> 黑幕加载资源 -> 开场与主角对白
       -> 黑幕创建 main.tscn -> 淡入卧室 -> 探索

探索 -> Esc -> 暂停 -> 继续 -> 同一会话
暂停 -> 主菜单 -> 继续游戏 -> 同一会话
新游戏 -> 完整开场 -> 重建会话
```

`start_new_game()` 先设置 `transitioning`，锁定重复输入并淡出，在完全黑屏后线程加载 `main.tscn`。加载失败时恢复菜单，并保留旧会话供继续。加载成功后播放 `opening_cinematic.gd` 的完整页序列；开场结束后释放旧实例、创建新实例，保持游戏冻结直到卧室淡入结束。

`opening_cinematic.gd` 使用独立 `StoryDialogue`、黑底、淡入与特定页震动；页数据包含前段旁白、Luna 台词、主角对白及回忆旁白。每次新游戏完整播放。开场期间由菜单转发输入，Esc 被消化，当前没有跳过开场接口。

`continue_game()` 恢复 `_game` 的显示、UI、相机和 `PROCESS_MODE_INHERIT`，并调用 BGM 的 `start_or_resume()`。`return_to_menu()` 调用 `_suspend_game()`，隐藏游戏、UI 和相机，设置 `PROCESS_MODE_DISABLED` 并清零速度。`pause_game()` 同样禁用游戏处理，但保留画面供暂停界面的两遍高斯模糊取样。暂停与 `_suspend_game()` 都显式调用 BGM 的 `suspend()` 冻结音频时间；节点处理模式负责会话逻辑，未使用 `SceneTree.paused`。

BGM 不自动播放。整段开场和卧室淡入结束前保持无音乐，菜单在恢复自由操作界面时才开始 Hide。新游戏销毁旧会话并重建 BGM，起始播放位置为 0；继续游戏恢复当前时间，主菜单没有另建音乐播放器。

“继续游戏”要求当前 `_game` 有效。退出进程后会话消失；音量和亮度偏好独立保留。存档槽与制作人员页面目前为预留空白页。页面接口为：

| 接口 | 作用 |
| --- | --- |
| `page_requested(page_id)` | 打开 `load_game`、`settings`、`credits` 时发出 |
| `request_load_slot(slot_id)` | 供未来槽位界面调用 |
| `load_slot_requested(slot_id)` | 转发载入请求，当前没有读写存档实现 |
| `return_to_menu()`、`pause_game()`、`continue_game()` | 控制现有会话的显示与处理模式 |

### 共享设置与偏好

`main_menu.gd` 创建 `scripts/ui/game_settings.gd` 服务和 `scenes/ui/settings_menu.tscn` 实例，并记录设置页的来源。主菜单与暂停界面均打开同一个设置组件；关闭按钮或 Esc 保存偏好并回到原界面，从暂停进入设置时游戏与 BGM 持续冻结。Esc 每次处理一层，返回暂停后下一次 Esc 才继续游戏。

设置服务持有 `sfx_volume`、`music_volume`、`brightness` 三个 0–100 整数，默认均为 100。服务随菜单壳存在，游戏会话重建保留这些值；偏好单独读写 `user://settings.cfg`，不包含地点、库存或剧情进度。调节立即应用，拖动结束、键盘/滚轮调节、返回和重置默认值时保存；窗口关闭或服务退出时补存未写入改动。

`settings_menu.gd` 按 1920×1080 参考画布等比居中显示用户提供的半透明蓝色背景、三行设置标题、重置与返回图片按钮；`settings_slider.gd` 使用横条与箭头纹理，接收鼠标点击/拖动、触摸拖动、滚轮及聚焦后的左右键和 Home/End，并将当前 0–100 数值显示在横条右侧。拖出控件后继续接收当前拖动，松开或窗口失焦时结束；关闭页面清理拖动与焦点。重置统一恢复三项默认值并刷新箭头和数字。

设置层为 CanvasLayer 40。从主菜单进入时隐藏所有菜单按钮，背景与 Lunar 标题保留供设置层两遍高斯模糊取样，再叠加设置背景与控件。从暂停进入时隐藏暂停 `Artwork`，复用暂停层既有两遍模糊，避免叠加原暂停文字。菜单壳另建 CanvasLayer 110 的全屏黑色亮度遮罩，鼠标过滤为忽略；亮度 100 时完全透明，亮度 0 时黑色 alpha 为 0.6，统一作用于菜单、设置、开场、游戏和转场。

`default_bus_layout.tres` 配置 Master、BGM、SFX，后两者输出至 Master。设置服务将背景音乐及音效百分比应用到各自总线，0 使用总线静音；BGM 控制器基准 `-6 dB` 保留。当前尚无实际音效素材或触发，后续音效播放器需输出至 SFX。

### 常驻游戏结构

```text
Demo2 (main.gd)
  GameState (game_state.gd)
  BGM (bgm_controller.gd，运行时创建 AudioStreamPlayer)
  World
    LevelHost
      当前地点 (level.gd)
    Player (player.tscn / player.gd)
    Camera (Camera2D)
  UI (game_ui.gd, CanvasLayer 10)
  RoomTransition (运行时建立, CanvasLayer 90)
```

地点切换只替换 `LevelHost` 的子实例。玩家、相机、GameState、GameUI 与 BGM 在单次会话内复用。主菜单的开场层为 50、全局转场层为 100，暂停场景层为 20、设置层为 40、全局亮度层为 110。

`main.gd` 默认从 `bedroom.tscn` 的 `start` 出生。地点根节点挂 `level.gd`，包含以下固定结构：

| 节点或字段 | 契约 |
| --- | --- |
| `level_id`、`display_name` | 地点身份与显示名称 |
| `camera_bounds: Rect2` | 相机可见范围约束 |
| `MovementBounds` | 物理活动边界，提供 `area` 与可选 `outline` |
| `Geometry` | 可见物件与碰撞，不承担统一交互调度 |
| `Interactables` | 当前实现只枚举其直接子节点 |
| `SpawnPoints/<spawn_id>` | 命名 `Marker2D`，由 `get_spawn()` 获取 |

`get_playable_bounds()` 返回 `MovementBounds.area`；物理活动范围还可能由多边形 `outline` 决定，相机约束则独立读取 `camera_bounds`。

### 五地点连接与出生点

| 来源 | 目标场景 | 目标出生点 | 条件 |
| --- | --- | --- | --- |
| 新游戏 | `bedroom.tscn` | `start` | 默认初始地点 |
| 卧室 | `corridor.tscn` | `from_bedroom` | F 交互 |
| 走廊 | `bedroom.tscn` | `from_corridor` | F 交互 |
| 走廊 | `first_floor.tscn` | `from_corridor` | 楼梯 F 交互 |
| 一楼 | `corridor.tscn` | `from_first_floor` | 楼梯 F 交互 |
| 一楼 | `courtyard.tscn` | `from_first_floor` | F 交互 |
| 小院 | `first_floor.tscn` | `from_courtyard` | F 交互 |
| 走廊 | `studio.tscn` | `from_corridor` | 持有 `studio_key_01` |
| 画室 | `corridor.tscn` | `from_studio` | F 交互 |

门户保存 `target_scene_path` 字符串，避免双向地点产生 PackedScene 循环引用。`portal.gd` 检查钥匙后调用常驻对象的 `change_level()`；无钥匙显示 4 秒“已上锁”，钥匙不消耗，成功进入后不自动显示“已解锁”。门和楼梯保留物理边界，转场由 F 触发。

### 地点加载与错误处理

`change_level(scene_path, spawn_id, arrival_note, note_offset)` 是异步地点切换入口：锁定输入、清零速度、取消目标高亮与旧提示，淡出后等待黑幕已绘制，线程加载目标，调用 `_replace_level()`，最后淡入并恢复输入。加载结果为 `bool`；有成功到达提示时在新地点显示。

`_replace_level()` 在移除旧地点前检查资源、根脚本类型及指定出生点。资源加载失败、地点根类型无效或缺少出生点时输出错误并返回 `false`；切换已有地点时旧实例保留，外层继续完成淡入和输入恢复。初次进入在 `_ready()` 中同步加载默认地点，也经过该替换入口；当前未实现自动重试或替代地点。

门户发起调用后会随旧地点释放，加载及转场完成由常驻 `main.gd` 负责。新增切换行为继续使用该入口，避免在交互节点中直接替换整个游戏场景。

## 输入与交互

### 输入路由

`main.gd:_setup_input()` 在运行时补齐物理按键动作：W/A/S/D 对应移动，F 对应 `interact`，Esc 对应 `close_view`。主菜单通过 Godot 的 `ui_cancel` 处理暂停和返回。

探索输入按以下顺序处理：

1. 地点转场中消化输入，禁止继续交互。
2. 一次性 `controls_hint` 优先处理按键；关闭说明的按键被消化。说明打开时移动与物件交互均被阻塞。
3. `modal_open` 时交给 GameUI；主场景停止向探索交互分发该事件。
4. 鼠标左键尝试点击检查物件。
5. F 重新选择最近有效目标并调用其 `interact(context)`。

`_physics_process()` 将 `transitioning`、`ui.modal_open`、操作说明状态汇总为 `player.input_blocked`。GameUI 发出 `view_state_changed` 时立即更新锁定、清零速度并重选目标。解谜覆盖世界时隐藏 `World`；解谜返回动画开始时恢复世界显示，模态锁定保留至退出完成。

`_select_target()` 遍历当前地点 `Interactables` 的直接子节点，依次检查继承类型、`can_interact()` 和交互范围，以世界距离选择最近目标，并切换其高亮。当前不显示浮动“按 F 交互”文字，`GameUI.set_prompt()` 保留接口并主动隐藏标签。

点击路径通过视口 canvas 变换还原世界坐标，按节点顺序选择第一个满足 `can_interact()` 且 `contains_click()` 命中的节点。点击不要求靠近，也不采用最近目标排序。`inspect_object.gd` 以 `visual_path` 指向物件的 `size` 和 `oval` 判断命中；该范围与美术透明轮廓及 `artwork_size/artwork_offset` 独立。

图片、收集、对白及解谜各自处理 Esc，处理成功后消化事件。菜单在 `_unhandled_input()` 处理剩余 Esc，并检查游戏模态与转场状态，保持当前弹层关闭优先于打开暂停。

### 交互上下文与基类

`main.gd` 创建并复用以下上下文：

```gdscript
context = {"game": self, "player": player, "state": state, "ui": ui}
```

| 键 | 依赖与典型用途 |
| --- | --- |
| `game` | `main.gd`，地点切换及 `transitioning` |
| `player` | 玩家实例与世界位置 |
| `state` | GameState，碎片、钥匙与剧情标记 |
| `ui` | GameUI，正文、图片、对白、解谜与临时提示 |

新增交互继承 `interactable.gd`，遵循 `can_interact(context)`、`is_in_interaction_range(world_position, default_range)`、`interact(context)` 及 `set_highlight(value)`。基类 `can_interact()` 返回 `enabled`，`interact()` 发出 `interacted(context)`；子类覆盖时按需要保留信号。继承的 `interaction_id` 和收集用 `fragment_id/key_id` 各有职责。

`interaction_rect` 为节点局部的玩家脚底位置矩形；非空时使用矩形，空时使用默认半径。`visual_path` 绑定可见对象，独立于 Area2D 的位置和交互范围。`get_highlight_color()` 默认返回白色，记忆类返回 `MEMORY_GLOW_COLOR`。

| 脚本 | 实现职责 |
| --- | --- |
| `portal.gd` | 可选钥匙门槛、锁定提示、目标场景路径及出生点 |
| `read_note.gd` | 世界坐标锚定、限时显示字条 |
| `inspect_cg.gd` | 单图查看或配置图片序列播放 |
| `inspect_object.gd` | 点击和靠近 F 检查，使用 collection 正文弹窗 |
| `collect_photo.gd` | F 照片收集，正文和获得提示两页，立即发放去重碎片 |
| `collect_memory_item.gd` | 继承点击检查的记忆来源，支持正文、美术和获得提示 |
| `collect_key.gd` | 立即发放去重钥匙，默认展示共享钥匙图片；预览的 key 回退同样使用该图片 |
| `story_gated_key.gd` | 继承钥匙收集，按 `required_story_id` 检查完整剧情阅读状态；未满足时拒绝 F 与高亮，玄关花盆绑定 `cg_04` |
| `story_gated_memory_item.gd` | 完整读完指定剧情后提供记忆收集，电影票以 `cg_03` 为门槛，收集 E/镜面 |
| `storage_room_door.gd` | 持有 `storage_key_02` 原地打开储物间门，以 `storage_room_opened` 恢复门禁状态，不消耗钥匙 |
| `consciousness_device.gd` | 检查完整 `cg_05_true`、最近 `cg_04=truth`、门已开与玩家已进入房内，点击/F 请求装置最终对白 |
| `well_interaction.gd` | 水井碎片门槛、首次前置对白判断与解谜调用 |
| `fish_tank_interaction.gd` | 继承点击检查，持有匹配碎片且已完整读完 `required_story_id`（默认 `cg_02`）时打开独立鱼缸配置；本局首次先播四页前置对白并记标记，否则显示静水正文 |
| `brush_wash_interaction.gd` | 继承点击检查，持有任意匹配碎片时打开独立洗笔桶资源；本局首次先播前置对白并记标记，否则显示静水正文 |
| `studio_genesis_interaction.gd` | 默认五页《创世纪》阅读与头痛剧情，靠近 F 或点击书本启动普通对白 |

## 会话状态

`game_state.gd` 持有 `fragments`、`keys`、`seen_story_events`、`seen_memory_stories`、`memory_story_branches` 与 `unlocked_endings` 六个字典，另以 `current_ending` 记录当前终局，跨地点保留，新游戏重建。`seen_story_events` 记录前置对白等已启动事件及 `storage_room_opened`；`seen_memory_stories` 使用稳定剧情 ID 记录完整阅读；`memory_story_branches` 记录最近完整读完的剧情分支及后续目标。结局记录仅在当前会话内保留，没有磁盘存档。

| 接口 | 语义 |
| --- | --- |
| `collect_fragment(fragment_id) -> bool` | 新 ID 写入并发出 `fragment_acquired`；重复返回 `false` |
| `has_fragment(fragment_id)`、`fragment_count()` | 查询持有状态与数量 |
| `owned_fragment_ids() -> Array[StringName]` | 构造新的 ID 列表，供解谜接收快照 |
| `collect_key(key_id) -> bool`、`has_key(key_id)` | 去重收集与持有查询，新钥匙发出 `key_acquired` |
| `has_seen_story_event(event_id)`、`mark_story_event_seen(event_id)` | 会话级剧情标记 |
| `has_seen_memory_story(story_id)`、`mark_memory_story_seen(story_id)` | 正式组合剧情完整阅读状态，空 ID 不写入，重复记录保持去重 |
| `record_memory_story_branch(story_id, branch_id, next_story_id)` | 完整读完分支后记录当前选择及阶段五目标，重复完整阅读替换该剧情的原分支 |
| `get_memory_story_branch(story_id)`、`get_next_memory_story(story_id)` | 查询最近完整读完的分支及后续目标；触发分支与提前退出不写入 |
| `unlock_ending(ending_id)` | 仅接受 `end1/end2`，写入 `unlocked_endings` 与 `current_ending`；由完整结局正文后的 GameUI 信号触发 |

照片、草稿纸、客厅小帐篷与符合门槛的电影票在打开正文时即写入碎片，提前关闭保留奖励。小帐篷沿用 `collect_memory_item.gd`，D/`memory_fragment_04` 为月影，无剧情门槛；电影票使用 `story_gated_memory_item.gd`，完整 `cg_03` 后从餐桌南侧椅子下收集 E/`memory_fragment_05` 镜面。阶段四五个选项与剧情编号分别为 A=港湾 1、E=镜面 2、B=涌泉 3、C=潮汐 4、D=月影 5；稳定 ID 和编号独立。阶段 1—3 保留原路由，E 展示名和词同步镜面，未增加 E 组合。重复奖励去重，钥匙不消耗。当前没有序列化存档、独立背包 UI 或按谜题 ID 记录的完成集合。

水井在同时持有 `bedroom_photo_01`、`corridor_photo_02` 且未标记 `well_memory_intro` 时请求前置对白。解谜成功打开且 `introduction_started` 为真后，入口立即写入标记；提前 Esc 退出对白也保留该标记。谜题的 `restoration_succeeded(puzzle_id)` 在 CG 演出开始时转发，未写入谜题完成集合。正式最后一页完整翻完时发出 `memory_story_completed(active_outcome.id)`，经 GameUI/main 写入 `seen_memory_stories`；阶段 1—4 使用 `cg_01/02/03/04`。情节块 4 先发 `memory_story_branch_completed(story_id, branch_id, next_story_id)` 记录分支，再发完整阅读信号并交 GameUI 同黑屏接第五幕。第五幕完整正文分别记录 `cg_05_true/cg_05_false/end2`。INTRO、微剧情、前两次 Luna 介入、未读完正文、占位 CG 与提前 Esc 不写新完成，提前退出保留旧记录。

洗笔桶在持有任意匹配碎片且未标记 `brush_wash_memory_intro` 时请求 `brush_wash_memory_story.gd:INTRO_PAGES` 的三句前置对白。对白实际开始后立即写入标记，提前 Esc 也保留；重复交互直接进入选碎片，新游戏重建状态后重新播放。没有匹配碎片时显示静水正文，不标记前置对白。

鱼缸先通过 `required_story_id` 查询 `has_seen_memory_story()`，默认门槛为洗笔桶情节块 2 的 `cg_02`。完整读完该剧情并持有任意匹配碎片，且未标记 `fish_tank_memory_intro` 时，才请求 `fish_tank_memory_story.gd:INTRO_PAGES` 的四页前置对白。实例实际进入 `INTRO` 后通过 `introduction_started` 立即写入本局标记，提前 Esc 保留；重复进入不重播，新游戏重置。未完整读完 `cg_02` 或没有匹配碎片时显示“水里没有鱼。水面毫无波澜。”，不记录前置标记；前置对白结束后才进入选碎片并按共享资格呈现拖拽引导。

一楼花盆 `Geometry/Plant` 位于 `(650, 365)`，`PlantStorageKey` 绑定它并在 `(650, 409)` 提供 F 脚点，使用 `story_gated_key.gd` 的 `can_interact()` 检查 `cg_04`；条件未满足时不参与 F 目标选择，也不显示靠近高亮。满足后复用共享钥匙图标与去重收集流程，发放 `storage_key_02` /“储藏室钥匙”（钥匙 2），钥匙不消耗。阶段四任一正式分支完整读完后写入 `cg_04` 并解锁花盆钥匙；前两次 Luna 介入、微剧情和提前 Esc 不写入。`cg_03` 与其后第四幕普通对白保持各自身份，不解锁该钥匙。

钥匙位置按用户最终确认保留在玄关花盆，地毯保留原查看。一楼上方 `UpperRoom` 作为储物间使用，原场景内接入仓库地板墙面、墙体、窗和门口内外两片，底部墙体左右拆片为世界 x=192.15–271.6 留入口，可行走地板从 y=338.4 开始。`StorageRoomGate` 位于 `(231.875, 552.6)`、实体 `79.45×30.8`，外片 `OuterLeaf` 是其子节点；`OpenStorageRoom` 持钥匙调用原 `_sync_gate()` 解除父节点碰撞并隐藏整组，以 `storage_room_opened` 跨重载恢复，不切换场景、不消耗钥匙。开门脚点为 `(231.875, 600)`、局部 F 矩形 `(-60, -10, 120, 45)`。房内 `UseConsciousnessDevice` 继续绑定 `Geometry/ConsciousnessDevice`，装置使用传送门图片并单独维护底部实体；脚点 `(295, 505)`、局部矩形 `(-60, -10, 120, 25)`，场景覆盖 `player_access_rect=(35, 338.4, 385, 206.1)`。门已开、完整 `cg_05_true`、最近 `cg_04=truth` 和玩家已进入房内的门槛保留。

`storage_room_door.gd` 新增导出 `room_visual_paths: Array[NodePath]` 与 `room_interaction_paths: Array[NodePath]`。`_sync_gate(opened)` 同步室内可见性与登记查看节点的 `enabled`：锁定时隐藏 UpperRoom 地板、墙面、窗、水渍及装置，墙体与装置实体继续阻挡；开门后显示室内并启用水渍查看。装置继续独立检查原剧情与房内门槛。房间重载后按 `storage_room_opened` 恢复同一显隐与交互状态。

碎片拖拽引导的已显示标记位于常驻 GameUI 的 `puzzle_drag_hint_seen`，供水井、鱼缸和洗笔桶在同一局中共享。它随新游戏重建 UI 后重置，退出谜题、换地点、失败重试及再次进入均保留；当前不写入 GameState 或磁盘。

## UI 与对白接口

`game_ui.gd` 是常驻 `CanvasLayer`，主要控件在 `_ready()` 里构建。`ModalMode` 包含 `NONE`、`IMAGE`、`PUZZLE`、`COLLECTION`、`DIALOGUE`、`ENDING`；`modal_open` 与 `view_state_changed(is_open)` 对外表达输入锁定。`is_story_covering_world()` 供 main 隐藏第五幕黑底对白与终局背后的探索世界。

| API | 用途与边界 |
| --- | --- |
| `show_note(text, world_anchor, seconds)`、`clear_note()` | 限时世界气泡，随相机投影、按左右边缘调整尾巴朝向并限制在视口四边内 |
| `show_view(title, caption, artwork, notice, show_exit_hint, narrative_text)` | 图片模态；`title` 留作当前标题状态，`caption` 参数当前未渲染，顶部正文来自 `narrative_text` |
| `show_slideshow(title, artworks, seconds_per_slide)` | 过滤空图片，自动按顺序播放；完整结束或手动退出后关闭 |
| `show_collection(pages, artwork, placeholder_type, reward_page, show_exit_hint, large_artwork)` | 纸张对白框内正文分页，奖励页字号独立，可显示缩略图、共享钥匙图标或大图；物件查看沿用此入口 |
| `show_dialogue(pages)` | 普通逐字对白，实例由 GameUI 复用 |
| `open_consciousness_device()` | 无其他模态时播放 `EndingStory.DEVICE_PAGES` 黑底正文与最终选择 |
| `open_puzzle(definition, owned_fragments, show_introduction, puzzle_scene = PuzzleScene) -> bool` | 无模态时创建指定 PackedScene 的谜题实例，默认共用场景；复制库存并连接信号，依据本局 `puzzle_drag_hint_seen` 设置实例 `show_drag_hint`，收到 `drag_hint_presented` 后记录已显示；空场景拒绝打开 |
| `handle_modal_input(event)`、`close_view()` | 输入转发、关闭、拖拽取消、资源引用和临时状态清理 |
| `show_controls_hint()` | 每个新游戏实例只呈现一次操作说明 |
| `set_status(location, count)` | 当前仅保存地点名，未显示计数 HUD |

`show_collection()`、`show_dialogue()`、`show_slideshow()` 和 `open_puzzle()` 会拒绝已有模态下的重复打开；交互调用者仍应统一遵守当前模态状态。图片/收集由左键、F 或 Esc 关闭或推进；普通对白由左键、Enter、空格、F 补全文字或推进，Esc 关闭。谜题输入由其自身接管。

普通对白页为 `Array[Dictionary]`：

```gdscript
var pages: Array[Dictionary] = [
    {"speaker": "主角", "text": "已确认的台词", "expression": &"speaking"},
    {"speaker": "Luna", "text": "已确认的台词"},
    {"text": "已确认的旁白", "show_protagonist": true, "expression": &"neutral"},
]
context["ui"].show_dialogue(pages)
```

`speaker` 可省略；`expression` 支持 `neutral`、`speaking`、`smile`、`teary`，未知值回退到 `neutral`。主角名为“主角”“你”或 `protagonist` 时默认显示立绘，也可由 `show_protagonist` 指定首次出现。一旦在本段出现，主角立绘持续保留到该对白序列结束；后续未指定表情的页采用中性图。`speaking` 在逐字播放时切换说话/中性口型，文字完成后回到中性。每次 `start()` 深拷贝页数据并重置本段立绘状态。

页可配置 `shake: true`，由 StoryDialogue 统一播放 0.55 秒、参考幅度 16 像素的衰减震动；`set_shake_offset()` 更新对白位置并发出 `shake_offset_changed(offset)`，偏移采用参考画布坐标。`main.gd` 监听常驻 GameUI 的对白实例，将偏移按对白缩放和镜头 zoom 转为反向 `Camera2D.offset`，使探索画面与对白同步移动。翻页、完整结束和 `stop()` 均归零，Esc 经 GameUI 关闭时同样清理。开场沿用此页字段及相同参数，共用实现管理震动计时。

页可配置 `choices: Array[Dictionary]`，每项为 `{id: StringName, text: String}`。正文完整显示后在底部纸张对白框内出现编号文字选项，支持鼠标、↑↓、Enter/空格/F 与数字 1/2；普通 `advance()` 不跳过选择。选择前置 `active=false` 并清理按钮/焦点，再发出 `choice_selected(choice_id)`，回调可同步 `start()` 新页；翻页和 `stop()` 同样清理。装置页显式关闭立绘，黑底由 GameUI 提供。

对白、开场和菜单按 1920 x 1080 参考画布等比居中适配。字体统一引用 `ui_font.tres`；`ui_text_style.gd` 管理一般提示的基础文字，谜题可按配置覆盖。主菜单与暂停按钮沿用图片文字。

`scripts/ui/dialogue_paper.gd` 提供共享 `TextureRect` 皮肤，引用 `resources/art/ui/dialogue_paper.tres`。原 `对话框.png` 为 1920×1080 透明图，按原字节归档至 `assets/art/ui/panels/dialogue_paper.png`，AtlasTexture 裁区为 `(37, 720, 1845, 291)`；`StoryDialogue.PANEL_RECT` 和 GameUI 的 `collection_panel` 以该参考位置与尺寸等比居中适配。纸张显示保持原比例，文字使用局部安全区避开右侧折角，字体、黑字与优先字号保留。

StoryDialogue 有说话人时正文安全区为 `(48, 78, 1688, 154)`，无说话人时为 `(48, 40, 1688, 192)`，继续提示为 `(48, 242, 1688, 30)`；选择项复用正文安全区并保留长文缩字号。GameUI 收集/物件查看的安全区为 `(48, 24, 1688, 242)`，正文与页脚各留空间，正文优先字号 36、奖励页 40，必要时通过 `DialogueBubble.fit_text()` 缩小至 24。附大图限制在纸张顶部上方 24 个参考像素，缩略图和钥匙预览继续保留。

共享 StoryDialogue 覆盖开场、普通剧情、四处谜题前置/正式/抵抗对白、第五幕、装置选择及结局正文，原翻页、奖励、选项、立绘、震动与模态逻辑保留。`memory_puzzle.gd` 的 CG 图片布局读取 `StoryDialogue.PANEL_RECT.position.y`，在参考 y=720 的纸张上方布局。微剧情继续使用 `memory_echo.gd` 浮字，首次键帽说明保持原样；独立大图 `view_panel` 继续为浅灰底。纸张初次接入时仅静态核对，未运行引擎、试玩或测试。

`scripts/ui/dialogue_bubble.gd` 与 `resources/art/ui/dialogue_bubble.tres` 继续用于 GameUI 的 `prompt_bubble`、`note_bubble` 世界提示。`content_rect()` 给出图内安全正文区，`fit_text()` 根据换行高度适配字号；`tail_on_right` 使用负宽度水平翻转，绘制原点保持 `Vector2.ZERO`。GameUI 将世界锚点投影到屏幕后摆放气泡、限制在四边内并调整尾巴方向。此前镜像额外右移一个框宽的修复保留，世界提示沿用原气泡皮肤。

2026-10-17 的历史黑屏专项验证已复现当时的镜像异常，并检查修复后的普通/镜像框体、新游戏按钮触发、开场首句可见、鼠标与 Enter 翻页及进入卧室，报告 `failures=[]`。该记录对应当时使用气泡底图的版本；后续矩形底框及当前纸张对白框、世界提示视口边缘与其余路线的验证独立记录。

`collection_preview.gd` 等比显示道具图片；`collect_key.gd` 的默认 `artwork` 与 `placeholder_type = key` 的回退均引用 `resources/art/ui/key_icon.tres`。该替换只影响图标，去重发放、钥匙查询与门户持有逻辑保留。

## 会话背景音乐

`main.tscn` 根下的 `BGM` Node 挂 `scripts/audio/bgm_controller.gd`，运行时创建一个 `AudioStreamPlayer`。控制器深复制 `resources/audio/gameplay_bgm.tres` 的 AudioStreamInteractive，为当前会话保留独立状态；clip 0 为 Hide，clip 1 为 Seek（原曲名 SEEK）。播放器基准音量 `-6 dB` 可由导出属性调整，输出至 `BGM` 总线，设置页的背景音乐百分比在总线上统一生效。

| 接口 | 作用 |
| --- | --- |
| `start_or_resume()` | 首次启动当前 clip；已有播放时解除 `stream_paused`，恢复同一时间 |
| `suspend()` | 设置 `stream_paused`，冻结音频播放时间 |
| `set_puzzle_active(active)` | 水井/鱼缸/洗笔桶/帐篷收纳盒谜题为真时选择 SEEK，否则选择 Hide；相同目标不重复请求 |
| `stop()` | 停止并重置控制器至未启动的 Hide 状态 |

`main.gd` 根据 GameUI 的 `view_state_changed` 与模态状态更新音乐，四个谜题 ID 为 `well_memory/fish_tank_memory/brush_wash_memory/tent_storage_memory`。前置、选碎片、填词、微剧情、Luna 介入与正式 CG 使用 SEEK；微剧情或前两次介入回谜题保持 SEEK。第五幕黑底 CG、装置正文及两种结局正文继续使用 SEEK；真回忆后的探索提示与终局使用 Hide。原三处 `return_started` 或 Esc 关闭后切 Hide，后续普通对白保持 Hide。普通图片、收集与地点切换保留当前播放时间。

双向转换均使用 `IMMEDIATE + SAME_POSITION + FADE_CROSS`，通过 `AudioStreamPlaybackInteractive.switch_to_clip()` 在同位置切换。`fade_beats = 0.03` 在当前无 BPM 的 WAV 上对应约 30 ms 逐采样交叉平滑；切换不重新播放或 seek。暂停与返回菜单由菜单壳显式挂起播放器，新游戏通过重建整个会话从 0 开始；整个开场及卧室淡入期间无 BGM，主菜单无新增 BGM。

两份原 WAV 与导入参数独立维护在 `assets/audio/`，全曲循环为 `begin 0 / end -1`，格式、循环枚举及替换约束见音频规范。设置页已提供独立 BGM/SFX 音量，当前尚无实际音效素材或触发。原文件归档、参数与总线引用已静态核对，四处组合剧情沿用既有谜题音乐生命周期；本次未由 Codex 启动游戏、引擎、测试或音频试听，同位置切换、音量调整、循环和乐句衔接的实际听感待用户确认。

## 共用记忆解谜

### 数据、实例与状态机

`scenes/puzzles/memory_puzzle.tscn` 配合 `scripts/puzzles/memory_puzzle.gd` 供水井、鱼缸、洗笔桶、帐篷收纳盒和后续入口复用。`scenes/puzzles/tent_storage_memory_puzzle.tscn` 继承共用场景并绑定阶段四独立定义。静态配置与单轮状态分开：

| 层 | 内容 |
| --- | --- |
| `memory_option.gd` Resource | 稳定 `choice_id`、绑定库存 `fragment_id`、展示名、词与 `moon_texture`；当前 A—E 绑定用户原文件 5/4/3/2/1，旧月相比率作为无纹理时的兼容 |
| `memory_puzzle_definition.gd` Resource | 选项、句型、可选 `sentence_templates:Array[Dictionary]` 与 `sentence_selector_rect`、失败反馈、演出脚本、背景布局、投放区域及可选视觉行为；成功开关控制现有演出路径，旧左右答案作无路由入口兼容 |
| `memory_combination_stories.gd:BY_PUZZLE` | 按谜题 ID 配置左右有序 `choice_id`、可选 `template_id`、剧情 ID、`kind` 与文字；阶段四两条正式路由分别为 `cg_branch/luna` 与 `cg_resistance/truth` |
| 解谜实例 | `available_fragment_ids` 快照、`selected_ids`、两个 `slot_ids`、`template_index`、深拷贝组合路由与待播内容、临时 token、动画与当前 phase |
| GameState | 实际持有碎片、前置事件与正式组合剧情完整阅读标记，解谜实例不发放或消耗碎片 |
| GameUI | 本局共享的 `puzzle_drag_hint_seen`，在引导实际显示时更新 |

推荐调用：

```gdscript
context["ui"].open_puzzle(definition, context["state"].owned_fragment_ids())
```

阶段为 `MOON`、`RISING`、`WORD`、`FEEDBACK`、`INTRO`、`RESOLVING`、`STORY`、`ECHO`、`RETURNING`、`RESISTANCE`。四处常规流程统一为选月相 -> Enter 确认 -> 已投入词飞出 -> 两槽填词 -> 组合判定。`MOON` 初始隐藏所有水面词与句槽；`add_moon()` 每次只让对应 Label 在 0.25 秒内显现，并保持可继续投入，选碎片期间不创建可拖词牌。Enter 进入 `RISING`，按配置顺序让已投入词在 0.9 秒内统一浮出并飞到各自词牌位置，完成后进入 `WORD` 可拖。四资源 `rise_on_drop=false`，旧导出字段仅作兼容，核心流程统一等待 Enter。前置对白、成功扫光、CG 与微剧情在相应阶段衔接；阶段四连续分支逻辑保留。

未持有月相隐藏并拒绝拖动；至少投入一块可 Enter 进入填词，至少填一槽可确认。可替换、交换槽中词牌或拖回水面取消。四处先用稳定 `choice_id` 匹配有序路由，显示文字为 A=港湾、B=涌泉、C=潮汐、D=月影、E=镜面；阶段四全部路由匹配 `template_id=3`。表外组合或少填沿用失败反馈，按 `failure_duration` 清空尝试、保留库存；未定义路由的入口使用旧答案兼容判定。`play_success_story` 继续控制原成功演出路径；微剧情和代码 CG 占位走各自浮现路径。

`sentence_templates` 每项包含稳定 `id`、两槽间的 `middle` 与句尾 `suffix`。列表为空时沿用旧单句型字段，阶段 1—3 保持该配置。阶段四仅配置 `{id:3, middle:"从", suffix:"中涌现"}`，显示“【A】从【B】中涌现”；单项不显示选择按钮、不响应 Tab。多项配置时才使用 `sentence_selector_rect` 与实例 `template_index` 切换，实例操作不修改共享定义。

拖拽数据带 `{kind, choice_id, puzzle_instance}`，`accepts_drag()` 同时检查实例身份、阶段和资格。实例深拷贝路由及待播 payload，单轮操作不修改共享 Resource 或常量数据。`_stop_word_motion()` 在重置、退出和 `_exit_tree()` 清理水面词淡入与飞词 Tween，重置重新隐藏水面词、句槽并回到 `MOON`；GameUI 关闭时取消仍在进行的 GUI 拖拽并释放解谜实例，库存与共享定义保留。

四处 A—E 共用五张透明月相原图和 `resources/art/puzzles/shared/` 中的 AtlasTexture。`memory_token.gd` 使用 `moon_reference_center`、`moon_reference_diameter` 元数据，将实月轮直径统一为 token 短边的 76%，保留各相位原图比例及近柔光；拖拽预览沿用同张纹理。鱼缸水面词中心 y=447，帐篷镜面词中心 `(1110, 785)`，保持在各自水面/盒盖内。本轮新月相与浮词行为当前仅静态核对，运行验证另行记录。

月相及拖拽预览的材质使用 `moon_fragment_edge_fade.gdshader`，通过 `source_rect` 将 Atlas 的源图 UV 转成裁区局部 UV，以 18 原像素边缘渐隐消除柔光方框；词牌沿用原绘制，源 PNG、主体比例与 76% 月轮直径保持。谜题 `story_image` 使用 `PRESET_TOP_LEFT` 配合显式布局，避免重复设置锚点产生布局警告。

### 首次拖拽引导与接收区域

`memory_drag_hint.gd` 绘制鼠标左键、月相和箭头指向目标的图示，文字为“按住左键，将记忆碎片”“拖到水井/鱼缸/洗笔桶/收纳盒上松开”；目标名来自定义的 `drag_hint_target_name`。浅灰蓝文字与透明深色薄边框沿用月光 UI，图片与引导均不拦截拖拽。`drag_hint_rect` 使用参考画布坐标：水井为 `(32, 32, 460, 224)`，鱼缸为 `(1290, 112, 460, 224)`，洗笔桶为 `(48, 710, 460, 224)`，收纳盒为 `(1300, 40, 460, 224)`；随窗口等比适配并限制在视口内，避开月相与目标物体。

实例通过 `show_drag_hint` 接收显示资格，仅在有可拖碎片且实际进入 `MOON` 阶段时显示并发出 `drag_hint_presented`。水井、鱼缸或洗笔桶前置剧情未读完时不显示也不记录；无可拖碎片时不记录。引导保持可直接拖拽，首块成功投入后淡出。任意非 Esc 按键可收起并消耗该事件，避免同次 Enter 提前确认；Esc 按原规则退出谜题。显示一次后，重试或重新进入均不重复。

`fragment_drop_rect` 是 `moon_reference_size` 中的绝对参考坐标，`fragment_drop_margin` 为同一参考尺度的边缘容错，默认分别为空矩形与 0。空矩形回退至水面形状；当前水井配置 `(600, 842, 750, 230)`，鱼缸配置 `(701, 339, 1060, 490)`，洗笔桶配置 `(760, 310, 700, 770)`，收纳盒配置 `(430, 425, 812, 655)`，四处 margin 均为 24，覆盖各自目标区域及边缘。

`moon_water_rect` 和其局部 `water_drop_polygon` 继续定义可见水面、涟漪及词语拖回取消范围。布局函数将碎片矩形及容错转换为 Water 的局部坐标；Water 的 `_has_point()` 在合法月相拖拽时扩展 GUI 接收范围，`_can_drop_data()` 继续检查实例、阶段和资格。词语拖回仍检查原椭圆或多边形。扩展碎片接收范围只影响月相投放，图片、涟漪、浮词位置、词牌与词槽尺寸保持各自配置。

### 子组件职责

| 文件 | 职责 |
| --- | --- |
| `memory_token.gd` | 月相/词牌绘制、拖拽预览、数据封装、已占用词槽接收替换拖放 |
| `water_drop_zone.gd` | 月相使用独立矩形与容错接收；词牌取消使用原水面椭圆或局部多边形；同步 GUI 命中与拖放资格校验 |
| `memory_drag_hint.gd` | 每局共享的首次碎片拖拽图示、两行文案、淡出与视口内适配 |
| `word_slot.gd` | 两个词槽的接收、弧光绘制、合法拖拽高亮与落槽反馈 |
| `water_ripple.gd`、同名 shader | 配置 SpriteFrames 单次播放、透明裁区与水面显示 |
| `moonlight_hint.gd` | Enter/Esc 透明键帽与阶段提示 |
| `moonlight_effects.gd` | 浮词光尘和成功句子扫光，效果结束后停止刷新 |
| `moonlight_sentence_mist.gd` | 句子背后可选的局部对比柔雾 |
| `memory_combination_stories.gd` | 四处共 32 条有序路由；阶段四句型 3 包含两条 `cg_04` 正式分支与 18 条用户微剧情 |
| `memory_echo.gd` | 原谜题背景上的淡雾、月光文字自动浮现与 CG 占位；左键/Enter/空格/F 补齐或淡出退出及 Tween 清理 |
| `well_memory_story.gd` | 水井 `INTRO_PAGES`、`NARRATIVE_PAGES`、`FOLLOWUP_PAGES` 数据 |
| `brush_wash_memory_story.gd` | 洗笔桶 `INTRO_PAGES` 三句前置对白、情节块 2 的 `NARRATIVE_PAGES` 及八页后续旁白 `FOLLOWUP_PAGES` |
| `fish_tank_memory_story.gd` | 鱼缸四页前置 `INTRO_PAGES`、情节块 3 的 41 页 `NARRATIVE_PAGES` 与第四幕 16 页 `FOLLOWUP_PAGES` |
| `tent_storage_memory_story.gd` | `INTRO_PAGES` 3 页、`RESISTANCE_PAGES` 2 页、`LUNA_PAGES` 7 页、`TRUTH_PAGES` 14 页及 `STORY_BRANCHES` 元数据 |

### 阶段 1—3 配置差异

| 行为 | 水井 | 鱼缸 | 洗笔桶 |
| --- | --- | --- | --- |
| 定义 | `resources/well_memory_puzzle.tres` | `resources/fish_tank_memory_puzzle.tres` | `resources/brush_wash_memory_puzzle.tres` |
| 入口 | 靠近 F，任意匹配碎片可尝试 | 点击或靠近 F，完整读完 `cg_02` 且持有匹配碎片可尝试；否则静水正文 | 点击或靠近 F，任意匹配碎片可尝试 |
| 阶段编号 / 已解锁句型 | 1 / 【A】之中，【B】到来 | 3 / 【A】里，不见【B】 | 2 / 【A】之中，【B】到来 |
| 组合路由 | A→B 为情节块 1；B→A 为微剧情 | A→B 为情节块 3 黑底对白；其余五种 A/B/C 异词组合为微剧情 | A→C 为情节块 2，后 11 页接窗边 CG；C→A、B→C、C→B 为微剧情 |
| 前置对白 | A+B 首次齐备时请求水井对白 | 本局首次有匹配碎片进入时播放四页对白 | 本局首次有匹配碎片进入时播放三句对白 |
| 碎片接收 | 水井外接矩形 `(600, 842, 750, 230)`，margin 24 | 鱼缸外接矩形 `(701, 339, 1060, 490)`，margin 24 | 洗笔桶外接矩形 `(760, 310, 700, 770)`，margin 24 |
| 水面效果 / 词语取消 | `moon_water_rect` 内椭圆 | `water_drop_polygon` 四边形 | `water_drop_polygon` 贴合桶内水面 |
| 拖拽引导 | 左上 `(32, 32)`，目标名“水井” | 右上 `(1290, 112)`，目标名“鱼缸” | 左下 `(48, 710)`，目标名“洗笔桶”；与收纳盒共四处共享已显示状态 |
| 浮词时机 | 一块显现一词，Enter 后统一飞出，动画结束进入填词 | 一块显现一词，Enter 后统一飞出，动画结束进入填词 | 一块显现一词，Enter 后统一飞出，动画结束进入填词 |
| CG 后 / 微剧情后 | 情节块 1 完整读完后返回探索并衔接后续对白；微剧情回选碎片 | 情节块 3 完整读完后淡回客厅原位置并衔接第四幕 16 页对白；微剧情回选碎片，无后续对白 | 情节块 2 完整读完后淡回画室原位置并衔接八页普通旁白；微剧情回选碎片，无后续对白 |
| 水波纹 | 配置 SpriteFrames | 未配置 | 未配置 |
| 可选 UI | 无白底、月光文字/槽位 | 无白底、月光文字/槽位，独立字号与句子柔雾 | 无白底、月光文字/槽位，句子柔雾透明度 0.21 |

布局位置由 `moon_reference_size`、`moon_well_rect`、`moon_water_rect`、可选月相/水中词坐标、句子矩形和提示中心配置；碎片接收和首次引导另由 `fragment_drop_rect/fragment_drop_margin`、`drag_hint_target_name/drag_hint_rect` 配置。`moon_environment` 单独存在时即可启用整图背景，`moon_well` 作为可选叠加层；洗笔桶使用用户原始整图，布局示意另行归档。背景按覆盖视口的等比缩放映射，部分控件采用自身尺寸规则；新增布局沿用现有换算函数，分别维护图像、水面效果和月相接收范围。洗笔桶的月相坐标、水面多边形及字号见美术规范。

### 阶段四帐篷收纳盒

一楼 `Geometry/TentStorageBox` 使用独立透明新图，按源构图位于客厅中央 `(741.475, 548.05)`，视觉与矩形实体尺寸均为 `50.75×41.3`。`Interactables/InspectTentStorageBox` 使用 `tent_storage_interaction.gd` 打开 `tent_storage_memory`；脚点 `(741.475, 608.05)`，局部 F 矩形 `(-60, -10, 120, 50)`，稳定交互 ID `tent_storage_box`、完整 `cg_03` 与至少一个匹配碎片门槛保留。条件未齐时显示“水面毫无波澜。”。`SmallTent` 继续独立收集月影。解谜背景绑定用户 ZIP 原图，布局示意仅作参考。A/B/C/D/E 分别绑定港湾/涌泉/潮汐/月影/镜面，解谜不发放或消耗库存。

收纳盒交互导出的 `puzzle_scene` 预加载 `scenes/puzzles/tent_storage_memory_puzzle.tscn`，通过 `open_puzzle(definition, owned_ids, show_intro, puzzle_scene)` 实际创建该继承场景。`show_intro` 由本局 `tent_storage_memory_intro` 标记决定，前置对白实际开始后记录；提前退出保留，新游戏重置。原三处调用沿用末尾参数默认值，不需要修改入口；定义与场景均可独立配置。

独立定义 `resources/tent_storage_memory_puzzle.tres` 按 1920×1080 配置月相、盒盖多边形、碎片接收矩形与固定句型。碎片接收矩形为 `(430, 425, 812, 655)`，容错 24；`moon_water_rect = (430, 565, 812, 460)` 与局部多边形管理盒盖效果和词语拖回取消。拖拽引导位于 `(1300, 40, 460, 224)`，目标名“收纳盒”，沿用四处共享每局一次标记。具体布局见美术规范。

独立 `story_script` 绑定 `tent_storage_memory_story.gd`，阶段四共 20 条有序路由，均匹配句型 3“【A】从【B】中涌现”。D→C 使用 `cg_branch/luna` 直接播放 Luna 7 页；C→D 使用 `cg_resistance/truth`，连续第三次播放真实 14 页。两条正式路由故事 ID 均为 `cg_04`，其余 18 条使用用户新正文与 `3_<左编号>_<右编号>` ID，覆盖剩余五碎片异词组合。阶段 1—3 原路由保留。

两分支正文逐字保留用户原文，每页空 `speaker` 且 `show_protagonist=false`。共用演出按路由 `branch_id` 深拷贝对应页组并进入 `STORY`，沿用左键/Enter/空格/F 补齐与翻页、黑底和通用对白框。未添加 CG 位图、立绘或音效，制作概要与真假结局说明不作为正文显示。

`INTRO_PAGES` 为三页解谜前置：Luna“月影从潮汐中涌现。”、旁白“事实果真如此吗？”、Luna 再次“月影从潮汐中涌现。”；每页关闭立绘，沿用共用对白和输入。未满足完整 `cg_03` 或没有匹配碎片时继续显示查看提示，不标记前置已开始。

`cg_resistance` 计数属于当前谜题实例，要求连续确认 C→D：前两次进入 `RESISTANCE`，分别执行 0.55 秒震动，第二次幅度更强；震动结束恢复偏移、清空词槽并将已投入词牌放回原位，保留投入资格与库存。随后分别播放 Luna 的 `是“月影从潮汐中涌现”。` 与 `小汐，听我的，别再多想了。`，读完回到 `WORD` 可直接再填；第三次进入真实导向 `STORY`。确认任何其他组合，包括微剧情、无匹配与少填，都清零连续计数；Esc 退出后重新进入创建新实例并清零。退出会终止 Tween 并恢复位置。乱码内容尚未确定，当前没有添加乱码演出。

`STORY_BRANCHES` 每项含 `id`、`label`、`next_story_id`、`pages`：`luna` 指向 `cg_05_false`，`truth` 指向 `cg_05_true`。正式最后一页读完后，先转发分支事件写入 GameState，再转发完整阅读事件标记 `cg_04`，花盆钥匙此时解锁。谜题直接请求退出，GameUI 释放实例并保持黑屏衔接第五幕；阶段四至第五幕之间不淡回探索。重复完整阅读可替换分支，提前 Esc 保留旧记录。

### 第五幕与结局

`scripts/ending_story.gd` 集中维护 `FALSE_ENDING_PAGES` 5 页、`TRUTH_RECOLLECTION_PAGES` 8 页、`EXPLORATION_PAGES` 3 页、`DEVICE_PAGES` 5 页正文加 1 页选择，以及 `TRUE_ENDING_PAGES` 5 页。正文来自用户本轮总剧情与 CG 文本，黑底页显式关闭立绘；CG 位图继续待提供。

GameUI 通过 `pending_ending_story` 接收完整 `cg_04` 的目标。`cg_05_false` 完整读完后记录阅读并进入假结局 `end1` 终局；`cg_05_true` 完整读完后记录阅读，恢复探索背景，播放三页提示并指出钥匙在玄关花盆里。玩家自行开储物间门、进入房间并使用装置。装置的 `leave` 选择播放真正文，完整后进入 `end2`；`stay` 选择播放假正文，完整后进入 `end1`。选择本身不提前解锁结局。

结局页面以 `ENDING` 模态显示黑底、结局名称与“返回主菜单”按钮，`ending_unlocked(ending_id)` 经 main 写入 GameState。按钮或 Esc 发出 `main_menu_requested` 交菜单壳挂起会话，继续游戏恢复同一终局；移动与物件交互保持锁定。普通第五幕对白 Esc 关闭且不记录未读完内容，可通过重新完成阶段四分支或重进装置继续；新游戏重建全部会话记录。

### 剧情浮现与完整阅读

四处共 32 条路由的剧情 ID、句型与对应词见 [项目状态的组合剧情映射](project_status.md#组合剧情映射)。`micro` 在 `ECHO` 调用 `memory_echo.gd`，原背景上浮现完整月光文字，配细光线与稀疏光点，不显示常规对白框或立绘。下方提示“左键 / Enter / 空格 / F 继续”；显现期间确认先补齐，完成后确认淡出并清空尝试、返回 `MOON`。确认输入被消化，Esc 退出整个谜题。库存和共享引导标记保留，微剧情不发出完成或后续对白事件。

`cg_existing` 读取当前定义的 `NARRATIVE_PAGES` 并进入 `STORY`：水井使用原分段 CG；洗笔桶情节块 2 共 39 页，前 28 页保留黑底，第 29–39 页（零起 index 28–38）通过 `cg_image` 接入 `resources/art/cg/act_02/cg_02_window.tres`，从小泠“好了，别再说了。”切入；鱼缸继续黑底正文。三处共用纸张对白框，正式回忆关闭立绘。阶段四通过 `cg_branch/cg_resistance` 进入正式分支，`cg_placeholder` 仅保留兼容实现。正式演出开始发出 `restoration_succeeded`；前三处完整读完后请求各自 `FOLLOWUP_PAGES` 并返回探索，阶段四完整后同黑屏接第五幕。提前 Esc 不接后续。微剧情仍在 `ECHO` 确认后回选碎片，不写完整阅读记录。

`memory_echo.gd` 针对首次浮现未见正文的反馈先完成可见布局，再通过延迟回调赋文本并强制计算换行；每次关闭递增 `_presentation_id`，旧回调按 ID 失效。该改动用于加固首次布局和取消时序，反馈根因尚未证明；本轮四处微剧情首次显示、快速关闭和重新进入的图形回归均通过。

前三处 GameUI 暂存后续页，收到 `return_started` 时恢复探索世界但保持输入锁定，等待淡出和 `exit_requested` 后直接打开待续对白。阶段四正式分支使用独立的第五幕目标队列，直接退出谜题、释放实例并同黑屏接新正文。

洗笔桶后续 `FOLLOWUP_PAGES` 将提供的完整旁白按自然句分为八页，每页设置空 `speaker`、`expression = neutral` 和 `show_protagonist = true`；复用 GameUI 普通对白，在画室背景上全程显示右侧主角中性立绘。后续对白保持 Hide。标题“第三幕——画室水桶解密后”和“接第三幕任务脚本”仅为制作说明，不显示为正文，不据此新增任务。

鱼缸后续 `FOLLOWUP_PAGES` 为第四幕 16 页普通对白，完整读完情节块 3 后经同一待续机制淡回客厅原位置播放。右侧主角立绘持续显示，Luna 为画外音；Luna 的“不，不，不。”与乱码数字台词两页配置 `shake = true`，复用共用对白及探索镜头震动。三遍相同的帐篷、小兔玩偶台词保持原图重复次序，不新增任务、音频、奖励或库存消耗；“第四幕”和“进解密”等制作标题、备注不作为正文。前置及情节块 3 使用 SEEK，`return_started` 后与第四幕保持 Hide。

`story_script` 通过脚本常量按需加载前置、正式、后续三组常规页，以及 `STORY_BRANCHES` 与 `RESISTANCE_PAGES`；未定义的页组按空数组处理。普通页格式由 StoryDialogue 解析；解谜演出额外读取 `cg_image`。当前水井将 AtlasTexture 区域作为 3508 x 2480 合成画布中的位置与尺寸，首次遇到各分镜时淡入并保留先前分镜。普通图片路径使用单图显示。情节块 2、3 的长段落按自然句分页，保留台词与旁白顺序，复用左键/Enter/空格/F 补齐和翻页及黑底、对白框的淡入淡出；情节块 2 前 28 页及情节块 3 等其余图片、雨声与新增演出待后续素材和需求。新增剧情结构若超出这些规则，需要同时扩展演出逻辑。

洗笔桶 `puzzle_definition` 使用稳定 A—E 库存映射；未持有选项隐藏，D 为小帐篷月影，E 为电影票镜面，四处名称与词同步。阶段 1—3 保留既有路由，D/E 相关新组合集中在阶段四。首次前置沿用实例 `INTRO`、`introduction_started` 与 GameState 标记机制。创世纪默认五页剧情复用普通交互、白色光晕与输入分发，每次从第一页开始。

## 移动、相机与显示效果

| 模块 | 实现及维护边界 |
| --- | --- |
| `player.gd`、`player.tscn` | `CharacterBody2D` 浮动模式，`Input.get_vector()` + `move_and_slide()`；脚底碰撞半径 19.5，默认速度 300、交互半径 65；`AnimatedSprite2D` 引用 `resources/art/characters/player_frames.tres` 的四方向行走与待机动画，各帧等比统一为 120 世界单位高，向右水平镜像朝左素材 |
| `main.gd` 相机 | `camera_view_size` 默认 1024 x 576 世界单位，按视口较小缩放因子等比适配；跟随脚底上方半身高，按 `camera_bounds` 限制，小于视野的轴居中 |
| `movement_bounds.gd` | `@tool` 生成物理外围；`outline` 有至少三点时建立闭合分段碰撞，否则使用 `area` 四边墙；`contains_body()` 为几何查询工具 |
| `whitebox.gd` | `@tool` 根据 `size/solid/oval` 重建碰撞，按 `artwork/artwork_size/artwork_offset` 绘图；有美术时隐藏占位文字，视觉尺寸与物理占地独立 |
| `shaders/studio_art_mask.gdshader` + `resources/art/studio/*_material.tres` | 按 SVG 轮廓遮罩采样画室原 PNG 对应区域，去除外围白底、保留内部白像素；遮罩同时提供给既有物件光晕 |
| `embedded_art_glow_proxy.gd` | 不绘制图片，向点击及光晕接口提供 `size/artwork/artwork_size/artwork_offset/oval`；走廊背景自带水渍借助透明遮罩复用现有高亮 |
| `interaction_glow.gd` + `shaders/interaction_glow.gdshader` | 懒创建独立光晕子层，按 PNG alpha/Atlas 裁区或矩形椭圆采样；依据 canvas 缩放保持屏幕亮边宽度；白色普通目标、幽蓝记忆目标，暂停随游戏冻结 |
| `pause_menu.tscn` + `shaders/pause_gaussian_blur.gdshader`、`pause_title.gdshader` | 冻结画面上水平/垂直两遍模糊，中间 BackBufferCopy，再叠加半透明 ColorRect、独立 Atlas 标题和图片按钮 |
| `settings_menu.tscn`、`settings_menu.gd`、`settings_slider.gd` | 复用两遍模糊和用户设置图片，三行可拖动纹理滑杆、右侧数值、重置及来源返回 |
| `scripts/ui/menu_hover_button.gd` | 保持 TextureButton 命中矩形，子图层承担悬停展开、淡入及按压回弹 |
| `LunarTitleFX/lunar_title.gd`、同名 shader、`lunar_title.tscn` | 主菜单标题单平面透视、鼠标平滑倾斜及程序扫光；每个实例独立 ShaderMaterial；可配置自动摆动与高光遮罩 |

100 世界单位约 1 米。玩家位置、出生点与 F 矩形使用脚底基准；绘制角色向上延伸。相机强制刷新后，UI 将世界提示投影到屏幕并限制越界。修改视野、物理尺寸和图像尺寸前分别核对其职责。

像素人物使用 `idle_up/down/left/right` 与 `walk_up/down/left/right` 八个动画名，原 PNG 位于 `assets/art/characters/player/`，源文件原尺寸与像素保留。AtlasTexture 仅裁透明留白，脚本按每帧裁区的实际高度等比缩放 `AnimatedSprite2D`，通过 `body_height = 120` 统一显示为 120 世界单位高，并供相机跟随参考。逐帧 `foot_anchor` 记录于 AtlasTexture metadata 与美术清单，缩放后仍按脚底锚点摆放，右向通过 `flip_h` 复用左向纹理。四方向待机以约 0.8 秒周期产生整数 2 世界单位的上下偏移，只影响可视层，碰撞、交互与脚底根位置保持。移动被模态或过渡锁定时，清零速度并切回当前朝向待机；暂停与回主菜单继续沿用会话冻结。原素材可见高度约 540–717，首次 1:1 接入后已调整为统一显示高度，各帧宽高比保留。2026-10-17 曾针对 150 高度版本通过 Godot 实例核对八个动画共 20 帧的统一高度与等比缩放、四向待机 2 世界单位幅度及原碰撞/交互参数，并查看卧室实际截图；手工移动衔接、多地图、交互流程与暂停未在本次验证范围内。

光晕视觉绑定当前依赖物件的 `size`、`artwork`、`artwork_size`、`artwork_offset`、`draw_placeholder`、`oval` 属性。改用新物件类型时应提供相同属性或补充适配。走廊 `CorridorWaterStain` 采用只提供属性的代理节点，背景图片保留原墙面水渍与小黑点，独立 SVG 遮罩仅用于轮廓光晕；原叠加 `CorridorWaterDrop` 白模已移除，查看交互锚点调整为 `(1036.8, 90)`。走廊地面一处与画室 `WetPatch` 使用共享地板水渍，画室位置随资产布局调整；一楼上方仓库、左侧通道和帐篷右侧三处继续使用 `first_floor_floor_stain.tres`，保留原位置、F 锚点、正文与无碰撞配置，客厅 `LivingRoomPuddle` 使用独立 `first_floor_kitchen_puddle.tres`，中心及查看锚点同步至 `(1263.5, 482.075)`。标题效果包含 `res://LunarTitleFX/` 的绝对资源引用，迁移目录时同步修改引用。素材文件及裁图维护细节见美术资产规范。

一楼第二批家具使用 `客厅厨房(2).zip` 的天然透明 4000×3000 原 PNG，通过 `resources/art/first_floor/` 内的 AtlasTexture 显示，按原图坐标乘 0.35 再加 `(35, 64)` 定位。鞋柜、地毯、挂画、两件沙发、餐桌、六把椅子、六只盘子、罐头、鱼缸与四处水渍已接入；北、南椅子原图各拆两块，保留六个独立 `DiningChair` 节点。鞋柜、沙发、鱼缸、餐桌与六把椅子的实体占地由独立隐藏 `Footprint` 节点维护，视觉尺寸独立配置。盘子和罐头为无碰撞桌面装饰，复用原餐桌查看正文；鱼缸继续通过 `InspectFishTank` 使用原 `cg_02` 门槛和独立谜题定义，电影票、钥匙、帐篷与门禁 ID 保留。电影票和其交互脚点横向对齐到南侧椅子 x=1051.75，原 y、剧情门槛与奖励保留。

2026-10-18 厨房与客厅七图继续使用同一 0.35 构图：窗、流理台、储物柜、厨房草稿纸、小帐篷、收纳盒及独立客厅水渍均通过现有 `whitebox` 的 `artwork` 接入，详细裁区、位置和尺寸见 [美术资产规范](art_assets.md#厨房与客厅七图补充)。窗复用外墙碰撞；流理台与储物柜采用主体矩形，小帐篷由隐藏 `SmallTentFootprint` 保留 `160×160` 椭圆实体，各自视觉尺寸分别维护。小帐篷 F 脚点为 `(593.075, 1005)`、局部矩形 `(-100, -15, 200, 35)`；草稿纸为 `(1235.85, 875)`，使用默认范围；储物柜为 `(1300, 835)`、局部矩形 `(-35, -65, 60, 110)`，收纳盒入口见上文。废纸篓占位移至 `(1310, 982)` 避开新纸张，原正文、奖励、门槛和稳定 ID 保留。该批接入时仅静态核对，未启动引擎、试玩或测试。

`DiningTableFootprint` 当前在 `(1083.425, 698.9)` 覆盖完整 `311.15×185.5` 桌面。`verification/player_scale/table_report.json` 记录四向接近均被餐桌阻挡，`InspectDiningTable` 与 `CollectMovieTicketMemory` 锚点可站立，`failures=[]`；该专项范围独立于完整交互剧情与其他家具验收。

两层 `Geometry/Stairs` 保留原实体范围、端点交互及出生点，图片分别按比例适配一楼宽 95 和走廊宽 100；原 Step 白模隐藏。一楼底部 y=407、走廊上端 y=240，`ToCorridor`、`ToFirstFloor` 的目标和往返出生点名称、坐标保持原配置。二楼纹理引用 `resources/art/corridor/corridor_stairs_down.tres`。2026-10-17 本次补入 21 张源图与关联资源，仅静态核对，未试玩、测试或执行 Godot 解析检查；实际显示、遮挡、通行和交互可达性待手工验收。

画室 `studio.tscn` 按来源 1360×1000 画布统一缩放 0.6，房间映射为 816×600，地板从 y=210 开始，活动边界为 `Rect2(18, 210, 780, 375)`。地板墙面用 AtlasTexture 拆层；白底物件与墙体由原 PNG、SVG 轮廓遮罩和画室材质组成。`whitebox.artwork` 绑定轮廓遮罩，材质负责原图采样，现有 `interaction_glow.gd` 继续从 artwork 获取真实轮廓。

`Easel`、`Stool`、`StorageShelf` 与新增 `PaletteSupportShelf` 的视觉尺寸按源图有效区域维护，各有独立隐藏 `Footprint` 节点负责底部碰撞。原 `PaletteTable` 改为无碰撞调色盘，画架清零旧旋转。四幅墙上画、三幅叠放画框及《创世纪》接入图片；返回门使用共享新门图，窗、草稿纸和报纸继续占位。`Interactables` 的原 ID、正文、钥匙/碎片与谜题路由保留，交互脚点随新布局迁移；返回门 `ToCorridor` 和出生点 `from_corridor` 名称保留，出生位置为 `(408, 520)`。

探索洗笔桶通过 `resources/art/studio/studio_brush_wash_bucket.tres` 显示天然透明 PNG 的 `(620, 511, 235, 245)` 区域，按反馈等比缩为约 `57.55102×60`；中心 `(486, 305)`、脚底 y=335，独立 `BrushWashBucketFootprint` 在 `(486, 314)` 保留 42×42 椭圆碰撞。F 交互脚点 `(521, 350)` 保留，光晕读取纹理 alpha。画室 `StorageShelfFootprint` 在 `(753.3, 449.4)` 覆盖 `87×271.2` 矩形，避免进入柜身。白底画室物件继续使用原遮罩材质，洗笔桶谜题背景、故事路由保留，月相 token 缩为 `144×144`。

小院 `courtyard.tscn` 的地面、围墙、水井、钥匙灌木和树使用 `resources/art/courtyard/` 中的 AtlasTexture，按 1360×1141 原画布统一 0.6 映射为 816×684.6；完整图只归档作参考。活动边界为 `Rect2(20.4, 18, 779.4, 666.6)`，原图顶部缺口保留，物理边界封闭。水井椭圆实体为 `(666, 97)`、`198×166`，树为 `(699, 609)`、`96×108`，`TreeTrunk.z_index=6` 高于玩家的 5，使树后角色被枝叶遮挡；灌木原实体保留；水井和灌木 F 脚点仍为 `(666, 215)` 和 `(134, 267)`。旧弯路、栏杆、底部植被与杂草白模叠层隐藏。

一楼左下 LowerRoom 的场景实例与入口已删除，主地板和外墙按上部及右下保留区拆 Atlas，原 PNG 保留。活动多边形经 `(446.95, 1047) → (446.95, 648.15) → (35, 648.15)` 围出新边界，`HallBottomWall` 与 `LivingLeftWall` 同步封边。最后的视觉细修将外侧 `LeftWall` 设为中心 `(31, 602.825)`、`8×90.65`，避免锁定仓库外侧残线；`LivingLeftWall` 保留 `8×398.85` 实体，图片独立为 `7.7×131.95`、偏移 `(7.85, -133.45)`，与原边框接合。`DiningOpenMagazine` 与其 `MagazineFold` 一并删除；餐桌四向 F 范围以桌心 `(1083.425, 698.9)` 的 `(-225, -175, 450, 350)` 配置，玄关挂画改为南侧 `(-95, -20, 190, 65)`，卧室门为 `(-95, -90, 140, 180)`。这些范围与物件实体分别维护。

2026-10-18 本轮反馈图形回归完成 94 项检查、失败 0，随后两项墙体接缝和树后遮挡细修又完成图形启动与截图复核。覆盖范围、报告和未验收项统一见 [项目状态](project_status.md#反馈表处理与本轮验证)，完整通关与音频听感仍待手工验收。

小院左下 `HouseDoor` 与画室 `CorridorDoor` 共用 `resources/art/shared/return_door.tres`，两处均显示为 `132×41.853659`、`z_index=2`。小院根位置 `(102, 672.6)`、碰撞 `132×24` 保留，图片偏移 `(0, -8.926829)`；画室根位置 `(408, 590)`、原大小 `132×12` 与 `solid=false` 保留，图片偏移 `(0, -14.926829)`。两处 Portal 的 F 脚点、目标及出生点保持原配置，小院交互脚点仍为 `(102, 638.4)`、`from_first_floor=(102, 598.4)`。`BushKey.acquisition_text` 保持“获得画室钥匙！快去看看吧”，收集继续复用原钥匙图标、稳定 ID 与去重流程。新门图、仓库、装置与票图的显示/裁区见 [美术资产规范](art_assets.md#返回门仓库装置与电影票)，该批接入时仅静态核对，未启动引擎、试玩或测试。

## 常用扩展步骤

### 新增地点与门户

1. 创建挂 `level.gd` 的地点场景，保留四个约定容器并设置 `level_id`、`display_name`、`camera_bounds`。
2. 配置 `MovementBounds.area/outline` 和 Geometry 占地，建立明确的 `SpawnPoints/<spawn_id>`。
3. 在来源地点 `Interactables` 的直接子节点中创建门户，配置目标 `res://` 路径、出生点、可选钥匙、局部 F 矩形和 `visual_path`。
4. 双向通路分别配置目标出生点；继续经 `change_level()` 加载。更新连接表与项目状态，按项目验证要求交付。

### 新增检查或收集物

1. 复用检查、照片、记忆物或钥匙脚本；行为确有差异时继承基类增加专用脚本。
2. 配置正文、展示图、稳定 ID、F 范围和视觉绑定；需要点击时提供 `contains_click()`。
3. 通过 GameState 方法收集，确认奖励发放时机、重复查看行为及弹层输入规则；美术替换继续分离显示和碰撞。

### 新增解谜入口

1. 创建独立定义资源，复用 `memory_puzzle_definition.gd` 与 `memory_option.gd`，配置独立 `puzzle_id`、选项、句型和反馈；按需在 `BY_PUZZLE` 添加有序组合路由，未定义路由的入口沿用旧答案字段。
2. 将选项 `fragment_id` 绑定实际来源，同步展示名与词牌；分别配置该入口的图像、水面、碎片矩形与容错、首次拖拽引导、浮词时机及剧情行为，维护单轮状态与共享配置分离。
3. 入口以持有 ID 列表快照调用 `GameUI.open_puzzle()`。需要前置对白时明确入口条件和已播放标记，复用水井、洗笔桶或鱼缸的时序。
4. 需要完整剧情后解锁时，用稳定的组合剧情 ID 与 `has_seen_memory_story()` 查询；正式 `STORY` 最后一页读完后经 `memory_story_completed` 写入会话状态。`restoration_succeeded` 保留演出开始事件语义。分支处理先经 `memory_story_branch_completed` 记录分支与后续目标，再发完整阅读事件，提前退出不更新；阶段四 `cg_04` 沿用该时序。持久存档需另行定义保存与恢复范围。

### 新增对白与存档

普通对白通过 `show_dialogue(pages)` 接入。创世纪的默认 `story_pages` 提供现有示例，演出震动使用页字段 `shake`。解谜前置、成功和后续页放入独立剧情脚本的对应常量；谨慎约定“启动”“读完”“还原成功”三种事件的标记时机。

存档接口目前预留。实现时需要显式选择序列化范围，例如 GameState 字典、当前地点身份与玩家位置，并通过现有加载和状态接口恢复；继续游戏现有行为只恢复内存实例。新增能力应同步更新本架构、项目状态及项目规范中的相关接口描述。
