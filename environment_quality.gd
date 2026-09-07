class_name EnvironmentQuality
extends RefCounted

const PRESETS := {
	"low": {"foliage": 0.55, "effects": 0.45, "shadow_distance": 20.0, "fog": 0.75},
	"medium": {"foliage": 1.0, "effects": 1.0, "shadow_distance": 45.0, "fog": 1.0},
	"high": {"foliage": 1.35, "effects": 1.35, "shadow_distance": 70.0, "fog": 1.15}
}

static var active_id: String = "medium"
static var weather_enabled: bool = true
static var reduced_motion: bool = false

static func configure(settings: Dictionary) -> void:
	var requested := str(settings.get("environment_quality", "medium"))
	active_id = requested if PRESETS.has(requested) else "medium"
	weather_enabled = bool(settings.get("weather_enabled", true))
	reduced_motion = bool(settings.get("reduced_motion", false))

static func preset(settings: Dictionary) -> Dictionary:
	var id := active_id if settings.is_empty() else str(settings.get("environment_quality", active_id))
	return (PRESETS.get(id, PRESETS["medium"]) as Dictionary).duplicate(true)

static func next(current: String) -> String:
	match current:
		"low": return "medium"
		"medium": return "high"
		_: return "low"
