extends TextureRect
signal pressed
var disabled:bool = true
func _ready():
	# 1. 动态绑定鼠标悬浮和点击信号
	mouse_entered.connect(_on_preview_hovered)
	mouse_exited.connect(_on_preview_unhovered)
	gui_input.connect(_on_preview_gui_input)

func _on_preview_hovered():
	if disabled:
		return
	# 使用 Tween 做一个极速顺滑的变亮过渡。
	# Color(1.2, 1.2, 1.2) 会让图片的 RGB 值超出 1，产生一种极佳的高光/发光感。
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.2, 1.2, 1.2, 1), 0.1)
	AudioManager.play_sfx("button_hover")
# 鼠标移出：图片恢复原状
func _on_preview_unhovered():
	if disabled:
		return
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.1)

# 监听输入事件 (替代 Button 的 pressed)
func _on_preview_gui_input(event: InputEvent):
	if disabled:
		return
	# 如果是鼠标左键，并且是按下状态 (pressed)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		
		# (附赠果汁) 点击瞬间让图片微缩一下，带来真实的物理按压感
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(0.6,0.6,0.6,1), 0.05)
		tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.1)
		AudioManager.play_sfx("button_pressed")
		# 向上级菜单发射数据！
		emit_signal("pressed")
