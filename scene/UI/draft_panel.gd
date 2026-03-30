extends Control

# 当玩家选中某张卡片时发出信号，通知主游戏进入“放置地块”状态
@export var exploror_costs:int = 1
@onready var card_buttons = [
	$PanelContainer/MarginContainer/background/HBoxContainer/card1,
	$PanelContainer/MarginContainer/background/HBoxContainer/card2,
	$PanelContainer/MarginContainer/background/HBoxContainer/card3
]
@onready var animator = $PanelAnimator
# 【重点】：这是你的卡池！把你做好的自然地块场景拖进来
# （比如 草地.tscn, 森林.tscn, 海岸.tscn, 山脉.tscn）
@export var tile_pool: Array[PackedScene] = []

func _ready():
	# 默认隐藏弹窗
	hide()
	
	# 给三张卡牌绑定点击事件
	for i in range(card_buttons.size()):
		card_buttons[i].pressed.connect(_on_card_clicked.bind(i))
		card_buttons[i].visible = false
# 底部按钮调用这个函数来打开抽卡界面
func open_draft():
	if GameResourceManager.stocks.get("explorer", 0) >= 1:
		GameResourceManager.consume_resources({"explorer": exploror_costs})
		
		# 直接让动画师干活！一行代码搞定！
		animator.open_panel()
		await get_tree().create_timer(0.5).timeout
		_roll_cards()
		
	else:
		print("探险家不足！")
		GameResourceManager.purchase_failed.emit({"explorer": exploror_costs})


# 核心抽卡逻辑
func _roll_cards():
	for i in range(card_buttons.size()):
		var random_scene = tile_pool.pick_random()
		card_buttons[i].set_meta("tile_scene", random_scene)
		
		var temp_tile = random_scene.instantiate()
		if temp_tile.data:
			card_buttons[i].init_card(temp_tile.data)
		temp_tile.queue_free()
		
		# 【新增】：让卡牌播放出现动画！
		# i * 0.15 意味着：第一张延迟0秒，第二张延迟0.15秒，第三张延迟0.3秒
		card_buttons[i].play_appear_anim(i * 0.15)
		
		
# 玩家点击了某张卡片
func _on_card_clicked(index: int):
	# 1. 立刻禁用所有按钮，防止动画期间的二次点击！
	for btn in card_buttons:
		btn.disabled = true
		
	var chosen_scene = card_buttons[index].get_meta("tile_scene")
	
	# 2. 视觉优化：让没被选中的卡牌立刻变暗/透明，烘托出你选中的那张
	for i in range(card_buttons.size()):
		if i != index:
			var fade_tween = create_tween()
			fade_tween.tween_property(card_buttons[i], "modulate", Color(1, 1, 1, 0), 0.2)
	
	# 3. 让被选中的卡牌播放它的专属动画！
	card_buttons[index].play_click_anim(func():
		# 当这张卡的消失动画播完后，再让大面板整体关闭
		animator.close_panel(func():
			
			# 面板彻底关完后，恢复所有按钮的可点击状态（为下次抽卡做准备）
			for btn in card_buttons:
				btn.disabled = false
				
			# 把地块发给鼠标
			draft_panel_tile_selected(chosen_scene)
		)
	)
	
func draft_panel_tile_selected(chosen_scene: PackedScene):
	# 1. 实例化地块（不需要检查余额，因为是用探险家换来的奖品）
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
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ESC") or event.is_action_pressed("mouse_right"):
		animator.close_panel()
