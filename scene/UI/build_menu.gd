extends Control

@onready var animator = $PanelAnimator
@onready var slots_container = $TextureRect/VBoxContainer # 替换成你的容器路径

func _ready():
	hide()
	# 自动遍历桌子上的所有商品，给它们连接购买逻辑
	for slot in slots_container.get_children():
		if slot is BuildSlot:
			slot.try_buy_tile.connect(_on_slot_try_buy)

# 底部按钮调用的打开函数
func open_menu():
	animator.open_panel()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ESC"):
		animator.close_panel()
# 接收商品发来的购买请求
func _on_slot_try_buy(scene: PackedScene, cost: Dictionary):
	# 1. 检查钱包
	if GameResourceManager.can_afford(cost):
		# 2. 扣钱
		GameResourceManager.consume_resources(cost)
		
		# 3. 优雅地关闭界面
		animator.close_panel(func():
			# 4. 面板关闭后，把地块发给玩家鼠标！
			# 这里直接调用你主界面接收地块的函数
			# 假设你的主界面有一个 handle_new_tile 函数，或者复用抽卡的那个逻辑
			build_menu_tile_selected(scene) 
		)
	else:
		# 没钱！触发顶部资源条的红字抖动动画！
		GameResourceManager.purchase_failed.emit(cost)
		
		
func build_menu_tile_selected(chosen_scene: PackedScene):
	# 1. 实例化地块
	var new_tile = chosen_scene.instantiate()
	# 2. 将它添加到地图中（完美复用你之前的 TileStorage 逻辑）
	var storage = get_tree().get_first_node_in_group("TileStorage")
	if storage:
		storage.add_child(new_tile)
	else:
		# 安全回退：如果没有找到 TileStorage，就加到当前场景
		get_tree().current_scene.add_child(new_tile)
	# 3. 【视觉优化】：先把地块瞬间传送到鼠标当前位置
	# 这样进入拖拽状态时，地块不会在屏幕左上角 (0,0) 闪烁一下
	new_tile.global_position = new_tile.get_global_mouse_position()
	# 4. 通知状态机进入拖拽状态！
	new_tile.Statemachine.current_state.state_finished.emit("Dragging")
