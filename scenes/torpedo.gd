extends RigidBody2D

const THRUST = 50_000
const DAMAGE: int = 10


func _physics_process(_delta: float) -> void:
	# NOTE: Modify global_position so collision keeps working after wrapping around the screen
	var viewport_rect = get_viewport_rect()
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
		pass
	queue_free()


func get_damage() -> int:
	return DAMAGE


func set_color(new_color: Color) -> void:
	$Polygon2D.color = new_color
