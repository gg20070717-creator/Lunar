extends Node
## Session state survives level replacement; saves store stable IDs as JSON strings.
signal fragment_acquired(fragment_id: StringName)
signal key_acquired(key_id: StringName)
var fragments: Dictionary = {}
var keys: Dictionary = {}
var seen_story_events: Dictionary = {}
## Stable combination-story IDs, recorded only after their complete narrative ends.
var seen_memory_stories: Dictionary = {}
## The most recently completed branch and its future story target for each story.
var memory_story_branches: Dictionary = {}
## Ending unlocks belong to this game session, like fragments and CG progress.
var unlocked_endings: Dictionary = {}
var current_ending: StringName = &""

func unlock_ending(ending_id: StringName) -> void:
	if ending_id in [&"end1", &"end2"]:
		unlocked_endings[ending_id] = true
		current_ending = ending_id

func collect_fragment(fragment_id: StringName) -> bool:
	if fragments.has(fragment_id):
		return false
	fragments[fragment_id] = true
	fragment_acquired.emit(fragment_id)
	return true

func has_fragment(fragment_id: StringName) -> bool:
	return fragments.has(fragment_id)

func fragment_count() -> int:
	return fragments.size()

func owned_fragment_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for fragment_id: StringName in fragments:
		result.append(fragment_id)
	return result

func collect_key(key_id: StringName) -> bool:
	if keys.has(key_id):
		return false
	keys[key_id] = true
	key_acquired.emit(key_id)
	return true

func has_key(key_id: StringName) -> bool:
	return keys.has(key_id)

func has_seen_story_event(event_id: StringName) -> bool:
	return seen_story_events.has(event_id)

func mark_story_event_seen(event_id: StringName) -> void:
	seen_story_events[event_id] = true

func has_seen_memory_story(story_id: StringName) -> bool:
	return seen_memory_stories.has(story_id)

func mark_memory_story_seen(story_id: StringName) -> void:
	if story_id != &"":
		seen_memory_stories[story_id] = true

func record_memory_story_branch(story_id: StringName, branch_id: StringName, next_story_id: StringName) -> void:
	if story_id == &"" or branch_id == &"" or next_story_id == &"":
		return
	memory_story_branches[story_id] = {"branch_id": branch_id, "next_story_id": next_story_id}

func get_memory_story_branch(story_id: StringName) -> StringName:
	var record: Dictionary = memory_story_branches.get(story_id, {})
	return StringName(record.get("branch_id", &""))

func get_next_memory_story(story_id: StringName) -> StringName:
	var record: Dictionary = memory_story_branches.get(story_id, {})
	return StringName(record.get("next_story_id", &""))

func export_save_data() -> Dictionary:
	var branches: Dictionary = {}
	for story_id: Variant in memory_story_branches:
		var record: Dictionary = memory_story_branches[story_id]
		branches[str(story_id)] = {
			"branch_id": str(record.get("branch_id", "")),
			"next_story_id": str(record.get("next_story_id", "")),
		}
	return {
		"fragments": _export_id_set(fragments),
		"keys": _export_id_set(keys),
		"seen_story_events": _export_id_set(seen_story_events),
		"seen_memory_stories": _export_id_set(seen_memory_stories),
		"memory_story_branches": branches,
		"unlocked_endings": _export_id_set(unlocked_endings),
		"current_ending": str(current_ending),
	}

func import_save_data(data: Dictionary) -> bool:
	# Validate every field before replacing anything. Loading never grants rewards again.
	if not validate_save_data(data):
		return false
	var branches: Dictionary = {}
	for story_id: String in data["memory_story_branches"]:
		var record: Dictionary = data["memory_story_branches"][story_id]
		branches[StringName(story_id)] = {
			"branch_id": StringName(record["branch_id"]),
			"next_story_id": StringName(record["next_story_id"]),
		}
	fragments = _import_id_set(data["fragments"])
	keys = _import_id_set(data["keys"])
	seen_story_events = _import_id_set(data["seen_story_events"])
	seen_memory_stories = _import_id_set(data["seen_memory_stories"])
	unlocked_endings = _import_id_set(data["unlocked_endings"])
	memory_story_branches = branches
	current_ending = StringName(data["current_ending"])
	return true

static func validate_save_data(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	for field: String in ["fragments", "keys", "seen_story_events", "seen_memory_stories", "unlocked_endings"]:
		if not _valid_id_list(data.get(field)):
			return false
	var branches: Variant = data.get("memory_story_branches")
	if not branches is Dictionary or branches.size() > 256:
		return false
	for story_id: Variant in branches:
		var record: Variant = branches[story_id]
		if not _valid_id(story_id) or not record is Dictionary:
			return false
		if not _valid_id(record.get("branch_id")) or not _valid_id(record.get("next_story_id")):
			return false
	var ending: Variant = data.get("current_ending")
	if not ending is String or ending not in ["", "end1", "end2"]:
		return false
	for ending_id: Variant in data["unlocked_endings"]:
		if ending_id not in ["end1", "end2"]:
			return false
	return ending == "" or data["unlocked_endings"].has(ending)

static func _valid_id(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 128 or value != value.strip_edges():
		return false
	for index: int in value.length():
		if value.unicode_at(index) < 32:
			return false
	return true

static func _valid_id_list(value: Variant) -> bool:
	if not value is Array or value.size() > 512:
		return false
	var seen: Dictionary = {}
	for entry: Variant in value:
		if not _valid_id(entry) or seen.has(entry):
			return false
		seen[entry] = true
	return true

static func _export_id_set(source: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for entry: Variant in source:
		result.append(str(entry))
	result.sort()
	return result

static func _import_id_set(source: Array) -> Dictionary:
	var result: Dictionary = {}
	for entry: String in source:
		result[StringName(entry)] = true
	return result
