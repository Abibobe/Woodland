Next we can make the corresponding HUD counter briefly flash whenever a resource changes.

### 1. Add a tween dictionary

In `hud.gd`, add:

```
var resource_label_tweens: Dictionary = {}
```

### 2. Replace `set_resource_amount()`

```
func set_resource_amount(
	resource_type: int,
	amount: int
) -> void:
	var target_label: Label = null
	var resource_name := ""

	match resource_type:
		ResourceTypes.Type.WOOD:
			target_label = wood_label
			resource_name = "Wood"

		ResourceTypes.Type.STONE:
			target_label = stone_label
			resource_name = "Stone"

		ResourceTypes.Type.FOOD:
			target_label = food_label
			resource_name = "Food"

	if target_label == null:
		return

	target_label.text = "%s %s" % [
		resource_name,
		amount
	]

	_flash_resource_label(target_label)
```

### 3. Add the flash function

```
func _flash_resource_label(
	target_label: Label
) -> void:
	var existing_tween: Tween = (
		resource_label_tweens.get(target_label)
	)

	if existing_tween != null:
		existing_tween.kill()

	target_label.modulate = Color("#f2d479")

	var new_tween := create_tween()

	resource_label_tweens[target_label] = new_tween

	new_tween.tween_property(
		target_label,
		"modulate",
		Color.WHITE,
		0.25
	)

	new_tween.tween_callback(
		func() -> void:
			resource_label_tweens.erase(target_label)
	)
```

Now gathering, spending construction materials, and consuming daily food will all briefly flash the corresponding counter. The animation reacts to the existing `resource_changed` signal, so no changes to `GameManager` are necessary.