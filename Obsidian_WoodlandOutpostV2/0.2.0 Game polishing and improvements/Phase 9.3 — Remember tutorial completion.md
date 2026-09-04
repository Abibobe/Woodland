
We’ll reuse the existing configuration file but introduce a separate key for the contextual tutorial.

### 1. Add the configuration constants

Near the top of `game_manager.gd`, add:

```
const TUTORIAL_CONFIG_PATH := (
	"user://tutorial_settings.cfg"
)

const TUTORIAL_CONFIG_SECTION := "tutorial"

const CONTEXTUAL_TUTORIAL_COMPLETED_KEY := (
	"contextual_tutorial_completed"
)
```

This does not interfere with the existing `controls_dismissed` key.

### 2. Check saved completion before starting

Replace `_on_main_menu_visibility_changed()` with:

```
func _on_main_menu_visibility_changed() -> void:
	if main_menu.visible:
		return

	if not tutorial_enabled:
		tutorial_step = TutorialStep.COMPLETE
		hud.hide_tutorial_hint()
		return

	if tutorial_step != TutorialStep.WAITING:
		return

	if _was_contextual_tutorial_completed():
		tutorial_step = TutorialStep.COMPLETE
		hud.hide_tutorial_hint()
		return

	tutorial_start_position = player.global_position

	_set_tutorial_step(
		TutorialStep.MOVEMENT
	)
```

### 3. Save when the tutorial finishes

Inside `_set_tutorial_step()`, update the final case:

```
TutorialStep.COMPLETE:
	hud.hide_tutorial_hint()
	_save_contextual_tutorial_completed()
```

### 4. Add the loading function

```
func _was_contextual_tutorial_completed() -> bool:
	var config := ConfigFile.new()

	if config.load(TUTORIAL_CONFIG_PATH) != OK:
		return false

	return bool(
		config.get_value(
			TUTORIAL_CONFIG_SECTION,
			CONTEXTUAL_TUTORIAL_COMPLETED_KEY,
			false
		)
	)
```

### 5. Add the saving function

```
func _save_contextual_tutorial_completed() -> void:
	var config := ConfigFile.new()

	config.load(TUTORIAL_CONFIG_PATH)

	config.set_value(
		TUTORIAL_CONFIG_SECTION,
		CONTEXTUAL_TUTORIAL_COMPLETED_KEY,
		true
	)

	var save_result := config.save(
		TUTORIAL_CONFIG_PATH
	)

	if save_result != OK:
		push_warning(
			"Could not save tutorial completion."
		)
```

Loading the existing file before saving preserves any other settings already stored inside it.

### Test

1. Complete the contextual tutorial and build the first camp stage.
2. Restart the game.
3. Press **Start Game** again.
4. No contextual tutorial should appear.
5. The regular **How To Play** menu should remain available.

To test the first-time experience again, close the running game and delete:

```
user://tutorial_settings.cfg
```

You can find it through Godot’s **Project → Open User Data Folder** option. This resets tutorial preferences only; it does not affect the project files.