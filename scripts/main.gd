extends Node2D

enum State { MENU, PLAYING, CRASHED, DOCKED }

var state: int = State.MENU
var planets: Dictionary
var planet: Dictionary
var planet_key: String = "earth"

var track: TrackGenerator
var car: Car
var pads: PadController
var camera: Camera2D

var hud: HUDController
var menu: MenuController
var audio: AudioFX

var score: float = 0.0
var distance: float = 0.0
var shake_strength: float = 0.0


func _ready() -> void:
	planets = PlanetData.get_all()

	hud = HUDController.new()
	add_child(hud)

	menu = MenuController.new()
	add_child(menu)
	menu.planet_chosen.connect(_on_planet_chosen)

	audio = AudioFX.new()
	add_child(audio)

	menu.show_start_menu(planets)


func _on_planet_chosen(key: String) -> void:
	planet_key = key
	planet = planets[key]
	_start_game()


func _start_game() -> void:
	if track:
		track.queue_free()
	if car:
		car.queue_free()
	if pads:
		pads.queue_free()
	if camera:
		camera.queue_free()

	score = 0.0
	distance = 0.0

	track = TrackGenerator.new()
	add_child(track)
	track.generate(planet, planet_key)

	car = Car.new()
	car.gravity_scale = planet["gravity_scale"]
	add_child(car)
	var start_x := 0.0
	car.global_position = Vector2(start_x, track.height_at(start_x) - 60.0)
	car.spawn_position = car.global_position
	car.trick_scored.connect(_on_trick_scored)
	car.crashed.connect(_on_crashed)

	pads = PadController.new()
	add_child(pads)
	pads.setup(track, car)
	pads.charged.connect(_on_charged)
	pads.boosted.connect(_on_boosted)
	pads.docked.connect(_on_docked)

	camera = Camera2D.new()
	camera.zoom = Vector2(0.85, 0.85)
	add_child(camera)
	camera.global_position = car.global_position

	menu.hide_start_menu()
	menu.hide_overlay()
	hud.show_hud(planet["name"])
	state = State.PLAYING


func _process(delta: float) -> void:
	if state == State.MENU:
		return

	if car and camera:
		var target: Vector2 = car.global_position + Vector2(140, -80)
		var shake_offset := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_strength
		camera.global_position = camera.global_position.lerp(target, 0.08) + shake_offset
		shake_strength = lerp(shake_strength, 0.0, delta * 6.0)

	if state == State.PLAYING and car:
		distance = max(distance, car.global_position.x)
		hud.update(car.battery, Car.MAX_BATTERY, car.linear_velocity.length() * 0.05, distance * 0.05, score)


func _on_trick_scored(points: int, label: String) -> void:
	score += points
	hud.show_popup("%s +%d" % [label, points], Color(1.0, 0.85, 0.2))
	_spawn_burst(car.global_position, Color(1.0, 0.85, 0.2))
	audio.play_trick()


func _on_charged() -> void:
	hud.show_popup("+ SUPERCHARGE", Color(0.2, 0.9, 1.0))
	_spawn_burst(car.global_position, Color(0.2, 0.9, 1.0))
	audio.play_charge()


func _on_boosted() -> void:
	hud.show_popup("LUDICROUS BOOST!", Color(0.85, 0.2, 1.0))
	_spawn_burst(car.global_position, Color(0.85, 0.2, 1.0))
	audio.play_boost()


func _on_crashed() -> void:
	if state != State.PLAYING:
		return
	state = State.CRASHED
	score = max(0.0, score - 300.0)
	car.freeze = true
	shake_strength = 20.0
	audio.play_crash()
	menu.show_overlay("CRASHED", "Respawn", _on_respawn_pressed)


func _on_respawn_pressed() -> void:
	car.respawn()
	car.freeze = false
	menu.hide_overlay()
	state = State.PLAYING


func _on_docked() -> void:
	if state != State.PLAYING:
		return
	state = State.DOCKED
	score += 5000.0
	car.freeze = true
	audio.play_dock()
	menu.show_overlay("DOCKED! MISSION COMPLETE\nScore: %d" % int(score), "Back to Menu", _on_back_to_menu)


func _on_back_to_menu() -> void:
	menu.hide_overlay()
	hud.hide_hud()
	state = State.MENU
	menu.show_start_menu(planets)


func _spawn_burst(pos: Vector2, color: Color) -> void:
	var burst := GPUParticles2D.new()
	burst.global_position = pos
	burst.emitting = true
	burst.one_shot = true
	burst.amount = 28
	burst.lifetime = 0.5
	burst.explosiveness = 1.0
	burst.local_coords = false
	burst.texture = _make_dot_texture(6, Color(1, 1, 1, 1))

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.gravity = Vector3(0, 400, 0)
	mat.initial_velocity_min = 60.0
	mat.initial_velocity_max = 220.0
	mat.scale_min = 0.6
	mat.scale_max = 1.4
	mat.color = color
	burst.process_material = mat

	add_child(burst)
	get_tree().create_timer(burst.lifetime + 0.2).timeout.connect(burst.queue_free)


func _make_dot_texture(size: int, color: Color) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size / 2.0, size / 2.0)
	var radius := size / 2.0
	for y in range(size):
		for x in range(size):
			if Vector2(x + 0.5, y + 0.5).distance_to(center) <= radius:
				img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)
