class_name WorldEventSystem
extends RefCounted

signal event_started(event_id: String, duration_seconds: float)
signal event_finished(event_id: String)

const FRESH_GROWTH := "fresh_growth"
const HERD_JOURNEY := "herd_journey"

var active_event_id := ""
var remaining_seconds := 0.0

func start(event_id: String, duration_seconds: float) -> bool:
	if event_id not in [FRESH_GROWTH, HERD_JOURNEY] or duration_seconds <= 0.0 or not active_event_id.is_empty():
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

func is_active(event_id: String) -> bool:
	return active_event_id == event_id
