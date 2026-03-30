extends Node
class_name DevCheats

# 只有在编辑器里运行游戏时，这个脚本才会生效。
# 这样你以后就算打包发布了游戏，玩家也无法触发这些快捷键！
func _ready():
	if not OS.has_feature("editor"):
		queue_free()

# 监听键盘输入
func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		
		# 按 F5：加 50 木头
		if event.keycode == KEY_F2:
			GameResourceManager.add_resources({"wood": 50})
			print("【作弊开启】已发放 50 木头！")
			
		# 按 F6：加 50 石头
		elif event.keycode == KEY_F3:
			GameResourceManager.add_resources({"stone": 50})
			print("【作弊开启】已发放 50 石头！")
			
		# 按 F7：加 50 食物 (妈妈再也不用担心我的工人饿死)
		elif event.keycode == KEY_F1:
			GameResourceManager.add_resources({"food": 50})
			print("【作弊开启】已发放 50 食物！")
			
		# 按 F8：加 5 交易点数 (测试市场和交易系统必备)
		elif event.keycode == KEY_F4:
			GameResourceManager.add_resources({"trade_point": 5})
			print("【作弊开启】已发放 5 交易点数！")
			
		# 按 F9：跳过当前回合 (如果你想快速刷回合数)
		elif event.keycode == KEY_F5:
			GameResourceManager.end_turn()
			print("【作弊开启】已强制跳过回合！")
