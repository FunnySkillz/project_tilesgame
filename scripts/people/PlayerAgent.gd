class_name PlayerAgent
extends RefCounted

const WALK_SPEED := 3.35

var position := Vector2.ZERO
var target := Vector2.ZERO
var last_direction := Vector2.DOWN


func setup(start_position: Vector2) -> PlayerAgent:
	position = start_position
	target = start_position
	last_direction = Vector2.DOWN
	return self


func tick(delta: float) -> void:
	var delta_to_target := target - position
	if delta_to_target.length() <= 0.01:
		return

	var move_distance := WALK_SPEED * delta
	if delta_to_target.length() <= move_distance:
		position = target
	else:
		position += delta_to_target.normalized() * move_distance
	last_direction = delta_to_target.normalized()


func set_target(next_target: Vector2) -> void:
	target = next_target


func is_at_target() -> bool:
	return position.distance_to(target) <= 0.05
