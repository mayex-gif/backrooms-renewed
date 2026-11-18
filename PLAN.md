# Plan de desarrollo

Plan incremental para Backrooms Renewed. Las casillas se marcan como listas
cuando el cambio está implementado; las que requieren revisión manual quedan
pendientes hasta recorrerlas en Godot.

## Hito 1 — Jugador y controles

- [x] Crear controlador en primera persona con movimiento WASD, gravedad y colisión.
- [x] Agregar correr con Ctrl, marcha sigilosa con Shift, agacharse con C y arrastrarse con Z.
- [x] Agregar linterna con F y captura/liberación del mouse con Escape.
- [x] Agregar vuelo sin colisión con F3 en compilaciones de desarrollo; E sube y Q baja.
- [ ] Revisar en Godot las transiciones de postura, la cámara, la linterna y el no-clip.
- [ ] Decidir y probar el comportamiento de salto.

## Hito 2 — Piezas de sala y techo

- [x] Separar datos de sala, sockets, huellas y colocación de los nodos visuales.
- [x] Construir paredes y aberturas transitables con colisiones a partir de sockets.
- [x] Cerrar las salidas que no se usan en una sala y cubrir la parte superior de puertas entre salas de distinta altura.
- [x] Ensanchar las aberturas principales y elevar dinteles; quitar marcos decorativos superpuestos que producían parpadeo visual.
- [x] Usar placas luminosas de tamaño casi completo de tile y espaciar las luminarias con un ritmo de tres tiles, con fallas y parpadeos.
- [x] Alinear la parte inferior de las barras con las placas y eliminar el hueco lateral entre ambas.
- [x] Aplicar techo modular también a la sala circular.
- [x] Mantener geometría sin tintes ni texturas mientras se corrigen formas y proporciones.
- [x] Ampliar el catálogo con una sala abierta de columnas.
- [ ] Recorrer el catálogo y comprobar visualmente puertas, colisiones, techos y materiales.

## Hito 3 — Dos formas de explorar

- [x] Crear un menú inicial que ofrece el plano diseñado o el generador aleatorio.
- [x] Ampliar el plano curado hasta 39 salas, con nuevas alas grandes al este y ramales conectados.
- [x] Ampliar el plano con una sala de columnas y una cámara de 8 m accesibles por el recorrido.
- [x] Abrir los pasos entre alas principales para que se perciban como zonas amplias conectadas.
- [ ] Diseñar precipicios jugables con bordes seguros y acceso claro a cada plataforma explorable.
- [ ] Diseñar el plenum del techo para mostrar cañerías y permitir acceso superior sin dejar huecos accidentales al exterior.
- [x] Añadir un panel F4: iluminación global y ajustes de cantidad/pesos para ambos modos.
- [x] Usar el conteo de salas para extender o acortar el plano curado; usar los pesos para priorizar ramales grandes y abiertos.
- [x] Reconstruir el mapa actual desde F4 y sellar las salidas de ramales omitidos.
- [x] Mantener `pruebas/escenario_generado.tscn` como modo de exploración procedural con semilla y ampliación por bloques.
- [x] Hacer opcional la impresión de la huella completa para que el log no crezca con cada ampliación.
- [ ] Recorrer ambos modos desde el menú, probar los ajustes F4 en ejecución y verificar que todas las conexiones coinciden en posición y altura.
- [ ] Verificar distintas semillas y el agotamiento de conexiones en el modo aleatorio.

## Hito 4 — Continuidad y rendimiento

- [x] Crear pruebas separadas de una escalera entre dos plantas y de una galería junto a una caída.
- [ ] Convertir las salas de altura variable y las conexiones verticales en parte del plano jugable.
- [ ] Continuar el modo diseñado con módulos de plano curados, manteniendo recorridos amplios y legibles.
- [ ] Descargar regiones lejanas y conservar datos para regenerarlas.
- [ ] Medir y corregir las pausas de carga con una escena reproducible.

**Problema de rendimiento registrado:** el log de la última ejecución muestra
ampliaciones de 24 a 36, 48, 60 y 72 salas. Cada ampliación reconstruye todas las
salas y produce una pausa cercana a un segundo. Se posterga la optimización por
ahora. El modo diseñado reconstruye como máximo 39 salas al aplicar cambios F4;
hay que comprobar si esa acción también genera una pausa perceptible.

## Hito 5 — Atmósfera y publicación

- [ ] Cerrar materiales, iluminación, niebla y sonido ambiental; la iluminación actual es editable desde F4.
- [ ] Revisar el zumbido de fluorescentes con pruebas auditivas y atenuación por distancia.
- [ ] Preparar build, video corto y publicación en itch.io.

## Criterios transversales

- Mantener la matemática de grilla/colocación separada de la construcción de escenas.
- Documentar decisiones, límites y problemas conocidos en `docs/`.
- Seguir el flujo Git Flow descrito en `CONTRIBUTING.md`.
