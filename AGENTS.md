# demo2 / Lunar 开发约定

## 范围与阅读顺序

- 本文件仅适用于本目录及子目录。项目本机路径为 `D:/godot/demo/demo2`，项目显示名与 Git 仓库名均为 `Lunar`。
- 继承上层 `D:/godot/AGENTS.md` 的表达、Godot MCP 和测试偏好；优先遵循用户当前指令。
- 开始任务先读 [README](README.md)，按任务查阅 [架构说明](docs/architecture.md)、[项目状态与待办](docs/project_status.md)、[美术资产规范](docs/art_assets.md) 和 [音频资源规范](docs/audio_assets.md)。
- 以实际脚本、场景和资源核对实现。发现文档与文件不一致时说明差异；玩法和剧情调整以用户确认内容为准。
- 修改限定在任务涉及的模块，保留用户已有修改。新增功能、剧情、答案、道具消耗及美术生成按用户要求进行。

## 工具与验证

- 引擎为 `D:/godot/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64.exe`，运行入口为 `res://scenes/ui/main_menu.tscn`。
- 操作编辑器优先 `godot-ai`，调用前核对会话的项目绝对路径。连接不可用或需要独立命令行/批处理时使用 `godot-solo`。
- 同一次修改、保存和验证流程使用同一个 MCP。切换前保存场景、等待资源刷新并停止上一工具启动的游戏；禁止同时修改同一文件或重复启动同一游戏。
- `addons/godot_ai` 已在 `project.godot` 启用，并注册 `_mcp_game_helper`。调整插件时同步这些引用；本机 MCP 客户端配置不随项目提交。
- 常规功能开发不主动运行自动化测试、验证场景或试玩，手工测试由用户进行。用户明确要求测试或修复 bug 时，再按影响范围验证。
- 当前脚本使用 GDScript。后续 C# 修改需要 `dotnet build`，Godot AI 的文本编辑结果不代表 C# 编译通过。
- 文档修改只核对内容、链接与差异，无需运行引擎。`tests/` 中的历史验证脚本先核对当前接口与需求，再按需运行；保留源文件，生成物放忽略的 `verification/`。

## 场景与生命周期

- `scenes/ui/main_menu.tscn` 管理菜单、开场、暂停和游戏会话。新游戏完整播放开场并重建游玩实例；继续游戏优先恢复本次运行的内存实例，无会话时读取最近有效磁盘存档。
- `main.tscn` 保留 `GameState`、`BGM`、`World/Player`、`World/Camera`、`World/LevelHost` 和 `UI`。地点切换通过 `game.change_level()` 替换 `LevelHost` 内的地点，保持玩家、UI、BGM 和状态。
- `change_level()` 包含异步加载与淡入淡出，需要切换结果的调用方使用 `await`。旧地点的交互节点会释放，到达提示交给常驻主场景处理。
- 地点根节点使用 `scripts/level.gd`；沿用 `MovementBounds`、`Geometry`、`Interactables`、`SpawnPoints` 结构，以及 `level_id`、`camera_bounds` 配置。
- 可被主场景发现的交互节点直接放在 `Interactables` 下。门户配置目标场景与 `SpawnPoints/<spawn_id>`，新增或调整通路时同步往返出生点。
- 镜头视野由 `main.gd` 的 `camera_view_size` 管理，物理边界由 `movement_bounds.gd` 管理，家具与内墙另设碰撞；分别维护这些配置。

## 交互与状态

- 新交互继承 `scripts/interactable.gd`，沿用 `can_interact(context)`、`interact(context)` 和 `{game, player, state, ui}` 四个上下文键。
- F 交互以角色脚点选择范围内最近目标。`interaction_rect` 为相对交互锚点的局部矩形，空矩形使用角色默认距离；按需求配置可接近的锚点。
- 点击查看通过 `contains_click(world_position)` 接入现有分发；仅为需要点击交互的物件实现该接口。
- `visual_path` 绑定可见物件，交互范围与图片尺寸独立。普通目标为白色光晕，记忆收集物和解谜入口使用幽蓝色；收集后保留记忆物件的颜色。
- 收集与剧情标记通过 GameState 的 `collect_fragment`、`collect_key`、`mark_story_event_seen`、`mark_memory_story_seen` 等接口更新。碎片、钥匙、剧情事件及谜题 ID 保持稳定，重复奖励由状态接口去重。
- 门户只检查钥匙持有条件，现有钥匙不消耗；无钥匙保留“已上锁”提示，成功进入后不自动显示“已解锁”。状态跨地点保留，新游戏重置；已保存进度通过磁盘存档恢复。
- `restoration_succeeded(puzzle_id)` 在 CG 演出开始时转发，未写入谜题完成集合。完整读完正式组合剧情后，`memory_story_completed(story_id)` 经 GameUI 和 main 写入 GameState 的 `seen_memory_stories`；门槛使用稳定剧情 ID 与 `has_seen_memory_story()` 查询，前置对白、微剧情与提前 Esc 不记已读完，状态随新游戏重置。

## UI、对白与谜题

- 弹窗、CG、收集、对白和谜题通过 GameUI 的现有方法打开，维护 `modal_open`、`view_state_changed` 与关闭清理。
- 保持场景过渡、首次操作说明、模态输入的拦截顺序。Esc 优先关闭当前模态，一级探索界面再打开暂停；同次输入不连带触发下一层操作。
- 主菜单与暂停共用设置页；设置返回与 Esc 恢复来源页面，暂停来源保持游戏及音频冻结。`scripts/ui/game_settings.gd` 由菜单外壳持有，音效、音乐和亮度为 `0–100` 整数，默认 `100`，偏好独立保存至 `user://settings.cfg`；拖动实时应用，松开、返回、重置和退出时保存，新游戏保留设置。亮度统一通过菜单外壳的遮罩应用，保持最低约 40% 显示亮度。
- 当前以首次游玩键帽说明和物件光晕引导交互。场景内常驻“按F交互”提示已移除；剧情文字、字条和解谜阶段提示按现有规则显示。
- 水井、鱼缸、洗笔桶与帐篷收纳盒共用每局一次的拖拽引导，显示状态由 GameUI 的 `puzzle_drag_hint_seen` 管理。只有有可拖碎片并实际进入选碎片阶段时，才通过 `drag_hint_presented` 记录已显示；已配置前置对白先于引导，重试和重新进入不重复，新游戏重置。
- 拖拽引导保持非阻塞：可直接拖拽，首块成功投入后淡出；任意非 Esc 按键收起并消耗事件，Esc 继续退出谜题。样式与摆放复用 `memory_drag_hint.gd` 及定义中的 `drag_hint_target_name/drag_hint_rect`，按窗口等比适配并限制在视口内。
- 开场、普通剧情、谜题前置/正式/抵抗、第五幕及装置选择共用 `scripts/ui/story_dialogue.gd` 的纸张对白框；GameUI 的 `collection_panel` 与经 `show_collection()` 打开的物件查看复用 `scripts/ui/dialogue_paper.gd`。纸张资源为 `resources/art/ui/dialogue_paper.tres`，按 1920×1080 参考画布 `(37, 720, 1845, 291)` 等比居中适配；文字放安全区避开折角，保留项目字体、黑字、优先字号及长文缩字号规则。
- `prompt_bubble`、`note_bubble` 世界提示保留旧气泡素材及原点镜像修复；独立大图 `view_panel` 保留浅灰底，微剧情浮字、首次键帽说明、菜单图片文字及月光谜题各自样式保留。纸张替换继续维护分页、选择、奖励、立绘、震动与模态生命周期。
- 通用对白复用 `scripts/ui/story_dialogue.gd`，通过页数据配置 speaker、text、expression、shake 等字段。可选页配置 `choices: [{id, text}]`，正文显示完整后在底部纸张对白框显示编号文字选项，发出 `choice_selected(choice_id)`；选择页普通翻页不可跳过，选择前停用并清理控件，翻页和关闭清理焦点。主角首次出现后在本段对白中持续保留，Luna 使用画外音；不自行添加未提供的演出或声音。页震动由共用对白管理，翻页、结束或关闭时清理偏移。
- 水井、鱼缸、洗笔桶与帐篷收纳盒复用 `scenes/puzzles/memory_puzzle.tscn`，各自使用独立的 `MemoryPuzzleDefinition` 资源；优先配置现有字段扩展布局和行为。整图背景允许仅配置 `moon_environment`，`moon_well` 为可选叠加层。
- 四处记忆谜题 MOON 初始隐藏水面词与句槽，每投入一块仅显现对应词；Enter 后已投词统一飞出再进入 WORD。A—E 月相按原文件 5/4/3/2/1 从残到满绑定，稳定碎片与剧情 ID 保留；重置和退出清理显词及飞词 Tween。
- 谜题接收库存快照，尝试状态属于该实例；拖拽、失败重试和退出不消耗库存、不修改共享定义。组合剧情按 `memory_combination_stories.gd:BY_PUZZLE` 的谜题 ID 与左右有序 `choice_id` 匹配；配置 `template_id` 的路由还检查当前句型，阶段四独立启用可选 `sentence_templates`，前三处空列表保持原布局，实例深拷贝路由和待播数据；有路由定义时优先使用路由，旧答案字段只作无路由定义的兼容配置。
- 碎片名称与稳定 ID 分离维护：A/`bedroom_photo_01` 为港湾，B/`corridor_photo_02` 为涌泉，C/`memory_fragment_03` 为潮汐，D/`memory_fragment_04` 为月影，E/`memory_fragment_05` 为镜面。阶段四剧情编号依次为港湾 1、镜面 2、涌泉 3、潮汐 4、月影 5，编号独立于稳定选项 ID；镜面从完整 `cg_03` 后可收集的餐桌椅下电影票获得。阶段四五碎片与 20 条有序路由独立配置，前三处保留原路由，E 同步展示名及词牌“镜面”，没有新增 E 组合。
- 月相碎片接收范围使用绝对参考坐标 `fragment_drop_rect` 与 `fragment_drop_margin`，当前四处谜题覆盖整个目标物体外接矩形并各加 24 像素参考容错。`moon_water_rect/water_drop_polygon` 继续管理水面效果和词语拖回取消；调整碎片接收范围不放大图片、涟漪、浮词或词槽。`Water._has_point()` 与 `_can_drop_data()` 保持一致的范围、实例和阶段校验。
- 微剧情在当前谜题背景上直接浮现文字，读完返回选碎片阶段并保留库存与共享引导标记，不发出完成事件或衔接后续对白。前三处 CG 完整读完后返回探索并衔接各自 `FOLLOWUP_PAGES`；阶段四同黑屏衔接第五幕。洗笔桶后续旁白与鱼缸第四幕对白沿用 GameUI 普通对白，每页显示右侧主角立绘，Luna 使用画外音；情节块 2、3 正式回忆继续关闭立绘，按页显示 CG 或黑底。情节块提前 Esc 不接后续，关闭或重置时清理拖拽、浮现 Tween、临时控件与待播放内容。
- 洗笔桶与鱼缸前置对白分别以 `brush_wash_memory_intro`、`fish_tank_memory_intro` 记录本局已开始，实际播放时记标记，提前退出保留，新游戏重置。鱼缸另要求完整读完 `cg_02`；无匹配碎片或未满足剧情门槛时查看静水正文且不记鱼缸前置标记。储物间钥匙在玄关花盆里，`PlantStorageKey` 沿用完整 `cg_04` 门槛，条件未满足时无交互高亮；地毯保留原查看。鱼缸后的第四幕普通对白不等同于 `cg_04`。四处句型、布局和组合剧情独立维护；待补画面、美术和制作人员页面见项目状态文档。

- 帐篷收纳盒要求完整 `cg_03` 与匹配碎片，首次三页前置对白以 `tent_storage_memory_intro` 记录已开始，提前退出保留，新游戏重置。阶段四仅配置 `template_id=3`“【A】从【B】中涌现”，不显示切换按钮或响应 Tab；20 条有序路由包含 18 条用户微剧情与两条正式分支。月影→潮汐直接进入 Luna 正式回忆；连续三次潮汐→月影进入真实正式回忆，前两次不同幅度震动、词牌归位并播放 Luna 对白，保留投入与库存。确认其他组合清零计数，退出重建实例后重新计算。正式分支完整读完才发出 `memory_story_branch_completed` 和 `memory_story_completed`，记录导向、后续剧情 ID 及 `cg_04`；提前退出保留原记录。正文沿用黑底、关闭立绘，Luna 单幅与真实三格 CG 按页元数据展示，乱码内容仍待提供，不自行补写。
- 第五幕正文集中在 `scripts/ending_story.gd`。GameUI 在完整 `cg_04` 后同黑屏衔接 `cg_05_false` 假结局正文或 `cg_05_true` 真结局前 CG；真回忆完整读完后返回探索并提示玄关花盆钥匙。一楼 `StorageRoomGate/OpenStorageRoom` 原地开门，不消耗钥匙，以 `storage_room_opened` 跨地点重载恢复；装置要求门已开、完整 `cg_05_true`、最近 `cg_04=truth` 且玩家进入房内。装置底部两选项分别进入真结局 `end2` 与假结局 `end1`。完整结局正文结束后才写入 GameState 的会话结局记录并进入黑屏终局，按钮/Esc 返回主菜单，继续恢复终局；支持五槽位磁盘存档。第五幕提前 Esc 不记未读完内容，可重新完成阶段四分支或重进装置。

## 磁盘存档

- 主菜单载入与暂停保存／读取共用五槽位界面，F5/F9 分别打开保存／读取。`scripts/save_manager.gd` 独立管理 `user://saves/slot_N.json`，槽号 1–5；名称可编辑，覆盖和删除由界面确认。继续优先内存会话，无会话时加载最近有效磁盘存档。
- `GameState`、main、GameUI、StoryDialogue、记忆谜题及音频组件通过 `export_save_data()/import_save_data()` 保存稳定 ID、位置、时长、当前界面／谜题阶段、正式 CG 页与音频断点。恢复不重复发奖励或记完整阅读；动画保存为稳定检查点，地点切换中暂不保存。读档以新候选实例恢复成功后替换旧会话，失败保留旧进度。
- 版本化 JSON 仅允许原始值，校验格式、大小、深度、有限数值、地点及进度字段；同目录临时文件完整写入后重命名替换，坏档占用原槽并显示错误。设置偏好仍独立保存在 `user://settings.cfg`。
- `resources/saves/fragment_4.json` 随仓库分发，首次安装至首个空槽并写持久标记，全满不覆盖，删除后不重复安装。预设含全五碎片、完整 CG01–03 和第四谜题 MOON 待操作状态，不写 CG04、分支或结局完成。
- CG 页元数据由 `story_cg_view.gd` 统一展示：`cg_image` 累积分镜，`cg_replace=true` 清旧换图，`cg_clear=true` 清屏；保持原图画布与 Atlas 相对位置。章节、退出和恢复时清理旧 Tween，恢复累计至当前页，不重播完成信号。

## 音乐、环境声与音效

- 按用户 `配乐都放在哪呢.docx` 维护音乐分配与触发时序；该说明覆盖旧 Hide/SEEK 分配和主菜单静音约定。22 份新 WAV 保留原字节，14 份循环、8 份单次；旧 Hide/SEEK 与 `gameplay_bgm.tres` 保留为历史未使用资源。
- 游戏根 `BGM` 使用 `bgm_controller.gd`，音乐、地点白噪音与 CG2 大雨各有独立双播放器淡化通道，脚步、uplifter 和短音效另行播放。公开 `start_or_resume/suspend/stop/set_context/set_environment/set_walking/play_sfx`；切换默认 0.75 秒，探索曲与水池曲保留共同时间，其他曲目按明确剧情 cue 切换。白噪音与雨声循环边界通过双声部交叉淡化，默认同为 0.75 秒。
- 主菜单外壳独立 `MenuAudio` 播放“主界面+解密”，不播放地点白噪音；新游戏淡出菜单曲，加载失败恢复菜单配乐；开场未增加配乐与环境声，卧室淡入结束后启动游戏音频。探索与普通对白使用探索曲，四处谜题的前置、操作、微剧情和抵抗对白使用“水池”，正式 CG 与真假结局按音频规范分配。
- 保留 CG2 雨声整段叠加和指定页切曲、CG3 uplifter 结束时截断并记录位置/播放水滴/指定页续播，以及真回忆“引子”单次完整播放的锁定。引子结束且已离开真回忆后恢复最新场景曲目，快速翻页及提前退出不截断；快速重进真实分支触发的新一轮引子排队，旧一轮完整播完后再播，避免丢失新触发；页 cue 深拷贝至实例，避免修改共享剧情数据。
- 室内外白噪音在相应地点的探索、谜题与 CG 持续；实际位移启停对应脚步。成功通过房门或打开仓库触发开门声，楼梯不触发；月相投入与显词可叠播，菜单图片按钮接点击/选中声。全部环境声和音效输出至 `SFX`，音乐输出至 `BGM`，共同汇入 `Master`，设置滑杆按线性增益独立控制。
- 暂停与回主菜单显式冻结全部游戏音频及淡化时间，继续同位置恢复；返回菜单后播放外壳菜单曲。新游戏重建游戏音频状态。原文件、循环、基准音量和页索引遵循音频规范，静态核对及语法解析不代表听感已验收。

## 资源与交付

- 运行资源存放在项目内并使用 `res://` 引用。运行文件名用英文小写与下划线；现有 `LunarTitleFX/` 为已接入的独立模块，移动时同步脚本和场景引用。
- 图片、AtlasTexture 显示区域、实体占地、碰撞、遮挡层级和交互锚点分别维护。`whitebox.gd` 的 `artwork*` 控制显示，`size`、`solid` 控制物理占地。
- 沿用约 100 世界单位/米的尺度。替换美术保持角色、家具和通道的尺度关系；缺少素材的物件继续使用白模或代码占位。
- 字体通过 `ui_font.tres` 引用项目内寒蝉点阵体；具体过滤、导入、裁图、来源清单要求见美术资产规范。
- 美术导入或替换时更新 `assets/art/manifest.json` 中对应来源、路径、区域及校验信息。保留必要 `.uid`、资源和 `.import` 设置，忽略 `.godot/` 与验证输出。
- 音频独立维护 `assets/audio/manifest.json` 与 `docs/audio_assets.md`，运行引用项目内 `res://assets/audio/`；微信来源路径不作为运行依赖，原文件字节保持。
- Git 根目录是本目录，交付完整项目。未经要求不创建提交、推送、发布或变更仓库配置。

## 文档维护

- 架构、接口或生命周期变化同步 `docs/architecture.md`；完成情况、占位与待办变化同步 `docs/project_status.md`；美术资源约定变化同步 `docs/art_assets.md`，音频资源和切换约定变化同步 `docs/audio_assets.md`。
- README 保持运行与导航简洁。AGENTS 保留稳定约束，任务清单放状态文档，避免将单次工作日志长期叠加到规范中。
- 项目本机路径、入口或工作约定变化时，同步 `D:/godot/AGENTS.md` 和 `D:/godot/demo2_交接说明.md` 的对应信息。
- 状态文档记录核对日期、依据和待确认事项。区分静态核对与实际验证，保留验证范围和未验证项。
