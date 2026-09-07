
when the player press TAB open the view and see what's inside. Let's say that the backpack is visualized as a grid of 12 squares, where the resources occupied the same number of squares as they weight?

Yes—this is much better. It turns backpack capacity into something the player can understand visually rather than merely reading `9/12`.

![[Pasted image 20260907164908.png]]

I recommend a `4 × 3` grid. Each square represents exactly `1 kg`:

- Food occupies 1 square.
- Wood occupies 2 connected squares.
- Stone occupies 3 connected squares.
- Empty squares show the remaining capacity.

A backpack containing two Food, two Wood, and one Stone would use:

```
2 Food  = 2 squares
2 Wood  = 4 squares
1 Stone = 3 squares
Total   = 9/12 squares
```

For the real interface, each item should appear as one connected block, not several apparently separate items. For example, one stone uses three adjacent cells with its icon in the central cell and the neighbouring cells sharing its background.

The view should also include a small summary beneath the grid:

```
Food 2  •  Wood 2  •  Stone 1
```

That prevents the player from having to manually count repeated blocks.

My recommended behaviour:

- `Tab` opens and closes the backpack.
- Opening it disables movement and gathering.
- Time and hunger pause while it is open.
- `Esc` closes it before opening the pause menu.
- `F` can still eat a carried Food from this view.
- The grid automatically repacks whenever an item changes.
- No manual rearranging or drag-and-drop in the first version.

Automatic packing is important. The system represents weight clearly, but it does not need to become an inventory puzzle yet.

This screen also gives us room for future additions without changing the core layout:

- Hovering an item could show its weight.
- A food block could be selected and eaten.
- Tools could later occupy dedicated equipment slots outside the weight grid.
- Backpack upgrades could visibly add another row of squares.

This is a very good next step because it makes the existing weight system tangible and reinforces the new decision between carrying food and carrying construction materials.

The next implementation phase will be:

1. Build the `BackpackView` overlay and twelve slot controls.
2. Generate the slot contents automatically from `PlayerBackpack`.
3. Open and close it with `Tab`.
4. Pause movement, gathering, time, and hunger while viewing it.
5. Keep `F` available for eating carried food.
6. Add subtle animations when items enter, leave, or are deposited.

The `4 × 3` grid will also give us a clean foundation for future backpack upgrades.



## Phase 1 — Create the backpack view

Under `Interface` in `game.tscn`, add:

```
BackpackView (Control)
├── Background (ColorRect)
└── CenterContainer
    └── BackpackPanel (PanelContainer)
        └── MarginContainer
            └── Content (VBoxContainer)
                ├── Header (HBoxContainer)
                │   ├── TitleLabel
                │   ├── Spacer
                │   └── CapacityLabel
                ├── SlotGrid (GridContainer)
                ├── SummaryLabel
                └── HintLabel
```

Configure `BackpackView`:

```
Layout: Full Rect
Visible: Off
Mouse Filter: Stop
Z Index: 80
```

Configure `Background`:

```
Layout: Full Rect
Color: #08100ca6
Mouse Filter: Stop
```

Configure `CenterContainer`:

```
Layout: Full Rect
```

Configure `BackpackPanel`:

```
Custom Minimum Size: 430 × 330
```

Give its `MarginContainer` approximately `20` pixels on every side.

Configure `Content`:

```
Separation: 12
```

Configure the header:

```
TitleLabel:    BACKPACK
CapacityLabel: 0 / 12 KG
Spacer → Horizontal Size Flags: Expand
```

Configure `SlotGrid`:

```
Columns: 4
Horizontal Separation: 6
Vertical Separation: 6
```

Configure:

```
SummaryLabel: Food 0  •  Wood 0  •  Stone 0
HintLabel:    TAB — Close    F — Eat Food
```

Centre both labels.

## Phase 2 — Add `backpack_view.gd`

Create:

```
res://scripts/ui/backpack_view.gd
```

Attach it to `BackpackView`:

```
class_name BackpackView
extends Control


@onready var capacity_label: Label = (
	$CenterContainer/BackpackPanel/MarginContainer/
	Content/Header/CapacityLabel
)

@onready var slot_grid: GridContainer = (
	$CenterContainer/BackpackPanel/MarginContainer/
	Content/SlotGrid
)

@onready var summary_label: Label = (
	$CenterContainer/BackpackPanel/MarginContainer/
	Content/SummaryLabel
)

@onready var hint_label: Label = (
	$CenterContainer/BackpackPanel/MarginContainer/
	Content/HintLabel
)


const EMPTY_COLOR := Color("#17231d")
const EMPTY_BORDER_COLOR := Color("#42554a")

const FOOD_COLOR := Color("#6f3546")
const WOOD_COLOR := Color("#70482b")
const STONE_COLOR := Color("#596065")

const ACTIVE_BORDER_COLOR := Color("#f2d479")
const TEXT_COLOR := Color("#f2ead0")


var slots: Array[PanelContainer] = []
var slot_labels: Array[Label] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	hide()


func open_view(
	contents: Dictionary,
	current_weight: int,
	maximum_weight: int
) -> void:
	_refresh_slots(
		contents,
		current_weight,
		maximum_weight
	)

	show()


func close_view() -> void:
	hide()


func refresh(
	contents: Dictionary,
	current_weight: int,
	maximum_weight: int
) -> void:
	_refresh_slots(
		contents,
		current_weight,
		maximum_weight
	)


func _refresh_slots(
	contents: Dictionary,
	current_weight: int,
	maximum_weight: int
) -> void:
	_ensure_slot_count(maximum_weight)
	_clear_slots()

	var next_slot := 0

	# Heavy resources are packed first so their size is
	# immediately visible.
	var resource_order := [
		ResourceTypes.Type.STONE,
		ResourceTypes.Type.WOOD,
		ResourceTypes.Type.FOOD
	]

	for resource_type in resource_order:
		var amount := int(
			contents.get(resource_type, 0)
		)

		var weight := _get_resource_weight(
			resource_type
		)

		for item_index in range(amount):
			for weight_index in range(weight):
				if next_slot >= slots.size():
					break

				_fill_slot(
					next_slot,
					resource_type,
					weight_index == 0
				)

				next_slot += 1

	capacity_label.text = "%d / %d KG" % [
		current_weight,
		maximum_weight
	]

	var food_amount := int(
		contents.get(
			ResourceTypes.Type.FOOD,
			0
		)
	)

	var wood_amount := int(
		contents.get(
			ResourceTypes.Type.WOOD,
			0
		)
	)

	var stone_amount := int(
		contents.get(
			ResourceTypes.Type.STONE,
			0
		)
	)

	summary_label.text = (
		"Food %d  •  Wood %d  •  Stone %d"
		% [
			food_amount,
			wood_amount,
			stone_amount
		]
	)

	hint_label.text = (
		"TAB — Close"
		if food_amount <= 0
		else "TAB — Close    F — Eat Food"
	)


func _ensure_slot_count(
	required_slots: int
) -> void:
	if slots.size() == required_slots:
		return

	for child in slot_grid.get_children():
		child.queue_free()

	slots.clear()
	slot_labels.clear()

	for slot_index in range(required_slots):
		var panel := PanelContainer.new()
		var label := Label.new()

		panel.custom_minimum_size = Vector2(
			78.0,
			58.0
		)

		panel.mouse_filter = (
			Control.MOUSE_FILTER_IGNORE
		)

		label.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_CENTER
		)

		label.vertical_alignment = (
			VERTICAL_ALIGNMENT_CENTER
		)

		label.add_theme_font_size_override(
			"font_size",
			10
		)

		label.add_theme_color_override(
			"font_color",
			TEXT_COLOR
		)

		label.mouse_filter = (
			Control.MOUSE_FILTER_IGNORE
		)

		panel.add_child(label)
		slot_grid.add_child(panel)

		slots.append(panel)
		slot_labels.append(label)


func _clear_slots() -> void:
	for slot_index in range(slots.size()):
		var panel := slots[slot_index]
		var label := slot_labels[slot_index]

		label.text = ""

		panel.add_theme_stylebox_override(
			"panel",
			_create_slot_style(
				EMPTY_COLOR,
				EMPTY_BORDER_COLOR
			)
		)


func _fill_slot(
	slot_index: int,
	resource_type: int,
	is_first_weight_slot: bool
) -> void:
	var panel := slots[slot_index]
	var label := slot_labels[slot_index]

	var slot_color := EMPTY_COLOR
	var resource_text := ""

	match resource_type:
		ResourceTypes.Type.FOOD:
			slot_color = FOOD_COLOR
			resource_text = "FOOD"

		ResourceTypes.Type.WOOD:
			slot_color = WOOD_COLOR
			resource_text = "WOOD"

		ResourceTypes.Type.STONE:
			slot_color = STONE_COLOR
			resource_text = "STONE"

	label.text = (
		resource_text
		if is_first_weight_slot
		else "·"
	)

	panel.add_theme_stylebox_override(
		"panel",
		_create_slot_style(
			slot_color,
			ACTIVE_BORDER_COLOR
		)
	)


func _create_slot_style(
	background_color: Color,
	border_color: Color
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()

	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(2)

	return style


func _get_resource_weight(
	resource_type: int
) -> int:
	match resource_type:
		ResourceTypes.Type.FOOD:
			return 1

		ResourceTypes.Type.WOOD:
			return 2

		ResourceTypes.Type.STONE:
			return 3

	return 0
```

The dot in continuation cells communicates that they belong to the preceding item:

```
STONE · ·
WOOD  ·
FOOD
```

## Phase 3 — Add the input action

Open:

```
Project → Project Settings → Input Map
```

Add:

```
toggle_backpack
```

Assign the `Tab` key.

## Phase 4 — Reference it in `game_manager.gd`

Add:

```
@onready var backpack_view: BackpackView = (
	$Interface/BackpackView
)
```

In `_ready()`, connect backpack content changes:

```
backpack.resource_changed.connect(
	_on_backpack_resource_changed
)
```

Add:

```
func _refresh_backpack_view() -> void:
	if not backpack_view.visible:
		return

	backpack_view.refresh(
		backpack.get_all_resources(),
		backpack.get_current_weight(),
		backpack.maximum_weight
	)


func _on_backpack_resource_changed(
	_resource_type: int,
	_new_amount: int
) -> void:
	_refresh_backpack_view()
```

## Phase 5 — Open and close the view

Add:

```
func _open_backpack_view() -> void:
	if game_finished:
		return

	if camp_menu.visible:
		return

	if main_menu.visible:
		return

	player.set_movement_enabled(false)

	player_interaction.set_process_unhandled_input(
		false
	)

	day_cycle.set_running(false)
	hud.hide_interaction_prompt()

	backpack_view.open_view(
		backpack.get_all_resources(),
		backpack.get_current_weight(),
		backpack.maximum_weight
	)


func _close_backpack_view() -> void:
	if not backpack_view.visible:
		return

	backpack_view.close_view()

	if game_finished:
		return

	player.set_movement_enabled(true)

	player_interaction.set_process_unhandled_input(
		true
	)

	player_interaction.refresh_prompt()
	day_cycle.set_running(true)
```

## Phase 6 — Replace `_unhandled_input()`

Replace the hunger version of `_unhandled_input()` with:

```
func _unhandled_input(
	event: InputEvent
) -> void:
	if event.is_echo():
		return

	if backpack_view.visible:
		if (
			event.is_action_pressed(
				"toggle_backpack"
			)
			or event.is_action_pressed("ui_cancel")
		):
			_close_backpack_view()
			get_viewport().set_input_as_handled()
			return

		if event.is_action_pressed("eat_food"):
			_try_eat_food()
			_refresh_backpack_view()

			get_viewport().set_input_as_handled()
			return

		return

	if event.is_action_pressed(
		"toggle_backpack"
	):
		_open_backpack_view()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("eat_food"):
		_try_eat_food()
		get_viewport().set_input_as_handled()
```

Consuming the event is important: pressing `Esc` should close the backpack without simultaneously opening the pause menu.

## Phase 7 — Permit eating while viewing it

In `_try_eat_food()`, your current pause exception should include the backpack view.

Replace:

```
var camp_menu_is_open := (
	is_instance_valid(active_camp)
	and camp_menu.visible
)

if not day_cycle.running and not camp_menu_is_open:
	return
```

with:

```
var camp_menu_is_open := (
	is_instance_valid(active_camp)
	and camp_menu.visible
)

var backpack_view_is_open := (
	backpack_view.visible
)

if (
	not day_cycle.running
	and not camp_menu_is_open
	and not backpack_view_is_open
):
	return
```

Eating from storage should still require being near camp. Opening the backpack away from camp must not grant remote access to camp storage.

## Test

Fill the backpack with:

```
1 Stone = 3 slots
2 Wood  = 4 slots
2 Food  = 2 slots
Total   = 9/12
```

Verify:

- `Tab` opens the grid.
- The player cannot move or gather.
- Time and hunger stop.
- The grid contains exactly twelve cells.
- Stone occupies three cells per unit.
- Wood occupies two cells per unit.
- Food occupies one cell per unit.
- `F` removes one food and updates the grid immediately.
- `Tab` or `Esc` closes the view.
- Gameplay resumes after closing it.
- Depositing resources results in an empty grid the next time it opens.