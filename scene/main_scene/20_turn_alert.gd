extends Node

func _ready():
	# 偷听 GameResourceManager 发出的“回合开始”信号
	if GameResourceManager.has_signal("turn_started"):
		GameResourceManager.turn_started.connect(_on_turn_started)

# 当接收到信号时，检查回合数
func _on_turn_started(turn_count: int):
	if turn_count == 20:
		_show_turn_20_alert()

# ==========================================
# 弹窗逻辑
# ==========================================
func _show_turn_20_alert():
	var dialog = AcceptDialog.new()
	dialog.title = "数值测试"
	dialog.dialog_text = "极限挑战结束！\n\n现在是第 20 回合，快看看你有没有凑够 70 个石头？"
	
	# 把弹窗加到当前场景树里
	get_tree().root.add_child(dialog)
	
	# 居中弹出
	dialog.popup_centered()
	
	# 当玩家点击确认时，直接把这个弹窗销毁，不留垃圾
	dialog.confirmed.connect(func(): dialog.queue_free())
