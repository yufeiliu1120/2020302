extends Node

# ==========================================
# ⚙️ 核心配置 (可以在右侧 Inspector 面板直接修改)
# ==========================================
@export var turns_to_generate: int = 3 # 需要几个回合产出
@export var card_scene: PackedScene # 【神来之笔】：把具体的卡牌图纸挖空，以后随便填！

var current_turns: int = 0

func _ready():
	if not GameResourceManager.turn_started.is_connected(_on_turn_started):
		GameResourceManager.turn_started.connect(_on_turn_started)

# ==========================================
# 🔄 回合结算
# ==========================================
func _on_turn_started(_current_turn: int):
	# 1. 检查父节点（城堡地块）是否被枯萎病或怪物压制了
	var parent_tile = get_parent()
	if parent_tile.get("is_suppressed") or parent_tile.get("is_disabled"):
		return
		
	# 2. 推进进度
	current_turns += 1
	if current_turns >= turns_to_generate:
		# 尝试把卡发到玩家手里
		var success = _try_spawn_card()
		
		if success:
			AudioManager.play_sfx("get_card")
			current_turns = 0 # 发牌成功，重新开始计步
		else:
			current_turns = turns_to_generate # 发牌失败（手牌满了），保持在即将发牌的状态，等下回合重试

# ==========================================
# 🃏 核心动作：寻找容器并实例化卡牌
# ==========================================
func _try_spawn_card() -> bool:
	if card_scene == null:
		push_error("【卡牌生成器】未配置卡牌场景！请在 Inspector 中拖入图纸！")
		return false
		
	# 1. 寻找手牌容器
	var tree = get_tree()
	var containers = tree.get_nodes_in_group("card container")
	if containers.is_empty():
		print("【卡牌生成器】找不到 card_container 组，无法发牌！")
		return false
		
	var hand_container = containers[0]
	
	# 2. 检查手牌容量上限
	var current_card_count = hand_container.get_child_count()
	# 安全获取最大卡牌数，如果没有设默认给个 4
	var max_cards = GameResourceManager.get("max_card_count") 
	if max_cards == null: max_cards = 4
	
	if current_card_count >= max_cards:
		print("【卡牌生成器】手牌区已满 (%d/%d)，暂停发放！" % [current_card_count, max_cards])
		return false
		
	# 3. 实例化卡牌并加入手牌区！
	var new_card = card_scene.instantiate()
	hand_container.add_child(new_card)
	
	# ✨ 顺手加个入场弹跳动画（Juiciness）
	new_card.scale = Vector2(0.1, 0.1)
	var tween = create_tween()
	tween.tween_property(new_card, "scale", Vector2(1.1, 1.1), 0.15).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(new_card, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_BOUNCE)
	
	return true
