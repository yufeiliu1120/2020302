extends VBoxContainer
@onready var volume_slider = $Master/HSlider
@onready var sfx_slider = $SFX/HSlider
@onready var bgm_slider = $BGM/HSlider

func _ready():
	# 1. 极其优雅的批量初始化：为三个滑块分别绑定它们对应的音频总线名字
	_setup_audio_slider(volume_slider, "Master")
	_setup_audio_slider(sfx_slider, "SFX")
	_setup_audio_slider(bgm_slider, "BGM")
	


# ==========================================
# 🔊 音量调整逻辑 (通用化)
# ==========================================

# 这是一个自定义的辅助函数，用来减少重复代码
func _setup_audio_slider(slider: HSlider, bus_name: String):
	# 获取当前音量并设置滑块初始位置
	var bus_index = AudioServer.get_bus_index(bus_name)
	var current_db = AudioServer.get_bus_volume_db(bus_index)
	slider.value = db_to_linear(current_db) 
	
	# 绑定信号，并把 bus_name 偷偷塞进参数里传给回调函数！
	slider.value_changed.connect(_on_volume_changed.bind(bus_name))
	slider.drag_ended.connect(_on_volume_drag_ended.bind(bus_name))


# 注意：这里的参数多了一个 bus_name，这就是我们用 bind 传过来的
func _on_volume_changed(value: float, bus_name: String):
	var bus_index = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))


func _on_volume_drag_ended(value_changed: bool, bus_name: String):
	if value_changed and AudioManager.has_method("play_sfx"):
		# 玩家松手时给个反馈，"叮"一声
		# 如果是调 BGM，你甚至可以加个判断 `if bus_name != "BGM":` 来决定要不要播音效
		AudioManager.play_sfx("click") 
