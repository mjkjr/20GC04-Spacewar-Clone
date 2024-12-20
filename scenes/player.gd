class_name Player extends RigidBody2D

signal damaged(int)
signal destroyed
#signal collided

enum Launchers { LEFT, RIGHT }

const THRUST: float = 100_000
const TORQUE: float = 2_000_000
const MAX_HP: int = 100
const COLLISION_DAMAGE: int = 20

const TORPEDO = preload("res://scenes/torpedo.tscn")
const EXPLOSION = preload("res://scenes/explosion.tscn")

var hp: int = MAX_HP
var thrusters_ready: bool = true
var launchers_ready: Array[bool] = [true, true]
var next_launcher: Launchers = Launchers.LEFT
var torpedo_color: Color = Color8(255, 247, 97, 255)

#var damage_tween: Tween = null


func _physics_process(_delta: float) -> void:
	# TODO: adjust this to account for the size of the player so it doesn't "pop" in and out of
	# existence on either side of the screen
	# TODO: raycast a collider to the opposite side and check for collisions before moving
	
	# NOTE: Modify global_position so collision keeps working after wrapping around the screen
	var viewport_rect = get_viewport_rect()
	var wrapped: Vector2
	wrapped.x = wrapf(global_position.x, 0, viewport_rect.size.x)
	wrapped.y = wrapf(global_position.y, 0, viewport_rect.size.y)
	if wrapped.x != global_position.x:
		global_position.x = wrapped.x
	if wrapped.y != global_position.y:
		global_position.y = wrapped.y


func thrust() -> void:
	var directed_force = Vector2.UP.rotated(rotation)
	directed_force *= THRUST
	apply_central_force(directed_force)
	$Thrusters/AnimationPlayer.play("thrusters")
	if not $ThrusterSound.playing:
		$ThrusterSound.play()


func stop_thrusters() -> void:
	$Thrusters/AnimationPlayer.play("RESET")


func rotate_left() -> void:
	apply_torque(-TORQUE)
	$Thrusters/AnimationPlayer.play("thrust_left")
	if not $ThrusterSound.playing:
		$ThrusterSound.play()


func rotate_right() -> void:
	apply_torque(TORQUE)
	$Thrusters/AnimationPlayer.play("thrust_right")
	if not $ThrusterSound.playing:
		$ThrusterSound.play()


func shoot() -> void:
	if (
			next_launcher == Launchers.LEFT
			and launchers_ready[Launchers.LEFT]
	):
		var torpedo = TORPEDO.instantiate()
		torpedo.set_color(torpedo_color)
		torpedo.set_linear_velocity(get_linear_velocity())
		get_parent().add_child(torpedo)
		torpedo.global_rotation = $TorpedoLauncherLeft.global_rotation
		torpedo.global_position = $TorpedoLauncherLeft.global_position
		launchers_ready[Launchers.LEFT] = false
		$LauncherCooldownLeft.start()
		next_launcher = Launchers.RIGHT
		$Shoot.play()
	elif (
			next_launcher == Launchers.RIGHT
			and launchers_ready[Launchers.RIGHT]
	):
		var torpedo = TORPEDO.instantiate()
		torpedo.set_color(torpedo_color)
		torpedo.set_linear_velocity(get_linear_velocity())
		get_parent().add_child(torpedo)
		torpedo.global_rotation = $TorpedoLauncherRight.global_rotation
		torpedo.global_position = $TorpedoLauncherRight.global_position
		launchers_ready[Launchers.RIGHT] = false
		$LauncherCooldownRight.start()
		next_launcher = Launchers.LEFT
		$Shoot.play()


func _on_body_entered(body: Node) -> void:
	var collision_groups = body.get_groups()
	if collision_groups.has("ships"):
		hp -= COLLISION_DAMAGE
		damaged.emit(hp)
		if hp <= 0:
			#collided.emit()
			explode()
			#queue_free()
	elif collision_groups.has("torpedoes"):
		hp -= body.get_damage()
		damaged.emit(hp)
		if not $Hit.playing:
			$Hit.play()
		if hp <= 0:
			explode()
			#queue_free()


func explode() -> void:
	var explosion = EXPLOSION.instantiate()
	$Ship.visible = false
	$Thrusters.visible = false
	add_child(explosion)
	explosion.animation_finished.connect(func(): destroyed.emit())
	explosion.play()


func _on_launcher_cooldown_left_timeout() -> void:
	launchers_ready[Launchers.LEFT] = true


func _on_launcher_cooldown_right_timeout() -> void:
	launchers_ready[Launchers.RIGHT] = true


func get_hp() -> int:
	return hp
