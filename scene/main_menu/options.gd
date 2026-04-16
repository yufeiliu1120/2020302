extends CanvasLayer

@onready var volume_slider = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Audiosetting/Master/HSlider
@onready var sfx_slider = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Audiosetting/SFX/HSlider
@onready var bgm_slider = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Audiosetting/BGM/HSlider
@onready var language_option = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/OptionButton
@onready var back_button = $PanelContainer/MarginContainer/VBoxContainer/BackButton

func _ready():
	# 1. 极其优雅的批量初始化：为三个滑块分别绑定它们对应的音频总线名字
	_setup_audio_slider(volume_slider, "Master")
	_setup_audio_slider(sfx_slider, "SFX")
	_setup_audio_slider(bgm_slider, "BGM")
	
	# 2. 初始化语言下拉框 (读取当前系统语言)
	var current_lang = TranslationServer.get_locale()
	if current_lang.begins_with("zh"):
		language_option.select(0) # 中文
	else:
		language_option.select(1) # 英文
		
	# 3. 绑定语言和返回信号
	language_option.item_selected.connect(_on_language_selected)
	back_button.pressed.connect(_on_back_pressed)


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


# ==========================================
# 🌐 语言切换逻辑
# ==========================================
func _on_language_selected(index: int):
	match index:
		0:
			TranslationServer.set_locale("zh") 
		1:
			TranslationServer.set_locale("en") 
			
	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("paper_rustle")

# ==========================================
# ⬅️ 返回逻辑
# ==========================================
func _on_back_pressed():
	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("button_pressed")
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(hide)
	
	# 通知主菜单恢复状态
	if owner and owner.has_method("on_settings_closed"):
		owner.on_settings_closed()
		
func open():
	show()
