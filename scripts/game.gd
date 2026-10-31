extends Node3D

const Architecture = preload("res://scripts/architecture.gd")
const Player = preload("res://scripts/player.gd")
const Companion = preload("res://scripts/companion.gd")
const Interface = preload("res://scripts/interface.gd")

var font: Font
var world: HouseArchitecture
var player: HousePlayer
var ui: HouseInterface
var environment: Environment
var menu_camera: Camera3D
var friends: Array[HouseCompanion] = []
var ambience: AudioStreamPlayer
var sounds: Dictionary = {}
var mode := "menu"
var location := "manor"
var reunited := false
var front_open := false
var fuse_found := false
var power_on := false
var drained := false
var log_read := false
var key_found := false
var team_ready := false
var transitioning := false
var target: Node
var safe_spawn := Vector3(-4,0.1,6.2)
var messages: Array[Dictionary] = []
var message_time := 0.0
var elapsed := 0.0
var sensitivity := 0.0022
var brightness := 1.0
var volume := 0.7
var testing := false
var capturing := false
var checkpoint := "user://checkpoint.cfg"
var moon: DirectionalLight3D
var intro_timer := 0.0
var horror_heard := false

func _ready() -> void:
 testing = "--self-test" in OS.get_cmdline_user_args()
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--capture-"): capturing=true
 if capturing: checkpoint="user://capture_checkpoint.cfg"
 if testing: checkpoint="user://test_checkpoint.cfg"
 font = load("res://assets/fonts/story.ttf")
 setup_input()
 load_settings()
 setup_environment()
 player = Player.new()
 player.game = self
 player.look_sensitivity = sensitivity
 add_child(player)
 menu_camera = Camera3D.new()
 add_child(menu_camera)
 ui = Interface.new()
 ui.game = self
 add_child(ui)
 load_audio()
 build_manor()
 return_menu()
 if "--capture-menu" in OS.get_cmdline_user_args(): capture_later("menu")
 if "--capture-room" in OS.get_cmdline_user_args():
  new_game()
  capture_later("bedroom")
 if "--capture-basement" in OS.get_cmdline_user_args():
  new_game()
  await enter_basement()
  player.place(Vector3(-0.5,0.1,8.5),0)
  capture_later("basement")
 if "--capture-lounge" in OS.get_cmdline_user_args():
  new_game()
  player.place(Vector3(3.0,0.1,4.6),-0.25)
  player.camera.look_at(Vector3(6.0,1.4,-3.8))
  capture_later("lounge")

func setup_input() -> void:
 var keys := {"forward":KEY_W,"back":KEY_S,"left":KEY_A,"right":KEY_D,"sprint":KEY_SHIFT,"interact":KEY_E,"flashlight":KEY_F,"journal":KEY_TAB}
 for action_name in keys:
  if not InputMap.has_action(action_name): InputMap.add_action(action_name)
  var event := InputEventKey.new()
  event.physical_keycode = keys[action_name]
  InputMap.action_add_event(action_name,event)

func setup_environment() -> void:
 var node := WorldEnvironment.new()
 environment = Environment.new()
 environment.background_mode = Environment.BG_COLOR
 environment.background_color = Color("111e2b")
 environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 environment.ambient_light_color = Color("90aeb8")
 environment.ambient_light_energy = 0.38
 environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 environment.fog_enabled = true
 environment.fog_light_color = Color("283d48")
 environment.fog_light_energy = 0.6
 environment.fog_density = 0.009
 environment.glow_enabled = true
 environment.glow_intensity = 0.5
 environment.ssao_enabled = false
 node.environment = environment
 add_child(node)
 moon = DirectionalLight3D.new()
 moon.rotation_degrees = Vector3(-38,-35,0)
 moon.light_color = Color("7ea6c2")
 moon.light_energy = 0.27
 moon.shadow_enabled = false
 add_child(moon)
 apply_brightness()

func apply_brightness() -> void:
 if environment: environment.ambient_light_energy = 0.38*brightness

func clear_world() -> void:
 target = null
 for friend in friends: friend.free()
 friends.clear()
 if is_instance_valid(world): world.free()
 world = Architecture.new()
 world.game = self
 add_child(world)

func make_friends(positions: Array[Vector3]) -> void:
 var names := ["林岚","周屿","许宁"]
 var roles := ["照明与陪伴","机械与维修","观察与记录"]
 var colors := [Color("637c73"),Color("8e6e54"),Color("63768a")]
 for i in 3:
  var friend := Companion.new()
  friend.game = self
  friend.person_name = names[i]
  friend.role = roles[i]
  friend.color = colors[i]
  friend.position = positions[i]
  add_child(friend)
  friends.append(friend)

func build_manor() -> void:
 clear_world()
 location = "manor"
 world.manor()
 world.batch_static_visuals()
 make_friends([Vector3(4.0,0.1,2.2),Vector3(6.8,0.1,-2.6),Vector3(4,0.1,-1.7)])
 moon.light_color = Color("7ea6c2")
 moon.light_energy = 0.27
 environment.fog_density = 0.009
 environment.fog_light_color=Color("283d48")
 environment.background_color=Color("111e2b")
 apply_brightness()

func reset_flags() -> void:
 reunited=false
 front_open=false
 fuse_found=false
 power_on=false
 drained=false
 log_read=false
 key_found=false
 team_ready=false
 messages.clear()
 message_time=0
 intro_timer=0
 horror_heard=false
 ui.dialogue("","")

func new_game() -> void:
 if transitioning: return
 reset_flags()
 build_manor()
 mode="playing"
 ui.close_modal()
 ui.hide_menu()
 safe_spawn=Vector3(-4,0.1,6.2)
 player.place(safe_spawn,-PI/2)
 player.camera.current=true
 set_controls(true)
 ui.fade.modulate.a=1
 create_tween().tween_property(ui.fade,"modulate:a",0.0,2.4)
 say("你 · 02:13","你被一阵轻微的敲击声惊醒。走廊尽头，似乎有人还醒着。",6)
 say("探索提示","WASD 移动，鼠标观察。准星对准物品后按 E 交互。",5)
 update_objective()
 save_game()

func set_controls(active: bool) -> void:
 player.enabled = active
 player.ignore_look_frames=3
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if active else Input.MOUSE_MODE_VISIBLE
 for friend in friends: friend.set_physics_process(active)

func resume_game() -> void:
 ui.close_modal()
 if mode=="playing": set_controls(true)

func return_menu() -> void:
 if transitioning: return
 if mode=="playing": save_game()
 mode="menu"
 set_controls(false)
 ui.close_modal()
 if location!="manor": build_manor()
 for friend in friends: friend.set_physics_process(false)
 menu_camera.position=Vector3(2.85,1.82,4.9)
 menu_camera.look_at(Vector3(6.5,1.45,-3.5))
 menu_camera.current=true
 player.torch.hide()
 ui.show_menu()
 ui.fade.modulate.a=0

func has_save() -> bool:
 return FileAccess.file_exists(checkpoint)

func save_game() -> void:
 if mode!="playing" or transitioning: return
 var config := ConfigFile.new()
 config.set_value("progress","location",location)
 for flag in ["reunited","front_open","fuse_found","power_on","drained","log_read","key_found"]:
  config.set_value("progress",flag,get(flag))
 config.save(checkpoint)

func continue_game() -> void:
 var config := ConfigFile.new()
 if config.load(checkpoint)!=OK:
  new_game()
  return
 new_game_without_save()
 if config.get_value("progress","location","manor")=="basement":
  await enter_basement(false)
 for flag in ["reunited","front_open","fuse_found","power_on","drained","log_read","key_found"]:
  set(flag,bool(config.get_value("progress",flag,false)))
 if location=="manor" and front_open:
  remove_front_door()
  player.place(Vector3(0,0.1,-13),0)
  for i in 3: friends[i].position=Vector3(-1.5+i*1.5,0.1,-16)
 if location=="basement":
  if fuse_found: hide_fuse()
  if power_on: light_power()
  if drained: world.get_node("Water").hide()
  if key_found: position_team(true)
 messages.clear()
 message_time=0
 say("检查点已恢复","大家都在。按 Tab 查看已经找到的线索。",4)
 update_objective()
 save_game()

func new_game_without_save() -> void:
 reset_flags()
 build_manor()
 mode="playing"
 ui.hide_menu()
 ui.close_modal()
 player.camera.current=true
 player.place(Vector3(-4,0.1,6.2),-PI/2)
 set_controls(true)
 player.torch.visible=player.flashlight_on

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.echo: return
 if event.is_action_pressed("ui_cancel"):
  if transitioning: return
  if mode=="playing":
   if is_instance_valid(ui.modal): resume_game()
   else: ui.pause_menu()
  elif mode=="menu" and is_instance_valid(ui.modal): ui.close_modal()
  get_viewport().set_input_as_handled()
 if mode!="playing" or transitioning: return
 if event.is_action_pressed("journal"):
  if ui.journal_open: resume_game()
  elif not is_instance_valid(ui.modal): ui.show_journal()
 if not player.enabled: return
 if event.is_action_pressed("flashlight"): player.toggle_torch()
 if event.is_action_pressed("interact") and is_instance_valid(target):
  interact(str(target.get_meta("action","")))

func _process(delta: float) -> void:
 elapsed+=delta
 if mode=="menu":
  menu_camera.position.y=1.82+sin(elapsed*0.3)*0.016
 if mode!="playing" or not player.enabled or transitioning: return
 player.torch.visible=player.flashlight_on
 if message_time>0:
  message_time-=delta
  if message_time<=0: next_message()
 elif not messages.is_empty(): next_message()
 for i in world.candles.size():
  var lamp := world.candles[i]
  lamp.light_energy = (0.52 if i<2 else 1.35)*(0.92+0.08*sin(elapsed*5.3+i)+0.03*sin(elapsed*12))
 find_target()
 if location=="manor" and not reunited and player.position.x>2.4 and player.position.z<5.8:
  reunion()
 if intro_timer>0:
  intro_timer-=delta
  if intro_timer<=0:
   trigger_horror()
   escort_to_exit()
 if key_found and location=="basement" and not team_ready:
  var ready := true
  for friend in friends:
   if not friend.route.is_empty(): ready=false
  if ready:
   team_ready=true
   for i in 3: world.get_node("Station"+str(i)).material_override=world.mats["green"]
   say("周屿","三个机关都压住了。把钥匙插进出口，我们一起出去！",5)
   update_objective()

func find_target() -> void:
 target=null
 ui.prompt.text=""
 var start := player.camera.global_position
 var end := start-player.camera.global_basis.z*3.1
 var query := PhysicsRayQueryParameters3D.create(start,end,1|4|8)
 query.exclude=[player.get_rid()]
 var result := get_world_3d().direct_space_state.intersect_ray(query)
 if not result.is_empty():
  var collider: Node=result.collider
  if collider.has_meta("action"):
   target=collider
   ui.prompt.text="[ E ]  "+str(collider.get_meta("label"))

func interact(id: String) -> void:
 if mode!="playing" or transitioning: return
 match id:
  "bed_note":
   ui.show_note("床头留言","林岚留下的纸条\n\n『我们在起居室等你。手电已经放在你身上，按 F 就能打开。别一个人乱跑。』\n\n纸条下面，是你们四人的合照。")
  "letter":
   ui.show_note("一张泛黄的旧报纸","山间别墅设施维护纪要\n\n主入口若因暴风雨封闭，可经庭院右侧的地下通道离开。\n地下通道设有四点联动门，必须由四人共同操作。\n\n有人在『四人』下面重重画了一道线。")
  "friend":
   if location=="manor": say("同伴","我们都在。先找到正门，别离大家太远。",4)
   elif key_found: say("同伴","你去门边，我会守住机关。我们一起出去。",4)
   else: say("同伴",hint_text(),5)
  "front_door":
   if not reunited:
    say("你","先到有壁炉的起居室找齐大家，再一起离开。",4)
   else:
    if not horror_heard: trigger_horror()
    front_open=true
    intro_timer=0
    remove_front_door()
    play_sound("door",-7)
    say("许宁","大门开了！沿着灯光走，大家跟上。",4)
    say("周屿","前面倒了一棵树。右边有地下通道的标记！",5)
    for i in 3:
     var route: Array[Vector3]=[]
     if friends[i].position.x>1.6:
      route.append(Vector3(3.2,0.1,1.0))
      route.append(Vector3(0,0.1,1.0))
     route.append(Vector3(0,0.1,-12))
     route.append(Vector3(-1.2+i*1.2,0.1,-18))
     route.append(Vector3(5.0+i*0.9,0.1,-21.7))
     friends[i].go(route)
    save_game()
    update_objective()
  "cellar":
   if front_open: enter_basement()
  "fuse":
   if not fuse_found:
    fuse_found=true
    hide_fuse()
    play_sound("pickup",-9)
    say("你","找到了一枚备用保险丝。",3)
    say("周屿","左侧墙边是配电箱。装上保险丝，我来确认线路。",4)
    changed()
  "generator":
   if power_on: say("周屿","线路稳定，供电已经恢复。",3)
   elif not fuse_found: say("周屿","这里少了一枚保险丝。入口左边的维修台上应该有备用的。",5)
   else:
    power_on=true
    light_power()
    play_sound("power",-9)
    say("周屿","有电了！排水泵也能启动了，我确认线路安全。",5)
    friends[1].go([Vector3(-3,0.1,3),Vector3(-6.8,0.1,1.6)])
    changed()
  "valve":
   if not power_on: say("周屿","先恢复供电，水泵才转得起来。",4)
   elif drained: say("周屿","积水已经排空。去看看水槽那边的记录。",4)
   else:
    drained=true
    play_sound("power",-12,0.65)
    create_tween().tween_property(world.get_node("ValveWheel"),"rotation:z",TAU*2,1.4)
    world.get_node("Water").hide()
    say("林岚","水位降下去了。我照着右边的水槽，你看看木箱上的记录。",5)
    friends[0].go([Vector3(2.7,0.1,2),Vector3(4.0,0.1,-0.3)])
    changed()
  "logbook":
   if not drained: say("你","水流太急，记录还被困在积水区。先把水排掉。",4)
   else:
    log_read=true
    ui.show_note("泵房值班记录","最后一班 · 10 月 17 日\n\n03:17  交接完毕。应急钥匙已收入密码柜。\n\n『密码仍是交接时间，去掉冒号。不要留人看守；四点联动门要求四个人都到场。』\n\n许宁在你的笔记上记下：0 — 3 — 1 — 7。")
    changed()
  "safe":
   if not power_on: say("你","密码面板没有电。",3)
   elif key_found: say("你","钥匙已经拿到了。大家正在出口机关旁等你。",4)
   else: ui.show_keypad()
  "escape":
   if not key_found: say("许宁","应急钥匙在密码柜里。我们会陪你把它找出来。",4)
   elif not team_ready: say("周屿","等我们站好三个机关……不要松开。",4)
   else: finish_game()

func changed() -> void:
 update_objective()
 save_game()

func reunion() -> void:
 reunited=true
 messages.clear()
 message_time=0
 say("林岚","你也醒了？我们三个都听见了，好像有人在楼上走。",5)
 say("许宁","我们四个人明明都在这里……",4)
 intro_timer=7.0
 save_game()
 update_objective()

func trigger_horror() -> void:
 horror_heard=true
 play_sound("dread",-4)
 say("楼上传来的声音","咚……咚……有人在拖动椅子。接着，一个陌生的声音念出了你们的名字。",5)
 say("林岚","别分开。出口在走廊最里面，我们一起走！",5)

func escort_to_exit() -> void:
 for i in 3:
  friends[i].go([Vector3(3.2,0.1,2.7-i*1.0),Vector3(0,0.1,2.7-i*1.0),Vector3(-0.8+i*0.8,0.1,-8.3+i*0.65)])
 update_objective()

func remove_front_door() -> void:
 for object_name in ["FrontDoor","DoorPanel"]:
  var object := world.get_node_or_null(object_name)
  if object: object.free()
 if world.interactables.has("front_door"):
  if is_instance_valid(world.interactables["front_door"]): world.interactables["front_door"].free()
  world.interactables.erase("front_door")

func enter_basement(write_save := true) -> void:
 if transitioning: return
 transitioning=true
 set_controls(false)
 if not testing:
  await create_tween().tween_property(ui.fade,"modulate:a",1.0,0.65).finished
 clear_world()
 location="basement"
 world.basement()
 world.batch_static_visuals()
 make_friends([Vector3(-2,0.1,7.8),Vector3(1.6,0.1,7.5),Vector3(2.4,0.1,6.0)])
 safe_spawn=Vector3(0,0.1,8.6)
 player.place(safe_spawn,0)
 player.camera.current=true
 messages.clear()
 message_time=0
 intro_timer=0
 moon.light_energy=0.05
 environment.fog_density=0.012
 mode="playing"
 transitioning=false
 set_controls(true)
 if not testing: create_tween().tween_property(ui.fade,"modulate:a",0.0,1.2)
 say("地下通道 · 02:26","身后的防火门突然合上。前方的出口，亮着四盏暗红色指示灯。",5)
 say("周屿","别慌，门是机械联动的。先找保险丝恢复供电，我来帮你。",5)
 update_objective()
 if write_save: save_game()

func hide_fuse() -> void:
 var object := world.get_node_or_null("FuseVisual")
 if object: object.hide()
 if world.interactables.has("fuse") and is_instance_valid(world.interactables["fuse"]):
  world.interactables["fuse"].free()
  world.interactables.erase("fuse")

func light_power() -> void:
 for z in [-7,0,7]:
  var lamp := world.get_node_or_null("CeilingLight"+str(z))
  if lamp: lamp.light_energy=1.6

func try_code(code: String) -> void:
 if location!="basement" or not power_on or key_found: return
 if code!="0317":
  if is_instance_valid(ui.code_error): ui.code_error.text="密码不正确。线索在排水区的值班记录里。"
  play_sound("click",-12,0.6)
  return
 key_found=true
 resume_game()
 play_sound("pickup",-6,0.8)
 say("你","柜门开了。找到应急出口的黄铜钥匙！",4)
 say("许宁","最后的门需要四个人。我们三个去守住开关，你负责转动钥匙。",5)
 position_team(false)
 changed()

func position_team(instant: bool) -> void:
 var positions: Array[Vector3]=[Vector3(-5,0.1,-7.7),Vector3(0,0.1,-5.9),Vector3(5,0.1,-7.7)]
 for i in 3:
  friends[i].assigned=true
  if instant:
   friends[i].position=positions[i]
   friends[i].rotation.y=0
   friends[i].route.clear()
  else:
   # Route via an open central lane; furniture stays outside this path.
   var x := -3.0 if i==0 else 3.0
   friends[i].go([Vector3(x,0.1,2.0),Vector3(x,0.1,-4.8),positions[i]])
 team_ready=instant
 if instant:
  for i in 3: world.get_node("Station"+str(i)).material_override=world.mats["green"]

func finish_game() -> void:
 if transitioning or not team_ready or not key_found: return
 transitioning=true
 set_controls(false)
 play_sound("door",-5,0.75)
 if not testing: await create_tween().tween_property(ui.fade,"modulate:a",1.0,1.0).finished
 clear_world()
 world.courtyard(true)
 world.batch_static_visuals()
 make_friends([Vector3(-1.4,0.1,-20),Vector3(0,0.1,-20.5),Vector3(1.4,0.1,-20)])
 location="dawn"
 mode="ending"
 for friend in friends: friend.set_physics_process(false)
 environment.fog_light_color=Color("adaf9e")
 environment.fog_density=0.015
 environment.ambient_light_energy=0.75
 environment.background_color=Color("8d9fa0")
 moon.light_color=Color("ffe1ab")
 moon.light_energy=1.2
 menu_camera.position=Vector3(3,2,-15)
 menu_camera.look_at(Vector3(0,1.3,-24))
 menu_camera.current=true
 ui.ending()
 transitioning=false
 if not testing: create_tween().tween_property(ui.fade,"modulate:a",0.0,2)

func update_objective() -> void:
 if location=="manor":
  ui.chapter_label.text="01 / 深夜别墅  ·  02:13"
  ui.objective.text="走出卧室，前往有壁炉的起居室与队友会合"
  if reunited: ui.objective.text="沿长廊寻找出口，四个人一起离开"
  if front_open: ui.objective.text="穿过庭院，寻找右侧的地下通道"
  ui.status.text="同伴  3 / 3\n"+("已会合" if reunited else "在起居室等你")
 else:
  ui.chapter_label.text="02 / 地下回声  ·  02:26"
  if not fuse_found: ui.objective.text="搜索维修工作台，寻找备用保险丝"
  elif not power_on: ui.objective.text="把保险丝装入左侧的配电箱"
  elif not drained: ui.objective.text="开启右侧排水泵，排空积水"
  elif not log_read and not key_found: ui.objective.text="查看排水区木箱上的值班记录"
  elif not key_found: ui.objective.text="用交接时间打开应急密码柜"
  elif not team_ready: ui.objective.text="前往出口，等待三名队友就位"
  else: ui.objective.text="三名队友已就位 · 用钥匙打开逃生门"
  ui.status.text="同伴  3 / 3\n"+("黄铜钥匙 ✓" if key_found else "供电已恢复" if power_on else "保险丝 ✓" if fuse_found else "物品  —")

func journal_text() -> String:
 var result := "林岚 / 照明　　周屿 / 机械　　许宁 / 观察\n三个人都值得信任。四个人一起离开。\n\n"
 if location=="manor":
  result+="深夜别墅\n从卧室出门左转，起居室在长廊右侧。\n别墅的正门在长廊尽头。庭院右侧有地下通道。"
 else:
  result+="地下设施\n"+("✓" if power_on else "○")+" 恢复供电　　"+("✓" if drained else "○")+" 排空积水\n"+("✓" if key_found else "○")+" 找到钥匙　　"+("✓" if team_ready else "○")+" 四人就位\n"
  if log_read: result+="\n值班记录：交接时间 03:17，密码 0317。"
  else: result+="\n应急柜提示：记住最后一班的交接时间。"
 return result

func hint_text() -> String:
 if location=="manor":
  if not reunited: return "从卧室出门左转，右侧有壁炉的起居室里就是三名队友。"
  if not front_open: return "从起居室回到中央长廊，沿地毯走到写着「出口」的大门。"
  return "倒树挡住了直行的路。向右绕过树，找到绿灯下的地下通道。"
 if not fuse_found: return "入口左边亮着台灯的工作台上，有一枚黄铜色保险丝。"
 if not power_on: return "左侧墙边标着「01」的金属箱就是配电箱。"
 if not drained: return "到右侧标着「02」的机器前，对准红色阀门按 E。"
 if not log_read: return "右侧前方有排水格栅。木箱上的白纸就是值班记录。"
 if not key_found: return "左前方标着「03」的应急柜密码是 0317。"
 return "走到最里面标着「04」的出口。等同伴就位，再对门按 E。"

func say(who: String,text_value: String,duration := 4.5) -> void:
 messages.append({"who":who,"text":text_value,"duration":duration})
 if message_time<=0: next_message()

func next_message() -> void:
 if messages.is_empty():
  ui.dialogue("","")
  message_time=0
  return
 var item: Dictionary=messages.pop_front()
 ui.dialogue(item.who,item.text)
 message_time=item.duration

func load_audio() -> void:
 for id in ["wind","dread","step","click","door","pickup","power"]:
  sounds[id]=load("res://assets/audio/"+id+".wav")
 sounds.wind.loop_mode=AudioStreamWAV.LOOP_FORWARD
 sounds.wind.loop_end=int(sounds.wind.get_length()*sounds.wind.mix_rate)
 ambience=AudioStreamPlayer.new()
 ambience.stream=sounds.wind
 ambience.volume_db=-20
 add_child(ambience)
 if DisplayServer.get_name()!="headless": ambience.play()
 AudioServer.set_bus_volume_db(0,linear_to_db(maxf(volume,0.0001)))

func play_sound(id: String,db := -10.0,pitch := 1.0) -> void:
 if testing or not sounds.has(id): return
 var sound := AudioStreamPlayer.new()
 sound.stream=sounds[id]
 sound.volume_db=db
 sound.pitch_scale=pitch
 add_child(sound)
 sound.finished.connect(sound.queue_free)
 sound.play()

func save_settings() -> void:
 if testing: return
 var config := ConfigFile.new()
 config.set_value("settings","sensitivity",sensitivity)
 config.set_value("settings","brightness",brightness)
 config.set_value("settings","volume",volume)
 config.save("user://settings.cfg")

func load_settings() -> void:
 var config := ConfigFile.new()
 if config.load("user://settings.cfg")==OK:
  sensitivity=clampf(float(config.get_value("settings","sensitivity",0.0022)),0.0007,0.004)
  brightness=clampf(float(config.get_value("settings","brightness",1.0)),0.5,1.6)
  volume=clampf(float(config.get_value("settings","volume",0.7)),0,1)

func _notification(what: int) -> void:
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(ui) and mode=="playing" and player.enabled and not transitioning and not testing and not capturing:
  ui.pause_menu()
 if what==NOTIFICATION_WM_CLOSE_REQUEST:
  save_game()
  get_tree().quit()

func capture_later(label_text: String) -> void:
 await get_tree().create_timer(4).timeout
 await RenderingServer.frame_post_draw
 var file_path := "res://captures/"+label_text+".png"
 get_viewport().get_texture().get_image().save_png(file_path)
 print("CAPTURE_SAVED "+file_path+" FPS="+str(Engine.get_frames_per_second())+" DRAW_CALLS="+str(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
 get_tree().quit()

func _exit_tree() -> void:
 if is_instance_valid(ambience):
  ambience.stop()
  ambience.stream=null
 sounds.clear()
