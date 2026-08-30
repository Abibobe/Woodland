
The next useful polish is highlighting the resource currently targeted by the player. To connect it safely,
- A small pixel-style marker beneath the targeted tree, rock, or bush.
- Automatic removal when the player moves away.
- No changes to gathering, collisions, or resource logic.

### 1. Update `resource_node.gd`

Add these variables near the top:

```
const HIGHLIGHT_COLOR := Color("#f2d479")

var is_highlighted: bool = false
```

Add this public function:

```
func set_highlighted(value: bool) -> void:
	if is_highlighted == value:
		return

	is_highlighted = value
	queue_redraw()
```

At the beginning of your existing `_draw()`, use:

```
func _draw() -> void:
	_draw_shadow()

	if is_highlighted:
		_draw_interaction_highlight()

	# Keep your existing resource drawing below.
```

Add the highlight drawing function:

```
func _draw_interaction_highlight() -> void:
	# Left bracket
	draw_rect(
		Rect2(-19.0, 8.0, 7.0, 2.0),
		HIGHLIGHT_COLOR
	)

	draw_rect(
		Rect2(-19.0, 4.0, 2.0, 6.0),
		HIGHLIGHT_COLOR
	)

	# Right bracket
	draw_rect(
		Rect2(12.0, 8.0, 7.0, 2.0),
		HIGHLIGHT_COLOR
	)

	draw_rect(
		Rect2(17.0, 4.0, 2.0, 6.0),
		HIGHLIGHT_COLOR
	)
```

This creates small golden selection brackets around the resource’s base.

## 2. Update `player_interaction.gd`

Below `nearby_targets`, add:

```
var highlighted_target: InteractionTarget = null
```

Replace `_refresh_interaction_prompt()` with:

```
func _refresh_interaction_prompt() -> void:
	var target := _get_closest_target()

	_set_highlighted_target(target)

	if target == null:
		interaction_prompt_changed.emit("")
		return

	interaction_prompt_changed.emit(
		target.get_interaction_text()
	)
```

Then add:

```
func _set_highlighted_target(
	new_target: InteractionTarget
) -> void:
	if highlighted_target == new_target:
		return

	if (
		is_instance_valid(highlighted_target)
		and highlighted_target.has_method("set_highlighted")
	):
		highlighted_target.set_highlighted(false)

	highlighted_target = new_target

	if (
		is_instance_valid(highlighted_target)
		and highlighted_target.has_method("set_highlighted")
	):
		highlighted_target.set_highlighted(true)
```

Using `has_method()` is intentional:

- Resources implement `set_highlighted()` and receive the marker.
- The camp remains a valid interaction target but does not need that method.
- Switching targets removes the previous highlight automatically.
- Leaving interaction range clears it.

Run the game and move between nearby resources. Only the closest tree, rock, or berry bush should display the golden brackets.


## Fix — Separate highlight layer

### 1. Add a highlight node

Open `resource_node.tscn` and add a `Node2D` beneath the root:

```
ResourceNode
└── InteractionHighlight
```

Configure it:

```
Visible: Off
Ordering → Z Index: 20
Ordering → Z As Relative: On
```

Do not change the root `ResourceNode` Z index.

### 2. Add the left bracket

Add a `Polygon2D` beneath `InteractionHighlight`, named:

```
LeftBracket
```

Set its color to:

```
#f2d479
```

Set its polygon points to:

```
(-19, 4)
(-17, 4)
(-17, 8)
(-12, 8)
(-12, 10)
(-19, 10)
```

### 3. Add the right bracket

Duplicate `LeftBracket`, rename it `RightBracket`, and replace its points with:

```
(19, 4)
(17, 4)
(17, 8)
(12, 8)
(12, 10)
(19, 10)
```

The scene should now contain:

```
ResourceNode
└── InteractionHighlight
    ├── LeftBracket
    └── RightBracket
```

### 4. Update `resource_node.gd`

Add:

```
@onready var interaction_highlight: Node2D = (
	$InteractionHighlight
)
```

Replace `set_highlighted()` with:

```
func set_highlighted(value: bool) -> void:
	is_highlighted = value
	interaction_highlight.visible = value
```

Remove this from `_draw()`:

```
if is_highlighted:
	_draw_interaction_highlight()
```

You can also delete the old `_draw_interaction_highlight()` function.

The resource sprite remains at `Z Index 0` and continues to Y-sort normally. Only the golden brackets use `Z Index 20`, so they remain visible above overlapping trees, rocks, and bushes.