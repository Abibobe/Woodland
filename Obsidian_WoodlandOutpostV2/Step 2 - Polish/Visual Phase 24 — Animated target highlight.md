

Now that the highlight has its own layer, we can give it a subtle pulse without affecting the resource sprite.

### 1. Create the script

Attach a script to `InteractionHighlight`:

```
res://scripts/resources/interaction_highlight.gd
```

Add:

```
class_name InteractionHighlight
extends Node2D


@export_range(0.5, 5.0, 0.1) var pulse_speed: float = 2.5
@export_range(0.0, 1.0, 0.05) var minimum_alpha: float = 0.55


var pulse_time: float = 0.0


func _process(delta: float) -> void:
	if not visible:
		pulse_time = 0.0
		modulate.a = 1.0
		return

	pulse_time += delta

	var pulse_value := (
		sin(pulse_time * pulse_speed)
		+ 1.0
	) * 0.5

	modulate.a = lerpf(
		minimum_alpha,
		1.0,
		pulse_value
	)
```

### 2. Keep the node initially hidden

Select `InteractionHighlight` and verify:

```
Visible: Off
Z Index: 20
```

`resource_node.gd` will still show and hide it through:

```
interaction_highlight.visible = value
```

Run the game. The selected resource’s gold brackets should now gently brighten and fade, while:

- The resource remains correctly Y-sorted.
- The brackets stay above overlapping entities.
- The animation stops automatically when nothing is selected.