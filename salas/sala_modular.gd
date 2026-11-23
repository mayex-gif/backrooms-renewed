extends Node3D
## Construye paredes con huecos físicos a partir de las dimensiones y sockets.

@export var ancho_m := 5.0
@export var largo_m := 5.0
@export var alto_m := 4.2
@export var huella_local := PackedVector2Array()
@export var sockets: Array[SocketDef] = []
@export var semilla_ambiente := 1
@export var columnas: Array[Vector3] = []
@export var columnas_tamanos: Array[Vector2] = []
## Columnas colocadas desde el editor; no se ajustan a la retícula automática.
@export var columnas_adicionales: Array[Vector3] = []
@export var columnas_adicionales_tamanos: Array[Vector2] = []
@export var modos_luces_mapa: Dictionary = {}
@export var luces_manuales_mapa: Dictionary = {}
@export var luces_automaticas := true
## Zonas locales donde otra sala ya aporta la superficie de piso o techo.
@export var zonas_suelo_excluidas: Array = []
@export var zonas_techo_excluidas: Array = []

const LuminariaScript = preload("res://salas/luminaria.gd")
const MaterialesAmbiente = preload("res://salas/materiales_ambiente.gd")
const ServiciosTecho = preload("res://salas/servicios_techo.gd")
const RejillaTechoScript = preload("res://datos/rejilla_techo.gd")
const GROSOR_PLACA_TECHO := 0.12
const GROSOR_VIGA_TECHO := 0.06
const DESFASE_PLACA_TECHO := LuminariaScript.DESFASE_PLACA_TECHO
const INCLINACION_PLACA_SUELTA := 1.0
## Distancia vertical entre la parte superior de las paredes y la cara inferior del plenum.
const ALTURA_CAMARA_TECNICA := 1.9

func _ready() -> void:
	var huella := _huella()
	_crear_superficie_poligonal("Piso", huella, zonas_suelo_excluidas, -0.1, 0.2)
	_crear_techo_modular()
	_crear_columnas()
	for arista in huella.size():
		_crear_pared_con_huecos(arista, huella)
	_crear_faldon_plenum(huella)

func _crear_faldon_plenum(huella: PackedVector2Array) -> void:
	# Cierra la cámara sobre las placas y evita que se vea el exterior por el borde.
	for arista in huella.size():
		var inicio := huella[arista]
		var fin := huella[(arista + 1) % huella.size()]
		var eje := (fin - inicio).normalized()
		var largo := inicio.distance_to(fin)
		var aberturas: Array[Vector2] = []
		for socket in sockets:
			if not _socket_en_arista(socket, arista):
				continue
			var lateral := (Vector2(socket.posicion_local.x, socket.posicion_local.z) - inicio).dot(eje)
			aberturas.append(Vector2(
				clampf(lateral - socket.ancho * 0.5, 0.0, largo),
				clampf(lateral + socket.ancho * 0.5, 0.0, largo)
			))
		aberturas = _unir_intervalos(aberturas)
		var cursor := 0.0
		for abertura in aberturas:
			_crear_tramo_faldon(inicio, eje, cursor, abertura.x)
			cursor = abertura.y
		_crear_tramo_faldon(inicio, eje, cursor, largo)

func _crear_tramo_faldon(inicio: Vector2, eje: Vector2, desde: float, hasta: float) -> void:
	if hasta - desde < 0.2:
		return
	var punto := inicio + eje * ((desde + hasta) * 0.5)
	var cuerpo := _crear_caja(
		"FaldonPlenum",
		Vector3(hasta - desde + 0.02, ALTURA_CAMARA_TECNICA, 0.2),
		Vector3(punto.x, alto_m + ALTURA_CAMARA_TECNICA * 0.5, punto.y)
	)
	cuerpo.rotation.y = -atan2(eje.y, eje.x)

func _huella() -> PackedVector2Array:
	if huella_local.size() >= 3:
		return GeometriaHuella.normalizar(huella_local)
	return GeometriaHuella.rectangulo(ancho_m, largo_m)

func _socket_en_arista(socket: SocketDef, arista: int) -> bool:
	if socket.arista >= 0:
		return socket.arista == arista
	return socket.direccion == posmod(arista, 4)

func _crear_pared_con_huecos(arista: int, huella: PackedVector2Array) -> void:
	var inicio_arista := huella[arista]
	var fin_arista := huella[(arista + 1) % huella.size()]
	var eje := (fin_arista - inicio_arista).normalized()
	var largo_lado := inicio_arista.distance_to(fin_arista)
	var sockets_lado: Array[SocketDef] = []
	for socket in sockets:
		if _socket_en_arista(socket, arista):
			sockets_lado.append(socket)
	var huecos: Array[Vector2] = []
	var sin_dintel: Array[Vector2] = []
	for socket in sockets_lado:
		if socket.continuar_sala:
			huecos.append(Vector2(0.0, largo_lado))
			sin_dintel.append(Vector2(0.0, largo_lado))
			continue
		var lateral := (Vector2(socket.posicion_local.x, socket.posicion_local.z) - inicio_arista).dot(eje)
		var inicio := clampf(lateral - socket.ancho * 0.5, 0.0, largo_lado)
		var fin := clampf(lateral + socket.ancho * 0.5, 0.0, largo_lado)
		if fin <= inicio:
			continue
		huecos.append(Vector2(inicio, fin))
		if socket.sin_dintel or socket.continuar_sala:
			sin_dintel.append(Vector2(inicio, fin))
	huecos = _unir_intervalos(huecos)
	var cursor := 0.0
	for hueco in huecos:
		_crear_tramo_pared(inicio_arista, eje, cursor, hueco.x, "Pared", is_zero_approx(cursor), false)
		cursor = hueco.y
	_crear_tramo_pared(inicio_arista, eje, cursor, largo_lado, "Pared", is_zero_approx(cursor), true)
	for socket in sockets_lado:
		if socket.sin_dintel or socket.continuar_sala:
			continue
		var lateral := (Vector2(socket.posicion_local.x, socket.posicion_local.z) - inicio_arista).dot(eje)
		var inicio := clampf(lateral - socket.ancho * 0.5, 0.0, largo_lado)
		var fin := clampf(lateral + socket.ancho * 0.5, 0.0, largo_lado)
		for parte in _restar_intervalos(Vector2(inicio, fin), sin_dintel):
			var altura_abertura := socket.altura_abertura_m if socket.altura_abertura_m > 0.0 else 2.45
			_crear_dintel(inicio_arista, eje, (parte.x + parte.y) * 0.5, parte.y - parte.x, altura_abertura)

func _unir_intervalos(intervalos: Array[Vector2]) -> Array[Vector2]:
	intervalos.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var unidos: Array[Vector2] = []
	for intervalo in intervalos:
		if unidos.is_empty() or intervalo.x > unidos[-1].y + 0.001:
			unidos.append(intervalo)
		else:
			var anterior: Vector2 = unidos[-1]
			unidos[-1] = Vector2(anterior.x, maxf(anterior.y, intervalo.y))
	return unidos

func _restar_intervalos(base: Vector2, cortes: Array[Vector2]) -> Array[Vector2]:
	var partes: Array[Vector2] = [base]
	for corte in _unir_intervalos(cortes):
		var nuevas: Array[Vector2] = []
		for parte in partes:
			if corte.y <= parte.x or corte.x >= parte.y:
				nuevas.append(parte)
			else:
				if corte.x > parte.x:
					nuevas.append(Vector2(parte.x, minf(corte.x, parte.y)))
				if corte.y < parte.y:
					nuevas.append(Vector2(maxf(corte.y, parte.x), parte.y))
		partes = nuevas
	return partes

func _crear_tramo_pared(inicio_arista: Vector2, eje: Vector2, desde: float, hasta: float, nombre: String, extender_inicio: bool = false, extender_fin: bool = false) -> void:
	if hasta - desde <= 0.01:
		return
	var extension_inicio := 0.1 if extender_inicio else 0.0
	var extension_fin := 0.1 if extender_fin else 0.0
	var punto := inicio_arista + eje * ((desde - extension_inicio + hasta + extension_fin) * 0.5)
	var cuerpo := _crear_caja(nombre, Vector3(hasta - desde + extension_inicio + extension_fin, alto_m, 0.2), Vector3(punto.x, alto_m * 0.5, punto.y))
	cuerpo.rotation.y = -atan2(eje.y, eje.x)

func _crear_dintel(inicio_arista: Vector2, eje: Vector2, centro: float, ancho: float, altura_abertura: float = 2.45) -> void:
	var altura_puerta := minf(altura_abertura, alto_m)
	if alto_m <= altura_puerta:
		return
	var tamano := Vector3(ancho, alto_m - altura_puerta, 0.2)
	var punto := inicio_arista + eje * centro
	var cuerpo := _crear_caja("Dintel", tamano, Vector3(punto.x, (alto_m + altura_puerta) * 0.5, punto.y))
	cuerpo.rotation.y = -atan2(eje.y, eje.x)

func _crear_caja(nombre: String, tamano: Vector3, posicion: Vector3, da_sombra: bool = true) -> StaticBody3D:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = nombre
	cuerpo.position = posicion
	var forma := BoxShape3D.new()
	forma.size = tamano
	var colision := CollisionShape3D.new()
	colision.shape = forma
	cuerpo.add_child(colision)
	var malla := BoxMesh.new()
	malla.size = tamano
	var visual := MeshInstance3D.new()
	visual.mesh = malla
	var tipo_material := MaterialesAmbiente.PLENUM if nombre == "FaldonPlenum" else MaterialesAmbiente.PARED
	MaterialesAmbiente.aplicar(visual, tipo_material)
	if not da_sombra:
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cuerpo.add_child(visual)
	add_child(cuerpo)
	return cuerpo

func _crear_superficie_poligonal(nombre: String, base: PackedVector2Array, exclusiones: Array, y: float, alto: float) -> void:
	for pieza in GeometriaHuella.diferencia_por_poligonos(base, exclusiones):
		if absf(GeometriaHuella.area_firmada(pieza)) > 0.01:
			_crear_prisma_poligonal(nombre, pieza, y, alto, true, false)

## Malla de un prisma vertical. Con "celda" lleva UV (0..1 sobre ese rectángulo, visto
## desde abajo) y tangentes; así las placas completas y las recortadas se ven idénticas.
func _construir_malla_prisma(poligono: PackedVector2Array, alto: float, celda: Rect2 = Rect2()) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normales := PackedVector3Array()
	var indices := Geometry2D.triangulate_polygon(poligono)
	for indice in range(0, indices.size(), 3):
		var a: Vector2 = poligono[indices[indice]]
		var b: Vector2 = poligono[indices[indice + 1]]
		var c: Vector2 = poligono[indices[indice + 2]]
		# Godot descarta las caras que no estén en sentido horario. Al proyectar
		# desde arriba, un triángulo X/Z con cruz positiva queda horario.
		if _cruz2d(b - a, c - a) < 0.0:
			var temporal := b
			b = c
			c = temporal
		_agregar_triangulo(vertices, normales, Vector3(a.x, alto * 0.5, a.y), Vector3(b.x, alto * 0.5, b.y), Vector3(c.x, alto * 0.5, c.y), Vector3.UP)
		_agregar_triangulo(vertices, normales, Vector3(a.x, -alto * 0.5, a.y), Vector3(c.x, -alto * 0.5, c.y), Vector3(b.x, -alto * 0.5, b.y), Vector3.DOWN)
	for indice in poligono.size():
		var a := poligono[indice]
		var b := poligono[(indice + 1) % poligono.size()]
		var arista := b - a
		var normal := Vector3(arista.y, 0, -arista.x).normalized()
		var a_abajo := Vector3(a.x, -alto * 0.5, a.y)
		var b_abajo := Vector3(b.x, -alto * 0.5, b.y)
		var a_arriba := Vector3(a.x, alto * 0.5, a.y)
		var b_arriba := Vector3(b.x, alto * 0.5, b.y)
		_agregar_triangulo(vertices, normales, a_abajo, b_abajo, b_arriba, normal)
		_agregar_triangulo(vertices, normales, a_abajo, b_arriba, a_arriba, normal)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normales
	if celda.size.x > 0.0 and celda.size.y > 0.0:
		var uvs := PackedVector2Array()
		for indice_v in vertices.size():
			var v := vertices[indice_v]
			# Los cantos (caras laterales) usan un punto fijo: sin rayas estiradas.
			if absf(normales[indice_v].y) < 0.5:
				uvs.append(Vector2(0.5, 0.5))
			else:
				uvs.append(Vector2((v.x - celda.position.x) / celda.size.x, (v.z - celda.position.y) / celda.size.y))
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		# Tangentes (hacen falta para el mapa de normales de las placas).
		var tangentes := PackedFloat32Array()
		for n in normales:
			if n.y > 0.5:
				tangentes.append_array([1.0, 0.0, 0.0, -1.0])
			elif n.y < -0.5:
				tangentes.append_array([1.0, 0.0, 0.0, 1.0])
			else:
				tangentes.append_array([n.z, 0.0, -n.x, 1.0])
		arrays[Mesh.ARRAY_TANGENT] = tangentes
	var malla := ArrayMesh.new()
	malla.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return malla


## "celda" (opcional): rectángulo de la placa a la que pertenece la pieza. Con él se
## calculan UV para que la textura de placa quede en su posición, como en las completas.
func _crear_prisma_poligonal(nombre: String, poligono: PackedVector2Array, centro_y: float, alto: float, colision: bool, sombra: bool, celda: Rect2 = Rect2(), semilla_material: int = 0) -> void:
	if poligono.size() < 3:
		return
	var contenedor: Node3D
	if colision:
		var cuerpo := StaticBody3D.new()
		cuerpo.name = nombre
		cuerpo.position.y = centro_y
		var forma := ConvexPolygonShape3D.new()
		var puntos_3d := PackedVector3Array()
		for punto in poligono:
			puntos_3d.append(Vector3(punto.x, -alto * 0.5, punto.y))
		for punto in poligono:
			puntos_3d.append(Vector3(punto.x, alto * 0.5, punto.y))
		forma.points = puntos_3d
		var colision_fisica := CollisionShape3D.new()
		colision_fisica.shape = forma
		cuerpo.add_child(colision_fisica)
		add_child(cuerpo)
		contenedor = cuerpo
	else:
		contenedor = Node3D.new()
		contenedor.name = nombre
		contenedor.position.y = centro_y
		add_child(contenedor)
	var malla := _construir_malla_prisma(poligono, alto, celda)
	var visual := MeshInstance3D.new()
	visual.mesh = malla
	MaterialesAmbiente.aplicar(visual, _tipo_material_superficie(nombre), semilla_material)
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if sombra else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	contenedor.add_child(visual)

func _tipo_material_superficie(nombre: String) -> String:
	match nombre:
		"Piso":
			return MaterialesAmbiente.PISO
		"TileTecho":
			return MaterialesAmbiente.PLACA_RECORTADA
		"Plenum superior":
			return MaterialesAmbiente.PLENUM
		"ReticulaTecho":
			return MaterialesAmbiente.YESO
		_:
			return MaterialesAmbiente.YESO

func _agregar_triangulo(vertices: PackedVector3Array, normales: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, normal: Vector3) -> void:
	vertices.append(a)
	vertices.append(b)
	vertices.append(c)
	normales.append(normal)
	normales.append(normal)
	normales.append(normal)

func _cruz2d(a: Vector2, b: Vector2) -> float:
	return a.x * b.y - a.y * b.x

func _crear_columnas() -> void:
	var usadas: Array[Vector3] = []
	var tamanos_usados: Array[Vector2] = []
	for indice in columnas.size():
		var columna := StaticBody3D.new()
		columna.name = "Columna_%02d" % indice
		var base := Vector2(columnas[indice].x, columnas[indice].z)
		var huella_columna := Vector2(1.3, 1.3)
		if indice < columnas_tamanos.size():
			huella_columna = columnas_tamanos[indice]
		huella_columna.x = clampf(huella_columna.x, 0.2, ancho_m)
		huella_columna.y = clampf(huella_columna.y, 0.2, largo_m)
		var posicion_xz := _buscar_posicion_columna_sin_luz(base, usadas, tamanos_usados, huella_columna)
		usadas.append(Vector3(posicion_xz.x, 0, posicion_xz.y))
		tamanos_usados.append(huella_columna)
		columna.position = Vector3(posicion_xz.x, alto_m * 0.5, posicion_xz.y)
		var tamano := Vector3(huella_columna.x, alto_m, huella_columna.y)
		var colision := CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = tamano
		colision.shape = forma
		columna.add_child(colision)
		var visual := MeshInstance3D.new()
		var malla := BoxMesh.new()
		malla.size = tamano
		visual.mesh = malla
		MaterialesAmbiente.aplicar(visual, MaterialesAmbiente.YESO)
		columna.add_child(visual)
		add_child(columna)
	for indice in columnas_adicionales.size():
		var posicion := columnas_adicionales[indice]
		var tamano := Vector2(0.5, 0.5) if indice >= columnas_adicionales_tamanos.size() else columnas_adicionales_tamanos[indice]
		_crear_columna_fija("ColumnaEditor_%02d" % indice, Vector2(posicion.x, posicion.z), tamano)

func _crear_columna_fija(nombre: String, base: Vector2, huella_columna: Vector2) -> void:
	var columna := StaticBody3D.new()
	columna.name = nombre
	columna.position = Vector3(base.x, alto_m * 0.5, base.y)
	var tamano := Vector3(huella_columna.x, alto_m, huella_columna.y)
	var forma := BoxShape3D.new()
	forma.size = tamano
	var colision := CollisionShape3D.new()
	colision.shape = forma
	columna.add_child(colision)
	var visual := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = tamano
	visual.mesh = malla
	MaterialesAmbiente.aplicar(visual, MaterialesAmbiente.YESO)
	columna.add_child(visual)
	add_child(columna)

func _buscar_posicion_columna_sin_luz(base: Vector2, usadas: Array[Vector3], tamanos_usados: Array[Vector2], tamano_columna: Vector2) -> Vector2:
	var tam_tile: float = RejillaTechoScript.TAMANO
	var limites_grilla := GeometriaHuella.limites(_huella())
	var rejilla := RejillaTechoScript.calcular(limites_grilla, Vector2(global_position.x, global_position.z), Vector2(global_basis.x.x, global_basis.x.z), Vector2(global_basis.z.x, global_basis.z.z))
	var cantidad_x: int = rejilla.columnas
	var cantidad_z: int = rejilla.filas
	var origen_grilla: Vector2 = rejilla.origen
	var mejor := base
	var mejor_distancia := INF
	for x in cantidad_x:
		for z in cantidad_z:
			var candidata := origen_grilla + Vector2((x + 0.5) * tam_tile, (z + 0.5) * tam_tile)
			var mundo_candidata := to_global(Vector3(candidata.x, 0.0, candidata.y))
			var es_posicion_luz := posmod(RejillaTechoScript.indice_mundo(mundo_candidata.x) - 1, 3) == 0 and posmod(RejillaTechoScript.indice_mundo(mundo_candidata.z) - 1, 3) == 0
			if es_posicion_luz:
				continue
			if candidata.x < tamano_columna.x * 0.5 or candidata.y < tamano_columna.y * 0.5:
				continue
			if candidata.x > ancho_m - tamano_columna.x * 0.5 or candidata.y > largo_m - tamano_columna.y * 0.5:
				continue
			var dentro_huella := true
			for esquina in [Vector2(-tamano_columna.x, -tamano_columna.y) * 0.5, Vector2(tamano_columna.x, -tamano_columna.y) * 0.5, Vector2(tamano_columna.x, tamano_columna.y) * 0.5, Vector2(-tamano_columna.x, tamano_columna.y) * 0.5]:
				if not GeometriaHuella.contiene(_huella(), candidata + esquina):
					dentro_huella = false
					break
			if not dentro_huella:
				continue
			if _cerca_de_puerta(candidata, maxf(tamano_columna.x, tamano_columna.y) * 0.5):
				continue
			var ocupada := false
			for indice_usada in usadas.size():
				var usada := Vector2(usadas[indice_usada].x, usadas[indice_usada].z)
				var radio_columna := maxf(tamano_columna.x, tamano_columna.y) * 0.5
				var radio_usada := maxf(tamanos_usados[indice_usada].x, tamanos_usados[indice_usada].y) * 0.5
				if candidata.distance_to(usada) < radio_columna + radio_usada + 0.35:
					ocupada = true
					break
			if ocupada:
				continue
			var distancia := candidata.distance_squared_to(base)
			if distancia < mejor_distancia:
				mejor = candidata
				mejor_distancia = distancia
	return mejor

func _cerca_de_puerta(punto: Vector2, radio_columna: float = 0.65) -> bool:
	for socket in sockets:
		var margen := socket.ancho * 0.5 + radio_columna
		var huella := _huella()
		for arista in huella.size():
			if not _socket_en_arista(socket, arista):
				continue
			var inicio := huella[arista]
			var fin := huella[(arista + 1) % huella.size()]
			var eje := (fin - inicio).normalized()
			var posicion_socket := Vector2(socket.posicion_local.x, socket.posicion_local.z)
			var centro_lateral := (posicion_socket - inicio).dot(eje)
			var lateral := (punto - inicio).dot(eje)
			if Geometry2D.get_closest_point_to_segment(punto, inicio, fin).distance_to(punto) < 1.5 and absf(lateral - centro_lateral) < margen:
				return true
	return false

func _crear_techo_modular() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla_ambiente
	var tam_tile: float = RejillaTechoScript.TAMANO
	var limites := GeometriaHuella.limites(_huella())
	var rejilla := RejillaTechoScript.calcular(limites, Vector2(global_position.x, global_position.z), Vector2(global_basis.x.x, global_basis.x.z), Vector2(global_basis.z.x, global_basis.z.z))
	var columnas_tiles: int = rejilla.columnas
	var filas_tiles: int = rejilla.filas
	var origen_x: float = rejilla.origen.x
	var origen_z: float = rejilla.origen.y
	# Tapa estructural sobre una cámara técnica de 1,9 m de altura libre.
	_crear_superficie_poligonal("Plenum superior", _huella(), zonas_techo_excluidas, alto_m + ALTURA_CAMARA_TECNICA + 0.1, 0.2)
	ServiciosTecho.crear(self, _huella(), alto_m, zonas_techo_excluidas)
	for x in range(columnas_tiles + 1):
		var px := origen_x + x * tam_tile
		_crear_viga_techo(GeometriaHuella.rectangulo(0.07, limites.size.y, Vector2(px, limites.get_center().y)), alto_m + LuminariaScript.PLANO_ENCASTRE_Y + GROSOR_VIGA_TECHO * 0.5)
	for z in range(filas_tiles + 1):
		var pz := origen_z + z * tam_tile
		_crear_viga_techo(GeometriaHuella.rectangulo(limites.size.x, 0.07, Vector2(limites.get_center().x, pz)), alto_m + LuminariaScript.PLANO_ENCASTRE_Y + GROSOR_VIGA_TECHO * 0.5)
	var luces_operativas := 0
	for x in columnas_tiles:
		for z in filas_tiles:
			var x0 := origen_x + x * tam_tile
			var z0 := origen_z + z * tam_tile
			var ancho_tile := tam_tile
			var largo_tile := tam_tile
			var rect_tile := GeometriaHuella.rectangulo(ancho_tile, largo_tile, Vector2(x0 + ancho_tile * 0.5, z0 + largo_tile * 0.5))
			var centro := Vector3(x0 + ancho_tile * 0.5, alto_m + LuminariaScript.PLANO_ENCASTRE_Y + GROSOR_PLACA_TECHO * 0.5, z0 + largo_tile * 0.5)
			var valor := rng.randf()
			var piezas := GeometriaHuella.intersecciones(rect_tile, _huella())
			piezas = GeometriaHuella.restar_a_poligonos(piezas, zonas_techo_excluidas)
			piezas = _sin_astillas(piezas)
			# Las luces siguen un ritmo de paneles de oficina, con variaciones por sala.
			# Esto evita el patrón de puntos aleatorios demasiado denso.
			var posicion_global_luz := to_global(Vector3(centro.x, alto_m, centro.z))
			# Las luces siguen la rejilla del mundo (una de cada 3 placas), igual en todas las salas.
			var es_posicion_luz := posmod(RejillaTechoScript.indice_mundo(posicion_global_luz.x) - 1, 3) == 0 and posmod(RejillaTechoScript.indice_mundo(posicion_global_luz.z) - 1, 3) == 0
			var id_luz := "X %.2f · Z %.2f" % [posicion_global_luz.x, posicion_global_luz.z]
			var modo_forzado := int(modos_luces_mapa.get(id_luz, -999))
			var es_luz_manual := luces_manuales_mapa.has(id_luz)
			if es_luz_manual and modo_forzado == 5:
				continue # Placa faltante: la fija el editor, nada es aleatorio.
			var area_tile_conservada := 0.0
			for pieza in piezas:
				area_tile_conservada += absf(GeometriaHuella.area_firmada(pieza))
			var tile_completo := absf(area_tile_conservada - ancho_tile * largo_tile) <= 0.01
			var tile_rectangular_completo := (
				absf(area_tile_conservada - ancho_tile * largo_tile) <= 0.001
				and piezas.size() == 1
				and is_equal_approx(ancho_tile, tam_tile)
				and is_equal_approx(largo_tile, tam_tile)
			)
			var pieza_rectangular := false
			var centro_visual := Vector2(centro.x, centro.z)
			var ancho_visual := ancho_tile
			var largo_visual := largo_tile
			if piezas.size() == 1:
				var limites_pieza := GeometriaHuella.limites(piezas[0])
				var area_pieza := absf(GeometriaHuella.area_firmada(piezas[0]))
				pieza_rectangular = absf(area_pieza - limites_pieza.size.x * limites_pieza.size.y) <= 0.01
				if pieza_rectangular:
					centro_visual = limites_pieza.get_center()
					ancho_visual = limites_pieza.size.x
					largo_visual = limites_pieza.size.y
			var es_modo_luz := modo_forzado >= 0 and modo_forzado <= 2
			var crear_luminaria := ((es_luz_manual and es_modo_luz) or (luces_automaticas and not es_luz_manual and modo_forzado != -1 and es_posicion_luz)) and pieza_rectangular and (tile_completo or (es_luz_manual and es_modo_luz))
			if crear_luminaria:
				var centro_panel := Vector3(centro_visual.x, alto_m + LuminariaScript.PLANO_ENCASTRE_Y + GROSOR_PLACA_TECHO * 0.5, centro_visual.y)
				_crear_tile(centro_panel, ancho_visual, largo_visual, 0.0, 0.0, false)
				var modo_inicial_forzado := modo_forzado if modo_forzado >= 0 else -1
				var funciona := LuminariaScript.crear(self, Vector3(centro_visual.x, alto_m + LuminariaScript.DESFASE_CENTRO_PANEL_Y, centro_visual.y), ancho_visual - LuminariaScript.MARGEN_PLACA_RETICULA, largo_visual - LuminariaScript.MARGEN_PLACA_RETICULA, alto_m, rng, modo_inicial_forzado)
				var luminaria_creada := get_child(get_child_count() - 1)
				luminaria_creada.set_meta("id_editor", id_luz)
				if funciona:
					luces_operativas += 1
			elif es_luz_manual and modo_forzado == 3 and tile_rectangular_completo:
				_crear_tile_rota(centro, ancho_tile, largo_tile, rng)
			elif es_luz_manual and modo_forzado == 4 and tile_rectangular_completo:
				_crear_tile(centro, ancho_tile, largo_tile, GROSOR_PLACA_TECHO + 0.03, rng.randf_range(-2.0, 2.0), true, rng.randf_range(9.0, 17.0) * (1.0 if rng.randf() < 0.5 else -1.0))
			elif tile_rectangular_completo:
				_crear_tile(centro, ancho_tile, largo_tile, DESFASE_PLACA_TECHO)
			else:
				# Cada pieza se separa de las vecinas con el mismo margen que las placas
				# completas y lleva UV de su placa, para que no se vea todo unido.
				var margen := LuminariaScript.MARGEN_PLACA_RETICULA
				var celda := Rect2(x0 + margen * 0.5, z0 + margen * 0.5, ancho_tile - margen, largo_tile - margen)
				var recorte := GeometriaHuella.rectangulo(ancho_tile - LuminariaScript.MARGEN_PLACA_RETICULA, largo_tile - LuminariaScript.MARGEN_PLACA_RETICULA, Vector2(x0 + ancho_tile * 0.5, z0 + largo_tile * 0.5))
				var semilla_placa := hash(Vector2i(roundi(centro.x * 10.0), roundi(centro.z * 10.0)))
				for pieza in piezas:
					for parte in _sin_astillas(GeometriaHuella.intersecciones(recorte, pieza)):
						_crear_prisma_poligonal("TileTecho", parte, alto_m + LuminariaScript.PLANO_ENCASTRE_Y + GROSOR_PLACA_TECHO * 0.5 + DESFASE_PLACA_TECHO, GROSOR_PLACA_TECHO, true, false, celda, semilla_placa)

	LuminariaScript.crear_relleno(self, limites.get_center(), limites.size.length() * 0.5, alto_m, luces_operativas)

## Placa rota: queda una mitad colgando torcida de un borde y el resto del hueco vacío.
func _crear_tile_rota(centro: Vector3, ancho: float, largo: float, rng: RandomNumberGenerator) -> void:
	var mitad := largo * 0.5
	var lado := -1.0 if rng.randf() < 0.5 else 1.0
	var origen := Vector3(centro.x, centro.y, centro.z + lado * (largo * 0.5 - mitad * 0.5))
	_crear_tile(origen + Vector3(0, -0.10, 0), ancho, mitad, 0.0, rng.randf_range(-6.0, 6.0), true, 0.0, rng.randf_range(14.0, 24.0) * -lado)


func _crear_tile(centro: Vector3, ancho: float, largo: float, elevacion: float = 0.0, inclinacion: float = 0.0, mostrar_malla: bool = true, giro_y: float = 0.0, cabeceo: float = 0.0) -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "TileTecho"
	cuerpo.position = centro + Vector3(0, elevacion, 0)
	cuerpo.rotation_degrees = Vector3(cabeceo, giro_y, inclinacion)
	var tamano := Vector3(ancho - LuminariaScript.MARGEN_PLACA_RETICULA, GROSOR_PLACA_TECHO, largo - LuminariaScript.MARGEN_PLACA_RETICULA)
	var forma := BoxShape3D.new()
	forma.size = tamano
	var colision := CollisionShape3D.new()
	colision.shape = forma
	cuerpo.add_child(colision)
	if mostrar_malla:
		var visual := MeshInstance3D.new()
		var mitad_x := tamano.x * 0.5
		var mitad_z := tamano.z * 0.5
		# Con centro explícito: sin él, rectangulo() arranca en (0, 0) y la placa quedaría corrida.
		var base := GeometriaHuella.rectangulo(tamano.x, tamano.z, Vector2.ZERO)
		visual.mesh = _construir_malla_prisma(base, tamano.y, Rect2(-mitad_x, -mitad_z, tamano.x, tamano.z))
		MaterialesAmbiente.aplicar(visual, MaterialesAmbiente.PLACA_TECHO, hash(Vector2i(roundi(centro.x * 10.0), roundi(centro.z * 10.0))))
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cuerpo.add_child(visual)
	add_child(cuerpo)

func _crear_viga_techo(base: PackedVector2Array, y: float) -> void:
	var piezas := GeometriaHuella.intersecciones(base, _huella())
	piezas = _sin_astillas(GeometriaHuella.restar_a_poligonos(piezas, zonas_techo_excluidas))
	for pieza in piezas:
		_crear_prisma_poligonal("ReticulaTecho", pieza, y, GROSOR_VIGA_TECHO, false, false)

## Descarta fragmentos mínimos producidos al recortar huellas y vigas.
func _sin_astillas(piezas: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var utiles: Array[PackedVector2Array] = []
	for pieza in piezas:
		if absf(GeometriaHuella.area_firmada(pieza)) > 0.01:
			utiles.append(pieza)
	return utiles
