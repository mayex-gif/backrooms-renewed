# Backrooms Renewed

Nivel de Backrooms con generación procedural infinita, hecho en Godot 4.7
(Forward+, Jolt Physics). Proyecto de práctica y de portafolio: acotado,
documentado y pensado para terminarse.

## Estado

- [x] Capa de datos: direcciones, sockets, definiciones de sala, grilla y colocación.
- [ ] Generador (cola de puertas, elección por pesos, semilla).
- [ ] Salas y relleno de paredes.
- [x] Jugador de prueba: movimiento, correr, agacharse y colisión con el piso verificados manualmente.
- [ ] Carga y descarga por distancia.
- [ ] Iluminación, sonido y pulido visual.

## Cómo probar la capa de datos

1. Abrí el proyecto en Godot 4.7.
2. Abrí `pruebas/prueba_datos.gd` en el editor de scripts.
3. Ejecutalo con Archivo > Ejecutar (Ctrl+Mayús+X).
4. Mirá el panel "Salida": tiene que terminar en `=== TODO OK ===`.

## Documentación

- [`CONTRIBUTING.md`](CONTRIBUTING.md): flujo Git Flow y convención de trabajo.
- [`PLAN.md`](PLAN.md): hitos de desarrollo y estado actual.
- [`docs/DISENO.md`](docs/DISENO.md): decisiones de diseño y criterio de "terminado".
- [`docs/JUGADOR.md`](docs/JUGADOR.md): origen, análisis y controles del jugador de prueba.

## Prueba del jugador

La escena principal abre `pruebas/escenario_jugador.tscn`, un piso sencillo para revisar movimiento, cámara, colisión, agacharse y linterna. Controles: WASD o flechas, Shift para correr, C para agacharse, mouse para mirar y Escape para liberar/recapturar el cursor. Hacé clic para recapturarlo.

El controlador se reconstruyó tomando como referencia el último commit del jugador anterior. Sus modelos, animaciones y audios no se copiaron porque dependen de recursos externos ausentes en este proyecto.
