extends Control

# ==========================================
# ⚙️ 触发规则配置 (Trigger Rules)
# ==========================================
@export_group("事件触发规则")
@export var start_turn: int = 5       # 从第几回合开始出现第一个事件
@export var event_interval: int = 3   # 之后每隔几回合出现一次 (1表示每回合都出)

# 🌟 新增：可以在属性面板里直接修改的冷却次数
@export var cooldown_drafts: int = 3  # 选过的事件在接下来的几次抽卡中不会出现

# 在右侧属性面板里，把所有的 .tres 事件文件塞进这个数组
@export_group("事件池")
@export var all_events: Array[EventResourceData] = []

@onready var slots = [
	$TextureRect/VBoxContainer/Event_slot1,
	$TextureRect/VBoxContainer/Event_slot2,
	$TextureRect/VBoxContainer/Event_slot3
]

@onready var animator = get_node_or_null("PanelAnimator")

# ==========================================
# ⏳ 本地冷却状态字典 (Local Cooldowns)
# 格式: { "event_name": 剩余冷却回合数 }
# ==========================================
var event_cooldowns: Dictionary = {}

func _ready():
	hide()
	for slot in slots:
		slot.event_selected.connect(_on_event_selected)
		
	# 戴上耳机，偷听大本营的回合开始信号
	if GameResourceManager.has_signal("turn_started"):
		GameResourceManager.turn_started.connect(_on_turn_started)

# ==========================================
# 🕒 回合监听系统
# ==========================================\
func _on_turn_started(current_turn: int):
	if current_turn < start_turn:
		return
		
	if (current_turn - start_turn) % event_interval == 0:
		trigger_random_events()

# ==========================================
# 🃏 核心抽牌逻辑 (带冷却过滤)
# ==========================================
func trigger_random_events():
	# ------------------------------------------------
	# 1. 推进本地冷却字典的进度
	# ------------------------------------------------
	var keys = event_cooldowns.keys()
	for key in keys:
		event_cooldowns[key] -= 1
		if event_cooldowns[key] <= 0:
			event_cooldowns.erase(key)
			print("【事件系统】", key, " 冷却完毕，重新加入卡池！")

	# ------------------------------------------------
	# 2. 过滤出当前可用的事件
	# ------------------------------------------------
	var available_events = []
	for event in all_events:
		# 如果这个事件的名字不在小黑屋字典里，就说明可用
		if not event_cooldowns.has(event.event_name):
			available_events.append(event)
			
	# 🛡️ 防呆保护：如果过滤完发现不够 3 张卡了，强制清空小黑屋放人！
	if available_events.size() < 3:
		print("【事件系统警告】可用事件不足 3 个，强制清空所有冷却状态！")
		event_cooldowns.clear()
		available_events = all_events.duplicate()

	# 再次安全检查
	if available_events.size() < 3:
		push_error("【事件系统错误】事件池里的总事件依然不足 3 个，无法抽取！")
		return
		
	# ------------------------------------------------
	# 3. 正常打乱并发牌
	# ------------------------------------------------
	available_events.shuffle()
	var chosen_events = available_events.slice(0, 3)
	
	for i in range(3):
		slots[i].setup(chosen_events[i])
		
	if animator and animator.has_method("open_panel"):
		animator.open_panel() 
	else:
		push_error("动画节点函数名称错误")

# ==========================================
# 🎯 玩家选择事件响应
# ==========================================
func _on_event_selected(event_data: EventResourceData):
	print("玩家选择了事件: ", tr(event_data.event_name))
	
	# 🌟【核心新增】：将刚刚选中的事件关入本地小黑屋！
	event_cooldowns[event_data.event_name] = cooldown_drafts
	print("【事件系统】", event_data.event_name, " 被关入小黑屋，接下来的 ", cooldown_drafts, " 次抽卡都不会遇到它了。")
	
	# 1. 关闭选择菜单
	if animator and animator.has_method("close_panel"):
		animator.close_panel() 
	else:
		push_error("动画节点函数名称错误")
		
	# 停顿 0.5 秒，营造危机降临的压迫感
	await get_tree().create_timer(0.5).timeout
	
	# 寻找并呼出详情面板，移交数据！
	var detail_menu = get_tree().get_first_node_in_group("event_detail")
	if detail_menu and detail_menu.has_method("show_event_details"):
		detail_menu.show_event_details(event_data)
	else:
		push_error("找不到 event_detail 组的节点，或者该节点没有 show_event_details 方法！")
