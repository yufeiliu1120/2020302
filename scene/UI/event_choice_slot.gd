extends HBoxContainer

# 当玩家点击这个选项时，发出信号并带上数据
signal event_selected(event_data: EventResourceData)

@export var event_data: EventResourceData

@onready var preview = $preview
@onready var title = $side_menu/Title

func _ready():
	# 1. 动态绑定鼠标悬浮和点击信号
	preview.mouse_entered.connect(_on_preview_hovered)
	preview.mouse_exited.connect(_on_preview_unhovered)
	preview.gui_input.connect(_on_preview_gui_input)
	
	# 2. 如果你在检查器里塞了数据，直接初始化画面
	if event_data:
		setup(event_data)

# 供外部 (发牌员) 调用的初始化函数
func setup(data: EventResourceData):
	event_data = data
	if data.preview_image:
		preview.texture = data.preview_image
	title.text = tr(data.event_name)

# ==========================================
# 交互动画与逻辑
# ==========================================

# 鼠标移入：图片变亮
func _on_preview_hovered():
	# 使用 Tween 做一个极速顺滑的变亮过渡。
	# Color(1.2, 1.2, 1.2) 会让图片的 RGB 值超出 1，产生一种极佳的高光/发光感。
	var tween = create_tween()
	tween.tween_property(preview, "modulate", Color(1.2, 1.2, 1.2, 1), 0.1)

# 鼠标移出：图片恢复原状
func _on_preview_unhovered():
	var tween = create_tween()
	tween.tween_property(preview, "modulate", Color(1, 1, 1, 1), 0.1)

# 监听输入事件 (替代 Button 的 pressed)
func _on_preview_gui_input(event: InputEvent):
	# 如果是鼠标左键，并且是按下状态 (pressed)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		
		# (附赠果汁) 点击瞬间让图片微缩一下，带来真实的物理按压感
		var tween = create_tween()
		tween.tween_property(preview, "modulate", Color(0.6,0.6,0.6,1), 0.05)
		tween.tween_property(preview, "modulate", Color(1, 1, 1, 1), 0.1)
		
		# 向上级菜单发射数据！
		event_selected.emit(event_data)
