@tool
extends EditorScript

const SEARCH_DIR = "res://scene/tile/" 

func _run():
	print("开始扫描并生成 CSV 表格...")
	var tscn_files = _get_all_tscn_files(SEARCH_DIR)
	
	var save_path = "res://TileDataPreview.csv"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	
	if file:
		# 【黑科技】：写入 UTF-8 BOM 头，防止 Excel 打开时中文乱码！
		file.store_buffer(PackedByteArray([0xEF, 0xBB, 0xBF]))
		
		# 1. 定义表头（第一行）
		var headers = PackedStringArray([
			"地块名称", 
			"需要道路", 
			"需要领地", 
			"建造成本", 
			"常规产出", 
			"食物产出", 
			"食物维护费", 
			"加成目标", 
			"提供加成",
			"来源路径"
		])
		file.store_csv_line(headers)
		
		# 2. 遍历所有场景并填入数据
		for file_path in tscn_files:
			var packed_scene = ResourceLoader.load(file_path)
			if packed_scene is PackedScene:
				var tile_instance = packed_scene.instantiate()
				
				if tile_instance and "data" in tile_instance and tile_instance.data != null:
					var res = tile_instance.data
					var t_name = res.get("tile_name")
					
					if t_name != null and t_name != "":
						# 将每一行的数据按表头顺序打包
# 提前安全获取数值，避免 null 报错
						var f_prod = res.get("food_production")
						var f_maint = res.get("food_maintenance")
						var adj_tile = res.get("adjacency_bonus_tile")
						
						# 将每一行的数据按表头顺序打包
						var row = PackedStringArray([
							str(t_name),
							"是" if res.get("requires_road") else "否",
							"是" if res.get("requires_hq_adjacency") else "否",
							_dict_to_string(res.get("upgrade_cost")),
							_dict_to_string(res.get("production")),
							str(f_prod) if f_prod != null else "0",
							str(f_maint) if f_maint != null else "0",
							str(adj_tile) if adj_tile != null and str(adj_tile) != "" else "-",
							_dict_to_string(res.get("adjacency_bonus_amount")),
							file_path
						])
						
						# 写入一行数据
						file.store_csv_line(row)
						print("已导出并写入表格: ", t_name)
						
				if tile_instance:
					tile_instance.queue_free()
					
		file.close()
		print("=======================================")
		print("✅ CSV 表格导出成功！请在文件系统查看: ", save_path)
		print("=======================================")
	else:
		push_error("无法创建 CSV 文件！")

# 辅助函数：将字典转换为好看的字符串
func _dict_to_string(d) -> String:
	if d == null or typeof(d) != TYPE_DICTIONARY or d.is_empty():
		return "-"
	# 去掉 JSON 中多余的引号和括号，让表格看起来更干净
	var result = JSON.stringify(d).replace("\"", "").replace("{", "").replace("}", "")
	return result

# 递归寻找 .tscn 文件
func _get_all_tscn_files(path: String) -> Array:
	var files = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if not file_name.begins_with("."):
					files.append_array(_get_all_tscn_files(path + file_name + "/"))
			else:
				if file_name.ends_with(".tscn"):
					files.append(path + file_name)
			file_name = dir.get_next()
	return files
