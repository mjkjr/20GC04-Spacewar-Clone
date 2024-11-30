extends RigidBody2D

const THRUST = 2_500


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
	
	var directed_force = Vector2.UP.rotated(rotation)
	directed_force *= THRUST
	apply_central_force(directed_force)


func _on_lifetime_timeout() -> void:
	queue_free()


func _on_body_entered(body: Node) -> void:
	if body.get_groups().has("torpedoes"):
		# TODO: explosion effect
		queue_free()
