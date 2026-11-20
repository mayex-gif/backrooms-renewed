extends Control
## Editor 2D simple de módulos. Guarda diseños JSON en el espacio del usuario.

const ConexionesMapaScript = preload("res://datos/conexiones_mapa.gd")
const PlanificadorSolapesScript = preload("res://datos/planificador_solapes.gd")

var _catalogo: Array[SalaDef] = []
var _salas: Array[Dictionary] = []
var _seleccion := 0
var _giros := 0
var _escala := 24.0
var _desplazamiento_vista := Vector2.ZERO
var _lienzo: Control
var _selector: OptionButton
var _estado: Label
var _dialogo: FileDialog
var _ruta_actual := "user://saves/mapa_actual.json"
var _lista_guardados: OptionButton
var _arrastre := -1
var _desfase_arrastre := Vector2.ZERO
var _paneo_activo := false
var _ultima_posicion_paneo := Vector2.ZERO
var _paredes_abiertas := false
var _check_paredes: CheckButton
## Módulos del archivo cuyo tipo ya no existe en el catálogo. Se conservan tal
## cual para que el autoguardado no los borre del JSON.
var _desconocidas: Array = []
## Nombres retirados del catálogo del editor, conservados como equivalentes geométricos.
var _alias_tipos: Dictionary = {}
## Estado elegido a mano para cada conexión: clave (ConexionesMapa.clave_de) -> estado.
var _estados_conexion: Dictionary = {}
## Estado por tramo interior superpuesto: true lo abre, false lo conserva como tabique.
var _estados_solape: Dictionary = {}
var _siguiente_id := 0

func _ready() -> void:
	var script_catalogo: Script = load("res://salas/catalogo_salas.gd")
	var catalogo_completo := script_catalogo.call("crear") as Array[SalaDef]
	_catalogo = _quitar_duplicados_catalogo(catalogo_completo)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	_crear_interfaz()
	if FileAccess.file_exists(_ruta_actual):
		_cargar_ruta(_ruta_actual)
	queue_redraw()

func _crear_interfaz() -> void:
	var columna := VBoxContainer.new()
	columna.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(columna)
	var barra := HBoxContainer.new()
	barra.custom_minimum_size.y = 48
	columna.add_child(barra)
	_selector = OptionButton.new()
	_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for definicion in _catalogo:
		_selector.add_item("%s  (%.1f × %.1f m)" % [definicion.nombre, definicion.ancho_m, definicion.largo_m])
	_selector.item_selected.connect(func(indice: int) -> void: _seleccion = indice)
	barra.add_child(_selector)
	_agregar_boton(barra, "Girar", _girar)
	_agregar_boton(barra, "Guardar", _guardar_actual)
	_agregar_boton(barra, "Guardar como", _abrir_guardar)
	_agregar_boton(barra, "Jugar", _jugar)
	_agregar_boton(barra, "Cargar", _abrir_cargar)
	_lista_guardados = OptionButton.new()
	_lista_guardados.item_selected.connect(_seleccionar_guardado)
	barra.add_child(_lista_guardados)
	_check_paredes = CheckButton.new()
	_check_paredes.text = "Pared completa abierta"
	_check_paredes.toggled.connect(func(activo: bool) -> void:
		_paredes_abiertas = activo
		_guardar_actual()
		_lienzo.queue_redraw()
	)
	barra.add_child(_check_paredes)
	_agregar_boton(barra, "Limpiar", _limpiar)
	_agregar_boton(barra, "Volver", func() -> void: get_tree().change_scene_to_file("res://pruebas/menu_principal.tscn"))
	_lienzo = Control.new()
	_lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lienzo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lienzo.draw.connect(_dibujar)
	_lienzo.gui_input.connect(_entrada_lienzo)
	columna.add_child(_lienzo)
	_estado = Label.new()
	_estado.custom_minimum_size.y = 28
	_estado.text = "Click: colocar/cambiar · arrastrar: mover sala · botón central: mover lienzo · botón derecho: borrar · rueda: zoom · verde: puerta · celeste: abierta con dintel · naranja: cerrada · violeta: abierta sin dintel · círculo: sin solapes"
	columna.add_child(_estado)
	_dialogo = FileDialog.new()
	_dialogo.access = FileDialog.ACCESS_FILESYSTEM
	_dialogo.add_filter("*.json", "Mapa JSON")
	add_child(_dialogo)
	_dialogo.file_selected.connect(_archivo_elegido)
	_actualizar_guardados()

func _agregar_boton(barra: HBoxContainer, texto: String, accion: Callable) -> void:
	var boton := Button.new()
	boton.text = texto
	boton.pressed.connect(accion)
	barra.add_child(boton)

func _girar() -> void:
	_giros = posmod(_giros + 1, 4)
	_estado.text = "Giro seleccionado: %d°" % (_giros * 90)

func _limpiar() -> void:
	_salas.clear()
	_desconocidas.clear()
	_estados_conexion.clear()
	_estados_solape.clear()
	_cambio_mapa("Mapa limpio.")

func _abrir_guardar() -> void:
	_dialogo.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_dialogo.current_dir = ProjectSettings.globalize_path("user://saves")
	_dialogo.current_file = "mapa_personalizado.json"
	_dialogo.popup_centered(Vector2i(760, 520))

func _abrir_cargar() -> void:
	_dialogo.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_dialogo.popup_centered(Vector2i(760, 520))

func _archivo_elegido(ruta: String) -> void:
	if _dialogo.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		var archivo := FileAccess.open(ruta, FileAccess.WRITE)
		if archivo == null:
			_estado.text = "No se pudo guardar el archivo."
			return
		archivo.store_string(_serializar())
		_ruta_actual = ruta
		_estado.text = "Mapa guardado: %s" % ruta
		_actualizar_guardados()
	else:
		_cargar_ruta(ruta)
	_lienzo.queue_redraw()
	_actualizar_guardados()

func _guardar_actual() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var archivo := FileAccess.open(_ruta_actual, FileAccess.WRITE)
	if archivo == null:
		_estado.text = "No se pudo guardar el mapa."
		return
	archivo.store_string(_serializar())
	_estado.text = "Guardado: %s" % _ruta_actual.get_file()
	_actualizar_guardados()

## Texto JSON del mapa actual. Conserva los módulos de tipo desconocido.
func _serializar() -> String:
	var filas: Array = _salas.map(func(s: Dictionary) -> Dictionary: return {"id": s.id, "tipo": s.tipo, "x": s.x, "z": s.z, "giros": s.giros})
	filas.append_array(_desconocidas)
	return JSON.stringify({"version": 3, "paredes_abiertas": _paredes_abiertas, "conexiones": _estados_conexion, "solapes": _estados_solape, "salas": filas}, "\t")

func _actualizar_guardados() -> void:
	if _lista_guardados == null:
		return
	_lista_guardados.clear()
	var dir := DirAccess.open("user://saves")
	if dir == null:
		return
	dir.list_dir_begin()
	var nombre := dir.get_next()
	while not nombre.is_empty():
		if not dir.current_is_dir() and nombre.ends_with(".json"):
			_lista_guardados.add_item(nombre)
			_lista_guardados.set_item_metadata(_lista_guardados.item_count - 1, "user://saves/" + nombre)
		nombre = dir.get_next()
	dir.list_dir_end()

func _seleccionar_guardado(indice: int) -> void:
	var ruta := String(_lista_guardados.get_item_metadata(indice))
	if ruta.is_empty():
		return
	_cargar_ruta(ruta)

func _cargar_ruta(ruta: String) -> void:
	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		_estado.text = "No se pudo abrir el mapa guardado."
		return
	var datos: Variant = JSON.parse_string(archivo.get_as_text())
	if not datos is Dictionary or not datos.has("salas"):
		_estado.text = "El archivo no contiene un mapa válido."
		return
	_salas.clear()
	_desconocidas.clear()
	_estados_conexion.clear()
	_estados_solape.clear()
	_paredes_abiertas = bool(datos.get("paredes_abiertas", false))
	var estados_guardados: Variant = datos.get("conexiones", {})
	if estados_guardados is Dictionary:
		for clave in estados_guardados:
			if ConexionesMapaScript.ESTADOS.has(String(estados_guardados[clave])):
				_estados_conexion[String(clave)] = String(estados_guardados[clave])
	var solapes_guardados: Variant = datos.get("solapes", {})
	if solapes_guardados is Dictionary:
		_estados_solape = solapes_guardados.duplicate()
	# Sin señal: si no, el CheckButton dispara _guardar_actual() con la lista de
	# salas vacía y pisa el archivo que estaba abierto antes de este.
	_check_paredes.set_pressed_no_signal(_paredes_abiertas)
	# Los mapas viejos no traen "id": se usa la posición de la fila en el archivo
	# (mapa_guardado.gd aplica la misma regla).
	_siguiente_id = 0
	var posicion_fila := 0
	for fila in datos.salas:
		var id_fila := int(fila.get("id", posicion_fila))
		_siguiente_id = maxi(_siguiente_id, id_fila + 1)
		var tipo_original := String(fila.get("tipo", ""))
		var tipo := String(_alias_tipos.get(tipo_original, tipo_original))
		if _indice_tipo(tipo) >= 0:
			_salas.append({"id": id_fila, "tipo": tipo, "x": float(fila.x), "z": float(fila.z), "giros": int(fila.giros)})
		else:
			_desconocidas.append(fila)
		posicion_fila += 1
	_ruta_actual = ruta
	var aviso := ""
	if not _desconocidas.is_empty():
		aviso += " · %d módulos de un tipo que ya no existe se conservan sin mostrarse" % _desconocidas.size()
	var modulos_cargados := _modulos_para_conexiones()
	var pares_solape := ConexionesMapaScript.pares_solapados(modulos_cargados)
	var solapes := pares_solape.size()
	if solapes > 0:
		aviso += " · %d pares de salas superpuestas (en rojo)" % solapes
	var circulares_solapadas := 0
	for par in pares_solape:
		if modulos_cargados[par.x].circular or modulos_cargados[par.y].circular:
			circulares_solapadas += 1
	if circulares_solapadas > 0:
		aviso += " · las salas circulares superpuestas no se recortan en esta etapa"
	_cambio_mapa("")
	# _cambio_mapa guarda y deja "Guardado: ..." en la barra; el aviso va después.
	_estado.text = "Mapa cargado para editar: %s%s" % [ruta.get_file(), aviso]

func _jugar() -> void:
	_guardar_actual()
	get_tree().change_scene_to_file("res://pruebas/mapa_guardado.tscn")

func _indice_tipo(nombre: String) -> int:
	for i in _catalogo.size():
		if _catalogo[i].nombre == nombre:
			return i
	return -1

func _hay_solape_con_circular(rect: Rect2, ignorar: int, sala_nueva_circular: bool = false) -> bool:
	for i in _salas.size():
		if i == ignorar:
			continue
		var existente := _rect_sala(_salas[i])
		if not rect.intersects(existente, false):
			continue
		if sala_nueva_circular or _es_circular(_catalogo[_indice_tipo(_salas[i].tipo)]):
			return true
	return false

func _entrada_lienzo(evento: InputEvent) -> void:
	if evento is InputEventMouseMotion:
		if _paneo_activo:
			_desplazamiento_vista += evento.position - _ultima_posicion_paneo
			_ultima_posicion_paneo = evento.position
			_lienzo.queue_redraw()
		elif _arrastre >= 0:
			var deseado := (_punto_mapa(evento.position) - _desfase_arrastre).snapped(Vector2(0.5, 0.5))
			var tamano := _rect_sala(_salas[_arrastre]).size
			var p := deseado
			var tipo_arrastrado := String(_salas[_arrastre].tipo)
			var es_circular_arrastrada := _es_circular(_catalogo[_indice_tipo(tipo_arrastrado)])
			if _hay_solape_con_circular(Rect2(p, tamano), _arrastre, es_circular_arrastrada):
				_estado.text = "Las salas circulares no se pueden superponer en esta etapa."
			else:
				_salas[_arrastre].x = p.x
				_salas[_arrastre].z = p.y
			_lienzo.queue_redraw()
	elif evento is InputEventMouseButton:
		if evento.button_index == MOUSE_BUTTON_MIDDLE and evento.pressed:
			_paneo_activo = true
			_ultima_posicion_paneo = evento.position
		elif evento.button_index == MOUSE_BUTTON_MIDDLE and not evento.pressed:
			_paneo_activo = false
		elif evento.button_index == MOUSE_BUTTON_LEFT and not evento.pressed and _arrastre >= 0:
			_arrastre = -1
			_guardar_actual()
		elif evento.pressed and evento.button_index == MOUSE_BUTTON_WHEEL_UP:
			_escala = minf(60.0, _escala * 1.15)
		elif evento.pressed and evento.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_escala = maxf(8.0, _escala / 1.15)
		elif evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
			var punto_mapa := _punto_mapa(evento.position)
			var clave_solape := _segmento_solape_en(punto_mapa)
			if not clave_solape.is_empty():
				var plan_actual: Dictionary = PlanificadorSolapesScript.calcular(_modulos_para_conexiones(), _estados_solape)
				var actual := ConexionesMapaScript.ESTADO_CERRADA
				for tramo in plan_actual.segmentos:
					if tramo.clave == clave_solape:
						actual = String(tramo.estado)
				var nuevo := PlanificadorSolapesScript.siguiente_estado(actual)
				_estados_solape[clave_solape] = nuevo
				_cambio_mapa("Pared interior: %s." % nuevo)
				return
			var clave_conexion := _conexion_en(punto_mapa)
			if not clave_conexion.is_empty():
				_cambiar_conexion(clave_conexion, evento.shift_pressed)
				return
			_arrastre = _indice_sala_en(punto_mapa)
			if _arrastre >= 0:
				var r := _rect_sala(_salas[_arrastre])
				_desfase_arrastre = _punto_mapa(evento.position) - r.position
			else:
				_colocar(evento.position)
		elif evento.pressed and evento.button_index == MOUSE_BUTTON_RIGHT:
			_borrar(evento.position)
		_lienzo.queue_redraw()

## El lienzo no tiene foco de teclado, así que las teclas no llegan a su
## gui_input: se escuchan desde el nodo raíz.
func _unhandled_key_input(evento: InputEvent) -> void:
	var tecla := evento as InputEventKey
	if tecla != null and tecla.pressed and not tecla.echo and tecla.keycode == KEY_R:
		_girar()
		get_viewport().set_input_as_handled()

func _es_circular(definicion: SalaDef) -> bool:
	return definicion.escena != null and definicion.escena.resource_path.ends_with("sala_circular.tscn")

## Datos mínimos de cada sala para ConexionesMapa (el mismo cálculo que usa la escena jugable).
func _modulos_para_conexiones() -> Array[Dictionary]:
	var modulos: Array[Dictionary] = []
	for sala in _salas:
		modulos.append({"id": sala.id, "rect": _rect_sala(sala), "circular": _es_circular(_catalogo[_indice_tipo(sala.tipo)])})
	return modulos

func _colocar(posicion: Vector2) -> void:
	var definicion := _catalogo[_seleccion]
	var ancho := definicion.ancho_m if _giros % 2 == 0 else definicion.largo_m
	var largo := definicion.largo_m if _giros % 2 == 0 else definicion.ancho_m
	var deseado := (_punto_mapa(posicion) - Vector2(ancho, largo) * 0.5).snapped(Vector2(0.5, 0.5))
	var origen := deseado
	var rect := Rect2(origen, Vector2(ancho, largo))
	if _hay_solape_con_circular(rect, -1, _es_circular(definicion)):
		_estado.text = "Las salas circulares no se pueden superponer en esta etapa."
		return
	var id_nuevo := _siguiente_id
	_siguiente_id += 1
	_salas.append({"id": id_nuevo, "tipo": definicion.nombre, "x": origen.x, "z": origen.y, "giros": _giros})
	_cambio_mapa("Sala colocada en (%.1f, %.1f)." % [origen.x, origen.y])

func _rect_sala(sala: Dictionary) -> Rect2:
	var indice := _indice_tipo(sala.tipo)
	var definicion := _catalogo[indice]
	var ancho := definicion.ancho_m if int(sala.giros) % 2 == 0 else definicion.largo_m
	var largo := definicion.largo_m if int(sala.giros) % 2 == 0 else definicion.ancho_m
	return Rect2(Vector2(sala.x, sala.z), Vector2(ancho, largo))

## Clave de la conexión cuya marca está cerca de un punto del mapa ("" si no hay).
func _conexion_en(punto: Vector2) -> String:
	var cercana := ""
	var mejor := 0.7
	for conexion in ConexionesMapaScript.calcular(_modulos_para_conexiones(), _paredes_abiertas, _estados_conexion):
		var vertical: bool = conexion.dir_a == Direcciones.Dir.ESTE or conexion.dir_a == Direcciones.Dir.OESTE
		var mitad := maxf(conexion.ancho, 1.5) * 0.5
		var desvio := Vector2(0.0, mitad) if vertical else Vector2(mitad, 0.0)
		for lado in ["punto_a", "punto_b"]:
			var centro: Vector2 = conexion[lado]
			var cerca := Geometry2D.get_closest_point_to_segment(punto, centro - desvio, centro + desvio)
			var distancia := cerca.distance_to(punto)
			if distancia < mejor:
				mejor = distancia
				cercana = conexion.clave
	return cercana

	## Click recorre los estados; Mayús vuelve al modo automático.
func _cambiar_conexion(clave: String, restablecer: bool) -> void:
	var actual: Dictionary = {}
	for conexion in ConexionesMapaScript.calcular(_modulos_para_conexiones(), _paredes_abiertas, _estados_conexion):
		if conexion.clave == clave:
			actual = conexion
	if actual.is_empty():
		return
	if restablecer:
		_estados_conexion.erase(clave)
		_cambio_mapa("Conexión %s: vuelve al modo automático." % clave)
	else:
		var nuevo := ConexionesMapaScript.siguiente_estado(String(actual.estado))
		_estados_conexion[clave] = nuevo
		_cambio_mapa("Conexión %s: %s." % [clave, nuevo])

func _borrar(posicion: Vector2) -> void:
	var indice := _indice_sala_en(_punto_mapa(posicion))
	if indice >= 0:
		var id_borrado: int = _salas[indice].id
		_salas.remove_at(indice)
		for clave in _estados_conexion.keys():
			var partes := String(clave).split(":")
			if partes.size() == 2 and (int(partes[0]) == id_borrado or int(partes[1]) == id_borrado):
				_estados_conexion.erase(clave)
		for clave in _estados_solape.keys():
			if String(clave).begins_with("%d:" % id_borrado):
				_estados_solape.erase(clave)
		_cambio_mapa("Sala eliminada.")

func _punto_mapa(posicion: Vector2) -> Vector2:
	return (posicion - _lienzo.size * 0.5 - _desplazamiento_vista) / _escala

func _indice_sala_en(punto: Vector2) -> int:
	for i in range(_salas.size() - 1, -1, -1):
		if _rect_sala(_salas[i]).has_point(punto):
			return i
	return -1

func _cambio_mapa(mensaje: String) -> void:
	_guardar_actual()
	if not mensaje.is_empty():
		_estado.text = mensaje
	_lienzo.queue_redraw()

func _dibujar() -> void:
	if _lienzo == null:
		return
	_lienzo.draw_rect(Rect2(Vector2.ZERO, _lienzo.size), Color("20211f"))
	var paso := _escala * 5.0
	var centro := _lienzo.size * 0.5 + _desplazamiento_vista
	for x in range(0, ceili(_lienzo.size.x / paso) + 1):
		var px := fposmod(centro.x, paso) + x * paso
		_lienzo.draw_line(Vector2(px, 0), Vector2(px, _lienzo.size.y), Color(0.32, 0.32, 0.29), 1.0)
	for z in range(0, ceili(_lienzo.size.y / paso) + 1):
		var pz := fposmod(centro.y, paso) + z * paso
		_lienzo.draw_line(Vector2(0, pz), Vector2(_lienzo.size.x, pz), Color(0.32, 0.32, 0.29), 1.0)
	var modulos := _modulos_para_conexiones()
	var solapadas := {}
	for par in ConexionesMapaScript.pares_solapados(modulos):
		solapadas[par.x] = true
		solapadas[par.y] = true
	for i in _salas.size():
		var sala := _salas[i]
		var rect := _rect_sala(sala)
		var dibujado := Rect2(centro + rect.position * _escala, rect.size * _escala)
		var circular: bool = modulos[i].circular
		var color := Color(0.47, 0.42, 0.27) if not circular else Color(0.30, 0.43, 0.38)
		if solapadas.has(i):
			color = Color(0.62, 0.22, 0.20)
		_lienzo.draw_rect(dibujado, color)
		_lienzo.draw_rect(dibujado, Color(0.83, 0.79, 0.62), false, 2.0)
		var etiqueta: String = sala.tipo + (" (sin puertas por ahora)" if circular else "")
		_lienzo.draw_string(ThemeDB.fallback_font, dibujado.position + Vector2(5, 18), etiqueta, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	for conexion in ConexionesMapaScript.calcular(modulos, _paredes_abiertas, _estados_conexion):
		_dibujar_puerta(conexion, centro)
	var plan_solapes: Dictionary = PlanificadorSolapesScript.calcular(modulos, _estados_solape)
	for par in plan_solapes.pares:
		var area: Rect2 = par.rect
		_lienzo.draw_rect(Rect2(centro + area.position * _escala, area.size * _escala), Color(0.8, 0.2, 0.18, 0.18), true)
	for segmento in plan_solapes.segmentos:
		var color := Color(0.55, 1.0, 0.55)
		match String(segmento.estado):
			ConexionesMapaScript.ESTADO_ABIERTA:
				color = Color(0.55, 0.95, 1.0)
			ConexionesMapaScript.ESTADO_CERRADA:
				color = Color(1.0, 0.6, 0.2)
			ConexionesMapaScript.ESTADO_INTERSECCION:
				color = Color(0.85, 0.55, 1.0)
		_lienzo.draw_line(centro + segmento.inicio * _escala, centro + segmento.fin * _escala, color, 6.0)

func _segmento_solape_en(punto: Vector2) -> String:
	var plan: Dictionary = PlanificadorSolapesScript.calcular(_modulos_para_conexiones(), _estados_solape)
	var cercana := ""
	var mejor := 0.45
	for segmento in plan.segmentos:
		var distancia := Geometry2D.get_closest_point_to_segment(punto, segmento.inicio, segmento.fin).distance_to(punto)
		if distancia < mejor:
			mejor = distancia
			cercana = String(segmento.clave)
	return cercana

## Marca cada conexión: verde puerta, celeste pared abierta, naranja pared cerrada.
## Un punto blanco indica que el estado lo eligió el usuario.
func _dibujar_puerta(conexion: Dictionary, centro: Vector2) -> void:
	var vertical: bool = conexion.dir_a == Direcciones.Dir.ESTE or conexion.dir_a == Direcciones.Dir.OESTE
	var cerrada: bool = conexion.estado == ConexionesMapaScript.ESTADO_CERRADA
	var largo: float = conexion.largo if cerrada else conexion.ancho
	var mitad := (Vector2(0.0, largo) if vertical else Vector2(largo, 0.0)) * 0.5 * _escala
	var color := Color(0.55, 1.0, 0.55)
	if conexion.estado == ConexionesMapaScript.ESTADO_ABIERTA:
		color = Color(0.55, 0.95, 1.0)
	elif conexion.estado == ConexionesMapaScript.ESTADO_INTERSECCION:
		color = Color(0.85, 0.55, 1.0)
	elif cerrada:
		color = Color(1.0, 0.6, 0.2)
	for clave in ["punto_a", "punto_b"]:
		var punto: Vector2 = centro + conexion[clave] * _escala
		_lienzo.draw_line(punto - mitad, punto + mitad, color, 5.0)
		if conexion.manual:
			_lienzo.draw_circle(punto, 4.0, Color.WHITE)

## En el editor los sockets de catálogo no controlan las conexiones: se eligen
## sobre el mapa. Se conserva una pieza por geometría, altura y forma especial.
func _quitar_duplicados_catalogo(completo: Array[SalaDef]) -> Array[SalaDef]:
	var resultado: Array[SalaDef] = []
	var representantes := {}
	for definicion in completo:
		var firma := _firma_geometria(definicion)
		if representantes.has(firma):
			_alias_tipos[definicion.nombre] = String(representantes[firma])
		else:
			representantes[firma] = definicion.nombre
			resultado.append(definicion)
	return resultado

func _firma_geometria(definicion: SalaDef) -> String:
	var lado_a := minf(definicion.ancho_m, definicion.largo_m)
	var lado_b := maxf(definicion.ancho_m, definicion.largo_m)
	var circular := definicion.escena != null and definicion.escena.resource_path.ends_with("sala_circular.tscn")
	var columnas: Array[String] = []
	for posicion in definicion.columnas_locales:
		columnas.append("%.2f,%.2f,%.2f" % [posicion.x, posicion.y, posicion.z])
	columnas.sort()
	return "%.2f|%.2f|%.2f|%s|%s|%s" % [lado_a, lado_b, definicion.alto_m, circular, columnas.size(), ";".join(columnas)]
