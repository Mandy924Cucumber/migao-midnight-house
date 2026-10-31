class_name HouseInterface
extends CanvasLayer

var game: Node
var root: Control
var menu: Control
var hud: Control
var modal: Control
var fade: ColorRect
var objective: Label
var chapter_label: Label
var prompt: Label
var subtitle: Label
var speaker: Label
var dialogue_panel: PanelContainer
var status: Label
var tip: Label
var code_input: LineEdit
var code_error: Label
var journal_open := false
var gold := Color("d4bd8a")
var pale := Color("e6e4da")
var muted := Color("91a4a5")

func _ready() -> void:
 layer = 10
 root = Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(root)
 var theme := Theme.new()
 theme.default_font = game.font
 theme.default_font_size = 18
 root.theme = theme
 var film := ColorRect.new()
 film.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 film.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var shader_material := ShaderMaterial.new()
 shader_material.shader = preload("res://shaders/film.gdshader")
 film.material = shader_material
 root.add_child(film)
 build_hud()
 fade = ColorRect.new()
 fade.color = Color.BLACK
 fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
 root.add_child(fade)
 fade.modulate.a = 0

func label(parent: Node,text_value: String,at: Vector2,size: Vector2,font_size: int,tint: Color) -> Label:
 var l := Label.new()
 l.text = text_value
 l.position = at
 l.size = size
 l.add_theme_font_size_override("font_size",font_size)
 l.add_theme_color_override("font_color",tint)
 l.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(l)
 return l

func panel_style(bg := Color("111d22"),border := Color("44544f")) -> StyleBoxFlat:
 var style := StyleBoxFlat.new()
 style.bg_color = bg
 style.border_color = border
 style.set_border_width_all(1)
 style.content_margin_left = 24
 style.content_margin_right = 24
 style.content_margin_top = 16
 style.content_margin_bottom = 16
 return style

func button(parent: Node,text_value: String,at: Vector2,size: Vector2,callback: Callable,primary := false) -> Button:
 var b := Button.new()
 b.text = text_value
 b.position = at
 b.size = size
 b.add_theme_font_size_override("font_size",20)
 b.add_theme_color_override("font_color",Color("142025") if primary else pale)
 b.add_theme_color_override("font_hover_color",Color("142025"))
 b.add_theme_stylebox_override("normal",panel_style(gold if primary else Color(0.045,0.08,0.1,0.8),gold if primary else Color("43534e")))
 b.add_theme_stylebox_override("hover",panel_style(Color("e2cca0"),gold))
 b.add_theme_stylebox_override("pressed",panel_style(Color("a58d62"),gold))
 b.add_theme_stylebox_override("focus",panel_style(Color(0,0,0,0),pale))
 b.pressed.connect(callback)
 parent.add_child(b)
 return b

func screen() -> Control:
 var c := Control.new()
 c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.add_child(c)
 return c

func shade(parent: Node,alpha: float) -> void:
 var r := ColorRect.new()
 r.color = Color(0.015,0.028,0.036,alpha)
 r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 parent.add_child(r)

func show_menu() -> void:
 close_modal()
 hud.hide()
 if is_instance_valid(menu): menu.queue_free()
 menu = screen()
 var scrim := ColorRect.new()
 scrim.position = Vector2.ZERO
 scrim.size = Vector2(650,900)
 scrim.color = Color(0.019,0.035,0.042,0.87)
 menu.add_child(scrim)
 label(menu,"N O C T U R N E   /   0 1",Vector2(82,75),Vector2(520,30),18,gold)
 label(menu,"夜半\n回廊",Vector2(75,170),Vector2(530,270),104,pale)
 label(menu,"M I D N I G H T   H O U S E",Vector2(83,472),Vector2(500,30),19,gold)
 label(menu,"门外的声音，叫出了你们的名字。\n四个人来到这里，也要四个人离开。",Vector2(83,530),Vector2(490,80),22,Color("aebbbb"))
 button(menu,"开始新的夜晚    →",Vector2(83,625),Vector2(440,60),game.new_game,true)
 if game.has_save():
  button(menu,"继续检查点",Vector2(83,702),Vector2(215,54),game.continue_game)
  button(menu,"游戏设置",Vector2(309,702),Vector2(214,54),func(): show_settings(true))
 else:
  button(menu,"游戏设置",Vector2(83,702),Vector2(440,54),func(): show_settings(true))
 label(menu,"第一人称 · 剧情解谜 · 三名可信赖的同伴",Vector2(83,815),Vector2(550,30),15,muted)
 label(menu,"一段关于信任的逃生故事",Vector2(1050,70),Vector2(310,30),17,pale)
 label(menu,"01 / 深夜别墅\n02 / 地下回声\n03 / 黎明之前",Vector2(1100,710),Vector2(280,100),18,gold)
 label(menu,"建议佩戴耳机  /  无血腥画面",Vector2(1080,837),Vector2(300,25),14,muted)

func hide_menu() -> void:
 if is_instance_valid(menu): menu.queue_free()
 menu = null
 hud.show()

func build_hud() -> void:
 hud = screen()
 hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
 chapter_label = label(hud,"01 / 深夜别墅",Vector2(45,34),Vector2(550,30),16,gold)
 objective = label(hud,"离开卧室，与队友会合",Vector2(45,68),Vector2(900,40),24,pale)
 status = label(hud,"",Vector2(1035,38),Vector2(355,80),16,pale)
 status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 label(hud,"·",Vector2(711,431),Vector2(18,32),27,Color(1,1,1,0.75))
 prompt = label(hud,"",Vector2(350,504),Vector2(740,42),22,pale)
 prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 prompt.add_theme_color_override("font_outline_color",Color("101a20"))
 prompt.add_theme_constant_override("outline_size",7)
 tip = label(hud,"WASD 移动    Shift 快跑    E 交互    F 手电    Tab 笔记    Esc 暂停",Vector2(45,850),Vector2(1260,25),15,muted)
 dialogue_panel = PanelContainer.new()
 dialogue_panel.position = Vector2(290,680)
 dialogue_panel.size = Vector2(860,132)
 dialogue_panel.add_theme_stylebox_override("panel",panel_style(Color(0.035,0.06,0.073,0.92),Color("52645c")))
 hud.add_child(dialogue_panel)
 var inner := Control.new()
 inner.custom_minimum_size = Vector2(812,98)
 dialogue_panel.add_child(inner)
 speaker = label(inner,"",Vector2(0,0),Vector2(810,26),16,gold)
 subtitle = label(inner,"",Vector2(0,32),Vector2(805,66),22,pale)
 subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 dialogue_panel.hide()
 hud.hide()

func dialogue(who: String,text_value: String) -> void:
 if text_value.is_empty():
  dialogue_panel.hide()
 else:
  speaker.text = who
  subtitle.text = text_value
  dialogue_panel.show()

func close_modal() -> void:
 if is_instance_valid(modal): modal.queue_free()
 modal = null
 journal_open = false

func modal_base(title: String,kicker: String) -> Control:
 close_modal()
 modal = screen()
 shade(modal,0.91)
 label(modal,kicker,Vector2(295,126),Vector2(850,30),16,gold)
 label(modal,title,Vector2(291,180),Vector2(860,60),44,pale)
 return modal

func pause_menu() -> void:
 game.set_controls(false)
 modal_base("夜还很长。", "P A U S E  /  暂 停")
 label(modal,"深呼吸。你的同伴就在附近。",Vector2(295,264),Vector2(850,45),21,muted)
 button(modal,"继续游戏    →",Vector2(295,355),Vector2(850,62),game.resume_game,true)
 button(modal,"查看笔记",Vector2(295,436),Vector2(414,58),show_journal)
 button(modal,"游戏设置",Vector2(731,436),Vector2(414,58),func(): show_settings(false))
 button(modal,"返回主菜单（自动保留进度）",Vector2(295,515),Vector2(850,58),game.return_menu)
 label(modal,"游戏已暂停  ·  Esc 返回",Vector2(295,684),Vector2(850,35),17,muted)

func show_journal() -> void:
 game.set_controls(false)
 modal_base("随身笔记", "F I E L D  N O T E S")
 journal_open = true
 var notes := label(modal,game.journal_text(),Vector2(295,275),Vector2(850,320),23,pale)
 notes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 button(modal,"需要一点提示",Vector2(295,659),Vector2(414,58),func():
  notes.text = game.journal_text()+"\n\n提示 / "+game.hint_text())
 button(modal,"回到游戏    →",Vector2(731,659),Vector2(414,58),game.resume_game,true)

func show_note(title: String,body: String) -> void:
 game.set_controls(false)
 modal_base(title,"F O U N D  D O C U M E N T  /  发 现 文 件")
 var text_label := label(modal,body,Vector2(295,290),Vector2(850,340),25,pale)
 text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 button(modal,"收好记录    →",Vector2(295,679),Vector2(850,58),game.resume_game,true)

func show_keypad() -> void:
 game.set_controls(false)
 modal_base("应急钥匙柜", "S E C U R I T Y  /  四 位 密 码")
 label(modal,"柜门上刻着一行字：『记住最后一班的交接时间。』",Vector2(295,280),Vector2(850,65),22,muted)
 code_input = LineEdit.new()
 code_input.position = Vector2(465,395)
 code_input.size = Vector2(510,88)
 code_input.max_length = 4
 code_input.placeholder_text = "— — — —"
 code_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
 code_input.add_theme_font_size_override("font_size",44)
 code_input.add_theme_color_override("font_color",gold)
 code_input.add_theme_stylebox_override("normal",panel_style())
 code_input.text_submitted.connect(func(_value: String): game.try_code(code_input.text))
 modal.add_child(code_input)
 code_input.grab_focus()
 code_error = label(modal,"",Vector2(295,510),Vector2(850,45),19,Color("d5a191"))
 code_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 button(modal,"暂时离开",Vector2(295,650),Vector2(414,58),game.resume_game)
 button(modal,"确认密码    →",Vector2(731,650),Vector2(414,58),func(): game.try_code(code_input.text),true)

func show_settings(from_menu: bool) -> void:
 modal_base("游戏设置", "S E T T I N G S")
 label(modal,"鼠标灵敏度",Vector2(295,310),Vector2(400,35),22,pale)
 slider(Vector2(720,317),0.0007,0.004,game.sensitivity,func(v: float): game.sensitivity=v; game.player.look_sensitivity=v)
 label(modal,"环境亮度",Vector2(295,403),Vector2(400,35),22,pale)
 slider(Vector2(720,410),0.5,1.6,game.brightness,func(v: float): game.brightness=v; game.apply_brightness())
 label(modal,"声音音量",Vector2(295,496),Vector2(400,35),22,pale)
 slider(Vector2(720,503),0,1,game.volume,func(v: float): game.volume=v; AudioServer.set_bus_volume_db(0,linear_to_db(maxf(v,0.0001))))
 label(modal,"手电筒无电量限制。亮度可随时调整。",Vector2(295,591),Vector2(850,40),17,muted)
 button(modal,"保存并返回    →",Vector2(295,680),Vector2(850,58),func():
  game.save_settings()
  if from_menu: close_modal()
  else: pause_menu(),true)

func slider(at: Vector2,lo: float,hi: float,value: float,callback: Callable) -> void:
 var s := HSlider.new()
 s.position = at
 s.size = Vector2(425,30)
 s.min_value = lo
 s.max_value = hi
 s.step = (hi-lo)/200
 s.value = value
 s.value_changed.connect(callback)
 modal.add_child(s)

func ending() -> void:
 hud.hide()
 modal_base("我们，一个也没少。", "D A W N  /  0 5 : 4 6")
 label(modal,"晨光落在铁门外，别墅终于安静下来。\n林岚收起手电，周屿松开机关，许宁回头数了数人。\n\n四个人。都在。",Vector2(295,290),Vector2(850,210),25,pale)
 label(modal,"夜半回廊  ·  已完成\n谢谢你没有丢下任何一个同伴。",Vector2(295,547),Vector2(850,80),20,gold)
 button(modal,"再经历一个夜晚",Vector2(295,684),Vector2(414,58),game.new_game,true)
 button(modal,"回到主菜单",Vector2(731,684),Vector2(414,58),game.return_menu)
