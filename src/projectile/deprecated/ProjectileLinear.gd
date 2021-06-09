#extends Projectile
#class_name ProjectileLinear
#
##the density of the fluid the projectile passes through (air for example)
#const DRAG_RHO : float = 0.1
#
#
#
#export(bool) var rotate_towards_heading : bool = true
#export(float) var lin_start_speed = 0.0
##export(Curve) var lin_speed_curve
#export(float) var lin_drag_coef : float = 0.98
#export(float) var lin_accel = 0.0
#export(float) var mass : float = 1.0
#
#export(Vector2) var gravity_direction = Vector2.ZERO
#export(float) var gravity_scale : float = 0.0
#export(Curve) var gravity_scale_factor_curve #is multiplied with gravity scale
#
#
#
#var _prev_lin_accel := Vector2.ZERO
#var _lin_accel := Vector2.ZERO
#var _lin_vel := Vector2.ZERO
#var _lin_vel_mag : float = 0.0
#
#
#
#func getGravityForce() -> Vector2:
#	var curve_factor : float = 1.0
#	if gravity_scale_factor_curve:
#		curve_factor = gravity_scale_factor_curve.interpolate_baked(getLifetimePercent())
#	return gravity_direction * gravity_scale * curve_factor
#
#
#
#
#func _spawn(pos : Vector2, rot : float, info : Dictionary = {}) -> void:
#	._spawn(pos, rot, info)
#	global_position = pos
#	global_rotation = rot
#	_lin_vel = getForward() * lin_start_speed
#
##func _despawn() -> void:
##	._despawn()
#
#func _destroy() -> void:
#	._destroy()
#	_prev_lin_accel = Vector2.ZERO
#	_lin_accel = Vector2.ZERO
#	_lin_vel = Vector2.ZERO
#
#
#
#
#func _physics_process(delta: float) -> void:
#	applyVelocity(delta)
#	applyForces(delta)
#	applyAcceleration(delta)
#
##	var drag : Vector2 = getDragForce(_lin_vel, DRAG_RHO, lin_drag_coef) * delta #* 60
##	drag = drag / mass
#	var drag : Vector2 = -_lin_vel * lin_drag_coef * delta
##	drag = drag.clamped(_lin_vel_mag)
#	if drag.length_squared() >= _lin_vel_mag * _lin_vel_mag:
#		_lin_vel = Vector2.ZERO
#		_lin_vel_mag = 0.0
#	else:
#		_lin_vel += drag
#		_lin_vel_mag = _lin_vel.length()
#
#	if rotate_towards_heading:
#		global_rotation = getForward().angle()
#
#
#
#
#func addForce(force : Vector2) -> void:
#	_lin_accel = _lin_accel + (force / mass)
#
#
#
#func applyForces(delta : float) -> void:
##	var drag : Vector2 = getDragForce(_lin_vel, DRAG_RHO, lin_drag_coef) * delta #* 60
##	drag = drag / mass
##	_lin_accel += drag.clamped(_lin_vel_mag * (1.0 / delta))
#
#	var grav : Vector2 = getGravityForce() * delta #* 60
#	_lin_accel += grav
#
#func applyAcceleration(delta : float) -> void:
#	_lin_vel += (_lin_accel + _prev_lin_accel) * (delta * 0.5)
#	_prev_lin_accel = _lin_accel
#	_lin_vel_mag = _lin_vel.length()
#	_lin_accel = getForward() * lin_accel
#
#func applyVelocity(delta : float) -> void:
#	var vel_part : Vector2 = _lin_vel * delta
#	var accel_part : Vector2 = _lin_accel * (delta * delta * 0.5)
#	global_position += vel_part + accel_part
#
#
#
##func getDragForce(vel : Vector2, rho : float, coef : float) -> Vector2:
##	var dir : Vector2 = vel.normalized()
##	var mag : float = vel.length_squared()
##	var drag_force : Vector2 = 0.5 * rho * coef * dir * mag
##	return -drag_force
