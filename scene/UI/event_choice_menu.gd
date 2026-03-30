extends Control

# ==========================================
# ⚙️ 触发规则配置 (Trigger Rules)
# ==========================================
@export_group("事件触发规则")
@export var start_turn: int = 5       # 从第几回合开始出现第一个事件
@export var event_interval: int = 3   # 之后每隔几回合出现一次 (1表示每回合都出)

# 在右侧属性面板里，把所有的 .tres 事件文件塞进这个数组
@export_group("事件池")
@export var all_events: Array[EventResourceData] = []

@onready var slots = [
	$TextureRect/VBoxContainer/Event_slot1,
	$TextureRect/VBoxContainer/Event_slot2,
	$TextureRect/VBoxContainer/Event_slot3
]

@onready var animator = get_node_or_null("PanelAnimator")

func _ready():
	hide()
	for slot in slots:
		slot.event_selected.connect(_on_event_selected)
		
	# 【核心新增】：戴上耳机，偷听大本营的回合开始信号
	if GameResourceManager.has_signal("turn_started"):
		GameResourceManager.turn_started.connect(_on_turn_started)

# ==========================================
# 🕒 回合监听系统
# ==========================================
func _on_turn_started(current_turn: int):
	# 1. 如果还没到设定的起始回合，直接忽略
	if current_turn < start_turn:
		return
		
	# 2. 计算是否满足触发间隔
	# 公式解析：(当前回合 - 起始回合) % 间隔 == 0
	# 假设起始为 5，间隔为 3。
	# 第 5 回合：(5-5)%3 = 0 (触发)
	# 第 6 回合：(6-5)%3 = 1 (不触发)
	# 第 8 回合：(8-5)%3 = 0 (触发)
	if (current_turn - start_turn) % event_interval == 0:
		trigger_random_events()

# ==========================================
# 🃏 核心抽牌逻辑 (保持不变)
# ==========================================
func trigger_random_events():
	if all_events.size() < 3:
		push_error("【事件系统错误】事件池里的事件不足 3 个，无法抽取！请在检查器中添加更多事件。")
		return
		
	var pool = all_events.duplicate()
	pool.shuffle()
	var chosen_events = pool.slice(0, 3)
	
	for i in range(3):
		slots[i].setup(chosen_events[i])
		
	if animator and animator.has_method("open_panel"):
		animator.open_panel() 
	else:
		push_error("动画节点函数名称错误")

func _on_event_selected(event_data: EventResourceData):
	print("玩家选择了事件: ", tr(event_data.event_name))
	
	# 1. 关闭选择菜单
	if animator and animator.has_method("close_panel"):
		animator.close_panel() 
	else:
		push_error("动画节点函数名称错误")
		
	# ==========================================
	# 【核心修改】：停顿 1.0 秒，营造危机降临的压迫感
	# ==========================================
	await get_tree().create_timer(1.0).timeout
	
	# ==========================================
	# 【核心修改】：寻找并呼出详情面板，移交数据！
	# ==========================================
	var detail_menu = get_tree().get_first_node_in_group("event_detail")
	if detail_menu and detail_menu.has_method("show_event_details"):
		detail_menu.show_event_details(event_data)
	else:
		push_error("找不到 event_detail 组的节点，或者该节点没有 show_event_details 方法！")
