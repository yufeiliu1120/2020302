
extends TextureRect # 如果你的根节点不是 TextureRect，请改成对应的 Control 类型

# ==========================================
# 🎨 动画配置参数
# ==========================================
var hover_scale: Vector2 = Vector2(1.1, 1.1) # 悬浮时放大 1.1 倍
var normal_scale: Vector2 = Vector2(1.0, 1.0)
var hover_offset_y: float = -20.0 # 悬浮时向上移动 20 像素

# 记录卡牌的原始 Y 坐标，方便复原
var base_position_y: float = 0.0
var is_selected: bool = false # 为下一步点击选中做准备

func _ready():
	# 1. 确保卡牌能够阻挡并接收鼠标事件
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 2. 将缩放中心点设置在卡牌的“底边中心”或“正中心”
	# 这样卡牌放大的时候才不会尴尬地向右下角偏移
	pivot_offset = Vector2(size.x / 2, size.y) 
	
	# 3. 记录初始位置 (建议用 call_deferred 确保 UI 布局完成后再记录)
	call_deferred("_record_base_position")
	
	# 4. 连接自带的鼠标输入信号
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _record_base_position():
	base_position_y = position.y

# ==========================================
# ✨ 鼠标悬浮动画
# ==========================================
func _on_mouse_entered():
	if is_selected: return # 如果已经被点选了，就不播悬浮动画了
	
	# 提升渲染层级，让这张卡牌显示在其他卡牌的上方
	z_index = 1 
	
	# 使用 set_parallel(true) 让放大和上浮同时发生
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", hover_scale, 0.15).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "position:y", base_position_y + hover_offset_y, 0.15).set_trans(Tween.TRANS_QUAD)
	
	# 你可以在这里加个轻微的“唰”的音效！

# ==========================================
# 🍂 鼠标移出动画
# ==========================================
func _on_mouse_exited():
	if is_selected: return 
	
	# 恢复渲染层级
	z_index = 0 
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", normal_scale, 0.15).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "position:y", base_position_y, 0.15).set_trans(Tween.TRANS_QUAD)

# ==========================================
# 🖱️ 鼠标点击侦测 (为下一步准备)
# ==========================================
func _gui_input(event):
	# 侦测鼠标左键按下
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		accept_event() # 吞掉这个点击事件，防止穿透到下层地图
		
		print("【骑士卡牌】被点击！准备扫描全图目标...")
		is_selected = true
		
		# 选中后可以给个特殊的动画反馈（比如再往上提一点，或者发光）
		var tween = create_tween()
		tween.tween_property(self, "position:y", base_position_y - 40.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		# TODO: 下一步在这里呼叫全局信号，让大本营高亮目标地块！
