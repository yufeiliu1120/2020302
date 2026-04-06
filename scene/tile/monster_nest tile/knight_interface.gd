extends Node

func banish():
	
	_release_neighbors()
	
	if GameResourceManager.turn_started.is_connected(_on_turn_started):
		GameResourceManager.turn_started.disconnect(_on_turn_started)
		
	var my_pos = GridAutoload.active_tiles.find_key($"..")
	if my_pos != null:
		GridAutoload.replace_tile_scene(my_pos, forest_scene)
		
func _release_neighbors():
	var my_pos = GridAutoload.active_tiles.find_key($"..")
	if my_pos == null: return
	
	var neighbors_pos = GridAutoload.get_neighbors(my_pos)
	
	for n_pos in neighbors_pos:
		if GridAutoload.active_tiles.has(n_pos):
			var n_tile = GridAutoload.active_tiles[n_pos]
			
			if is_instance_valid(n_tile):
				# 1. 同样检查白名单
				var is_immune = false
				if n_tile.get("data"):
					var tile_name = n_tile.data.get("tile_name")
					if tile_name in immune_tiles:
						is_immune = true
				
				# 2. 只有被我们压制过的地块，才需要恢复颜色和状态
				if not is_immune:
					n_tile.modulate = Color(1.0, 1.0, 1.0, 1.0) 
					if "is_suppressed" in n_tile:
						n_tile.is_suppressed = false
