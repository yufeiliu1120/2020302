extends TextureRect # 如果你的根节点不是 TextureRect，请改回你的 Control 类型

# ==========================================
# 🎨 动画配置参数
# ==========================================
var hover_scale: Vector2 = Vector2(1.1, 1.1)
var normal_scale: Vector2 = Vector2(1.0, 1.0)
var hover_offset_y: float = -20.0

var base_position_y: float = 0.0
var is_selected: bool = false

# ==========================================
# 🎯 战术模式目标管理
# ==========================================
var current_targets: Array[Node] = []
var hovered_target: Node = null # 核心新增：记录当前鼠标正指着哪个合法目标

# ==========================================
# 🚀 初始化与基础动画
# ==========================================
func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	pivot_offset = Vector2(size.x / 2, size.y) 
	call_deferred("_record_base_position")
	
	# 连接卡牌自身的悬浮动画
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _record_base_position():
	base_position_y = position.y

func _on_mouse_entered():
	if is_selected: return
	z_index = 1 
	var tween = create_tween().set_parallel(true)
	AudioManager.play_sfx("button_hover")
	tween.tween_property(self, "scale", hover_scale, 0.15).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "position:y", base_position_y + hover_offset_y, 0.15).set_trans(Tween.TRANS_QUAD)

func _on_mouse_exited():
	if is_selected: return 
	z_index = 0 
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", normal_scale, 0.15).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "position:y", base_position_y, 0.15).set_trans(Tween.TRANS_QUAD)

# ==========================================
# 🖱️ 卡牌点击：进入战术模式
# ==========================================
func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		accept_event() # 吞掉点击事件
		
		if is_selected:
			_cancel_selection()
			return
			
		AudioManager.play_sfx("button_pressed")
		print("【骑士卡牌】使用骑士！扫描全图组件...")
		var targets = _scan_for_targets()
		
		if targets.is_empty():
			print("【骑士指令】岛上目前没有需要讨伐的敌人！")
			return
			
		is_selected = true
		
		# 卡牌升起动画
		var tween = create_tween()
		tween.tween_property(self, "position:y", base_position_y - 40.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		_enter_tactical_view(targets)

# ==========================================
# 🔍 扫描：寻找 Knight_Interface 组件
# ==========================================
func _scan_for_targets() -> Array[Node]:
	var valid_targets: Array[Node] = []
	
	for pos in GridAutoload.active_tiles.keys():
		var tile = GridAutoload.active_tiles[pos]
		if is_instance_valid(tile):
			var is_target = false
			# 遍历子节点，寻找带有 banish 函数的 Knight_Interface 组件
			for child in tile.get_children():
				if child.is_in_group("Knight Interface") and child.has_method("banish"):
					is_target = true
					break
			if is_target:
				valid_targets.append(tile)
				
	return valid_targets

# ==========================================
# 🌒 战术模式开启：高亮、变暗与【信号连接】
# ==========================================
func _enter_tactical_view(targets: Array[Node]):
	current_targets = targets
	hovered_target = null # 重置悬浮状态
	
	for pos in GridAutoload.active_tiles.keys():
		var tile = GridAutoload.active_tiles[pos]
		if is_instance_valid(tile):
			if tile in current_targets:
				# 1. 视觉高亮与呼吸效果
				tile.modulate = Color(1.2, 1.2, 1.2, 1.0) 
				var tween = create_tween().set_loops()
				tween.tween_property(tile, "modulate", Color(2.0, 1.0, 1.0, 1.0), 0.8) 
				tween.tween_property(tile, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.8) 
				tile.set_meta("highlight_tween", tween) 
				
				# 2. 🔌 【核心逻辑】：动态连接该地块的鼠标悬浮信号
				# 使用 .bind(tile) 能够把当前地块作为参数传给函数
				if not tile.mouse_entered.is_connected(_on_target_mouse_entered):
					tile.mouse_entered.connect(_on_target_mouse_entered.bind(tile))
				if not tile.mouse_exited.is_connected(_on_target_mouse_exited):
					tile.mouse_exited.connect(_on_target_mouse_exited.bind(tile))
					
			else:
				# 压暗无关地块
				tile.modulate = Color(0.3, 0.3, 0.3, 1.0) 

# ==========================================
# 🎯 目标悬浮追踪 (Area2D 信号回调)
# ==========================================
func _on_target_mouse_entered(target: Node):
	if is_selected:
		hovered_target = target
		# (可选) 你可以在这里让高亮的目标再变大一点点，反馈更好
		
func _on_target_mouse_exited(target: Node):
	if is_selected and hovered_target == target:
		hovered_target = null

# ==========================================
# 🌍 游戏内全局点击：驱逐与取消
# ==========================================
func _unhandled_input(event):
	if not is_selected: return
	
	if event is InputEventMouseButton and event.pressed:
		
		# 🖱️ 左键点击
		if event.button_index == MOUSE_BUTTON_LEFT:
			# 如果鼠标当前正指着一个合法目标，执行驱逐！
			if is_instance_valid(hovered_target):
				_execute_banish(hovered_target)
				get_viewport().set_input_as_handled() # 吞掉输入
			else:
				print("【骑士指令】未点中发光目标！")
				
		# 🖱️ 右键点击：取消战术模式
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_selection()
			get_viewport().set_input_as_handled() # 吞掉输入

# ==========================================
# ⚔️ 执行驱逐与卡牌消耗
# ==========================================
func _execute_banish(target_tile: Node):
	for child in target_tile.get_children():
		if child.is_in_group("Knight Interface") and child.has_method("banish"):
			print("骑士发起了冲锋！目标：", target_tile.name)
			child.banish() 
			break 
			
	_cancel_selection()
	
	# ==========================================
	# ⚡ 【核心新增】：打完收工后的全局通知
	# ==========================================
	# 1. 刷新物流网（如果驱逐强盗变回了道路，需要立刻接通周围的物流）
	if ConnectivityManager.has_method("update_connectivity"):
		ConnectivityManager.update_connectivity()
		
	# 2. 通知所有灾难事件：立刻重新清点人数！
	if SignalBusAutoload.has_signal("enemy_banished"):
		SignalBusAutoload.enemy_banished.emit()
		
	queue_free()

# ==========================================
# ☀️ 取消选中：恢复颜色并【断开信号】
# ==========================================
func _cancel_selection():
	is_selected = false
	hovered_target = null
	
	var tween = create_tween()
	tween.tween_property(self, "position:y", base_position_y, 0.2).set_trans(Tween.TRANS_QUAD)
	
	for pos in GridAutoload.active_tiles.keys():
		var tile = GridAutoload.active_tiles[pos]
		if is_instance_valid(tile):
			# 清除动画
			if tile.has_meta("highlight_tween"):
				var t = tile.get_meta("highlight_tween")
				if t and t.is_valid(): t.kill()
				tile.remove_meta("highlight_tween")
			
			# 恢复颜色
			tile.modulate = Color(1.0, 1.0, 1.0, 1.0) 
			
			# 🔌 断开目标地块的鼠标信号，防止内存泄漏或误触
			if tile in current_targets:
				if tile.mouse_entered.is_connected(_on_target_mouse_entered):
					tile.mouse_entered.disconnect(_on_target_mouse_entered)
				if tile.mouse_exited.is_connected(_on_target_mouse_exited):
					tile.mouse_exited.disconnect(_on_target_mouse_exited)
					
	current_targets.clear()
