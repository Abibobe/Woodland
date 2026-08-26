class_name DayCycle
extends Node


signal display_changed(day: int, phase: String)
signal day_ended(day: int)
signal survival_period_completed


@export_range(10.0, 600.0, 5.0) var day_duration: float = 90.0
@export_range(1, 30) var total_days: int = 7


const PHASE_NAMES := [
	"Morning",
	"Afternoon",
	"Evening",
	"Night"
]


var current_day: int = 1
var elapsed_time: float = 0.0
var running: bool = true
var previous_phase: String = ""


func _ready() -> void:
	_update_display(true)


func _process(delta: float) -> void:
	if not running:
		return

	elapsed_time += delta

	if elapsed_time >= day_duration:
		elapsed_time -= day_duration
		_finish_current_day()

	if running:
		_update_display()


func get_phase_name() -> String:
	var day_progress := elapsed_time / day_duration
	var phase_index := floori(day_progress * PHASE_NAMES.size())

	phase_index = clampi(
		phase_index,
		0,
		PHASE_NAMES.size() - 1
	)

	return PHASE_NAMES[phase_index]


func set_running(value: bool) -> void:
	running = value


func _finish_current_day() -> void:
	day_ended.emit(current_day)

	if current_day >= total_days:
		running = false
		survival_period_completed.emit()
		return

	current_day += 1
	_update_display(true)


func _update_display(force_update: bool = false) -> void:
	var current_phase := get_phase_name()

	if not force_update and current_phase == previous_phase:
		return

	previous_phase = current_phase

	display_changed.emit(
		current_day,
		current_phase
	)
