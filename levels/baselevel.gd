extends Node2D

onready var tilemap = $Foreground

signal block_highlight
signal block_unhighlight

var highlighted_position = null
var active_player

func get_class():
    return "baselevel"

# func _ready():
#     # By default, all nodes in server inherit from master,
#     # while all nodes in clients inherit from slave.
#         
#     if (get_tree().is_network_server()):
#         #If in the server, get control of player 2 to the other peer.
#         #This function is tree recursive by default.
#         $player2.set_network_master(get_tree().get_network_connected_peers()[0])
#         active_player = $player1
#     else:
#         #If in the client, give control of player 2 to itself. 
#         #This function is tree recursive by default.
#         $player2.set_network_master(get_tree().get_network_unique_id())
#         active_player = $player2

# func _on_block_select(position):
#     var tilemap_position = tilemap.world_to_map(position)
#     var block_position = tilemap.map_to_world(tilemap_position)
#     if highlighted_position == null or block_position != highlighted_position:
#         highlight_sprite.global_position = block_position
#         highlighted_position = block_position
#         highlight_sprite.visible = true
#         emit_signal("block_highlight", highlighted_position)
# 
# func _on_block_deselect():
#     highlight_sprite.visible = false
#     highlighted_position = null
#     emit_signal("block_unhighlight")
# 
# func _on_block_breaking():
#     highlight_sprite.find_node("Particles2D").visible = true
#     
# func _on_block_stop_breaking():
#     highlight_sprite.find_node("Particles2D").visible = false

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
