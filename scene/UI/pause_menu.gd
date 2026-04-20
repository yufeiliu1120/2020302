extends TextureRect
@onready var resume_button = $VBoxContainer/Resume
@onready var settings_button = $VBoxContainer/Settings
@onready var restart_button = $VBoxContainer/Restart
@onready var main_menu_button = $"VBoxContainer/Return to main menu"
@onready var exit_button = $"VBoxContainer/Exit game"
@onready var panelanimator = $PanelAnimator
@onready var objective_panel = $PanelContainer  #用来挂载当前目标显示的节点。

func _ready() -> void:
	hide()
	get_objective()
	
func open_menu():
	panelanimator.open_panel()
	get_tree().paused = true

func close_menu():
	panelanimator.close_panel()
	get_tree().paused = false

func get_objective():
	if SceneManager.current_scene == "res://scene/main_scene/test.tscn":
		var objective_scene = load("res://scene/UI/explororer's_objective.tscn").instantiate()
		objective_panel.add_child(objective_scene)

func _on_resume_pressed() -> void:
	close_menu()

func _on_restart_pressed() -> void:
	SceneManager.restart_scene()


func _on_return_to_main_menu_pressed() -> void:
	SceneManager.goto_scene("res://scene/main_menu/node_2d.tscn")


func _on_exit_game_pressed() -> void:
	get_tree().quit()
