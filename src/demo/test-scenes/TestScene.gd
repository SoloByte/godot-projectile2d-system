extends Node2D




export(PackedScene) var test_projectile
export(int) var pool_instances : int = 250



onready var _projectile_parent := $ProjectileParent
onready var _turret := $Turret
onready var _projectile_spawn_pos := $Turret/ProjectileSpawnPos

var count : int = 0
var firerate_timer : float = 0.0


var projectiles_ready : Array = []
var projectiles_in_use : Array = []

func _ready():
	for i in range(pool_instances):
		var instance = test_projectile.instance()
		_projectile_parent.add_child(instance)
		
		instance.connect("Despawned", self, "On_Projectile_Despawned")
		
		projectiles_ready.append(instance)
		
		instance._setup()



#func _input(event: InputEvent) -> void:
#	if event.is_action_pressed("shoot"):
#		spawnProjectile()

func getProjectileInstance():
	if projectiles_ready.size() <= 0:
		return null
	
	var p = projectiles_ready.pop_back()
	projectiles_in_use.append(p)
	return p


func _process(delta: float) -> void:
	_turret.global_rotation = (get_global_mouse_position() - _turret.global_position).angle()
	
	if firerate_timer > 0.0:
		firerate_timer = max(firerate_timer - delta, 0.0)
	if Input.is_action_pressed("shoot") and firerate_timer <= 0.0:
		spawnProjectile()
		firerate_timer = 0.1

func spawnProjectile() -> void:
	if not test_projectile: return 
	
	var projectile = getProjectileInstance() #test_projectile.instance()
	if not projectile: return
	
#	_projectile_parent.add_child(projectile)
	var pos : Vector2 = _projectile_spawn_pos.global_position
	var accuracy : float = deg2rad(3.0)
	var angle : float = _turret.global_rotation + rand_range(-accuracy, accuracy)
	projectile._spawn(pos, angle)




func On_Projectile_Despawned(projectile, pos : Vector2) -> void:
	var index : int = projectiles_in_use.find(projectile)
	if index >= 0:
		projectiles_in_use.remove(index)
		projectiles_ready.append(projectile)
