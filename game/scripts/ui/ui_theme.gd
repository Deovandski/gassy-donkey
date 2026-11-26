class_name UiTheme
## The finished game's look: Comic Relief, the 2016 title orange and planet-name cyan, the 2016 parchment
## panel (art/legacy/menu/text_background.png), and big touch-friendly buttons.

const FONT := preload("res://fonts/ComicRelief-Regular.ttf")
const FONT_BOLD := preload("res://fonts/ComicRelief-Bold.ttf")
## The 2016 colours: "Gassy Donkey" title orange and "Planet" name cyan (MainGame.unity).
const ORANGE := Color(1, 0.651927, 0.0294118)
const CYAN := Color(0.2119377, 0.7476077, 0.8235294)
const PEACH := Color(1, 0.769574, 0.4779412)
const INK := Color(0.16, 0.1, 0.05)
const CREAM := Color(1.0, 0.95, 0.82)

static var _theme: Theme


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = FONT
	t.default_font_size = 26
	t.set_color("font_color", "Label", Color.WHITE)
	t.set_constant("outline_size", "Label", 0)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		t.set_stylebox(state, "Button", _button_box(state))
	t.set_font("font", "Button", FONT_BOLD)
	t.set_font_size("font_size", "Button", 28)
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", INK)
	t.set_color("font_pressed_color", "Button", INK)
	t.set_color("font_focus_color", "Button", INK)
	t.set_color("font_hover_pressed_color", "Button", INK)
	t.set_color("font_disabled_color", "Button", Color(0.35, 0.3, 0.25))
	t.set_stylebox("panel", "PanelContainer", panel_box())
	t.set_stylebox("panel", "Panel", panel_box())
	t.set_color("font_color", "CheckButton", INK)
	t.set_font_size("font_size", "CheckButton", 26)
	_theme = t
	return t


static func _button_box(state: String) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = {
		"normal": ORANGE, "hover": ORANGE.lightened(0.15), "pressed": ORANGE.darkened(0.15),
		"disabled": Color(0.6, 0.55, 0.5), "focus": ORANGE.lightened(0.1)}[state]
	b.set_corner_radius_all(18)
	b.set_border_width_all(4)
	b.border_color = INK if state != "focus" else Color.WHITE
	b.content_margin_left = 22
	b.content_margin_right = 22
	b.content_margin_top = 8
	b.content_margin_bottom = 10
	b.shadow_color = Color(0, 0, 0, 0.35)
	b.shadow_size = 0 if state == "pressed" else 4
	b.shadow_offset = Vector2(0, 4)
	b.anti_aliasing = true
	return b


## The 2016 parchment panel ("Menu Scene Text background"), stretched with its border kept.
static func panel_box() -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = load("res://art/legacy/menu/text_background.png")
	s.region_rect = Rect2(89, 19, 331, 411)
	s.set_texture_margin_all(10)
	s.set_content_margin_all(24)
	return s


static func label(text: String, size := 26, color := Color.WHITE, bold := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_font_override("font", FONT_BOLD)
	if color == Color.WHITE or color == ORANGE or color == CYAN or color == PEACH:
		l.add_theme_constant_override("outline_size", maxi(4, size / 7))
		l.add_theme_color_override("font_outline_color", INK)
	return l


static func button(text: String, on_press: Callable, min_width := 260) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_width, 64)
	b.pressed.connect(func() -> void:
		Audio.play("click")
		on_press.call())
	return b


## A small round icon button (pause, back).
static func icon_button(texture: Texture2D, on_press: Callable, size := 72) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = texture
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.custom_minimum_size = Vector2(size, size)
	b.pressed.connect(func() -> void:
		Audio.play("click")
		on_press.call())
	return b


## A screen title in the 2016 orange.
static func title(text: String, size := 64) -> Label:
	var l := label(text, size, ORANGE, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l
