extends Node
class_name NatureGenerator

# 把你的自然地块（草地、森林、海岸、山脉）预制体拖到这个数组里
@export var natural_tile_pool: Array[PackedScene] = []

# 引用你存放所有地块的父节点（TileStorage）
@export var tile_storage: Node2D

func _ready():
	# 假设你在 GameResourceManager 里有一个类似 turn_processed 的信号
	# （你需要根据你实际的回合结束代码来连接这个信号）
	# GameResourceManager.turn_processed.connect(_on_turn_started)
	pass

# 这个函数专门负责在边缘长出一块新土地
func grow_nature():
	# 确保已经配置了卡池和容器
	if natural_tile_pool.is_empty() or tile_storage == null:
		push_error("NatureGenerator 没有配置自然地块卡池或地块容器 (tile_storage)！")
		return
		
	# 1. 直接从“大脑”获取所有已占用的坐标字典
	var occupied_coords = GridAutoload.active_tiles
	
	if occupied_coords.is_empty():
		return # 如果地图完全是空的，就跳过生长
		
# 2. 找到所有合法的“空边缘”坐标（严格遵循领地网限制）
	var valid_empty_edges = {} 
	
	for coord in occupied_coords.keys():
		var source_tile = occupied_coords[coord]
		
		# 检查这个“源地块”是否有效且包含数据
		if not is_instance_valid(source_tile) or source_tile.get("data") == null:
			continue
			
		var tile_name = source_tile.data.tile_name
		
		# ==========================================
		# 【新增核心限制】：海岸地块是天然结界！
		# 如果它是海岸，直接放弃从它周围寻找空地。
		# (⚠️ 注意：请把 "TILE_NAME_COAST" 换成你在 TileResourceData 里给海岸起的真实名字)
		# ==========================================
		if tile_name == "海岸" or tile_name == "TILE_NAME_COAST" or tile_name == "Coast":
			continue 
			
		var is_hq = (tile_name == "HQ")
		var is_territory = source_tile.get("is_territory") == true
		
		# 只有当它是大本营，或者它已经被点亮为“领地”时，才允许在它周围长东西！
		if is_hq or is_territory:
			var neighbors = GridAutoload.get_neighbors(coord)
			for n_coord in neighbors:
				# 如果这个邻居位置不在 active_tiles 里，说明它是空的
				if not occupied_coords.has(n_coord):
					valid_empty_edges[n_coord] = true
	# 提取所有合法的候选坐标
	var edge_array = valid_empty_edges.keys()
	if edge_array.is_empty():
		return # 没有合法的空余位置可以生长
		
	# 3. 命运摇骰：随机选一个目标网格位置
	var target_coord = edge_array.pick_random()
	
	# 4. 随机抽一个自然地块场景并实例化
	var random_scene = natural_tile_pool.pick_random()
	var new_tile = random_scene.instantiate()
	
	# 5. 坐标转换与加入场景树
	if GridAutoload.has_method("grid_to_pixel"):
		new_tile.global_position = GridAutoload.grid_to_pixel(target_coord)
	elif GridAutoload.has_method("hex_to_pixel"):
		new_tile.global_position = GridAutoload.hex_to_pixel(target_coord)
		
	# 【核心新增】：确保大自然生出来的地块知道自己的网格坐标！
	if "grid_coordinate" in new_tile:
		new_tile.grid_coordinate = target_coord
		
	tile_storage.add_child(new_tile)
	
	# 6. 【核心！绝对不能漏】：将新诞生的地块注册回你的大脑中！
	GridAutoload.register_tile(target_coord, new_tile)
	
	# 7. 唤醒新地块，直接进入放置后的 Idle 状态
	if "Statemachine" in new_tile:
		new_tile.Statemachine.change_state("Idle")
		# 如果需要结算加成，可以在这里调用类似 new_tile.apply_placement() 
		
	# 8. 【极其重要】：大自然长出新地块后，地图格局发生变化，强制刷新整个连通性网络！
	# 这样新长出来的地块如果挨着领地，也会立刻被点亮！
	if ConnectivityManager.has_method("update_connectivity"):
		ConnectivityManager.update_connectivity()
		
	# 9. 播放果冻弹跳的出生动画
	_play_grow_animation(new_tile)


# 附加的果冻弹跳动画（如果没有这个函数，请一并复制上）
func _play_grow_animation(tile: Node2D):
	tile.scale = Vector2(0, 0)
	var tween = create_tween()
	# 用 0.5 秒时间，以非常有弹性的感觉放大到正常大小
	tween.tween_property(tile, "scale", Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
