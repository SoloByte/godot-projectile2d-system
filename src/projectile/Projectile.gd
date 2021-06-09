extends CollisionShape2D
class_name Projectile




signal Spawned(projectile, pos, info)
signal Despawned(projectile, pos)
signal Destroyed(projectile, pos) #happens before despawn
signal Impact(projectile, pos, impact_info)



export(float) var lifetime = 1.0

export(int, LAYERS_2D_PHYSICS) var collision_layer
export(bool) var collide_with_bodies = true
export(bool) var collide_with_areas = false
export(float) var margin : float = 0.0
export(int) var max_results : int = 6

export(int, "Impact", "Bounce", "Pierce") var move_behaviour : int = 0



func isPiercing() -> bool:
	return move_behaviour == 2

func isBouncing() -> bool:
	return move_behaviour == 1

func isImpact() -> bool:
	return move_behaviour == 0

func getLifetimePercent() -> float:
	if not hasLifetime():
		return 0.0
	return _lifetime_timer / lifetime

func hasLifetime() -> bool:
	return lifetime > 0.0

func isDestroyed() -> bool:
	return _destroyed or (hasLifetime() and getLifetimePercent() <= 0.0)

func getForward() -> Vector2:
	return get_global_transform().x




var _move_query : Physics2DShapeQueryParameters = null
var _lin_vel := Vector2.ZERO
var _ang_vel : float = 0.0

var _excluded : Array = []
var _lifetime_timer : float = 0.0
var _destroyed : bool = false




func _spawn(pos : Vector2, rot : float, info : Dictionary = {}) -> void:
	emit_signal("Spawned", self, pos, info)
	onSpawned(info)
	
	_lifetime_timer = lifetime
	visible = true
	_destroyed = false

func _despawn() -> void:
	emit_signal("Despawned", self, global_position)
	onDespawned()
	
	queue_free()

func _destroy() -> void:
	emit_signal("Destroyed", self, global_position)
	onDestroyed()
	
	_destroyed = true
	_lifetime_timer = 0.0
	visible = false
	call_deferred("_despawn")

func _impact(impact_info : Dictionary) -> void:
	#impact stuff comes here
	
	#last
	emit_signal("Impact", self, impact_info)
	onImpact(impact_info)




func _process(delta: float) -> void:
	if isDestroyed(): return
	
	if hasLifetime() and _lifetime_timer > 0.0:
		_lifetime_timer -= delta
		if _lifetime_timer <= 0.0:
			_lifetime_timer = 0.0
			_destroy()




#these are functions that work like signals and can be overridden in child classes
#they are always called last
func onSpawned(info : Dictionary) -> void:
	pass

func onDespawned() -> void:
	pass

func onImpact(impact_info : Dictionary) -> void:
	pass

func onDestroyed() -> void:
	pass
#--------------------------


func move(delta : float) -> void:
	var motion : Vector2 = _lin_vel * delta
	var result : Array = checkMove(motion)
	var fraction : float = result[1] 
	
	if  fraction >= 1.0: #no collision
		global_position += motion * fraction
		global_rotation += _ang_vel * delta * fraction
	
	else: #collision
		var collision : Dictionary = collide()
		if collision:
#			emit_signal("Impact", self, global_position, collision)
#			_impact(collision)
			
			match move_behaviour:
				0: #impact
					pass
				1: #bounce
					pass
				2: #pierce
					pass
				_: 
					pass

func collide() -> Dictionary:
	updateMoveQuery()
	return getSpaceState().get_rest_info(_move_query)


func checkMove(motion : Vector2) -> Array:
	updateMoveQuery(motion)
	return getSpaceState().cast_motion(_move_query)

func updateMoveQuery(motion := Vector2.ZERO) -> void:
	if not _move_query:
		_move_query = createMoveQuery()
	
	_move_query.transform = get_global_transform()
	_move_query.motion = motion

func createMoveQuery() -> Physics2DShapeQueryParameters:
	var query := Physics2DShapeQueryParameters.new()
	query.set_shape(shape)
	query.motion = Vector2.ZERO
	query.collision_layer = collision_layer
	query.exclude = _excluded
	query.collide_with_bodies = collide_with_bodies
	query.collide_with_areas = collide_with_areas
	query.transform = get_global_transform()
	query.margin = margin
	return query





func getSpaceState() ->  Physics2DDirectSpaceState:
	return get_world_2d().direct_space_state












#COLLISION ---------------------------------------------------------------------
#func addExclusion(obj) -> void:
#	_excluded.append(obj)
#
#func removeExclusion(obj) -> void:
#	if not _excluded or _excluded.size() <= 0: return
#	var index : int = _excluded.find(obj)
#	removeExclusionIndex(index)
#
#func removeExclusionIndex(index : int) -> void:
#	if not _excluded or _excluded.size() <= 0: return
#	if index < 0 or index >= _excluded.size(): return
#	_excluded.remove(index)
#
#
#func getQuery() -> Physics2DShapeQueryParameters:
#	if not _move_query:
#		setQuery(createQuerySimple())
#	return _move_query
#
#func setQuery(query : Physics2DShapeQueryParameters) -> void:
#	_move_query = query
#
#
#func updateQuery(pos : Vector2, rot : float) -> void:
#	updateCustomQuery(getQuery(), pos, rot, _excluded)
#
#func updateCustomQuery(query : Physics2DShapeQueryParameters, pos : Vector2, rot : float, excluded = []) -> void:
#	if not query: return
#	query.transform = Transform2D(rot, pos)
#	query.exclude = excluded
#
#
#func createQuerySimple() -> Physics2DShapeQueryParameters:
#	return createQuery(global_position, global_rotation, Vector2.ZERO, shape, collision_layer, _excluded, collide_with_bodies, collide_with_areas, margin)
#
#func createQuery(_pos : Vector2, _rot : float, _motion : Vector2, _shape, _collision_layer, _exclude : Array = [], _collide_with_bodies : bool = true, _collide_with_areas : bool = false, _margin : float = 0.0) -> Physics2DShapeQueryParameters:
#	var query := Physics2DShapeQueryParameters.new()
#	query.set_shape(_shape)
#	query.motion = _motion
#	query.collision_layer = _collision_layer
#	query.exclude = _exclude
#	query.collide_with_bodies = _collide_with_bodies
#	query.collide_with_areas = _collide_with_areas
#	query.transform = Transform2D(_rot, _pos)
#	query.margin = _margin
#	return query


#-------------------------------------------------------------------------------



static func filterResults(result : Array) -> Array:
#	print("results: ", result)
	if not result or result.size() <= 0:
		return []
	if result.size() == 1:
		return [result[0].collider]

	var filtered : Array = []
	for i in range(result.size()):
		var body = result[i].collider
		if not body in filtered:
			filtered.append(body)

	return filtered

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
























#export(int, LAYERS_2D_PHYSICS) var exp_collision_layer
#export(bool) var exp_collide_with_bodies = true
#export(bool) var exp_collide_with_areas = false
#export(float) var exp_margin : float = 0.0
#export(int) var exp_max_results : int = 6

#var _exp_query : Physics2DShapeQueryParameters = null
#var _exp_shape : CircleShape2D = null
#
#func setExpShapeRadius(r : float) -> void:
#	if r <= 0.0: return
#	getExpShape().radius = r
#
#func getExpShape() -> CircleShape2D:
#	if _exp_shape == null:
#		_exp_shape = CircleShape2D.new()
#		_exp_shape.radius = self.radius
#	return _exp_shape
#
#func getExpQuery() -> Physics2DShapeQueryParameters:
#	if not _move_query:
#		setExpQuery(createExpQuerySimple())
#	return _move_query
#
#func setExpQuery(query : Physics2DShapeQueryParameters) -> void:
#	_exp_query = query
#
#func createExpQuerySimple() -> Physics2DShapeQueryParameters:
#	return createQuery(global_position, global_rotation, Vector2.ZERO, getExpShape(), exp_collision_layer, [], exp_collide_with_bodies, exp_collide_with_areas, exp_margin)
#
#func updateExpQuery(pos : Vector2, rot : float, r : float = -1.0) -> void:
#	setExpShapeRadius(r)
#	updateCustomQuery(getExpQuery(), pos, rot, null, [])
#
#func castExp(r : float = -1.0) -> Array:
#	updateExpQuery(global_position, global_rotation, r)
#	return getSpaceState().intersect_shape(getExpQuery(), exp_max_results)






#CAST STUFF

#export(float) var radius : float = 1.0
#export(int, LAYERS_2D_PHYSICS) var collision_layer
#
#export(int) var max_results : int = 6
#export(float) var margin : float = 0.0
#
#export(bool) var collide_with_bodies = true
#export(bool) var collide_with_areas = false
#
#
#
#
#var _move_query : Physics2DShapeQueryParameters = null
#var _exp_shape : CircleShape2D = null
#var _excluded : Array = []
#
#
#
#
#func addExclusion(obj) -> void:
#	_excluded.append(obj)
#
#func removeExclusion(obj) -> void:
#	if not _excluded or _excluded.size() <= 0: return
#	var index : int = _excluded.find(obj)
#	removeExclusionIndex(index)
#
#func removeExclusionIndex(index : int) -> void:
#	if not _excluded or _excluded.size() <= 0 or index < 0 or index >= _excluded.size(): return
#	_excluded.remove(index)
#
#
#
#func setCircleShapeRadius(r : float) -> void:
#	if r <= 0.0: return
#	getCircleShape().radius = r
#
#
#func getCircleShape() -> CircleShape2D:
#	if _exp_shape == null:
#		_exp_shape = CircleShape2D.new()
#		_exp_shape.radius = self.radius
#	return _exp_shape
#
#
#func getQuery() -> Physics2DShapeQueryParameters:
#	if not _move_query:
#		setQuery(createQuerySimple())
#	return _move_query
#
#func setQuery(query : Physics2DShapeQueryParameters) -> void:
#	_move_query = query
#
#
#func updateQuery(pos : Vector2, rot : float, r : float = -1.0) -> void:
#	setCircleShapeRadius(r)
#	updateCustomQuery(getQuery(), pos, rot, null)
#
#func updateCustomQuery(query : Physics2DShapeQueryParameters, pos : Vector2, rot : float, shape = null) -> void:
#	if not query: return
#	query.transform = Transform2D(rot, pos)
#	if shape:
#		query.set_shape(shape)
#
#
#
#func createQuerySimple() -> Physics2DShapeQueryParameters:
#	return createQuery(global_position, global_rotation, Vector2.ZERO, getCircleShape(), collision_layer, _excluded, collide_with_bodies, collide_with_areas, margin)
#
#func createQuery(_pos : Vector2, _rot : float, _motion : Vector2, _shape, _collision_layer, _exclude : Array = [], _collide_with_bodies : bool = true, _collide_with_areas : bool = false, _margin : float = 0.0) -> Physics2DShapeQueryParameters:
#	var query := Physics2DShapeQueryParameters.new()
#	query.set_shape(_shape)
#	query.motion = _motion
#	query.collision_layer = _collision_layer
#	query.exclude = _exclude
#	query.collide_with_bodies = _collide_with_bodies
#	query.collide_with_areas = _collide_with_areas
#	query.transform = Transform2D(_rot, _pos)
#	query.margin = _margin
#	return query
#
#
#func getSpaceState() ->  Physics2DDirectSpaceState:
#	return get_world_2d().direct_space_state
#
#
#
#
#func cast(r : float = -1.0) -> Array:
#	updateQuery(global_position, global_rotation, r)
#	return intersectShape(getQuery(), max_results)
#
#func castStatic(r : float = -1.0) -> Array:
#	setCircleShapeRadius(r)
#	return intersectShape(getQuery(), max_results)
#
#func castCustom(_pos : Vector2, _rot : float, _shape, _collision_layer, _exclude : Array = [], _collide_with_bodies : bool = true, _collide_with_areas : bool = false, _margin : float = 0.0, max_results : int = 32) -> Array:
#	var query = createQuery(_pos, _rot, Vector2.ZERO, _shape, _collision_layer, _exclude, _collide_with_bodies, _collide_with_areas, _margin)
#	return intersectShape(query, max_results)
#
#
#static func filterResults(result : Array) -> Array:
#	print("results: ", result)
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
#
#static func filterResultsAdv(result : Array) -> Dictionary:
#	if not result or result.size() <= 0:
#		return {}
#
#	var filtered : Dictionary = {}
#	if result.size() == 1:
#		filtered[result[0].collider_id] = {"body" : result[0].collider, "shapes" : [result[0].shape]}
#		return filtered
#
#	for r in result:
#		if filtered.has(r.collider_id):
#			filtered[r.collider_id].shapes.append(r.shape)
#		else:
#			filtered[r.collider_id] = {"body" : r.collider, "shapes" : [r.shape]}
#
#	return filtered
#
#
#func castMotion(query : Physics2DShapeQueryParameters) -> Array:
#	return getSpaceState().cast_motion(query)
#
#
#func getCollisionPoints(query : Physics2DShapeQueryParameters, max_results : int = 32) -> Array:
#	return getSpaceState().collide_shape(query, max_results)
