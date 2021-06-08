extends Node2D




export(PackedScene) var test_projectile




onready var _projectile_parent := $ProjectileParent
onready var _turret := $Turret
onready var _projectile_spawn_pos := $Turret/ProjectileSpawnPos



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot"):
		spawnProjectile()

func _process(delta: float) -> void:
	_turret.global_rotation = (get_global_mouse_position() - _turret.global_position).angle()

func spawnProjectile() -> void:
	if not test_projectile: return 
	
	var projectile = test_projectile.instance()
	_projectile_parent.add_child(projectile)
	var pos : Vector2 = _projectile_spawn_pos.global_position
	var accuracy : float = deg2rad(3.0)
	var angle : float = _turret.global_rotation + rand_range(-accuracy, accuracy)
	projectile._spawn(pos, angle)
