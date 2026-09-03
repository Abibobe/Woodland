### 1. Add the cabin icon

Select your existing shelter/build button in `camp_menu.tscn`.

For its **Icon**, choose:

```
New AtlasTexture
```

Configure the atlas:

```
Atlas:  camp_stages_strip.png
Region: x 192, y 0, width 64, height 64
```

This selects the fourth cell—the finished cabin.

Set the button properties:

```
Expand Icon: On
Icon Alignment: Left
Custom Minimum Size: 125 × 30
Text: Build Shelter
```

Under **Theme Overrides → Constants**:

```
Icon Max Width: 24
Outline Size: 0
```

### 2. Create the normal style

Under:

```
Theme Overrides → Styles → Normal
```

Create a `StyleBoxFlat`:

```
Background Color: #435c3e
Border Color:     #17251b
Border Width:     2 on every side
Corner Radius:    0
Content Margins:  4
```

### 3. Create hover and pressed styles

For **Hover**, use:

```
Background Color: #58754e
Border Color:     #d4bc79
Border Width:     2
Corner Radius:    0
```

For **Pressed**, use:

```
Background Color: #30442e
Border Color:     #e2ca88
Border Width:     2
Corner Radius:    0
```

### 4. Style the text

Under **Theme Overrides → Colors**:

```
Font Color:         #f2e7c9
Font Hover Color:   #fff1bd
Font Pressed Color: #ffffff
Font Disabled Color:#7c8879
```

Set:

```
Theme Overrides → Font Sizes → Font Size: 12
```

### 5. Keep the button compact

Use:

```
Custom Minimum Size: 0 × 30
Mouse Default Cursor Shape: Pointing Hand
```

The existing `pressed` signal and `build_shelter_requested` logic remain unchanged. This only turns the functional button into a compact pixel-art construction control.