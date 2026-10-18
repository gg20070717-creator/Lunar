extends RefCounted
## Act Four branch narratives; STORY_BRANCHES drives Act Five continuations.

const INTRO_PAGES: Array[Dictionary] = [
	{
		"speaker": "Luna",
		"text": "月影从潮汐中涌现。",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "事实果真如此吗？",
		"show_protagonist": false,
	},
	{
		"speaker": "Luna",
		"text": "月影从潮汐中涌现。",
		"show_protagonist": false,
	},
]

const RESISTANCE_PAGES: Array[Dictionary] = [
	{
		"speaker": "Luna",
		"text": "是“月影从潮汐中涌现”。",
		"show_protagonist": false,
	},
	{
		"speaker": "Luna",
		"text": "小汐，听我的，别再多想了。",
		"show_protagonist": false,
	},
]

const LUNA_PAGES: Array[Dictionary] = [
	{
		"speaker": "",
		"text": "所有结果完全符合公式推导。",
		"show_protagonist": false,
		"cg_image": "res://resources/art/cg/act_04/cg_04_luna.tres",
		"cg_replace": true,
	},
	{
		"speaker": "",
		"text": "飞船奇迹般地出现在你眼前。宇航员从驾驶舱中钻出，向欢呼的人群挥舞双臂。",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "你被鲜花与掌声吞没，兴奋到忘乎所以。",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "小泠恰到好处地出现在你身后，送你一束铃兰与一个拥抱。",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "人类的新纪元就此开启了——太空航行的时间被大幅缩短，星际殖民终于成为了可能。",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "一切本该如此。",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "小汐，一切本该如此。",
		"show_protagonist": false,
	},
]

const TRUTH_PAGES: Array[Dictionary] = [
	{
		"speaker": "",
		"text": "回忆如同自地底涌出的内生泉，在脑海中奔涌浮现。",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "——地面控制室里，弦音科技总裁按下按钮。",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "现实世界以月球为圆心扩散出一圈圈涟漪，穿过你的意识，让你眼前的世界奇异地闪动一帧。",
		"show_protagonist": false,
		"cg_image": "res://resources/art/cg/act_04/cg_04_truth_01.tres",
	},
	{
		"speaker": "",
		"text": "你的大脑被瞬间清空，强烈的失重感让你失去平衡你捂着头跪倒在地，直到耳鸣消退，周围人的呼喊也慢慢清晰起来。",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "你听见他们说，月亮消失了。",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "原本沉睡着的幽蓝夜空毫无预兆地裂开一道巨大口子，整片海域被引力拉扯，海水呼啸着被吸入漆黑的裂隙之中。",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "大地开始剧烈晃动，一座座高楼建筑像多米诺骨牌一般接连倒下。",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "引力失衡让混凝土碎片悬浮在半空又重重砸落，平整坚硬的柏油马路被这突如其来的力量生生撕裂，张开的狰狞大口，吞下还不及躲避的车辆与行人。",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "在整片城市天翻地覆的纷乱之中，你顾不上身后不断坠落的碎片与震耳欲聋的轰鸣，本能地向着你们的家狂奔而去。",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "你心脏狂跳，脑中画面纷飞——没有看成的电影，画布上涂抹的月光——小泠一定不能有事——",
		"show_protagonist": false,
		"cg_image": "res://resources/art/cg/act_04/cg_04_truth_02.tres",
	},
	{
		"speaker": "",
		"text": "登上距离你家几百米之遥的高地，你的心猛地一沉。",
		"show_protagonist": false,
		"cg_image": "res://resources/art/cg/act_04/cg_04_truth_03.tres",
	},
	{
		"speaker": "",
		"text": "整个街区都被潮水吞没了，你甚至根本辨不出你的家原本在哪个位置。",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "你的后脑猛地被钢筋击中。",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "你脚下一软，掉进了水里。",
		"show_protagonist": false,
	},
]

const STORY_BRANCHES: Array[Dictionary] = [
	{
		"id": &"luna",
		"label": "Luna导向",
		"next_story_id": &"cg_05_false",
		"pages": LUNA_PAGES,
	},
	{
		"id": &"truth",
		"label": "真实导向",
		"next_story_id": &"cg_05_true",
		"pages": TRUTH_PAGES,
	},
]
