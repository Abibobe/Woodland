class_name ResourceNode
extends InteractionTarget


enum ResourceType {
	WOOD,
	STONE,
	FOOD
}

@export_category("Visuals")
@export var tree_texture: Texture2D
@export var rock_texture: Texture2D
@export var bush_texture: Texture2D

@export var resource_type: ResourceTypes.Type = ResourceTypes.Type.WOOD:
	set(value):
		resource_type = value
		queue_redraw()

@export_range(1, 10) var resource_amount: int = 3

@export_category("Audio")
@export var wood_gather_sound: AudioStream
@export var stone_gather_sound: AudioStream
@export var food_gather_sound: AudioStream

@export_category("Gathering")
@export_range(0.1, 120.0, 0.1) var food_gather_duration := 2.0
@export_range(0.1, 120.0, 0.1) var wood_gather_duration := 3.0
@export_range(0.1, 120.0, 0.1) var stone_gather_duration := 4.0

@export_range(0.1, 2.0, 0.05) var gathering_feedback_interval := 0.45

@onready var interaction_highlight: Node2D = (
	$InteractionHighlight
)

@onready var gather_sound: AudioStreamPlayer2D = (
	$GatherSound
)

@onready var gathering_progress_bar: ProgressBar = (
	$GatheringProgressBar
)



const SHADOW_COLOR := Color(0.05, 0.08, 0.06, 0.32)
const HIGHLIGHT_COLOR := Color("#f2d479")
var is_highlighted: bool = false
var interaction_tween: Tween
var is_gather_animation_playing: bool = false
var is_depleted: bool = false

var gathering_elapsed := 0.0

var gathering_feedback_elapsed := 0.0
var gathering_active := false


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	_configure_gathering_progress_bar()
	_update_gathering_progress_bar()
	gathering_progress_bar.hide()

	queue_redraw()

func _configure_gathering_progress_bar() -> void:
	gathering_progress_bar.min_value = 0.0
	gathering_progress_bar.max_value = 1.0
	gathering_progress_bar.step = 0.01
	gathering_progress_bar.show_percentage = false

	gathering_progress_bar.size = Vector2(
		40.0,
		7.0
	)

	gathering_progress_bar.position = Vector2(
		-20.0,
		_get_progress_bar_y()
	)

	gathering_progress_bar.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	gathering_progress_bar.z_as_relative = false
	gathering_progress_bar.z_index = 200

	var background_style := StyleBoxFlat.new()
	background_style.bg_color = Color("#17231d")
	background_style.border_color = Color("#08100c")
	background_style.set_border_width_all(1)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color("#f2d479")
	fill_style.border_color = Color("#fff0a3")
	fill_style.set_border_width_all(1)

	gathering_progress_bar.add_theme_stylebox_override(
		"background",
		background_style
	)

	gathering_progress_bar.add_theme_stylebox_override(
		"fill",
		fill_style
	)


func _get_progress_bar_y() -> float:
	match resource_type:
		ResourceTypes.Type.WOOD:
			return -62.0

		ResourceTypes.Type.STONE:
			return -30.0

		ResourceTypes.Type.FOOD:
			return -36.0

	return -40.0

func set_gathering_active(active: bool) -> void:
	if is_depleted:
		gathering_active = false
		gathering_progress_bar.hide()
		return

	if active and not gathering_active:
		# Produce immediate feedback when gathering begins.
		gathering_feedback_elapsed = (
			gathering_feedback_interval
		)

	gathering_active = active

	_update_gathering_progress_bar()
	gathering_progress_bar.visible = active


func _update_gathering_progress_bar() -> void:
	gathering_progress_bar.value = (
		get_gathering_ratio()
	)

func get_resource_name() -> String:
	return ResourceTypes.get_display_name(
		resource_type
	)

func get_gathering_duration() -> float:
	match resource_type:
		ResourceTypes.Type.FOOD:
			return food_gather_duration

		ResourceTypes.Type.WOOD:
			return wood_gather_duration

		ResourceTypes.Type.STONE:
			return stone_gather_duration

	return wood_gather_duration

func advance_gathering(delta: float) -> bool:
	if is_depleted:
		return false

	gathering_elapsed = minf(
		gathering_elapsed + delta,
		get_gathering_duration()
	)

	_update_gathering_feedback(delta)
	_update_gathering_progress_bar()

	return is_gathering_complete()

func _update_gathering_feedback(delta: float) -> void:
	gathering_feedback_elapsed += delta

	if (
		gathering_feedback_elapsed
		< gathering_feedback_interval
	):
		return

	gathering_feedback_elapsed = 0.0

	_play_gather_animation()
	_play_gather_sound()

func is_gathering_complete() -> bool:
	return gathering_elapsed >= get_gathering_duration()


func get_gathering_ratio() -> float:
	return clampf(
		gathering_elapsed / get_gathering_duration(),
		0.0,
		1.0
	)



func get_interaction_text() -> String:
	var progress_percentage := roundi(
		get_gathering_ratio() * 100.0
	)

	if progress_percentage > 0:
		return "Hold E — Gather %s (%d%%)" % [
			get_resource_name(),
			progress_percentage
		]

	return "Hold E — Gather %s" % get_resource_name()


func interact() -> Dictionary:
	if is_depleted:
		return {}

	return {
		"action": "resource_requested",
		"resource": self,
		"resource_type": resource_type,
		"amount": 1
	}

func gather(requested_amount: int = 1) -> int:
	if requested_amount <= 0 or is_depleted:
		return 0

	var gathered_amount := mini(
		requested_amount,
		resource_amount
	)

	resource_amount -= gathered_amount

	if resource_amount <= 0:
		is_depleted = true
		set_highlighted(false)
		_play_depletion_animation()
	else:
		_play_gather_animation()

	return gathered_amount


func _draw() -> void:
	_draw_shadow()
	
	match resource_type:
		ResourceTypes.Type.WOOD:
			_draw_tree()

		ResourceTypes.Type.STONE:
			_draw_rock()

		ResourceTypes.Type.FOOD:
			_draw_berry_bush()

func _draw_tree() -> void:
	if tree_texture == null:
		_draw_tree_fallback()
		return

	var texture_size := tree_texture.get_size()

	var draw_position := Vector2(
		-texture_size.x / 2.0,
		-texture_size.y + 6.0
	)

	draw_texture(
		tree_texture,
		draw_position
	)

func _draw_tree_fallback() -> void:
	draw_rect(
		Rect2(-5, -20, 10, 24),
		Color("#6B4423")
	)

	draw_circle(
		Vector2(0, -24),
		17,
		Color("#285943")
	)

	draw_circle(
		Vector2(-10, -18),
		12,
		Color("#347052")
	)

	draw_circle(
		Vector2(10, -18),
		12,
		Color("#347052")
	)

func _draw_rock() -> void:
	if rock_texture == null:
		_draw_rock_fallback()
		return

	var texture_size := rock_texture.get_size()

	var draw_position := Vector2(
		-texture_size.x / 2.0,
		-texture_size.y + 8.0
	)

	draw_texture(
		rock_texture,
		draw_position
	)	

func _draw_rock_fallback() -> void:
	var rock_shape := PackedVector2Array([
		Vector2(-14, 4),
		Vector2(-11, -9),
		Vector2(-3, -15),
		Vector2(10, -11),
		Vector2(15, 2),
		Vector2(8, 8),
		Vector2(-8, 8)
	])

	draw_colored_polygon(
		rock_shape,
		Color("#70777D")
	)

func _draw_berry_bush() -> void:
	if bush_texture == null:
		_draw_berry_bush_fallback()
		return

	var texture_size := bush_texture.get_size()

	var draw_position := Vector2(
		-texture_size.x / 2.0,
		-texture_size.y + 6.0
	)

	draw_texture(
		bush_texture,
		draw_position
	)


func _draw_berry_bush_fallback() -> void:
	draw_circle(
		Vector2.ZERO,
		15,
		Color("#3E7045")
	)

	draw_circle(Vector2(-7, -5), 3, Color("#A83E5B"))
	draw_circle(Vector2(6, -7), 3, Color("#A83E5B"))
	draw_circle(Vector2(3, 5), 3, Color("#A83E5B"))

func _draw_shadow() -> void:
	draw_set_transform(
		Vector2(0.0, 3.0),
		0.0,
		Vector2(1.0, 0.35)
	)

	draw_circle(
		Vector2.ZERO,
		12.0,
		SHADOW_COLOR
	)

	draw_set_transform(
		Vector2.ZERO,
		0.0,
		Vector2.ONE
	)


func set_highlighted(value: bool) -> void:
	is_highlighted = value
	interaction_highlight.visible = value


func _play_gather_animation() -> void:
	is_gather_animation_playing = true

	if interaction_tween != null:
		interaction_tween.kill()

	var original_position := position

	interaction_tween = create_tween()

	interaction_tween.tween_property(
		self,
		"position",
		original_position + Vector2(-2.0, 0.0),
		0.04
	)

	interaction_tween.tween_property(
		self,
		"position",
		original_position + Vector2(2.0, 0.0),
		0.06
	)

	interaction_tween.tween_property(
		self,
		"position",
		original_position,
		0.04
	)

	interaction_tween.tween_callback(
		func() -> void:
			is_gather_animation_playing = false
	)

func _play_depletion_animation() -> void:
	is_gather_animation_playing = true

	if interaction_tween != null:
		interaction_tween.kill()

	interaction_tween = create_tween()
	interaction_tween.set_parallel(true)

	interaction_tween.tween_property(
		self,
		"scale",
		Vector2(0.75, 0.75),
		0.2
	)

	interaction_tween.tween_property(
		self,
		"modulate:a",
		0.0,
		0.2
	)

	interaction_tween.set_parallel(false)

	interaction_tween.tween_callback(
		queue_free
	)


func _play_gather_sound() -> void:
	var selected_sound: AudioStream = null

	match resource_type:
		ResourceTypes.Type.WOOD:
			selected_sound = wood_gather_sound

		ResourceTypes.Type.STONE:
			selected_sound = stone_gather_sound

		ResourceTypes.Type.FOOD:
			selected_sound = food_gather_sound
	
	if selected_sound == null:
		return

	gather_sound.stream = selected_sound
	gather_sound.pitch_scale = randf_range( #change here for more heavy pitch vars
		0.6, 1.5
		#0.94,
		#1.06
	)

	gather_sound.play()


func collect(requested_amount: int = 1) -> int:
	if is_depleted:
		return 0


	var gathered_amount := gather(
		requested_amount
	)

	if gathered_amount > 0:
		_play_gather_sound()

	return gathered_amount

func complete_gathering(
	requested_amount: int = 1
) -> int:
	if not is_gathering_complete():
		return 0

	var gathered_amount := collect(
		requested_amount
	)

	if gathered_amount > 0:
		gathering_elapsed = 0.0
		gathering_feedback_elapsed = 0.0

		_update_gathering_progress_bar()
		set_gathering_active(false)

	return gathered_amount
