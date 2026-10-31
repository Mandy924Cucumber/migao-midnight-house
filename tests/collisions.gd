extends SceneTree

var game: Node
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
 call_deferred("run")

func check(value: bool, description: String) -> void:
 checks+=1
 if value: print("PASS ",description)
 else:
  failures.append(description)
  push_error("FAIL "+description)

func frames(count: int) -> void:
 for i in count: await physics_frame

func freeze_team() -> void:
 for friend in game.friends:
  friend.route.clear()
  friend.set_physics_process(false)

func camera_clear() -> bool:
 var sphere := SphereShape3D.new()
 sphere.radius=0.13
 var query := PhysicsShapeQueryParameters3D.new()
 query.shape=sphere
 query.transform=game.player.camera.global_transform
 query.collision_mask=1|4
 query.exclude=[game.player.get_rid()]
 return game.get_world_3d().direct_space_state.intersect_shape(query).is_empty()

func approach(label: String, start: Vector3, direction: Vector3, axis: String, limit: float, minimum: bool) -> void:
 game.player.place(start,atan2(-direction.x,-direction.z))
 await frames(4)
 Input.action_press("forward")
 Input.action_press("sprint")
 await frames(65)
 Input.action_release("forward")
 Input.action_release("sprint")
 var coordinate: float=game.player.position[axis]
 check(coordinate>=limit if minimum else coordinate<=limit,label+" blocks sprint ("+str(snappedf(coordinate,0.01))+")")
 # The near clipping plane must remain outside geometry even while looking up/down.
 var clear := true
 for pitch in [-1.35,0,1.35]:
  game.player.camera.rotation.x=pitch
  clear=clear and camera_clear()
 check(clear,label+" keeps first-person camera outside geometry")

func run() -> void:
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await frames(4)
 game.new_game()
 game.set_process(false)
 freeze_team()
 await approach("Bedroom wall",Vector3(-3.2,0.1,3.6),Vector3.RIGHT,"x",-2.4,false)
 await approach("Bed",Vector3(-4.9,0.1,7.6),Vector3.LEFT,"x",-5.74,true)
 await approach("Bedside lamp",Vector3(-3.5,0.1,8.8),Vector3.LEFT,"x",-4.16,true)
 await approach("Coffee table",Vector3(5.8,0.1,3.8),Vector3.FORWARD,"z",1.88,true)
 await approach("Sofa",Vector3(6.5,0.1,0),Vector3.RIGHT,"x",7.25,false)
 await approach("Bookcase",Vector3(4.1,0.1,-3),Vector3.FORWARD,"z",-5.18,true)
 await approach("Window and curtains",Vector3(8,0.1,3.5),Vector3.RIGHT,"x",9.2,false)
 await approach("Hall picture frame",Vector3(0,0.1,-2),Vector3.LEFT,"x",-1.4,true)
 await approach("Closed front door",Vector3(0,0.1,-9),Vector3.FORWARD,"z",-10.54,true)
 await approach("Tree trunk",Vector3(7.3,0.1,-11.8),Vector3.FORWARD,"z",-13.0,true)
 await approach("Courtyard lamppost",Vector3(4.3,0.1,-12),Vector3.FORWARD,"z",-13.65,true)
 await approach("Fallen tree outer end",Vector3(3.9,0.1,-20.8),Vector3.FORWARD,"z",-22.4,true)
 Engine.physics_ticks_per_second=15
 await approach("Low-tick sprint against wall",Vector3(-3.2,0.1,3.6),Vector3.RIGHT,"x",-2.4,false)
 await approach("Low-tick sprint against thin post",Vector3(4.3,0.1,-12),Vector3.FORWARD,"z",-13.65,true)
 Engine.physics_ticks_per_second=60
 # Exercise the real escort route through furniture, the hall, the narrow door and lampposts.
 game.player.place(Vector3(0,0.1,-20.4),0)
 game.reunited=true
 for person in game.friends: person.set_physics_process(true)
 game.interact("front_door")
 var escort_separation := true
 for i in 1300:
  await physics_frame
  for a in 3:
   for b in range(a+1,3):
    var offset: Vector3=game.friends[a].position-game.friends[b].position
    if Vector2(offset.x,offset.z).length()<0.74: escort_separation=false
 check(escort_separation,"Escort companions remain separated through narrow doorway")
 check(game.friends.all(func(person): return person.route.is_empty() and person.position.z < -21),"All companions complete courtyard escort without blocking each other")
 freeze_team()
 # Isolate the people tests in an empty courtyard lane.
 var friend: HouseCompanion=game.friends[0]
 friend.position=Vector3(0,0.1,-16)
 await approach("Stationary companion",Vector3(0,0.1,-13.8),Vector3.FORWARD,"z",-15.3,true)
 game.player.place(Vector3(0,0.1,-16),0)
 friend.position=Vector3(0,0.1,-18.5)
 friend.set_physics_process(true)
 friend.go([Vector3(0,0.1,-13.5)])
 var separation := true
 for i in 260:
  await physics_frame
  var distance: float=Vector2(friend.position.x-game.player.position.x,friend.position.z-game.player.position.z).length()
  if distance<0.70: separation=false
 check(separation,"Walking companion never overlaps stationary player")
 check(friend.route.is_empty(),"Companion detours around player and reaches destination")
 await game.enter_basement()
 game.set_process(false)
 freeze_team()
 await approach("Pump tank",Vector3(7.3,0.1,1.4),Vector3.BACK,"z",3.23,false)
 await approach("Valve wheel",Vector3(8,0.1,6.7),Vector3.FORWARD,"z",5.23,true)
 await approach("Switch console",Vector3(-5,0.1,-6.3),Vector3.FORWARD,"z",-7.94,true)
 await approach("Workshop table",Vector3(-6.8,0.1,8.4),Vector3.FORWARD,"z",7.69,true)
 await approach("Generator",Vector3(-8.7,0.1,3.4),Vector3.FORWARD,"z",1.55,true)
 await approach("Emergency cabinet",Vector3(-8.5,0.1,-4),Vector3.FORWARD,"z",-5.7,true)
 # Restore physics and test crossing routes with all people collidable.
 game.player.place(Vector3(0,0.1,8.5),0)
 game.friends[0].position=Vector3(-3,0.1,2)
 game.friends[1].position=Vector3(3,0.1,2)
 game.friends[2].position=Vector3(0,0.1,5)
 for person in game.friends: person.set_physics_process(true)
 var goals: Array[Vector3]=[Vector3(3,0.1,2),Vector3(-3,0.1,2),Vector3(0,0.1,-2)]
 for i in 3:
  var person: HouseCompanion=game.friends[i]
  person.go([goals[i]])
 separation=true
 for i in 360:
  await physics_frame
  for a in 3:
   for b in range(a+1,3):
    var delta: Vector3=game.friends[a].position-game.friends[b].position
    if Vector2(delta.x,delta.z).length()<0.74: separation=false
 check(separation,"Crossing companion routes never overlap")
 check(game.friends.all(func(person): return person.route.is_empty()),"Crossing companion routes finish without deadlock")
 if FileAccess.file_exists(game.checkpoint): DirAccess.remove_absolute(ProjectSettings.globalize_path(game.checkpoint))
 print("\nCOLLISIONS: %s checks, %s failures" % [checks,failures.size()])
 game.free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
