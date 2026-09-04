Now we can add the seven-day clock as an independent system. The HUD will show a simple phase instead of a busy digital clock:

### 1. Add the day-cycle node

In `game.tscn`, add a regular `Node` beneath `Game`:

```
Game
├── World
├── Actors
├── ResourceInventory
├── DayCycle
└── Interface
```

Attach:

```
res://scripts/game/day_cycle.gd
```

### 2. Add the day-cycle code

```
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
```

### 3. Update the HUD day label

In `hud.gd`, replace the existing `set_day()` with:

```
func set_day(
	day: int,
	phase: String
) -> void:
	day_label.text = "Day %s · %s" % [
		day,
		phase
	]
```

### 4. Connect it in `game_manager.gd`

Add:

```
@onready var day_cycle: DayCycle = $DayCycle
```

Inside `_ready()`, add:

```
	day_cycle.display_changed.connect(
		_on_time_display_changed
	)

	day_cycle.day_ended.connect(
		_on_day_ended
	)

	day_cycle.survival_period_completed.connect(
		_on_survival_period_completed
	)

	_on_time_display_changed(
		day_cycle.current_day,
		day_cycle.get_phase_name()
	)
```

Then add:

```
func _on_time_display_changed(
	day: int,
	phase: String
) -> void:
	hud.set_day(day, phase)


func _on_day_ended(day: int) -> void:
	print("Day %s ended." % day)


func _on_survival_period_completed() -> void:
	print("The seventh day has ended.")
```

### 5. Pause time while the camp menu is open

At the end of `_open_camp_menu()`, add:

```
	day_cycle.set_running(false)
```

At the end of `_close_camp_menu()`, add:

```
	day_cycle.set_running(true)
```

Now time won’t advance while the player is using the menu.

For testing, temporarily set `DayCycle → Day Duration` to `20` seconds in the Inspector. Once verified, return it to approximately `90`.

The HUD should progress through:

```
Day 1 · Morning
Day 1 · Afternoon
Day 1 · Evening
Day 1 · Night
Day 2 · Morning
```

Next, we can make each completed day consume food and introduce the first actual survival consequence.