extends Control

# ==========================================
# ⚙️ 配置：我们要去哪个场景？
# ==========================================
# 在右侧 Inspector 面板里，把你的 test.tscn 的路径填在这里！
# 默认暂定为你的主场景路径
@export_file("*.tscn") var next_scene_path: String = "res://scene/main_scene/test.tscn" 

@onready var progress_bar = $ProgressBar
@onready var status_label = $Label

# Godot 用来接收后台加载进度的数组（必须是数组类型，虽然里面只有一个元素）
var progress: Array = []

func _ready():
	# 初始化 UI
	progress_bar.value = 0
	status_label.text = "Loading... 0%"
	get_tree().call_group("Resettable", "reset_data")
	# ==========================================
	# 🚀 核心指令：告诉引擎在后台开启新线程加载场景！
	# ==========================================
	var request_error = ResourceLoader.load_threaded_request(next_scene_path)
	
	if request_error != OK:
		status_label.text = "Error: Failed to request loading!"
		set_process(false) # 停止更新

func _process(_delta):
	# ==========================================
	# 🔍 每一帧去问引擎：后台加载到百分之几了？
	# ==========================================
	var status = ResourceLoader.load_threaded_get_status(next_scene_path, progress)
	
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		# progress[0] 返回的是 0.0 到 1.0 之间的小数
		var percentage = progress[0] * 100.0 
		
		# 平滑更新 UI
		progress_bar.value = percentage
		status_label.text = "Loading... %d%%" % percentage
		
	elif status == ResourceLoader.THREAD_LOAD_LOADED:
		# ==========================================
		# 🎉 加载完成！
		# ==========================================
		progress_bar.value = 100
		status_label.text = "Welcome to the Island!"
		set_process(false) # 关掉 _process，防止重复触发
		
		# 稍微延迟 0.1 秒切换，让玩家能看清 100% 的瞬间（视觉体验更好）
		await get_tree().create_timer(0.1).timeout
		
		# 取出加载好的“打包场景 (PackedScene)”，并执行切换！
		var next_scene = ResourceLoader.load_threaded_get(next_scene_path)
		get_tree().change_scene_to_packed(next_scene)
		
	elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		status_label.text = "Error: Failed to load scene."
		set_process(false)
