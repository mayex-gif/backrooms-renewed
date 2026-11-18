# Backrooms Renewed

Prototipo de exploración en primera persona hecho en Godot 4.7 (Forward+ y
Jolt Physics). Al iniciar, el menú permite elegir entre un plano diseñado a
mano, con espacios amplios y conexiones claras, y el generador procedural
aleatorio que ya existía.

El modo diseñado tiene un circuito circular, espacios de 15 a 20 metros,
una cámara de 8 m de altura, una sala de columnas y ramales pequeños. Sus
conexiones principales son amplias para que el recorrido se lea como zonas
continuas. El modo aleatorio conserva la semilla reproducible y amplía el mapa
por bloques.
La extensión aleatoria todavía reconstruye todas las salas y puede detener el
juego brevemente al cargar un bloque; ese problema está anotado en `PLAN.md`.
Los modos de varios pisos y las conexiones verticales aún son prototipos
separados, no parte de estos recorridos.

## Estado

- [x] Capa de datos para direcciones, sockets, definiciones de sala, grilla y colocación.
- [x] Catálogo de 24 variantes entre 5 × 5 y 15 × 20 m, más un vestíbulo de 20 × 15 m y una sala circular.
- [x] Plano curado de hasta 39 salas y menú para elegir el modo de juego.
- [x] Modo procedural con semilla y ampliación por bloques, disponible desde el menú.
- [x] Techos de placas, huecos y fluorescentes espaciados, apagados o intermitentes.
- [x] Jugador con movimiento, posturas, linterna y vuelo de desarrollo.
- [ ] Revisión manual de conexiones, alturas, controles y apariencia en Godot.
- [ ] Carga/descarga por distancia y corrección de las pausas al ampliar el modo aleatorio.
- [ ] Integrar niveles superpuestos, rampas, pozos y caídas en el plano jugable.

## Inicio y controles

Ejecutá el proyecto para abrir `pruebas/menu_principal.tscn`. Elegí **Plano
diseñado** o **Generación aleatoria**. También podés ejecutar escenas de prueba
individuales desde el editor de Godot.

- WASD o flechas: moverse.
- Mouse: mirar; Escape libera o captura el cursor; clic lo vuelve a capturar.
- Shift: caminar sigilosamente.
- Ctrl: correr.
- C: agacharse o levantarse.
- Z: arrastrarse o levantarse.
- F: prender o apagar la linterna.
- F3: activar o desactivar no-clip en una compilación de desarrollo; WASD y el
  mouse dirigen el vuelo, E sube y Q baja.
- F4: abrir el panel de desarrollo. Permite encender/apagar la iluminación y
  ajustar su intensidad. En el plano curado, la cantidad (hasta 39) extiende o
  acorta el recorrido y los pesos priorizan ramales grandes o abiertos; en el
  aleatorio cambian el máximo y los pesos del catálogo. Pulsá **Aplicar al mapa
  actual** para reconstruirlo y ver el cambio durante la partida. El jugador
  vuelve al inicio del mapa al aplicarlo. Mientras el panel está abierto, el
  cursor queda libre y el movimiento del jugador se detiene.

## Escenas de exploración y pruebas

- `pruebas/escenario_plano.tscn`: plano diseñado que se selecciona en el menú.
- `pruebas/escenario_generado.tscn`: generador aleatorio. Usa semilla aleatoria
  por defecto; asigná una semilla fija desde el Inspector para reproducirla.
  Empieza con 24 salas y amplía el límite en bloques de 12 al acercarse a los
  bordes. Para inspeccionar las coordenadas de cada sala, activá
  `imprimir_huella_completa` en el Inspector.
- `pruebas/escenario_sala.tscn`: habitación modular de muestra.
- `pruebas/escenario_abismo.tscn`: galería transitable junto a una caída y una
  plataforma lejana que se puede ver, pero no alcanzar.
- `pruebas/escenario_multinivel.tscn`: prototipo físico de escalera entre dos
  plantas; todavía no se integra a los niveles del menú.

## Comprobaciones de datos

1. Abrí el proyecto en Godot 4.7.
2. Ejecutá `pruebas/prueba_datos.gd` como EditorScript desde Archivo > Ejecutar.
3. Para semilla, solapamientos y conexiones, ejecutá también
   `pruebas/prueba_generador.gd` como EditorScript.

## Documentación

- [`CONTRIBUTING.md`](CONTRIBUTING.md): Git Flow y convención de trabajo.
- [`PLAN.md`](PLAN.md): hitos, estado actual y deuda de rendimiento.
- [`docs/DISENO.md`](docs/DISENO.md): decisiones de diseño y límites conocidos.
- [`docs/JUGADOR.md`](docs/JUGADOR.md): origen, análisis y controles del jugador.

El jugador se reconstruyó con referencia al último commit del proyecto
anterior. Sus modelos, animaciones, head bobbing y audios no se importaron:
dependían de recursos externos que no están en este repositorio.
