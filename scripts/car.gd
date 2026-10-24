class_name Car
extends RigidBody2D

signal crashed
signal trick_scored(points: int, label: String)
signal landed(air_time: float)

const MAX_BATTERY := 100.0
const DRIVE_DRAIN := 3.0          # battery/sec while driving
const THRUST_DRAIN := 22.0        # battery/sec while thrusting

const DRIVE_FORCE := 2600.0       # forward push while grounded + accelerating
const DRIVE_TORQUE := 1800.0      # arcade "nose lifts under gas" lean
const AIR_TORQUE := 2600.0        # mid-air spin speed for tricks
const THRUST_FORCE := 3400.0      # upward push while thrusting

const SPRING_K := 60.0          # suspension stiffness
const SPRING_DAMPING := 18.0     # suspension damping (less bounce)
const WHEEL_RADIUS := 16.0
const RIDE_HEIGHT := 46.0         # resting height above ground

const TRICK_DEADZONE := 0.35      # radians of air-rotation below which it's just a hop
const TRICK_TOLERANCE := 0.18     # how close to a clean 360 multiple counts as a landed flip

var battery: float = MAX_BATTERY
var spawn_position: Vector2 = Vector2.ZERO
var grounded := false
var wheel_front: RayCast2D
var wheel_rear: RayCast2D
var wheel_front_visual: Node2D
var wheel_rear_visual: Node2D
var thruster_flame: Polygon2D
var thruster_particles: GPUParticles2D
var thrust_sound: AudioStreamPlayer
var engine_sound: AudioStreamPlayer

var was_airborne := false
var air_start_rotation := 0.0
var air_time := 0.0


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 6
	collision_layer = 2
	collision_mask = 1
	linear_damp = 0.3
	angular_damp = 1.4
	body_entered.connect(_on_body_entered)

	_build_visuals()
	spawn_position = global_position


func _build_visuals() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(78, 24)
	shape.shape = rect
	add_child(shape)

	var body_poly := Polygon2D.new()
	body_poly.polygon = PackedVector2Array([
		Vector2(-45, 6), Vector2(-38, -10), Vector2(-5, -20),
		Vector2(28, -16), Vector2(45, -4), Vector2(45, 10), Vector2(-45, 10),
	])
	body_poly.color = Color(0.78, 0.05, 0.08)
	add_child(body_poly)

	var windshield := Polygon2D.new()
	windshield.polygon = PackedVector2Array([
		Vector2(-18, -10), Vector2(-2, -18), Vector2(14, -14), Vector2(10, -4), Vector2(-14, -2),
	])
	windshield.color = Color(0.55, 0.75, 0.85, 0.85)
	add_child(windshield)

	var rocker := Polygon2D.new()
	rocker.polygon = PackedVector2Array([
		Vector2(-40, 6), Vector2(40, 6), Vector2(40, 10), Vector2(-40, 10),
	])
	rocker.color = Color(0.08, 0.02, 0.02)
	add_child(rocker)

	var spoiler := Polygon2D.new()
	spoiler.polygon = PackedVector2Array([
		Vector2(30, -16), Vector2(44, -26), Vector2(48, -26), Vector2(42, -14),
	])
	spoiler.color = Color(0.08, 0.02, 0.02)
	add_child(spoiler)

	thruster_flame = Polygon2D.new()
	thruster_flame.polygon = PackedVector2Array([
		Vector2(-10, 10), Vector2(10, 10), Vector2(0, 42),
	])
	thruster_flame.color = Color(1.0, 0.55, 0.1, 0.9)
	thruster_flame.position = Vector2(-4, 0)
	thruster_flame.visible = false
	add_child(thruster_flame)

	thruster_particles = GPUParticles2D.new()
	thruster_particles.position = Vector2(-4, 14)
	thruster_particles.emitting = false
	thruster_particles.amount = 20
	thruster_particles.lifetime = 0.35
	thruster_particles.explosiveness = 0.0
	thruster_particles.local_coords = false
	thruster_particles.texture = _make_dot_texture(6, Color(1, 1, 1, 1))
	var thrust_mat := ParticleProcessMaterial.new()
	thrust_mat.direction = Vector3(0, 1, 0)
	thrust_mat.spread = 24.0
	thrust_mat.gravity = Vector3(0, 300, 0)
	thrust_mat.initial_velocity_min = 90.0
	thrust_mat.initial_velocity_max = 170.0
	thrust_mat.scale_min = 0.5
	thrust_mat.scale_max = 1.1
	thrust_mat.color = Color(1.0, 0.55, 0.12, 0.9)
	thruster_particles.process_material = thrust_mat
	add_child(thruster_particles)

	thrust_sound = AudioStreamPlayer.new()
	thrust_sound.stream = AudioFX.make_noise_loop(0.3, 0.35)
	thrust_sound.volume_db = -6.0
	add_child(thrust_sound)

	engine_sound = AudioStreamPlayer.new()
	engine_sound.stream = AudioFX.make_hum_loop(70.0, 0.25, 0.3)
	engine_sound.volume_db = -14.0
	add_child(engine_sound)

	wheel_rear = RayCast2D.new()
	wheel_rear.position = Vector2(-30, 8)
	wheel_rear.target_position = Vector2(0, RIDE_HEIGHT)
	wheel_rear.collision_mask = 1
	wheel_rear.enabled = true
	add_child(wheel_rear)

	wheel_front = RayCast2D.new()
	wheel_front.position = Vector2(30, 8)
	wheel_front.target_position = Vector2(0, RIDE_HEIGHT)
	wheel_front.collision_mask = 1
	wheel_front.enabled = true
	add_child(wheel_front)

	wheel_rear_visual = _make_wheel_visual()
	wheel_rear_visual.position = Vector2(-30, 8)
	add_child(wheel_rear_visual)

	wheel_front_visual = _make_wheel_visual()
	wheel_front_visual.position = Vector2(30, 8)
	add_child(wheel_front_visual)


func _make_dot_texture(size: int, color: Color) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size / 2.0, size / 2.0)
	var radius := size / 2.0
	for y in range(size):
		for x in range(size):
			if Vector2(x + 0.5, y + 0.5).distance_to(center) <= radius:
				img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)


func _make_wheel_visual() -> Node2D:
	var n := Node2D.new()
	var rim := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in range(12):
		var a := TAU * float(i) / 12.0
		pts.append(Vector2(cos(a), sin(a)) * WHEEL_RADIUS)
	rim.polygon = pts
	rim.color = Color(0.05, 0.05, 0.05)
	n.add_child(rim)
	var hub := Polygon2D.new()
	var hpts := PackedVector2Array()
	for i in range(8):
		var a2 := TAU * float(i) / 8.0
		hpts.append(Vector2(cos(a2), sin(a2)) * (WHEEL_RADIUS * 0.4))
	hub.polygon = hpts
	hub.color = Color(0.6, 0.6, 0.65)
	n.add_child(hub)
	return n


func _physics_process(delta: float) -> void:
	wheel_front.force_raycast_update()
	wheel_rear.force_raycast_update()
	var grounded_front := wheel_front.is_colliding()
	var grounded_rear := wheel_rear.is_colliding()
	grounded = grounded_front or grounded_rear

	_apply_suspension(wheel_front, grounded_front)
	_apply_suspension(wheel_rear, grounded_rear)

	var accel := 0.0
	if Input.is_action_pressed("ui_right"):
		accel += 1.0
	if Input.is_action_pressed("ui_left"):
		accel -= 1.0
	var thrust := Input.is_action_pressed("ui_accept") and battery > 0.0

	if grounded:
		if accel != 0.0:
			apply_central_force(Vector2.RIGHT.rotated(rotation) * DRIVE_FORCE * accel)
			apply_torque(DRIVE_TORQUE * accel)
			battery = max(0.0, battery - DRIVE_DRAIN * delta)
		var spin: float = linear_velocity.length() * 0.05 * (sign(accel) if accel != 0.0 else 1.0)
		wheel_front_visual.rotation += spin * delta
		wheel_rear_visual.rotation += spin * delta
	else:
		if accel != 0.0:
			apply_torque(AIR_TORQUE * accel)

	if grounded and accel != 0.0:
		if not engine_sound.playing:
			engine_sound.play()
	elif engine_sound.playing:
		engine_sound.stop()

	if thrust:
		apply_central_force(Vector2.UP.rotated(rotation) * THRUST_FORCE)
		battery = max(0.0, battery - THRUST_DRAIN * delta)
		if not thrust_sound.playing:
			thrust_sound.play()
	elif thrust_sound.playing:
		thrust_sound.stop()
	thruster_flame.visible = thrust
	thruster_particles.emitting = thrust

	_update_trick_state(grounded, delta)


func _apply_suspension(ray: RayCast2D, is_grounded: bool) -> void:
	if not is_grounded:
		return
	var hit_point: Vector2 = ray.get_collision_point()
	var normal: Vector2 = ray.get_collision_normal()
	var wheel_pos: Vector2 = ray.global_position
	var current_length: float = wheel_pos.distance_to(hit_point)
	var compression: float = RIDE_HEIGHT - current_length
	if compression < 0.0:
		return
	var closing_speed: float = linear_velocity.dot(normal)
	var force_mag: float = compression * SPRING_K - closing_speed * SPRING_DAMPING
	force_mag = max(0.0, force_mag)
	var offset: Vector2 = wheel_pos - global_position
	apply_force(normal * force_mag, offset)


func _update_trick_state(grounded: bool, delta: float) -> void:
	if not grounded:
		if not was_airborne:
			was_airborne = true
			air_start_rotation = rotation
			air_time = 0.0
		air_time += delta
	else:
		if was_airborne:
			was_airborne = false
			landed.emit(air_time)
			_evaluate_landing()


func _evaluate_landing() -> void:
	var rotation_delta: float = rotation - air_start_rotation

	if abs(rotation_delta) < TRICK_DEADZONE:
		return

	var flips: float = rotation_delta / TAU
	var nearest: float = round(flips)
	var remainder: float = abs(flips - nearest)

	if remainder <= TRICK_TOLERANCE:
		if int(nearest) != 0:
			var n := int(abs(nearest))
			var pts := n * 1000
			var label := "FLIP!" if n == 1 else "KICKFLIP x%d!" % n
			trick_scored.emit(pts, label)
	else:
		_on_crash()


func _on_body_entered(body: Node) -> void:
	if body is StaticBody2D:
		_on_crash()


func _on_crash() -> void:
	crashed.emit()


func respawn() -> void:
	global_position = spawn_position
	rotation = 0.0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	battery = max(battery, 35.0)
