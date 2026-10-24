class_name PlanetData
extends RefCounted


static func get_all() -> Dictionary:
	return {
		"earth": {
			"name": "Earth",
			"gravity_scale": 1.0,
			"amplitude": 1.0,
			"gap_width": 230.0,
			"sky_top": Color(0.04, 0.07, 0.18),
			"sky_bottom": Color(0.45, 0.62, 0.85),
			"ground": Color(0.32, 0.22, 0.14),
			"ground_top": Color(0.25, 0.55, 0.22),
		},
		"moon": {
			"name": "Moon",
			"gravity_scale": 0.16,
			"amplitude": 0.55,
			"gap_width": 360.0,
			"sky_top": Color(0.0, 0.0, 0.02),
			"sky_bottom": Color(0.04, 0.04, 0.08),
			"ground": Color(0.45, 0.45, 0.48),
			"ground_top": Color(0.62, 0.62, 0.65),
		},
		"mars": {
			"name": "Mars",
			"gravity_scale": 0.38,
			"amplitude": 1.25,
			"gap_width": 290.0,
			"sky_top": Color(0.12, 0.03, 0.02),
			"sky_bottom": Color(0.55, 0.26, 0.14),
			"ground": Color(0.5, 0.22, 0.12),
			"ground_top": Color(0.68, 0.36, 0.18),
		},
	}
