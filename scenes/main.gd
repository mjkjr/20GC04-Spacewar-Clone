extends Node

## Spacewar! Clone

## TODO: Add instructions screen
## TODO: Add health
## TODO: Add credits screen
## TODO: Explosion effects for destroyed ships and torpedoes
## TODO: Add particle effects for thrusters & torpedoes
## TODO: Replace ships & torpedos with proper sprites
## TODO: Add AI player opponent
## TODO: Handle controller connect / disconnect


enum State { LAUNCH, MAIN, PLAYING, PAUSED, GAME_OVER, CREDITS }

const PLAYER = preload("res://scenes/player.tscn")

var state: State = State.LAUNCH

var player1: Player
var player2: Player


func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _process(_delta: float) -> void:
	match state:
		State.LAUNCH:
			if (
					Input.is_action_just_pressed("p1_join")
					and player1 == null
			):
					player1 = PLAYER.instantiate()
					add_child(player1)
					player1.position = Vector2(1920*0.25, 1080*0.5)
					player1.destroyed.connect(_on_player_destroyed.bind(1))
					player1.collided.connect(_on_players_collided)
					%Player1JoinLabel.text = "Joined\nWaiting for other player..."
					$Menus/Join/P1ReadyColorRect.visible = true
					if player2 != null:
						$Menus/Join.visible = false
						state = State.PLAYING
			if (
					Input.is_action_just_pressed("p2_join")
					and player2 == null
			):
					player2 = PLAYER.instantiate()
					add_child(player2)
					player2.position = Vector2(1920*0.75, 1080*0.5)
					player2.destroyed.connect(_on_player_destroyed.bind(2))
					%Player2JoinLabel.text = "Joined\nWaiting for other player..."
					$Menus/Join/P2ReadyColorRect.visible = true
					if player1 != null:
						$Menus/Join.visible = false
						state = State.PLAYING
		State.PLAYING:
			if Input.is_action_pressed("p1_thrust"):
				player1.thrust(Player.ThrustDirection.FORWARD)
			if Input.is_action_pressed("p2_thrust"):
				player2.thrust(Player.ThrustDirection.FORWARD)
			if Input.is_action_pressed("p1_reverse_thrust"):
				player1.thrust(Player.ThrustDirection.REVERSE)
			if Input.is_action_pressed("p2_reverse_thrust"):
				player2.thrust(Player.ThrustDirection.REVERSE)
			if Input.is_action_pressed("p1_rotate_left"):
				player1.rotate_left()
			if Input.is_action_pressed("p2_rotate_left"):
				player2.rotate_left()
			if Input.is_action_pressed("p1_rotate_right"):
				player1.rotate_right()
			if Input.is_action_pressed("p2_rotate_right"):
				player2.rotate_right()
			if Input.is_action_just_pressed("p1_fire_torpedo"):
				player1.fire_torpedo()
			if Input.is_action_just_pressed("p2_fire_torpedo"):
				player2.fire_torpedo()
			if Input.is_action_just_pressed("pause"):
				state = State.PAUSED
				$Menus/Pause.visible = true
				$Gameplay.process_mode = PROCESS_MODE_DISABLED
				get_tree().set_group("ships", "process_mode", PROCESS_MODE_DISABLED)
				get_tree().set_group("torpedoes", "process_mode", PROCESS_MODE_DISABLED)
		State.PAUSED:
			if Input.is_action_just_pressed("pause"):
				state = State.PLAYING
				$Menus/Pause.visible = false
				$Gameplay.process_mode = PROCESS_MODE_INHERIT
				get_tree().set_group("ships", "process_mode", PROCESS_MODE_INHERIT)
				get_tree().set_group("torpedoes", "process_mode", PROCESS_MODE_INHERIT)


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	print("Device %s %s" % [device, "connected" if connected else "disconnected" ])
	print("TODO: handle controller connect / disconnect")


func _on_players_collided() -> void:
	state = State.GAME_OVER
	$Gameplay.process_mode = Node.PROCESS_MODE_DISABLED
	%GameOverSummary.text = "Your ships collided! No Winners!"
	$Menus/GameOver.visible = true


func _on_player_destroyed(player_number: int) -> void:
	state = State.GAME_OVER
	%GameOverSummary.text = "Player %s wins!" % (1 if player_number == 2 else 2)
	$Menus/GameOver.visible = true


func _on_play_again_button_pressed() -> void:
	print("TODO: reset the game")


func _on_credits_button_pressed() -> void:
	print("TODO: Show the credits screen")


func _on_star_body_entered(body: Node2D) -> void:
	var collision_groups = body.get_groups()
	if collision_groups.has("ships"):
		if body == player1:
			body.queue_free()
			_on_player_destroyed(1)
		else:
			body.queue_free()
			_on_player_destroyed(2)
	elif collision_groups.has("torpedoes"):
		body.queue_free()
