
extends VBoxContainer

# ==========================================
@export var start_turn: int = 0
@export var event_interval: int = 0

# 获取子节点 (请将这里的名字替换为你实际的 Label 节点名)
@onready var turn_label = $turns
@onready var event_label = $event_label

func _ready():
	var event_choice_menu = get_tree().get_first_node_in_group("event_choice_menu")
	
	# 【增加安全判断】：确保找到了节点再取值
	if event_choice_menu:
		start_turn = event_choice_menu.start_turn
		event_interval = event_choice_menu.event_interval
	else:
		push_warning("警告：场景中没有找到属于 event_choice_menu 组的节点！将使用默认回合设置。")
		
	# 监听大本营发出的回合开始信号
	if GameResourceManager.has_signal("turn_started"):
		GameResourceManager.turn_started.connect(_update_ui)
	# 游戏刚开始时，强行初始化一次显示为第 1 回合
	_update_ui(1)
	
# 当回合更新时，自动计算并刷新文字
func _update_ui(current_turn: int):
	# 1. 显示当前回合
	turn_label.text = tr("turn") + ": " + str(current_turn)
	
	# 2. 计算距离下一次事件还有几回合
	var turns_left: int = 0
	
	if current_turn < start_turn:
		# 还没到第一次事件
		turns_left = start_turn - current_turn
	else:
		# 已经度过了第一次事件，推算下一次
		var next_event_turn = start_turn
		
		# 利用 while 循环找出下一个大于当前回合的触发点
		while next_event_turn <= current_turn:
			# 如果当前回合刚好就是事件触发回合！
			if next_event_turn == current_turn:
				event_label.text = tr("event_coming")# 如果你用了 RichTextLabel 可以加颜色
				return # 直接结束函数，不显示剩余回合了
				
			next_event_turn += event_interval
			
		# 计算差值
		turns_left = next_event_turn - current_turn

	# 3. 显示倒计时
	event_label.text = tr("event_left")+ ": " + str(turns_left)
