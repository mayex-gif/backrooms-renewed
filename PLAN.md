# Plan de desarrollo

Plan incremental para completar Backrooms Renewed. Los hitos se marcan como listos solo después de probarlos. Actualizar este archivo y el README al cerrar cada etapa.

## Hito 1 — Base y controles del jugador (en progreso)

- [x] Separar datos de la vista y documentar reglas de grilla/colocación.
- [x] Crear controlador de primera persona y escenario de piso.
- [x] Confirmar movimiento WASD, correr con Shift, agacharse con C y colisión con el piso (prueba manual reportada por el usuario).
- [ ] Comprobar rotación de cámara, captura del mouse, linterna y colisiones en movimiento.
- [ ] Bloquear el ponerse de pie cuando un techo impida ampliar la cápsula.
- [ ] Decidir y probar el comportamiento de salto; no está implementado todavía.

## Hito 2 — Salas modulares

- [ ] Definir una sala de prueba con huella y sockets validados.
- [ ] Crear geometría y colisión de sala con huecos de puerta.
- [ ] Implementar relleno para sockets de anchos distintos y verificar alineación entre datos y escena.

## Hito 3 — Generador determinista

- [ ] Diseñar cola de sockets pendientes y selección por peso/semilla.
- [ ] Rechazar huellas solapadas y colocaciones desalineadas antes de instanciar nodos.
- [ ] Probar generaciones repetibles con la misma semilla y manejo de callejones sin salida.

## Hito 4 — Integración y rendimiento

- [ ] Integrar al jugador en el mapa generado.
- [ ] Cargar y descargar salas por distancia, manteniendo datos suficientes para regenerarlas.
- [ ] Medir tirones y FPS con un escenario reproducible antes de optimizar.

## Hito 5 — Atmósfera y publicación

- [ ] Cerrar materiales, iluminación, niebla y sonido ambiental.
- [ ] Resolver el zumbido de fluorescentes con pruebas auditivas y controles de cantidad/distancia.
- [ ] Preparar build, video corto y publicación en itch.io.

## Criterios transversales

- Mantener lógica de generación independiente de los nodos de presentación.
- Añadir una prueba pequeña al completar cada sistema puro; documentar pruebas manuales de escena.
- Registrar decisiones, límites y riesgos conocidos en `docs/`.
