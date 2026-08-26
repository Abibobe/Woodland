class_name PlayerAnimation
extends AnimatedSprite2D


enum Facing {
	DOWN,
	UP,
	SIDE
}


@onready var player: Player = get_parent()


var last_facing: Facing = Facing.DOWN
var last_side_was_left: bool = false


func _process(_delta: float) -> void:
	var movement := player.velocity

	if movement.length_squared() > 0.0:
		_update_walking_animation(movement)
	else:
		_update_idle_animation()


func _update_walking_animation(
	movement: Vector2
) -> void:
	if absf(movement.x) > absf(movement.y):
		last_facing = Facing.SIDE
		last_side_was_left = movement.x < 0.0

		flip_h = last_side_was_left
		_play_if_changed("walk_side")
		return

	flip_h = false

	if movement.y < 0.0:
		last_facing = Facing.UP
		_play_if_changed("walk_up")
	else:
		last_facing = Facing.DOWN
		_play_if_changed("walk_down")


func _update_idle_animation() -> void:
	match last_facing:
		Facing.DOWN:
			flip_h = false
			_play_if_changed("idle_down")

		Facing.UP:
			flip_h = false
			_play_if_changed("idle_up")

		Facing.SIDE:
			flip_h = last_side_was_left
			_play_if_changed("idle_side")


func _play_if_changed(
	animation_name: StringName
) -> void:
	if animation == animation_name:
		return

	play(animation_name)
