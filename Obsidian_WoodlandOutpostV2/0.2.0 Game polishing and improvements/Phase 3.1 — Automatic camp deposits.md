
We’ll make entering the camp’s interaction range begin a one-second deposit. Leaving early cancels it.

### 1. Add proximity signals

In `player_interaction.gd`, add:

```
signal interaction_target_entered(
	target: InteractionTarget
)

signal interaction_target_exited(
	target: InteractionTarget
)
```

Update `_on_body_entered()`:

```
func _on_body_entered(body: Node2D) -> void:
	if body is InteractionTarget:
		if not nearby_targets.has(body):
			nearby_targets.append(body)

		_refresh_interaction_prompt()

		interaction_target_entered.emit(
			body
		)
```

Update `_on_body_exited()`:

```
func _on_body_exited(body: Node2D) -> void:
	if body is InteractionTarget:
		nearby_targets.erase(body)

		interaction_target_exited.emit(
			body
		)

		_refresh_interaction_prompt()
```

Add:

```
func has_target(
	target: InteractionTarget
) -> bool:
	return (
		is_instance_valid(target)
		and nearby_targets.has(target)
	)
```

## 2. Add the deposit timer

Under the root `Game` node, add a `Timer`:

```
Game
├── ResourceInventory
├── PlayerBackpack
├── DepositTimer
├── DayCycle
└── Interface
```

Configure:

```
Wait Time: 1.0
One Shot: On
Autostart: Off
```

## 3. Add GameManager references

In `game_manager.gd`:

```
@onready var deposit_timer: Timer = $DepositTimer
```

Add:

```
var deposit_camp: Camp
```

In `_ready()`, connect:

```
player_interaction.interaction_target_entered.connect(
	_on_interaction_target_entered
)

player_interaction.interaction_target_exited.connect(
	_on_interaction_target_exited
)

deposit_timer.timeout.connect(
	_on_deposit_timer_timeout
)
```

## 4. Start and cancel depositing

Add:

```
func _on_interaction_target_entered(
	target: InteractionTarget
) -> void:
	if game_finished:
		return

	if not target is Camp:
		return

	if backpack.is_empty():
		return

	deposit_camp = target as Camp
	deposit_timer.start()

	hud.show_interaction_prompt(
		"Depositing supplies..."
	)


func _on_interaction_target_exited(
	target: InteractionTarget
) -> void:
	if target != deposit_camp:
		return

	if not deposit_timer.is_stopped():
		deposit_timer.stop()

	deposit_camp = null

	hud.show_resource_gain(
		"Deposit cancelled",
		_get_player_screen_position()
	)
```

## 5. Complete the transfer

Add:

```
func _on_deposit_timer_timeout() -> void:
	if deposit_camp == null:
		return

	if not is_instance_valid(deposit_camp):
		deposit_camp = null
		return

	if not player_interaction.has_target(
		deposit_camp
	):
		deposit_camp = null
		return

	if backpack.is_empty():
		deposit_camp = null
		return

	var delivered_resources := backpack.take_all()

	for resource_type in delivered_resources:
		var delivered_amount := int(
			delivered_resources[resource_type]
		)

		if delivered_amount <= 0:
			continue

		inventory.add_resource(
			int(resource_type),
			delivered_amount
		)

	var summary := _format_delivery_summary(
		delivered_resources
	)

	hud.show_resource_gain(
		summary,
		_get_player_screen_position()
	)

	if active_camp != null:
		_refresh_camp_menu()

	deposit_camp = null
	player_interaction.refresh_prompt()
```

## 6. Add summary helpers

Add:

```
func _format_delivery_summary(
	delivered_resources: Dictionary
) -> String:
	var parts := PackedStringArray()

	for resource_type in delivered_resources:
		var amount := int(
			delivered_resources[resource_type]
		)

		if amount <= 0:
			continue

		var resource_name := (
			ResourceTypes.get_display_name(
				int(resource_type)
			)
		)

		parts.append(
			"+%d %s" % [
				amount,
				resource_name
			]
		)

	if parts.is_empty():
		return "No supplies delivered"

	return "Delivered: %s" % ", ".join(parts)


func _get_player_screen_position() -> Vector2:
	return (
		get_viewport().get_canvas_transform()
		* player.global_position
	)
```

You can simplify the existing resource-gain and backpack-full code later by using this shared screen-position helper.

## Test

1. Gather resources.
2. Confirm only backpack weight increases.
3. Approach the camp.
4. Confirm `Depositing supplies...` appears.
5. Walk away before one second: the backpack should remain unchanged.
6. Stay near camp: backpack weight should return to `0/12`.
7. Stored-resource counters should increase.
8. Construction should now recognize the deposited resources.

This completes the first strategic loop:

```
Gather → Fill backpack → Return → Deposit → Build
```

The next step will replace the temporary single-line delivery message with the planned pixel-style multi-line summary and counter animations.