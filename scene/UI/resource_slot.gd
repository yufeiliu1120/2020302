extends Control

@onready var amount_label = $number # 必须是 RichTextLabel 并开启 BBCode

func update_display(current_amount: int, change_amount: int):
	# 基础数字
	var final_text = str(current_amount)
	
	# 实时拼接预期的加减号
	if change_amount > 0:
		final_text += " [color=green]+" + str(change_amount) + "[/color]"
	elif change_amount < 0:
		final_text += " [color=red]" + str(change_amount) + "[/color]"
		
	# change_amount == 0 时，什么都不拼接，直接显示当前库存
	
	amount_label.text = final_text

# 【新增】：报错动画！
func play_error_anim():
	# 设定中心点为锚点（如果需要缩放/旋转的话）
	pivot_offset = size / 2 
	
	var tween = create_tween()
	var original_x = position.x
	
	# 瞬间变红
	modulate = Color(1.0, 0.3, 0.3) 
	
	# 快速左右晃动 (4个小碎步)
	tween.tween_property(self, "position:x", original_x - 8, 0.04)
	tween.tween_property(self, "position:x", original_x + 8, 0.04)
	tween.tween_property(self, "position:x", original_x - 5, 0.04)
	tween.tween_property(self, "position:x", original_x + 5, 0.04)
	tween.tween_property(self, "position:x", original_x, 0.04) # 回归原位
	
	# 开一个新的 Tween 让颜色在 0.4 秒内慢慢褪回原来的白色
	var color_tween = create_tween()
	color_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.4)
