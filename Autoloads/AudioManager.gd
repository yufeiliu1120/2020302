extends Node

# ==========================================
# 🎵 音效资源字典 (Data-Driven SFX)
# 在这里将音效名字映射到对应的音频文件
# ==========================================
var sfx_dict: Dictionary = {
"button_hover":preload("res://assets/SFX/button hover.mp3"),
"button_pressed":preload("res://assets/SFX/button pressed.mp3"),
"tile_drop":preload("res://assets/SFX/tile drop.mp3"),
"UI_OPEN":preload("res://assets/SFX/ui_open.mp3"),
"EVENT_NAME_SEA_STORM":preload("res://assets/SFX/sea storm.mp3"),
"EVENT_NAME_FOREST_AWAKENING":preload("res://assets/SFX/forest awakening.mp3"),
"EVENT_NAME_ROYAL_TAX":preload("res://assets/SFX/royal_tax.mp3"),
"EVENT_NAME_MINE_EXPLOSION":preload("res://assets/SFX/mine_explosion.mp3"),
"EVENT_NAME_BLIGHT":preload("res://assets/SFX/blight.mp3"),
"EVENT_NAME_FAMINE":preload("res://assets/SFX/famine.mp3"),
"EVENT_NAME_BANDITS":preload("res://assets/SFX/bandits.mp3"),
"get_card":preload("res://assets/SFX/get_card.mp3"),
"box_slide":preload("res://assets/SFX/box open.mp3")
}

# ==========================================
# 🎵 背景音乐播放列表 (BGM Playlist)
# 把你用 Suno 生成的音乐全塞进这个数组里
# ==========================================
var bgm_playlist: Array[AudioStream] = [
	preload("res://assets/bgm/__Lute & Ledger__.wav"),
	preload("res://assets/bgm/Mapmakers’ Lute 2.wav"),
	preload("res://assets/bgm/Mapmakers’ Lute.wav")
]

# 全局唯一的 BGM 播放器
var bgm_player: AudioStreamPlayer
# 记录上一首播放的歌，防止连续两首播一样的
var last_played_bgm: AudioStream = null
var bgm_volume_dB = -20
func _ready():
	add_to_group("Resettable")
	# 【黑魔法】：监听整个场景树的节点添加事件
	# 这样以后无论你用代码动态生成什么 UI，管家都能瞬间捕捉并绑上音效
	get_tree().node_added.connect(_on_node_added)
	
	# 顺便把游戏启动时已经存在于场景树里的节点也扫一遍
	_bind_existing_nodes(get_tree().root)
	# ==========================================
	# 🌟 初始化 BGM 系统
	# ==========================================
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "BGM" # 确保你在底部 Audio 面板建了名叫 "BGM" 的总线
	add_child(bgm_player)
	
	# 【核心】：一首歌播完（触发 finished 信号），立刻再抽一首新的播！
	bgm_player.finished.connect(_play_random_bgm)
	bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	# 监听大本营发出的游戏开始信号 (这里使用你的 SignalBusAutoload)
	if SignalBusAutoload.has_signal("game_start"):
		SignalBusAutoload.game_start.connect(_play_random_bgm)

# ==========================================
# 🔊 核心逻辑：动态音效池 (Dynamic Pool)
# 任何地方只需要呼叫：AudioManager.play_sfx("名字")
# ==========================================
func play_sfx(sfx_name: String, _volume_db = 0.0):
	# 安全检查：如果字典里没这个音效，直接退出，绝不崩溃
	if not sfx_dict.has(sfx_name):
		push_warning("【音频管家】找不到指定音效: " + sfx_name)
		return
		
	# 1. 现切现做：实例化一个新的播放器
	var player = AudioStreamPlayer.new()
	player.stream = sfx_dict[sfx_name]
	
	# 2. 分配到正确的音频总线 (确保你在引擎底部新建了名为 "SFX" 的总线)
	# 如果还没有建，这行可以先注释掉或者写 "Master"
	player.bus = "SFX" 
	
	# 3. 加入场景树并播放
	add_child(player)
	player.volume_db = _volume_db
	player.play()
	
	# 4. 阅后即焚：播放完毕后自动调用 queue_free 销毁节点，释放内存
	player.finished.connect(player.queue_free)


# ==========================================
# 🖱️ UI 自动化钩子 (Auto UI Hooks)
# ==========================================
func _on_node_added(node: Node):
	# BaseButton 是所有按钮（Button, TextureButton 等）的父类
	if node is BaseButton:
		_bind_button_sounds(node)

func _bind_existing_nodes(node: Node):
	if node is BaseButton:
		_bind_button_sounds(node)
	for child in node.get_children():
		_bind_existing_nodes(child)

func _bind_button_sounds(btn: BaseButton):
	# 防止重复绑定导致一声点出两声响
	if not btn.mouse_entered.is_connected(_on_btn_hover):
		btn.mouse_entered.connect(_on_btn_hover)
		
	if not btn.pressed.is_connected(_on_btn_click):
		btn.pressed.connect(_on_btn_click)

# 按钮触发的回调函数
func _on_btn_hover():
	play_sfx("button_hover")

func _on_btn_click():
	play_sfx("button_pressed")


# ==========================================
# 🎶 BGM 随机切歌逻辑
# ==========================================
func _play_random_bgm():
	if bgm_playlist.is_empty():
		push_warning("【音频管家】BGM 列表为空！")
		return
		
	# 随机抽一首歌
	var next_bgm = bgm_playlist.pick_random()
	
	# 智能防重复：如果列表里有多首歌，保证下一首绝对不和上一首一样
	if bgm_playlist.size() > 1:
		while next_bgm == last_played_bgm:
			next_bgm = bgm_playlist.pick_random()
			
	last_played_bgm = next_bgm
	bgm_player.stream = next_bgm
	bgm_player.volume_db = bgm_volume_dB
	bgm_player.play()
	
	print("【音频管家】正在播放 BGM...")

# 提供给外部手动切歌或控制的方法
func stop_bgm():
	bgm_player.stop()

func set_bgm_volume(volume_db: float):
	bgm_player.volume_db = volume_db

# ==========================================
# 🧹 重置/停止逻辑
# ==========================================
func reset_data():
	# 停止当前的背景音乐
	# 这样在加载界面时，耳朵会清净下来，等待下一局的音乐开启
	if bgm_player and bgm_player.is_playing():
		bgm_player.stop()
		
	print("【音频管家】BGM 已停止，等待下一局开始信号...")
