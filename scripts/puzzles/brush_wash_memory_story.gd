extends RefCounted
## The studio bucket introduction, Act Two memory, and follow-up narration.
const INTRO_PAGES: Array[Dictionary] = [
	{
		"speaker": "Luna",
		"text": "你还记得她为什么要一遍又一遍地画月亮吗？",
		"show_protagonist": false,
	},
	{
		"speaker": "主角",
		"text": "……我不记得了。",
		"expression": &"speaking",
	},
	{
		"speaker": "Luna",
		"text": "回忆会给你答案的。",
	},
]

# Act Two: the supplied window CG begins with Xiaoling; keep the wording and route.
const NARRATIVE_PAGES: Array[Dictionary] = [
	{
		"speaker": "",
		"text": "2082年的夏天，这座城市迎来了本世纪最大的一场雨。",
		"show_protagonist": false
	},
	{
		"speaker": "妈妈",
		"text": "小汐，你最近到底怎么了？你理科这么强，只要英语再努努力，完全能够到首都大学的物理专业。",
		"show_protagonist": false
	},
	{
		"speaker": "妈妈",
		"text": "你整天画这些乱七八糟的，还分不分得清主次？",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "她在得知你成绩下滑后，发疯一般闯进你的卧室，翻出了小泠送给你的漫画和你的画本。",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "餐桌上摆着的画满漫画的草稿纸即是罪证，你坐在餐桌另一头，等待母亲对你的审判。",
		"show_protagonist": false
	},
	{
		"speaker": "妈妈",
		"text": "（深深吸一口气）小汐啊，你在物理领域有天赋，妈妈一直看在眼里。",
		"show_protagonist": false
	},
	{
		"speaker": "妈妈",
		"text": "现在有两个大热门，一个脑机接口，一个空间物理，你这么高的天资，去首都大学读个物理学硕士，",
		"show_protagonist": false
	},
	{
		"speaker": "妈妈",
		"text": "爸爸妈妈都在弦音科技工作，完全可以把你安排进总部研究所......",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "你不耐烦地用筷子翻动着碗里的饭菜，一句话也听不进去。",
		"show_protagonist": false
	},
	{
		"speaker": "你",
		"text": "我想考美院。",
		"show_protagonist": false
	},
	{
		"speaker": "妈妈",
		"text": "......什么？",
		"show_protagonist": false
	},
	{
		"speaker": "你",
		"text": "我想考美院。就我们市的小美院，留在这里挺好的。",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "你看着母亲脸上的错愕转变成愤怒。这样的愤怒几分出于对你的关心，几分出于自己权威被挑战的恼羞成怒，你不得而知。",
		"show_protagonist": false
	},
	{
		"speaker": "妈妈",
		"text": "你疯了吧？你有为你的前途考虑过吗？爸爸妈妈辛苦工作这么多年，不是让你去当什么乱七八糟的艺术家的！",
		"show_protagonist": false
	},
	{
		"speaker": "妈妈",
		"text": "你有替我们考虑过吗？你有替自己的前途考虑过吗？",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "母亲愤而站起身，绕着餐厅来回踱步。你盯着桌上一筷未动的饭菜，忍住不哭出来。她突然停下，转向你，神情几乎是哀求。",
		"show_protagonist": false
	},
	{
		"speaker": "妈妈",
		"text": "小汐，我知道你是真的喜欢画画，你说想读美院也是认真的。但我请你好好想一想，学艺术真的有前途吗？",
		"show_protagonist": false
	},
	{
		"speaker": "妈妈",
		"text": "如果你学物理，你可以去最好的科技公司，给你和家人提供优渥的物质生活，休闲时间照样可以继续画画。",
		"show_protagonist": false
	},
	{
		"speaker": "妈妈",
		"text": "这样不好吗？为什么非得选一条风险更高的路呢？",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "听着母亲给你许诺的未来，你脑中一遍又一遍回放与小汐在一起的时光。",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "和她在一起，你无需考虑未来，因为当下的每分每秒都弥足珍贵。可是这样真的被允许吗？",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "你真的可以逃避父母的期许与成家立业的责任，和你真正想要的人一起做你真正想做的事吗？",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "母亲看见你神情软下来，拉开椅子坐到你身边。",
		"show_protagonist": false
	},
	{
		"speaker": "妈妈",
		"text": "妈妈知道小泠想留在本地读小美院，而你想陪着她，这我都可以理解。",
		"show_protagonist": false
	},
	{
		"speaker": "妈妈",
		"text": "可首都有全国最好的美院，为什么她不努努力去考首都美院呢？",
		"show_protagonist": false
	},
	{
		"speaker": "妈妈",
		"text": "要是你们一起去首都念书，尽管不在一个大学，不也算有个伴吗？",
		"show_protagonist": false
	},
	{
		"speaker": "妈妈",
		"text": "妈妈知道，你想做什么事就一定会去做，我拦不住你。小汐，你再好好考虑考虑吧。",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "千言万语堵在喉咙，可望着你妈妈决绝又带着一丝恳求的神情，你什么也说不出口。",
		"show_protagonist": false
	},
	{
		"speaker": "小泠",
		"text": "好了，别再说了。",
		"cg_image": "res://resources/art/cg/act_02/cg_02_window.tres",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "雨声渐强，小泠背光对着你，你看不清她的神情。和母亲谈完后，你决定和她把话说开。",
		"cg_image": "res://resources/art/cg/act_02/cg_02_window.tres",
		"show_protagonist": false
	},
	{
		"speaker": "你",
		"text": "我们还是可以在同一个城市上学呀！小泠，你画得这么好，为什么就是不乐意考首都美院呢？",
		"cg_image": "res://resources/art/cg/act_02/cg_02_window.tres",
		"show_protagonist": false
	},
	{
		"speaker": "小泠",
		"text": "这是因为——",
		"cg_image": "res://resources/art/cg/act_02/cg_02_window.tres",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "她把脸埋进手心，深呼吸几次，转头望向窗外。漫天乌云遮住了月亮。",
		"cg_image": "res://resources/art/cg/act_02/cg_02_window.tres",
		"show_protagonist": false
	},
	{
		"speaker": "小泠",
		"text": "我无法在没有月光的夜晚入睡。首都的光污染太严重了......在那里我睡不着。",
		"cg_image": "res://resources/art/cg/act_02/cg_02_window.tres",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "你无言以对。就因为这个？和前途与未来相比，这问题实在是太渺小了。",
		"cg_image": "res://resources/art/cg/act_02/cg_02_window.tres",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "她察觉到了你自以为已经掩藏好的质疑。望着你的眼睛，她咬住下唇，像是下定了决心。",
		"cg_image": "res://resources/art/cg/act_02/cg_02_window.tres",
		"show_protagonist": false
	},
	{
		"speaker": "小泠",
		"text": "我想明白了，无论如何，我想要和你在一起。",
		"cg_image": "res://resources/art/cg/act_02/cg_02_window.tres",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "她握住你的双手，你的心因希望剧烈地跳动起来。",
		"cg_image": "res://resources/art/cg/act_02/cg_02_window.tres",
		"show_protagonist": false
	},
	{
		"speaker": "小泠",
		"text": "一起努力吧。我们首都见。",
		"cg_image": "res://resources/art/cg/act_02/cg_02_window.tres",
		"show_protagonist": false
	}
]

# 情节块 2 完整读完后，在原画室继续旁白；幕标题与任务备注不显示。
const FOLLOWUP_PAGES: Array[Dictionary] = [
	{
		"speaker": "",
		"text": "直到现在你才意识到，她和你一同搬来首都的决定背后牺牲了多少。",
		"expression": &"neutral",
		"show_protagonist": true,
	},
	{
		"speaker": "",
		"text": "桩桩件件的事情里，她始终在为你让步——就连家中客厅里的全部陈设，都几乎是按照你的想法布置的，",
		"expression": &"neutral",
		"show_protagonist": true,
	},
	{
		"speaker": "",
		"text": "无论是地毯颜色还是鱼缸里热带鱼的品种，她什么事都顺着你的心意。",
		"expression": &"neutral",
		"show_protagonist": true,
	},
	{
		"speaker": "",
		"text": "可迟来的愧疚是不作数的。",
		"expression": &"neutral",
		"show_protagonist": true,
	},
	{
		"speaker": "",
		"text": "你再也没有机会把客厅那条地毯换成她喜欢的款式，再也没有机会养她喜欢的小小猫而非昂贵的热带鱼，",
		"expression": &"neutral",
		"show_protagonist": true,
	},
	{
		"speaker": "",
		"text": "再也没有机会好好告诉她，你的付出我全部看在眼里。",
		"expression": &"neutral",
		"show_protagonist": true,
	},
	{
		"speaker": "",
		"text": "你愿意用一切换一个再次和她窝在沙发上看电视的机会。",
		"expression": &"neutral",
		"show_protagonist": true,
	},
	{
		"speaker": "",
		"text": "可你对她的记忆，几乎都已经消散殆尽了。",
		"expression": &"neutral",
		"show_protagonist": true,
	},
]
