
extends Node

var forest_scene = preload("res://scene/tile/forest tile/area_2d.tscn") 

# ==========================================
# 🛡️ 【新增】：免疫怪物的地块白名单 (请填入你真实的 tile_name)
# ==========================================
var immune_tiles: Array[String] = [
	"HQ",  "TILE_NAME_COAST"     # 大本营
]

func _ready():
	_suppress_neighbors()
	if not GameResourceManager.turn_started.is_connected(_on_turn_started):
		GameResourceManager.turn_started.connect(_on_turn_started)

func _on_turn_started(_current_turn: int):
	_suppress_neighbors()

# ==========================================
# 🛑 核心逻辑：压制周围六边形 (带白名单过滤)
# ==========================================
func _suppress_neighbors():
	var my_pos = GridAutoload.active_tiles.find_key($"..")
	if my_pos == null: return
	
	var neighbors_pos = GridAutoload.get_neighbors(my_pos)
	
	for n_pos in neighbors_pos:
		if GridAutoload.active_tiles.has(n_pos):
			var n_tile = GridAutoload.active_tiles[n_pos]
			
			if is_instance_valid(n_tile):
				# 1. 检查该地块是否在白名单中
				var is_immune = false
				if n_tile.get("data"):
					var tile_name = n_tile.data.get("tile_name")
					if tile_name in immune_tiles:
						is_immune = true
				
				# 2. 如果不是免疫地块，才进行压制
				if not is_immune:
					n_tile.modulate = Color(0.4, 0.4, 0.4, 1.0)
					if "is_suppressed" in n_tile:
						n_tile.is_suppressed = true

# ==========================================
# ⚔️ 预留接口：骑士驱逐怪物
# ==========================================
func banish_monster():
	print("【骑士出击】怪物被驱逐，巢穴恢复为森林！")
	
	_release_neighbors()
	
	if GameResourceManager.turn_started.is_connected(_on_turn_started):
		GameResourceManager.turn_started.disconnect(_on_turn_started)
		
	var my_pos = GridAutoload.active_tiles.find_key($"..")
	if my_pos != null:
		GridAutoload.replace_tile_scene(my_pos, forest_scene)

# ==========================================
# 🕊️ 辅助功能：解除压制 (带白名单过滤)
# ==========================================
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
