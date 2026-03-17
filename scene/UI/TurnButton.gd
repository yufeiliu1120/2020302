extends TextureButton

func _ready():
	# 防止点击按钮时误触地块
	mouse_filter = Control.MOUSE_FILTER_STOP
	pressed.connect(_on_pressed)

func _on_pressed():
	# 调用资源管理器执行结算
	GameResourceManager.process_turn()
