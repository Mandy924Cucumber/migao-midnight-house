class_name HouseCompanion
extends CharacterBody3D

var person_name := ""
var role := ""
var route: Array[Vector3] = []
var legs: Array[Node3D] = []
var arms: Array[Node3D] = []
var elapsed := 0.0
var base: Node3D
var game: Node
var assigned := false
var color := Color("64746b")

func _ready() -> void:
 collision_layer = 4
 collision_mask = 1 | 2 | 4
 safe_margin = 0.01
 floor_snap_length = 0.15
 var collider := CollisionShape3D.new()
 var capsule := CapsuleShape3D.new()
 capsule.radius = 0.38
 capsule.height = 1.94
 collider.shape = capsule
 collider.position.y = 0.98
 add_child(collider)
 base = Node3D.new()
 add_child(base)
 part(base,Vector3(0,1.12,0),Vector3(0.49,0.6,0.29),color)
 part(base,Vector3(0,0.83,0),Vector3(0.43,0.21,0.27),color.darkened(0.15))
 part(base,Vector3(0,1.48,0),Vector3(0.13,0.14,0.13),Color("a98874"),true)
 part(base,Vector3(0,1.67,0),Vector3(0.29,0.33,0.27),Color("b39781"),true)
 part(base,Vector3(0,1.82,0.025),Vector3(0.3,0.17,0.28),Color("24272b"),true)
 for side in [-1,1]:
  part(base,Vector3(side*0.061,1.69,-0.123),Vector3(0.033,0.033,0.018),Color("202829"),true)
  part(base,Vector3(side*0.065,1.736,-0.115),Vector3(0.058,0.014,0.014),Color("393431"))
  part(base,Vector3(side*0.143,1.666,0.0),Vector3(0.045,0.085,0.07),Color("b39781"),true)
 part(base,Vector3(0,1.646,-0.143),Vector3(0.043,0.07,0.05),Color("ae8e77"),true)
 part(base,Vector3(0,1.595,-0.117),Vector3(0.05,0.012,0.01),Color("735b51"))
 part(base,Vector3(0,1.11,-0.151),Vector3(0.014,0.52,0.012),Color("b4b2a3"))
 for side in [-1,1]:
  part(base,Vector3(side*0.135,0.99,-0.153),Vector3(0.14,0.11,0.014),color.darkened(0.15))
 part(base,Vector3(0,1.44,-0.04),Vector3(0.43,0.12,0.34),color.lightened(0.22))
 for side in [-1,1]:
  var leg := Node3D.new()
  leg.position = Vector3(side*0.13,0.79,0)
  base.add_child(leg)
  part(leg,Vector3(0,-0.32,0),Vector3(0.18,0.63,0.2),Color("303941"))
  part(leg,Vector3(0,-0.7,-0.05),Vector3(0.21,0.15,0.32),Color("1a2025"))
  legs.append(leg)
  var arm := Node3D.new()
  arm.position = Vector3(side*0.29,1.35,0)
  base.add_child(arm)
  part(arm,Vector3(0,-0.22,0),Vector3(0.16,0.48,0.19),color)
  part(arm,Vector3(0,-0.49,0),Vector3(0.13,0.15,0.13),Color("ae8e77"),true)
  arms.append(arm)
 # Small shoulder light lets a friend remain readable in the dark.
 part(base,Vector3(-0.15,1.3,-0.16),Vector3(0.065,0.09,0.04),Color("e9c58e"))
 var lamp := OmniLight3D.new()
 lamp.position = Vector3(0,1.35,-0.3)
 lamp.light_color = Color("c9dacc")
 lamp.light_energy = 0.32
 lamp.omni_range = 2.2
 base.add_child(lamp)
 set_meta("action","friend")
 set_meta("label",person_name+" · "+role)

func part(parent: Node3D, at: Vector3, size: Vector3, tint: Color, round_shape := false) -> void:
 var mesh := MeshInstance3D.new()
 if round_shape:
  var sphere := SphereMesh.new()
  sphere.radius = 0.5
  sphere.height = 1
  mesh.mesh = sphere
 else:
  var box := BoxMesh.new()
  box.size = Vector3.ONE
  mesh.mesh = box
 mesh.scale = size
 mesh.position = at
 var mat := StandardMaterial3D.new()
 mat.albedo_color = tint
 mat.roughness = 0.9
 mesh.material_override = mat
 parent.add_child(mesh)

func go(points: Array[Vector3]) -> void:
 route = points.duplicate()

func _physics_process(delta: float) -> void:
 elapsed += delta
 var walking := false
 if not route.is_empty():
  var direction := route[0]-position
  direction.y = 0
  if direction.length()<0.22:
   route.pop_front()
  else:
   walking = true
   direction = steer(direction.normalized())
   velocity.x = direction.x*2.35
   velocity.z = direction.z*2.35
   rotation.y = lerp_angle(rotation.y,atan2(-direction.x,-direction.z),delta*6)
 if not walking:
  velocity.x = 0
  velocity.z = 0
  if is_instance_valid(game.player) and position.distance_to(game.player.position)<5 and not assigned:
   var dir: Vector3 = game.player.position-position
   rotation.y = lerp_angle(rotation.y,atan2(-dir.x,-dir.z),delta*2)
 if not walking and assigned:
  rotation.y=lerp_angle(rotation.y,0,delta*4)
 if not is_on_floor(): velocity.y -= delta*18
 else: velocity.y = -0.1
 move_and_slide()
 for i in legs.size():
  legs[i].rotation.x = sin(elapsed*9+i*PI)*0.42 if walking else 0.0
  arms[i].rotation.x = -sin(elapsed*9+i*PI)*0.25 if walking else (-0.85 if assigned else sin(elapsed*1.3+i)*0.025)
 base.position.y = sin(elapsed*2.0)*0.006

# Sweep the actual body, including other people, before choosing a detour.
# Keep a chosen side briefly to avoid oscillating when two routes cross.
var detour_side := 0.0
var detour_time := 0.0

func steer(desired: Vector3) -> Vector3:
 detour_time=maxf(0.0,detour_time-get_physics_process_delta_time())
 if not test_move(global_transform,desired*0.85):
  return desired
 var side: float=detour_side if detour_time>0 else (1.0 if get_index()%2==0 else -1.0)
 for angle in [0.55,0.95,1.35,1.75,2.2]:
  for sign_value in [side,-side]:
   var candidate := desired.rotated(Vector3.UP,angle*sign_value)
   if not test_move(global_transform,candidate*0.65):
    detour_side=sign_value
    detour_time=0.8
    return candidate
 return Vector3.ZERO
