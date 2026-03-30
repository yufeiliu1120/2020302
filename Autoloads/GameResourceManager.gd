extends Node

# ==========================================
# 信号定义
# ==========================================
signal resources_changed(new_stocks)
signal turn_started(turn_count)
signal purchase_failed(cost: Dictionary)

# ==========================================
# 核心状态与库存
# ==========================================
var current_turn: int = 1
var max_trade_points: int = 1 

var stocks = {
	"food": 5,
	"wood": 10,
	"stone": 4, 
	"explorer": 0,
	"metal": 0,
	"trade_point": 1
}

# ==========================================
# 🚨 灾难事件全局拦截器 (Event Hooks)
# ==========================================
var is_trade_disabled: bool = false      # 用于“海上风暴”：封锁市场
var is_production_frozen: bool = false   # 用于“粮食欠收”：全局停产（但可能还要吃维护费）

var max_demolish_points: int = 1         # 用于“枯萎病”：每回合最大拆除次数
var current_demolish_points: int = 1     # 当前剩余拆除次数



# ==========================================
# 回合结算核心系统 (合并了旧的 end_turn 和 process_turn)
# ==========================================
func end_turn():
	# 每回合开始时，重置拆除行动点数
	current_demolish_points = max_demolish_points
	# 1. 结算前先刷新一次领地和物流网，确保地块的 is_working 状态是最准确的
	if ConnectivityManager.has_method("update_connectivity"):
		ConnectivityManager.update_connectivity()
		
	var turn_production = {
		"wood": 0, "stone": 0, "food": 0, "explorer": 0, "metal": 0 
	}
	var turn_food_maintenance = 0
	
	# 2. 遍历并收集所有正常工作地块的产出
	for tile in GridAutoload.active_tiles.values():
		if tile.has_method("is_working") and tile.is_working():
			var data = tile.data
			if data:
				# ==========================================
				# 【新增】：原料审查机制！防止玩家 0 木头白嫖金属
				var can_operate = true
				if "resource_maintenance" in data:
					for res in data.resource_maintenance:
						var required = data.resource_maintenance[res]
						if required > 0:
							# 如果 "当前库存" + "本回合其他建筑先产出的量" 都不够扣：
							if stocks.get(res, 0) + turn_production.get(res, 0) < required:
								can_operate = false
								break
				
				# 如果原料不够，这台机器本回合直接停工（跳过产出和消耗）
				if not can_operate:
					print(data.tile_name, " 因为缺少原料，本回合停工！")
					continue 
				
				# 如果能开工，先扣除工业原料
				if "resource_maintenance" in data:
					for res in data.resource_maintenance:
						var cost = data.resource_maintenance[res]
						if cost > 0:
							turn_production[res] = turn_production.get(res, 0) - cost
				# ==========================================

				# 【事件钩子】：饥荒全局停产拦截
				# ==========================================
				if is_production_frozen:
					# 依然会累加 food_maintenance (该吃的饭还得吃)，但跳过生产
					turn_food_maintenance += data.food_maintenance
					continue # 直接跳过当前地块的产出逻辑
				var current_prod = {}
				if tile.has_method("get_current_production"):
					current_prod = tile.get_current_production()
				else:
					current_prod = data.production
					
				for res in current_prod.keys():
					if turn_production.has(res):
						turn_production[res] += current_prod[res]
					else:
						turn_production[res] = current_prod[res]
						
				turn_production["food"] += data.food_production
				turn_food_maintenance += data.food_maintenance

	# 3. 结算并应用资源变化
	var net_food = turn_production["food"] - turn_food_maintenance
	stocks["food"] = stocks.get("food", 0) + net_food
	
	# 食物不足时的惩罚（工人挨饿）
	if stocks["food"] < 0:
		print("警告：食物不足以支付维护费，工人饿肚子了！")
		stocks["food"] = 0
		
	# 将其他资源入库
	for res in turn_production.keys():
		if res != "food":
			stocks[res] = stocks.get(res, 0) + turn_production[res]

	# 4. 重置交易点数到上限
	stocks["trade_point"] = max_trade_points
	
	# 5. 回合数增加
	current_turn += 1
	
	# 6. 后台打印财报（极度方便你做数值测试）
	print("\n=== 第 %d 回合结算完毕 ===" % current_turn)
	print("本回合产出: ", turn_production)
	print("本回合消耗食物: ", turn_food_maintenance)
	print("结算后总库存: ", stocks)
	print("=========================\n")
	
	# 7. 【关键修复】正确发送两个信号，UI 刷新和 20 回合弹窗将完美工作
	resources_changed.emit(stocks)
	turn_started.emit(current_turn)
	
	# 8. 最后触发大自然蔓延
	var nature_gen = get_tree().get_first_node_in_group("NatureGeneratorGroup")
	if nature_gen and nature_gen.has_method("grow_nature"):
		nature_gen.grow_nature()


# ==========================================
# 资源消费与获取逻辑
# ==========================================
func can_afford(cost: Dictionary) -> bool:
	for res in cost:
		if stocks.get(res, 0) < cost[res]:
			return false
	return true

func consume_resources(cost: Dictionary):
	for res in cost:
		if stocks.has(res):
			stocks[res] -= cost[res]
	resources_changed.emit(stocks)

func add_resources(rewards: Dictionary):
	for res in rewards:
		if stocks.has(res):
			stocks[res] += rewards[res]
		else:
			stocks[res] = rewards[res]
	resources_changed.emit(stocks)


# ==========================================
# 辅助计算系统 (用于 UI 预测和花费计算)
# ==========================================

## 计算地块落地时的额外差价 (距离惩罚)
func get_placement_penalty(tile_data: Resource, distance: int) -> Dictionary:
	var penalty = {}
	if not tile_data or distance <= 0 or distance >= 999:
		return penalty
		
	for res in tile_data.distance_penalty.keys():
		var cost_per_step = tile_data.distance_penalty[res]
		if cost_per_step > 0:
			penalty[res] = cost_per_step * distance
	return penalty

## 获取下回合的预期产出（模拟结算，用于 UI 显示）
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
				# --- 预测时的原料审查 ---
				var can_operate = true
				if "resource_maintenance" in data:
					for res in data.resource_maintenance:
						var required = data.resource_maintenance[res]
						if required > 0:
							if stocks.get(res, 0) + projection.get(res, 0) < required:
								can_operate = false
								break
				
				if not can_operate:
					continue 
				
				if "resource_maintenance" in data:
					for res in data.resource_maintenance:
						var cost = data.resource_maintenance[res]
						if cost > 0:
							projection[res] = projection.get(res, 0) - cost
				# ------------------------

				var current_prod = {}
				if tile.has_method("get_current_production"):
					current_prod = tile.get_current_production()
				else:
					current_prod = data.production
					
				for res in current_prod.keys():
					if projection.has(res):
						projection[res] += current_prod[res]
					else:
						projection[res] = current_prod[res]
						
				projection["food"] += data.food_production
				turn_food_maintenance += data.food_maintenance
				
	projection["food"] -= turn_food_maintenance
	
	return projection
	
