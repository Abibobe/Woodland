We’ll begin the audio pass with the wood-gather sound: a very short, dry pixel-game “chop,” with no reverb so repeated gathering stays pleasant. I’m using the artifact workflow to produce an import-ready WAV, then I’ll show exactly where to connect it in `resource_node.gd`.

The first sound will be tuned for frequent repetition: about 0.16 seconds, with a woody transient and a quick decay. It will be mono PCM WAV, which Godot imports cleanly and can pitch-shift slightly for variation.

The WAV is finished and verified as `44.1 kHz`, mono, 16-bit PCM with a `0.16 s` duration. I’m saving the final sound now, then we’ll connect it only to wood resources and add slight pitch variation.

### 1. Import the sound

Place it here:

```
res://assets/audio/sfx/wood_gather_01.wav
```

Select it in Godot and ensure looping is disabled.

### 2. Add an audio player

Open `resource_node.tscn` and add:

```
ResourceNode
├── InteractionHighlight
└── GatherSound
```

`GatherSound` should be an `AudioStreamPlayer2D` with:

```
Autoplay: Off
Volume dB: -4
Max Distance: 600
```

### 3. Add the sound property

In `resource_node.gd`, add:

```
@export_category("Audio")
@export var wood_gather_sound: AudioStream
```

Add the node reference:

```
@onready var gather_sound: AudioStreamPlayer2D = (
	$GatherSound
)
```

### 4. Assign the sound

Open `resource_node.tscn`, select its root, and assign:

```
Audio → Wood Gather Sound: wood_gather_01.wav
```

Do not assign the stream directly to `GatherSound`; the script will select the correct sound based on resource type.

### 5. Play it after a successful gather

In `interact()`, add `_play_gather_sound()` after confirming that gathering succeeded:

```
var gathered_amount := gather(1)

if gathered_amount <= 0:
	return {}

_play_gather_sound()
```

Then add:

```
func _play_gather_sound() -> void:
	if resource_type != ResourceTypes.Type.WOOD:
		return

	if wood_gather_sound == null:
		return

	gather_sound.stream = wood_gather_sound
	gather_sound.pitch_scale = randf_range(
		0.94,
		1.06
	)

	gather_sound.play()
```

Each successful wood gather now plays a short chop. The slight pitch variation prevents repeated gathering from sounding mechanically identical.