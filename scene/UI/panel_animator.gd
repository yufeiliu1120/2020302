extends Node
class_name PanelAnimator # 注册为一个全局类，以后可以直接当节点用

@onready var target: Control = get_parent() # 获取它的父节点（即需要被动画控制的面板）

# --- 封装的打开动画 ---
func open_panel():
	target.show()
	# 动态获取父节点的中心点
	target.pivot_offset = target.size / 2
	
	target.modulate = Color(1, 1, 1, 0)
	target.scale = Vector2(0.8, 0.8)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(target, "modulate", Color(1, 1, 1, 1), 0.2).set_trans(Tween.TRANS_SINE)
	tween.tween_property(target, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# 禁用摄像头控制
	var camera = get_tree().get_first_node_in_group("Camera")
	camera.process_mode = Node.PROCESS_MODE_DISABLED
	
# --- 封装的关闭动画 ---
# Callable 是一个非常强大的类型，代表“一个函数”。
# 这样我们可以告诉动画：“关完之后，顺便帮我执行这个操作。”
func close_panel(on_finished: Callable = Callable()):
	var tween = create_tween().set_parallel(true)
	tween.tween_property(target, "modulate", Color(1, 1, 1, 0), 0.15).set_trans(Tween.TRANS_SINE)
	tween.tween_property(target, "scale", Vector2(0.9, 0.9), 0.15).set_trans(Tween.TRANS_SINE)
	
	tween.chain().tween_callback(func():
		target.hide()
		# 如果传入了有效的后续任务，就执行它
		if on_finished.is_valid():
			on_finished.call()
	)
	# 重新启用摄像头控制
	var camera = get_tree().get_first_node_in_group("Camera")
	camera.process_mode = Node.PROCESS_MODE_INHERIT
