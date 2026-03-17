extends Node

signal resources_changed(new_stocks)
signal turn_started(turn_count)

# 当试图购买却资源不足时发出，带上原本需要的花费
signal purchase_failed(cost: Dictionary)

var current_turn: int = 1

# 交易点数上限（未来可以被市场、渔场等建筑增加）
var max_trade_points: int = 1 

var stocks = {
	"food": 5,
	"wood": 10,
	"stone": 5,
	"explorer": 5,
	"metal": 5,
	"trade_point": 1 # 【新增】：初始给玩家 1 点交易点数
}

func end_turn():
	# 1. 先更新连通性，这会影响地块是否 is_working
	ConnectivityManager.update_connectivity()
	
	# 2. 结算产出
	var delta = _calculate_resources()
	for res in delta:
		if stocks.has(res):
			stocks[res] += delta[res]
	
	current_turn += 1
	resources_changed.emit(stocks)
	turn_started.emit(current_turn)

func _calculate_resources() -> Dictionary:
	var delta = {"food": 0, "wood": 0, "stone": 0, "explorer": 0}
	for tile in GridAutoload.active_tiles.values():
		if tile.has_method("is_working") and tile.is_working():
			var d = tile.data
			delta["food"] += (d.food_production - d.food_maintenance)
			# 这里可以根据需要添加其他资源的生产逻辑
	return delta

func can_afford(cost: Dictionary) -> bool:
	for res in cost:
		if stocks.get(res, 0) < cost[res]:
			return false
	return true

func consume_resources(cost: Dictionary):
	for res in cost:
		stocks[res] -= cost[res]
	resources_changed.emit(stocks)
	
## 计算地块落地时的额外差价
func get_placement_penalty(tile_data: TileResourceData, distance: int) -> Dictionary:
	var penalty = {}
	
	# 如果数据为空，或者距离无效/在HQ旁边(距离为0)，则没有额外花费
	if not tile_data or distance <= 0 or distance >= 999:
		return penalty
		
	# 遍历地块的 distance_penalty 配置，乘以距离
	for res in tile_data.distance_penalty.keys():
		var cost_per_step = tile_data.distance_penalty[res]
		if cost_per_step > 0:
			penalty[res] = cost_per_step * distance
			
	return penalty
	
# --- 回合制结算系统 ---

## 执行回合结束结算
func process_turn() -> void:
	var turn_production = {
		"wood": 0, "stone": 0, "food": 0, "explorer": 0, "iron": 0
	}
	var turn_food_maintenance = 0
	
	# 1. 遍历所有已放置在地图上的地块
	for tile in GridAutoload.active_tiles.values():
		# 只有满足工作条件（连了路、未停工）的地块才参与结算
		if tile.has_method("is_working") and tile.is_working():
			var data = tile.data as TileResourceData
			if data:
				# ==========================================
				# 【核心修改】：获取包含相邻加成的动态产量
				# ==========================================
				var current_prod = {}
				if tile.has_method("get_current_production"):
					current_prod = tile.get_current_production()
				else:
					current_prod = data.production # 安全回退方案
					
				# 累加常规资源产出（使用动态计算的 current_prod）
				for res in current_prod.keys():
					if turn_production.has(res):
						turn_production[res] += current_prod[res]
					else:
						# 如果以后配置了新的资源种类，这里也能自动兼容
						turn_production[res] = current_prod[res]
				# ==========================================
				
				# 累加食物的特殊产出与维护费
				turn_production["food"] += data.food_production
				turn_food_maintenance += data.food_maintenance
				
	# 2. 结算食物及维护费
	var net_food = turn_production["food"] - turn_food_maintenance
	
	# 使用 get() 确保即使 stocks 里没写全键值也不会报错，默认值为 0
	stocks["food"] = stocks.get("food", 0) + net_food
	
	# 食物不足时的简单处理（防跌破0，后续可以加入“罢工”惩罚）
	if stocks["food"] < 0:
		print("警告：食物不足以支付维护费，工人饿肚子了！")
		stocks["food"] = 0
		
	# 3. 结算其他资源
	for res in ["wood", "stone", "explorer", "iron"]:
		# 使用 get() 防止报错，容错率更高
		stocks[res] = stocks.get(res, 0) + turn_production.get(res, 0)
		
	# 4. 打印本回合“财报” (方便我们在后台控制台调试)
	print("\n=== 第 %d 回合结算完毕 ===" % current_turn)
	print("本回合产出: ", turn_production)
	print("本回合消耗食物: ", turn_food_maintenance)
	print("结算后总库存: ", stocks)
	print("=========================\n")
	
	# 5. 回合数增加
	current_turn += 1
	
	# ==========================================
	# 【核心修改】：每回合重置交易点数到上限！
	stocks["trade_point"] = max_trade_points
	# ==========================================
	
	# 6. 发送信号，通知顶部 UI 刷新显示的数字
	resources_changed.emit(stocks)
	
	# ... 触发自然生长等代码 ...
	
	# 6. 发送信号，通知顶部 UI 刷新显示的数字
	resources_changed.emit(stocks)
	var nature_gen = get_tree().get_first_node_in_group("NatureGeneratorGroup")
	if nature_gen:
		nature_gen.grow_nature()
	
# 获取下回合的预期产出（模拟结算）
func get_projected_income() -> Dictionary:
	var projection = {
		"wood": 0, "stone": 0, "food": 0, "explorer": 0, "metal": 0
	}
	var turn_food_maintenance = 0
	
	# 遍历计算预期
	for tile in GridAutoload.active_tiles.values():
		if tile.has_method("is_working") and tile.is_working():
			var data = tile.data
			if data:
				var current_prod = {}
				if tile.has_method("get_current_production"):
					current_prod = tile.get_current_production()
				else:
					current_prod = data.production
					
				for res in current_prod.keys():
					if projection.has(res):
						projection[res] += current_prod[res]
						
				# 【修改这里】：直接用点(.)访问属性，因为你在资源里已经给它们默认赋值为 0 了
				projection["food"] += data.food_production
				turn_food_maintenance += data.food_maintenance
				
	# 结算预期净食物
	projection["food"] -= turn_food_maintenance
	
	return projection
	
	
# ==========================================
# 万能增加资源函数
# 接收一个字典，比如 {"wood": 2, "stone": 1}
# ==========================================
func add_resources(rewards: Dictionary):
	for res in rewards:
		if stocks.has(res):
			stocks[res] += rewards[res]
		else:
			stocks[res] = rewards[res] # 万一发了一种以前没有的新资源，直接创建键值
			
	# 发送信号让 UI 更新
	resources_changed.emit(stocks)
	
