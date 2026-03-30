extends Control

@export var button_scene: PackedScene # 在右侧把刚才做好的按钮场景拖进来！

# 获取你的 UI 节点 (请根据你的实际路径调整)
@onready var full_image = $content/image
@onready var desc_label = $"content/Interactive menu/VBoxContainer/ScrollContainer/description"
@onready var buttons_container = $"content/Interactive menu/VBoxContainer/buttons" # 你说的用来装按钮的节点

@onready var animator = get_node_or_null("PanelAnimator")

var current_event_data: EventResourceData

func _ready():
	hide()

# 这个函数将被图一的“选择菜单”调用
func show_event_details(event_data: EventResourceData):
	current_event_data = event_data
	
	# 1. 刷新画面和文字
	if event_data.full_image:
		full_image.texture = event_data.full_image
	desc_label.text = tr(event_data.event_description)
	
	# 2. 清空旧按钮
	for child in buttons_container.get_children():
		child.queue_free()
		
	# 3. 动态生成新按钮 (目前只有一个“确认/承受”按钮)
	var btn = button_scene.instantiate()
	buttons_container.add_child(btn)
	# 按钮文字可以写死一个通用翻译词条，比如 "btn_accept" (接受命运)
	btn.label.text = tr("btn_accept")
	
	# 监听玩家点击了这个按钮
	btn.option_selected.connect(_on_accept_clicked)
	
	# 4. 华丽登场
	if animator and animator.has_method("open_panel"):
		animator.open_panel()
	else:
		push_error("动画节点函数名称错误")

# 当玩家点击详情面板的选项按钮时
func _on_accept_clicked():
	# 1. 隐藏面板
	if animator and animator.has_method("close_panel"):
		animator.close_panel()
	else:
		push_error("动画节点函数名称错误")
		
	# 2. 真正执行惩罚脚本！
	if current_event_data and current_event_data.effect_script:
		var effect_instance = current_event_data.effect_script.new() 
		if effect_instance.has_method("execution_event"):
			effect_instance.execution_event()
