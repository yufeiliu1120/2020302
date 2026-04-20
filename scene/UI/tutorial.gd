extends Control

# 把你的三个步骤节点放进一个数组里，方便按顺序调用
@onready var steps: Array = [$step1, $step2, $step3, $step4]

var current_step_index: int = -1
var is_tutorial_active: bool = false

func _ready() -> void:
	# 1. 初始状态：隐藏整个教程层，并隐藏所有步骤
	hide()
	for step in steps:
		step.hide()
		
	# 2. 监听游戏开始的信号（请确保 SignalBusAutoload 的名字正确）
	SignalBusAutoload.game_start.connect(_on_game_start)

# ==========================================
# 🚀 启动逻辑
# ==========================================
func _on_game_start() -> void:
	# 延迟 0.5 秒，给玩家一个缓冲，或者等其他开场动画结束
	await get_tree().create_timer(0.5).timeout
	start_tutorial()

# 封装成独立函数，以后暂停菜单里的“重新播放教程”可以直接调用这个函数！
func start_tutorial() -> void:
	is_tutorial_active = true
	current_step_index = 0
	show() # 显示整个教程层
	
	# 确保所有步骤先隐藏
	for step in steps:
		step.hide()
		
	# 显示第一张幻灯片
	if steps.size() > 0:
		steps[0].show()

# ==========================================
# 🖱️ 点击切换逻辑
# ==========================================
func _input(event: InputEvent) -> void:
	# 如果教程没在播放，就不管
	if not is_tutorial_active:
		return
		
	# 监听鼠标左键点击 (按下时触发)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 🌟 神级避坑：阻止这个点击事件继续向下传递！
		# 这样玩家点幻灯片时，就不会误触到底下真正的游戏按钮或地块
		get_viewport().set_input_as_handled()
		_next_step()

func _next_step() -> void:
	# 播放翻页音效（如果有的话）
	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("page") # 或者换成翻书的声音 "paper_rustle"
		
	# 隐藏当前幻灯片
	if current_step_index >= 0 and current_step_index < steps.size():
		steps[current_step_index].hide()
		
	# 索引加 1，进入下一步
	current_step_index += 1
	
	# 检查是否还有下一步
	if current_step_index < steps.size():
		steps[current_step_index].show()
	else:
		_end_tutorial()

# ==========================================
# 🏁 结束逻辑
# ==========================================
func _end_tutorial() -> void:
	is_tutorial_active = false
	hide() # 隐藏整个教程界面
	current_step_index = -1
	print("【教程】幻灯片播放完毕，已隐藏。")
