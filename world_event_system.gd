class_name WorldEventSystem
extends RefCounted

signal event_started(event_id: String, duration_seconds: float)
signal event_finished(event_id: String)

const FRESH_GROWTH := "fresh_growth"
const HERD_JOURNEY := "herd_journey"
const PREDATOR_PASSAGE := "predator_passage"

static func field_guide_text(event_id: String) -> String:
	match event_id:
		FRESH_GROWTH:
			return "Fresh Growth: rain and sunlight briefly bring extra edible plants to the valley."
		HERD_JOURNEY:
			return "Herd Journey: a herd moves together to a safer feeding meadow."
		PREDATOR_PASSAGE:
			return "Predator Passage: a predator crosses a marked route; give it room and use a safe retreat."
	return ""

var active_event_id := ""
var remaining_seconds := 0.0

func start(event_id: String, duration_seconds: float) -> bool:
	if event_id not in [FRESH_GROWTH, HERD_JOURNEY, PREDATOR_PASSAGE] or duration_seconds <= 0.0 or not active_event_id.is_empty():
		return false
	active_event_id = event_id
	remaining_seconds = duration_seconds
	event_started.emit(active_event_id, remaining_seconds)
	return true

func tick(delta: float) -> bool:
	if active_event_id.is_empty():
		return false
	remaining_seconds = maxf(0.0, remaining_seconds - delta)
	if remaining_seconds > 0.0:
		return false
	var finished_id := active_event_id
	active_event_id = ""
	event_finished.emit(finished_id)
	return true

func cancel() -> String:
	var cancelled_id := active_event_id
	active_event_id = ""
	remaining_seconds = 0.0
	return cancelled_id

func is_active(event_id: String) -> bool:
	return active_event_id == event_id
