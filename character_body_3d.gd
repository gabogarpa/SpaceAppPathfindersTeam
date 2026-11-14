extends CharacterBody3D

# --- Variables de Movimiento ---
const MAX_SPEED: float = 6.0
const ACCELERATION: float = 12.0
const FRICTION: float = 10.0

const MAX_TURN_SPEED: float = 2.5
const TURN_ACCEL: float = 8.0

# --- Variables de Salto y Gravedad ---
const GRAVITY: float = 15.0
const JUMP_FORCE: float = 7.5

# --- Variables de Volumen del Motor (en decibelios) ---
const VOLUMEN_SUELO_DB: float = 0.0   # Volumen normal rodando en el suelo
const VOLUMEN_AIRE_DB: float = -5.0  # Volumen reducido durante el salto

var can_jump: bool = false

var turn_input: float = 0.0
var walk_input: float = 0.0
var current_speed: float = 0.0
var current_turn_speed: float = 0.0

# Referencias a los nodos de audio hijos dentro de MoonBot
@onready var motor_audio = get_node_or_null("MotorAudio")
@onready var salto_audio = get_node_or_null("SaltoAudio")

func _ready() -> void:
	floor_snap_length = 0.2
	safe_margin = 0.04

func _process(_delta: float) -> void:
	var right = Input.get_action_strength("ui_right")
	var left = Input.get_action_strength("ui_left")
	turn_input = right - left
	
	var forward = Input.get_action_strength("ui_up")
	var back = Input.get_action_strength("ui_down")
	walk_input = forward - back

func _physics_process(delta: float) -> void:
	# 1. Rotación suave
	var target_turn = -turn_input * MAX_TURN_SPEED
	current_turn_speed = move_toward(current_turn_speed, target_turn, TURN_ACCEL * delta)
	rotate_y(current_turn_speed * delta)

	# 2. Aceleración y frenado con inercia
	var target_speed = walk_input * MAX_SPEED
	var rate = ACCELERATION if walk_input != 0.0 else FRICTION
	current_speed = move_toward(current_speed, target_speed, rate * delta)

	# 3. Velocidad hacia adelante (+Z)
	var forward_dir = global_transform.basis.z
	velocity.x = forward_dir.x * current_speed
	velocity.z = forward_dir.z * current_speed

	# 4. Gravedad y Salto con sonido
	if is_on_floor():
		if can_jump and Input.is_action_just_pressed("ui_accept"):
			velocity.y = JUMP_FORCE
			if salto_audio:
				salto_audio.pitch_scale = randf_range(0.95, 1.05)
				salto_audio.play()
		else:
			velocity.y = 0.0
	else:
		velocity.y -= GRAVITY * delta

	# 5. Ejecutar movimiento
	move_and_slide()
	
	# 6. Actualizar sonido del motor y su volumen según esté en suelo o aire
	_actualizar_audio_motor(delta)

func _actualizar_audio_motor(delta: float) -> void:
	if not motor_audio:
		return
		
	if abs(current_speed) > 0.1:
		var speed_ratio = abs(current_speed) / MAX_SPEED
		motor_audio.pitch_scale = lerp(0.85, 1.2, speed_ratio)
		
		# Baja el volumen suavemente si está en el aire y lo sube al tocar el suelo
		var target_vol = VOLUMEN_SUELO_DB if is_on_floor() else VOLUMEN_AIRE_DB
		motor_audio.volume_db = move_toward(motor_audio.volume_db, target_vol, 60.0 * delta)
		
		if not motor_audio.playing:
			motor_audio.play()
	else:
		if motor_audio.playing:
			motor_audio.stop()

func habilitar_salto() -> void:
	can_jump = true
	print("¡Resorte equipado! Ahora puedes saltar con Espacio.")
