extends Node

# ⚠️ 统一配置加载界面的路径，以后改路径只需改这里
const LOADING_SCREEN_PATH = "res://scene/UI/loading_screen.tscn"

## 重新开始当前关卡
func restart_scene():
	var current_scene = get_tree().current_scene
	if current_scene:
		var current_path = current_scene.scene_file_path
		if current_path != "":
			goto_scene(current_path)
		else:
			push_error("【场景管理】无法重新开始：当前场景没有有效的场景文件路径。")

## 跳转到指定场景（带加载界面）
func goto_scene(target_path: String):
	if target_path == "":
		push_error("【场景管理】跳转失败：目标路径为空。")
		return

	# 1. 强制解除暂停，确保加载界面能运行
	get_tree().paused = false
	
	# 2. 实例化加载界面
	var loading_scene_packed = load(LOADING_SCREEN_PATH)
	if not loading_scene_packed:
		push_error("【场景管理】加载界面资源未找到：" + LOADING_SCREEN_PATH)
		return
		
	var loading_node = loading_scene_packed.instantiate()
	
	# 3. 传递场景参数
	if "next_scene_path" in loading_node:
		loading_node.next_scene_path = target_path
	else:
		push_warning("【场景管理】加载界面节点不包含 next_scene_path 变量。")
	
	# 4. 手动执行场景替换逻辑
	var root = get_tree().root
	var old_scene = get_tree().current_scene
	
	root.add_child(loading_node)
	get_tree().current_scene = loading_node
	
	# 5. 销毁旧场景
	if old_scene:
		old_scene.queue_free()
	
	print("【场景管理】正在通过加载界面前往：" + target_path)
