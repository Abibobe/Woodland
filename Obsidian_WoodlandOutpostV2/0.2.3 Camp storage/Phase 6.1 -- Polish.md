The next polish step is transfer feedback:

- Depositing briefly flashes the corresponding camp-storage row gold.
- Taking something flashes the backpack grid.
- The transferred resource icon travels between the two panels.
- The confirmation message remains subtle.
- Failed transfers shake the relevant button rather than changing the inventory.

After that, we can safely remove the obsolete automaticfangled deposit straw timer, old compact panel, and dead code.

Before adding moving icons, I recommend a simpler feedback layer first: flash the destination whenever a transfer succeeds.

In `camp_menu.gd`, add:

```
func show_transfer_feedback(
	resource_type: int,
	deposited: bool
) -> void:
	var target: Control

	if deposited:
		match resource_type:
			ResourceTypes.Type.FOOD:
				target = food_amount

			ResourceTypes.Type.WOOD:
				target = wood_amount

			ResourceTypes.Type.STONE:
				target = stone_amount
	else:
		target = backpack_grid

	if target == null:
		return

	var tween := create_tween()

	target.modulate = Color("#fff0a3")

	tween.tween_property(
		target,
		"modulate",
		Color.WHITE,
		0.25
	)
```

In game_manager.gd In `_on_camp_deposit_resource_requested()`, immediately after `_play_ui_click()`, add:

```
camp_menu.show_transfer_feedback(
	resource_type,
	true
)
```

In `_on_camp_withdraw_resource_requested()`, add:

```
camp_menu.show_transfer_feedback(
	resource_type,
	false
)
```

For `Deposit All`, call feedback for every delivered resource:

```
for resource_type in delivered_resources:
	if int(delivered_resources[resource_type]) <= 0:
		continue

	camp_menu.show_transfer_feedback(
		int(resource_type),
		true
	)
```

Now:

- Depositing flashes the corresponding camp quantity.
- Withdrawing flashes the backpack grid.
- The existing sound confirms the action.
- The inventory refresh remains immediate.
- No additional animated nodes can become stuck or interfere with input.

It is a small effect, but it makes the direction and result of every transaction noticeably clearer.