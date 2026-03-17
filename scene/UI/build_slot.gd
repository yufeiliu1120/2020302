extends HBoxContainer # 注意这里继承变成了 HBoxContainer
class_name BuildSlot

signal try_buy_tile(scene: PackedScene, cost: Dictionary)

@export var tile_scene: PackedScene
var tile_data: TileResourceData

# 获取 UI 节点
@onready var icon_rect = $Icon
@onready var name_label = $InfoBox/Namelabel
@onready var desc_label = $InfoBox/Desclabel
@onready var cost_label = $Costslabel
@onready var buy_button = $BuyButton

func _ready():
	if tile_scene:
		var temp_tile = tile_scene.instantiate()
		tile_data = temp_tile.data
		
		_setup_ui()
		temp_tile.queue_free()
		
	# 把购买按钮的点击信号连上
	buy_button.pressed.connect(_on_buy_pressed)

func _setup_ui():
	if not tile_data: return
	
	# 1. 设置图标
	if tile_data.icon:
		icon_rect.texture = tile_data.icon
		
	# 2. 设置名字和介绍 (结合本地化)
	name_label.text = tr(tile_data.tile_name)
	
	var raw_desc = tile_data.description
	if raw_desc == "": raw_desc = "UNKNOWN_DESC"
	
	# 【修改】：直接把生肉和数据丢进全局绞肉机！
	desc_label.text = TextManager.format_tile_desc(raw_desc, tile_data)
	
	# 3. 设置价格文本 (使用 BBCode 排版)
	var cost_text = "[center]"
	var cost = tile_data.base_cost # 记得我们昨天确定的用 base_cost
	for res in cost:
		if cost[res] > 0:
			# 比如显示: wood: 5
			cost_text += tr(res) + ": " + str(cost[res]) + "   "
	cost_text += "[/center]"
	cost_label.text = cost_text

func _on_buy_pressed():
	if tile_data:
		try_buy_tile.emit(tile_scene, tile_data.base_cost)
