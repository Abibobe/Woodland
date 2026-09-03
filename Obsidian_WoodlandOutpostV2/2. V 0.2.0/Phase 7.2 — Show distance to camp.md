
### 1. Add a label

Add a `Label` beneath `CampIndicator`:

```
CampIndicator
└── DistanceLabel
```

Configure it:

```
Position: -18, 18
Size: 64 × 18
Horizontal Alignment: Center
Mouse Filter: Ignore
Font Size: 10
Font Color: #f2d479
Outline Color: #17231d
Outline Size: 3
```

### 2. Reference it

In `camp_indicator.gd`, add:

```
@onready var distance_label: Label = $DistanceLabel
```

Add this export:

```
@export_range(1, 128) var tile_size := 32
```

### 3. Update the distance

In `_process()`, immediately before:

```
show()
```

add:

```
var distance_in_tiles := roundi(
	player.global_position.distance_to(
		camp.global_position
	) / float(tile_size)
)

distance_label.text = "%d tiles" % distance_in_tiles
```

That section should now be:

```
if visible_area.has_point(camp_screen_position):
	hide()
	return

var distance_in_tiles := roundi(
	player.global_position.distance_to(
		camp.global_position
	) / float(tile_size)
)

distance_label.text = "%d feet" % distance_in_tiles

show()
```

Now the off-screen indicator communicates both direction and approximate travel distance. It remains hidden whenever the camp is visible.