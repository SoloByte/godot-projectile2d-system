extends CollisionShape2D
class_name Projectile




signal Spawned(projectile, pos, info)
signal Despawned(projectile, pos)
signal Destroyed(projectile, pos) #happens before despawn

signal Impact(projectile, pos, impact_info)
signal Pierced(projectile, pos, pierce_info)
signal Bounced(projectile, pos, bounce_info)

signal Exploded(projectile, pos, r, bodies)



#export(int, 1, 5) var iterations : int = 1
export(float) var lifetime = 1.0
export(bool) var rotate_parent : bool = false
export(float) var mass : float = 1.0
export(String) var bedrock_group = "Bedrock"

export(int, LAYERS_2D_PHYSICS) var collision_layer
export(bool) var collide_with_bodies = true
export(bool) var collide_with_areas = false
export(float) var margin : float = 0.0
export(int) var max_results : int = 12

export(int, "Impact", "Bounce", "Pierce") var move_behaviour : int = 0
export(int) var bounce_count = 0 #-1 = infinite bounces / 0 = no bounce
export(int) var pierce_count = 0 #-1 = infinite pierces / 0 = no pierce




func isPiercing() -> bool:
	return move_behaviour == 2

func isBouncing() -> bool:
	return move_behaviour == 1

func isImpact() -> bool:
	return move_behaviour == 0

func getLifetimePercent() -> float:
	if not hasLifetime():
		return 0.0
	return clamp(_lifetime_timer / lifetime, 0.0, 1.0)

func hasLifetime() -> bool:
	return lifetime > 0.0

func isDestroyed() -> bool:
	return _destroyed or (hasLifetime() and getLifetimePercent() <= 0.0)

func getForward() -> Vector2:
	return get_global_transform().x

func hasBouncesLeft() -> bool:
	return bounce_count != 0 and (_bounces < bounce_count or bounce_count < 0)

func hasPiercesLeft() -> bool:
	return pierce_count != 0 and (_pierces < pierce_count or pierce_count < 0)




var _move_query : Physics2DShapeQueryParameters = null
var _lin_vel := Vector2.ZERO
var _ang_vel : float = 0.0

var _excluded : Array = []
var _lifetime_timer : float = 0.0
var _destroyed : bool = false
var _bounces : int = 0
var _pierces : int = 0




onready var rng := RandomNumberGenerator.new()




func _setup(info : Dictionary = {}) -> void:
	rng.randomize()
	_destroyed = true
	_lifetime_timer = 0.0
	visible = false
	
	_lin_vel = Vector2.ZERO
	_ang_vel = 0.0
	
	set_process(false)
	set_physics_process(false)

func _spawn(pos : Vector2, rot : float, info : Dictionary = {}) -> void:
	emit_signal("Spawned", self, pos, info)
	onSpawned(info)
	
	_lifetime_timer = lifetime
	visible = true
	_destroyed = false
	_bounces = 0
	_pierces = 0
	
	global_position = pos
	if rotate_parent:
		global_rotation = rot
	
#	_lin_vel = Vector2(100, 0).rotated(rot) * 15
	
	set_process(true)
	set_physics_process(true)

func _despawn() -> void:
	emit_signal("Despawned", self, global_position)
	onDespawned()

func _destroy() -> void:
	emit_signal("Destroyed", self, global_position)
	onDestroyed()
	
	_destroyed = true
	_lifetime_timer = 0.0
	visible = false
	
	_lin_vel = Vector2.ZERO
	_ang_vel = 0.0
	
	set_process(false)
	set_physics_process(false)
	
	call_deferred("_despawn")




func _impact(impact_info : Dictionary, delta : float, rest_fraction : float) -> void:
	emit_signal("Impact", self, impact_info)
	onImpact(impact_info)
	
	global_position += _lin_vel * delta * rest_fraction
	_destroy()

func _pierce(pierce_info : Dictionary, delta : float, rest_fraction : float) -> void:
	emit_signal("Pierced", self, pierce_info)
	onPierce(pierce_info)
	
	if hasPiercesLeft():
		global_position += _lin_vel * delta * rest_fraction
		_pierces += 1
	else:
		_impact(pierce_info, delta, rest_fraction)

func _bounce(bounce_info : Dictionary, delta : float, rest_fraction : float) -> void:
	emit_signal("Bounced", self, bounce_info)
	onBounce(bounce_info)
	
	if hasBouncesLeft():
		var n : Vector2 = bounce_info.normal
		if not n.is_normalized():
#			print("bounce normal not normalized! n: ", n)
			_impact(bounce_info, delta, rest_fraction)
			return
		else:
			global_position += _lin_vel * delta * rest_fraction
			_lin_vel = _lin_vel.bounce(n)
			_bounces += 1
	else:
		_impact(bounce_info, delta, rest_fraction)


func _explode(query : Physics2DShapeQueryParameters, max_results : int = 12) -> Dictionary:
	var r : float = query.shape.radius
	var pos : Vector2 = query.transform.get_origin()
	
	var bodies : Dictionary = circleCast(query, max_results)
	
	if not bodies or bodies.size() <= 0: 
		return {}
	
	emit_signal("Exploded", self, pos, r, bodies)
	onExploded(bodies, pos, r)
	
	return bodies


func _process(delta: float) -> void:
	if isDestroyed(): return
	
	if hasLifetime() and _lifetime_timer > 0.0:
		_lifetime_timer -= delta
		if _lifetime_timer <= 0.0:
			_lifetime_timer = 0.0
			_destroy()

func _physics_process(delta):
	updateAngularVelocity(delta)
	updateLinearVelocity(delta)
	move(delta)
	if rotate_parent and _lin_vel != Vector2.ZERO:
		global_rotation = _lin_vel.angle()



func updateAngularVelocity(delta : float) -> void:
	pass

func updateLinearVelocity(delta : float) -> void:
	pass


#these are functions that work like signals and can be overridden in child classes
#they are always called last
func onSpawned(info : Dictionary) -> void:
	pass

func onDespawned() -> void:
	pass

func onDestroyed() -> void:
	pass


func onImpact(impact_info : Dictionary) -> void:
	pass

func onPierce(pierce_info : Dictionary) -> void:
	pass

func onBounce(bounce_info : Dictionary) -> void:
	pass

func onExploded(bodies : Dictionary, pos : Vector2, r : float) -> void:
	pass
#--------------------------



func move(delta : float, fraction : float = 1.0) -> void:
	if fraction <= 0.0: return
	if _lin_vel == Vector2.ZERO: return
	
	var ang_motion : float = _ang_vel * delta
	_lin_vel = _lin_vel.rotated(ang_motion)
	
	var lin_motion : Vector2 = _lin_vel * delta * fraction
	var result : Array = checkMove(lin_motion)
	
	var safe_fraction : float = result[0]
	var unsafe_fraction : float = result[1]
	
	if unsafe_fraction < 1.0: #collision
		var col_pos : Vector2 = global_position + lin_motion * unsafe_fraction# * 1.1 
		var collision : Dictionary = collide(col_pos)
		if collision and collision.size() > 0:
			if collision.collider.is_in_group(bedrock_group):
#				print("bedrock hit")
				_impact(collision, delta, safe_fraction)
				return
			
			match move_behaviour:
				0: _impact(collision, delta, safe_fraction)
				1: _bounce(collision, delta, safe_fraction)
				2: _pierce(collision, delta, unsafe_fraction)
				_: _impact(collision, delta, safe_fraction)
		else:
			if safe_fraction <= 0.0:
#				print("destroy ", result)
				_destroy()
				return
			
#			print("invalid collision: ", result)
			global_position += lin_motion * safe_fraction
	else:
		global_position += lin_motion


func collide(col_pos : Vector2) -> Dictionary:
	updateMoveQuery(col_pos, Vector2.ZERO)
	var points : Array = getSpaceState().collide_shape(_move_query, max_results)
	var target_point : Vector2
	if not points or points.size() < 0:
#		print("no col points")
		return {}
	
	var ray_start : Vector2 = global_position
	
	var safeguard : Dictionary
	for p in points:
		var dir : Vector2 = p - ray_start
		var ray_end : Vector2 = ray_start + (dir * 2.0)
		var ray_info : Dictionary = getSpaceState().intersect_ray(ray_start, ray_end, _excluded, collision_layer, collide_with_bodies, collide_with_areas)
		if ray_info and ray_info.size() > 0:
			if not isBouncing():
				return ray_info #optimal path not bouncing projectile
			else:
				if ray_info.normal != Vector2.ZERO:
					return ray_info #optimal path bouncing projectile
				else:
#					print("normal problem p: ", p, " start: ", ray_start, " end: ", ray_end)
					if not safeguard:
						safeguard = ray_info
	
	if not safeguard:
#		print("all rays missed")
		return {}
	else:
#		print("safeguard ray info returned: ", safeguard)
		return safeguard


func checkMove(motion : Vector2) -> Array:
	updateMoveQuery(global_position, motion)
	return getSpaceState().cast_motion(_move_query)



func updateMoveQuery(pos : Vector2, motion := Vector2.ZERO) -> void:
	if not _move_query:
		_move_query = createMoveQuery()
	
	var rot : float = 0.0
	if _lin_vel != Vector2.ZERO:
		rot = _lin_vel.angle()
		
	_move_query.transform = Transform2D(rot, pos)
	_move_query.motion = motion

func createMoveQuery() -> Physics2DShapeQueryParameters:
#	var query := Physics2DShapeQueryParameters.new()
#	query.set_shape(shape)
#	query.motion = Vector2.ZERO
#	query.collision_layer = collision_layer
#	query.exclude = _excluded
#	query.collide_with_bodies = collide_with_bodies
#	query.collide_with_areas = collide_with_areas
#	query.transform = get_global_transform()
#	query.margin = margin
	return createQueryTrans(get_global_transform(), shape, collision_layer, Vector2.ZERO, collide_with_bodies, collide_with_areas, _excluded, margin)



func getSpaceState() ->  Physics2DDirectSpaceState:
	return get_world_2d().direct_space_state



func circleCast(query, max_results : int = 12) -> Dictionary:
	var cast_info : Array = getSpaceState().intersect_shape(query, max_results)
	return filterResultsAdv(cast_info)




static func filterResultsAdv(result : Array) -> Dictionary:
	if not result or result.size() <= 0:
		return {}

	var filtered : Dictionary = {}
	if result.size() == 1:
		filtered[result[0].collider_id] = {"body" : result[0].collider, "shapes" : [result[0].shape]}
		return filtered

	for r in result:
		if filtered.has(r.collider_id):
			filtered[r.collider_id].shapes.append(r.shape)
		else:
			filtered[r.collider_id] = {"body" : r.collider, "shapes" : [r.shape]}

	return filtered

static func createQuery(pos : Vector2, cast_shape, col_layer : int, rot : float = 0.0, motion := Vector2.ZERO, col_with_bodies : bool = true, col_with_areas : bool = false, excluded : Array = [], margin : float = 0.0) -> Physics2DShapeQueryParameters:
	var query := Physics2DShapeQueryParameters.new()
	query.set_shape(cast_shape)
	query.motion = motion
	query.collision_layer = col_layer
	query.exclude = excluded
	query.collide_with_bodies = col_with_bodies
	query.collide_with_areas = col_with_areas
	query.transform = Transform2D(rot, pos)
	query.margin = margin
	return query

static func createQueryTrans(trans : Transform2D, cast_shape, col_layer : int, motion := Vector2.ZERO, col_with_bodies : bool = true, col_with_areas : bool = false, excluded : Array = [], margin : float = 0.0) -> Physics2DShapeQueryParameters:
	var query := Physics2DShapeQueryParameters.new()
	query.set_shape(cast_shape)
	query.motion = motion
	query.collision_layer = col_layer
	query.exclude = excluded
	query.collide_with_bodies = col_with_bodies
	query.collide_with_areas = col_with_areas
	query.transform = trans
	query.margin = margin
	return query














#static func filterResults(result : Array) -> Array:
##	print("results: ", result)
#	if not result or result.size() <= 0:
#		return []
#	if result.size() == 1:
#		return [result[0].collider]
#
#	var filtered : Array = []
#	for i in range(result.size()):
#		var body = result[i].collider
#		if not body in filtered:
#			filtered.append(body)
#
#	return filtered







#func updateExpQuery(pos : Vector2, r : float) -> void:
#	_exp_query.transform = Transform2D(0.0, pos)
#	_exp_query.shape.radius = r
#
#func createExpQuery(pos : Vector2, r : float, col_layer : int, col_with_bodies : bool = true, col_with_areas : bool = false, excluded : Array = []) -> Physics2DShapeQueryParameters:
#	var query := Physics2DShapeQueryParameters.new()
#
#	var circle := CircleShape2D.new()
#	circle.radius = r
#	query.set_shape(circle)
#
#	query.motion = Vector2.ZERO
#	query.collision_layer = col_layer
#	query.exclude = excluded
#	query.collide_with_bodies = col_with_bodies
#	query.collide_with_areas = col_with_areas
#	query.transform = Transform2D(0.0, pos)
#	query.margin = 0.0
#	return query
