class_name FishAgent
extends RefCounted

var position := Vector2.ZERO
var velocity := Vector2.ZERO
var fish_kind := 0
var turn_timer := 0.0
var wiggle_phase := 0.0


func setup(start_position: Vector2, start_velocity: Vector2, kind: int) -> FishAgent:
	position = start_position
	fish_kind = kind
	velocity = _normalized_or_random(start_velocity) * _preferred_speed()
	turn_timer = _next_turn_delay()
	wiggle_phase = randf_range(0.0, TAU)
	return self


func tick(delta: float, water_min: Vector2, water_max: Vector2, boat_position: Vector2) -> void:
	turn_timer -= delta
	wiggle_phase += delta * _wiggle_speed()

	var desired_velocity := _wander_velocity()
	var away_from_boat := position - boat_position
	if away_from_boat.length() < _flee_radius() and away_from_boat.length() > 0.001:
		desired_velocity = away_from_boat.normalized() * _panic_speed()

	velocity = velocity.lerp(desired_velocity, clamp(delta * _turn_response(), 0.0, 1.0))
	var swim_velocity := velocity
	if fish_kind == 0 and velocity.length() > 0.001:
		swim_velocity += velocity.normalized().orthogonal() * sin(wiggle_phase) * 0.09
	position += swim_velocity * delta

	if position.x < water_min.x:
		position.x = water_min.x
		velocity.x = abs(velocity.x)
	elif position.x > water_max.x:
		position.x = water_max.x
		velocity.x = -abs(velocity.x)

	if position.y < water_min.y:
		position.y = water_min.y
		velocity.y = abs(velocity.y)
	elif position.y > water_max.y:
		position.y = water_max.y
		velocity.y = -abs(velocity.y)


func _wander_velocity() -> Vector2:
	if turn_timer > 0.0 and velocity.length() > 0.001:
		return velocity.normalized() * _preferred_speed()

	turn_timer = _next_turn_delay()
	var angle := randf_range(-_turn_angle(), _turn_angle())
	var direction := _normalized_or_random(velocity).rotated(angle)
	if fish_kind == 2 and randf() < 0.55:
		return direction * _panic_speed()
	return direction * _preferred_speed()


func _preferred_speed() -> float:
	match fish_kind:
		2:
			return 0.82
		1:
			return 0.48
		_:
			return 0.38


func _panic_speed() -> float:
	match fish_kind:
		2:
			return 1.45
		1:
			return 0.7
		_:
			return 0.58


func _flee_radius() -> float:
	match fish_kind:
		2:
			return 1.45
		1:
			return 0.85
		_:
			return 1.05


func _turn_response() -> float:
	match fish_kind:
		2:
			return 5.0
		1:
			return 1.35
		_:
			return 2.4


func _turn_angle() -> float:
	match fish_kind:
		2:
			return 1.75
		1:
			return 0.45
		_:
			return 0.9


func _next_turn_delay() -> float:
	match fish_kind:
		2:
			return randf_range(0.25, 0.75)
		1:
			return randf_range(1.8, 3.2)
		_:
			return randf_range(0.75, 1.45)


func _wiggle_speed() -> float:
	match fish_kind:
		2:
			return 9.0
		1:
			return 2.0
		_:
			return 5.5


func _normalized_or_random(vector: Vector2) -> Vector2:
	if vector.length() > 0.001:
		return vector.normalized()
	var angle := randf_range(0.0, TAU)
	return Vector2(cos(angle), sin(angle))
