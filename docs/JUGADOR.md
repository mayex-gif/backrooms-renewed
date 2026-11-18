# Jugador de prueba

## Origen

La referencia es el commit `afb5cd2` ("Personaje creado y falta arreglar las
animaciones") del repositorio anterior, rama `main`, en particular
`jugador/jugador.gd` y `jugador/jugador.tscn`. Ese controlador usaba
`CharacterBody3D`, movimiento relativo a la orientación, gravedad, cámara en
primera persona, agachado, carrera, head bobbing y pasos sincronizados con el
bob.

## Qué se reutilizó y qué se dejó fuera

Se conserva el enfoque de `CharacterBody3D`, cámara hija que rota en pitch,
movimiento WASD relativo al jugador, mouse capturado con Escape y cambios de
altura de colisión para agacharse. El controlador se reconstruyó como un script
pequeño. No se importaron modelos, animaciones ni sonidos: dependían de recursos
externos que no existen en este proyecto. El head bobbing y los pasos quedan
fuera hasta validar el movimiento básico.

## Controles

El jugador aparece en `pruebas/escenario_plano.tscn` o
`pruebas/escenario_generado.tscn`, elegibles desde el menú principal.

- WASD o flechas: moverse.
- Mouse: mirar.
- Shift: caminar sigilosamente.
- Ctrl: correr.
- C: agacharse o levantarse.
- Z: arrastrarse o levantarse. La cápsula baja a 0,65 m y la cámara queda cerca
  del suelo.
- F: alternar la linterna.
- Escape: liberar o volver a capturar el cursor; un clic también lo captura.
- F3: alternar no-clip solo en builds de desarrollo. WASD y mouse dirigen el
  vuelo; E sube y Q baja. La gravedad y las colisiones se suspenden mientras
  está activo.

La altura de la cápsula al estar de pie es 1,8 m; antes de levantarse desde
agachado o arrastrado, el controlador comprueba si hay espacio libre.

## Estado de validación

El usuario comprobó anteriormente WASD, agacharse con C, correr con Shift en
esa sesión inicial y colisión con el piso. La distribución actual usa Shift
para caminar sigilosamente y Ctrl para correr. Falta revisar en el juego las
transiciones de postura, la linterna, los marcos de puerta y el no-clip.

## Diferencias y problemas conocidos del prototipo viejo

- Velocidades del último commit: caminar 6, correr 10 y agachado 0,75. Eran
  altas para el ritmo buscado; la versión nueva usa velocidades más moderadas y
  ajustables en el Inspector.
- El freno antiguo variaba con la tasa de física. La versión nueva lo escala
  por `delta`.
- El jugador anterior componía animaciones y pasos con el head bobbing; el
  commit reporta animaciones por arreglar. Se dejaron esos sistemas fuera.
