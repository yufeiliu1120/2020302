extends SubViewportContainer

func _ready() -> void:
	$SubViewport.world_2d = get_tree().root.world_2d
	$SubViewport/Camera2D.global_position = Vector2(480,45)
