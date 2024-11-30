class_name Player extends RigidBody2D

signal destroyed
signal collided

enum Position { LEFT, RIGHT }
enum ThrustDirection { FORWARD = 1, REVERSE = -1 }

const THRUST = 100_000
const TORQUE = 2

const TORPEDO = preload("res://scenes/torpedo.tscn")

var next_launcher: Position = Position.LEFT
var launcher_ready: Array[bool] = [true, true]


func _physics_process(_delta: float) -> void:
	var viewport_rect = get_viewport_rect()
	# TODO: adjust this to account for the size of the player so it doesn't "pop" in and out of
	# existence on either side of the screen
	# TODO: raycast a collider to the opposite side and check for collisions before moving
	# NOTE: Modify global_position so collision keeps working after wrapping around the screen
	var wrapped: Vector2
	wrapped.x = wrapf(global_position.x, 0, viewport_rect.size.x)
	wrapped.y = wrapf(global_position.y, 0, viewport_rect.size.y)
	if wrapped.x != global_position.x:
		global_position.x = wrapped.x
	if wrapped.y != global_position.y:
		global_position.y = wrapped.y


func thrust(direction: ThrustDirection) -> void:
	var directed_force = Vector2.UP.rotated(rotation)
	directed_force *= THRUST * direction
	apply_central_force(directed_force)


func rotate_left() -> void:
	apply_torque(-TORQUE)


func rotate_right() -> void:
	apply_torque(TORQUE)


func fire_torpedo() -> void:
	if (
			next_launcher == Position.LEFT
			and launcher_ready[Position.LEFT]
	):
		var torpedo = TORPEDO.instantiate()
		# rotation must be set before adding to scene tree
		torpedo.rotation = rotation
		torpedo.set_linear_velocity(get_linear_velocity())
		get_parent().add_child(torpedo)
		torpedo.global_position = $TorpedoLauncherLeft.global_position
		launcher_ready[Position.LEFT] = false
		$LauncherCooldownLeft.start()
		next_launcher = Position.RIGHT
	elif (
			next_launcher == Position.RIGHT
			and launcher_ready[Position.RIGHT]
	):
		var torpedo = TORPEDO.instantiate()
		# rotation must be set before adding to scene tree
		torpedo.rotation = rotation
		torpedo.linear_velocity = get_linear_velocity()
		get_parent().add_child(torpedo)
		torpedo.global_position = $TorpedoLauncherRight.global_position
		launcher_ready[Position.RIGHT] = false
		$LauncherCooldownRight.start()
		next_launcher = Position.LEFT


func _on_body_entered(body: Node) -> void:
	var collision_groups = body.get_groups()
	if collision_groups.has("ships"):
		collided.emit()
	elif collision_groups.has("torpedoes"):
		# TODO: explosion effect
		destroyed.emit()
		queue_free()
	#else:
		#print("collided with the star")


func _on_launcher_cooldown_left_timeout() -> void:
	launcher_ready[Position.LEFT] = true


func _on_launcher_cooldown_right_timeout() -> void:
	launcher_ready[Position.RIGHT] = true
