extends Camera3D

# Ajusta la altura (Y) y el desplazamiento (Z) desde el Inspector si quieres
@export var offset: Vector3 = Vector3(0.0, 12.0, 5.0) 
@export var smooth_speed: float = 8.0
@export var pitch_angle: float = -60.0 # -90 es 100% vertical; -75 deja ver mejor el relieve voxel

func _ready() -> void:
	# Desvincula la rotación del robot para que la cámara no gire con él
	top_level = true
	var parent = get_parent() as Node3D
	if parent:
		global_position = parent.global_position + offset
	rotation_degrees = Vector3(pitch_angle, 0.0, 0.0)

func _physics_process(delta: float) -> void:
	var parent = get_parent() as Node3D
	if not parent:
		return
		
	var target_pos = parent.global_position + offset
	global_position = global_position.lerp(target_pos, smooth_speed * delta)
