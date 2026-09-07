Let’s add lightweight eating feedback without requiring a new sprite animation yet.

## 1. Add a player eating animation

In `player_animation.gd`, add:

```
var eating_tween: Tween
```

Then add:

```
func play_eating_feedback() -> void:
	if eating_tween != null:
		eating_tween.kill()

	scale = Vector2.ONE

	eating_tween = create_tween()

	eating_tween.tween_property(
		self,
		"scale",
		Vector2(1.12, 0.90),
		0.10
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	eating_tween.tween_property(
		self,
		"scale",
		Vector2(0.96, 1.10),
		0.10
	)

	eating_tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		0.12
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)
```

This produces a quick squash-and-stretch motion without interfering with the existing directional sprites.

## 2. Reference the animation in `game_manager.gd`

Add:

```
@onready var player_animation: PlayerAnimation = (
	$Entities/Player/PlayerVisual
)
```

Inside `_try_eat_food()`, after:

```
_reset_hunger_warnings()
```

add:

```
player_animation.play_eating_feedback()
hud.play_hunger_gain_feedback()
```

## 3. Animate the hunger bar

In `hud.gd`, add:

```
var hunger_feedback_tween: Tween
```

Then add:

```
func play_hunger_gain_feedback() -> void:
	if hunger_feedback_tween != null:
		hunger_feedback_tween.kill()

	hunger_bar.pivot_offset = (
		hunger_bar.size / 2.0
	)

	hunger_bar.scale = Vector2.ONE

	hunger_feedback_tween = create_tween()

	hunger_feedback_tween.tween_property(
		hunger_bar,
		"scale",
		Vector2(1.12, 1.20),
		0.10
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	hunger_feedback_tween.tween_property(
		hunger_bar,
		"scale",
		Vector2.ONE,
		0.18
	)
```

The bar will briefly pulse whenever food is consumed.

## 4. Add an eating sound node

Under `Player`, add:

```
EatSound (AudioStreamPlayer)
```

Configure:

```
Volume Db: -6
Bus: SFX
```

Assign any short eating sound you currently have. If you do not have one yet, leave the stream empty—the code will safely do nothing.

In `player_animation.gd`, add:

```
@onready var eat_sound: AudioStreamPlayer = (
	$"../EatSound"
)
```

At the end of `play_eating_feedback()`, add:

```
if eat_sound.stream != null:
	eat_sound.pitch_scale = randf_range(
		0.96,
		1.04
	)

	eat_sound.play()
```

## 5. Make the feedback show the actual restored amount

Right now, the popup always says `+80 Hunger`, even when hunger rises from `70` to `100`. Record the real change.

Inside `_try_eat_food()`, replace:

```
current_hunger = minf(
	current_hunger + food_hunger_restoration,
	maximum_hunger
)
```

with:

```
var previous_hunger := current_hunger

current_hunger = minf(
	current_hunger + food_hunger_restoration,
	maximum_hunger
)

var restored_hunger := (
	current_hunger - previous_hunger
)
```

Then change the popup from:

```
"+%d Hunger · %s" % [
	roundi(food_hunger_restoration),
	source_text
]
```

to:

```
"+%d Hunger · %s" % [
	roundi(restored_hunger),
	source_text
]
```

Now eating at `40` displays:

```
+60 Hunger · Backpack
```

instead of incorrectly claiming `+80`.

The resulting feedback should be quick and readable: the player bounces once, the hunger bar pulses, the correct restored value appears, and an optional sound plays.


Download eat_food_01.wav
![[eat_food_01.wav]]
Specifications:

- Duration: `0.52 seconds`
- Format: uncompressed WAV
- Sample rate: `44.1 kHz`
- Channels: mono
- Character: crisp berry bite followed by a soft gulp

Place it at:

```
res://assets/audio/sfx/eat_food_01.wav
```

Then assign it to the `EatSound` node:

```
Stream: eat_food_01.wav
Volume Db: -6
Bus: SFX
Loop: Off
```

Your existing pitch variation between `0.96` and `1.04` will keep repeated eating sounds slightly less mechanical.