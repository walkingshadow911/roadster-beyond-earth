class_name HUDController
extends CanvasLayer

var battery_bar: ProgressBar
var label_speed: Label
var label_distance: Label
var label_score: Label
var label_planet: Label
var popup_container: Control
var root: Control


func _ready() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var battery_label := Label.new()
	battery_label.text = "BATTERY"
	battery_label.position = Vector2(20, 18)
	root.add_child(battery_label)

	battery_bar = ProgressBar.new()
	battery_bar.min_value = 0
	battery_bar.max_value = 100
	battery_bar.value = 100
	battery_bar.position = Vector2(20, 40)
	battery_bar.size = Vector2(220, 24)
	battery_bar.show_percentage = false
	root.add_child(battery_bar)

	label_speed = Label.new()
	label_speed.position = Vector2(20, 72)
	root.add_child(label_speed)

	label_distance = Label.new()
	label_distance.position = Vector2(20, 98)
	root.add_child(label_distance)

	label_score = Label.new()
	label_score.add_theme_font_size_override("font_size", 22)
	label_score.position = Vector2(20, 126)
	root.add_child(label_score)

	label_planet = Label.new()
	label_planet.add_theme_font_size_override("font_size", 22)
	label_planet.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	label_planet.position = Vector2(-220, 20)
	root.add_child(label_planet)

	popup_container = Control.new()
	popup_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(popup_container)

	root.visible = false


func show_hud(planet_name: String) -> void:
	label_planet.text = planet_name
	root.visible = true


func hide_hud() -> void:
	root.visible = false


func update(battery: float, max_battery: float, speed: float, dist: float, score: float) -> void:
	battery_bar.max_value = max_battery
	battery_bar.value = battery
	label_speed.text = "SPEED  %d" % int(speed)
	label_distance.text = "DIST   %d m" % int(dist)
	label_score.text = "SCORE  %d" % int(score)


func show_popup(text: String, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", color)
	l.set_anchors_preset(Control.PRESET_CENTER_TOP)
	l.position = Vector2(-150, 160)
	popup_container.add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position:y", l.position.y - 50, 1.2)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.2)
	tw.tween_callback(l.queue_free)
