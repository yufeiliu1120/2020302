extends Node2D

@onready var new_game_button = $"new game button/Button"
@onready var options_button = $"options button/Button"
@onready var credits_button = $"credits button/Button"
@onready var exit_button = $"exit button/Button"

# 盒子相关的节点
@onready var box_cover = $box/cover
@onready var text_panel = $"box/text label"
@onready var text_label = $"box/text label/MarginContainer/RichTextLabel"
@onready var banners_container = $box/banners 

# 变量准备
var initial_cover_pos: Vector2
var is_animating: bool = false
var is_box_open: bool = false 

# 🌟 阵营选择系统变量
var banner_initial_positions: Dictionary = {} 
var selected_banner: TextureRect = null        

# ==========================================
# 🗺️ 关卡场景映射字典
# 填入你做好的场景路径，未做的留空即可
# ==========================================
var level_scenes: Dictionary = {
	"exploror": "res://scene/main_scene/test.tscn", # ⚠️ 替换为你的真实探险家关卡路径
	"baron": "", 
	"druid": ""  
}

func _ready() -> void:
	# 强制让静态节点去读取 'zh' 这一列
	initial_cover_pos = box_cover.position
	text_label.hide()
	text_panel.hide()
	
	# 动态初始化阵营旗帜系统
	for banner in banners_container.get_children():
		if banner is TextureRect and "disabled" in banner: 
			banner_initial_positions[banner] = banner.position
			banner.pressed.connect(_on_faction_banner_pressed.bind(banner))
			
	_set_faction_buttons_enabled(false)
	
	# 绑定所有按钮
	new_game_button.pressed.connect(_on_new_game_button_pressed)
	options_button.pressed.connect(_on_options_button_pressed)
	credits_button.pressed.connect(_on_credits_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)


# ==========================================
# 🚩 阵营选择与动画逻辑
# ==========================================

func _on_faction_banner_pressed(clicked_banner: TextureRect):
	if is_animating: return
	
	if selected_banner == null:
		_select_banner(clicked_banner)
	elif selected_banner == clicked_banner:
		_start_game(clicked_banner)

func _select_banner(banner: TextureRect):
	is_animating = true
	selected_banner = banner
	
	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("card_draw") 
		
	var tween = create_tween().set_parallel(true)
	
	# 1. 选中的旗帜飞出
	tween.tween_property(banner, "position", Vector2(-322.127, -100.0), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 2. 其他旗帜渐隐并禁用
	for other_banner in banners_container.get_children():
		if other_banner is TextureRect and other_banner != banner:
			tween.tween_property(other_banner, "modulate:a", 0.0, 0.3)
			other_banner.disabled = true 
			
	tween.chain().tween_callback(func():
		is_animating = false
		_show_faction_info(banner)
	)

func _cancel_selection():
	if selected_banner == null or is_animating: return
	
	is_animating = true
	
	text_panel.hide()
	text_label.hide()
	
	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("paper_rustle") 
		
	var tween = create_tween().set_parallel(true)
	
	tween.tween_property(selected_banner, "position", banner_initial_positions[selected_banner], 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	for banner in banners_container.get_children():
		if banner is TextureRect and "disabled" in banner:
			tween.tween_property(banner, "modulate:a", 1.0, 0.3)
			banner.disabled = false
		
	tween.chain().tween_callback(func():
		is_animating = false
		selected_banner = null 
	)

func _show_faction_info(banner: TextureRect):
	var info_text = ""
	match banner.name:
		"exploror":
			info_text = tr("MAIN_MENU_DESC_EXPLOROR") + tr("PRESS_FLAG_TO_START")
		"baron":
			info_text = tr("MAIN_MENU_DESC_BARON") + tr("STILL_IN_DEVELOPMENT")
		"druid":
			info_text = tr("MAIN_MENU_DESC_DRUID") + tr("STILL_IN_DEVELOPMENT")
		_:
			info_text = "[center]未知阵营\n\n[color=gray]敬请期待[/color][/center]"
			
	text_label.text = info_text
	text_panel.show()
	text_label.show()

func _start_game(banner: TextureRect):
	var level_path = level_scenes.get(banner.name, "")
	
	if level_path != "" and ResourceLoader.exists(level_path):
		print("【系统】准备以阵营开始游戏：", banner.name)
		if AudioManager.has_method("play_sfx"):
			AudioManager.play_sfx("click") 
		
		SceneManager.goto_scene(level_path)
		
	else:
		# 阵营未开放逻辑
		print("【系统】阵营尚未实装：", banner.name)
		if AudioManager.has_method("play_sfx"):
			AudioManager.play_sfx("error") 
		
		text_label.text = "[center]该阵营仍在开发中\n\n[color=red]敬请期待！[/color][/center]"
		
		# 左右抖动特效
		var start_x = text_panel.position.x
		var tween = create_tween()
		tween.tween_property(text_panel, "position:x", start_x + 8, 0.05)
		tween.tween_property(text_panel, "position:x", start_x - 8, 0.05)
		tween.tween_property(text_panel, "position:x", start_x + 4, 0.05)
		tween.tween_property(text_panel, "position:x", start_x, 0.05)


# ==========================================
# 🖱️ 右键取消选择逻辑 (输入监听)
# ==========================================
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if is_box_open and selected_banner != null:
			_cancel_selection()


# ==========================================
# 📦 盒盖核心动画
# ==========================================
func open_box():
	if is_animating or is_box_open: return 
	
	is_animating = true
	is_box_open = true 
	
	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("box_slide") 

	var tween = create_tween().set_parallel(true)
	var target_y = initial_cover_pos.y - 800 
	tween.tween_property(box_cover, "position:y", target_y, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(box_cover, "modulate:a", 0.0, 0.8)
	
	tween.chain().tween_callback(func():
		is_animating = false
		box_cover.hide()
		_set_faction_buttons_enabled(true)
	)

func close_box():
	if is_animating or not is_box_open: return 
	
	if selected_banner != null:
		selected_banner.position = banner_initial_positions[selected_banner]
		for banner in banners_container.get_children():
			if banner is TextureRect:
				banner.modulate.a = 1.0
		selected_banner = null
		text_panel.hide()
		text_label.hide()
	
	is_animating = true
	is_box_open = false 
	
	box_cover.show()
	_set_faction_buttons_enabled(false)
	
	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("box_close") 

	var tween = create_tween().set_parallel(true)
	tween.tween_property(box_cover, "position:y", initial_cover_pos.y, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(box_cover, "modulate:a", 1.0, 0.6)
	
	tween.chain().tween_callback(func():
		is_animating = false
	)


# ==========================================
# 辅助与其他按钮响应
# ==========================================

func _set_faction_buttons_enabled(enabled: bool):
	for banner in banners_container.get_children():
		if banner is TextureRect and "disabled" in banner:
			banner.disabled = !enabled

func _on_new_game_button_pressed():
	open_box()

func _on_options_button_pressed():
	if is_box_open: close_box()

func _on_credits_button_pressed():
	if is_box_open: close_box()
	
func _on_exit_button_pressed():
	if is_box_open: close_box()
	get_tree().quit()
