extends "res://scripts/interactable.gd"
## Paths avoid circular PackedScene references between bidirectionally linked rooms.
@export_file("*.tscn") var target_scene_path := ""
@export var target_spawn: StringName
## Empty means unrestricted. Keys live in session state and are never consumed here.
@export var required_key: StringName
@export var message_offset := Vector2(0, -120)
## Stair portals disable this while keeping the shared transition behavior.
@export var door_sound_enabled := true

func can_interact(context: Dictionary) -> bool:
	return enabled and not context["game"].transitioning and not target_scene_path.is_empty()

func interact(context: Dictionary) -> void:
	if not can_interact(context):
		return
	interacted.emit(context)
	if required_key != &"" and not context["state"].has_key(required_key):
		context["ui"].show_note("已上锁", global_position + message_offset, 4.0)
		return
	if door_sound_enabled:
		context["game"].bgm.play_sfx(&"door_open")
	# The old portal is freed during the fade; the persistent game owns completion.
	context["game"].change_level(target_scene_path, target_spawn)
