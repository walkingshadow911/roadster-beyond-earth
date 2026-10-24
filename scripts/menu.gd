class_name MenuController
extends CanvasLayer

signal planet_chosen(key: String)

var start_root: Control
var overlay_root: Control
var overlay_label: Label
var overlay_button: Button


func _ready() -> void:
	_build_start_screen()
	_build_overlay()


func _build_start_screen() -> void:
	start_root = Control.new()
	start_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(start_root)

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	start_root.add_child(panel)

	var title := Label.new()
	title.text = "ROADSTER: ORBITAL DRIFT"
	title.add_theme_font_size_override("font_size", 40)
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(-260, 90)
	start_root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Choose a world. Thrust = Space. Drive = Left/Right. Flip in the air for points."
	subtitle.set_anchors_preset(Control.PRESET_CENTER_TOP)
	subtitle.position = Vector2(-320, 150)
	start_root.add_child(subtitle)


func show_start_menu(planets: Dictionary) -> void:
	for c in start_root.get_children():
		if c is Button:
			c.queue_free()

	var keys := planets.keys()
	var i := 0
	for key in keys:
		var p: Dictionary = planets[key]
		var btn := Button.new()
		btn.text = "%s\ngravity x%.2f" % [p["name"], p["gravity_scale"]]
		btn.custom_minimum_size = Vector2(220, 90)
		btn.set_anchors_preset(Control.PRESET_CENTER)
		btn.position = Vector2(-360 + i * 260, -20)
		btn.pressed.connect(_on_planet_pressed.bind(key))
		start_root.add_child(btn)
		i += 1

	start_root.visible = true


func hide_start_menu() -> void:
	start_root.visible = false


func _on_planet_pressed(key: String) -> void:
	planet_chosen.emit(key)


func _build_overlay() -> void:
	overlay_root = Control.new()
	overlay_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_root.visible = false
	add_child(overlay_root)

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.modulate = Color(1, 1, 1, 0.85)
	overlay_root.add_child(panel)

	overlay_label = Label.new()
	overlay_label.add_theme_font_size_override("font_size", 32)
	overlay_label.set_anchors_preset(Control.PRESET_CENTER)
	overlay_label.position = Vector2(-300, -80)
	overlay_root.add_child(overlay_label)

	overlay_button = Button.new()
	overlay_button.custom_minimum_size = Vector2(220, 60)
	overlay_button.set_anchors_preset(Control.PRESET_CENTER)
	overlay_button.position = Vector2(-110, 20)
	overlay_root.add_child(overlay_button)


func show_overlay(text: String, button_text: String, on_press: Callable) -> void:
	overlay_label.text = text
	overlay_button.text = button_text
	for c in overlay_button.pressed.get_connections():
		overlay_button.pressed.disconnect(c["callable"])
	overlay_button.pressed.connect(on_press)
	overlay_root.visible = true


func hide_overlay() -> void:
	overlay_root.visible = false
