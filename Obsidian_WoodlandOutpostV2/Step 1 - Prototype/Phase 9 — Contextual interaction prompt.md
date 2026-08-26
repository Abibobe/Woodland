Before adding the camp, let’s complete the interaction experience with a contextual prompt that appears only when needed.

The HUD will normally stay clean. When the player approaches a resource, a small message will appear:

```
E — Gather Wood
```

It disappears when the player moves away.

### 1. Add the prompt to the HUD

Open `hud.tscn`.

Add a `Label` directly beneath the root `HUD` and name it:

```
InteractionPrompt
```

The tree should be:

```
HUD
├── TopBar
└── InteractionPrompt
```

Set:

```
Text: E — Gather
Horizontal Alignment: Center
Vertical Alignment: Center
Visibility: Off
```

Under **Layout → Custom Minimum Size**, use:

```
X: 240
Y: 36
```

You can give it the same light font colour as the top bar.

Optionally, under **Theme Overrides → Styles → Normal**, create a `StyleBoxFlat` with:

```
Background Color: #17231DE6
Corner Radius: 6
```

### 2. Update `hud.gd`

Add this reference:

```
@onready var interaction_prompt: Label = $InteractionPrompt

@onready var top_bar: PanelContainer = $TopBar

func _ready() -> void:
	get_viewport().size_changed.connect(_apply_layout)
	call_deferred("_apply_layout")
```

Update `_apply_layout()` so it also positions the prompt:

```
func _apply_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size

	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = viewport_size

	top_bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top_bar.position = Vector2.ZERO
	top_bar.size = Vector2(viewport_size.x, 42.0)

	interaction_prompt.set_anchors_preset(
		Control.PRESET_TOP_LEFT
	)

	interaction_prompt.size = Vector2(240.0, 36.0)

	interaction_prompt.position = Vector2(
		(viewport_size.x - interaction_prompt.size.x) / 2.0,
		viewport_size.y - 58.0
	)
```

Add these two functions:

```
func show_interaction_prompt(text: String) -> void:
	interaction_prompt.text = text
	interaction_prompt.show()


func hide_interaction_prompt() -> void:
	interaction_prompt.hide()
```

### 3. Add a signal to `player_interaction.gd`

Below the existing `resource_collected` signal, add:

```
signal interaction_prompt_changed(text: String)
```

Update `interact()`:

```
func interact() -> void:
	var resource := _get_closest_resource()

	if resource == null:
		return

	var collected_amount := resource.gather(1)

	if collected_amount <= 0:
		return

	resource_collected.emit(
		resource.resource_type,
		collected_amount
	)

	if resource.resource_amount <= 0:
		nearby_resources.erase(resource)

	_refresh_interaction_prompt()
```

Replace the two body-detection functions with:

```
func _on_body_entered(body: Node2D) -> void:
	if body is ResourceNode:
		if not nearby_resources.has(body):
			nearby_resources.append(body)

		_refresh_interaction_prompt()


func _on_body_exited(body: Node2D) -> void:
	if body is ResourceNode:
		nearby_resources.erase(body)
		_refresh_interaction_prompt()
```

Then add:

```
func _refresh_interaction_prompt() -> void:
	var resource := _get_closest_resource()

	if resource == null:
		interaction_prompt_changed.emit("")
		return

	interaction_prompt_changed.emit(
		"E — Gather %s" % resource.get_resource_name()
	)
```

### 4. Connect the prompt through `GameManager`

In `game_manager.gd`, add this connection inside `_ready()`:

```
	player_interaction.interaction_prompt_changed.connect(
		_on_interaction_prompt_changed
	)
```

Then add:

```
func _on_interaction_prompt_changed(text: String) -> void:
	if text.is_empty():
		hud.hide_interaction_prompt()
		return

	hud.show_interaction_prompt(text)
```

Your `_ready()` should now contain:

```
func _ready() -> void:
	player_interaction.resource_collected.connect(
		_on_resource_collected
	)

	player_interaction.interaction_prompt_changed.connect(
		_on_interaction_prompt_changed
	)

	inventory.resource_changed.connect(
		_on_inventory_resource_changed
	)

	_update_entire_hud()
```

Run the game and walk near a tree, rock, or bush. The prompt should appear at the bottom centre and disappear when you move away.

This preserves the clean interface rule: information is displayed only when it becomes useful.