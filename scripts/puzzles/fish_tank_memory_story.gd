extends RefCounted
## Fish tank introduction, Act Three memory, and Act Four follow-up dialogue.
# 第三幕鱼缸解密前；幕标题与进解密备注不显示。
const INTRO_PAGES: Array[Dictionary] = [
	{
		"speaker": "Luna",
		"text": "我从来不喜欢听你聊工作。我只是想和你聊聊漫画，电影，可自从来首都后我们的生活就只剩下你的研究了——",
		"show_protagonist": false,
	},
	{
		"speaker": "你",
		"text": "......我很抱歉。",
		"expression": &"speaking",
		"show_protagonist": true,
	},
	{
		"speaker": "",
		"text": "她的声音忽然轻快起来，让你不由得觉得有些反常。",
		"expression": &"neutral",
		"show_protagonist": true,
	},
	{
		"speaker": "Luna",
		"text": "没关系，小汐，我们的时间还有很多。",
		"expression": &"neutral",
		"show_protagonist": true,
	},
]

# 情节块 3：科研与晚餐整图按页替换，幻觉两页清屏。
const NARRATIVE_PAGES: Array[Dictionary] = [
	{
		"speaker": "你",
		"text": "我回来了！",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "你刚进门就被手里沉甸甸的袋子绊了一下——袋子里装着冰好的啤酒可乐还有炸鸡薯片。",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "你的脚步一下踉跄，控制不住重心，整个人向着前方倾倒过去。",
		"show_protagonist": false
	},
	{
		"speaker": "小泠",
		"text": "呀！",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "你被沾着颜料的柔软双手接住，鼻尖嗅到熟悉的洗衣粉香气。抬头，小泠笑着看你。",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "你一整年埋在书山题海里的日夜苦读没有白费，最终拿到了首都大学物理系的录取通知书，",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "而小泠也放弃了老家本地的艺术院校机会，随着你一起来到了繁华的首都。",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "2089年，你硕士毕业之后，你听从父母的安排，进入弦音科技公司的总部研究所，负责引力波引擎的研发工作。",
		"show_protagonist": false,
		"cg_image": "res://resources/art/cg/act_03/cg_03_work.tres",
		"cg_replace": true,
	},
	{
		"speaker": "",
		"text": "弦音科技的核心业务围绕引力波引擎展开，但老员工都清楚，公司董事长早年是做脑机接口出身，",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "后来被媒体曝出开展非人道生物实验，这才推动公司整体转型，投入更加政治正确的环保引擎开发。",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "公司内部一直流传着地下室藏着恐怖实验之类的小道传闻，但你对此毫不在意，反正你的工牌刷不开那层。",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "显然，你并不相信弦音科技“改变能源结构，解决全球变暖”的那一套，",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "但他们支付给研究员的薪水足够让你闭嘴干活——你在首都不错的街区买了套小独栋后，",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "余下的存款也足够支撑你和小泠两人的生活。",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "至于小泠，她接稿就是有一单没一单的。搞艺术的嘛。",
		"show_protagonist": false
	},
	{
		"speaker": "小泠",
		"text": "（捡起散落的东西）今天怎么回来这么早？",
		"show_protagonist": false
	},
	{
		"speaker": "你",
		"text": "实验进行得很顺利，采集到的所有实验数据都很漂亮，完全符合我们之前的预期。",
		"show_protagonist": false
	},
	{
		"speaker": "你",
		"text": "老板很满意，提前放我们走，不用留在所做收尾整理了。（看向厨房）哇塞，你还点了披萨？！",
		"show_protagonist": false,
		"cg_image": "res://resources/art/cg/act_03/cg_03_dinner.tres",
		"cg_replace": true,
	},
	{
		"speaker": "",
		"text": "你笑嘻嘻地跑到擦桌边，准备用脏手抓起披萨往嘴里塞。",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "忽然，眼前的景象变了。天花板滴下水，一地，两滴，餐桌上是泛着酸臭的罐头和发霉的压缩饼干。",
		"show_protagonist": false,
		"cg_clear": true,
	},
	{
		"speaker": "",
		"text": "积水漫过你脚踝，几张被水浸湿的稿纸向你飘来。你知道，如果按照纸上的算式推导，必然得出那个结果——",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "小泠在你手上轻拍一下，把你拉回现实。",
		"show_protagonist": false,
		"cg_image": "res://resources/art/cg/act_03/cg_03_dinner.tres",
		"cg_replace": true,
	},
	{
		"speaker": "小泠",
		"text": "喂，先去洗手。",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "她察觉到你神情异样。",
		"show_protagonist": false
	},
	{
		"speaker": "小泠",
		"text": "小汐，你怎么了？",
		"show_protagonist": false
	},
	{
		"speaker": "你",
		"text": "没什么。我做实验做出幻觉了。",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "你乖乖去洗手后在餐桌旁坐定。这是你一天中最幸福的时刻——逃离你算不上热爱的工作，和她在餐桌前享用食物。",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "杯中的淡色艾尔啤酒冒着细密的气泡，微醺的酒意逐渐朦胧了你的视野，桌上暖黄色的灯光漫溢开来，",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "在她清亮的眼底慢慢晕开。这样的瞬间会让你觉得，选择物理研究这条路是正确的。",
		"show_protagonist": false
	},
	{
		"speaker": "小泠",
		"text": "......所以你能给我带月壤吗？",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "小泠对你们公司那个月球计划比你热衷得多。她对自己脱产画画这件事有些敏感，",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "于是主动和你聊起工作上的话题，好让自己看起来没那么脱离社会。",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "你心里清楚，首都从没给过她安全感，是故乡小城的明月始终让她魂牵梦萦。",
		"show_protagonist": false
	},
	{
		"speaker": "你",
		"text": "说什么傻话呢，我又不是阿姆斯特朗。这次实验风险很高，监管部门怎么都不同意我们在地球上开展实机测试。",
		"show_protagonist": false
	},
	{
		"speaker": "你",
		"text": "所以引力波引擎会先由运载火箭送上月球，再由地面站的工程师远程操作——如果所有环节顺利，",
		"show_protagonist": false
	},
	{
		"speaker": "你",
		"text": "只要在控制中心按下启动按钮，整艘试验飞船就会“咻”的一下，通过引力折叠通道直接闪回地球的发射基地——",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "你喋喋不休，夸张地比着手势，没有注意到小泠脸上一闪而过的尴尬。",
		"show_protagonist": false
	},
	{
		"speaker": "小泠",
		"text": "好了好了。对了，《铃兰女校弓道部》出新剧场版了，下周末一起去看吧？",
		"show_protagonist": false
	},
	{
		"speaker": "你",
		"text": "下周末？唉火箭马上就要发射了，哪里有时间......",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "小泠叹一口气。",
		"show_protagonist": false
	},
	{
		"speaker": "小泠",
		"text": "随便吧。就当我没说过。",
		"show_protagonist": false
	}
]

# 情节块 3 完整读完后，在原客厅衔接第四幕对白；微剧情与提前退出不触发。
const FOLLOWUP_PAGES: Array[Dictionary] = [
	{
		"speaker": "",
		"text": "那是什么？",
		"expression": &"neutral",
		"show_protagonist": true,
	},
	{
		"speaker": "",
		"text": "回忆里突兀插入的一帧，让你深感到不安。你遗漏了什么非常重要的东西。",
		"expression": &"neutral",
		"show_protagonist": true,
	},
	{
		"speaker": "你",
		"text": "我记起了一些不太对的东西——究竟发生了什么？我到底忘记了什么？",
		"expression": &"speaking",
		"show_protagonist": true,
	},
	{
		"speaker": "",
		"text": "你脑中的声音变了。它不再亲切熟悉，反而变得冷漠、僵硬，甚至令人毛骨悚然。",
		"expression": &"neutral",
		"show_protagonist": true,
	},
	{
		"speaker": "Luna",
		"text": "潮汐偏要去找比记忆更深的东西，结果翻上来的确实比灾变还要旧的伤口。",
		"expression": &"neutral",
		"show_protagonist": true,
	},
	{
		"speaker": "Luna",
		"text": "我执意把月光留在岸上，月光却执意沉入湖底。洪水退去后，内生泉水开始涌出。大地的裂隙永远不会愈合了。",
		"expression": &"neutral",
		"show_protagonist": true,
	},
	{
		"speaker": "你",
		"text": "......什么？",
		"expression": &"speaking",
		"show_protagonist": true,
	},
	{
		"speaker": "Luna",
		"text": "不，不，不。",
		"expression": &"neutral",
		"show_protagonist": true,
		"shake": true,
	},
	{
		"speaker": "Luna",
		"text": "所有一切等于1110101错误。来到首都等于错错错错错错误。弦音科0011技等于错误。不，不，不，事情本该如此——",
		"expression": &"neutral",
		"show_protagonist": true,
		"shake": true,
	},
	{
		"speaker": "",
		"text": "——你的后脑又传来被敲击的钝痛。",
		"expression": &"neutral",
		"show_protagonist": true,
	},
	{
		"speaker": "Luna",
		"text": "哈哈，小汐。记得我们在客厅摆的小帐篷吗？你送我的那只小兔玩偶还摆在哪里呢。",
		"expression": &"neutral",
		"show_protagonist": true,
	},
	{
		"speaker": "Luna",
		"text": "哈哈，小汐。记得我们在客厅摆的小帐篷吗？你送我的那只小兔玩偶还摆在哪里呢。",
		"expression": &"neutral",
		"show_protagonist": true,
	},
	{
		"speaker": "Luna",
		"text": "哈哈，小汐。记得我们在客厅摆的小帐篷吗？你送我的那只小兔玩偶还摆在哪里呢。",
		"expression": &"neutral",
		"show_protagonist": true,
	},
	{
		"speaker": "",
		"text": "脑中的声音一遍又一遍地重复同一句话。",
		"expression": &"neutral",
		"show_protagonist": true,
	},
	{
		"speaker": "",
		"text": "这个声音到底是如何被植入到你的大脑里的？",
		"expression": &"neutral",
		"show_protagonist": true,
	},
	{
		"speaker": "",
		"text": "你预感真相正在向你靠近。",
		"expression": &"neutral",
		"show_protagonist": true,
	},
]
