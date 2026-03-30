extends Control # 或者 PanelContainer, 根据你的实际根节点

signal option_selected

@onready var label = $text # 假设你按钮下有个 Label 节点叫 Label


func _on_texture_button_pressed() -> void:
	option_selected.emit()
