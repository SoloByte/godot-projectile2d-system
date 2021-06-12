extends Projectile
class_name ProjectileCurve




export(float) var lin_vel_scale = 1.0
export(Curve) var lin_vel_curve


export(bool) var random_start_ang_dir = false
export(float) var ang_vel_scale = 1.0
export(Curve) var ang_vel_curve



var starting_ang_vel_dir : float = 1.0



func getCurLinVelMag() -> float:
	if not lin_vel_curve: return lin_vel_scale
	return lin_vel_curve.interpolate_baked(1.0 - getLifetimePercent()) * lin_vel_scale

func getCurAngVelMag() -> float:
	if not ang_vel_curve: return deg2rad(ang_vel_scale) * starting_ang_vel_dir
	return deg2rad(ang_vel_curve.interpolate_baked(1.0 - getLifetimePercent()) * ang_vel_scale) * starting_ang_vel_dir


func _spawn(pos : Vector2, rot : float, info : Dictionary = {}) -> void:
	._spawn(pos, rot, info)
	
	random_start_ang_dir = 1.0
	if random_start_ang_dir:
		if rng.randf() < 0.5:
			starting_ang_vel_dir = -1.0
	
	_ang_vel = getCurAngVelMag()
	_lin_vel = Vector2.RIGHT.rotated(rot) * getCurLinVelMag()



func updateAngularVelocity(delta : float) -> void:
	_ang_vel = getCurAngVelMag()
	

func updateLinearVelocity(delta : float) -> void:
	var mag : float = getCurLinVelMag()
	_lin_vel = _lin_vel.normalized() * mag
