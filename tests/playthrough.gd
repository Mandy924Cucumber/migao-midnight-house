extends SceneTree

var game: Node
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
 call_deferred("run")

func check(value: bool,description: String) -> void:
 checks+=1
 if value: print("PASS ",description)
 else:
  failures.append(description)
  push_error("FAIL "+description)

func settle(frames := 4) -> void:
 for i in frames: await physics_frame

func aim_at(id: String, at: Vector3) -> void:
 game.player.place(at,0)
 var object: Node3D=game.world.interactables[id]
 game.player.camera.look_at(object.global_position)
 await settle(5)
 game.find_target()
 check(is_instance_valid(game.target) and game.target.get_meta("action","")==id,"Reachable camera interaction: "+id)

func run() -> void:
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await settle()
 check(game.mode=="menu","Menu initializes")
 check(game.friends.size()==3,"Exactly three friendly companions")
 check(not game.player.enabled,"Menu releases first-person input")
 game.new_game()
 await settle(25)
 check(game.player.is_on_floor(),"Bedroom spawn rests on collision floor")
 check(game.location=="manor" and game.player.enabled,"New game enables movement in manor")
 await aim_at("bed_note",Vector3(-3.8,0.1,8.55))
 game.interact("front_door")
 check(not game.front_open,"Cannot leave companions behind before reunion")
 # Real physics movement through the bedroom doorway into the hall.
 game.player.place(Vector3(-3.8,0.08,6.1),-PI/2)
 Input.action_press("forward")
 await settle(70)
 Input.action_release("forward")
 check(game.player.position.x>-1.5,"Bedroom doorway can be traversed with WASD physics")
 # Verify wall collisions prevent walking through bedroom partition.
 game.player.place(Vector3(-3.2,0.08,3.6),-PI/2)
 Input.action_press("forward")
 await settle(50)
 Input.action_release("forward")
 check(game.player.position.x < -2.25,"Partition wall blocks first-person movement")
 game.player.place(Vector3(3.3,0.08,3.2),0)
 await settle()
 check(game.reunited,"Entering lounge triggers reunion")
 await aim_at("front_door",Vector3(0,0.1,-9))
 game.interact("front_door")
 check(game.horror_heard,"Eerie sound cannot be skipped by sprinting to exit")
 check(game.front_open,"Exit unlocks after reunion")
 check(game.world.get_node_or_null("FrontDoor")==null,"Door collider removed with opened door")
 game.player.place(Vector3(0,0.08,-9.5),0)
 Input.action_press("forward")
 await settle(55)
 Input.action_release("forward")
 check(game.player.position.z < -11.5,"Front door can be crossed physically")
 await aim_at("cellar",Vector3(6.6,0.1,-22.4))
 await game.enter_basement()
 await settle(20)
 check(game.location=="basement","Basement transition succeeds")
 check(game.player.is_on_floor(),"Basement spawn rests on collision floor")
 check(game.friends.size()==3,"All companions arrive in basement")
 game.interact("escape")
 check(game.mode=="playing","Final exit stays locked before puzzles")
 game.interact("valve")
 check(not game.drained,"Drain requires power")
 game.interact("generator")
 check(not game.power_on,"Power requires fuse")
 game.interact("logbook")
 check(not game.log_read,"Flooded clue requires drain")
 game.try_code("0317")
 check(not game.key_found,"Keypad cannot bypass missing power")
 # Raycast interaction at the fuse from a reachable viewing position.
 game.player.place(Vector3(-6.5,0.1,8.0),0)
 game.player.camera.look_at(Vector3(-6.5,1,6.6))
 await settle()
 game.find_target()
 check(is_instance_valid(game.target) and game.target.get_meta("action","")=="fuse","Fuse interaction is reachable through actual camera ray")
 game.interact("fuse")
 check(game.fuse_found,"Fuse can be collected")
 check(not game.world.interactables.has("fuse"),"Collected fuse cannot be collected again")
 await aim_at("generator",Vector3(-8.7,0.1,3.2))
 game.interact("generator")
 check(game.power_on,"Fuse restores power")
 await aim_at("valve",Vector3(8,0.1,6.6))
 game.interact("valve")
 check(game.drained and not game.world.get_node("Water").visible,"Pump drains water")
 await aim_at("logbook",Vector3(7.8,0.1,-2.8))
 game.interact("logbook")
 check(game.log_read and "0317" in game.journal_text(),"Clue recorded permanently in journal")
 check(not game.player.enabled,"Document modal releases mouse and pauses movement")
 game.resume_game()
 await aim_at("safe",Vector3(-8.5,0.1,-4.0))
 game.interact("safe")
 game.try_code("1111")
 check(not game.key_found and not game.ui.code_error.text.is_empty(),"Wrong code is rejected with useful feedback")
 game.try_code("0317")
 check(game.key_found and game.player.enabled,"Correct code awards key and returns input")
 check(not game.team_ready,"Final door waits for companions to arrive")
 # Let actual companion steering and collisions run until all stations are reached.
 game.player.place(Vector3(1.5,0.1,-8.0),0)
 await settle(700)
 check(game.team_ready,"All three companions physically reach final stations")
 for i in 3:
  check(game.friends[i].route.is_empty(),"Companion %s route completes without getting stuck" % i)
 # Checkpoint reload preserves puzzles, places the team correctly and remains winnable.
 game.save_game()
 game.return_menu()
 await game.continue_game()
 await settle(8)
 check(game.location=="basement" and game.power_on and game.drained and game.key_found,"Checkpoint restores full puzzle progress")
 check(game.team_ready,"Reload restores companion stations")
 game.ui.pause_menu()
 var old_position: Vector3=game.player.position
 Input.action_press("forward")
 await settle(20)
 Input.action_release("forward")
 check(game.player.position.is_equal_approx(old_position),"Pause prevents movement")
 game.resume_game()
 var old_torch: bool=game.player.flashlight_on
 game.player.toggle_torch()
 check(game.player.flashlight_on!=old_torch,"Flashlight toggles")
 await aim_at("escape",Vector3(0,0.1,-8.8))
 await game.finish_game()
 check(game.mode=="ending" and game.friends.size()==3,"All four people escape and ending screen appears")
 game.new_game()
 await settle(4)
 check(game.location=="manor" and not game.key_found and not game.reunited,"Restart clears all previous progress")
 if FileAccess.file_exists(game.checkpoint): DirAccess.remove_absolute(ProjectSettings.globalize_path(game.checkpoint))
 print("\nPLAYTHROUGH: %s checks, %s failures" % [checks,failures.size()])
 game.free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
