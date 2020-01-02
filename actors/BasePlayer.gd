extends KinematicBody2D

const UP = Vector2(0, -1)
export(int) var GRAVITY = 750
export(int) var MAX_SPEED = 250
export(int) var JUMP_HEIGHT = 30
export(int) var ACCELERATION = 50 
export(float) var FRICTION_GROUND = 0.3
export(float) var FRICTION_AIR = 0.05
export(int) var MAX_HEALTH = 100

var health

var spawn_point

var motion = Vector2()

var controller_id = null

var animation_override = null

onready var projectile = load("res://objects/Projectile.tscn")
onready var health_box = $Health

var level = null

func _ready():
    health = MAX_HEALTH
    health_box.text = String(health)

func input(delta):
    var is_on_floor = is_on_floor()
    var friction = false

    if Input.is_action_pressed("ui_right"):
        motion.x = min(motion.x + ACCELERATION, MAX_SPEED)
    elif Input.is_action_pressed("ui_left"):
        motion.x = max(motion.x - ACCELERATION, -MAX_SPEED)
    else:
        friction = true

    if is_on_floor:
        if Input.is_action_just_pressed("ui_up"):
            motion.y = -GRAVITY * JUMP_HEIGHT * delta
        if friction:
            motion.x = lerp(motion.x, 0, FRICTION_GROUND)
    elif friction:
        motion.x = lerp(motion.x, 4, FRICTION_AIR)

func animate():
    if animation_override:
        return

    var is_on_floor = is_on_floor()
    # Animations
    var playing = $AnimatedSprite.animation
    var round_motion = motion.round()
    if is_on_floor:
        if round_motion.x == 0:
            $AnimatedSprite.play("idle")
        else:
            $AnimatedSprite.play("run")
    elif round_motion.y < 0:
        $AnimatedSprite.play("jump")
    else:
        $AnimatedSprite.play("fall")
        
    # Direction
    if round_motion.x > 0:
        $AnimatedSprite.set_flip_h(false)
    elif round_motion.x < 0:
        $AnimatedSprite.set_flip_h(true)

func movement(delta):
    motion.y += GRAVITY * delta
    motion = move_and_slide(motion, UP)
    rpc('update_posmot', position, motion)
    
puppet func update_posmot(pos, mot):
    position = pos
    motion = mot

func _physics_process(delta):
    if is_network_master():
        input(delta)
    movement(delta)
    animate()
    update()

sync func spawn_projectile(direction, position, combo):
    $AnimatedSprite.stop()
    match combo:
        0:
            animation_override = "attack1"
            $AnimatedSprite.play("attack1")
        1:
            animation_override = "attack2"
            $AnimatedSprite.play("attack2")
        2:
            animation_override = "attack3"
            $AnimatedSprite.play("attack3")
    if direction.x >= 0:
        $AnimatedSprite.set_flip_h(false)
    else:
        $AnimatedSprite.set_flip_h(true)
    var proj = projectile.instance()
    proj.initial_velocity = direction
    proj.position = position
    level.add_child(proj)

func _on_animation_finished():
    animation_override = null

sync func set_health(h):
    health = h
    health_box.text = String(h)

func remove_from_physics():
    set_physics_process(false)
    $CollisionShape2D.disabled = true
    set_process_input(false)
    move_and_slide(Vector2(0,0))

func add_to_physics():
    set_physics_process(true)
    set_process_input(true)
    $CollisionShape2D.disabled = false

sync func _on_death():
    visible = false
    remove_from_physics()

sync func spawn():
    health = MAX_HEALTH
    visible = true
    global_position = spawn_point
    add_to_physics()
