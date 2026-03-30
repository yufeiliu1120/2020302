extends CanvasLayer # (如果你的根节点是 Control，这里就是 extends Control)

func _ready():
	# 1. 游戏一开始，直接把整个 UI 藏起来
	# 注意：如果你用的是 Control 节点，建议用 visible = false 或 modulate.a = 0
	visible = false 
	
	# 2. 戴上耳机，偷听“开场动画结束”的信号
	if SignalBusAutoload.has_signal("game_start"):
		SignalBusAutoload.game_start.connect(_on_game_start)

func _on_game_start():
	# 当收到游戏开始信号时，让 UI 优雅地显示出来
	visible = true
	
	# 【附赠果汁】：如果你想让 UI 的出现更顺滑，可以给它加个 0.5 秒的淡入效果！
	# (前提是你的 UI 节点是 Control 或者底下有一个主 Control 节点)
	# 假设你所有的按钮都在一个叫 MainUI 的 Control 子节点下：
	var main_ui = get_node_or_null("MainUI") # 替换成你实际包裹所有 UI 的子节点名
	if main_ui:
		main_ui.modulate = Color(1, 1, 1, 0) # 先变透明
		var tween = create_tween()
		tween.tween_property(main_ui, "modulate", Color(1, 1, 1, 1), 0.5).set_ease(Tween.EASE_OUT)
