extends "res://actors/BasePlayer.gd"

export(float) var MAX_MINE_RADIUS = 150
export(float) var MIN_PLACE_RADIUS = 48
export(float) var PROJECTILE_SPAWN_DISTANCE = 52

enum Action { SHOOT, MINE, PLACE }
var current_action = Action.MINE

var combo = 0

var can_shoot = true

var selected_position = null

onready var break_timer = $BreakTimer
onready var highlight_sprite = $Highlighted
onready var shoot_delay = $ShootDelay
onready var combo_window = $ComboWindow
onready var spawn_timer = $SpawnTimer

signal block_break
signal block_place

func select_block():
    if current_action != Action.MINE and current_action != Action.PLACE:
        return

    var result = cast_mouse_ray()

    if result:
        var pos = result.position
        var local_position = pos - global_position
        if local_position.length() <= MIN_PLACE_RADIUS and \
                current_action == Action.PLACE:
            block_deselect()
            return
        var offset = 1 if current_action == Action.MINE else -1
        pos = local_position.normalized() *  \
                (local_position.length() + offset) + global_position
        block_select(pos)
    else:
        block_deselect()

func cast_mouse_ray():
    var space_state = get_world_2d().direct_space_state
    var mouse_position = get_global_mouse_position()
    mouse_position = (mouse_position - global_position).normalized() * \
            MAX_MINE_RADIUS + global_position
    var result = space_state.intersect_ray(global_position, mouse_position,
            [self], 2)
    return result


func _ready():
    connect("block_break", level, "_on_block_break")
    connect("block_place", level, "_on_block_place")

func _physics_process(delta):
    select_block()
    update()

func _input(event):
    if is_network_master():
        if event.is_action_pressed("use_action"):
            match current_action:
                Action.SHOOT:
                    shoot()
                Action.MINE:
                    start_breaking()
                Action.PLACE:
                    if selected_position:
                        emit_signal("block_place", selected_position)
        if event.is_action_released("use_action"):
            if current_action == Action.MINE:
                stop_breaking()
        if event.is_action_pressed("switch_action_1"):
            block_deselect()
            current_action = Action.SHOOT
        if event.is_action_pressed("switch_action_2"):
            current_action = Action.MINE
        if event.is_action_pressed("switch_action_3"):
            current_action = Action.PLACE

func shoot():
    if not can_shoot:
        return
    var mouse_position = get_global_mouse_position()
    var direction_vector = mouse_position - global_position
    var spawn_position = direction_vector.normalized() * PROJECTILE_SPAWN_DISTANCE
    can_shoot = false
    $ComboWindow.stop()
    $ShootDelay.start()
    rpc("spawn_projectile", direction_vector, spawn_position + global_position, combo)

func block_select(position):
    var tilemap = level.get_node("Foreground")
    var tilemap_position = tilemap.world_to_map(position)
    var block_position = tilemap.map_to_world(tilemap_position)
    highlight_sprite.global_position = block_position
    highlight_sprite.visible = true
    selected_position = block_position

func block_deselect():
    highlight_sprite.visible = false
    selected_position = null

func start_breaking():
    break_timer.stop()
    break_timer.start()
    highlight_sprite.get_node("Particles2D").visible = true

func stop_breaking():
    break_timer.stop()
    highlight_sprite.get_node("Particles2D").visible = false

func _on_breaktimer_timeout():
    if selected_position:
        emit_signal("block_break", selected_position)

func _on_shootdelay_timeout():
    can_shoot = true
    combo = (combo + 1) % 3
    combo_window.start()

func _on_combowindow_timeout():
    combo = 0
    
func _on_lose_health(amount):
    rpc("set_health", health - amount)
    if health <= 0:
        die()

func die():
    rpc("_on_death")
    spawn_timer.start()

func _on_spawntimer_timeout():
    rpc("spawn")
