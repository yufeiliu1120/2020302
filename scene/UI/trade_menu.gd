extends Control

@onready var animator = $PanelAnimator
@onready var tp_label = $Trade_point_left
@onready var give_btn = $HBoxContainer/GiveButton
@onready var arrow_btn = $HBoxContainer/ArrowButton
@onready var get_btn = $HBoxContainer/GetButton
@onready var popup_menu = $PopupMenu # 我们刚才加的弹出菜单
@onready var give_button_label = $HBoxContainer/GiveButton/Label
@onready var get_button_label = $HBoxContainer/GetButton/Label
@onready var give_button_icon = $HBoxContainer/GiveButton/icon
@onready var get_button_icon = $HBoxContainer/GetButton/icon

# 游戏中可交易的资源种类
var tradeable_res = ["wood", "stone", "food"]
var current_give = "wood"
var current_get = "stone"
var current_rate = 1

var is_picking_give = true # 记录玩家刚才点的是左边还是右边

# 💡 请在右侧属性面板里，把这三种资源的对应图标拖进去！
@export var res_icons: Dictionary = {
	"wood": preload("res://assets/UI parts/resource icon wood.png"),
	"stone": preload("res://assets/UI parts/resource icon stone.png"),
	"food": preload("res://assets/UI parts/resource icon food.png")
}

func _ready():
	hide()
	# 1. 为弹出菜单塞入选项（带图标和文字）
	for i in range(tradeable_res.size()):
		var res_name = tradeable_res[i]
		# 【核心修改】：tr(res_name) 会自动把 "wood" 变成 "木材" 或 "Wood"
		popup_menu.add_icon_item(give_button_icon.texture, tr(res_name), i)
		
	# 2. 绑定点击事件
	give_btn.pressed.connect(func(): _open_popup(true))  # 点击左边
	get_btn.pressed.connect(func(): _open_popup(false)) # 点击右边
	popup_menu.id_pressed.connect(_on_popup_item_selected) # 菜单被选中时
	arrow_btn.pressed.connect(_on_trade_pressed)         # 点击中间的箭头
	
	# 3. 初始化 UI
	_update_trade_ui()
	# 给三个核心交互按钮注入动效！
	_add_button_juice(give_btn)
	_add_button_juice(get_btn)
	_add_button_juice(arrow_btn)
	
	_update_trade_ui()

# 打开面板
func open_menu():
	_update_tp_label()
	animator.open_panel()

func _update_tp_label():
	# 从大脑获取当前的交易点数
	var tp = GameResourceManager.stocks.get("trade_point", 0)
	# 【核心修改】：翻译并替换占位符
	tp_label.text = tr("trade_points_left").format({"tp": tp})
	
# 弹出选择菜单
func _open_popup(is_give: bool):
	is_picking_give = is_give
	# 让菜单直接在鼠标当前位置“啪”地弹出来
	popup_menu.position = get_global_mouse_position()
	popup_menu.popup()

# 玩家在弹出的菜单里选好了资源
func _on_popup_item_selected(id: int):
	var selected_res = tradeable_res[id]
	if is_picking_give:
		current_give = selected_res
	else:
		current_get = selected_res
		
	_update_trade_ui()

# 刷新两边的图标和中间的汇率
func _update_trade_ui():
	give_button_icon.texture = res_icons[current_give]
	get_button_icon.texture = res_icons[current_get]
	
	# 如果左右两边选了同一个资源，禁止交易
	if current_give == current_get:
		give_button_label.text = "无效"
		get_button_label.text = "无效"
		arrow_btn.disabled = true
		return
		
	# 【核心修改】：计算本次实际能拿出的交易量（最多为 5，不够则全拿）
	var player_has = GameResourceManager.stocks.get(current_give, 0)
	var trade_amount = mini(5, player_has) 
	
	# 获取基础汇率
	current_rate = _calculate_rate(current_give, current_get)
	
	# 如果玩家这个资源穷得连 1 个都没有
	if trade_amount == 0:
		give_button_label.text = "0"
		get_button_label.text = "0"
		arrow_btn.disabled = true # 没钱就禁用箭头
	else:
		# 动态显示：比如你只有 3 个木头，左边显示 3，右边显示 3 * 汇率
		give_button_label.text = str(trade_amount)
		get_button_label.text = str(trade_amount * current_rate)
		arrow_btn.disabled = false

# 🌟 动态汇率计算器
func _calculate_rate(give: String, get: String) -> int:
	# 默认 1换1。
	# 未来你可以加逻辑，比如 1木头 换 2食物：
	# if give == "wood" and get == "food": return 2
	return 1
# ----------------------------------------------------

# 玩家点击了中间的箭头！
func _on_trade_pressed():
	# 再次确认玩家当前有多少库存，防止打开菜单期间资源变动
	var player_has = GameResourceManager.stocks.get(current_give, 0)
	var trade_amount = mini(5, player_has)
	
	if trade_amount <= 0:
		return
		
	# 组装这笔批量交易的“账单”：
	var cost = {
		current_give: trade_amount,  # 扣除 1~5 个左侧资源
		"trade_point": 1             # 依然只扣 1 点交易手续费
	}
	
	if GameResourceManager.can_afford(cost):
		GameResourceManager.consume_resources(cost)
		
		# 给玩家发货：实际交易量 * 汇率
		GameResourceManager.add_resources({current_get: trade_amount * current_rate})
		
		_update_tp_label()
		# 【重要】：交易完后，立刻刷新一次 UI 数字。
		# 比如你原本有 8 个木头，换了 5 个，这里会立刻刷新显示为 "3 ➡ 3"
		_update_trade_ui() 
		
		print("批量交易成功！消耗: ", trade_amount, " ", current_give, "，获得: ", trade_amount * current_rate, " ", current_get)
	else:
		print("资源或交易点数不足！")
		GameResourceManager.purchase_failed.emit(cost)
# ==========================================
# 🌟 万能 UI 动效注入器
# ==========================================
func _add_button_juice(btn: Control):
	# 【核心设定】：确保缩放是从中心点开始，而不是默认的左上角！
	# 等待一帧，确保 UI 已经排版完毕并且获得了正确的 size
	call_deferred("_center_pivot", btn)

	# 1. 鼠标悬浮 (Hover)：微微放大，并且提亮颜色（产生发光感）
	btn.mouse_entered.connect(func():
		if btn is Button and btn.disabled: return # 禁用的按钮不发光
		var tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(btn, "modulate", Color(1.2, 1.2, 1.2), 0.1) # 1.2 代表超白/发光
	)

	# 2. 鼠标离开 (Normal)：恢复原状
	btn.mouse_exited.connect(func():
		var tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
		tween.parallel().tween_property(btn, "modulate", Color(1.0, 1.0, 1.0), 0.1)
	)

	# 3. 鼠标按下 (Pressed)：瞬间缩小，颜色变暗（产生被按下去的物理凹陷感）
	btn.button_down.connect(func():
		if btn is Button and btn.disabled: return
		var tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(0.9, 0.9), 0.05)
		tween.parallel().tween_property(btn, "modulate", Color(0.8, 0.8, 0.8), 0.05)
	)

	# 4. 鼠标松开 (Released)：弹回悬浮状态
	btn.button_up.connect(func():
		if btn is Button and btn.disabled: return
		var tween = create_tween()
		# 加上一点点弹簧回弹效果 (TRANS_BACK)
		tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(btn, "modulate", Color(1.2, 1.2, 1.2), 0.1)
	)

# 辅助函数：把中心点设为控件正中心
func _center_pivot(btn: Control):
	btn.pivot_offset = btn.size / 2.0
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ESC") or event.is_action_pressed("mouse_right"):
		animator.close_panel()
