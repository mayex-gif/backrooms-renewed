class_name SocketDef
extends Resource
## Una abertura de una sala por la que se puede conectar con otra.
## Es solo datos: dónde está, hacia dónde mira y qué ancho tiene.

## Centro del hueco, en metros, relativo al origen de la sala (a nivel del piso).
@export var posicion_local: Vector3 = Vector3.ZERO

## Hacia dónde mira el hueco, hacia AFUERA de la sala (antes de rotar la sala).
@export var direccion: Direcciones.Dir = Direcciones.Dir.NORTE
## Índice de arista en la huella poligonal; -1 mantiene la dirección cardinal.
@export var arista: int = -1
## Rotación local de la pared alrededor de Y para sockets sobre cualquier arista.
@export var rotacion_pared: float = -1.0
## Ángulo radial personalizado para una abertura sobre una pared circular. -1 usa la dirección cardinal.
@export var rotacion_radial: float = -1.0

## Ancho del hueco en metros (por ejemplo 1.0, 1.5, 2.5, 5.0, 7.5).
@export var ancho: float = 2.5
## Abre toda la pared para que dos módulos se lean como un único espacio.
@export var continuar_sala: bool = false
## Omite también el dintel y deja libre todo el tramo del piso al techo.
@export var sin_dintel: bool = false
## Altura máxima libre del hueco. Un valor negativo usa la altura estándar de puerta.
@export var altura_abertura_m: float = -1.0
