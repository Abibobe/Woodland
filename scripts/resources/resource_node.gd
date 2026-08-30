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


@onready var interaction_highlight: Node2D = (
	$InteractionHighlight
)

@onready var gather_sound: AudioStreamPlayer2D = (
	$GatherSound
)

const SHADOW_COLOR := Color(0.05, 0.08, 0.06, 0.32)
const HIGHLIGHT_COLOR := Color("#f2d479")
var is_highlighted: bool = false
var interaction_tween: Tween
var is_gather_animation_playing: bool = false
var is_depleted: bool = false


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()


func get_resource_name() -> String:
	return ResourceTypes.get_display_name(
		resource_type
	)


func get_interaction_text() -> String:
	return "E — Gather %s" % get_resource_name()


func interact() -> Dictionary:
	if is_gather_animation_playing or is_depleted:
		return {}

	var gathered_amount := gather(1)

	if gathered_amount <= 0:
		return {}
	
	_play_gather_sound()
	
	return {
		"action": "resource_collected",
		"resource_type": resource_type,
		"amount": gathered_amount,
		"target_depleted": is_depleted
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
