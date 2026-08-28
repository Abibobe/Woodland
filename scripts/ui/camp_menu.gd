class_name CampMenu
extends Control


signal build_requested
signal close_requested


@onready var panel: PanelContainer = $Panel

@onready var title_label: Label = (
	$Panel/MarginContainer/Content/TitleLabel
)

@onready var cost_label: Label = (
	$Panel/MarginContainer/Content/CostRow/CostLabel
)

@onready var message_label: Label = (
	$Panel/MarginContainer/Content/MessageLabel
)

@onready var build_button: Button = (
	$Panel/MarginContainer/Content/Buttons/BuildButton
)

@onready var close_button: Button = (
	$Panel/MarginContainer/Content/Buttons/CloseButton
)


func _ready() -> void:
	build_button.pressed.connect(
		_on_build_button_pressed
	)

	close_button.pressed.connect(
		_on_close_button_pressed
	)

	get_viewport().size_changed.connect(
		_apply_layout
	)

	call_deferred("_apply_layout")


func open_menu(
	next_stage_name: String,
	cost_text: String,
	can_build: bool,
	is_complete: bool
) -> void:
	message_label.text = ""

	if is_complete:
		title_label.text = "Cabin complete"
		cost_label.text = "Ready for winter"
		build_button.hide()
	else:
		title_label.text = "Build %s" % next_stage_name
		cost_label.text = "Cost: %s" % cost_text
		
		build_button.show()
		build_button.disabled = not can_build
		if build_button.disabled:
			cost_label.modulate = Color("#e06c68")
		else:
			cost_label.modulate = Color("#f2e7c9")

	show()
	_apply_layout()


func close_menu() -> void:
	hide()


func show_message(text: String) -> void:
	message_label.text = text


func _apply_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size

	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = viewport_size

	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.size = Vector2(360.0, 140.0)

	panel.position = Vector2(
		(viewport_size.x - panel.size.x) / 2.0,
		viewport_size.y - panel.size.y - 24.0
	)


func _on_build_button_pressed() -> void:
	build_requested.emit()


func _on_close_button_pressed() -> void:
	close_requested.emit()
