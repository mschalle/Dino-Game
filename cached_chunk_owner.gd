extends Node

# Keep detached scene ownership tied to the world even if its stream manager
# is retained by signals during shutdown.
var chunk: Node3D

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and is_instance_valid(chunk):
		chunk.free()
