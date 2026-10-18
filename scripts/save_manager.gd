extends RefCounted
## Five versioned JSON slots. UI/gameplay own their snapshots; this class owns disk I/O.
const GameStateScript = preload("res://scripts/game_state.gd")
const MAX_SLOTS := 5
const FORMAT := "lunar_save"
const VERSION := 1
const SAVE_DIRECTORY := "user://saves"
const PRESET_PATH := "res://resources/saves/fragment_4.json"
const PRESET_ID := "fragment_4"
const MAX_FILE_BYTES := 4 * 1024 * 1024
const LEVEL_NAMES := {
	"res://scenes/bedroom.tscn": "卧室",
	"res://scenes/corridor.tscn": "二楼走廊",
	"res://scenes/first_floor.tscn": "一楼",
	"res://scenes/courtyard.tscn": "小院",
	"res://scenes/studio.tscn": "画室",
}
var save_directory: String

func _init(directory: String = SAVE_DIRECTORY) -> void:
	save_directory = directory.trim_suffix("/")

func list_slots() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot: int in range(1, MAX_SLOTS + 1):
		var metadata := {
			"slot": slot, "empty": true, "valid": false, "name": "", "title": "",
			"created_at": "", "updated_at": "", "saved_at": "", "saved_at_unix": 0.0, "location": "",
			"elapsed_seconds": 0.0, "fragment_count": 0, "summary": "", "error": "",
		}
		if FileAccess.file_exists(_slot_path(slot)):
			metadata["empty"] = false
			var loaded := _read_slot(slot)
			if loaded["ok"]:
				metadata.merge(_metadata(loaded["record"]), true)
			else:
				metadata["error"] = loaded["error"]
				metadata["name"] = "无法读取的存档"
				metadata["title"] = metadata["name"]
		result.append(metadata)
	return result

func save_slot(slot: int, snapshot: Dictionary, name: String = "") -> Dictionary:
	return _save_slot(slot, snapshot, name)

func load_slot(slot: int) -> Dictionary:
	if not _valid_slot(slot):
		return _failure("槽位必须在 1 到 5 之间。")
	var loaded := _read_slot(slot)
	if not loaded["ok"]:
		return loaded
	var record: Dictionary = loaded["record"]
	return {"ok": true, "error": "", "slot": slot, "snapshot": record["snapshot"].duplicate(true), "metadata": _metadata(record)}

func delete_slot(slot: int) -> Dictionary:
	if not _valid_slot(slot):
		return _failure("槽位必须在 1 到 5 之间。")
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return {"ok": true, "error": "", "slot": slot}
	var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if error != OK:
		return _failure("删除存档失败（%s）。" % error_string(error))
	return {"ok": true, "error": "", "slot": slot}

func rename_slot(slot: int, name: String) -> Dictionary:
	if not _valid_slot(slot):
		return _failure("槽位必须在 1 到 5 之间。")
	name = name.strip_edges()
	if not _valid_name(name):
		return _failure("存档名称需为 1 到 40 个字符，且不能包含换行或控制字符。")
	var loaded := _read_slot(slot)
	if not loaded["ok"]:
		return loaded
	var record: Dictionary = loaded["record"]
	record["name"] = name
	var written := _atomic_write(_slot_path(slot), record)
	if not written["ok"]:
		return written
	return {"ok": true, "error": "", "slot": slot, "metadata": _metadata(record)}

func load_preset() -> Dictionary:
	var loaded := _read_json(PRESET_PATH)
	if not loaded["ok"]:
		return loaded
	var value: Variant = loaded["data"]
	if not value is Dictionary or value.get("format") != "lunar_save_preset" or not _version_matches(value.get("version")):
		return _failure("预设存档格式或版本不兼容。")
	if not value.get("snapshot") is Dictionary or not _valid_name(value.get("name", "")):
		return _failure("预设存档内容无效。")
	var problem := validate_snapshot(value["snapshot"])
	if not problem.is_empty():
		return _failure(problem)
	return {"ok": true, "error": "", "name": value["name"], "snapshot": value["snapshot"].duplicate(true)}

func install_preset() -> Dictionary:
	# Marker survives slot deletion. Existing saves, including damaged files, stay occupied.
	var marker := save_directory.path_join("fragment_4_installed.json")
	if FileAccess.file_exists(marker):
		return {"ok": true, "error": "", "skipped": true, "reason": "already_installed"}
	var first_empty := 0
	for slot: int in range(1, MAX_SLOTS + 1):
		if not FileAccess.file_exists(_slot_path(slot)):
			if first_empty == 0:
				first_empty = slot
			continue
		var loaded := _read_slot(slot)
		if loaded["ok"] and loaded["record"].get("preset_id", "") == PRESET_ID:
			var repaired := _atomic_write(marker, {"preset_id": PRESET_ID, "version": VERSION})
			if not repaired["ok"]:
				return repaired
			return {"ok": true, "error": "", "skipped": true, "reason": "already_installed"}
	if first_empty == 0:
		return {"ok": true, "error": "", "skipped": true, "reason": "slots_full"}
	var preset := load_preset()
	if not preset["ok"]:
		return preset
	var saved := _save_slot(first_empty, preset["snapshot"], preset["name"], PRESET_ID)
	if not saved["ok"]:
		return saved
	var marked := _atomic_write(marker, {"preset_id": PRESET_ID, "version": VERSION})
	if not marked["ok"]:
		# Slot carries the origin too, allowing a later marker-write retry without duplication.
		saved["warning"] = marked["error"]
	saved["skipped"] = false
	return saved

static func validate_snapshot(snapshot: Dictionary) -> String:
	if not GameStateScript.validate_save_data(snapshot.get("state")):
		return "游戏进度字段无效。"
	var world: Variant = snapshot.get("world")
	if not world is Dictionary or not world.get("scene_path") is String or not LEVEL_NAMES.has(world["scene_path"]):
		return "地点字段无效。"
	var position: Variant = world.get("position")
	if not position is Array or position.size() != 2:
		return "角色位置字段无效。"
	for coordinate: Variant in position:
		if not _finite_number(coordinate) or absf(float(coordinate)) > 1000000.0:
			return "角色位置超出有效范围。"
	var ui: Variant = snapshot.get("ui")
	if not ui is Dictionary or ui.get("mode") not in ["exploration", "puzzle", "dialogue", "image", "collection", "ending"]:
		return "界面恢复字段无效。"
	if snapshot.has("audio") and not snapshot["audio"] is Dictionary:
		return "音频恢复字段无效。"
	var elapsed: Variant = snapshot.get("elapsed_seconds", 0.0)
	if not _finite_number(elapsed) or float(elapsed) < 0.0 or float(elapsed) > 1000000000000.0:
		return "游戏时长字段无效。"
	return ""

func _save_slot(slot: int, snapshot: Dictionary, name: String, preset_id: String = "") -> Dictionary:
	if not _valid_slot(slot):
		return _failure("槽位必须在 1 到 5 之间。")
	# Copy and normalize StringName keys/values. Objects, resources and non-finite numbers fail.
	var copied := _copy_json(snapshot, 0, [50000])
	if not copied["ok"]:
		return copied
	var payload: Dictionary = copied["value"]
	var problem := validate_snapshot(payload)
	if not problem.is_empty():
		return _failure(problem)
	var now := Time.get_datetime_string_from_system(false, true)
	var created_at := now
	var previous := _read_slot(slot)
	if previous["ok"]:
		created_at = previous["record"]["created_at"]
		if name.strip_edges().is_empty():
			name = previous["record"]["name"]
	name = name.strip_edges()
	if name.is_empty():
		name = "存档 %d" % slot
	if not _valid_name(name):
		return _failure("存档名称需为 1 到 40 个字符，且不能包含换行或控制字符。")
	var record := {
		"format": FORMAT, "version": VERSION, "slot": slot, "name": name,
		"created_at": created_at, "updated_at": now,
		"saved_at_unix": Time.get_unix_time_from_system(), "snapshot": payload,
	}
	if not preset_id.is_empty():
		record["preset_id"] = preset_id
	elif previous["ok"] and previous["record"].has("preset_id"):
		record["preset_id"] = previous["record"]["preset_id"]
	var written := _atomic_write(_slot_path(slot), record)
	if not written["ok"]:
		return written
	return {"ok": true, "error": "", "slot": slot, "metadata": _metadata(record)}

func _read_slot(slot: int) -> Dictionary:
	var loaded := _read_json(_slot_path(slot))
	if not loaded["ok"]:
		return loaded
	var value: Variant = loaded["data"]
	if not value is Dictionary or value.get("format") != FORMAT or not _version_matches(value.get("version")):
		return _failure("存档格式或版本不兼容。")
	if not _finite_number(value.get("slot")) or float(value["slot"]) != float(slot):
		return _failure("存档槽位标记无效。")
	if not _valid_name(value.get("name", "")):
		return _failure("存档名称无效。")
	for key: String in ["created_at", "updated_at"]:
		if not value.get(key) is String or value[key].is_empty() or value[key].length() > 64:
			return _failure("存档时间字段无效。")
	if value.has("saved_at_unix"):
		if not _finite_number(value["saved_at_unix"]) or float(value["saved_at_unix"]) < 0.0 or float(value["saved_at_unix"]) > 1000000000000.0:
			return _failure("存档高精度时间字段无效。")
	if not value.get("snapshot") is Dictionary:
		return _failure("存档缺少游戏快照。")
	var problem := validate_snapshot(value["snapshot"])
	if not problem.is_empty():
		return _failure(problem)
	return {"ok": true, "error": "", "record": value}

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _failure("此槽位没有存档。")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _failure("读取存档失败（%s）。" % error_string(FileAccess.get_open_error()))
	if file.get_length() > MAX_FILE_BYTES:
		file.close()
		return _failure("存档文件过大。")
	var source := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(source) != OK:
		return _failure("存档 JSON 无法解析。")
	var copied := _copy_json(json.data, 0, [50000])
	if not copied["ok"]:
		return copied
	return {"ok": true, "error": "", "data": copied["value"]}

func _atomic_write(path: String, value: Dictionary) -> Dictionary:
	var text := JSON.stringify(value, "\t", true, true)
	if text.to_utf8_buffer().size() > MAX_FILE_BYTES:
		return _failure("存档文件过大。")
	var absolute := ProjectSettings.globalize_path(path)
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	if directory_error != OK:
		return _failure("创建存档目录失败（%s）。" % error_string(directory_error))
	var temporary := absolute + ".tmp." + str(Time.get_ticks_usec())
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _failure("写入存档失败（%s）。" % error_string(FileAccess.get_open_error()))
	file.store_string(text)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(temporary)
		return _failure("写入存档失败（%s）。" % error_string(write_error))
	# Same-directory rename replaces the destination only after the complete file is closed.
	var rename_error := DirAccess.rename_absolute(temporary, absolute)
	if rename_error != OK:
		DirAccess.remove_absolute(temporary)
		return _failure("提交存档失败（%s）。" % error_string(rename_error))
	return {"ok": true, "error": ""}

func _metadata(record: Dictionary) -> Dictionary:
	var snapshot: Dictionary = record["snapshot"]
	var world: Dictionary = snapshot["world"]
	var location: String = LEVEL_NAMES.get(world["scene_path"], "")
	var fragment_count: int = snapshot["state"]["fragments"].size()
	var summary := "%s · 碎片 %d/5" % [location, fragment_count]
	return {
		"slot": int(record["slot"]), "empty": false, "valid": true,
		"name": record["name"], "title": record["name"], "location": location,
		"created_at": record["created_at"], "updated_at": record["updated_at"],
		"saved_at": record["updated_at"], "saved_at_unix": _record_saved_at_unix(record),
		"elapsed_seconds": float(snapshot.get("elapsed_seconds", 0.0)),
		"fragment_count": fragment_count, "summary": summary, "error": "",
	}

static func _record_saved_at_unix(record: Dictionary) -> float:
	if record.has("saved_at_unix"):
		return float(record["saved_at_unix"])
	# Older display timestamps were local time, without an explicit zone offset.
	var seconds := Time.get_unix_time_from_datetime_string(String(record.get("updated_at", "")))
	var offset_seconds := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	return maxf(0.0, float(seconds - offset_seconds))

func _slot_path(slot: int) -> String:
	return save_directory.path_join("slot_%d.json" % slot)

static func _valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= MAX_SLOTS

static func _valid_name(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 40 or value != value.strip_edges():
		return false
	for index: int in value.length():
		if value.unicode_at(index) < 32:
			return false
	return true

static func _finite_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func _version_matches(value: Variant) -> bool:
	return _finite_number(value) and float(value) == float(VERSION)

static func _failure(message: String) -> Dictionary:
	return {"ok": false, "error": message}

static func _copy_json(value: Variant, depth: int, budget: Array) -> Dictionary:
	budget[0] -= 1
	if depth > 24 or budget[0] < 0:
		return _failure("存档数据层级过深或内容过多。")
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT:
			return {"ok": true, "value": value}
		TYPE_FLOAT:
			if not is_finite(value):
				return _failure("存档含无效数值。")
			return {"ok": true, "value": value}
		TYPE_STRING, TYPE_STRING_NAME:
			var result := str(value)
			if result.length() > 262144:
				return _failure("存档文本过长。")
			return {"ok": true, "value": result}
		TYPE_ARRAY:
			var result: Array = []
			for entry: Variant in value:
				var copied := _copy_json(entry, depth + 1, budget)
				if not copied["ok"]:
					return copied
				result.append(copied["value"])
			return {"ok": true, "value": result}
		TYPE_DICTIONARY:
			var result: Dictionary = {}
			for key: Variant in value:
				if not key is String and not key is StringName:
					return _failure("存档字段名称必须为字符串。")
				if str(key).length() > 256:
					return _failure("存档字段名称过长。")
				var copied := _copy_json(value[key], depth + 1, budget)
				if not copied["ok"]:
					return copied
				result[str(key)] = copied["value"]
			return {"ok": true, "value": result}
	return _failure("存档含不支持的数据类型。")
