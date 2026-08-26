class_name ResultScreen
extends Control


signal restart_requested


@onready var dimmer: ColorRect = $Dimmer
@onready var panel: PanelContainer = $Panel

@onready var title_label: Label = (
	$Panel/MarginContainer/Content/TitleLabel
)

@onready var message_label: Label = (
	$Panel/MarginContainer/Content/MessageLabel
)

@onready var restart_button: Button = (
	$Panel/MarginContainer/Content/RestartButton
)


func _ready() -> void:
	restart_button.pressed.connect(
		_on_restart_button_pressed
	)

	get_viewport().size_changed.connect(
		_apply_layout
	)

	call_deferred("_apply_layout")


func show_result(
	title: String,
	message: String
) -> void:
	title_label.text = title
	message_label.text = message

	show()
	_apply_layout()


func _apply_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size

	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = viewport_size

	dimmer.set_anchors_preset(Control.PRESET_TOP_LEFT)
	dimmer.position = Vector2.ZERO
	dimmer.size = viewport_size

	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.size = Vector2(400.0, 180.0)

	panel.position = Vector2(
		(viewport_size.x - panel.size.x) / 2.0,
		(viewport_size.y - panel.size.y) / 2.0
	)


func _on_restart_button_pressed() -> void:
	restart_requested.emit()
