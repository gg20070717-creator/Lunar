extends "res://scripts/inspect_object.gd"
## Unlock the room in-place; the session flag restores the open gate on return.
@export var required_key: StringName = &"storage_key_02"
@export var opened_event: StringName = &"storage_room_opened"
## Keep the locked interior concealed while its physical walls still block movement.
@export var room_visual_paths: Array[NodePath] = []
@export var room_interaction_paths: Array[NodePath] = []

func can_interact(context: Dictionary) -> bool:
	var opened: bool = context["state"].has_seen_story_event(opened_event)
	_sync_gate(opened)
	return super.can_interact(context) and not opened and not context["game"].transitioning

func interact(context: Dictionary) -> void:
	if context["ui"].modal_open or not can_interact(context):
		return
	interacted.emit(context)
	if not context["state"].has_key(required_key):
		context["ui"].show_note("已上锁", global_position + Vector2(0, -100), 4.0)
		return
	context["state"].mark_story_event_seen(opened_event)
	_sync_gate(true)
	set_highlight(false)

func _sync_gate(opened: bool) -> void:
	for path: NodePath in room_visual_paths:
		var visual := get_node_or_null(path) as CanvasItem
		if visual != null:
			visual.visible = opened
	for path: NodePath in room_interaction_paths:
		var interaction := get_node_or_null(path)
		if interaction != null:
			interaction.set("enabled", opened)
	var gate := get_node_or_null(visual_path) as Node2D
	if gate == null:
		return
	if bool(gate.get("solid")) == opened:
		gate.set("solid", not opened)
	gate.visible = not opened
