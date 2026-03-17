extends Control
class_name TileCard

@onready var icon_rect = $TileIcon
@onready var name_label = $VBoxContainer/TileName
@onready var desc_label = $VBoxContainer/TileDescription
var hover_tween: Tween

func _ready():
	# 绑定鼠标悬停和移出的信号
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_idle)
	
# 当卡牌被抽卡系统“发”出来时，调用这个函数进行初始化
func init_card(data: TileResourceData):
	if data == null:
		return
		
	if data.icon:
		icon_rect.texture = data.icon
		
	# 【关键修改】：用 tr() 包裹原本的字符串！
	name_label.text = tr(data.tile_name)
	
	# 获取描述，如果没有填，默认给个 UNKNOWN_DESC 的占位键值
	var raw_desc = data.description
	if raw_desc == "": raw_desc = "UNKNOWN_DESC"
	
	# 【修改】：直接把生肉和数据丢进全局绞肉机！
	desc_label.text = TextManager.format_tile_desc(raw_desc, data)
func _on_hover():
	# 把缩放和旋转的中心点设置到卡牌正中央
	pivot_offset = size / 2
	
	# 如果之前有正在播放的动画，先把它掐断
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		
	# 创建新的平滑动画
	hover_tween = create_tween().set_parallel(true) # set_parallel(true) 让接下来的动画同时发生
	# 放大到 1.1 倍，用时 0.15 秒，使用弹簧般丝滑的缓动曲线
	hover_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# 微微向右倾斜 2 度
	hover_tween.tween_property(self, "rotation_degrees", 2.0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# （可选）让卡牌在图层中变高，这样放大的时候不会被旁边的卡牌挡住
	z_index = 10 


func _on_idle():
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		
	hover_tween = create_tween().set_parallel(true)
	# 恢复原状
	hover_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	hover_tween.tween_property(self, "rotation_degrees", 0.0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 层级恢复
	z_index = 0
	
# --- 发牌动画 ---
# 传入一个 delay（延迟时间），这样我们就能让三张卡牌“依次”飞出来
func play_appear_anim(delay: float):
	# 确保从中心放大
	visible = true
	pivot_offset = size / 2 
	
	# 初始状态：完全透明，且缩得非常小
	scale = Vector2(0, 0)
	modulate = Color(1, 1, 1, 0)
	
	var tween = create_tween().set_parallel(true)
	# 延迟 delay 秒后，开始变亮
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2).set_delay(delay)
	# 延迟 delay 秒后，弹出到正常大小，带有果冻回弹效果！
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)


# --- 被点击（选中）动画 ---
# 传入一个 Callable，动画播完后通知主面板“我表演完了，你可以关门了”
func play_click_anim(on_complete: Callable):
	# 如果鼠标悬停的放大动画还在播，立刻掐断它
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		
	pivot_offset = size / 2
	z_index = 20 # 把自己提到最上层，防止被旁边的牌挡住
	
	var tween = create_tween().set_parallel(true)
	
	# 1. 瞬间再放大一点点（模拟“被抓起”的感觉）
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_SINE)
	
	# 2. 然后迅速缩小并消失（被收入囊中）
	# chain() 保证这一步在上面的“放大”完成后执行
	tween.chain().tween_property(self, "scale", Vector2(0.5, 0.5), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 0), 0.2)
	
	# 3. 动画彻底结束后，呼叫回调函数
	tween.chain().tween_callback(on_complete)
