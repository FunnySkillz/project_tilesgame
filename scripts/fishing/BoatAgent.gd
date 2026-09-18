class_name BoatAgent
extends RefCounted

const BASE_SPEED := 2.2
const SPEED_PER_LEVEL := 0.35
const BASE_NET_LENGTH := 0.45
const NET_LENGTH_PER_LEVEL := 0.16
const BASE_NET_RADIUS := 0.28
const NET_RADIUS_PER_LEVEL := 0.08
const BASE_NET_CAPACITY := 4
const NET_CAPACITY_PER_LEVEL := 3
const HOLD_CAPACITY_PER_LEVEL := 2

var position := Vector2.ZERO
var target := Vector2.ZERO
var last_direction := Vector2.DOWN
var fish_stock: Array = [0, 0, 0]
var level := 1


func setup(dock_position: Vector2) -> BoatAgent:
	position = dock_position
	target = dock_position
	last_direction = Vector2.DOWN
	fish_stock = [0, 0, 0]
	level = 1
	return self


func tick(delta: float) -> void:
	var delta_to_target := target - position
	if delta_to_target.length() <= 0.01:
		return

	var move_distance := speed() * delta
	if delta_to_target.length() <= move_distance:
		position = target
	else:
		position += delta_to_target.normalized() * move_distance
	last_direction = delta_to_target.normalized()


func set_target(next_target: Vector2) -> void:
	target = next_target


func is_at(point: Vector2) -> bool:
	return position.distance_to(point) <= 0.08


func speed() -> float:
	return BASE_SPEED + float(level - 1) * SPEED_PER_LEVEL


func direction() -> Vector2:
	if last_direction.length() <= 0.001:
		return Vector2.DOWN
	return last_direction.normalized()


func net_center(net_level: int) -> Vector2:
	return position - direction() * net_length(net_level)


func net_length(net_level: int) -> float:
	return BASE_NET_LENGTH + float(net_level) * NET_LENGTH_PER_LEVEL


func net_radius(net_level: int) -> float:
	return BASE_NET_RADIUS + float(net_level) * NET_RADIUS_PER_LEVEL


func net_capacity(net_level: int) -> int:
	return BASE_NET_CAPACITY + net_level * NET_CAPACITY_PER_LEVEL + (level - 1) * HOLD_CAPACITY_PER_LEVEL


func net_count() -> int:
	var total := 0
	for amount in fish_stock:
		total += int(amount)
	return total


func upgrade() -> void:
	level += 1
