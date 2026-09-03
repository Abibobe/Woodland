The core gathering mechanic is now working. Next we’ll improve the instruction shown to the player so the new control is immediately clear.

In `resource_node.gd`, replace:

```
func get_interaction_text() -> String:
	return "E — Gather %s" % get_resource_name()
```

with:

```
func get_interaction_text() -> String:
	var progress_percentage := roundi(
		get_gathering_ratio() * 100.0
	)

	if progress_percentage > 0:
		return "Hold E — Gather %s (%d%%)" % [
			get_resource_name(),
			progress_percentage
		]

	return "Hold E — Gather %s" % get_resource_name()
```

Now an interrupted resource will communicate that its work was preserved:

```
Hold E — Gather Wood (47%)
```

### Keep the prompt updated

In `player_interaction.gd`, after:

```
active_gathering_resource.set_gathering_active(true)
```

inside `_process()`, add:

```
interaction_prompt_changed.emit(
	active_gathering_resource.get_interaction_text()
)
```

That section should become:

```
if player.velocity.length_squared() > 0.0:
	active_gathering_resource.set_gathering_active(
		false
	)
	return

active_gathering_resource.set_gathering_active(true)

interaction_prompt_changed.emit(
	active_gathering_resource.get_interaction_text()
)
```

The percentage will now increase while the player holds `E`, remain saved after interruption, and return in the prompt when the same resource is selected again.