extends Node

## Pizza Battle in Space!
## Spacewar! Clone

enum States { LAUNCH, PLAYING, PAUSED, GAME_OVER }
enum Modes { SINGLE_PLAYER, TWO_PLAYER }

const PLAYER1 = preload("res://scenes/cheese-ship.tscn")
const PLAYER2 = preload("res://scenes/pizza-ship.tscn")
const READY_COUNTDOWN = 4

var state: States = States.LAUNCH
var mode: Modes = Modes.TWO_PLAYER

var ready_countdown: int = READY_COUNTDOWN

var player1_ready: bool = false
var player2_ready: bool = false
var player1_disconnected: bool = false
var player2_disconnected: bool = false
var disconnection_paused: bool = false

var player1: Player
var player2: Player


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	%NotReadyColor.call_deferred("grab_focus")


func _process(_delta: float) -> void:
	match state:
		States.LAUNCH:
			$Menus/Join.visible = true
			if (
					Input.is_action_just_pressed("p1_join")
					and player1_ready == false
					and %NotReadyColor.has_focus()
			):
				player1_ready = true
				%ReadyColorP1.visible = true
				%ReadyLabelP1.visible = true
				%NotReadyLabelP1.visible = false
				if %ReadyTimer.is_stopped():
					_on_ready_timer_timeout()
			if (
					Input.is_action_just_pressed("p2_join")
					and player2 == null
					and %NotReadyColor.has_focus()
			):
				player2_ready = true
				%ReadyColorP2.visible = true
				%ReadyLabelP2.visible = true
				%NotReadyLabelP2.visible = false
				if %ReadyTimer.is_stopped():
					_on_ready_timer_timeout()
		States.PLAYING:
			if mode == Modes.SINGLE_PLAYER:
				_ai_player_turn()
				
			if Input.is_action_pressed("p1_thrust_forward"):
				player1.thrust()
			elif Input.is_action_just_released("p1_thrust_forward"):
				player1.stop_thrusters()
			if Input.is_action_pressed("p2_thrust_forward"):
				player2.thrust()
			elif Input.is_action_just_released("p2_thrust_forward"):
				player2.stop_thrusters()
			if Input.is_action_pressed("p1_rotate_left"):
				player1.rotate_left()
			elif Input.is_action_just_released("p1_rotate_left"):
				player1.stop_thrusters()
			if Input.is_action_pressed("p2_rotate_left"):
				player2.rotate_left()
			elif Input.is_action_just_released("p2_rotate_left"):
				player2.stop_thrusters()
			if Input.is_action_pressed("p1_rotate_right"):
				player1.rotate_right()
			elif Input.is_action_just_released("p1_rotate_right"):
				player1.stop_thrusters()
			if Input.is_action_pressed("p2_rotate_right"):
				player2.rotate_right()
			elif Input.is_action_just_released("p2_rotate_right"):
				player2.stop_thrusters()
			if Input.is_action_just_pressed("p1_shoot"):
				player1.shoot()
			if Input.is_action_just_pressed("p2_shoot"):
				player2.shoot()
			if Input.is_action_just_pressed("pause"):
				state = States.PAUSED
				$Menus/Pause.visible = true
				$Menus/Pause/PauseCooldownTimer.start()
				pause_gameplay()
		States.PAUSED:
			if Input.is_action_just_pressed("pause"):
				state = States.PLAYING
				$Menus/Pause.visible = false
				unpause_gameplay()


func _ai_player_turn() -> void:
	var p1_position = player1.get_global_position()
	var p2_position = player2.get_global_position()
	
	var angle = rad_to_deg(p2_position.angle_to_point(p1_position)) + 90
	var p2_rotation = player2.get_global_rotation_degrees()
	var difference = angle - p2_rotation
	
	#print("angle = %s" % angle)
	#print("p2 rotation = %s" % p2_rotation)
	#print("difference = %s" % difference)
	
	# rotate toward the other player
	if (
			(difference > 10
			and difference < 150)
			or
			(difference < -210
			and difference > -350)
	):
		Input.call_deferred("action_release", "p2_rotate_left")
		Input.call_deferred("action_press", "p2_rotate_right")
	elif (
	 		(difference < -10
			and difference > -150)
			or
			(difference > 210
			and difference < 350)
	):
		Input.call_deferred("action_release", "p2_rotate_right")
		Input.call_deferred("action_press", "p2_rotate_left")
	else:
		# shoot and follow
		Input.action_release("p2_rotate_right")
		Input.action_release("p2_rotate_left")
		Input.action_press("p2_shoot")
		Input.call_deferred("action_release", "p2_shoot")
		Input.action_press("p2_thrust_forward")
		Input.call_deferred("action_release", "p2_thrust_forward")


func _physics_process(delta: float) -> void:
	if state == States.PLAYING:
		$Gameplay/Star/Body.rotate(delta * 1)
		$Gameplay/Star/Corona1.rotate(delta * -0.25)
		$Gameplay/Star/Corona2.rotate(delta * 0.125)


func _unhandled_input(event: InputEvent) -> void:
	if state != States.LAUNCH: return
	
	if event.is_action("ui_cancel"):
		if (
			event.device == 0
			and player1_ready
		):
			player1_ready = false
			%ReadyColorP1.visible = false
			%ReadyLabelP1.visible = false
			%NotReadyLabelP1.visible = true
			%Countdown.visible = false
			%ReadyTimer.stop()
			ready_countdown = READY_COUNTDOWN
		elif (
			event.device == 1
			and player2_ready
		):
			player2_ready = false
			%ReadyColorP2.visible = false
			%ReadyLabelP2.visible = false
			%NotReadyLabelP2.visible = true
			%Countdown.visible = false
			%ReadyTimer.stop()
			ready_countdown = READY_COUNTDOWN


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if state == States.LAUNCH:
		if Input.get_connected_joypads().size() < 1:
			%ControllersRequired.visible = true
		else:
			%ControllersRequired.visible = false
	elif state == States.PLAYING:
		match device:
			0:
				if not connected:
					pause_gameplay()
					%DisconnectedMessage.visible = true
					disconnection_paused = true
					player1_disconnected = true
				else:
					player1_disconnected = false
					if (
							disconnection_paused
							and not player2_disconnected
					):
						%DisconnectedMessage.visible = false
						unpause_gameplay()
			1:
				if not connected:
					pause_gameplay()
					%DisconnectedMessage.visible = true
					disconnection_paused = true
					player2_disconnected = true
				else:
					player2_disconnected = false
					if (
							disconnection_paused
							and not player1_disconnected
					):
						%DisconnectedMessage.visible = false
						unpause_gameplay()


func _on_player_damaged(hp: int, which_player: int) -> void:
	get_node("%%Player%sHP" % which_player).text = str(hp)
	var tween = get_tree().create_tween()
	tween.tween_property($Gameplay/ScreenFX/Flash, "color", Color(1,1,1,1), 0.1).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($Gameplay/ScreenFX/Flash, "color", Color(1,1,1,0), 0.1)


func _on_player_destroyed(player_number: int) -> void:
	state = States.GAME_OVER
	pause_gameplay()
	_show_game_over_screen("Player %s wins!" % (1 if player_number == 2 else 2))


#func _on_players_collided() -> void:
	#state = States.GAME_OVER
	#pause_gameplay()
	#_show_game_over_screen("Ships Collided: NO Winners!")


func _on_star_body_entered(body: Node2D) -> void:
	var collision_groups = body.get_groups()
	if collision_groups.has("ships"):
		if body == player1:
			$SunCollisionSound.finished.connect(func(): _on_player_destroyed(1))
			$SunCollisionSound.play()
			player1.explode()
		else:
			$SunCollisionSound.finished.connect(func(): _on_player_destroyed(2))
			$SunCollisionSound.play()
			player2.explode()
	elif collision_groups.has("torpedoes"):
		body.queue_free()


func _show_game_over_screen(message: String = "") -> void:
	if message != "":
		%GameOverSummary.text = message
	$Menus/GameOver.visible = true
	$Menus/GameOver/GameOverCooldown.start()


func _pause_gameplay() -> void:
	$Gameplay.process_mode = PROCESS_MODE_DISABLED
	get_tree().set_group("ships", "process_mode", PROCESS_MODE_DISABLED)
	get_tree().set_group("torpedoes", "process_mode", PROCESS_MODE_DISABLED)


func pause_gameplay() -> void:
	call_deferred("_pause_gameplay")


func unpause_gameplay() -> void:
	$Gameplay.process_mode = PROCESS_MODE_INHERIT
	get_tree().set_group("ships", "process_mode", PROCESS_MODE_INHERIT)
	get_tree().set_group("torpedoes", "process_mode", PROCESS_MODE_INHERIT)


func _on_resume_button_pressed() -> void:
	if state == States.PAUSED:
		state = States.PLAYING
		$Menus/Pause.visible = false
		unpause_gameplay()


func _on_play_again_button_pressed() -> void:
	reset()


func _on_credits_button_pressed() -> void:
	if state == States.GAME_OVER:
		$Menus/GameOver.visible = false
	$Menus/Credits.visible = true
	%DismissCreditsButton.call_deferred("grab_focus")


func _on_dismiss_credits_button_pressed() -> void:
	$Menus/Credits.visible = false
	match state:
		States.GAME_OVER:
			_show_game_over_screen()
		States.PAUSED:
			$Menus/Pause/PauseCooldownTimer.start()
		States.LAUNCH:
			%NotReadyColor.call_deferred("grab_focus")


func reset() -> void:
	$Menus/GameOver.visible = false
	get_tree().call_group("ships", "free")
	get_tree().call_group("torpedoes", "free")
	player1_ready = false
	%ReadyColorP1.visible = false
	%ReadyLabelP1.visible = false
	%NotReadyLabelP1.visible = true
	player2_ready = false
	%ReadyColorP2.visible = false
	%ReadyLabelP2.visible = false
	%NotReadyLabelP2.visible = true
	ready_countdown = READY_COUNTDOWN
	%Countdown.visible = false
	%NotReadyColor.call_deferred("grab_focus")
	unpause_gameplay()
	state = States.LAUNCH


func _on_pause_cooldown_timer_timeout() -> void:
	%ResumeButton.call_deferred("grab_focus")


func _on_game_over_cooldown_timeout() -> void:
	%PlayAgainButton.call_deferred("grab_focus")


# counts down before starting game giving the players time to join
func _on_ready_timer_timeout() -> void:
	%Countdown.visible = true
	if ready_countdown > 1:
		ready_countdown -= 1
		%CountdownSeconds.text = str(ready_countdown)
		%ReadyTimer.start()
	else:
		start_game()


func start_game() -> void:
	player1 = PLAYER1.instantiate()
	add_child(player1)
	player1.position = Vector2(1920*0.125, 1080*0.5)
	player1.rotation_degrees = randf_range(0, 360)
	player1.damaged.connect(_on_player_damaged.bind(1))
	player1.destroyed.connect(_on_player_destroyed.bind(1))
	#player1.collided.connect(_on_players_collided)
	%Player1HP.text = str(player1.get_hp())
	
	player2 = PLAYER2.instantiate()
	add_child(player2)
	player2.torpedo_color = Color8(192, 34, 49, 255)
	player2.position = Vector2(1920*0.875, 1080*0.5)
	player2.rotation_degrees = randf_range(0, 360)
	player2.damaged.connect(_on_player_damaged.bind(2))
	player2.destroyed.connect(_on_player_destroyed.bind(2))
	%Player2HP.text = str(player2.get_hp())
	
	if Input.get_connected_joypads().size() == 1:
		mode = Modes.SINGLE_PLAYER
	else:
		if (
				player1_ready
				and player2_ready
		):
			mode = Modes.TWO_PLAYER
		else:
			mode = Modes.SINGLE_PLAYER

	$Menus/Join.visible = false
	state = States.PLAYING


func _on_quit_button_pressed() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
