extends Node
class_name VictoryCondition
#所有胜利条件的基类，当修改胜利条件时，请修改下面的check_condition函数


# 当条件满足时，发出胜利信号
signal victory_achieved(message: String)

# 子类需要重写这个函数，包含具体的判断逻辑
func check_condition() -> bool:
	return false

# 统一的检测接口
func evaluate():
	if check_condition():
		victory_achieved.emit(get_victory_message())

# 子类可以重写胜利宣言
func get_victory_message() -> String:
	return "游戏胜利！"
