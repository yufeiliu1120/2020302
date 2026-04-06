extends Node

func banish():
	# 1. 只加载图纸 (PackedScene)，千万不要在这里 instantiate()！
	var road_scene = load("res://scene/tile/road tile/Road.tscn")
	
	# 2. 找到父节点（地块本身）在网格中的坐标
	var my_pos = GridAutoload.active_tiles.find_key($"..")
	
	if my_pos != null:
		# 3. 把图纸交给底层函数，它会帮你造好并替换
		GridAutoload.replace_tile_scene(my_pos, road_scene)
