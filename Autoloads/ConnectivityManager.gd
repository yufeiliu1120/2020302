extends Node
class_name Connectivitymanager

# 哪些地块可以传导连通性
const CONDUCTIVE_TILES = ["HQ", "TILE_NAME_ROAD"]

func is_conductive(tile: Node2D) -> bool:
	if not is_instance_valid(tile) or not tile.data: return false
	return tile.data.tile_name in CONDUCTIVE_TILES

func update_connectivity():
	var active_tiles = GridAutoload.active_tiles
	
	# 0. 安全审查机制：清理幽灵节点（必须保留）
	var dead_keys = []
	for pos in active_tiles.keys():
		var tile = active_tiles[pos]
		if not is_instance_valid(tile) or tile.is_queued_for_deletion():
			dead_keys.append(pos)
	for pos in dead_keys:
		active_tiles.erase(pos)

	# 1. 重置所有地块的双网状态
	for tile in active_tiles.values():
		tile.is_connected = false      # 物流网断开
		tile.distance_to_source = 999 
		tile.is_territory = false      # 【新增】领地网断开
		
	# ==================================================
	# 网络 A：领地网 (Territory Network)
	# 负责：允许玩家像涂色一样，挨着已有的领地向外无脑扩张。
	# 【修改】：现在它会感染所有物理相连的地块（包括大自然）！
	# ==================================================
	var territory_queue = []
	var territory_visited = {} # 记录访问过的坐标，防止死循环
	
	# 1. 寻找所有的源头（大本营）
	for pos in active_tiles.keys():
		var tile = active_tiles[pos]
		if tile.data and tile.data.tile_name == "HQ":
			tile.is_territory = true
			territory_queue.append(pos)
			territory_visited[pos] = true
			
	# 2. 像水流一样向外蔓延
	while territory_queue.size() > 0:
		var curr_pos = territory_queue.pop_front()
		
		# 获取周围 6 个邻居
		var neighbors = GridAutoload.get_neighbors(curr_pos)
		for n_pos in neighbors:
			# 如果这个位置有地块，且还没被领地网扫描过
			if active_tiles.has(n_pos) and not territory_visited.has(n_pos):
				var n_tile = active_tiles[n_pos]
				
				# 无论是草地、森林还是道路，只要连着，统统变成领地！
				n_tile.is_territory = true 
				
				territory_visited[n_pos] = true
				territory_queue.append(n_pos) # 把邻居也加入队列，继续向外传导
	# ==================================================
	# 网络 B：物流网 (Logistics Network)
	# 负责：运输资源，算运费，维持高级建筑运作。
	# ==================================================
	var logistics_queue = []
	var visited = {}
	for tile in active_tiles.values():
		if tile.data and tile.data.tile_name == "HQ":
			logistics_queue.append(tile)
			tile.is_connected = true
			tile.distance_to_source = 0
			visited[tile.grid_coordinate] = 0
			
	while logistics_queue.size() > 0:
		var current = logistics_queue.pop_front()
		var current_dist = visited[current.grid_coordinate]
		for n_pos in GridAutoload.get_neighbors(current.grid_coordinate):
			if active_tiles.has(n_pos):
				var n_tile = active_tiles[n_pos]
				if not is_instance_valid(n_tile) or n_tile.is_queued_for_deletion(): continue
				
				if not visited.has(n_pos):
					# 只要挨着路，就被点亮并算入运费距离
					n_tile.is_connected = true
					n_tile.distance_to_source = current_dist + 1
					visited[n_pos] = current_dist + 1
					
					# 【核心】：只有正宗的“导电体（道路）”才能继续往下传！
					if is_conductive(n_tile):
						logistics_queue.append(n_tile)

	SignalBusAutoload.map_state_changed.emit()


# 【修改】：现在放置草地时，检查的是“领地网 is_territory”
func has_hq_network_neighbor(grid_pos: Vector2i) -> bool:
	var neighbors = GridAutoload.get_neighbors(grid_pos)
	for n in neighbors:
		if GridAutoload.active_tiles.has(n):
			var neighbor_tile = GridAutoload.active_tiles[n]
			# 只要旁边是属于领地的地块，就可以放置
			if neighbor_tile.data.tile_name == "HQ" or neighbor_tile.get("is_territory") == true:
				return true
	return false

# 以下两个函数保持原样，它们严格检查物流网（is_connected）
func get_min_distance_at(grid_pos: Vector2i, is_hq: bool) -> int:
	if is_hq: return 0 
	var min_dist = 999
	for n_pos in GridAutoload.get_neighbors(grid_pos):
		if GridAutoload.active_tiles.has(n_pos):
			var n_tile = GridAutoload.active_tiles[n_pos]
			if n_tile.is_connected and is_conductive(n_tile):
				if n_tile.distance_to_source < min_dist:
					min_dist = n_tile.distance_to_source
	return min_dist

func check_placement_connectivity(grid_pos: Vector2i, is_hq: bool) -> bool:
	if is_hq: return true 
	if GridAutoload.active_tiles.is_empty(): return true 
	for n_pos in GridAutoload.get_neighbors(grid_pos):
		if GridAutoload.active_tiles.has(n_pos):
			var n_tile = GridAutoload.active_tiles[n_pos]
			if n_tile.is_connected and is_conductive(n_tile):
				return true
	return false
