extends RefCounted
class_name BaseDurationEvent # 【核心】：注册为一个全局类，方便其他脚本继承

var remaining_turns: int = 0 
var effect_type: String = "base_event"

# ==========================================
# ⚙️ 核心运转逻辑 (不需要再在子类里写了)
# ==========================================
func execution_event():
	# 1. 查重与叠加逻辑
	for effect in GameResourceManager.active_event_effects:
		if effect.get("effect_type") == self.effect_type:
			print("【事件叠加】%s 持续时间延长！新增 %d 回合！" % [self.effect_type, self.remaining_turns])
			effect.remaining_turns += self.remaining_turns
			effect._update_ui() # 通知前辈刷新 UI
			return # 直接销毁自己

	# 2. 如果是全新事件，走初始化流程
	print("【事件触发】%s 降临！持续 %d 回合！" % [self.effect_type, self.remaining_turns])
	GameResourceManager.active_event_effects.append(self)
	
	# 【挂钩】：调用子类独有的生效代码
	_on_event_start() 
	_update_ui()
	
	if not GameResourceManager.turn_started.is_connected(_on_turn_started):
		GameResourceManager.turn_started.connect(_on_turn_started)

func _on_turn_started(_current_turn: int):
	remaining_turns -= 1
	
	if remaining_turns <= 0:
		print("【事件结束】%s 退去！" % self.effect_type)
		# 【挂钩】：调用子类独有的失效代码
		_on_event_end()
		
		if GameResourceManager.turn_started.is_connected(_on_turn_started):
			GameResourceManager.turn_started.disconnect(_on_turn_started)
		GameResourceManager.active_event_effects.erase(self)
		
	# 无论事件是否结束，都会刷新 UI
	_update_ui()

# ==========================================
# 🧩 虚函数 (Virtual Methods) - 留给具体灾难去填空的坑位
# ==========================================

# 当事件刚开始时要做什么？
func _on_event_start():
	pass 

# 当事件结束时要做什么？
func _on_event_end():
	pass 

# 这个事件需要刷新哪些 UI？
func _update_ui():
	pass
