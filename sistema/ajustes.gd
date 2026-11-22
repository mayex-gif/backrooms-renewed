extends Node
## Ajustes del jugador: pantalla, audio, controles y calidad. Se guardan en
## user://ajustes.cfg y se aplican al iniciar. Autoload con el nombre "Ajustes".
## También aplica a todo el juego un tema visual común para los menús.

signal ajustes_cambiados

const RUTA := "user://ajustes.cfg"

var pantalla_completa := false
var vsync := true
## Volumen general, de 0 a 1.
var volumen := 0.8
## Multiplicador de la sensibilidad del mouse.
var sensibilidad := 1.0
var campo_vision := 75.0
var sombras := true
## Rebote de luz en pantalla (SSIL).
var rebote_pantalla := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	cargar()
	get_tree().root.theme = _crear_tema()
	aplicar()

func cargar() -> void:
	var archivo := ConfigFile.new()
	if archivo.load(RUTA) != OK:
		return
	pantalla_completa = bool(archivo.get_value("pantalla", "completa", pantalla_completa))
	vsync = bool(archivo.get_value("pantalla", "vsync", vsync))
	volumen = clampf(float(archivo.get_value("audio", "volumen", volumen)), 0.0, 1.0)
	sensibilidad = clampf(float(archivo.get_value("controles", "sensibilidad", sensibilidad)), 0.1, 4.0)
	campo_vision = clampf(float(archivo.get_value("video", "campo_vision", campo_vision)), 50.0, 110.0)
	sombras = bool(archivo.get_value("video", "sombras", sombras))
	rebote_pantalla = bool(archivo.get_value("video", "rebote_pantalla", rebote_pantalla))

func guardar() -> void:
	var archivo := ConfigFile.new()
	archivo.set_value("pantalla", "completa", pantalla_completa)
	archivo.set_value("pantalla", "vsync", vsync)
	archivo.set_value("audio", "volumen", volumen)
	archivo.set_value("controles", "sensibilidad", sensibilidad)
	archivo.set_value("video", "campo_vision", campo_vision)
	archivo.set_value("video", "sombras", sombras)
	archivo.set_value("video", "rebote_pantalla", rebote_pantalla)
	archivo.save(RUTA)

func restablecer() -> void:
	pantalla_completa = false
	vsync = true
	volumen = 0.8
	sensibilidad = 1.0
	campo_vision = 75.0
	sombras = true
	rebote_pantalla = true
	aplicar()
	guardar()

## Aplica los valores actuales al juego en marcha.
func aplicar() -> void:
	var modo := DisplayServer.WINDOW_MODE_FULLSCREEN if pantalla_completa else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != modo:
		DisplayServer.window_set_mode(modo)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volumen, 0.0001)))
	for luz in get_tree().get_nodes_in_group("luces_techo_nodos"):
		if luz is SpotLight3D:
			(luz as SpotLight3D).shadow_enabled = sombras
	for nodo in get_tree().get_nodes_in_group("entornos_juego"):
		var entorno := nodo as WorldEnvironment
		if entorno != null and entorno.environment != null:
			entorno.environment.ssil_enabled = rebote_pantalla
	ajustes_cambiados.emit()


## Tema común: tonos de las Backrooms (amarillo apagado) para botones, paneles y listas.
func _crear_tema() -> Theme:
	var tema := Theme.new()
	var texto := Color(0.90, 0.87, 0.74)
	var borde := Color(0.42, 0.39, 0.27)
	tema.set_color("font_color", "Label", texto)
	tema.set_stylebox("panel", "PanelContainer", _caja(Color(0.145, 0.135, 0.10, 0.97), borde, 6, 10))
	tema.set_stylebox("normal", "Button", _caja(Color(0.23, 0.21, 0.15), borde, 4, 8))
	tema.set_stylebox("hover", "Button", _caja(Color(0.31, 0.28, 0.19), Color(0.62, 0.57, 0.38), 4, 8))
	tema.set_stylebox("pressed", "Button", _caja(Color(0.40, 0.36, 0.22), Color(0.75, 0.69, 0.45), 4, 8))
	tema.set_stylebox("disabled", "Button", _caja(Color(0.16, 0.15, 0.12), Color(0.25, 0.24, 0.19), 4, 8))
	var foco := _caja(Color(0, 0, 0, 0), Color(0.86, 0.82, 0.62), 4, 8)
	foco.draw_center = false
	tema.set_stylebox("focus", "Button", foco)
	tema.set_color("font_color", "Button", texto)
	tema.set_color("font_hover_color", "Button", Color(1.0, 0.98, 0.86))
	tema.set_color("font_pressed_color", "Button", Color(1.0, 0.98, 0.86))
	tema.set_color("font_disabled_color", "Button", Color(0.50, 0.48, 0.40))
	tema.set_stylebox("panel", "ItemList", _caja(Color(0.10, 0.095, 0.075), borde, 4, 4))
	tema.set_stylebox("selected", "ItemList", _caja(Color(0.38, 0.34, 0.21), Color(0.70, 0.64, 0.42), 3, 3))
	tema.set_stylebox("selected_focus", "ItemList", _caja(Color(0.38, 0.34, 0.21), Color(0.86, 0.82, 0.62), 3, 3))
	tema.set_color("font_color", "ItemList", texto)
	tema.set_color("font_selected_color", "ItemList", Color(1.0, 0.98, 0.86))
	tema.set_stylebox("normal", "LineEdit", _caja(Color(0.10, 0.095, 0.075), borde, 3, 5))
	tema.set_stylebox("focus", "LineEdit", _caja(Color(0.10, 0.095, 0.075), Color(0.86, 0.82, 0.62), 3, 5))
	tema.set_color("font_color", "LineEdit", texto)
	return tema

func _caja(fondo: Color, borde: Color, radio: int, margen: int) -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = fondo
	caja.border_color = borde
	caja.set_border_width_all(1)
	caja.set_corner_radius_all(radio)
	caja.set_content_margin_all(margen)
	return caja
