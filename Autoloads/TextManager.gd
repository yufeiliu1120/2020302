extends Node

# 这是一个全局方法，专门用来解析地块的介绍文本
func format_tile_desc(text_key: String, data: TileResourceData) -> String:
	# 1. 先翻译（如果传入的是空字符串，直接返回空）
	if text_key == "": return ""
	var translated_text = tr(text_key)
	
	# 如果没有传入数据，就只返回翻译后的纯文本
	if data == null:
		return translated_text
		
	# 2. 组装全局通用的“超级字典”
	var dynamic_vars = {
		# 相邻加成
		"adj_food": data.adjacency_bonus_amount.get("food", 0),
		"adj_wood": data.adjacency_bonus_amount.get("wood", 0),
		"adj_stone": data.adjacency_bonus_amount.get("stone", 0),
		
		# 基础产量 (假设你以后有 base_production 这个字典)
		#"base_wood": data.base_production.get("wood", 0),
		
		# 其他地块通用属性
		"cost_wood": data.base_cost.get("wood", 0),
		"cost_stone": data.base_cost.get("stone", 0)
	}
	
	# 3. 替换并返回最终文本
	return translated_text.format(dynamic_vars)
