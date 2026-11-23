extends Node
## Guarda la elección del personaje entre partidas.

const RUTA_CONFIGURACION := "user://preferencias_personaje.cfg"
const PERSONAJES: Dictionary = {
	"casual": {
		"nombre": "Explorador casual",
		"ruta": "res://assets/modelos/personaje_casual.glb"
	},
	"guardia_seguridad": {
		"nombre": "Guardia de seguridad",
		"ruta": "res://assets/modelos/personaje_guardia_seguridad.glb"
	}
}

var personaje_seleccionado := "casual"

func _ready() -> void:
	var configuracion := ConfigFile.new()
	if configuracion.load(RUTA_CONFIGURACION) != OK:
		return
	var guardado := String(configuracion.get_value("personaje", "seleccionado", "casual"))
	if PERSONAJES.has(guardado):
		personaje_seleccionado = guardado

func obtener_ruta_modelo() -> String:
	var datos: Dictionary = PERSONAJES.get(personaje_seleccionado, PERSONAJES["casual"])
	return String(datos["ruta"])

func obtener_nombre_actual() -> String:
	var datos: Dictionary = PERSONAJES.get(personaje_seleccionado, PERSONAJES["casual"])
	return String(datos["nombre"])

func seleccionar(id_personaje: String) -> bool:
	if not PERSONAJES.has(id_personaje):
		return false
	personaje_seleccionado = id_personaje
	var configuracion := ConfigFile.new()
	configuracion.set_value("personaje", "seleccionado", personaje_seleccionado)
	var error_guardado := configuracion.save(RUTA_CONFIGURACION)
	if error_guardado != OK:
		push_warning("No se pudo guardar la elección del personaje (error %d)." % error_guardado)
	return error_guardado == OK
