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
		show()

func _on_event_selected(event_data: EventResourceData):
	print("玩家选择了事件: ", tr(event_data.event_name))
	
	if animator and animator.has_method("close_panel"):
		animator.close_panel() 
	else:
		hide()
		
	if event_data.effect_script:
		var effect_instance = event_data.effect_script.new() 
		if effect_instance.has_method("execution_event"):
			effect_instance.execution_event()
		else:
			push_warning("【警告】事件脚本缺少 'execution_event' 函数！无法执行惩罚。事件ID: " + event_data.event_id)
	else:
		push_warning("【警告】该事件没有配置效果脚本！直接关闭菜单。事件ID: " + event_data.event_id)

# (测试用的 F7 快捷键可以删掉了，因为现在全自动了！)
