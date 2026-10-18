extends RefCounted
## Act Five text and stable ending IDs. Images can be added independently.

const FALSE_ENDING_PAGES: Array[Dictionary] = [
	{"text": "皎皎明月高悬于天际，从第一个新生儿呱呱落地，直到最后一名老者类合上双眼。", "show_protagonist": false, "cg_image": "res://resources/art/cg/act_05/ending_false.tres", "cg_replace": true},
	{"text": "引力波引擎研发成功后，你顺利升职加薪，坐上了事少钱多的高层管理岗位。", "show_protagonist": false},
	{"text": "小泠的作品被藏家相中，画作被成批运进市中心美术馆参展，随后又在拍卖行卖出了不可思议的高价。", "show_protagonist": false},
	{"text": "多年以后，你们搬回了故乡，在一座简朴的小房子里度过余生。", "show_protagonist": false},
	{"text": "你的生活足够平凡也足够幸福。", "show_protagonist": false},
]

const TRUTH_RECOLLECTION_PAGES: Array[Dictionary] = [
	{"text": "所有回忆浮上脑海。你终于记起了一切。", "show_protagonist": false, "cg_clear": true},
	{"text": "意识深潜。这是弦音科技应对这场灾难的最后手段。", "show_protagonist": false},
	{"text": "你被一小队幸存者救起，送进了弦音科技公司在地下秘密设置的避难所。这里安置着公司早年被迫中止的研究项目——意识深潜装置。", "show_protagonist": false},
	{"text": "将装置接入大脑，就能够备份意识，上传到一段虚假的回忆当中。", "show_protagonist": false},
	{"text": "避难所里的人和你一样浑身湿透，也都不再掩饰绝望。你无法想象地表现在正在发生什么，你只是知道，对人类文明的毁灭性打击已经发生了。", "show_protagonist": false},
	{"text": "启动意识上传吧，你听见自己开口说道。如果后世还能有文明找到这台装置，我们至少能留下人类曾来过的痕迹。", "show_protagonist": false},
	{"text": "你浑浑噩噩的爬进装置。机器自动启动，扫描你的脑电波，将你的意识逐渐抽离。", "show_protagonist": false},
	{"text": "你的最后一个想法是，要是能再和小泠看一次月亮就好了。", "show_protagonist": false},
]

const EXPLORATION_PAGES: Array[Dictionary] = [
	{"text": "你记起来了。链接真实与虚拟的意识深潜仪在一楼储物间里，钥匙就在玄关花盆里。", "show_protagonist": true},
	{"speaker": "Luna", "text": "小汐......", "show_protagonist": true},
	{"text": "你不再听从她的话。", "show_protagonist": true},
]

const DEVICE_PAGES: Array[Dictionary] = [
	{"text": "她只是一段程序，仅此而已。她做出的所有挽留，不过是意识深潜装置的内部修复指令而已。", "show_protagonist": false},
	{"text": "你并不感到悲伤。是假的又如何？人类灭绝后，你还能最后听一次她的声音，这是何等奢侈。", "show_protagonist": false},
	{"text": "困在电脑模拟出的虚假记忆里，你就能多留她在身边一段时日。可脱离意识深潜装置之后，你该何去何从？你又该怎么在这个被引力与潮汐摧毁的世界里活下去呢？", "show_protagonist": false},
	{"text": "可意识深潜装置迟早会耗尽最后一点能源，她虚假的陪伴也注定不会永久。也许离开还能有一线生机，也许文明还有重建的可能——", "show_protagonist": false},
	{"speaker": "Luna", "text": "小汐，你要走了吗？", "show_protagonist": false},
	{
		"speaker": "你", "text": "", "show_protagonist": false,
		"choices": [
			{"id": &"leave", "text": "是的，再见。"},
			{"id": &"stay", "text": "不。请留在我身边吧，今晚我们去看你想看的那部电影。"},
		],
	},
]

const TRUE_ENDING_PAGES: Array[Dictionary] = [
	{"text": "你从营养液中坐起来，像一具被海洋吐出的尸体。", "show_protagonist": false},
	{"text": "你剧烈咳嗽，挣扎着从培养缸中爬了出来。粘稠的液体顺着脊椎滑落，你脚下一软，跪倒在地。", "show_protagonist": false},
	{"text": "你贴着真实的地面，感受着真实的心跳，在未能适应身体的眩晕中感受到了久违的实感。", "show_protagonist": false},
	{"text": "你不清楚自己有没有足够的勇气去面对一切。你深吸一口气，把最后一丝培养液的甜味从肺里挤出去。", "show_protagonist": false},
	{"text": "然后你站起身，向前迈步，走进现实。", "show_protagonist": false, "cg_image": "res://resources/art/cg/act_05/ending_true.tres", "cg_replace": true},
]
