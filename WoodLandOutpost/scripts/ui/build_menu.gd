class_name BuildMenu
extends Control


signal campfire_requested
signal close_requested


@onready var background: ColorRect = $Background

@onready var panel: PanelContainer = (
	$CenterContainer/Panel
)

@onready var main_camp_button: Button = (
	$CenterContainer/Panel/MarginContainer/
	Content/MainCampButton
)

@onready var campfire_button: Button = (
	$CenterContainer/Panel/MarginContainer/
	Content/CampfireButton
)

@onready var rabbit_trap_button: Button = (
	$CenterContainer/Panel/MarginContainer/
	Content/RabbitTrapButton
)

@onready var close_button: Button = (
	$CenterContainer/Panel/MarginContainer/
	Content/CloseButton
)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	campfire_button.pressed.connect(
		_on_campfire_pressed
	)

	close_button.pressed.connect(
		_on_close_pressed
	)

	main_camp_button.disabled = true
	rabbit_trap_button.disabled = true

	hide()


func open_menu() -> void:
	main_camp_button.text = (
		"MAIN CAMP — ALREADY ESTABLISHED"
	)

	campfire_button.text = (
		"CAMPFIRE\nCost: 3 Wood"
	)

	rabbit_trap_button.text = (
		"RABBIT TRAP — LOCKED"
	)

	show()
	campfire_button.grab_focus()


func close_menu() -> void:
	hide()


func _on_campfire_pressed() -> void:
	campfire_requested.emit()


func _on_close_pressed() -> void:
	close_requested.emit()
