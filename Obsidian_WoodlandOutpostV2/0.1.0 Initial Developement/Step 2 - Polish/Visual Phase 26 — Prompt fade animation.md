Let’s make the new interaction prompt appear and disappear smoothly.
### 1. Add a tween variable

In `hud.gd`, beneath the `@onready` variables, add:

```
var interaction_prompt_tween: Tween
```

### 2. Replace `show_interaction_prompt()`

```
func show_interaction_prompt(text: String) -> void:
	var clean_text := text

	if clean_text.begins_with("Press E to "):
		clean_text = clean_text.trim_prefix(
			"Press E to "
		)

	interaction_prompt_label.text = (
		clean_text.capitalize()
	)

	if interaction_prompt_tween != null:
		interaction_prompt_tween.kill()

	interaction_prompt.show()
	interaction_prompt.modulate.a = 0.0

	interaction_prompt_tween = create_tween()

	interaction_prompt_tween.tween_property(
		interaction_prompt,
		"modulate:a",
		1.0,
		0.12
	)
```

### 3. Replace `hide_interaction_prompt()`

```
func hide_interaction_prompt() -> void:
	if not interaction_prompt.visible:
		return

	if interaction_prompt_tween != null:
		interaction_prompt_tween.kill()

	interaction_prompt_tween = create_tween()

	interaction_prompt_tween.tween_property(
		interaction_prompt,
		"modulate:a",
		0.0,
		0.1
	)

	interaction_prompt_tween.tween_callback(
		interaction_prompt.hide
	)
```

### 4. Ensure the initial state is clean

At the end of `_ready()`, add:

```
interaction_prompt.modulate.a = 0.0
interaction_prompt.hide()
```

The prompt will now fade in when approaching a target and fade out after leaving it. If the closest target changes, the previous animation is safely cancelled before the new prompt appears.