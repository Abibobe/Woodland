Before enlarging the world, let’s add the final strategic feedback from the camp system: notify the player when a delivery makes the next construction stage affordable.

### 1. Track the affordability state

In `game_manager.gd`, near the other state variables, add:

```
var next_camp_stage_was_affordable := false
```

### 2. Add the affordability check

Add this function beneath `_can_afford()`:

```
func _check_next_camp_stage_affordability() -> void:
	if camp.current_stage == Camp.CampStage.CABIN:
		next_camp_stage_was_affordable = false
		return

	var costs := camp.get_next_stage_cost()
	var is_now_affordable := _can_afford(costs)

	if (
		is_now_affordable
		and not next_camp_stage_was_affordable
	):
		var next_stage_name := (
			camp.get_next_stage_name()
		)

		hud.show_resource_gain(
			"%s ready to build!" % next_stage_name,
			_get_player_screen_position()
		)

	next_camp_stage_was_affordable = is_now_affordable
```

### 3. Check after depositing resources

In `_on_deposit_timer_timeout()`, immediately after:

```
hud.show_delivery_summary(
	delivered_resources
)
```

add:

```
_check_next_camp_stage_affordability()
```

### 4. Reset the check after construction

In `_on_camp_build_requested()`, immediately after:

```
active_camp.advance_construction()
```

add:

```
next_camp_stage_was_affordable = false
_check_next_camp_stage_affordability()
```

This recalculates affordability for the new construction stage.

### Test it

Deposit resources in smaller batches:

- An insufficient delivery should show only the delivery summary.
- The delivery that completes the cost should also show:

```
Campfire ready to build!
```

- Additional deliveries should not repeat the notification.
- After building, the system starts tracking affordability for the next stage.

After this, we’ll be ready for **Phase 6: enlarging the procedural world and distributing resources by distance from camp**. For that step, I’ll need the latest `world_generator.gd`, `resource_spawner.gd`, and the current camera setup.


### Minor Fix: have a better highlight for the "Ready to build" message

Absolutely. This is a milestone, so it deserves a dedicated banner instead of the small floating-resource message.

## Create a milestone banner

Under the `HUD` node, add:

```
MilestonePopup (PanelContainer)
└── MarginContainer
    └── MilestoneLabel (Label)
```

Configure `MilestonePopup`:

```
Visible: Off
Custom Minimum Size: 460 × 70
Mouse → Filter: Ignore
Ordering → Z Index: 30
```

Configure `MilestoneLabel`:

```
Horizontal Alignment: Center
Vertical Alignment: Center
Theme Overrides → Font Sizes → Font Size: 20
Theme Overrides → Colors → Font Color: #f2d479
```

Give `MarginContainer` approximately `10` pixels of margin on every side.

## Update `hud.gd`

Add the references:

```
@onready var milestone_popup: PanelContainer = (
	$MilestonePopup
)

@onready var milestone_label: Label = (
	$MilestonePopup/MarginContainer/MilestoneLabel
)
```

Add the tween variable:

```
var milestone_tween: Tween
```

In `_ready()`, add:

```
milestone_popup.hide()
```

At the end of `_apply_layout()`, add:

```
milestone_popup.size = Vector2(
	460.0,
	70.0
)

milestone_popup.position = Vector2(
	(viewport_size.x - milestone_popup.size.x) / 2.0,
	76.0
)

milestone_popup.pivot_offset = (
	milestone_popup.size / 2.0
)
```

Now add:

```
func show_milestone(message: String) -> void:
	if milestone_tween != null:
		milestone_tween.kill()

	milestone_label.text = message

	milestone_popup.modulate.a = 0.0
	milestone_popup.scale = Vector2(0.92, 0.92)
	milestone_popup.show()

	milestone_tween = create_tween()

	milestone_tween.set_parallel(true)

	milestone_tween.tween_property(
		milestone_popup,
		"modulate:a",
		1.0,
		0.2
	)

	milestone_tween.tween_property(
		milestone_popup,
		"scale",
		Vector2.ONE,
		0.2
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	milestone_tween.set_parallel(false)

	milestone_tween.tween_interval(3.5)

	milestone_tween.tween_property(
		milestone_popup,
		"modulate:a",
		0.0,
		0.4
	)

	milestone_tween.tween_callback(
		milestone_popup.hide
	)
```

The notification will remain clearly visible for approximately four seconds.

## Update `game_manager.gd`

Inside `_check_next_camp_stage_affordability()`, replace:

```
hud.show_resource_gain(
	"%s ready to build!" % next_stage_name,
	_get_player_screen_position()
)
```

with:

```
hud.show_milestone(
	"NEXT BUILD AVAILABLE\n%s — RETURN TO CAMP"
	% next_stage_name.to_upper()
)
```

The result will be a prominent golden banner near the top of the screen:

```
NEXT BUILD AVAILABLE
CAMPFIRE — RETURN TO CAMP
```

It remains separate from delivery summaries, interaction prompts, and resource-gain messages, so none of those systems will overwrite it.