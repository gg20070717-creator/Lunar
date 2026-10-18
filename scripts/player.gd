extends CharacterBody2D
@export var speed := 300.0
@export var interaction_range := 65.0
## Visible height in world units; also used by camera framing.
@export_range(32.0, 256.0, 1.0) var body_height := 120.0
@export_range(0.0, 16.0, 1.0) var idle_bob_height := 2.0
@export_range(0.1, 4.0, 0.1) var idle_bob_period := 0.8
var input_blocked := false
var facing := Vector2.DOWN
var idle_elapsed := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	sprite.frame_changed.connect(_sync_sprite_offset)
	_update_animation(false, 0.0)

func _physics_process(delta: float) -> void:
	if input_blocked:
		velocity = Vector2.ZERO
		_update_animation(false, delta)
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	if direction != Vector2.ZERO:
		if absf(direction.x) > absf(direction.y):
			facing = Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
		else:
			facing = Vector2.DOWN if direction.y > 0.0 else Vector2.UP
	var before := position
	move_and_slide()
	_update_animation(position.distance_to(before) > 0.01, delta)

func _facing_name() -> String:
	if facing == Vector2.UP:
		return "up"
	if facing == Vector2.LEFT:
		return "left"
	if facing == Vector2.RIGHT:
		return "right"
	return "down"

func _update_animation(is_moving: bool, delta: float) -> void:
	var animation_name := StringName(("walk_" if is_moving else "idle_") + _facing_name())
	sprite.flip_h = facing == Vector2.RIGHT
	if sprite.animation != animation_name:
		idle_elapsed = 0.0
		sprite.play(animation_name)
	elif not sprite.is_playing():
		sprite.play()
	if is_moving:
		idle_elapsed = 0.0
	else:
		idle_elapsed = fmod(idle_elapsed + delta, idle_bob_period)
	_sync_sprite_offset()

func _sync_sprite_offset() -> void:
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if texture == null:
		return
	var texture_size := texture.get_size()
	# Source frames have different pixel resolutions; give them a consistent world height.
	sprite.scale = Vector2.ONE * (body_height / texture_size.y)
	var foot_anchor: Vector2 = texture.get_meta("foot_anchor", Vector2(floorf(texture_size.x * 0.5), texture_size.y))
	if sprite.flip_h:
		foot_anchor.x = texture_size.x - foot_anchor.x
	var bob := 0.0
	if String(sprite.animation).begins_with("idle_"):
		bob = -roundf((1.0 - cos(idle_elapsed / idle_bob_period * TAU)) * 0.5 * idle_bob_height)
	# Only the artwork moves; the foot collider, interactions and camera stay fixed.
	sprite.offset = texture_size * 0.5 - foot_anchor
	sprite.position = Vector2(0.0, bob)
