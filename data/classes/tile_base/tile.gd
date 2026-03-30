extends Area2D
class_name TileBase
# --- 用来确定距离HQ的距离 ---
var distance_to_source: int = 999

#代表这个地块是否属于玩家的扩张领地
var is_territory: bool = false
@onready var Statemachine:StateMachine = $Statemachine
# --- 属性暴露 ---
@export_group("Economics")
@export var data: TileResourceData:
	set(value):
		data = value
		_update_visual_status() # 数据变化时刷新视觉

@export_group("Status")
@export var is_active: bool = true:
	set(value):
		is_active = value
		_update_visual_status()

var is_connected: bool = false:
	set(value):
		is_connected = value
		_update_visual_status()

# --- 内部变量 ---
var grid_coordinate: Vector2i = Vector2i(-999, -999)
var connected_tiles: Array[Node] = []

# --- 核心逻辑 ---
var is_suppressed: bool = false # 被怪物巢穴或枯萎病压制，无法工作
var is_blocked: bool = false    # 被强盗占领（如果是道路，将失去连通功能）

func _ready():
	# 如果被压制或占领，直接视为停工！
	if is_suppressed or is_blocked:
		return false
	if get_parent():
		get_parent().y_sort_enabled = true
	snap_to_nearest_grid()
	
	# 连接输入信号
	input_pickable = true
	input_event.connect(_on_tile_input_event)
	if GameResourceManager.has_signal("resources_changed"):
		GameResourceManager.resources_changed.connect(_on_resources_changed)
		
	# 初始化时先检查一下自己会不会被饿死
	_check_visual_status()
	
func snap_to_nearest_grid():
	# 如果是刚生成的坐标（通常初始默认值是 0,0 或者一个极端的负数）
	# 才去尝试对齐，如果是改造继承过来的，坚决不要重新算！
	if grid_coordinate == Vector2i.ZERO: # (假设你初始化没赋值时是 ZERO)
		grid_coordinate = GridAutoload.pixel_to_grid(global_position)
		global_position = GridAutoload.grid_to_pixel(grid_coordinate)

func update_connections():
	connected_tiles.clear()
	var neighbors = GridAutoload.get_neighbors(grid_coordinate)
	for n_pos in neighbors:
		if GridAutoload.active_tiles.has(n_pos):
			var neighbor_node = GridAutoload.active_tiles[n_pos]
			connected_tiles.append(neighbor_node)
			if not neighbor_node.connected_tiles.has(self):
				neighbor_node.connected_tiles.append(self)

func is_working() -> bool:
	# 如果没有 data，默认不工作或根据需求调整
	if not data: return false
	if not is_active: return false 
	if data.requires_road and not is_connected: return false 
	return true

func _update_visual_status():
	# 确保在节点进入场景树后才执行（防止初始化时报错）
	if not is_inside_tree(): return
	
	if is_working():
		modulate = Color(1, 1, 1) 
	else:
		# 变灰暗并带一点透明度，增强“停工”感
		modulate = Color(0.4, 0.4, 0.4, 0.8) 

# --- 交互逻辑 ---

func _on_tile_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		# 右键点击弹出菜单
		if event.button_index == MOUSE_BUTTON_RIGHT:
			# 这里假设你有一个状态机实例在 Actor 上，或者全局判断
			# 我们暂定在全局单例里判断当前是否处于可操作状态
			_try_open_context_menu()

func _try_open_context_menu():
	# 只有当它已经安稳地放在地上（处于 Idle 状态）时，才允许弹出菜单
	if Statemachine.current_state.state_name == "Idle":
		# 获取当前鼠标在屏幕上的绝对位置，通知 UI 弹出
		var mouse_pos = get_viewport().get_mouse_position()
		SignalBusAutoload.show_tile_menu.emit(self, mouse_pos)
		
		
#计算包含相邻加成后的最终产量
func get_current_production() -> Dictionary:
	if not data or typeof(data.get("production")) != TYPE_DICTIONARY:
		return {}
		
	# 1. 复制一份基础产量
	var total_prod = data.production.duplicate()
	
	# 2. 读取加成设定
	var bonus_tile_name = data.get("adjacency_bonus_tile")
	var bonus_amount = data.get("adjacency_bonus_amount")
	
	# 3. 如果有加成设定，开始环顾四周找邻居！
	if bonus_tile_name != "" and bonus_amount and not bonus_amount.is_empty():
		var neighbors = GridAutoload.get_neighbors(grid_coordinate)
		var bonus_count = 0
		
		# 统计周围有多少个目标地块
		for n_pos in neighbors:
			if GridAutoload.active_tiles.has(n_pos):
				var n_tile = GridAutoload.active_tiles[n_pos]
				if n_tile.data and n_tile.data.tile_name == bonus_tile_name:
					bonus_count += 1
					
		# 结算额外加成
		if bonus_count > 0:
			for res_key in bonus_amount.keys():
				if total_prod.has(res_key):
					total_prod[res_key] += bonus_amount[res_key] * bonus_count
				else:
					total_prod[res_key] = bonus_amount[res_key] * bonus_count
					
	return total_prod
	
func _on_resources_changed(_new_stocks: Dictionary):
	_check_visual_status()

# 动态改变地块的外观颜色
func _check_visual_status():
	if not data: return
	
	# 如果这个建筑根本不需要工业原料，就不管它
	if not data.get("resource_maintenance") or data.resource_maintenance.is_empty():
		return
		
	var sprite = get_node_or_null("Sprite2D") # 请确保这里是你地块贴图的真实节点名
	if not sprite: return
	
	# 判断能否付得起原料费
	if GameResourceManager.can_afford(data.resource_maintenance):
		# 原料充足，恢复原本的颜色
		sprite.modulate = Color(1, 1, 1, 1) 
	else:
		# 原料不足，让贴图变暗发红，表示停机
		sprite.modulate = Color(0.6, 0.4, 0.4, 1)
