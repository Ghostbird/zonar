extends "res://actors/BasePlayer.gd"

export(float) var MAX_MINE_RADIUS = 150
export(float) var MIN_PLACE_RADIUS = 42
export(float) var PROJECTILE_SPAWN_DISTANCE = 52

enum Action { SHOOT, MINE, PLACE }
var current_action = Action.MINE

var combo = 0

var can_shoot = true

var selected_position = null

onready var break_timer = $BreakTimer
onready var build_timer = $BuildTimer
onready var highlight_sprite = $Highlighted
onready var shoot_delay = $ShootDelay
onready var combo_window = $ComboWindow
onready var spawn_timer = $SpawnTimer

signal block_break
signal block_place

func select_block():
    var to_highlight
    
    match current_action:
        Action.MINE:
            to_highlight = select_block_mining()
        Action.PLACE:
            to_highlight = select_block_placing()
        _:
            block_deselect()

    if to_highlight:
        block_select(to_highlight)
    else:
        block_deselect()
    

func select_block_mining():
    var to_highlight

    var space_state = get_world_2d().direct_space_state
    var mouse_position = get_global_mouse_position()

    mouse_position = (mouse_position - global_position).normalized() * \
            MAX_MINE_RADIUS + global_position
    var result = space_state.intersect_ray(global_position, mouse_position,
            [self], 2)
    if result:
        var pos = result.position
        var local_position = pos - global_position
        var offset = 1
        pos = local_position.normalized() *  \
                (local_position.length() + offset) + global_position
        to_highlight = pos

    return to_highlight

func select_block_placing():
    var to_highlight

    var space_state = get_world_2d().direct_space_state
    var mouse_position = get_global_mouse_position()
    var tilemap = level.get_node("Foreground")
    
    if (mouse_position - global_position).length() <= MAX_MINE_RADIUS and \
            is_adjacent_in_tilemap(tilemap.world_to_map(mouse_position)):
        var would_highlight = tilemap.map_to_world(tilemap.world_to_map(mouse_position))
        var to_check = []
        to_check.append(would_highlight)
        to_check.append(Vector2(would_highlight.x + 32, would_highlight.y))
        to_check.append(Vector2(would_highlight.x, would_highlight.y + 32))
        to_check.append(Vector2(would_highlight.x + 32, would_highlight.y + 32))
        for pos in to_check:
            var result = space_state.intersect_ray(global_position, pos,
                    [self], 2)
            if not result:
                to_highlight = mouse_position
                break

    if to_highlight and \
            (to_highlight - global_position).length() >= MIN_PLACE_RADIUS:
        return to_highlight

    mouse_position = (mouse_position - global_position).normalized() * \
            MAX_MINE_RADIUS + global_position
    var result = space_state.intersect_ray(global_position, mouse_position,
            [self], 2)
    if result:
        var pos = result.position
        var local_position = pos - global_position
        var offset = -1
        pos = local_position.normalized() *  \
                (local_position.length() + offset) + global_position
        to_highlight = pos

    if to_highlight and \
            (to_highlight - global_position).length() < MIN_PLACE_RADIUS:
        to_highlight = null

    return to_highlight

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
                    start_placing()
        if event.is_action_released("use_action"):
            match current_action:
                Action.SHOOT:
                    pass
                Action.MINE:
                    stop_breaking()
                Action.PLACE:
                    stop_placing()
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
    combo_window.stop()
    shoot_delay.start()
    rpc("spawn_projectile", direction_vector, spawn_position + global_position, combo)

func block_select(pos):
    var tilemap = level.get_node("Foreground")
    var tilemap_position = tilemap.world_to_map(pos)
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

func start_placing():
    if selected_position:
        emit_signal("block_place", selected_position)
    build_timer.stop()
    build_timer.start()

func stop_placing():
    build_timer.stop()

func _on_breaktimer_timeout():
    if selected_position:
        emit_signal("block_break", selected_position)

func _on_buildtimer_timeout():
    if selected_position:
        emit_signal("block_place", selected_position)

func _on_shootdelay_timeout():
    can_shoot = true
    combo = (combo + 1) % 3
    combo_window.start()

func _on_combowindow_timeout():
    combo = 0
    
func _on_lose_health(amount):
    var new_health = get_health() - amount
    rpc("set_health", new_health)
    if new_health <= 0:
        die()

func die():
    rpc("_on_death")
    spawn_timer.start()

func _on_spawntimer_timeout():
    rpc("spawn")

func is_adjacent_in_tilemap(tilemap_position):
    var to_check = []
    var tilemap = level.get_node("Foreground")
    if tilemap.get_cellv(tilemap_position) != -1:
        return false
    to_check.append(Vector2(tilemap_position.x - 1, tilemap_position.y))
    to_check.append(Vector2(tilemap_position.x + 1, tilemap_position.y))
    to_check.append(Vector2(tilemap_position.x, tilemap_position.y - 1))
    to_check.append(Vector2(tilemap_position.x, tilemap_position.y + 1))
    for pos in to_check:
        if tilemap.get_cellv(pos) != -1:
            return true
    return false
