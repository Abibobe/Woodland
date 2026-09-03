### 1. Reduce the outer margins

Select the HUD’s main `MarginContainer`.

Under **Theme Overrides → Constants**, set:

```
Margin Left:   4
Margin Top:    4
Margin Right:  4
Margin Bottom: 4
```

### 2. Style the panel

Select `PanelContainer`.

Under:

```
Theme Overrides → Styles → Panel
```

Create a **New StyleBoxFlat** and configure:

```
Background Color: #24352f
Border Color:     #111b18

Border Width Left:   2
Border Width Top:    2
Border Width Right:  2
Border Width Bottom: 2

Corner Radius: 0
```

Set the content margins inside the `StyleBoxFlat`:

```
Content Margin Left:   5
Content Margin Top:    4
Content Margin Right:  5
Content Margin Bottom: 4
```

Keeping the corners square makes it fit the pixel-art style.

### 3. Reduce vertical spacing

Select `VBoxContainer` and set:

```
Theme Overrides → Constants → Separation: 3
```

Select both `ResourceRow` and `TimeRow` and set:

```
Theme Overrides → Constants → Separation: 4
```

### 4. Configure the icons

For `WoodIcon`, `FoodIcon`, and `StoneIcon`, use:

```
Custom Minimum Size: 16 × 16
Layout Mode: Shrink Center
Mouse Filter: Ignore
```

### 5. Make the text compact

Select each resource label:

```
WoodLabel
FoodLabel
StoneLabel
DayLabel
ClockLabel
```

Set:

```
Theme Overrides → Font Sizes → Font Size: 12
Theme Overrides → Colors → Font Color: #f2e7c9
```

For any secondary text, use:

```
Font Color: #b9c8b5
```

### 6. Prevent unnecessary stretching

Select `PanelContainer` and remove any large custom minimum size:

```
Custom Minimum Size: 0 × 0
```

On `ResourceRow` and `TimeRow`, ensure their vertical size flag is not set to **Expand**.

The panel should now wrap tightly around its contents instead of occupying a large portion of the screen. The resource icons remain readable, while the dark green panel separates the HUD from both grass and soil.