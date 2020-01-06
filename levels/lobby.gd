extends Control

export(int) var server_port = 27027
export(int) var max_players = 8

# Player info, associate ID to data
var player_info = {}
var connected_peer_resource = load("res://actors/connected_peer.tscn")
var localplayer = load("res://actors/LocalPlayer.tscn")
var networkplayer = load("res://actors/NetworkPlayer.tscn")

# Get info for the local player
func get_player_info():
	return { name = $connectbox/vbox/hbox/username.text, color = $connectbox/vbox/hbox/color.color }

func _ready():
    get_tree().connect("network_peer_connected", self, "_player_connected")
    get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
    get_tree().connect("connected_to_server", self, "_connected_ok")
    get_tree().connect("connection_failed", self, "_connected_fail")
    get_tree().connect("server_disconnected", self, "_server_disconnected")

func _player_connected(id):
    # Called on both clients and server when a peer connects. Send my info to it.
    rpc_id(id, "register_player", get_player_info(), get_tree().get_network_unique_id())

func _player_disconnected(id):
    if (get_tree().is_network_server()):
        player_info.erase(id) # Erase player from info.
        # Erase node from connected players list
        for node in $playerbox/vbox/playerinfo/vbox.get_children():
            if node.id == id:
                node.queue_free()
                break

        $playerbox.hide()
    else:
        get_tree().reload_current_scene()

func _connected_ok():
    $playerbox.show()

func _server_disconnected():
    _end_game("Server disconnected")

func _connected_fail():
    print_debug('CONNECT FAILED')

remote func register_player(info, id):
    # Store the info
    player_info[id] = info
    var connected_peer = connected_peer_resource.instance()
    connected_peer.set_id(id)
    connected_peer.set_color(info.color)
    connected_peer.set_username(info.name)
    $playerbox/vbox/playerinfo/vbox.add_child(connected_peer)
    $playerbox/vbox/title.text = 'Connected players: (%s/%s)' % [$playerbox/vbox/playerinfo/vbox.get_child_count(), max_players]
    if get_tree().is_network_server():
        $playerbox/vbox/start.show()

func _on_host_pressed():
    var peer = NetworkedMultiplayerENet.new()
    # Godot by default does not treat the server as a player, but it is in our case hence the -1.
    peer.create_server(server_port, max_players - 1)
    get_tree().set_network_peer(peer)
    $playerbox.show()
    $connectbox.disable()
    # Register self
    register_player(get_player_info(), get_tree().get_network_unique_id())

func _on_join_pressed():
    var peer = NetworkedMultiplayerENet.new()
    peer.create_client($connectbox/vbox/server_address.text, server_port)
    get_tree().set_network_peer(peer)
    $playerbox.show()
    $connectbox.disable()
    # Register self
    register_player(get_player_info(), get_tree().get_network_unique_id())


func _on_start_pressed():
    # Do not allow new connections
    get_tree().set_refuse_new_network_connections(true)
    rpc("start_game")

sync func start_game():
    var self_peer_id = get_tree().get_network_unique_id()
    #This starts the game upon connection.
    var level = load("res://levels/level01.tscn").instance() #Change to scene for testing
    level.connect("game_finished",self,"_end_game",[],CONNECT_DEFERRED) # connect deferred so we can safely erase it from the callback
    get_tree().get_root().add_child(level)

    var my_player = localplayer.instance()
    my_player.set_name(str(self_peer_id))
    my_player.set_network_master(self_peer_id)
    my_player.level = level
    level.get_node("Players").add_child(my_player)
    my_player.set_username(player_info[self_peer_id].name)
    my_player.set_color(player_info[self_peer_id].color)

    for p in get_tree().get_network_connected_peers():
        var player = networkplayer.instance()
        player.set_name(str(p))
        player.set_network_master(p)
        player.level = level
        level.get_node("Players").add_child(player)
        player.set_username(player_info[p].name)
        player.set_color(player_info[p].color)

    if is_network_master():
        level.spawn_players()

    hide()

func _end_game(with_error=""):
    if get_tree().get_root().find_node("level"):
        #erase level scene
        get_tree().get_root().find_node("level").free() # erase immediately, otherwise network might show errors (this is why we connected deferred above)
        show()
    get_tree().set_network_peer(null) #remove peer
    $connectbox.enable(with_error)
