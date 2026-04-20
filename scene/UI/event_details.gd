extends Control

@export var button_scene: PackedScene 

@onready var full_image = $content/image
@onready var desc_label = $"content/Interactive menu/VBoxContainer/ScrollContainer/description"
@onready var mec_desc_label = $content/mechanism/ScrollContainer/description
@onready var buttons_container = $content/buttons
@onready var animator = get_node_or_null("PanelAnimator")

var current_event_data: EventResourceData
# 【新增】：在顶部保存当前实例化的脚本对象
var current_effect_instance: RefCounted = null 

func _ready():
	hide()

func show_event_details(event_data: EventResourceData):
	current_event_data = event_data
	AudioManager.play_sfx(event_data.event_name)
	if event_data.full_image:
		full_image.texture = event_data.full_image
	desc_label.text = tr(event_data.event_description)
	mec_desc_label.text = tr(event_data.event_mechanism_description)
	for child in buttons_container.get_children():
		child.queue_free()
		
	# ==========================================
	# 【核心修改】：面板一打开，立刻实例化脚本！
	# ==========================================
	if event_data.effect_script:
		current_effect_instance = event_data.effect_script.new() 
		
		# 1. 如果这个事件脚本支持“多选项” (有 get_choices 函数)
		if current_effect_instance.has_method("get_choices"):
			var choices = current_effect_instance.get_choices()
			for choice in choices:
				var btn = button_scene.instantiate()
				buttons_container.add_child(btn)
				btn.label.text = tr(choice["label"]) # 从字典读取文字
				
				# 逻辑：如果玩家不够钱，让这个按钮变灰且无法点击
				if choice.get("disabled", false):
					btn.modulate = Color(0.4, 0.4, 0.4) # 变灰
					btn.mouse_filter = Control.MOUSE_FILTER_IGNORE # 取消鼠标响应
				else:
					# 使用 Godot 4 的 lambda 表达式，把选项的 action 传给点击事件！
					btn.option_selected.connect(func(): _on_choice_clicked(choice["action"]))
		
		# 2. 如果不支持 (比如旧的海上风暴)，回退到单按钮逻辑
		else:
			var btn = button_scene.instantiate()
			buttons_container.add_child(btn)
			btn.label.text = tr("btn_accept")
			btn.option_selected.connect(func(): _on_choice_clicked("default"))
	
	if animator and animator.has_method("open_panel"):
		animator.open_panel()
	else:
		push_error("动画节点函数名称错误")

# 【核心修改】：合并了原本的 _on_accept_clicked，现在接收参数
func _on_choice_clicked(action: String):
	if animator and animator.has_method("close_panel"):
		animator.close_panel()
	else:
		push_error("动画节点函数名称错误")
		
	# 根据传入的动作，指挥刚刚提前实例化好的脚本去干活！
	if current_effect_instance:
		if action == "default":
			# 兼容旧逻辑
			if current_effect_instance.has_method("execution_event"):
				current_effect_instance.execution_event()
		else:
			# 执行多选项的新逻辑
			if current_effect_instance.has_method("execute_choice"):
				current_effect_instance.execute_choice(action)
