class_name PadController
extends Node

signal charged
signal boosted
signal docked

const DOCK_MAX_SPEED := 110.0
const DOCK_MAX_ANGLE := 0.22        # radians, ~12.6 degrees
const DOCK_HOLD_TIME := 1.1
const SPAWN_LIFT := 60.0            # how far above a pad the car respawns from

const BOOST_FORWARD := 420.0        # forward speed kick, in the car's facing direction
const BOOST_LIFT := 160.0           # upward kick, in world space, so it launches even off a flat pad

var track: TrackGenerator
var car: Car
var dock_area: Area2D
var dock_timer := 0.0
var docked_done := false


func setup(p_track: TrackGenerator, p_car: Car) -> void:
	track = p_track
	car = p_car

	for pad in track.pads:
		var area: Area2D = pad["area"]
		match pad["type"]:
			"charge":
				area.body_entered.connect(_on_charge_entered.bind(area))
			"boost":
				area.body_entered.connect(_on_boost_entered)
			_:
				dock_area = area


func _on_charge_entered(body: Node, area: Area2D) -> void:
	if body != car:
		return
	car.battery = min(Car.MAX_BATTERY, car.battery + 45.0)
	car.spawn_position = area.global_position - Vector2(0, SPAWN_LIFT)
	charged.emit()


func _on_boost_entered(body: Node) -> void:
	if body != car:
		return
	var impulse := Vector2.RIGHT.rotated(car.rotation) * BOOST_FORWARD + Vector2.UP * BOOST_LIFT
	car.apply_central_impulse(impulse)
	boosted.emit()


func _process(delta: float) -> void:
	if not dock_area or docked_done:
		return

	var overlapping := false
	for b in dock_area.get_overlapping_bodies():
		if b == car:
			overlapping = true
			break

	if not overlapping:
		dock_timer = 0.0
		return

	var angle_ok: bool = abs(wrapf(car.rotation, -PI, PI)) < DOCK_MAX_ANGLE
	var speed_ok: bool = car.linear_velocity.length() < DOCK_MAX_SPEED
	var grounded_ok: bool = car.grounded

	if angle_ok and speed_ok and grounded_ok:
		dock_timer += delta
		if dock_timer >= DOCK_HOLD_TIME:
			docked_done = true
			docked.emit()
	else:
		dock_timer = 0.0
