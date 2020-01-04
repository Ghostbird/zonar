extends Node2D

onready var tilemap = $Foreground
onready var players_node = $Players
onready var spawns_node = $Spawns


func _on_block_break(position):
    var tilemap_position = tilemap.world_to_map(position)
    rpc("block_break", tilemap_position)

func _on_block_place(position):
    var tilemap_position = tilemap.world_to_map(position)
    rpc("block_place", tilemap_position)

sync func block_break(tilemap_position):
    tilemap.set_cellv(tilemap_position, -1)
    tilemap.update_bitmask_area(tilemap_position)

sync func block_place(tilemap_position):
    tilemap.set_cellv(tilemap_position, 0)
    tilemap.update_bitmask_area(tilemap_position)

func spawn_players():
    var players = players_node.get_children()
    randomize()
    players.shuffle()
    var spawns = spawns_node.get_child_count()
    var i = 0
    for player in players:
        var point = spawns_node.get_child(i % spawns).global_position
        player.rpc("set_spawn", point)
        player.rpc("spawn")
        i += 1
