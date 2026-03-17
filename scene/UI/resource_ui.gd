extends Control

@onready var slot_wood = $HBoxContainer/wood
@onready var slot_stone = $HBoxContainer/stone
@onready var slot_food = $HBoxContainer/food
@onready var slot_metal = $HBoxContainer/metal
@onready var slot_explorer = $HBoxContainer/exploror

func _ready():
	GameResourceManager.resources_changed.connect(_update_all_slots)
	SignalBusAutoload.map_state_changed.connect(_update_all_slots)
	
	# 监听购买失败的信号
	GameResourceManager.purchase_failed.connect(_on_purchase_failed)
	
	_update_all_slots()

# 无论是资源变了，还是地图变了，都强制刷新一次UI
# (用 dummy_arg 吸收掉信号传过来的参数，我们直接从单例拿最新数据)
func _update_all_slots(dummy_arg = null):
	# 获取当前真实库存
	var current_stocks = GameResourceManager.stocks
	# 获取最新的模拟预期收入！
	var projected = GameResourceManager.get_projected_income()
	
	# 把 当前库存 和 预期收入 传给卡槽
	slot_wood.update_display(current_stocks.get("wood", 0), projected.get("wood", 0))
	slot_stone.update_display(current_stocks.get("stone", 0), projected.get("stone", 0))
	slot_food.update_display(current_stocks.get("food", 0), projected.get("food", 0))
	slot_metal.update_display(current_stocks.get("metal", 0), projected.get("metal", 0))
	slot_explorer.update_display(current_stocks.get("explorer", 0), projected.get("explorer", 0))
	
	
# 【新增】：精准打击，缺哪个晃哪个
func _on_purchase_failed(cost: Dictionary):
	var current_stocks = GameResourceManager.stocks
	
	# 挨个检查，如果当前库存小于花费要求，就让对应的 UI 播放报错动画！
	if current_stocks.get("wood", 0) < cost.get("wood", 0):
		slot_wood.play_error_anim()
		
	if current_stocks.get("stone", 0) < cost.get("stone", 0):
		slot_stone.play_error_anim()
		
	if current_stocks.get("food", 0) < cost.get("food", 0):
		slot_food.play_error_anim()
		
	if current_stocks.get("metal", 0) < cost.get("metal", 0):
		slot_metal.play_error_anim()
		
	if current_stocks.get("explorer", 0) < cost.get("explorer", 0):
		slot_explorer.play_error_anim()
