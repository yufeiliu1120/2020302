extends Node
class_name MarketLogic

# 请在右侧属性面板确保这些名字和你海岸地块的 tile_name 一致！
@export var valid_coast_names: Array[String] = ["TILE_NAME_COAST"]

var parent_tile: Node2D
var current_bonus: int = 0
var was_working: bool = false

func _ready():
	parent_tile = get_parent()
	
	# 监听回合开始。
	# 因为在大脑的 end_turn() 里，系统会把玩家的总交易点强行重置为 1（或上限）。
	# 所以回合一开始，市场必须把自己的“额外份额”再发给玩家一次！
	if GameResourceManager.has_signal("turn_started"):
		GameResourceManager.turn_started.connect(_on_turn_started)

# 实时监控：只要游戏运行，它就在观察父地块
func _process(_delta):
	if not is_instance_valid(parent_tile):
		return
		
	# 获取地块当前是否正常工作（必须已经放置、且连着道路）
	var currently_working = false
	if parent_tile.has_method("is_working"):
		currently_working = parent_tile.is_working()
		
	# 状态发生切换的瞬间！（刚放下、或者路断了）
	if currently_working != was_working:
		was_working = currently_working
		if currently_working:
			_calculate_and_apply_bonus()
		else:
			_remove_bonus()

func _on_turn_started(_turn_count: int):
	# 回合刷新时，点数已经被系统砍回去了，我们重新评估海岸并加上去
	if was_working:
		_calculate_and_apply_bonus()

func _calculate_and_apply_bonus():
	if not is_instance_valid(parent_tile) or not ("grid_coordinate" in parent_tile):
		return
		
	var my_coord = parent_tile.grid_coordinate
	var neighbors = GridAutoload.get_neighbors(my_coord)
	
	var new_bonus = 0
	for n_coord in neighbors:
		if GridAutoload.active_tiles.has(n_coord):
			var neighbor_tile = GridAutoload.active_tiles[n_coord]
			# 确保邻居合法，且名字在海岸列表里
			if is_instance_valid(neighbor_tile) and neighbor_tile.get("data") and neighbor_tile.data.tile_name in valid_coast_names:
				new_bonus += 1
	
	# 如果有加成，立刻发给玩家
	if new_bonus > 0:
		current_bonus = new_bonus
		GameResourceManager.add_resources({"trade_point": current_bonus})
		print("🚢 市场开张！增加交易点: ", current_bonus, "，当前总交易点: ", GameResourceManager.stocks["trade_point"])

func _remove_bonus():
	# 防重复扣除保护
	if current_bonus > 0:
		var current_tp = GameResourceManager.stocks.get("trade_point", 0)
		
		# ==========================================
		# 【核心逻辑】：剥夺交易点数
		# 如果玩家当前点数小于等于市场提供的，直接榨干归零；否则正常扣除
		# ==========================================
		if current_tp <= current_bonus:
			GameResourceManager.stocks["trade_point"] = 0
		else:
			GameResourceManager.stocks["trade_point"] -= current_bonus
			
		# 手动通知 UI 数字改变了
		GameResourceManager.resources_changed.emit(GameResourceManager.stocks)
		print("⚠️ 市场停工/被拆！扣除交易点: ", current_bonus, "，当前总交易点: ", GameResourceManager.stocks["trade_point"])
		
		# 清零记录，等待下次开工
		current_bonus = 0

# 【极其重要】：当地块被右键拆除销毁时，一定会触发这个生命周期函数
func _exit_tree():
	if was_working:
		_remove_bonus()
