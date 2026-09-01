### 1. Add the statistics label

Inside the result panel’s `Content` container, add a `Label` between `MessageLabel` and `RestartButton`:

```
Content
├── TitleLabel
├── MessageLabel
├── StatsLabel
└── RestartButton
```

Configure `StatsLabel`:

```
Horizontal Alignment: Center
Vertical Alignment: Center
Font Size: 11
Font Color: #b9c8b5
Custom Minimum Size Y: 54
```

### 2. Add the reference

In `result_screen.gd`:

```
@onready var stats_label: Label = (
	$Panel/MarginContainer/Content/StatsLabel
)
```

### 3. Update `show_result()`

Replace it with:

```
func show_result(
	title: String,
	message: String,
	stats: Dictionary = {}
) -> void:
	title_label.text = title
	message_label.text = message
	stats_label.text = _format_stats(stats)

	match title:
		"Victory":
			title_label.add_theme_color_override(
				"font_color",
				Color("#f2d479")
			)

		"Defeat":
			title_label.add_theme_color_override(
				"font_color",
				Color("#e06c68")
			)

		_:
			title_label.add_theme_color_override(
				"font_color",
				Color("#f2e7c9")
			)

	show()
	_apply_layout()
	_play_result_animation()
```

Add:

```
func _format_stats(stats: Dictionary) -> String:
	if stats.is_empty():
		return ""

	return (
		"Day reached: %d\n"
		+ "Wood %d  |  Stone %d  |  Food %d\n"
		+ "Camp stage: %s"
	) % [
		int(stats.get("day", 1)),
		int(stats.get("wood", 0)),
		int(stats.get("stone", 0)),
		int(stats.get("food", 0)),
		String(stats.get("camp_stage", "Site"))
	]
```

### 4. Increase the result-panel height

Inside `_apply_layout()`, change:

```
panel.size = Vector2(420.0, 190.0)
```

to:

```
panel.size = Vector2(420.0, 250.0)
```

### 5. Pass the statistics from `GameManager`

In `_finish_game()`, before `result_screen.show_result()`, add:

```
var camp_stage_name := String(
	Camp.CampStage.keys()[
		int(camp.current_stage)
	]
).capitalize()

var final_stats := {
	"day": day_cycle.current_day,
	"wood": inventory.get_amount(
		ResourceTypes.Type.WOOD
	),
	"stone": inventory.get_amount(
		ResourceTypes.Type.STONE
	),
	"food": inventory.get_amount(
		ResourceTypes.Type.FOOD
	),
	"camp_stage": camp_stage_name
}
```

Then replace:

```
result_screen.show_result(
	title,
	message
)
```

with:

```
result_screen.show_result(
	title,
	message,
	final_stats
)
```

The result screen will now summarize exactly how far the player progressed, regardless of whether the run ended in victory or defeat.