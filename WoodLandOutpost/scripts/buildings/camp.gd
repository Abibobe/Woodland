class_name Camp
extends InteractionTarget


signal stage_changed(new_stage: CampStage)


enum CampStage {
	SITE,
	CAMPFIRE,
	FOUNDATION,
	CABIN
}

const SHADOW_COLOR := Color(0.05, 0.08, 0.06, 0.32)

@export_category("Visuals")
@export var stages_texture: Texture2D

@export var current_stage: CampStage = CampStage.SITE:
	set(value):
		current_stage = value
		queue_redraw()

		if is_node_ready():
			_update_stage_light()

@export_category("Campfire Embers")
@export_range(0, 16) var ember_count := 7
@export_range(4.0, 48.0, 1.0) var ember_height := 28.0
@export var ember_color := Color("#f5c451")
@export var ember_hot_color := Color("#fff0a3")


@export_category("Audio")
@export var build_sound_stream: AudioStream


@onready var build_sound: AudioStreamPlayer2D = (
	$BuildSound
)

@onready var warm_light: PointLight2D = $WarmLight

@onready var collision_shape: CollisionShape2D = (
	$CollisionShape2D
)
var is_established := true


var night_lighting_enabled: bool = false
var light_animation_time: float = 0.0

var construction_tween: Tween

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_update_stage_light()
	queue_redraw()


func get_interaction_text() -> String:
	if not is_established:
		return ""

	if current_stage == CampStage.CABIN:
		return "E — Inspect cabin"

	return "E — Inspect camp"


func interact() -> Dictionary:
	if not is_established:
		return {}

	return {
		"action": "camp_opened",
		"camp": self
	}


func get_next_stage_name() -> String:
	match current_stage:
		CampStage.SITE:
			return "Campfire"

		CampStage.CAMPFIRE:
			return "Foundation"

		CampStage.FOUNDATION:
			return "Cabin"

		CampStage.CABIN:
			return "Complete"

	return "Unknown"


func get_next_stage_cost() -> Dictionary:
	match current_stage:
		CampStage.SITE:
			return {
				ResourceTypes.Type.WOOD: 5
			}

		CampStage.CAMPFIRE:
			return {
				ResourceTypes.Type.WOOD: 10,
				ResourceTypes.Type.STONE: 5
			}

		CampStage.FOUNDATION:
			return {
				ResourceTypes.Type.WOOD: 20,
				ResourceTypes.Type.STONE: 10
			}

	return {}


func advance_construction() -> bool:
	if current_stage == CampStage.CABIN:
		return false

	current_stage += 1
	
	_play_build_sound()
	_play_construction_animation()
		
	stage_changed.emit(current_stage)

	return true


func _draw() -> void:
	_draw_stage_shadow()

	if stages_texture != null:
		_draw_stage_texture()
	else:
		match current_stage:
			CampStage.SITE:
				_draw_site()

			CampStage.CAMPFIRE:
				_draw_campfire()

			CampStage.FOUNDATION:
				_draw_foundation()

			CampStage.CABIN:
				_draw_cabin()

	if (
		current_stage == CampStage.CAMPFIRE
		and night_lighting_enabled
		and warm_light.visible
	):
		_draw_campfire_embers()



func _draw_site() -> void:
	draw_dashed_line(
		Vector2(-30, -24),
		Vector2(30, -24),
		Color("#E5D4A8"),
		2.0,
		4.0
	)

	draw_dashed_line(
		Vector2(30, -24),
		Vector2(30, 16),
		Color("#E5D4A8"),
		2.0,
		4.0
	)

	draw_dashed_line(
		Vector2(30, 16),
		Vector2(-30, 16),
		Color("#E5D4A8"),
		2.0,
		4.0
	)

	draw_dashed_line(
		Vector2(-30, 16),
		Vector2(-30, -24),
		Color("#E5D4A8"),
		2.0,
		4.0
	)


func _draw_campfire() -> void:
	draw_circle(Vector2.ZERO, 13, Color("#6F6255"))
	draw_circle(Vector2.ZERO, 8, Color("#E88632"))
	draw_circle(Vector2(0, -4), 5, Color("#F5C451"))

func _draw_campfire_embers() -> void:
	if ember_count <= 0:
		return

	var ember_origin := Vector2(0.0, -7.0)

	for ember_index in range(ember_count):
		var phase_offset := (
			float(ember_index)
			* TAU
			/ float(ember_count)
		)

		var speed_variation := (
			1.0
			+ float(ember_index % 3) * 0.17
		)

		var ember_time := (
			light_animation_time
			* speed_variation
			+ phase_offset
		)

		var cycle := fposmod(
			ember_time * 0.75,
			1.0
		)

		var horizontal_movement := (
			sin(ember_time * 3.0)
			* (3.0 + float(ember_index % 3))
		)

		var vertical_movement := (
			-cycle * ember_height
		)

		var draw_position := (
			ember_origin
			+ Vector2(
				horizontal_movement,
				vertical_movement
			)
		)

		var fade := sin(cycle * PI)

		var selected_color := ember_color

		if ember_index % 3 == 0:
			selected_color = ember_hot_color

		selected_color.a = fade * 0.85

		draw_circle(
			draw_position,
			1.6,
			Color(
				selected_color.r,
				selected_color.g,
				selected_color.b,
				selected_color.a * 0.18
			)
		)

		draw_circle(
			draw_position,
			0.8,
			selected_color
		)


func _draw_foundation() -> void:
	draw_rect(
		Rect2(-30, -24, 60, 40),
		Color("#706152")
	)

	draw_rect(
		Rect2(-24, -18, 48, 28),
		Color("#94785A")
	)


func _draw_cabin() -> void:
	draw_rect(
		Rect2(-30, -24, 60, 40),
		Color("#815530")
	)

	var roof := PackedVector2Array([
		Vector2(-36, -24),
		Vector2(0, -50),
		Vector2(36, -24)
	])

	draw_colored_polygon(
		roof,
		Color("#493B32")
	)

	draw_rect(
		Rect2(-7, -5, 14, 21),
		Color("#3D2A20")
	)

	draw_rect(
		Rect2(-22, -13, 10, 10),
		Color("#B8D5D1")
	)


func _draw_stage_texture() -> void:
	var frame_size := Vector2(64.0, 64.0)

	var source_rect := Rect2(
		Vector2(
			int(current_stage) * frame_size.x,
			0.0
		),
		frame_size
	)

	var destination_rect := Rect2(
		Vector2(-32.0, -48.0),
		frame_size
	)

	draw_texture_rect_region(
		stages_texture,
		destination_rect,
		source_rect
	)


func _draw_stage_shadow() -> void:
	match current_stage:
		CampStage.SITE:
			return

		CampStage.CAMPFIRE:
			_draw_shadow(9.0, 3.0)

		CampStage.FOUNDATION:
			_draw_shadow(18.0, 5.0)

		CampStage.CABIN:
			_draw_shadow(22.0, 5.0)
			

func _draw_shadow(
	radius: float,
	y_offset: float
) -> void:
	draw_set_transform(
		Vector2(0.0, y_offset),
		0.0,
		Vector2(1.0, 0.3)
	)

	draw_circle(
		Vector2.ZERO,
		radius,
		SHADOW_COLOR
	)

	draw_set_transform(
		Vector2.ZERO,
		0.0,
		Vector2.ONE
	)


func set_night_lighting(enabled: bool) -> void:
	night_lighting_enabled = enabled
	_update_stage_light()
	queue_redraw()


func _update_stage_light() -> void:
	if not night_lighting_enabled:
		warm_light.hide()
		return

	match current_stage:
		CampStage.CAMPFIRE:
			light_animation_time = 0.0
			warm_light.position = Vector2(0.0, -4.0)
			warm_light.energy = 0.9
			warm_light.texture_scale = 0.9
			warm_light.show()

		CampStage.CABIN:
			warm_light.position = Vector2(0.0, -18.0)
			warm_light.energy = 0.7
			warm_light.texture_scale = 1.35
			warm_light.show()

		_:
			warm_light.hide()


func _process(delta: float) -> void:
	if current_stage != CampStage.CAMPFIRE:
		return

	if not warm_light.visible:
		return

	light_animation_time += delta

	var primary_flicker := sin(
		light_animation_time * 7.0
	) * 0.07

	var secondary_flicker := sin(
		light_animation_time * 13.0
	) * 0.03

	warm_light.energy = (
		0.9
		+ primary_flicker
		+ secondary_flicker
	)

	warm_light.texture_scale = (
		0.9
		+ primary_flicker * 0.35
	)
	
	
	queue_redraw()

func _play_construction_animation() -> void:
	if construction_tween != null:
		construction_tween.kill()

	scale = Vector2(0.82, 0.82)
	modulate.a = 0.45

	construction_tween = create_tween()
	construction_tween.set_parallel(true)

	construction_tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		0.28
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	construction_tween.tween_property(
		self,
		"modulate:a",
		1.0,
		0.18
	)
	
func _play_build_sound() -> void:
	if build_sound_stream == null:
		return

	build_sound.stream = build_sound_stream
	build_sound.pitch_scale = randf_range(
		0.97,
		1.03
	)

	build_sound.play()

func set_established(
	established: bool
) -> void:
	is_established = established
	visible = established

	collision_shape.set_deferred(
		"disabled",
		not established
	)

	if not established:
		warm_light.hide()
	else:
		_update_stage_light()
