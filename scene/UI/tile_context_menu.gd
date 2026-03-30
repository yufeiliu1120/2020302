extends PanelContainer

var current_tile: Node2D = null

@onready var btn_upgrade = $VBoxContainer/HBoxContainer/BtnUpgrade
@onready var btn_demolish = $VBoxContainer/HBoxContainer/BtnDemolish
# 【新增】获取我们刚刚创建的信息展示板
@onready var info_label = $VBoxContainer/InfoLabel

func _ready():
	hide()
	SignalBusAutoload.show_tile_menu.connect(_on_show_menu)
	SignalBusAutoload.hide_tile_menu.connect(hide)
	
	btn_upgrade.pressed.connect(_on_upgrade_pressed)
	btn_demolish.pressed.connect(_on_demolish_pressed)

func _on_show_menu(tile: Node2D, screen_pos: Vector2):
	current_tile = tile
	global_position = screen_pos
	
	if current_tile.data:
		# 1. 控制改造按钮状态
		var can_upgrade = current_tile.data.can_be_upgraded and current_tile.data.get("upgrade_scene") != null
		if can_upgrade and not GameResourceManager.can_afford(current_tile.data.upgrade_cost):
			can_upgrade = false
		btn_upgrade.disabled = not can_upgrade
		
		# 2. 控制拆除按钮状态
		var can_demolish = current_tile.data.get("can_be_demolished")
		if can_demolish == null:
			can_demolish = true 
			
		# 【事件钩子】：检查当前回合是否还有拆除行动点！
		if GameResourceManager.current_demolish_points <= 0:
			can_demolish = false
			
		btn_demolish.disabled = not can_demolish
		
		# ==========================================
		# 【核心新增】：拼装并刷新详情面板的文字！
		# ==========================================
		_update_info_panel()
	
	show()

# 专门负责组装信息的函数
func _update_info_panel():
	if not info_label or not current_tile or not current_tile.data:
		return
		
	var d = current_tile.data
	# 标题：本地化地块名，加粗居中
	var text = "[center][b]" + tr(d.tile_name) + "[/b][/center]\n"
	
	# 状态：是否正常工作
	# 状态：综合判断物理连通性与经济原料
	if current_tile.has_method("is_working"):
		if not current_tile.is_working():
			text += "[color=red] " + tr("status_stopped") + "[/color]\n"
		else:
			# 物理上能工作（连了路），再查查经济上揭不揭得开锅
			var lacking_res = false
			if d.get("resource_maintenance") and not GameResourceManager.can_afford(d.resource_maintenance):
				lacking_res = true
				
			if lacking_res:
				# 变红并警告玩家原料不够
				text += "[color=red]" + tr("status_lacking_res") + "[/color]\n"
			else:
				text += "[color=green] " + tr("status_working") + "[/color]\n"
			
	# 产出与消耗（完美兼容动态相邻加成）
	var prod = d.production
	if current_tile.has_method("get_current_production"):
		prod = current_tile.get_current_production()
		
	for res in prod.keys():
		if prod[res] > 0:
			text += "+" + str(prod[res]) + " " + tr(res) + "/" + tr("turn") + "\n"
			
	if d.food_production > 0:
		text += "+" + str(d.food_production) + " " + tr("food") + "/" + tr("turn") + "\n"
		
	if d.food_maintenance > 0:
		text += "-" + str(d.food_maintenance) + " " + tr("food") + "/" + tr("turn") + "\n"
	# 工业原料消耗
	if d.get("resource_maintenance"):
		for res in d.resource_maintenance.keys():
			if d.resource_maintenance[res] > 0:
				text += "[color=orange] -" + str(d.resource_maintenance[res]) + " " + tr(res) + "/回合[/color]\n"
					
	# 改造花费提示 (如果这个建筑可以升级的话，把它需要花多少钱列出来)
	if d.can_be_upgraded and d.get("upgrade_scene") != null:
		text += "\n[color=orange]" + tr("menu_upgrade_cost") + ": "
		for res in d.upgrade_cost.keys():
			if d.upgrade_cost[res] > 0:
				text += str(d.upgrade_cost[res]) + " " + tr(res) + " "
		text += "[/color]"
		
	info_label.text = text
	
	# 【本地化】：顺手把两个按钮的文字也翻译了
	btn_upgrade.text = tr("btn_upgrade")
	btn_demolish.text = tr("btn_demolish")


func _on_upgrade_pressed():
	if current_tile and current_tile.data:
		var cost = current_tile.data.upgrade_cost
		var upgrade_scene = current_tile.data.get("upgrade_scene")
		
		if upgrade_scene and GameResourceManager.can_afford(cost):
			GameResourceManager.consume_resources(cost)
			
			var grid_pos = current_tile.grid_coordinate
			var pixel_pos = current_tile.global_position
			
			var new_tile = upgrade_scene.instantiate()
			new_tile.grid_coordinate = grid_pos
			new_tile.global_position = pixel_pos
			
			var storage = get_tree().get_first_node_in_group("TileStorage")
			if storage:
				storage.add_child(new_tile)
			else:
				current_tile.get_parent().add_child(new_tile)
				
			GridAutoload.unregister_tile(grid_pos) 
			GridAutoload.register_tile(grid_pos, new_tile)
			new_tile.update_connections()
			
			current_tile.queue_free()
			current_tile = null
			
			ConnectivityManager.update_connectivity()
			
			if has_method("_play_upgrade_effect"):
				_play_upgrade_effect(new_tile)
	hide()

func _on_demolish_pressed():
	if current_tile:
		if current_tile.data and current_tile.data.demolish_refund:
			var refund = current_tile.data.demolish_refund
			GameResourceManager.add_resources(refund) # 直接用万能函数退还拆除费
		
		GridAutoload.unregister_tile(current_tile.grid_coordinate)
		current_tile.queue_free()
		current_tile = null
		ConnectivityManager.update_connectivity()
		
	hide()

func _play_upgrade_effect(tile: Node2D):
	var sprite = tile.get_node_or_null("Sprite2D")
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.2, 0.8), 0.1).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(sprite, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BOUNCE)
	var dust = tile.get_node_or_null("DustParticles")
	if dust:
		dust.restart()
		dust.emitting = true
