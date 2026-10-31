class_name HousePlayer
extends CharacterBody3D

var camera: Camera3D
var torch: SpotLight3D
var enabled := false
var look_sensitivity := 0.0022
var pitch := 0.0
var gait := 0.0
var foot_time := 0.0
var game: Node
var flashlight_on := true
var ignore_look_frames := 0

func _ready() -> void:
 collision_layer = 2
 collision_mask = 1 | 4
 safe_margin = 0.01
 floor_snap_length = 0.15
 var shape := CollisionShape3D.new()
 var capsule := CapsuleShape3D.new()
 capsule.radius = 0.34
 capsule.height = 1.84
 shape.shape = capsule
 shape.position.y = 0.93
 add_child(shape)
 camera = Camera3D.new()
 camera.position.y = 1.62
 camera.fov = 76
 camera.near = 0.06
 add_child(camera)
 torch = SpotLight3D.new()
 torch.light_color = Color("d9e4dc")
 torch.light_energy = 1.65
 torch.spot_range = 19
 torch.spot_angle = 34
 torch.spot_attenuation = 1.35
 torch.spot_angle_attenuation = 0.8
 torch.shadow_enabled = true
 torch.shadow_bias=0.08
 torch.shadow_normal_bias=1.5
 torch.position = Vector3(0.18,-0.13,-0.12)
 camera.add_child(torch)

func _unhandled_input(event: InputEvent) -> void:
 if ignore_look_frames>0 or game.capturing: return
 if enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
  rotation.y -= event.relative.x * look_sensitivity
  pitch = clampf(pitch-event.relative.y*look_sensitivity,-1.35,1.35)
  camera.rotation.x = pitch

func _physics_process(delta: float) -> void:
 if ignore_look_frames>0: ignore_look_frames-=1
 if not enabled:
  velocity = Vector3.ZERO
  return
 var axis := Input.get_vector("left","right","forward","back")
 var direction := (transform.basis * Vector3(axis.x,0,axis.y)).normalized()
 var running := Input.is_action_pressed("sprint") and axis.length()>0.0
 var speed := 4.7 if running else 2.8
 velocity.x = move_toward(velocity.x,direction.x*speed,delta*16)
 velocity.z = move_toward(velocity.z,direction.z*speed,delta*16)
 if not is_on_floor(): velocity.y -= 18.0*delta
 else: velocity.y = -0.1
 move_and_slide()
 if direction.length()>0.1 and is_on_floor():
  gait += delta*(11.0 if running else 7.5)
  camera.position.y = 1.62+sin(gait)*0.027
  camera.rotation.z = sin(gait*0.5)*0.004
  foot_time -= delta
  if foot_time <= 0:
   game.play_sound("step",-17.0,randf_range(0.85,1.15))
   foot_time = 0.31 if running else 0.48
 else:
  camera.position.y = lerpf(camera.position.y,1.62,delta*8)
  camera.rotation.z = lerpf(camera.rotation.z,0,delta*8)
 camera.fov = lerpf(camera.fov,80.0 if running else 76.0,delta*4)
 if position.y < -8:
  position = game.safe_spawn
  velocity = Vector3.ZERO

func place(at: Vector3, yaw: float) -> void:
 position = at
 rotation.y = yaw
 pitch = 0.0
 camera.rotation = Vector3.ZERO
 velocity = Vector3.ZERO

func toggle_torch() -> void:
 flashlight_on = not flashlight_on
 torch.visible = flashlight_on
 game.play_sound("click",-13)
