class_name TrackGenerator
extends Node2D

const TRACK_LENGTH := 9000.0
const STEP := 60.0
const TERRAIN_DEPTH := 1400.0
const BASE_Y := 600.0
const CAP_HEIGHT := 14.0
const FLAT_BLEND := 160.0
const PAD_FLAT_WIDTH := 220.0
const TEXTURE_TILE_SIZE := 128.0
const CITY_BG_SCALE := 0.7
const CITY_BG_Y_OFFSET := 280.0

var planet: Dictionary
var planet_key: String
var ground_texture: ImageTexture

var gaps: Array = []
var flat_zones: Array = []
var pads: Array = []


func generate(p: Dictionary, key: String) -> void:
	planet = p
	planet_key = key
	gaps.clear()
	flat_zones.clear()
	pads.clear()

	for c in get_children():
		c.queue_free()

	ground_texture = _build_ground_texture()
	_plan_track()
	_build_background()
	_build_terrain()


func _build_ground_texture() -> ImageTexture:
	var size := int(TEXTURE_TILE_SIZE)
	var noise := FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.06
	noise.fractal_octaves = 4

	var base_color: Color = planet["ground"]
	var top_color: Color = planet["ground_top"]

	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in range(size):
		for x in range(size):
			var n := noise.get_noise_2d(float(x), float(y))
			var t: float = clamp((n + 1.0) * 0.5, 0.0, 1.0)
			var speckle := randf_range(-0.045, 0.045)
			var c := base_color.lerp(top_color, t * 0.35)
			c = Color(
				clamp(c.r + speckle, 0.0, 1.0),
				clamp(c.g + speckle, 0.0, 1.0),
				clamp(c.b + speckle, 0.0, 1.0),
			)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


func height_at(x: float) -> float:
	for z in flat_zones:
		var z0: float = z[0]
		var z1: float = z[1]
		if x >= z0 - FLAT_BLEND and x <= z1 + FLAT_BLEND:
			var flat_y := _raw_height((z0 + z1) * 0.5)
			if x < z0:
				var t: float = clamp((x - (z0 - FLAT_BLEND)) / FLAT_BLEND, 0.0, 1.0)
				return lerp(_raw_height(x), flat_y, smoothstep(0.0, 1.0, t))
			elif x > z1:
				var t2: float = clamp(((z1 + FLAT_BLEND) - x) / FLAT_BLEND, 0.0, 1.0)
				return lerp(_raw_height(x), flat_y, smoothstep(0.0, 1.0, t2))
			else:
				return flat_y
	return _raw_height(x)


func is_in_gap(x: float) -> bool:
	for g in gaps:
		if x >= g[0] and x <= g[1]:
			return true
	return false


func _raw_height(x: float) -> float:
	var amp: float = planet["amplitude"]
	return BASE_Y - (
		sin(x * 0.0025) * 120.0
		+ sin(x * 0.0009 + 1.3) * 220.0
		+ sin(x * 0.004 + 3.0) * 40.0
	) * amp


func _plan_track() -> void:
	flat_zones.append([-500.0, 500.0])

	var gap_w: float = planet["gap_width"]
	var x := 1800.0
	var gap_index := 0
	while x < TRACK_LENGTH - 900.0:
		if gap_index % 2 == 1:
			var boost_x: float = x - 180.0
			flat_zones.append([boost_x - 140.0, boost_x + 140.0])
			pads.append({"x": boost_x, "type": "boost"})

		gaps.append([x, x + gap_w])
		var pad_x: float = x + gap_w + 260.0
		flat_zones.append([pad_x - PAD_FLAT_WIDTH, pad_x + PAD_FLAT_WIDTH])
		pads.append({"x": pad_x, "type": "charge"})
		gap_index += 1
		x = pad_x + 1800.0 + randf() * 900.0

	flat_zones.append([TRACK_LENGTH - 600.0, TRACK_LENGTH + 200.0])
	pads.append({"x": TRACK_LENGTH - 250.0, "type": "dock"})


func _build_background() -> void:
	var bg := Node2D.new()
	bg.name = "Background"
	bg.z_index = -10
	add_child(bg)

	var sky := Polygon2D.new()
	sky.polygon = PackedVector2Array([
		Vector2(-600, -1200), Vector2(TRACK_LENGTH + 600, -1200),
		Vector2(TRACK_LENGTH + 600, 3000), Vector2(-600, 3000),
	])
	sky.color = planet["sky_bottom"]
	bg.add_child(sky)

	var sky_top := Polygon2D.new()
	sky_top.polygon = PackedVector2Array([
		Vector2(-600, -1200), Vector2(TRACK_LENGTH + 600, -1200),
		Vector2(TRACK_LENGTH + 600, -200), Vector2(-600, -200),
	])
	sky_top.color = planet["sky_top"]
	bg.add_child(sky_top)

	if planet_key != "earth":
		for i in range(140):
			var star := Polygon2D.new()
			var s := randf_range(1.5, 3.0)
			star.polygon = PackedVector2Array([
				Vector2(-s, -s), Vector2(s, -s), Vector2(s, s), Vector2(-s, s),
			])
			star.color = Color(1, 1, 1, randf_range(0.3, 0.9))
			star.position = Vector2(randf_range(-500, TRACK_LENGTH + 500), randf_range(-1100, -250))
			bg.add_child(star)

	_build_city_skyline(bg)


func _build_city_skyline(parent: Node2D) -> void:
	var city_texture := load("res://assets/background_city.png") as Texture2D
	if not city_texture:
		return

	var tile_w: float = city_texture.get_width() * CITY_BG_SCALE
	var start_x := -600.0
	var count := int(ceil((TRACK_LENGTH + 1200.0) / tile_w)) + 1
	for i in range(count):
		var spr := Sprite2D.new()
		spr.texture = city_texture
		spr.centered = false
		spr.scale = Vector2(CITY_BG_SCALE, CITY_BG_SCALE)
		spr.position = Vector2(start_x + i * tile_w, CITY_BG_Y_OFFSET)
		spr.modulate = Color(1, 1, 1, 0.8)
		parent.add_child(spr)


func _build_terrain() -> void:
	var terrain := Node2D.new()
	terrain.name = "Terrain"
	terrain.z_index = -5
	add_child(terrain)

	var x := -500.0
	var prev_point: Variant = null
	while x <= TRACK_LENGTH + 200.0:
		if is_in_gap(x):
			prev_point = null
			x += STEP
			continue
		var p := Vector2(x, height_at(x))
		if prev_point != null:
			_add_terrain_segment(terrain, prev_point, p)
		prev_point = p
		x += STEP

	for pad in pads:
		_add_pad(terrain, pad)


func _add_terrain_segment(parent: Node2D, p0: Vector2, p1: Vector2) -> void:
	var quad := PackedVector2Array([
		p0, p1,
		Vector2(p1.x, p1.y + TERRAIN_DEPTH),
		Vector2(p0.x, p0.y + TERRAIN_DEPTH),
	])

	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionPolygon2D.new()
	col.polygon = quad
	body.add_child(col)
	parent.add_child(body)

	var jitter: float = randf_range(-0.04, 0.04)
	var ground_color: Color = planet["ground"]
	var base_color := Color(
		clamp(ground_color.r + jitter, 0.0, 1.0),
		clamp(ground_color.g + jitter, 0.0, 1.0),
		clamp(ground_color.b + jitter, 0.0, 1.0),
	)

	var poly := Polygon2D.new()
	poly.polygon = quad
	poly.color = base_color
	poly.texture = ground_texture
	poly.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var uv := PackedVector2Array()
	for v in quad:
		uv.append(v / TEXTURE_TILE_SIZE)
	poly.uv = uv
	parent.add_child(poly)

	var top_color: Color = planet["ground_top"]
	var mid_h := 70.0
	var mid := Polygon2D.new()
	mid.polygon = PackedVector2Array([
		p0, p1,
		Vector2(p1.x, p1.y + mid_h), Vector2(p0.x, p0.y + mid_h),
	])
	mid.color = top_color.lerp(base_color, 0.6)
	parent.add_child(mid)

	var cap := Polygon2D.new()
	cap.polygon = PackedVector2Array([
		p0, p1,
		Vector2(p1.x, p1.y + CAP_HEIGHT), Vector2(p0.x, p0.y + CAP_HEIGHT),
	])
	cap.color = top_color
	parent.add_child(cap)


func _add_pad(parent: Node2D, pad: Dictionary) -> void:
	var px: float = pad["x"]
	var py := height_at(px)
	var pad_type: String = pad["type"]
	var w := 90.0

	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-w, -6), Vector2(w, -6), Vector2(w, 6), Vector2(-w, 6),
	])
	match pad_type:
		"dock":
			visual.color = Color(1.0, 0.85, 0.2)
		"boost":
			visual.color = Color(0.85, 0.2, 1.0)
		_:
			visual.color = Color(0.2, 0.9, 1.0)
	visual.position = Vector2(px, py - 6)
	parent.add_child(visual)

	var area := Area2D.new()
	area.collision_layer = 4
	area.collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w * 2.0, 60.0)
	shape.shape = rect
	shape.position = Vector2(0, -30)
	area.add_child(shape)
	area.position = Vector2(px, py)
	parent.add_child(area)

	pad["area"] = area
