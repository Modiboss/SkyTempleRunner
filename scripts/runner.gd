extends CharacterBody3D
class_name Runner

@export var lane_width := 2.4
@export var lane_speed := 12.0
@export var forward_speed := 8.0
@export var max_speed := 22.0
@export var acceleration := 0.6
@export var jump_velocity := 8.5
@export var gravity := 24.0

var lane := 0
var sliding := false
var slide_timer := 0.0
var swipe_start := Vector2.ZERO
var tracking_touch := false

func _physics_process(delta):
    if Input.is_action_just_pressed("lane_left"): change_lane(-1)
    if Input.is_action_just_pressed("lane_right"): change_lane(1)
    if Input.is_action_just_pressed("jump"): jump()
    if Input.is_action_just_pressed("slide"): slide()

    for i in Input.get_touch_count():
        var t := Input.get_touch(i)
        if t.pressed and t.canceled == false:
            if not tracking_touch:
                swipe_start = t.position
                tracking_touch = true
        elif tracking_touch:
            var d := t.position - swipe_start
            tracking_touch = false
            if d.length() > 60:
                if abs(d.x) > abs(d.y): change_lane(1 if d.x > 0 else -1)
                elif d.y < 0: jump()
                else: slide()

    forward_speed = min(max_speed, forward_speed + acceleration * delta)
    var target_x := lane * lane_width
    velocity.x = (target_x - position.x) * lane_speed
    velocity.z = forward_speed

    if not is_on_floor():
        velocity.y -= gravity * delta
    elif velocity.y < 0:
        velocity.y = 0

    if sliding:
        slide_timer -= delta
        if slide_timer <= 0: sliding = false

    move_and_slide()

func change_lane(direction:int):
    lane = clamp(lane + direction, -1, 1)

func jump():
    if is_on_floor() and not sliding:
        velocity.y = jump_velocity

func slide():
    if is_on_floor():
        sliding = true
        slide_timer = 0.7
