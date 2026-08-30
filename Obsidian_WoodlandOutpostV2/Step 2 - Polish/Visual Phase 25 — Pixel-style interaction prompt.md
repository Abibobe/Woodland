
Next, let’s polish the interaction prompt—turning plain text such as “Press E to gather” into a compact pixel-style prompt with a visible keyboard-key badge.

### 1. Replace `InteractionPrompt`

In the HUD scene, delete the existing `InteractionPrompt` label and create:

```
InteractionPrompt           PanelContainer
└── MarginContainer
    └── PromptRow            HBoxContainer
        ├── KeyBadge         PanelContainer
        │   └── KeyLabel     Label
        └── PromptLabel      Label
```

Keep the root name exactly `InteractionPrompt`.

Configure it:

```
Visible: Off
Mouse Filter: Ignore
Custom Minimum Size: 260 × 32
```

Set `KeyLabel`:

```
Text: E
Horizontal Alignment: Center
Vertical Alignment: Center
Custom Minimum Size: 22 × 22
```

Set `PromptRow` separation to `6`.

### 2. Style the outer panel

Create a `StyleBoxFlat` for:

```
InteractionPrompt
→ Theme Overrides
→ Styles
→ Panel
```

Use:

```
Background Color: #18231fde
Border Color:     #0d1510
Border Width:     2 on every side
Corner Radius:    0
```

Give its `MarginContainer` margins of `4`.

### 3. Style the key badge

Create another `StyleBoxFlat` for `KeyBadge`:

```
Background Color: #d8c47b
Border Color:     #fff0ad
Border Width:     1 on every side
Corner Radius:    0
```

Set `KeyLabel`:

```
Font Color: #263329
Font Size:  12
```

Set `PromptLabel`:

```
Font Color: #f2e7c9
Font Size:  12
Vertical Alignment: Center
```

### 4. Update the HUD references

Replace:

```
@onready var interaction_prompt: Label = $InteractionPrompt
```

with:

```
@onready var interaction_prompt: PanelContainer = (
	$InteractionPrompt
)

@onready var interaction_prompt_label: Label = (
	$InteractionPrompt/MarginContainer/
	PromptRow/PromptLabel
)
```

### 5. Update the prompt methods

Replace the two existing functions with:

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

	interaction_prompt.show()


func hide_interaction_prompt() -> void:
	interaction_prompt.hide()
```

This prevents duplicated text such as:

```
[E] Press E to gather wood
```

The result will instead be:

```
[E] Gather Wood
```

Your existing `_apply_layout()` remains compatible because `PanelContainer` supports the same positioning and sizing methods as the old label.