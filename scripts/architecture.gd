class_name HouseArchitecture
extends Node3D

var game: Node
var mats: Dictionary = {}
var interactables: Dictionary = {}
var candles: Array[OmniLight3D] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
 rng.seed = 317
 mats["wood"] = surface(Color("624d36"),Color("2f2924"),0)
 mats["plaster"] = surface(Color("536464"),Color("354745"),2)
 mats["brick"] = surface(Color("526063"),Color("242f33"),1)
 mats["stone"] = surface(Color("5d6664"),Color("373f42"),2)
 for pair in [["trim","293b3a"],["oak","342c27"],["gold","a38554"],["cream","b3a58a"],["cloth","3d5558"],["rug","593b3a"],["metal","333f45"],["black","172127"],["paper","d9c5a1"],["red","875a45"]]:
  mats[pair[0]] = material(Color(pair[1]))
 mats["gold"].metallic = 0.65
 mats["gold"].roughness = 0.3
 mats["glass"] = material(Color("497b89"),0.45)
 mats["bulb"] = material(Color("ffdca1"),3.0)
 mats["green"] = material(Color("95dbad"),1.5)

func material(color: Color, emission := 0.0) -> StandardMaterial3D:
 var mat := StandardMaterial3D.new()
 mat.albedo_color = color
 mat.roughness = 0.78
 if emission>0:
  mat.emission_enabled = true
  mat.emission = color
  mat.emission_energy_multiplier = emission
 return mat

func surface(a: Color,b: Color,kind: float) -> ShaderMaterial:
 var mat := ShaderMaterial.new()
 mat.shader = preload("res://shaders/surface.gdshader")
 mat.set_shader_parameter("base_color",a)
 mat.set_shader_parameter("second_color",b)
 mat.set_shader_parameter("pattern",kind)
 return mat

func box(at: Vector3,size: Vector3,mat_name: String,solid := false,parent: Node3D = null) -> MeshInstance3D:
 var mesh := MeshInstance3D.new()
 var cube := BoxMesh.new()
 cube.size = size
 mesh.mesh = cube
 mesh.material_override = mats[mat_name]
 mesh.position = at
 (self if parent==null else parent).add_child(mesh)
 if solid:
  var body := StaticBody3D.new()
  var shape := CollisionShape3D.new()
  var bounds := BoxShape3D.new()
  bounds.size = size
  shape.shape = bounds
  body.add_child(shape)
  mesh.add_child(body)
 return mesh

func solid_box(at: Vector3,size: Vector3,parent: Node3D = null) -> StaticBody3D:
 var body := StaticBody3D.new()
 body.position=at
 body.collision_layer=1
 body.collision_mask=0
 var bounds := BoxShape3D.new()
 bounds.size=size
 var collider := CollisionShape3D.new()
 collider.shape=bounds
 body.add_child(collider)
 (self if parent==null else parent).add_child(body)
 return body

func solid_cylinder(mesh: MeshInstance3D,radius: float,height: float) -> void:
 var body := StaticBody3D.new()
 body.collision_layer=1
 body.collision_mask=0
 var shape := CylinderShape3D.new()
 shape.radius=radius
 shape.height=height
 var collider := CollisionShape3D.new()
 collider.shape=shape
 body.add_child(collider)
 mesh.add_child(body)

func cylinder(at: Vector3,radius: float,height: float,mat_name: String,parent: Node3D = null) -> MeshInstance3D:
 var mesh := MeshInstance3D.new()
 var cylinder_mesh := CylinderMesh.new()
 cylinder_mesh.top_radius = radius
 cylinder_mesh.bottom_radius = radius
 cylinder_mesh.height = height
 cylinder_mesh.radial_segments = 20
 mesh.mesh = cylinder_mesh
 mesh.material_override = mats[mat_name]
 mesh.position = at
 (self if parent==null else parent).add_child(mesh)
 return mesh

func ball(at: Vector3,radius: float,mat_name: String,parent: Node3D = null) -> MeshInstance3D:
 var mesh := MeshInstance3D.new()
 var sphere := SphereMesh.new()
 sphere.radius = radius
 sphere.height = radius*2
 mesh.mesh = sphere
 mesh.material_override = mats[mat_name]
 mesh.position = at
 (self if parent==null else parent).add_child(mesh)
 return mesh

func light(at: Vector3,tint: Color,energy: float,radius: float,_shadows := false) -> OmniLight3D:
 var node := OmniLight3D.new()
 node.position = at
 node.light_color = tint
 node.light_energy = energy
 node.omni_range = radius
 node.shadow_enabled = false
 add_child(node)
 return node

func action(at: Vector3,size: Vector3,id: String,title: String) -> StaticBody3D:
 var body := StaticBody3D.new()
 body.position = at
 body.collision_layer = 8
 body.collision_mask = 0
 var shape := CollisionShape3D.new()
 var bounds := BoxShape3D.new()
 bounds.size = size
 shape.shape = bounds
 body.add_child(shape)
 body.set_meta("action",id)
 body.set_meta("label",title)
 add_child(body)
 interactables[id] = body
 return body

func label3d(at: Vector3,text_value: String,size := 30,tint := Color("c8b78f"),yaw := 0.0) -> Label3D:
 var label := Label3D.new()
 label.text = text_value
 label.font = game.font
 label.font_size = size
 label.pixel_size = 0.006
 label.modulate = tint
 label.outline_size = 2
 label.position = at
 label.rotation.y = yaw
 add_child(label)
 return label

func wall_x(x: float,z: float,length: float,kind := "plaster") -> void:
 box(Vector3(x,1.8,z),Vector3(0.2,3.6,length),kind,true)
 if kind=="plaster":
  box(Vector3(x,0.65,z),Vector3(0.25,1.3,length),"trim")
  for y in [0.12,1.28,3.35]: box(Vector3(x,y,z),Vector3(0.31,0.07,length),"gold" if y==1.28 else "trim")
  for zz in range(int(z-length/2),int(z+length/2)+1):
   box(Vector3(x,0.64,zz),Vector3(0.29,1.12,0.035),"oak")

func wall_z(x: float,z: float,length: float,kind := "plaster") -> void:
 box(Vector3(x,1.8,z),Vector3(length,3.6,0.2),kind,true)
 if kind=="plaster":
  box(Vector3(x,0.65,z),Vector3(length,1.3,0.25),"trim")
  for y in [0.12,1.28,3.35]: box(Vector3(x,y,z),Vector3(length,0.07,0.31),"gold" if y==1.28 else "trim")
  for xx in range(int(x-length/2),int(x+length/2)+1):
   box(Vector3(xx,0.64,z),Vector3(0.035,1.12,0.29),"oak")

func doorway_x(x: float,z: float,width: float) -> void:
 box(Vector3(x,3.08,z),Vector3(0.23,1.04,width),"plaster",true)
 for side in [-1,1]: box(Vector3(x,1.3,z+side*width/2),Vector3(0.34,2.6,0.12),"gold",true)
 box(Vector3(x,2.6,z),Vector3(0.34,0.12,width+0.15),"gold")

func rug(at: Vector3,size: Vector2) -> void:
 box(at+Vector3(0,0.025,0),Vector3(size.x,0.018,size.y),"rug")
 for side in [-1,1]:
  box(at+Vector3(side*(size.x/2-0.13),0.04,0),Vector3(0.045,0.008,size.y-0.22),"gold")
  box(at+Vector3(0,0.04,side*(size.y/2-0.13)),Vector3(size.x-0.22,0.008,0.045),"gold")
 for z in range(-int(size.y/2)+1,int(size.y/2)):
  var accent := box(at+Vector3(0,0.04,z),Vector3(0.38,0.008,0.38),"cream")
  accent.rotation.y = PI/4

func table(at: Vector3,size := Vector2(1.5,0.8)) -> void:
 solid_box(at+Vector3(0,0.42,0),Vector3(size.x,0.84,size.y))
 box(at+Vector3(0,0.78,0),Vector3(size.x,0.12,size.y),"oak",true)
 for x in [-1,1]:
  for z in [-1,1]: box(at+Vector3(x*(size.x/2-0.12),0.37,z*(size.y/2-0.1)),Vector3(0.09,0.74,0.09),"oak")

func lamp(at: Vector3) -> void:
 solid_box(at+Vector3(0,0.42,0),Vector3(0.54,0.76,0.54))
 cylinder(at+Vector3(0,0.025,0),0.16,0.05,"gold")
 cylinder(at+Vector3(0,0.32,0),0.026,0.6,"gold")
 var mesh := cylinder(at+Vector3(0,0.64,0),0.27,0.32,"cream")
 mesh.mesh.top_radius = 0.16
 ball(at+Vector3(0,0.5,0),0.065,"bulb")
 light(at+Vector3(0,0.53,0),Color("ffd39c"),1.4,4.8,true)

func candle(at: Vector3) -> void:
 cylinder(at,0.085,0.055,"gold")
 cylinder(at+Vector3(0,0.15,0),0.042,0.27,"cream")
 var flame := ball(at+Vector3(0,0.31,0),0.038,"bulb")
 flame.scale = Vector3(0.7,1.8,0.7)
 candles.append(light(at+Vector3(0,0.38,0),Color("ffc58d"),0.52,3.5))

func picture(at: Vector3,size: Vector2,yaw := 0.0) -> void:
 var root := Node3D.new()
 root.position = at
 root.rotation.y = yaw
 add_child(root)
 solid_box(Vector3(0,0,0.04),Vector3(size.x,size.y,0.18),root)
 box(Vector3.ZERO,Vector3(size.x, size.y,0.085),"gold",false,root)
 box(Vector3(0,0,0.05),Vector3(size.x-0.1,size.y-0.1,0.025),"black",false,root)
 # Abstract landscape in relief: a pale moon over layered mountains.
 ball(Vector3(size.x*0.18,size.y*0.18,0.08),size.y*0.12,"cream",root).scale.z = 0.15
 var landscape := SurfaceTool.new()
 landscape.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in 5:
  var x: float = -size.x*0.34+i*size.x*0.17
  for point in [Vector3(x-size.x*0.1,-size.y*0.4,0.095),Vector3(x,-size.y*0.05,0.095),Vector3(x+size.x*0.1,-size.y*0.4,0.095)]:
   landscape.set_normal(Vector3.BACK)
   landscape.add_vertex(point)
 var peaks := MeshInstance3D.new()
 peaks.mesh=landscape.commit()
 peaks.material_override=mats["cloth"]
 root.add_child(peaks)

func window_x(x: float,z: float) -> void:
 solid_box(Vector3(x-0.13,2.13,z),Vector3(0.46,2.5,2.85))
 box(Vector3(x,2.13,z),Vector3(0.08,1.85,2.0),"glass")
 for zz in [-1.06,0,1.06]: box(Vector3(x-0.1,2.13,z+zz),Vector3(0.16,2.0,0.075),"oak")
 for y in [1.15,2.13,3.13]: box(Vector3(x-0.1,y,z),Vector3(0.17,0.075,2.2),"oak")
 for side in [-1,1]:
  for i in 5:
   cylinder(Vector3(x-0.24,2.1,z+side*(1.08+i*0.055)),0.07,2.35,"cloth")
 light(Vector3(x-0.5,2.2,z),Color("8ac3dd"),1.25,7)
 # Cool slats on the floor evoke broken moonlight.
 for i in 3:
  var patch := box(Vector3(x-1.9-i*0.55,0.013,z),Vector3(0.32,0.012,2.1),"glass")
  patch.rotation.y = -0.28

func shelf(at: Vector3) -> void:
 solid_box(at+Vector3(0,1.24,0),Vector3(1.79,2.48,0.5))
 for x in [-0.82,0.82]: box(at+Vector3(x,1.2,0),Vector3(0.09,2.4,0.48),"oak",true)
 for y in [0.12,0.7,1.3,1.9,2.4]: box(at+Vector3(0,y,0),Vector3(1.7,0.08,0.5),"oak",true)
 for row in 3:
  for i in 9:
   var h := rng.randf_range(0.25,0.43)
   var book := box(at+Vector3(-0.65+i*0.15,0.75+row*0.6+h/2,0),Vector3(0.1,h,0.29),["cloth","red","cream","gold"][rng.randi_range(0,3)])
   book.rotation.z = rng.randf_range(-0.08,0.08)

func manor() -> void:
 box(Vector3(0,-0.18,0),Vector3(20,0.35,22),"wood",true)
 box(Vector3(0,3.65,0),Vector3(20,0.12,22),"plaster",true)
 wall_x(-10,0,22)
 wall_x(10,0,22)
 wall_z(0,11,20)
 wall_z(-5.6,-11,8.8)
 wall_z(5.6,-11,8.8)
 box(Vector3(0,3,-11),Vector3(2.4,1.2,0.2),"plaster",true)
 # Bedroom, hall and sitting room, joined by genuine open doorways.
 wall_x(-2,-3.2,15.6)
 wall_x(-2,9.3,3.4)
 doorway_x(-2,6.1,3.0)
 wall_z(-6,2.2,8)
 wall_x(2,8.6,4.8)
 wall_x(2,-7.6,6.8)
 doorway_x(2,1.0,4.0)
 wall_z(6,6.2,8)
 rug(Vector3(0,0,0),Vector2(2.25,19))
 rug(Vector3(6,0,-0.6),Vector2(5.4,6.8))
 rug(Vector3(-6,0,6.3),Vector2(5,5))
 # Bedroom bed, upholstered headboard, bedside table and a writing desk.
 box(Vector3(-7.3,0.3,7.6),Vector3(2.5,0.55,3.5),"oak",true)
 box(Vector3(-7.3,0.63,7.6),Vector3(2.4,0.25,3.4),"cream",true)
 box(Vector3(-7.3,0.81,7.0),Vector3(2.42,0.15,2.15),"cloth")
 box(Vector3(-7.3,1.1,9.25),Vector3(2.7,1.8,0.15),"oak",true)
 for x in [-7.85,-6.75]:
  box(Vector3(x,0.86,8.65),Vector3(0.91,0.2,0.62),"paper")
 for x in [-8.3,-7.8,-7.3,-6.8,-6.3]: box(Vector3(x,1.17,9.14),Vector3(0.38,1.2,0.05),"cloth")
 table(Vector3(-4.7,0,8.8),Vector2(0.9,0.8))
 lamp(Vector3(-4.7,0.85,8.8))
 box(Vector3(-4.6,0.86,8.55),Vector3(0.28,0.05,0.17),"black")
 action(Vector3(-4.6,1.0,8.55),Vector3(0.6,0.5,0.6),"bed_note","床头留言")
 picture(Vector3(-6,2.4,2.34),Vector2(1.8,1.05))
 table(Vector3(-8.7,0,3.4),Vector2(1.4,0.75))
 candle(Vector3(-8.7,0.88,3.4))
 # Hall lamps and symmetrical frames.
 for z in [-8,-2,9]:
  table(Vector3(-1.48,0,z),Vector2(0.5,1.0))
  lamp(Vector3(-1.48,0.85,z))
  picture(Vector3(-1.83,2.1,z),Vector2(1.0,1.2),PI/2)
 # Living room sofa, coffee table, fireplace and books.
 box(Vector3(8.1,0.4,0),Vector3(1.15,0.6,3.6),"cloth",true)
 box(Vector3(8.55,0.9,0),Vector3(0.28,0.85,3.6),"cloth",true)
 for z in [-1.75,1.75]: box(Vector3(8.1,0.73,z),Vector3(1.2,0.48,0.25),"cloth",true)
 for z in [-1.08,0,1.08]: box(Vector3(8.0,0.73,z),Vector3(0.82,0.12,0.92),"cream")
 table(Vector3(5.8,0,0.3),Vector2(1.6,2.6))
 candle(Vector3(5.65,0.9,0.2))
 box(Vector3(5.9,0.87,0.9),Vector3(0.52,0.04,0.35),"paper")
 for z in [-0.4,0.6]: cylinder(Vector3(6.05,0.92,z),0.09,0.18,"cream")
 action(Vector3(5.9,1,0.9),Vector3(0.7,0.4,0.5),"letter","旧报纸")
 shelf(Vector3(4.1,0,-5.7))
 shelf(Vector3(8.1,0,-5.7))
 box(Vector3(6.1,0.9,-5.76),Vector3(1.85,1.8,0.48),"stone",true)
 box(Vector3(6.1,0.64,-5.49),Vector3(1.22,1.15,0.04),"black")
 box(Vector3(6.1,1.83,-5.7),Vector3(2.15,0.14,0.65),"cream",true)
 for i in 5:
  var log_mesh := cylinder(Vector3(5.7+i*0.18,0.21,-5.36),0.08,0.6,"oak")
  log_mesh.rotation.x = PI/2
 for i in 4:
  var ember := ball(Vector3(5.8+i*0.19,0.28,-5.35),0.065,"bulb")
  ember.scale.y = 0.45
 candles.append(light(Vector3(6.1,0.5,-5.2),Color("ff9b63"),1.5,5.5,true))
 picture(Vector3(6.1,2.6,-5.5),Vector2(1.4,0.95))
 for z in [-3,3.5,8]: window_x(9.85,z)
 # Pendant with six warm points.
 cylinder(Vector3(5.7,3.3,0),0.025,0.55,"gold")
 for i in 6:
  var a := i*TAU/6
  var arm := box(Vector3(5.7+cos(a)*0.38,2.99,sin(a)*0.38),Vector3(0.82,0.045,0.045),"gold")
  arm.rotation.y = -a
  ball(Vector3(5.7+cos(a)*0.77,3.03,sin(a)*0.77),0.08,"bulb")
 light(Vector3(5.7,2.8,0),Color("ffd2a0"),1.1,8,true)
 # Door is an interaction-triggered portal into a continuous courtyard.
 box(Vector3(0,1.4,-10.92),Vector3(2.05,2.8,0.18),"oak",true).name = "FrontDoor"
 box(Vector3(0,1.4,-10.79),Vector3(1.77,2.5,0.025),"trim").name = "DoorPanel"
 for x in [-1.12,1.12]: box(Vector3(x,1.5,-10.8),Vector3(0.13,3,0.3),"gold",true)
 label3d(Vector3(0,2.95,-10.72),"出 口",28)
 action(Vector3(0,1.3,-10.6),Vector3(2.05,2.6,0.2),"front_door","别墅大门")
 courtyard(false)

func courtyard(dawn: bool) -> void:
 box(Vector3(0,-0.25,-20),Vector3(22,0.5,18),"stone",true)
 box(Vector3(0,0.015,-20),Vector3(3.4,0.03,18),"stone")
 for side in [-1,1]:
  wall_x(side*10,-20,18,"brick")
  for z in [-14,-20,-26]:
   var post := cylinder(Vector3(side*4.3,1.3,z),0.06,2.6,"metal")
   solid_cylinder(post,0.06,2.6)
   box(Vector3(side*4.3,2.6,z),Vector3(0.3,0.45,0.3),"bulb")
   light(Vector3(side*4.3,2.6,z),Color("ffd6a1"),1.1,5)
   tree(Vector3(side*7.3,0,z+0.5))
 wall_z(-5.8,-28,8.4,"brick")
 wall_z(5.8,-28,8.4,"brick")
 for x in range(-15,16):
  cylinder(Vector3(x*0.1,1.5,-28),0.018,3,"metal")
 box(Vector3(0,1.5,-28),Vector3(3.2,3,0.15),"black",true).visible = false
 if not dawn:
  var fallen := cylinder(Vector3(0,0.9,-23),0.6,9,"oak")
  fallen.rotation.z = 1.3
  solid_cylinder(fallen,0.6,9)
  box(Vector3(6.6,1.4,-25.9),Vector3(4.5,2.8,3.0),"brick",true)
  box(Vector3(6.6,1.0,-24.32),Vector3(1.6,2,0.14),"metal",true)
  label3d(Vector3(6.6,2.3,-24.2),"地下通道  ↓",26,Color("a9dbc9"))
  light(Vector3(6.6,2.3,-23.8),Color("83c6a5"),1.2,5)
  action(Vector3(6.6,1.1,-24.1),Vector3(1.8,2.2,0.4),"cellar","进入地下通道")

func tree(at: Vector3) -> void:
 var trunk := cylinder(at+Vector3(0,2,0),0.22,4,"oak")
 solid_cylinder(trunk,0.22,4)
 for i in 5:
  var branch := cylinder(at+Vector3(0,2.5+i*0.35,0),0.07,2.5,"oak")
  branch.rotation = Vector3(0,i*1.5,0.65+i*0.2)
  solid_cylinder(branch,0.07,2.5)
  var crown := ball(at+Vector3(sin(i*2)*0.7,4+i*0.2,cos(i*2)*0.7),1.3,"trim")
  crown.scale.y = 0.55

func basement() -> void:
 box(Vector3(0,-0.2,0),Vector3(20,0.4,22),"stone",true)
 box(Vector3(0,3.7,0),Vector3(20,0.2,22),"stone",true)
 wall_x(-10,0,22,"brick")
 wall_x(10,0,22,"brick")
 wall_z(0,11,20,"brick")
 wall_z(0,-11,20,"brick")
 for x in [-9.6,9.6]:
  for z in [-8,-2,4,10]: box(Vector3(x,1.8,z),Vector3(0.55,3.6,0.5),"stone",true)
 for z in [-7,0,7]:
  box(Vector3(0,3.3,z),Vector3(20,0.22,0.32),"metal")
  cylinder(Vector3(0,3.2,z),0.03,0.45,"metal")
  cylinder(Vector3(0,2.93,z),0.22,0.12,"metal")
  ball(Vector3(0,2.86,z),0.095,"bulb")
  var l := light(Vector3(0,2.7,z),Color("a6cfc4"),0.7,8,true)
  l.name = "CeilingLight"+str(z)
 for x in [-8.8,8.8]:
  var pipe := cylinder(Vector3(x,3.25,0),0.1,21,"metal")
  pipe.rotation.x = PI/2
  for z in [-8,-4,0,4,8]:
   var collar := cylinder(Vector3(x,3.25,z),0.14,0.08,"gold")
   collar.rotation.x = PI/2
 # Room markings and an uncluttered central traversal area.
 for z in range(-8,9):
  box(Vector3(-2.1,0.013,z),Vector3(0.055,0.018,0.6),"gold")
  box(Vector3(2.1,0.013,z),Vector3(0.055,0.018,0.6),"gold")
 label3d(Vector3(0,2.9,10.83),"B1 / 地下设施",36,Color("bcaf8f"),PI)
 # Workbench / fuse.
 table(Vector3(-6.8,0,6.8),Vector2(3.2,1.2))
 lamp(Vector3(-7.9,0.85,6.8))
 var fuse_visual := Node3D.new()
 fuse_visual.name="FuseVisual"
 add_child(fuse_visual)
 box(Vector3(-6.5,0.9,6.6),Vector3(0.48,0.11,0.19),"gold",false,fuse_visual)
 for x in [-6.68,-6.32]: box(Vector3(x,0.94,6.6),Vector3(0.07,0.09,0.22),"cream",false,fuse_visual)
 action(Vector3(-6.5,1,6.6),Vector3(0.75,0.55,0.7),"fuse","拾取备用保险丝")
 label3d(Vector3(-6.9,2.3,8.7),"维修工作台",33)
 shelf(Vector3(-8.8,0,9.8))
 # Generator.
 box(Vector3(-8.7,1.2,0.6),Vector3(1.6,2.4,1.3),"metal",true)
 box(Vector3(-8.68,1.4,1.28),Vector3(1.24,1.7,0.08),"trim")
 for i in 7: box(Vector3(-8.7,0.65+i*0.13,1.34),Vector3(1.0,0.035,0.02),"black")
 for x in [-9.05,-8.65,-8.25]: ball(Vector3(x,2.03,1.38),0.05,"red")
 label3d(Vector3(-8.7,2.7,1.33),"01 / 配电箱",26)
 action(Vector3(-8.7,1.4,1.5),Vector3(1.6,2,0.5),"generator","检修配电箱")
 # Pump, wheel and pipes.
 box(Vector3(8,0.5,4),Vector3(2.6,1,1.4),"metal",true)
 for x in [7.3,8.7]:
  var tank := cylinder(Vector3(x,1.45,4),0.47,2.2,"metal")
  solid_cylinder(tank,0.47,2.2)
 var wheel := Node3D.new()
 wheel.position = Vector3(8,1.5,4.85)
 wheel.name = "ValveWheel"
 solid_box(Vector3(8,1.5,4.85),Vector3(0.8,0.8,0.15))
 add_child(wheel)
 var torus := MeshInstance3D.new()
 var ring := TorusMesh.new()
 ring.inner_radius = 0.31
 ring.outer_radius = 0.4
 torus.mesh = ring
 torus.material_override = mats["red"]
 torus.rotation.x = PI/2
 wheel.add_child(torus)
 for i in 4:
  var spoke := box(Vector3.ZERO,Vector3(0.67,0.045,0.045),"red",false,wheel)
  spoke.rotation.z = i*PI/4
 label3d(Vector3(8,2.9,4.75),"02 / 排水泵",26)
 action(Vector3(8,1.6,5),Vector3(1,1.3,0.45),"valve","操作排水阀")
 # Water only covers the inaccessible drain, never masks navigation.
 box(Vector3(6,0.032,-3.2),Vector3(5,0.035,5),"glass").name = "Water"
 for i in 9: box(Vector3(4+i*0.46,0.015,-3.2),Vector3(0.12,0.025,4.8),"metal")
 box(Vector3(7.8,0.2,-4.5),Vector3(1.5,0.4,0.9),"oak",true)
 box(Vector3(7.8,0.43,-4.5),Vector3(0.55,0.025,0.42),"paper")
 action(Vector3(7.8,0.6,-4.5),Vector3(1.3,0.9,0.9),"logbook","读取泵房值班记录")
 # Emergency cabinet.
 box(Vector3(-8.5,1.0,-6.5),Vector3(2,2,1),"metal",true)
 box(Vector3(-8.5,1.05,-5.96),Vector3(1.7,1.72,0.09),"trim")
 for x in [-8.93,-8.05]:
  for y in [0.4,1.7]: ball(Vector3(x,y,-5.89),0.035,"gold")
 box(Vector3(-8.1,1.3,-5.88),Vector3(0.35,0.48,0.045),"black")
 label3d(Vector3(-8.5,2.4,-5.86),"03 / 应急钥匙柜",25)
 action(Vector3(-8.5,1.2,-5.7),Vector3(2,2,0.5),"safe","应急密码柜")
 # Four stations: three teammates stand at side consoles; the player turns the final lock.
 box(Vector3(0,1.5,-10.8),Vector3(3.3,3,0.24),"metal",true)
 for x in [-1.45,0,1.45]: box(Vector3(x,1.5,-10.61),Vector3(0.1,2.8,0.06),"gold")
 for y in [0.4,1.2,2.0,2.7]: box(Vector3(0,y,-10.59),Vector3(3,0.07,0.08),"gold")
 label3d(Vector3(0,3.2,-10.48),"04 / 四人联动 · 紧急出口",29)
 for i in 3:
  var x := -5.0+i*5
  var z := -8.5 if i!=1 else -6.7
  var stand := cylinder(Vector3(x,0.6,z),0.1,1.2,"metal")
  solid_cylinder(stand,0.1,1.2)
  box(Vector3(x,1.2,z),Vector3(0.65,0.2,0.5),"metal",true)
  ball(Vector3(x,1.34,z),0.085,"red").name = "Station"+str(i)
 action(Vector3(0,1.3,-10.3),Vector3(2.8,2.5,0.5),"escape","四人联动逃生门")
 light(Vector3(0,2.5,-10),Color("bb8b68"),1.3,5)
 # Stacked supply crates, kept at the edges.
 for at in [Vector3(-5,0,9),Vector3(8,0,9),Vector3(-9,0,-2.8)]:
  box(at+Vector3(0,0.5,0),Vector3(1.2,1,1),"oak",true)
  for x in [-0.4,0.4]: box(at+Vector3(x,0.5,0.51),Vector3(0.08,0.96,0.025),"gold")

# Merge immutable set dressing by material. Collision bodies remain independent.
# Interactive/animated props are excluded so removing a door also removes its image.
func batch_static_visuals() -> void:
 var groups: Dictionary = {}
 var dynamic_names := ["FrontDoor","DoorPanel","FuseVisual","Water","ValveWheel","Station0","Station1","Station2"]
 for child in find_children("*","MeshInstance3D",true,false):
  var mesh_instance := child as MeshInstance3D
  if not mesh_instance.visible or mesh_instance.mesh==null: continue
  var dynamic := false
  var ancestor: Node = mesh_instance
  while ancestor!=self and ancestor!=null:
   if str(ancestor.name) in dynamic_names:
    dynamic=true
    break
   ancestor=ancestor.get_parent()
  if dynamic: continue
  var mat: Material=mesh_instance.material_override
  var cell := Vector2i(floori(mesh_instance.global_position.x/7),floori(mesh_instance.global_position.z/7))
  var group_key := str(mat.get_instance_id())+":"+str(cell)
  if not groups.has(group_key): groups[group_key]={"material":mat,"meshes":[]}
  groups[group_key].meshes.append(mesh_instance)
 for group_key in groups:
  var surface := SurfaceTool.new()
  surface.begin(Mesh.PRIMITIVE_TRIANGLES)
  surface.set_material(groups[group_key].material)
  for mesh_instance in groups[group_key].meshes:
   surface.append_from(mesh_instance.mesh,0,global_transform.affine_inverse()*mesh_instance.global_transform)
   mesh_instance.visible=false
  var merged := MeshInstance3D.new()
  merged.mesh=surface.commit()
  merged.name="StaticBatch"
  add_child(merged)
