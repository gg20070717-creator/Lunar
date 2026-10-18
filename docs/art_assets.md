# 美术资产规范

本规范仅适用于 `D:/godot/demo/demo2`（Lunar）。开发规则见 [AGENTS.md](../AGENTS.md)，模块职责见 [项目架构](architecture.md)，完成情况与待办见 [项目状态](project_status.md)，项目入口见 [README](../README.md)。本文维护美术来源、导入、显示和替换约定；当前配置以对应场景、脚本及资源文件为准。

## 目录与职责

所有游戏用资源必须位于 demo2 项目内，场景通过 `res://` 引用。资源文件使用英文小写及下划线，名称表达用途与身份；替换图片时保持路径和 ID 稳定。

| 路径 | 内容 |
| --- | --- |
| `assets/art/environments/<scene>/backgrounds/` | 场景地板、墙面、边框及背景层 |
| `assets/art/environments/<scene>/props/` | 对应场景的家具、门窗、照片框等物件图片 |
| `assets/art/environments/<scene>/decals/` | 后续增加的无碰撞地面贴花、污渍等 |
| `assets/art/environments/studio/masks/` | 画室白底物件与墙体的 SVG 轮廓遮罩，供显示材质和交互光晕共用 |
| `assets/art/environments/courtyard/references/` | 小院完整合成参考图，单独归档，运行画面不叠加 |
| `assets/art/shared/props/` | 多个场景实际共用的同一张物件图片，保持一份 |
| `assets/art/shared/decals/` | 走廊与画室共用的地面水渍图片，一楼使用专属素材 |
| `assets/art/characters/<character>/` | 人物、朝向及动画图集 |
| `assets/art/ui/icons/`、`assets/art/ui/panels/` | 背包图标、按钮、界面边框 |
| `assets/art/ui/main_menu/`、`assets/art/ui/pause_menu/` | 主界面与暂停界面的配套素材 |
| `assets/art/ui/settings_menu/` | 主菜单与暂停共用的设置底板、拖动组件、按钮及完整参考图 |
| `assets/fonts/` | 游戏文字字体文件与 Godot 导入设置 |
| `assets/art/cg/<act>/` | 剧情插画、全屏照片及分镜 |
| `assets/art/puzzles/<puzzle>/backgrounds/` | 独立解谜界面的整图背景或环境、物件分层图片；参考图单独归档 |
| `assets/art/puzzles/<puzzle>/effects/<effect>/` | 对应解谜的透明特效序列，帧号使用四位数字 |
| `assets/art/puzzles/shared/moon_fragments/` | 四处谜题共用的五张原始透明月相 PNG，按 A—E 从残到满绑定 |
| `resources/art/<scene>/` | AtlasTexture 区域、SpriteFrames 等引擎资源配置 |
| `scenes/props/` | 后续需要复用的物件场景，组合图片、碰撞和交互节点 |
| `assets/art/manifest.json` | 资产清单：稳定 ID、中文原名、项目路径、尺寸、区域及 SHA-256 |
| `LunarTitleFX/` | 已接入主菜单的标题组件、`assets/title.png` 与专用 shader，保留整套相对路径 |

以上是按需建立的目录约定。当前 bedroom、corridor、first_floor、studio、courtyard 已建立背景、物件及相关显示资源目录；探索像素人物、主角对白立绘、第一幕 CG、情节块 2 窗边 CG、CG3／CG4 与真假结局插画、水井、鱼缸、洗笔桶与帐篷收纳盒解谜背景、菜单及字体也已接入。新增分类在收到对应素材时建立。

命名示例：`bedroom_bookshelf.png`、`player_walk_down.png`、`act_01_memory_01.png`。方向/动画/帧号按需要追加，如 `player_walk_down_01.png`。不使用空格、临时名称、中文运行时路径或 `最终版2` 之类的后缀。美术原文件可继续用中文名，交付清单保留中文对照。

PSD、Aseprite、设计稿及历史版本放在项目外的团队美术源文件目录，运行项目仅放需要的导出资源。Godot 自动生成的 `.godot/` 缓存不提交；PNG 对应的 `.import` 设置文件随项目保留。

未获得用户明确授权时，继续使用已有素材或已确认的占位，不生成、下载或重新设计美术，也不补写缺失剧情。资产接入时同步 manifest；美术说明更新在本文，功能状态更新在 `project_status.md`。

## 游戏字体

用户提供的 `ChillBitmap_16px.ttf` 原样保存为 `assets/fonts/chill_bitmap_16px.ttf`，中文字体名为“寒蝉点阵体 16px”。`ui_font.tres` 作为统一 FontVariation 引用项目内的 FontFile，覆盖键帽操作说明、字条、剧情对白与正文、获得提示、水井、鱼缸及洗笔桶解谜的提示与词卡，以及场景占位文字；菜单按钮、设置页静态文字及暂停标题使用图片字形，设置页数值引用 `ui_font.tres`，主菜单标题使用 `LunarTitleFX` 的图片与 shader。

字体不依赖系统安装，导入时关闭抗锯齿、子像素定位和系统字体回退，保留原字体数据。普通剧情、收集与查看沿用纯黑文字和原字号，底衬使用下述纸张图片框；其余文字样式继续由 `scripts/ui_text_style.gd` 等现有 UI 配置管理。水井、鱼缸与洗笔桶启用 `moonlight_ui_enabled`，使用浅灰蓝文字、轻微深影与低强度青蓝柔光；其 `ui_backing_enabled = false`，保留透明键帽和薄弧光词槽。各类 UI 都继续引用 `ui_font.tres`，替换字体时保持路径并保留各自字号及样式。原文件名、项目路径及 SHA-256 记录在资产清单。

## 探索像素人物

用户提供的 `像素小人.zip` 位于 `D:/微信/聊天记录/xwechat_files/wxid_n5xuklyzkxa321_cfaf/msg/file/2026-10/像素小人.zip`。其中上、下、左三个朝向各含一张待机和两张步态 PNG，共九张，原始文件字节、透明通道和像素保留在 `assets/art/characters/player/`。游戏通过项目内资源引用，原 ZIP 路径仅记录来源。

| 朝向 | 项目 PNG | 动画 |
| --- | --- | --- |
| 上 | `player_up_idle.png`、`player_up_step_01.png`、`player_up_step_02.png` | `idle_up`、`walk_up` |
| 下 | `player_down_idle.png`、`player_down_step_01.png`、`player_down_step_02.png` | `idle_down`、`walk_down` |
| 左 | `player_left_idle.png`、`player_left_step_01.png`、`player_left_step_02.png` | `idle_left`、`walk_left` |
| 右 | 复用左向三张纹理，显示节点设置 `flip_h` | `idle_right`、`walk_right` |

`resources/art/characters/player_frames.tres` 用 SpriteFrames 集中管理八个动画，`scenes/player.tscn` 的 `AnimatedSprite2D` 接入。AtlasTexture 只裁透明边，不改源图；图片使用无损导入、最近邻过滤、关闭 mipmaps，源 PNG 保留原尺寸与像素。脚本按每帧裁图的实际高度等比缩放显示节点，以 `body_height = 120` 统一为 120 世界单位高，各帧宽高比保留。逐帧 `foot_anchor` 记录在 AtlasTexture metadata 与美术清单中，供缩放后的脚底定位与静态核对；右向行走和待机均使用左向素材水平镜像。

四方向待机采用约 0.8 秒周期的整数 2 世界单位上下颤动，只移动可视层。脚底根位置、半径 19.5 的圆形碰撞、移动速度 300 与 F 交互半径 65 保留；`body_height = 120` 同时作为相机跟随参考。各源图裁去透明边后的可见高度约 540–717，首次按 1:1 原像素大小接入，后续已调整为每帧统一显示高度，源文件原尺寸与比例继续保留。移动锁定时仍进入当前方向待机，暂停与回菜单沿用会话冻结。

来源、项目路径、裁区与 SHA-256 记录在美术清单。2026-10-17 曾针对 150 高度版本通过 Godot 实例核对八个动画共 20 帧的统一高度与等比缩放、四向待机 2 世界单位幅度及原碰撞/交互参数，并查看卧室实际截图；手工移动衔接、多地图、交互流程与暂停未在本次验证范围内。

## 本次卧室资产

已原样复制用户提供的 10 张 PNG，透明通道与原始像素均保留。它们使用同一套 1360×870 画布，每张图包含不同位置的物件；通过 AtlasTexture 选择有效区域，避免透明留白影响缩放和摆放。

| 原文件 | 项目文件 | 接入位置 |
| --- | --- | --- |
| 地板墙面.png | `backgrounds/bedroom_floor_wall.png` | 分为地板和后墙两个区域 |
| 墙体.png | `backgrounds/bedroom_wall_border.png` | 分为上下左右边框，右侧保留门洞 |
| 书架.png | `props/bedroom_bookshelf.png` | 左侧书架 |
| 台灯.png | `props/bedroom_desk_lamp.png` | 桌面，无独立交互或碰撞 |
| 床.png | `props/bedroom_bed.png` | 右下床，图片自带枕头和地毯 |
| 桌子.png | `props/bedroom_desk.png` | 左下桌子 |
| 椅子.png | `props/bedroom_chair.png` | 桌子右侧椅子 |
| 照片.png | `props/bedroom_photo_frame.png` | 书架上的照片物件 |
| 窗户.png | `props/bedroom_window.png` | 上方窗户 |
| 门.png | `props/bedroom_door.png` | 右侧卧室门 |

表中项目文件均位于 `assets/art/environments/bedroom/`。照片.png 是场景中的照片框图，当前照片交互继续使用已确认的正文→获得提示流程。字条已使用下述 10.15 素材；探索角色已接入上述像素人物，未提供对应素材的物件继续使用现有占位，对白主角使用下述四张立绘。

## 10.15 字条、对话框、钥匙与水渍

源文件位于 `D:/godot/素材/10.15/素材`，来自 `素材(2).zip`；同目录的 `素材(1).zip` 与该压缩包内容一致。五张 PNG 原样复制到项目，保留原始像素与透明通道，通过 AtlasTexture 裁去透明留白。来源、原名、区域与 SHA-256 已记录在 manifest。

| 原文件 | 项目图片 | Atlas 区域 `(x, y, w, h)` / 资源 |
| --- | --- | --- |
| 字条.png | `assets/art/environments/bedroom/props/bedroom_note.png` | `(12, 43, 169, 93)`，`resources/art/bedroom/bedroom_note.tres` |
| 对话框.png | `assets/art/ui/panels/dialogue_bubble.png` | `(24, 20, 171, 129)`，`resources/art/ui/dialogue_bubble.tres` |
| 钥匙.png | `assets/art/ui/icons/key_icon.png` | `(9, 55, 166, 64)`，`resources/art/ui/key_icon.tres` |
| 水渍/地板水渍/插画4.png | `assets/art/shared/decals/floor_stain_01.png` | `(12, 114, 164, 37)`，`resources/art/shared/floor_stain_01.tres` |
| 水渍/地板水渍/插画5.png | `assets/art/shared/decals/floor_stain_02.png` | `(24, 156, 124, 25)`，`resources/art/shared/floor_stain_02.tres` |

卧室桌上字条的显示尺寸为约 `27.258065×15` 世界单位，清空白模标签；原物件占地与交互配置保留。钥匙收集默认绑定共享 `key_icon.tres`，预览的 `key` 回退分支同样使用此图，继续等比显示并保留去重及持有规则。

10.15 对话框素材通过 `scripts/ui/dialogue_bubble.gd` 继续用于 `prompt_bubble`、`note_bubble` 世界提示。图内正文安全区为左侧 16%、顶部 18%、宽 68%、高 58%，世界提示按镜头投影后限制在游戏视口四边内，靠近左右边缘时调整摆放并水平翻转尾巴。常规剧情、收集与查看已接入下述独立纸张对白框，继续保留黑字、分页与独立立绘，正文适配沿用 `DialogueBubble.fit_text()`。月光谜题、微剧情、独立 CG 图片灰色底板和首次键帽说明维持各自样式。

气泡尾巴朝右时，绘制矩形仍以局部 `(0, 0)` 为原点，仅将宽度改为负值进行水平镜像，框体与正文安全区保持对齐。2026-10-17 曾修复镜像额外右移一个框宽的问题，并对当时使用气泡底图的开场完成专项验证；该历史记录见项目状态文档。当前世界提示保留该镜像修复，PNG、Atlas 裁区和剧情配置保留。随后曾将开场与通用对白恢复为白色矩形底框，参考位置 `(58, 800)`、尺寸 `1804×248`，收集和查看保留白色/浅灰矩形；该次恢复仅静态核对。历史气泡专项验证与矩形恢复记录不覆盖本次纸张图片框，世界提示边缘摆放继续单独验收。

走廊背景原图已包含墙面水渍与其旁的小黑点，已移除叠加的水滴白模。`scripts/embedded_art_glow_proxy.gd` 只向点击与高亮接口提供尺寸和透明遮罩，不绘制额外水渍；`corridor_native_water_stain_mask.svg` 对应背景原图区域 `(1648, 16, 152, 160)`，用于现有白色轮廓光晕。走廊一处地面水洼和画室 `WetPatch` 继续使用共享地板水渍，保留无碰撞与既有交互；一楼原四处曾统一接入下节 `客厅厨房(2).zip` 的配套水渍，当前客厅一处已换为后续独立新图，其余三处继续使用第二批素材。10.15 两张共享原图与资源保留。画室水渍随下述资产布局调整位置，继续使用最近邻过滤。水渍目录中的三张墙面素材留在源目录，当前无对应待替换白模。

该批接入时只核对文件、资源引用与 Git 差异，未启动游戏、验证场景或自动化测试，未进行音频试听；气泡边缘摆放、长文本与水渍高亮待用户手工确认。

## 纸张对白框

2026-10-18 接入用户提供的 `对话框.png`，来源为 `D:/微信/聊天记录/xwechat_files/wxid_n5xuklyzkxa321_cfaf/msg/file/2026-10/对话框.png`，原字节复制至 `assets/art/ui/panels/dialogue_paper.png`。原图为 1920×1080 RGBA，alpha 范围 0–255，非零 alpha 外接矩形为 `(37, 720, 1882, 1011)`；来源、路径、尺寸、透明范围与 SHA-256 记录在 manifest。该图与上节 10.15 世界提示气泡分别归档。

`resources/art/ui/dialogue_paper.tres` 通过 `AtlasTexture` 取区域 `Rect2(37, 720, 1845, 291)`，启用 `filter_clip`。原 PNG 保留完整画布与透明像素，裁图仅在资源显示区域生效。图片使用无损导入、线性过滤并关闭 mipmaps，保留 `.import` 设置。

开场、普通剧情、黑底 CG 正文与装置对白使用 `StoryDialogue`，普通物件查看和收集使用 `GameUI.collection_panel`，两者通过 `scripts/ui/dialogue_paper.gd` 共用同一纸张 `TextureRect` 皮肤。1920×1080 参考画布中，图片位置为 `(37, 720)`、尺寸 `1845×291`，随窗口等比适配并居中。文字保持项目字体、原字号和黑色，正文与提示布局放在纸张内部，长文字继续按可用区域适配。

以下坐标均相对纸张裁图左上角；后续布局以共用皮肤和调用方配置为准：

| 区域 | 参考矩形 `(x, y, w, h)` |
| --- | --- |
| 文字安全区 | `(48, 24, 1688, 242)` |
| 说话者 | `(48, 24, 1688, 42)` |
| 有说话者时的正文 | `(48, 78, 1688, 154)` |
| 无说话者时的正文 | `(48, 40, 1688, 192)` |
| 底部继续提示 | `(48, 242, 1688, 30)` |

带大图的收集和分镜 CG 将上方图片区限制在纸张顶部 y=720 以上，并继续等比显示。主角立绘、翻页与选择逻辑沿用现有配置；微剧情浮字、世界提示 `dialogue_bubble`、独立大图灰色底板和首次键帽提示保留各自素材及样式。

该批接入时仅静态核对源 PNG、原字节复制、SHA-256、透明数据、Atlas 裁区、导入配置与资源引用；未启动 Godot、游戏、验证场景或自动化测试。纸张边缘、长段正文、立绘遮挡、选项和窗口适配待用户手工验收。

## 一楼与走廊资产

用户提供的 `客厅厨房(1).zip` 与 `走廊(1).zip` 共 13 张 PNG 原样保存，中文原名、画布、区域和 SHA-256 记录在 manifest。所有运行资源引用项目内路径，原 ZIP 与中文源文件留在项目外。

| 场景 | 原文件 | 项目文件 / 位置 |
| --- | --- | --- |
| 一楼 | 地板墙面.png | `backgrounds/first_floor_floor_wall.png`，大厅与厨房地板墙面；运行裁图已排除左下房间，左上仓库使用独立图片 |
| 一楼 | 墙体.png | `backgrounds/first_floor_wall_border.png`，外轮廓、墙返及房间边框 |
| 一楼 | 大门.png | `props/first_floor_courtyard_door.png`，玄关上方，保留院子入口 |
| 一楼 | 毯子.png | `decals/first_floor_shoe_mat.png`，大门下方鞋垫，无碰撞 |
| 一楼 | 凳子.png | `props/first_floor_stool.png`，鞋垫左侧，仅凳脚处有碰撞 |
| 走廊 | 墙壁地面.png | `backgrounds/corridor_floor_wall.png`，墙面和地板分别裁片铺设 |
| 走廊 | 墙体.png | `backgrounds/corridor_wall_border.png`，边框按楼梯口拆开 |
| 走廊 | 门1.png | `props/corridor_bedroom_door.png`，左侧卧室门 |
| 走廊 | 门2.png | `props/corridor_studio_door.png`，上墙画室门，保留钥匙判定 |
| 走廊 | 照片1.png | `props/corridor_photo_frame_left.png`，画室门右侧第一张 |
| 走廊 | 照片2.png | `props/corridor_photo_frame_middle.png`，中间竖框 |
| 走廊 | 照片记忆碎片.png | `props/corridor_memory_photo_frame.png`，右侧记忆照片，提供“涌泉”碎片，稳定 ID 为 `corridor_photo_02` |
| 走廊 | 花盆.png | `props/corridor_flower_pot.png`，右端楼梯上方，仅盆底有碰撞 |

表中 PNG 位于 `assets/art/environments/<scene>/`，AtlasTexture 位于 `resources/art/<scene>/`。图片无损导入、关闭 mipmaps，场景采用最近邻过滤。原图像素和透明通道保留；走廊照片和画室门存在低透明度散点，Atlas 只截取主体，避免无关透明区挤占显示尺寸。

一楼首批五层共用 4000×3000 画布，按 0.35 等比缩放并偏移 (35, 64)。大门中心约 (539.7, 140.125)，鞋垫约 (526.225, 248.625)，凳子在其左侧。左上储物间已接入独立仓库图片；左下 LowerRoom 的地板、墙、窗、书柜及原实例按反馈删除。主地板与墙体分别裁为上部 `(0, 0, 4000, 1669)` 和右下保留区：地板 `(1177, 1669, 2823, 1139)`、墙体 `(1177, 1669, 2823, 1137)`。原 PNG 字节保留，`HallBottomWall` 与 `LivingLeftWall` 在世界 x=446.95、y=648.15 的转角封闭新边界。右上楼梯位于凹口，下端 y=407、到达脚点 `(1387.5, 467)` 保留。

走廊横坐标按 `x = 0.6 × 原图 x + 2.4` 排列，墙面保留 200 高，步行地面为 1360.8×168。家具图片等比显示，画室门按人物高度单独定为 180 高。记忆照片交互脚点 (574.5, 115)，画室门脚点 (379.5, 120)，楼梯上端 (1316, 240)，从一楼返回落在 (1316, 190)。凸出楼梯与上一轮上下端交互方向保留；两层楼梯、沙发和餐桌椅已补齐第二批素材，厨房与客厅七图补充见后文。

### 客厅厨房第二批资产

2026-10-17 核对用户提供的 `客厅厨房(2).zip`，其中 21 张 PNG 的 SHA-256 在接入前的 manifest 中均无匹配，首批 `客厅厨房(1).zip` 已接入的地板墙面、墙体、大门、鞋垫与小凳子保留。新增原图均为天然透明的 4000×3000 PNG，原文件字节复制到项目，中文原名、来源、裁区和校验同步 manifest；运行资源统一使用 `res://` 引用。

| 资产组 | 本批原图数量 | 接入与显示 |
| --- | --- | --- |
| 一楼楼梯、二楼楼梯 | 2 | 保留既有实体范围与端点门户，图片按比例适配一楼宽 95、走廊宽 100；原 Step 白模隐藏 |
| 鞋柜、地毯、挂画 | 3 | 按共同画布定位；地毯只取主组件 `(2041, 620, 568, 423)`，排除远处 36 像素杂点 |
| 沙发 | 2 | 两件独立家具，等比显示 |
| 椅子 | 4 | 北、南两张各含两把椅子，分别拆左右 AtlasTexture，另两张各一把，保留六个 Chair 节点 |
| 盘子、罐头、餐桌 | 8 | 六张盘子、一张罐头与一张餐桌，盘子和罐头无碰撞，复用原餐桌查看正文 |
| 探索鱼缸、水渍 | 2 | 鱼缸沿用原交互与谜题；接入时一张配套水渍复用于原四处，当前客厅一处由后续新图替换 |

二楼楼梯原图归档为 `assets/art/environments/corridor/props/corridor_stairs_down.png`，由 `resources/art/corridor/corridor_stairs_down.tres` 接入。其余 20 张 PNG 位于 `assets/art/environments/first_floor/props/` 或 `decals/`，AtlasTexture 位于 `resources/art/first_floor/`；本批合计 23 个 AtlasTexture。家具按照 `世界坐标 = 原图坐标 × 0.35 + (35, 64)` 定位，鞋柜、沙发、鱼缸、餐桌与六把椅子的实体占地由独立隐藏 `Footprint` 节点维护，图片裁区、显示尺寸、碰撞和交互脚点分别配置。两层楼梯的原端点保持：一楼下端 y=407，走廊上端 y=240，目标场景和往返出生点名称、坐标均保留。

第二批接入时，一楼四处地板水渍共用 `resources/art/first_floor/first_floor_floor_stain.tres`，宽度依次为 125、110、115、95，高度按素材有效区域的 638:269 比例等比显示。当前上方仓库、左侧通道和帐篷右侧三处继续保留该资源、原位置/F 锚点/正文与无碰撞配置，宽分别为 125、110、95；`LivingRoomPuddle` 使用后续厨房新水渍。原 10.15 共享水渍仍服务走廊和画室。

餐桌独立 `DiningTableFootprint` 已扩大到可见桌面尺寸 `311.15×185.5`。Godot 专项运行已核对四向阻挡，以及餐桌/电影票锚点可站立，`verification/player_scale/table_report.json` 的 `failures=[]`；其他家具与完整交互剧情继续按各自范围验收。

探索鱼缸继续绑定 `InspectFishTank`，保留完整 `cg_02` 与匹配碎片门槛，原前置、后续、组合剧情和独立谜题布局保持。电影票、钥匙、帐篷与储物间门禁沿用现有稳定 ID 和流程。植栽与废纸篓等缺少源图的物件继续占位；厨房柜台、帐篷等已补入下述七图，电影票与储物间另有后续资产接入。本批仅静态核对来源、文件、资源引用和差异，未试玩、测试或执行 Godot 解析检查；比例、遮挡、光晕、通行与交互可达性待用户手工验收。

### 厨房与客厅七图补充

2026-10-18 接入用户提供的七张天然透明 4000×3000 PNG，原字节归档在 `assets/art/environments/first_floor/props/` 与 `decals/`，AtlasTexture 位于 `resources/art/first_floor/`。沿用 `世界坐标 = 原图坐标 × 0.35 + (35, 64)` 共同构图，中文原名、来源路径、裁区及 SHA-256 由 manifest 维护。除流理台采用主体裁区 `(2583, 2390, 1169, 394)` 排除主体外无关散点，其余图片按 alpha 外接矩形裁图，原 PNG 保留。

| 运行资源名 | Geometry 节点 | 世界中心 | 显示尺寸 |
| --- | --- | --- | --- |
| `first_floor_kitchen_window` | `SideWindow` | `(1421.35, 559.075)` | `19.6×191.45` |
| `first_floor_kitchen_counter` | `KitchenCounter` | `(1143.625, 969.45)` | `409.15×137.9` |
| `first_floor_kitchen_puddle` | `LivingRoomPuddle` | `(1263.5, 482.075)` | `184.8×116.55` |
| `first_floor_tent_storage_box` | `TentStorageBox` | `(741.475, 548.05)` | `50.75×41.3` |
| `first_floor_small_tent` | `SmallTent` | `(593.075, 888.425)` | `189.35×167.65` |
| `first_floor_kitchen_draft_paper` | `KitchenDraftPaper` | `(1235.85, 978.2)` | `72.8×69.3` |
| `first_floor_kitchen_storage_cabinet` | `KitchenSideCounter` | `(1386, 888.95)` | `82.6×312.2` |

窗使用外墙原有碰撞，图片节点 `solid=false`、`z_index=2`；流理台、储物柜和收纳盒采用各自显示尺寸的矩形实体。小帐篷图片自身无碰撞，由独立隐藏 `SmallTentFootprint` 保留 `160×160` 椭圆实体，视觉尺寸独立。水渍与草稿纸无碰撞，草稿纸清零旧旋转；废纸篓占位移至 `(1310, 982)` 避开新纸张。收纳盒按原构图放在客厅中央，继续使用原 `TentStorageBox` 与 `tent_storage_box` 交互 ID；小帐篷月影奖励、阶段四 `tent_storage_memory` 的完整 `cg_03` 和匹配碎片门槛、储物柜与草稿纸的查看正文均保留。

交互脚点随新构图同步：小帐篷 `(593.075, 1005)`、局部 F 矩形 `(-100, -15, 200, 35)`；收纳盒 `(741.475, 608.05)`、局部矩形 `(-60, -10, 120, 50)`；储物柜 `(1300, 835)`、局部矩形 `(-35, -65, 60, 110)`，位于柜台上方可站区域。厨房草稿纸脚点为 `(1235.85, 875)`，使用默认范围，与画室提供潮汐的同名草稿纸各自维护。本次无新增剧情、音频或道具，仅静态核对文件、裁图、配置及引用，未启动引擎、游戏、验证场景或自动化测试；比例、遮挡、碰撞、光晕与交互可达性待用户手工验收。

## 画室资产

用户提供的 `画室.zip` 位于 `D:/微信/聊天记录/xwechat_files/wxid_n5xuklyzkxa321_cfaf/msg/file/2026-10/画室.zip`。十五张 PNG 均为 1360×1000 画布，含不透明白底，原文件字节复制到 `assets/art/environments/studio/backgrounds/` 与 `props/`；中文原名、项目路径、显示区域、来源及 SHA-256 由 manifest 维护，游戏引用项目内资源。

| 资产 | 接入方式 |
| --- | --- |
| 地板墙面 | `AtlasTexture` 拆为 `Floor` 与 `BackWall`，保持共同画布原点 |
| 墙体 | 原 PNG 采样配合 SVG 遮罩显示轮廓 |
| 画架、画凳、置物架、小架子 | 各自等比显示；使用独立隐藏 `Footprint`，置物架现按完整柜身矩形阻挡，其他家具保留各自底部实体 |
| 调色盘 | 原 `PaletteTable` 改显示调色盘，无碰撞；新增小架子承担对应摆放层 |
| 《创世纪》 | 置物架书本美术，保留原点击/F 阅读与剧情 |
| 后墙四幅画、地面叠放三幅画框 | 分别接入原物件和交互位置，保留现有正文 |

上述白底物件与墙体通过 `assets/art/environments/studio/masks/` 内的 SVG 轮廓、`shaders/studio_art_mask.gdshader` 和 `resources/art/studio/*_material.tres` 显示：材质按显示区域采样原 PNG，遮罩去除外围白底并保留封闭内部白像素。`whitebox.artwork` 同时绑定对应轮廓遮罩，使现有交互光晕沿真实物件边缘采样。修改原图有效区域时同步遮罩、材质采样区域与 manifest，原 PNG 保持原样。

画室以资产的相对比例和摆放为准，原 1360×1000 画布统一按 0.6 等比映射到 816×600 世界单位；地板从 y=210 开始，`MovementBounds.area = Rect2(18, 210, 780, 375)`。物件可视尺寸按各自有效区域乘 0.6 配置，画架清零旧白模旋转。碰撞只覆盖对应落地点，图片、碰撞、遮挡层级与交互脚点独立维护；返回门户 `ToCorridor` 与出生点 `from_corridor` 名称保留，出生位置改为 `(408, 520)`。

按反馈，`StorageShelfFootprint` 在 `(753.3, 449.4)` 覆盖 `87×271.2` 的完整矩形柜身；柜图、原《创世纪》正文与交互入口保持。该实体的四向阻挡及《创世纪》原锚点/左侧入口已纳入本轮图形回归。

画室返回门已接入与小院共用的新门图；草稿纸已接入独立原图，窗和报纸继续保留占位，地面水渍复用已有共享图片。探索洗笔桶已接入下述独立透明 PNG，洗笔桶谜题整图继续使用原独立资源。钥匙、碎片、剧情与谜题路由保持原 ID 和流程。该批接入时仅静态核对文件、引用与差异，未启动游戏、验证场景或自动化测试，未执行 Godot 解析检查；实际比例、白底遮罩边缘、遮挡、通行与交互可达性待用户手工验收。

2026-10-19 补入独立草稿纸原图 `assets/art/environments/studio/props/studio_draft_paper.png`，保留 2740×2628 原画布与透明通道；Atlas `resources/art/studio/studio_draft_paper.tres` 裁区为 `(189,355,2172,2043)`。探索 `SketchPaper` 按宽34等比显示为 `34×31.980663`，无碰撞；`CollectSketchPaper.artwork` 共用同一 Atlas 提供收集大图，原高中草稿纸正文、潮汐碎片 ID 与奖励去重保留。来源与校验由 manifest 维护，语法／导入检查与实际体验验收范围见项目状态。

## 小院与探索洗笔桶

2026-10-17 接入用户提供的 `洗笔桶.png` 和院子六张 PNG，七张原图均为 1360×1141。原文件字节复制到项目内，来源、中文原名、裁区与 SHA-256 记录在 manifest。洗笔桶、围墙、树、水井与灌木自带透明 alpha，探索分层直接使用 AtlasTexture，光晕读取原图透明轮廓。

| 资产 | 项目 PNG 路径（相对 `assets/art/environments/`） | 资源与用途 |
| --- | --- | --- |
| 探索洗笔桶 | `studio/props/studio_brush_wash_bucket.png` | `resources/art/studio/studio_brush_wash_bucket.tres`，裁区 `(620, 511, 235, 245)` |
| 院子地面 | `courtyard/backgrounds/courtyard_ground.png` | `resources/art/courtyard/courtyard_ground.tres`；自带道路、落叶、底部植被与杂草 |
| 院子围墙 | `courtyard/backgrounds/courtyard_wall.png` | `resources/art/courtyard/courtyard_wall.tres`，保持原轮廓与顶部缺口 |
| 院子树 | `courtyard/props/courtyard_tree.png` | `resources/art/courtyard/courtyard_tree.tres`，右下树图，新增独立椭圆实体 |
| 院子水井 | `courtyard/props/courtyard_well.png` | `resources/art/courtyard/courtyard_well.tres`，取主区域 `(792, 30, 559, 313)`，排除远处低 alpha 散点 |
| 钥匙灌木 | `courtyard/props/courtyard_bush.png` | `resources/art/courtyard/courtyard_bush.tres`，左上钥匙来源 |
| 院子完整图 | `courtyard/references/courtyard_composite_reference.png` | 单独作为构图参考，运行画面不叠加 |

探索洗笔桶已按反馈缩为约 `57.55102×60` 世界单位，中心 `(486, 305)`、脚底 y=335，为当前角色显示高度的一半；独立 `BrushWashBucketFootprint` 保留 42×42 椭圆占地，中心 `(486, 314)`。`Interactables/BrushWashBucket` 的 F 脚点 `(521, 350)` 和原点击入口保留。桶身直接使用天然透明纹理，原 PNG 与裁区不变；白底画室素材继续沿用上节遮罩材质。独立谜题背景、前置/后续对白与组合路由保留。本轮已核对桶身高度、脚底及碎片尺寸。

小院按原图构图统一缩放 0.6，映射为 816×684.6，活动边界为 `Rect2(20.4, 18, 779.4, 666.6)`。水井位于右上、钥匙灌木位于左上、树位于右下；水井椭圆占地调整为 `(666, 97)`、`198×166`，树新增独立椭圆占地 `(699, 609)`、`96×108`，树图 `TreeTrunk.z_index=6` 高于玩家 5，树根实体与枝叶遮挡共同保持前后关系；灌木原占地保留。水井与灌木 F 脚点仍为 `(666, 215)` 与 `(134, 267)`。地面已包含旧弯路、栏杆下方环境、底部灌木、落叶和杂草，旧白模叠层隐藏，图片显示与实体分别维护。94 项回归后另以角色世界位置 `(699, 525)` 核对树后遮挡，`tree_occlusion.png` 已查看，日志记录 `TREE_OCCLUSION_PASS z=6`。

左下 `HouseDoor` 当前使用与画室共用的 `resources/art/shared/return_door.tres`，显示尺寸 `132×41.853659`，根位置 `(102, 672.6)`、碰撞 `132×24` 保留，视觉偏移 `(0, -8.926829)`、`z_index=2`。返回交互脚点 `(102, 638.4)`、从一楼进入的 `from_first_floor=(102, 598.4)` 和原门户引用保留；此前复用的一楼大门资源继续服务一楼原入口。原图顶部缺口保留，物理活动边界封闭，地点连接保持原五处结构。稳定 ID `well_memory`、`studio_key_bush` 与 `studio_key_01` 继续使用原配置，首次获得画室钥匙正文为“获得画室钥匙！快去看看吧”。院门初次接图与提示仅静态核对；本轮树、井实体与水井 F 点另有图形回归记录。

该批接入时仅静态核对文件、资源引用和差异，未启动游戏、验证场景或自动化测试，未执行 Godot 解析检查；等比显示、透明边缘、光晕、遮挡、通行与交互可达性待用户手工验收。

## 导入与摆放

- 像素场景素材使用最近邻过滤、无损压缩、关闭 mipmaps；卧室、走廊、一楼、画室与小院根节点已设置最近邻。非像素菜单、主角立绘、解谜背景、CG 和水井涟漪使用各自显示节点的线性过滤，避免把像素场景的过滤方式全局套用到 UI。
- 家具等物件等比缩放。背景与墙体按场景区域铺设；不要把整张透明大画布作为物件尺寸。
- 现有约定为 100 世界单位约 1 米。床、桌椅等场景物件按同一尺度校准；探索像素人物逐帧等比统一为 120 世界单位高，源 PNG 保留原尺寸，画室与小院按各自来源资产统一 0.6 等比映射。尽量统一导出像素密度；同一方向物件采用一致的落地锚点。
- `whitebox.gd` 的 `artwork` 绑定纹理，`artwork_size` 与 `artwork_offset` 调整显示尺寸和偏移。零显示尺寸会自动等比适配 `size`；地板、边框可显式指定铺设尺寸。
- `size`、`solid`、碰撞体、活动边界和 F 交互锚点属于玩法配置，独立于图片。美术替换时保留稳定交互 ID 和玩法流程；按用户要求采用资产布局时，同步调整必要的边界、底部碰撞和交互脚点。需要验证时按下面的范围规则核查通行与交互可达性。台灯、地毯等装饰不增加碰撞。
- 已带在图片中的枕头、桌脚等旧占位绘制已关闭，避免叠加。绑定 artwork 后自动隐藏原白模占位文字；物件名作为内部配置保留。未提供素材的对象继续保留占位。普通剧情、查看与收集使用纸张图片框与黑字，世界提示使用气泡素材，月光 UI 等专用界面保留各自样式。
- 场景中“按 F 交互”的浮动文字已移除，F 功能与物件光晕保留。`scripts/ui/controls_hint.gd` 在每次新载入游玩实例时，于左上角显示一次 WASD、F、Esc 键帽说明；任意键关闭并消耗该次按键，切换地点、暂停和继续游戏不重弹。解谜界面保留阶段性的 Enter/Esc 提示。

## 后续交付与替换

1. 导出透明 PNG，说明场景、物件身份、方向及是否为像素风；若使用大画布分层导出，保持所有层的画布尺寸和原点一致。
2. 按上表归类并命名，更新 manifest 的路径、尺寸与校验值。复用资源引用已有路径。
3. 若原图画布或有效区域改变，更新对应 AtlasTexture 的 region；保持场景中资源路径稳定。图片文件重命名或移动使用 Godot FileSystem 面板，随后核查引用。
4. 调整显示尺寸、偏移及必要的物件层级；碰撞只覆盖实体占地。角色素材由独立 SpriteFrames 管理，显示尺寸与脚底碰撞分别维护。
5. 常规开发不主动运行自动化测试、验证场景或试玩，手工测试由用户进行。仅在用户明确要求测试或正在修复 bug 时主动验证，并按改动范围检查显示、比例和对齐；涉及碰撞或交互时再检查对应物件的通行与 F 功能。交付说明需写明实际验证范围及未运行项目，不把历史截图或报告作为本次验证结果。
6. 交付时复制整个 demo2 项目，保留 `LunarTitleFX/`、项目内字体、资源和 `.import` 设置；临时目录中的原图无需一同复制。

## 记忆月相素材与显词时序

用户提供的五张月相 PNG 均为 300×300、RGBA 透明，原字节保存于 `assets/art/puzzles/shared/moon_fragments/`，AtlasTexture 位于 `resources/art/puzzles/shared/`。图片无损导入、线性过滤、关闭 mipmaps；原名、来源、裁区和 SHA-256 同步 manifest。四个定义均显式绑定 `moon_texture`，A—E 从残到满依次对应原文件 5、4、3、2、1，碎片 ID、词名与剧情路由保持。

| 选项 / 词 | PNG 与同名 `.tres` 资源主名 | Atlas 区域 `(x, y, w, h)` | 参考月轮直径 |
| --- | --- | --- | --- |
| A / 港湾 | `moon_fragment_05_thin_crescent` | `(91, 71, 137, 137)` | 88 |
| B / 涌泉 | `moon_fragment_04_crescent` | `(97, 69, 137, 137)` | 88 |
| C / 潮汐 | `moon_fragment_03_half` | `(87, 74, 132, 132)` | 84 |
| D / 月影 | `moon_fragment_02_gibbous` | `(81, 72, 143, 143)` | 94 |
| E / 镜面 | `moon_fragment_01_full` | `(83, 67, 133, 133)` | 85 |

Atlas 的 `moon_reference_center` 位于裁区方形中心，`moon_reference_diameter` 记录表中参考月轮直径。`memory_token.gd` 按元数据等比绘制，使五种相位实月轮直径统一为 token 短边的 76%，保留近柔光，拖拽预览自动使用相同纹理。更换图片时同步裁区、参考圆心与直径，保持 token 接收区域与库存映射。

月相 token 与其拖拽预览使用 `shaders/moon_fragment_edge_fade.gdshader`：通过 `source_rect` 把原 300×300 PNG 的 Atlas UV 转为裁区局部 UV，再按到最近裁边的原像素距离，以 `smoothstep` 在 18 原像素内渐隐 alpha，消除近柔光的方形裁边。当前月轮高 alpha 主体距裁边至少 19.5 像素，主体和 76% 月轮尺寸保留；词牌使用原绘制。原 PNG 字节、校验与 Atlas 区域保持，边缘参数由 manifest 记录，替换源图时同步核对主体与渐隐范围。

四处选碎片阶段初始隐藏水面词和句槽；每投入一块只使对应 Label 在 0.25 秒内显现，可继续投入。Enter 后仅已投入词统一在 0.9 秒内浮出并飞到词牌位置，动画完成进入填词，选碎片阶段不生成可拖词牌。四定义 `rise_on_drop=false`，重置/退出清理显词与飞词 Tween。鱼缸五个词中心 y=447，帐篷 E 词中心 `(1110, 785)`，保证浮词起点位于对应水面或盒盖内。本轮新素材与时序当前仅静态核对，实际显示和运行验证另行记录。

## 水井选碎片界面

三张原图归档在 `assets/art/puzzles/well_memory/backgrounds/`：`well_memory_environment.png` 与 `well_memory_well.png` 在选碎片、文字浮现及填词阶段持续分层显示；`well_memory_composite.png` 保留作总图对照，不重复叠加。港湾→涌泉进入现有独立 CG 与对白流程，涌泉→港湾在原谜题背景上浮现微剧情。

`resources/well_memory_puzzle.tres` 绑定 `moon_environment`、`moon_well`；`moon_reference_size` 表示原始画布大小，`moon_well_rect` 表示水井图片位置。月相碎片的接收范围独立使用 `fragment_drop_rect = Rect2(600, 842, 750, 230)`，覆盖整件水井外接矩形，`fragment_drop_margin = 24` 为参考画布尺度的边缘容错，井身与井沿均可接收碎片。`moon_water_rect` 继续定义井口椭圆的水面效果及词语拖回取消区域。更换背景后分别维护图像、水面和碎片接收范围，无图片配置时保留白模界面。

图片层忽略鼠标输入，由 Water 节点接收拖放；其合法月相 GUI 范围扩展至独立碎片矩形，词语拖回仍使用原水面。当前 `ui_backing_enabled = false`，碎片外围白盘、词卡白底、句子白底与提示白底均已关闭，月相本体使用上述五张 PNG。`moonlight_ui_enabled = true` 提供浅灰蓝字迹、柔光、薄弧光槽及透明细线键帽；水中词字号 32、可用词字号 46，句子雾透明度为 0。水面初始无词，一块显现一词，Enter 后已投词先浮出水面再飞回各自词牌位置；句型为“【A】之中，【B】到来”，句槽在 Enter 后于水井上方显示。碎片接收范围扩展不会放大背景、涟漪、浮词或词槽。

## 鱼缸记忆界面

`客厅鱼缸.zip` 的三张原图归档在 `assets/art/puzzles/fish_tank/backgrounds/`：`客厅.png` 对应 `fish_tank_environment.png`，`鱼缸.png` 对应 `fish_tank_layer.png`，`总图.png` 对应 `fish_tank_composite_reference.png`。前两张分层显示，总图仅作合成参考；原始画布、像素和透明通道保留，来源与校验值记录在 manifest。

鱼缸共用 `scenes/puzzles/memory_puzzle.tscn`，独立配置位于 `resources/fish_tank_memory_puzzle.tres`。参考画布为 1920×1080；鱼缸显示矩形为 `(701, 339, 1060, 490)`，月相碎片以同一外接矩形作为 `fragment_drop_rect`，并配置 `fragment_drop_margin = 24` 的参考边缘容错。水面矩形为 `(737, 383, 863, 128)`，局部多边形为 `(1, 0)、(863, 2)、(863, 128)、(0, 124)`，继续管理水面效果与词语拖回取消。更换素材时分别核对整件鱼缸的碎片接收区域和可见水面区域。

| 配置 | 当前值 |
| --- | --- |
| A—E 月相中心 | `(200, 860)、(250, 570)、(410, 225)、(735, 185)、(1005, 200)` |
| 月相尺寸 | `160×160` |
| A—E 水中词中心 | `(855, 447)、(1005, 447)、(1160, 447)、(1320, 447)、(1480, 447)` |
| 句子矩形 | `(835, 405, 680, 84)` |
| 水中词 / 可用词字号 | `46 / 64` |
| 词牌尺寸 | `144×96` |
| 词槽线宽 / 空槽透明度 | `3.2 / 0.95` |
| 句子柔雾透明度 | `moonlight_sentence_mist_opacity = 0.21` |
| Enter / 反馈中心 | `(1210, 950) / (1180, 970)` |

鱼缸同样关闭白底并启用 moonlight UI，句子后方绘制低透明深蓝柔雾，保持亮水面上的可读性。水面初始无词，每投入一块只显现对应词，Enter 后已投词统一飞出，动画结束进入填词；`rise_on_drop=false`，进入填词后保留原分层背景。A/B/C/D/E 对应港湾/涌泉/潮汐/月影/镜面，D 来自小帐篷、E 来自电影票；阶段 3 使用句型 2“【A】里，不见【B】”，原路由保留。港湾→涌泉触发情节块 3，其余已配置组合浮现微剧情。鱼缸定义绑定 `fish_tank_memory_story.gd` 并启用 `play_success_story=true`；情节块 3 使用共用纸张图片对白框与原字体，关闭立绘，科研／晚餐 CG 按零起 index 7／17／21 切换、19 清屏。完整读完 `cg_02` 且有匹配碎片后，本局首次先播四页前置；完整读完情节块 3 后回客厅原位置并接第四幕 16 页对白，保留主角立绘、Luna 画外音与两页震动。前后对白共用纸张图片框，微剧情和情节块提前退出不接后续。鱼缸未配置涟漪，布局、字号、柔雾与水面多边形在独立资源维护。

## 洗笔桶记忆界面

用户提供的 `画室洗笔桶.png` 原样保存为 `assets/art/puzzles/brush_wash/backgrounds/brush_wash_environment.png`，1920×1080 整图已包含桶身、画笔和环境；`画室洗笔桶 记忆碎片示意.png` 单独保存为同目录的 `brush_wash_layout_reference.png`，用于月相布局对照，不在运行画面叠加。原像素、画布和透明通道保留，来源、路径与 SHA-256 记录在 manifest。

独立配置位于 `resources/brush_wash_memory_puzzle.tres`，复用共用记忆谜题。只配置 `moon_environment` 即可显示整图背景，`moon_well` 为可选叠加层；当前洗笔桶不重复叠加桶身图片。图片采用无损导入、线性过滤并关闭 mipmaps，控件沿 1920×1080 参考坐标适配。

| 配置 | 当前值 |
| --- | --- |
| A—E 月相中心 | `(442, 345)、(815, 172)、(1314, 148)、(1682, 364)、(1762, 710)` |
| 月相 token 尺寸 / 可见直径 | `144×144 / 约 109.44` |
| A—E 水中词中心 | `(960, 545)、(1050, 500)、(1160, 545)、(1080, 595)、(1260, 585)` |
| 碎片接收矩形 / 容错 | `(760, 310, 700, 770) / 24` |
| 水面矩形 | `(820, 415, 570, 385)` |
| 句子矩形 | `(800, 640, 680, 88)` |
| 水中词 / 可用词字号 | `46 / 64` |
| 词牌尺寸 | `144×96` |
| 句子柔雾透明度 | `moonlight_sentence_mist_opacity = 0.21` |
| Enter / 反馈中心 | `(1110, 980) / (1110, 970)` |
| 拖拽引导矩形 / 目标名 | `(48, 710, 460, 224) / 洗笔桶` |

水面局部 `water_drop_polygon` 为 `(23, 106)、(96, 61)、(291, 13)、(359, 0)、(416, 42)、(481, 120)、(552, 241)、(564, 272)、(544, 286)、(222, 375)、(168, 377)、(133, 348)、(61, 215)`，贴合桶内水面并用于词语拖回取消。月相投放使用覆盖整件洗笔桶的独立接收矩形与 24 像素边缘容错，水面显示、浮词和词槽各自保留配置。

洗笔桶关闭白底并使用月光 UI，`rise_on_drop=false`；初始无水面词，每次有效投入只显现对应一词并可继续投入，Enter 后已投词统一飞出，动画结束进入填词。三句前置后使用“【A】之中，【B】到来”，A/B/C/D/E 对应港湾/涌泉/潮汐/月影/镜面，未持有月相隐藏，前三处原路由保留。港湾→潮汐触发情节块 2 的 39 页正文，前 28 页黑底，后 11 页接入窗边 `CG2-2.png`，共用纸张图片框与原字体、关闭立绘；其余组合浮现原微剧情。完整后回画室原位置接八页旁白，保留主角中性立绘；微剧情回选碎片，提前 Esc 不接后续，未新增涟漪。月相按反馈缩为 `144×144`，可见月轮约 109.44，原五张 PNG、中心与水面布局保留。本轮已核对 144×144 token 配置及 CG 截图；完整拖拽和长文推进体验继续手工验收。

## 帐篷收纳盒记忆界面

用户提供的 `帐篷收纳盒.zip` 中两张 1920×1080 PNG 原样归档在 `assets/art/puzzles/tent_storage/backgrounds/`：运行背景为 `tent_storage_environment.png`，布局示意为 `tent_storage_layout_reference.png`。原文件像素、画布和透明通道保留，中文原名、来源与 SHA-256 记录在 manifest；布局示意不叠加到运行画面。图片采用无损导入、线性过滤并关闭 mipmaps。

阶段四独立定义为 `resources/tent_storage_memory_puzzle.tres`，`scenes/puzzles/tent_storage_memory_puzzle.tscn` 继承共用谜题场景。整图包含帐篷环境与收纳盒，只绑定 `moon_environment`，不重复叠加盒身。探索中的 `TentStorageBox` 已接入上述独立新图，世界中心 `(741.475, 548.05)`、视觉尺寸 `50.75×41.3`，点击与 F 交互锚点为 `(741.475, 608.05)`，局部矩形 `(-60, -10, 120, 50)`。小帐篷原有月影收集继续保留，探索图片与独立谜题背景各自维护。

| 配置 | 当前值 |
| --- | --- |
| 参考画布 | `1920×1080` |
| A—E 月相中心 | `(239, 487)、(480, 245)、(893, 167)、(1280, 309)、(1640, 487)` |
| 月相 token 尺寸 | `190×190` |
| A—E 水中词中心 | `(610, 805)、(735, 865)、(870, 835)、(995, 785)、(1110, 785)` |
| 碎片接收矩形 / 容错 | `(430, 425, 812, 655) / 24` |
| 盒盖效果与词语取消矩形 | `(430, 565, 812, 460)` |
| 盒盖局部多边形 | `(0, 220)、(441, 0)、(812, 154)、(410, 460)` |
| 句子矩形 | `(1015, 710, 850, 100)` |
| 句型 | `template_id=3`：`【A】从【B】中涌现`；仅一项，不显示选择按钮 |
| 水中词 / 可用词字号 | `46 / 64` |
| 词牌尺寸 | `144×96` |
| 句子柔雾透明度 | `0.21` |
| Enter / 反馈中心 | `(1450, 1005) / (1450, 955)` |
| 拖拽引导矩形 / 目标名 | `(1300, 40, 460, 224) / 收纳盒` |

五个选项 A/B/C/D/E 绑定港湾/涌泉/潮汐/月影/镜面，剧情编号为 1/3/4/5/2，未持有月相隐藏。关闭白底、使用月光 UI，`rise_on_drop=false`；初始无水面词，一块显现一词，Enter 后已投词统一飞出为词牌，动画结束进入填词。盒盖多边形保留词语取消范围，月相接收矩形加 24 像素容错。阶段四仅使用句型 3，不显示切换按钮、不响应 Tab，前三处句型与路由保持。

本局首次进入播放三页前置。月影→潮汐直接进入 Luna 7 页，连续三次潮汐→月影进入真实 14 页；前两次震动、归位及 Luna 介入，第二次震动更强，其他组合或退出清零计数。正式正文空 `speaker`、关闭立绘，完整后记录 `cg_04`/导向并同黑屏接第五幕。另有用户新提供的 18 条微剧情沿用原背景浮现，不新增图片。乱码待定，当前未添加。两分支与真假结局已接入下文的新 CG，正文保留共享纸张框与关闭立绘；意识上传真回忆仍为黑底。

该项最初接入时仅静态核对剧情页、分支配置、资源引用与 Git 差异；未启动游戏、验证场景或自动化测试，未进行音频试听。原背景的来源与 SHA-256 沿用既有清单，分支正文与窗口适配待用户手工确认。

## 组合微剧情与黑底对白

水井、洗笔桶、鱼缸、帐篷收纳盒分别对应阶段 1—4，完整有序组合见 [项目状态](project_status.md#组合剧情映射)。`scripts/puzzles/memory_echo.gd` 在既有谜题背景上绘制深蓝半透明淡雾，使用 `ui_font.tres` 的浅月光色正文、细光线和稀疏光点；完整正文自动轻微上浮并淡入，下方显示“左键 / Enter / 空格 / F 继续”。文字显现期间确认先补齐，显现完成后确认触发淡出并返回选碎片；Esc 退出整个谜题。微剧情不显示常规对白框或角色立绘，长段落及观测日志按正文换行，文本与提示保留独立显示区域。

情节块 1 继续使用已有天台 CG 原图与 AtlasTexture。情节块 2 前 28 页保留黑底、后 11 页显示窗边图；情节块 3、4 两分支与真假结局已按下文时点接图；正文共用纸张图片框并关闭立绘。情节块 4 完整后同黑屏接 `cg_05_false/cg_05_true`，装置两选项在底部纸张框内显示编号文字按钮，终局使用代码黑底、结局名称和返回菜单按钮。CG2 前段与意识上传真回忆画面继续待提供，收到后归档来源、校验与分镜。组合数据与稳定选项 ID 独立维护，更换图片不改变库存映射。

`CG2-2.png` 原图在本机微信文件目录已找到，原字节归档为 `assets/art/cg/act_02/cg_02_window.png`；`resources/art/cg/act_02/cg_02_window.tres` 使用完整 `3508×2480` 区域，无损导入、关闭 mipmaps、线性显示。洗笔桶 `NARRATIVE_PAGES` 的零起 index 28–38 从小泠“好了，别再说了。”至“一起努力吧。我们首都见。”绑定同图，前 28 页餐桌争执保留黑底。原 39 页正文、完整阅读、返回与后续旁白语义保留；本轮已核对第 29 页窗边 CG 的图形显示与截图；完整 39 页推进和后续旁白仍按实际流程验收。

一楼电影票、储物间和意识深潜装置已接入下文新资产：票图在原 `MovieTicket` 位置显示，并由 `CollectMovieTicketMemory.artwork` 提供收集大图；仓库复用原 `UpperRoom`，装置使用传送门图片。对应显示尺寸、碰撞与交互锚点分别维护，完整 `cg_03` 后提供 E/镜面的门槛与去重流程保留。第五幕假正文与最终真正文已接相依／独立望月两图，意识上传真回忆仍缺对应画面，既有剧情背景的来源与 SHA-256 保留。

该项初次接入时仅静态核对脚本、资源配置及引用，未运行试玩或测试；浮现对比度、长文本排版与窗口适配待用户手工确认。

## 返回门、仓库、装置与电影票

2026-10-18 接入 `门＆传送门.zip` 两图、`仓库(3).zip` 五图及用户临时目录电影票 PNG，共八张原图。原 PNG 字节与天然透明通道保留，按无损、关闭 mipmaps 的方式导入，探索显示沿用最近邻过滤；GameUI 的大图 `view_texture` 显式采用线性过滤。中文原名、来源路径、alpha/显示裁区与 SHA-256 由 manifest 维护。

| 来源与用途 | 项目 PNG |
| --- | --- |
| 返回门，供小院 `HouseDoor` 与画室 `CorridorDoor` 共用 | `assets/art/shared/props/return_door.png` |
| 传送门，作为一楼 `ConsciousnessDevice` 的图片 | `assets/art/shared/props/consciousness_portal.png` |
| 仓库地板墙面 | `assets/art/environments/first_floor/backgrounds/first_floor_storage_floor_wall.png` |
| 仓库墙体 | `assets/art/environments/first_floor/backgrounds/first_floor_storage_wall_border.png` |
| 仓库窗 | `assets/art/environments/first_floor/props/first_floor_storage_window.png` |
| 仓库门口两片 | `assets/art/environments/first_floor/props/first_floor_storage_door_01.png`、`first_floor_storage_door_02.png` |
| 电影票 | `assets/art/environments/first_floor/props/first_floor_movie_ticket.png` |

返回门 Atlas 为 `(16, 20, 164, 52)`，两处按宽 132 等比显示为 `132×41.853659`。画室 `CorridorDoor` 根位置 `(408, 590)`、原 `132×12` 大小与 `solid=false` 保留，图片偏移 `(0, -14.926829)`、`z_index=2`；小院 `HouseDoor` 的原物理入口与返回脚点保持，具体参数见上文。两处继续使用原传送目标、出生点和交互入口。

仓库继续使用 `first_floor.tscn` 原 `UpperRoom`，五张图沿用 `世界坐标 = 原图坐标 × 0.35 + (35, 64)`。地板墙面运行 Atlas 为 `(0, 397, 1122, 1013)`，世界中心 `(231.35, 380.225)`、尺寸 `392.7×354.55`；可行走地板从 y=338.4 开始，后墙另以隐藏碰撞覆盖 y=207.5–338.4。墙体主体为 `(0, 386, 1122, 1024)`，运行时拆为下表五片；左右底墙同步裁片并保留世界 x=192.15–271.6 的入口。

| 墙体部位 | 源图 Atlas 裁区 |
| --- | --- |
| 顶部 | `(0, 386, 1122, 24)` |
| 左侧 | `(0, 410, 28, 978)` |
| 右侧 | `(1098, 410, 24, 978)` |
| 左下 | `(0, 1388, 449, 22)` |
| 右下 | `(676, 1388, 446, 22)` |

入口地面 `UpperRoomDoor` 从地板墙面裁取 `(449, 1300, 227, 88)`，在门组同一中心显示 `79.45×30.8` 且无碰撞；门打开后继续保留地面。窗 `UpperRoomWindow` 使用 `(725, 469, 261, 184)`，中心 `(334.425, 260.35)`、显示 `91.35×64.4`，图片无碰撞并由原后墙阻挡。

门图两片内容上下镜像，对应门口内外两侧。`StorageRoomGate` 在 `(231.875, 552.6)` 提供 `79.45×30.8` 矩形实体，内片显示 `79.1×18.9`、纹理偏移 `(-0.175, -5.95)`；外片为无碰撞子节点 `OuterLeaf`，局部位置 `(0.175, 5.95)`、显示同尺寸。`OpenStorageRoom` 脚点为 `(231.875, 600)`、局部 F 矩形 `(-60, -10, 120, 45)`。现有 `_sync_gate()` 隐藏父节点并解除碰撞时两片共同隐藏，不增设动画状态；`storage_key_02` 不消耗，`storage_room_opened` 跨地点重载恢复。

锁定时，`room_visual_paths` 登记的仓库地板、墙面、窗、水渍和装置均隐藏，原实体继续阻挡；`room_interaction_paths` 登记的水渍查看停用。持钥匙开门后统一显示室内并启用登记查看，门组共同隐藏，装置继续使用原剧情门槛。此显隐配置随 `storage_room_opened` 在重载时恢复，图片与碰撞独立管理。

一楼左下裁除后，`LeftWall` 收至中心 `(31, 602.825)`、`8×90.65`。`LivingLeftWall` 仍以中心 `(442.95, 847.575)`、`8×398.85` 提供实体，图片独立显示 `7.7×131.95`、偏移 `(7.85, -133.45)`，从源图 y=2046 对应世界 y=780.1 处与原边框接合。两项视觉细修在 94 项回归后完成图形启动与地图截图复核，避免锁定仓库外侧残线和双线。

装置使用 `resources/art/shared/consciousness_portal.tres` 的 `(40, 12, 117, 152)` 区域，`ConsciousnessDevice` 位于 `(295, 395)`、显示 `117×152` 且图片自身无碰撞，独立隐藏实体位于 `(295, 459)`、尺寸 `80×24`。交互脚点 `(295, 505)`、局部 F 矩形 `(-60, -10, 120, 25)`；场景将 `player_access_rect` 配为 `(35, 338.4, 385, 206.1)`，与仓库实际地板范围协调。

电影票原图为 2740×2628，Atlas 裁区 `(880, 124, 1182, 2309)`。探索小图按原比例显示为约 `18.428757×36`，保留 `(1051.75, 817)`、无碰撞与 `z_index=3`；收集脚点 `(1051.75, 847)` 和原交互矩形保留。`CollectMovieTicketMemory.artwork` 与探索小图引用同一票图 Atlas，原正文、`cg_03` 门槛、E/`memory_fragment_05` 镜面奖励与去重保留。装置接图保留完整真回忆、真实分支、门已开及玩家进入仓库后的点击/F 条件，最终两选项与结局行为保留。该批接入时仅静态核对文件、引用与场景配置，未启动引擎、试玩或测试；实际入口、碰撞、遮挡、光晕与票图展示待手工验收。

## 首次碎片拖拽引导

水井、鱼缸、洗笔桶与帐篷收纳盒共享 `scripts/puzzles/memory_drag_hint.gd` 的代码绘制引导，无新增位图素材。浅灰蓝文字搭配透明深色薄边框，显示鼠标左键、月相与指向目标的箭头；两行文案为“按住左键，将记忆碎片”“拖到水井/鱼缸/洗笔桶/收纳盒上松开”，按当前目标显示名称。目标名由 `drag_hint_target_name` 配置，`drag_hint_rect` 使用绝对参考坐标：水井 `(32, 32, 460, 224)`，鱼缸 `(1290, 112, 460, 224)`，洗笔桶 `(48, 710, 460, 224)`，收纳盒 `(1300, 40, 460, 224)`。引导随窗口等比适配并限制在视口内，布局避开月相和目标主体。

引导不阻塞直接拖拽，首块成功投入后淡出；任意非 Esc 按键收起并消耗该次事件，Esc 沿用退出谜题功能。GameUI 的会话标记仅在有可拖碎片并实际进入选碎片阶段、引导呈现时更新；已配置的前置剧情结束后才呈现。四处每局合计显示一次，重试与重新进入不重复，新游戏重置。调整图示和布局时保留这套显示时序，相关状态与信号职责见架构说明。本次未运行测试或试玩，图示与适配效果待手工确认。

## 水井涟漪动画

`水波纹(1).zip` 的 229 张透明 PNG 原样归档为 `assets/art/puzzles/well_memory/effects/ripple/ripple_0001.png` 至 `ripple_0229.png`，按数字顺序播放。原始 2500×2500 图片和透明通道保留；Godot 的 `.import` 设置将运行纹理尺寸限制为 512，采用线性过滤并关闭 mipmaps，避免加载原始大画布消耗过多显存。

`resources/art/well_memory/water_ripple_frames.tres` 统一管理帧序、60 FPS 和单次播放配置。当前播放时长约 3.82 秒，可在 SpriteFrames 中调整速度。`well_memory_puzzle.tres` 的 `water_ripple` 绑定动画；`ripple_source_uv` 根据整套序列的透明有效范围裁出显示区域，源文件像素不改动。

碎片有效投入水井接收矩形及其容错边缘后播放，连续投入会重新开始；无效拖放不触发。动画位于词语下方，仍通过 shader 限制在原井口椭圆内并降低亮度与不透明度，忽略鼠标输入。碎片接收范围扩大时涟漪显示范围保持原水面。Enter 可以直接进入还原，进入填词阶段、重置或关闭界面后清除动画。没有投入时水面保持静止，原有失败提示与解谜判定继续保留。

## 卧室照片与窗户 CG

用户提供的 `照片 2.png` 原样保存为 `assets/art/cg/act_01/bedroom_photo.png`，绑定卧室 `ShelfPhoto.artwork`。查看时在底部文字框上方等比显示大图，正文→获得“港湾”→关闭的两页流程及奖励去重保留。`show_collection` 的可选 `large_artwork` 参数开启大图布局，钥匙等物品使用小图预览；钥匙统一使用 10.15 的共享图标。

五张窗户 CG 原样归档在 `assets/art/cg/act_01/window_moon/`，按月亮亮部从少到多排列；两组左右朝向素材均保留：

| 播放顺序 | 原文件 | 项目文件 |
| --- | --- | --- |
| 1 | 未命名作品 5.png | `window_moon_01_crescent_left.png` |
| 2 | 未命名作品 8.png | `window_moon_02_crescent_right.png` |
| 3 | 未命名作品 1 2.png | `window_moon_03_wide_left.png` |
| 4 | 未命名作品 7.png | `window_moon_04_wide_right.png` |
| 5 | 未命名作品 6.png | `window_moon_05_full.png` |

`WindowCG.artworks` 配置播放顺序，`slide_duration` 配置每张停留时间，目前为 2 秒。靠近窗户按 F 全屏等比播放，完整播放后返回卧室；左键、F 或 Esc 可提前退出，重新查看从第一张开始。CG 不增加占位文字，播放期间暂停人物移动，退出后保留原位置。图片顺序和时长均通过场景配置调整，`show_slideshow` 可供后续其他 CG 使用。

## 主角立绘与水井 CG

四张主角原图原样保存到 `assets/art/characters/protagonist/`，原画布均为 1100×1900。中文原名及 SHA-256 记录在 manifest。

| 原文件 | 项目文件 | 表情 ID |
| --- | --- | --- |
| 立绘 (1).png | `protagonist_neutral.png` | `neutral` |
| 拆分1 (1).png | `protagonist_speaking.png` | `speaking` |
| 拆分2 (1).png | `protagonist_smile.png` | `smile` |
| 拆分3 (1).png | `protagonist_teary.png` | `teary` |

`scripts/ui/story_dialogue.gd` 为四张图分别创建 AtlasTexture，统一 `region = Rect2(180, 70, 715, 1800)`，源图片不裁切或改写。1920×1080 参考画布中，显示位置为 `(1285, 105)`，容器为 `555×1397`，使用等比居中和线性过滤，随对白整体等比适配窗口。表情由对白页配置，主角在本段首次出现后持续保留，结束时与对白框一起隐藏；开场 Luna 画外音及纯 CG 不额外显示立绘。

水井成功 CG 的原图 `CG1.png` 保存为 `assets/art/cg/act_01/cg_01_rooftop.png`。三个裁片由 `resources/art/cg/act_01/cg_01_rooftop_01.tres` 至 `cg_01_rooftop_03.tres` 管理，区域依次为 `(72, 89, 1260, 811)`、`(72, 954, 1260, 1422)`、`(1382, 91, 2051, 2290)`。剧情按原照片布局逐步叠加左上、左下及右侧画面，已出现的画面保留；源图、分隔线与白边通过 Atlas 显示区域处理，替换时同步资源及 manifest。剧情时序由 `scripts/puzzles/well_memory_story.gd` 和解谜组件管理。

## CG3、CG4与真假结局图片

2026-10-19 接入六张用户原 PNG，原字节、画布及颜色模式保持；CG3 两张为 3508×2480 RGBA，第四幕两张为 1920×1080 RGBA，真假结局为 2823×1540 RGB，不人为补 alpha。来源为微信 `2026-10` 目录中的 `CG3-1.png`、`CG3-2.png`、`第四幕cg.zip` 与 `真假结局cg.zip`。中文原名、ZIP entry、SHA-256、画布及 Atlas 区域统一记入 manifest，PNG 无损导入、关闭 mipmaps，显示使用线性过滤。

| 原图 | 项目 PNG（`assets/art/cg/` 下） | 对应正文 |
| --- | --- | --- |
| `CG3-1.png` | `act_03/cg_03_work.png` | 科研工作桌与小泠来电 |
| `CG3-2.png` | `act_03/cg_03_dinner.png` | 两人披萨晚餐 |
| `第四幕cg luna导向.png` | `act_04/cg_04_luna.png` | 收纳盒 CG4 Luna 分支 |
| `第四幕cg 真实导向.png` | `act_04/cg_04_truth.png` | 收纳盒 CG4 真实分支三格 |
| `2A7DBBCF33A27903D66429B24FC7F25B.png` | `act_05/ending_false.png` | 假结局共同生活 |
| `B448FB1A4CD078793234CD0FE1D344D1.png` | `act_05/ending_true.png` | 最终真结局走进现实 |

同名 Atlas 资源位于 `resources/art/cg/act_03/`、`act_04/`、`act_05/`。单幅使用完整原画布；真实分支的 `cg_04_truth_01/02/03.tres` 区域分别为 `(65,61,662,958)`、`(760,61,1099,358)`、`(760,479,1102,540)`，保留棕色边框，以原 1920×1080 坐标累加左竖／右上／右下格。StoryCGView 从 atlas 原图读取画布尺寸，在纸张上方等比居中，不将1920或2823宽图片套入旧3508画布。

以下页码全部从 0 开始；正文和 speaker 字符串保持原样，仅新增演出元数据。

| 页组与页码 | 显示或清理 |
| --- | --- |
| 鱼缸 `NARRATIVE_PAGES[0..6]` | 黑底，暂无入门／大学对应图 |
| `[7]`“2089年…进入弦音科技…” | `cg_03_work.tres`，替换旧图 |
| `[17]`“哇塞，你还点了披萨？！” | 替换为 `cg_03_dinner.tres` |
| `[19]`“忽然，眼前的景象变了…” | 清屏，19／20 保持黑底 |
| `[21]`“把你拉回现实” | 恢复晚餐图，保留至40 |
| 收纳盒 `LUNA_PAGES[0]` | 显示完整粉月牵手图，保留至6 |
| `TRUTH_PAGES[2]`／`[9]`／`[10]` | 依次累加左、右上、右下三格，保留至13 |
| 第五幕 `TRUTH_RECOLLECTION_PAGES[0]` | 清屏，8页意识上传回忆保持黑底 |
| `FALSE_ENDING_PAGES[0]` | 显示相依图，保留全部5页 |
| `TRUE_ENDING_PAGES[4]`“走进现实” | 显示独自望月图；此前0–3页培养缸场景保持黑底 |

`cg_image` 默认累积，`cg_replace=true` 先清旧换图，`cg_clear=true` 清回黑底；章节起始、退出、返回探索及终局清理旧图和 Tween。CG1 原三格累积保持。读档重建至当前页后直接完成淡入，不重播奖励或完整阅读事件。

时点依据：全文检查现存 `cg文本(1)/(2)/(3)/(5)/(6)/(7)/(8)/(9).docx` 及 `总剧本(10).docx` 的包内全部 XML，涵盖正文、批注／文本框节点及 drawing name/alt；未找到 CG3-1／3-2 或三格逐图编号 cue。`cg文本(4)` 未在所给微信文件目录树找到，7／8／9 原字节完全相同。CG3／CG4／结局切图点按当前页正文与原图内容对应确定；CG2 明确黑屏标记沿用既有实现。第四幕两图归属于 CG4 分支，独自望月归于最终真结局；意识上传段继续等待对应图片，不新增正文或虚构画面。

本批已静态核对原图、manifest、Atlas、页元数据、引用与 Git 差异，相关脚本语法解析及资源导入通过；未试玩或执行自动化验证场景，实际构图、切图与读档体验待用户手工验收。

## 主界面菜单资产

用户提供的原主界面素材共 8 张 PNG，原始像素和透明通道原样保留，统一归档在 `assets/art/ui/main_menu/`。中文原名、尺寸和 SHA-256 记录在 `assets/art/manifest.json`。背景与六个按钮继续使用该目录图片，按钮的白色文字沿用原图。旧 `main_menu_title.png` 作为已接收素材归档保留。

`scenes/ui/main_menu.tscn` 已接入 `LunarTitleFX/lunar_title.tscn`，当前标题纹理为 `LunarTitleFX/assets/title.png`，`lunar_title.gd` 与 `lunar_title.gdshader` 控制鼠标透视倾斜及周期扫光。标题位置仍为 `(490, 187)`、容器 `920×440`，shader 参数由标题脚本导出项管理。替换当前标题时更新这套组件内的纹理与参数，保持 `res://LunarTitleFX/` 路径完整。

主菜单按 1920×1080 参考画布布置。下表保留原始 8 张素材的来源与摆放数据，其中旧标题一行用于归档对照。坐标为整张 PNG 的左上角，尺寸包含透明留白；运行图层共同等比缩放并居中，保持相对位置。背景与标题忽略鼠标输入，按钮的 300×60 区域接收点击。

| 原文件 | 项目文件 | 参考坐标（x, y） | 显示尺寸 |
| --- | --- | --- | --- |
| 背景.png | `main_menu_background.png` | 0, 0 | 1920×1080 |
| 标题.png | `main_menu_title.png` | 490, 187 | 920×440 |
| 新游戏.png | `main_menu_new_game.png` | 810, 564 | 300×60 |
| 继续游戏.png | `main_menu_continue.png` | 810, 639 | 300×60 |
| 设置.png | `main_menu_settings.png` | 810, 715 | 300×60 |
| 载入游戏.png | `main_menu_load_game.png` | 810, 788 | 300×60 |
| 退出.png | `main_menu_quit.png` | 810, 863 | 300×60 |
| 制作人员名单.png | `main_menu_credits.png` | 809, 938 | 300×60 |

菜单图片采用线性过滤、无损导入并关闭 mipmaps。替换背景和按钮时保持上述文件路径、画布和坐标关系；当前标题按 `LunarTitleFX` 的配置替换，参考合成图与原始 ZIP 保留在项目外。

## 暂停界面资产

用户提供的暂停素材共 4 张 PNG，原始像素和透明通道原样保留，归档在 `assets/art/ui/pause_menu/`。中文原名、尺寸及 SHA-256 记录在 `assets/art/manifest.json`。按钮文字直接使用原图。

`scenes/ui/pause_menu.tscn` 按 1920×1080 参考画布布置。下表坐标为整张 PNG 的左上角，按钮点击区域为 390×80；素材共同等比缩放并居中。

| 原文件 | 项目文件 | 参考坐标（x, y） | 显示尺寸 |
| --- | --- | --- | --- |
| 暂停+透明背景.png | `pause_menu_overlay.png` | 0, 0 | 1920×1080 |
| 继续游戏.png | `pause_menu_resume.png` | 765, 397 | 390×80 |
| 设置.png（复用主菜单素材） | `main_menu_settings.png` | 765, 667 | 390×80 |
| 主菜单.png | `pause_menu_main_menu.png` | 765, 757 | 390×80 |
| 退出游戏.png | `pause_menu_quit.png` | 765, 847 | 390×80 |

保存游戏与读取存档两个按钮由 `pause_menu.gd` 使用项目字体和代码样式建立，参考位置分别为 `(765,487)`、`(765,577)`，尺寸均 `390×80`，其余按钮运行坐标按上表更新。五槽位 `save_slots_panel.gd` 为 CanvasLayer 55，复用菜单背景和项目字体，用代码绘制边框、缩略预览、名称输入、时间／地点信息及确认控件，没有新增用户位图。

运行时保留并冻结当前游戏画面，通过 `shaders/pause_gaussian_blur.gdshader` 分别执行水平、垂直两遍高斯模糊，两遍之间使用全视口 `BackBufferCopy`。随后用 `Overlay` ColorRect 绘制与原底板一致的 RGBA（26, 46, 101, 142）半透明遮罩，再叠加标题和按钮；按钮保持清晰。

暂停标题通过 AtlasTexture 从 `pause_menu_overlay.png` 的 `(896, 352, 128, 64)` 区域取字形，独立放在参考位置 `(880, 284)`、尺寸 `160×80`，保留相对原始字形上移和放大后的布局。`shaders/pause_title.gdshader` 提取字形为白字透明底，消除原蓝底的叠加；更新标题时同时保留 Atlas 区域与该材质的关系。

暂停图片采用线性过滤、无损导入并关闭 mipmaps。更换素材时保留文件路径、画布、透明通道及坐标关系；原始 ZIP 留在项目外。图片、收集弹窗和水井解谜的 Esc 退出由原界面优先处理，暂停界面仅在一级游戏界面打开。

## 设置界面资产

2026-10-18 接入用户提供的六张 PNG，原字节、画布、像素和透明通道完整保留在 `assets/art/ui/settings_menu/`。`assets/art/manifest.json` 记录中文原名、临时目录来源路径、尺寸、非零 alpha 外接矩形、alpha 范围与 SHA-256。来源路径仅用于归档，运行通过项目内 `res://` 资源引用。

| 原文件 | 项目文件 | 用途与尺寸 |
| --- | --- | --- |
| 设置+背景.png | `settings_overlay.png` | 1920×1080 设置底板，含标题与三行标签 |
| 设置界面.png | `settings_reference.png` | 1920×1080 完整布局参考，单独归档 |
| 箭头.png | `settings_handle.png` | 50×50 透明拖动箭头，三条滑杆共用 |
| 返回.png | `settings_back.png` | 370×80 返回图片按钮 |
| 重置为默认值.png | `settings_reset.png` | 370×80 重置图片按钮 |
| 音量线.png | `settings_track.png` | 200×90 透明横条，三条滑杆共用 |

设置底板与完整参考图的背景像素为 RGBA（26, 46, 101, 142），alpha 范围 142–255；其余四图 alpha 范围为 0–255。运行整张显示 `settings_overlay.png`，独立叠加可操作横条、箭头与图片按钮；`settings_reference.png` 保留作构图参考。图片采用线性过滤、无损导入并关闭 mipmaps，保留 `.import` 设置。

设置页按 1920×1080 参考画布等比缩放并居中。音效、背景音乐、亮度三条滑杆的原横条左上角依次为 `(1311, 304)`、`(1311, 403)`、`(1311, 502)`，可见横线在原图的 `(13, 54)` 至 `(189, 57)`；箭头在横线上方沿有效横线区间移动。三条数值独立使用项目字体，在横条右侧实时显示。重置按钮原图位于 `(775, 707)`，返回按钮位于 `(775, 797)`；后续微调以设置页代码中的参考矩形为准。

主菜单打开设置时隐藏全部原按钮文字，保留背景与 Lunar 标题，先经过水平、垂直两遍高斯模糊，再叠加半透明设置底板与清晰控件。暂停打开设置时隐藏原暂停标题与按钮，复用已冻结游戏画面的模糊层。返回和重置按钮复用 `menu_hover_button.gd` 的悬停与按压反馈。

该批接入时仅静态核对原图字节、尺寸、透明数据、导入配置、资源清单和引用；未启动 Godot、游戏、验证场景或自动化测试。实际构图、窗口适配、拖动、数值与背景模糊待用户手工验收。

## 菜单悬停与按压

主菜单、暂停菜单和设置页图片按钮共用用户提供的悬停 PNG，原图保存为 `assets/art/ui/panels/menu_hover_background.png`，原始像素与透明通道保持不变。`resources/art/ui/menu_hover_background.tres` 选取主体与柔光区域（176, 96, 1823, 514），隐藏透明画布留白。图片采用无损导入、线性过滤并关闭 mipmaps。

菜单图片按钮共用 `scripts/ui/menu_hover_button.gd`。背景在原文字下方绘制，尺寸按按钮宽的 1.5 倍、高的 4/3 倍计算：300×60 主菜单按钮对应 450×80、390×80 暂停按钮对应 585×106.67、370×80 设置按钮对应 555×106.67，居中于原按钮；文字、背景、标题、按钮坐标与点击区域由各自界面配置维护。悬停背景在 0.18 秒内淡入并轻微展开，移开在 0.14 秒内淡出。素材自身的半透明颜色原样保留。

按下时仅视觉层在 0.08 秒内缩至 97% 并下移 4 个参考像素，松开后 0.16 秒回弹。特效与文字子层均忽略鼠标输入。禁用的“继续游戏”沿用原外观与不可点击规则；切页、隐藏菜单、窗口移出时清理动画，返回与调整窗口尺寸后同步悬停位置。
