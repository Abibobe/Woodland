The tutorial will advance through five short steps:

1. **Movement**  
    “Use WASD or the arrow keys to explore.”
2. **Gathering**  
    “Approach a resource and hold E to gather.”
3. **Backpack**  
    After collecting the first item:  
    “Resources have weight. Your backpack can carry 12 kg.”
4. **Returning to camp**  
    When the backpack becomes sufficiently loaded:  
    “Return to camp to deposit your resources.”
5. **Construction objective**  
    After the first delivery:  
    “Gather the required materials and complete the cabin before winter.”

Each message will disappear after completion—not merely after a timer—and completed instructions won’t return during that playthrough.

I confirmed the current behavior:

- The main menu pauses the game.
- `TutorialPrompt` automatically opens after the first press of **Start Game**.
- It pauses gameplay again and permanently remembers dismissal.
- The **How To Play** button uses a separate `HelpCenter`.
- `PauseMenu` also has a reference to `TutorialPrompt`.

We’ll therefore preserve `TutorialPrompt` for manual access, but stop it from automatically appearing. The new contextual hints will live in the HUD.

## Phase 9.1 — Contextual tutorial panel

### 1. Disable the old automatic popup

In `tutorial_prompt.gd`, replace `_ready()` with:

```
func _ready() -> void:
	hide()

	got_it_button.pressed.connect(
		_dismiss_prompt
	)
```

Remove these parts from `_ready()`:

```
main_menu.visibility_changed.connect(
	_on_main_menu_visibility_changed
)

call_deferred(
	"_check_for_first_game"
)
```

Do not delete the rest of `tutorial_prompt.gd`. Its `open_prompt()` function remains available if `PauseMenu` uses it.

### 2. Add the new HUD nodes

Under `HUD`, add:

```
HUD
├── ...
└── TutorialHint (PanelContainer)
    └── MarginContainer
        └── TutorialLabel (Label)
```

Configure `TutorialHint`:

```
Visible: Off
Custom Minimum Size: 380 × 54
Mouse Filter: Ignore
Z Index: 25
```

Configure `TutorialLabel`:

```
Horizontal Alignment: Center
Vertical Alignment: Center
Autowrap Mode: Word Smart
Font Size: 13
Font Color: #f2d479
Outline Color: #17231d
Outline Size: 3
```

Give the `MarginContainer` approximately 10 pixels of margin.

### 3. Reference it in `hud.gd`

Add:

```
@onready var tutorial_hint: PanelContainer = (
	$TutorialHint
)

@onready var tutorial_label: Label = (
	$TutorialHint/MarginContainer/TutorialLabel
)
```

Add the tween variable:

```
var tutorial_hint_tween: Tween
```

In `_ready()`, add:

```
tutorial_hint.hide()
```

### 4. Position it

At the end of `_apply_layout()`, add:

```
tutorial_hint.size = Vector2(
	380.0,
	54.0
)

tutorial_hint.position = Vector2(
	(viewport_size.x - tutorial_hint.size.x) / 2.0,
	62.0
)

tutorial_hint.pivot_offset = (
	tutorial_hint.size / 2.0
)
```

This places it beneath the top bar and above the existing milestone banner area.

### 5. Add the display function

```
func show_tutorial_hint(message: String) -> void:
	if tutorial_hint_tween != null:
		tutorial_hint_tween.kill()

	tutorial_label.text = message

	if tutorial_hint.visible:
		tutorial_hint.modulate.a = 1.0
		tutorial_hint.scale = Vector2.ONE
		return

	tutorial_hint.modulate.a = 0.0
	tutorial_hint.scale = Vector2(0.94, 0.94)
	tutorial_hint.show()

	tutorial_hint_tween = create_tween()
	tutorial_hint_tween.set_parallel(true)

	tutorial_hint_tween.tween_property(
		tutorial_hint,
		"modulate:a",
		1.0,
		0.18
	)

	tutorial_hint_tween.tween_property(
		tutorial_hint,
		"scale",
		Vector2.ONE,
		0.2
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)
```

Unlike the milestone notification, this has no timer. It stays visible until the player completes the relevant action.

### 6. Add the hide function

```
func hide_tutorial_hint() -> void:
	if not tutorial_hint.visible:
		return

	if tutorial_hint_tween != null:
		tutorial_hint_tween.kill()

	tutorial_hint_tween = create_tween()

	tutorial_hint_tween.tween_property(
		tutorial_hint,
		"modulate:a",
		0.0,
		0.15
	)

	tutorial_hint_tween.tween_callback(
		_finish_hiding_tutorial_hint
	)


func _finish_hiding_tutorial_hint() -> void:
	tutorial_hint.hide()
	tutorial_hint.modulate.a = 1.0
	tutorial_hint.scale = Vector2.ONE
```

After this step, the old blocking tutorial will no longer appear automatically, and the HUD will be ready for the event-driven tutorial sequence. Next we’ll add the state machine to `game_manager.gd` and begin with movement detection.