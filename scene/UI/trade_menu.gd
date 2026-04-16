extends Control

@onready var animator = $PanelAnimator
@onready var tp_label = $Trade_point_left
@onready var give_btn = $HBoxContainer/GiveButton
@onready var arrow_btn = $HBoxContainer/ArrowButton
@onready var get_btn = $HBoxContainer/GetButton
@onready var popup_menu = $PopupMenu 
@onready var give_button_label = $HBoxContainer/GiveButton/Label
@onready var get_button_label = $HBoxContainer/GetButton/Label
@onready var give_button_icon = $HBoxContainer/GiveButton/icon
@onready var get_button_icon = $HBoxContainer/GetButton/icon
@onready var title_label = $title

# 游戏中可交易的资源种类 (已加入 metal)
var tradeable_res = ["wood", "stone", "food", "metal"]
var current_give = "wood"
var current_get = "stone"

# 【修复 1】：将基础汇率声明为浮点数 float，防止 0.5 被吞掉变成 0
var current_rate: float = 1.0 

var is_picking_give = true 

# 💡 别忘了在右侧属性面板里，把【金属】的图标也加进字典里！
@export var res_icons: Dictionary = {
	"wood": preload("res://assets/UI parts/resource icon wood.png"),
	"stone": preload("res://assets/UI parts/resource icon stone.png"),
	"food": preload("res://assets/UI parts/resource icon food.png"),
	# "metal": preload("你的金属图标路径...") # 记得取消注释并配置好
}

func _ready():
	hide()
	for i in range(tradeable_res.size()):
		var res_name = tradeable_res[i]
		popup_menu.add_icon_item(give_button_icon.texture, tr(res_name), i)
		
	give_btn.pressed.connect(func(): _open_popup(true))  
	get_btn.pressed.connect(func(): _open_popup(false)) 
	popup_menu.id_pressed.connect(_on_popup_item_selected) 
	arrow_btn.pressed.connect(_on_trade_pressed)         
	
	_update_trade_ui()
	_add_button_juice(give_btn)
	_add_button_juice(get_btn)
	_add_button_juice(arrow_btn)
	
	_update_trade_ui()

func open_menu():
	_update_tp_label()
	animator.open_panel()

func _update_tp_label():
	var tp = GameResourceManager.stocks.get("trade_point", 0)
	tp_label.text = tr("trade_points_left").format({"tp": tp})
	
func _open_popup(is_give: bool):
	is_picking_give = is_give
	popup_menu.position = get_global_mouse_position()
	popup_menu.popup()

func _on_popup_item_selected(id: int):
	var selected_res = tradeable_res[id]
	if is_picking_give:
		current_give = selected_res
	else:
		current_get = selected_res
		
	_update_trade_ui()

# 刷新两边的图标和中间的汇率
func _update_trade_ui():
	if GameResourceManager.get("is_trade_disabled"):
		arrow_btn.disabled = true
		var turns_left = 0
		for effect in GameResourceManager.active_event_effects:
			if effect.get("effect_type") == "trade_block": 
				turns_left = effect.remaining_turns
				break 
				
		if title_label:
			var block_text = tr("trade_menu_blocked_text")
			var turn_text = str(turns_left)
			title_label.text = "[center][color=red][wave amp=30.0 freq=10.0 connected=1]" + block_text + turn_text + "[/wave][/color][/center]"
		return
			
	else:
		if title_label:
			title_label.text = "[center]" + tr("trade_menu_text") + "[/center]"
		
	# 【安全拦截】：如果没有配置金属图标，临时放个别的防报错
	give_button_icon.texture = res_icons.get(current_give, res_icons["wood"])
	get_button_icon.texture = res_icons.get(current_get, res_icons["wood"])
	
	if current_give == current_get:
		give_button_label.text = tr("unable")
		get_button_label.text = tr("unable")
		arrow_btn.disabled = true
		return
		
	var player_has = GameResourceManager.stocks.get(current_give, 0)
	var max_trade = mini(5, player_has) 
	
	current_rate = _calculate_rate(current_give, current_get)
	
	# ==========================================
	# 💡 【核心修复】：防坑机制 (取整 + 剔除多余尾数)
	# ==========================================
	var trade_amount = max_trade
	
	if current_rate < 1.0:
		# 比如汇率 0.5 -> 倒数就是 2 (意味着每 2 个才能换 1 个)
		var required_multiple = roundi(1.0 / current_rate) 
		# 如果玩家拿了 5 个，5 % 2 = 1。那么实际交易量退回到 4 个，不让玩家吃亏！
		trade_amount = trade_amount - (trade_amount % required_multiple)
		
	# 最终到手数量：向下取整（如 4 * 0.5 = 2）
	var final_get = floori(trade_amount * current_rate)
	
	# 如果玩家连 1 个最终产物都换不到（比如穷得只有 1 个木头，换不到 0.5 个金属）
	if trade_amount == 0 or final_get == 0:
		give_button_label.text = str(max_trade) # 左边显示他可怜的库存
		get_button_label.text = "0"
		arrow_btn.disabled = true 
	else:
		give_button_label.text = str(trade_amount)
		get_button_label.text = str(final_get)
		arrow_btn.disabled = false

# 🌟 动态汇率计算器
# 【修复 2】：返回值必须改成 -> float
func _calculate_rate(give: String, get: String) -> float:
	if get == "metal": return 0.5
	if give == "metal": return 2.0
	return 1.0

# 玩家点击了中间的箭头！
func _on_trade_pressed():
	var player_has = GameResourceManager.stocks.get(current_give, 0)
	var trade_amount = mini(5, player_has)
	
	# 【重要】：这里要用同样的防坑逻辑再算一遍，防止数据错位
	if current_rate < 1.0:
		var required_multiple = roundi(1.0 / current_rate) 
		trade_amount = trade_amount - (trade_amount % required_multiple)
		
	var final_get = floori(trade_amount * current_rate)
	
	if trade_amount <= 0 or final_get <= 0:
		return
		
	var cost = {
		current_give: trade_amount,  # 扣除整理后的防坑数额
		"trade_point": 1             
	}
	
	if GameResourceManager.can_afford(cost):
		GameResourceManager.consume_resources(cost)
		
		# 给玩家发货：发送取整过后的安全数值
		GameResourceManager.add_resources({current_get: final_get})
		
		_update_tp_label()
		_update_trade_ui() 
		
		print("批量交易成功！消耗: ", trade_amount, " ", current_give, "，获得: ", final_get, " ", current_get)
	else:
		print("资源或交易点数不足！")
		GameResourceManager.purchase_failed.emit(cost)

# ==========================================
# 🌟 万能 UI 动效注入器
# ==========================================
func _add_button_juice(btn: Control):
	call_deferred("_center_pivot", btn)

	btn.mouse_entered.connect(func():
		if btn is Button and btn.disabled: return 
		var tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(btn, "modulate", Color(1.2, 1.2, 1.2), 0.1) 
	)

	btn.mouse_exited.connect(func():
		var tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
		tween.parallel().tween_property(btn, "modulate", Color(1.0, 1.0, 1.0), 0.1)
	)

	btn.button_down.connect(func():
		if btn is Button and btn.disabled: return
		var tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(0.9, 0.9), 0.05)
		tween.parallel().tween_property(btn, "modulate", Color(0.8, 0.8, 0.8), 0.05)
	)

	btn.button_up.connect(func():
		if btn is Button and btn.disabled: return
		var tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(btn, "modulate", Color(1.2, 1.2, 1.2), 0.1)
	)

func _center_pivot(btn: Control):
	btn.pivot_offset = btn.size / 2.0
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ESC") or event.is_action_pressed("mouse_right"):
		animator.close_panel()
