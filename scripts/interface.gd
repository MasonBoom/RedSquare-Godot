extends Control

enum Screen { WALK, MAP, PAUSE }

const CREAM := Color("#f6edcf")
const PAPER := Color("#eae1c6")
const PINE := Color("#243a34")
const MUTED := Color("#657267")
const RED := Color("#a64b38")
const GOLD := Color("#d4b56b")
const INK := Color("#1d302c")
const WATERMARK := Color("#cbc6af")
const MAP_ORIGIN := Vector2(178, 248)
const CARTO_SCALE := 1.62

@onready var resume_button: Button = $PauseCenter/Panel/Inset/Options/Resume
@onready var sound_button: CheckButton = $PauseCenter/Panel/Inset/Options/Sound

var player: CharacterBody3D
var landmarks: Array = []
var mode := Screen.WALK
var map_from := Screen.WALK
var place := "Red Square"
var hint_time := 11.0
var location_timer := 0.0
var title_font := SystemFont.new()
var ui_font: Font


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_font.font_names = PackedStringArray(["Georgia", "Liberation Serif", "Noto Serif", "DejaVu Serif"])
	ui_font = ThemeDB.fallback_font
	$PauseCenter.hide()
	$PauseCenter/Panel/Inset/Options/Title.add_theme_font_override("font", title_font)
	resume_button.pressed.connect(_change_screen.bind(Screen.WALK))
	$PauseCenter/Panel/Inset/Options/Map.pressed.connect(_open_map)
	$PauseCenter/Panel/Inset/Options/Return.pressed.connect(_return_to_spawn)
	$PauseCenter/Panel/Inset/Options/Quit.pressed.connect(func(): get_tree().quit())
	sound_button.toggled.connect(func(enabled): AudioServer.set_bus_mute(0, not enabled))
	sound_button.set_pressed_no_signal(not AudioServer.is_bus_mute(0))


func setup(body: CharacterBody3D, sights: Array) -> void:
	player = body
	landmarks = sights
	_change_screen(Screen.WALK)


func _change_screen(next: Screen) -> void:
	mode = next
	get_tree().paused = next != Screen.WALK
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if next == Screen.WALK else Input.MOUSE_MODE_VISIBLE
	$PauseCenter.visible = next == Screen.PAUSE
	if next == Screen.PAUSE:
		resume_button.grab_focus()
	queue_redraw()


func _open_map() -> void:
	map_from = mode
	_change_screen(Screen.MAP)


func _return_to_spawn() -> void:
	player.call("respawn")
	location_timer = 0.0
	_change_screen(Screen.WALK)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready() and player != null:
		if mode == Screen.WALK:
			_change_screen(Screen.PAUSE)


func _input(event: InputEvent) -> void:
	if not player:
		return
	if event.is_action_pressed("toggle_map"):
		if mode == Screen.MAP:
			_change_screen(map_from)
		else:
			_open_map()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause_game"):
		if mode == Screen.MAP:
			_change_screen(map_from)
		elif mode == Screen.PAUSE:
			_change_screen(Screen.WALK)
		else:
			_change_screen(Screen.PAUSE)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not player or mode != Screen.WALK:
		return
	if hint_time > 0.0:
		hint_time -= delta
		if hint_time <= 0.0:
			queue_redraw()
	location_timer -= delta
	if location_timer > 0.0:
		return
	location_timer = 0.22
	var nearest := INF
	var label := "Red Square"
	for site in landmarks:
		var distance: float = site.distance_from_outline(player.global_position)
		if distance <= site.name_distance and distance < nearest:
			nearest = distance
			label = site.title
	if label != place:
		place = label
		queue_redraw()


func _text(pos: Vector2, value: String, font_size: int, color: Color, face: Font = null) -> void:
	draw_string(face if face != null else ui_font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _map_point(p: Vector3) -> Vector2:
	# The district is rotated into a north-up schematic.
	return MAP_ORIGIN + Vector2(-p.x, -p.z) * CARTO_SCALE


func _compass(center: Vector2, tint: Color) -> void:
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -11),
			center + Vector2(5, 6), center, center + Vector2(-5, 6)]), tint)


func _draw_map() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.10, 0.09, 0.63))
	var sheet := Vector2(686, 496)
	var scale_factor := minf((size.x - 38.0) / sheet.x, (size.y - 38.0) / sheet.y)
	scale_factor = minf(scale_factor, 1.16)
	var offset := (size - sheet * scale_factor) * 0.5
	draw_set_transform(offset, 0.0, Vector2.ONE * scale_factor)
	draw_rect(Rect2(4, 7, sheet.x, sheet.y), Color(0, 0, 0, 0.25))
	draw_rect(Rect2(Vector2.ZERO, sheet), PAPER)
	draw_rect(Rect2(10, 10, sheet.x - 20, sheet.y - 20), WATERMARK, false, 1.0)
	draw_line(Vector2(333, 33), Vector2(333, 463), WATERMARK, 1.0)
	_text(Vector2(34, 48), "ПЛАН ПЛОЩАДИ", 13, MUTED)
	_compass(Vector2(52, 100), PINE)
	_text(Vector2(47, 82), "N", 13, PINE)
	var bounds := Rect2(_map_point(Vector3(43, 0, 102)), Vector2(90, 204) * CARTO_SCALE)
	draw_rect(bounds.grow(8), Color("#ddd7bf"))
	draw_rect(bounds, Color("#f5edd4"))
	draw_rect(bounds, Color("#b7b59e"), false, 1.3)
	for garden in [Vector3(-27, 0, -74), Vector3(15, 0, -78), Vector3(35, 0, 52)]:
		var g := _map_point(garden)
		draw_rect(Rect2(g - Vector2(7, 16), Vector2(14, 32)), Color("#a3b18c"))
	for site in landmarks:
		var half: Vector2 = site.footprint * 0.5
		var corners := PackedVector2Array()
		for v in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			corners.append(_map_point(site.to_global(Vector3(v.x * half.x, 0, v.y * half.y))))
		var fill := Color("#ad7865") if site.map_number != 3 else Color("#b8a077")
		draw_colored_polygon(corners, fill)
		var p := _map_point(site.global_position)
		# The rampart label sits on a clear stretch beside the clock tower.
		if site.map_number == 6:
			p.y -= 57.0
		draw_circle(p, 10.2, PINE, true, -1.0, true)
		_text(p + Vector2(-4.0, 4.1), str(site.map_number), 11, CREAM)
	var at := _map_point(player.global_position)
	var forward := -player.global_transform.basis.z
	var direction := Vector2(-forward.x, -forward.z).normalized()
	var side := Vector2(-direction.y, direction.x)
	draw_circle(at, 9.1, PAPER, true, -1.0, true)
	draw_colored_polygon(PackedVector2Array([at + direction * 10.0, at - direction * 5.7 + side * 5.2,
			at - direction * 3.4, at - direction * 5.7 - side * 5.2]), RED)
	_text(Vector2(361, 74), "МОСКВА", 15, MUTED)
	_text(Vector2(359, 124), "Red Square", 48, PINE, title_font)
	draw_line(Vector2(362, 146), Vector2(648, 146), WATERMARK, 1)
	for i in landmarks.size():
		var y := 183.0 + 31.0 * i
		draw_circle(Vector2(372, y - 5), 9.6, PINE, true, -1.0, true)
		_text(Vector2(368.4, y - 1.1), str(landmarks[i].map_number), 11, CREAM)
		_text(Vector2(392, y), landmarks[i].title, 17, INK)
	draw_circle(Vector2(372, 388), 5.0, RED, true, -1.0, true)
	_text(Vector2(392, 394), "Your position", 15, INK)
	draw_line(Vector2(362, 417), Vector2(648, 417), WATERMARK, 1)
	_text(Vector2(362, 448), "M  /  Esc     Close map", 14, MUTED)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw() -> void:
	if not player or not ui_font:
		return
	if mode == Screen.MAP:
		_draw_map()
		return
	if mode == Screen.PAUSE:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.045, 0.075, 0.067, 0.64))
		return
	var width := maxf(190.0, title_font.get_string_size(place, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x + 47)
	draw_rect(Rect2(25, 24, width, 70), Color(0.06, 0.11, 0.10, 0.76))
	draw_rect(Rect2(25, 24, 3, 70), GOLD)
	_text(Vector2(42, 47), "МОСКВА   /   MOSCOW", 12, CREAM)
	_text(Vector2(40, 79), place, 30, Color.WHITE, title_font)
	draw_circle(size * 0.5, 2.0, Color(0.12, 0.17, 0.16, 0.65), true, -1.0, true)
	draw_circle(size * 0.5, 1.1, Color(1, 1, 0.92, 0.80), true, -1.0, true)
	var baseline := size.y - 28.0
	if hint_time > 0.0:
		draw_rect(Rect2(25, baseline - 26.0, 427, 37), Color(0.06, 0.10, 0.09, 0.72))
		_text(Vector2(39, baseline - 1), "WASD  Move     Mouse  Look     Shift  Run     Space  Jump", 15, CREAM)
	draw_rect(Rect2(size.x - 187, baseline - 26, 162, 37), Color(0.06, 0.10, 0.09, 0.72))
	_text(Vector2(size.x - 173, baseline - 1), "M   Map     Esc   Pause", 14, CREAM)
