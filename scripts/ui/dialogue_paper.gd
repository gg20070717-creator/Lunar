extends TextureRect
## Shared paper backing in the artwork's original 1920 x 1080 composition.
const TEXTURE = preload("res://resources/art/ui/dialogue_paper.tres")
const REFERENCE_SIZE := Vector2(1920, 1080)
const REFERENCE_RECT := Rect2(37, 720, 1845, 291)
# Keep all text clear of the torn edges and the folded upper-right corner.
const CONTENT_RECT := Rect2(48, 24, 1688, 242)
const SPEAKER_RECT := Rect2(48, 24, 1688, 42)
const SPOKEN_BODY_RECT := Rect2(48, 78, 1688, 154)
const NARRATION_BODY_RECT := Rect2(48, 40, 1688, 192)
const HINT_RECT := Rect2(48, 242, 1688, 30)


func _init() -> void:
	texture = TEXTURE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = REFERENCE_RECT.size
