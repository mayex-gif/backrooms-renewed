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

### Plan de rendimiento y variedad geométrica

- [x] Cambiar la ocupación del generador de celdas de 0,5 m a rectángulos AABB en metros, rotados en pasos de 90° y comparados con tolerancia de 1 mm.
- [x] Usar el cuadrado envolvente para la sala circular y validar los sockets con ancho/largo reales, sin construir huellas de celdas.
- [ ] Comprobar con semillas repetibles las conexiones entre salas cuyos centros de puerta caen en posiciones de 1,25/3,75 m y revisar si cambia el agotamiento.
- [x] Aumentar para prueba el paso y el tamaño de tiles, luminarias y vigas del techo; inspeccionar en Godot si se ve proporcionado.
- [x] Retirar los marcos decorativos: se solapaban en intersecciones y conexiones cercanas.
- [x] Agrandar las columnas y desplazar cada una al tile sin luminaria más cercano, evitando que se amontonen entre sí.
- [x] Crear algunas conexiones de pared completamente abiertas para que salas contiguas se lean como un único espacio; seleccionar de forma reproducible, coordinar ambos lados y cerrar con un panel la franja superior cuando las alturas difieran.
- [x] Dimensionar los rellenos laterales hasta la altura real de la abertura y cerrar diferencias de altura entre puertas en el lado de la abertura más alta.
- [x] Limitar las aperturas completas a paredes únicas, centradas y de igual longitud para que no queden extremos descubiertos.
- [x] Desplazar de forma determinista los sockets centrados del catálogo, respetando el ancho de abertura y el margen del borde.
- [x] Mantener conexiones entre sockets de distinto ancho y dimensionar los rellenos según la abertura mayor; el generador no exige anchos idénticos.
- [x] Alejar luminarias del perímetro de las salas y reducir su alcance e intensidad base.
- [x] Hacer que el parpadeo apague y encienda tanto la luz como la emisión visible del panel.
- [x] Aumentar duración y frecuencia visible de los ciclos de apagado/encendido para identificar los fluorescentes intermitentes.
- [x] Bajar el plenum del techo para que se solape con las placas y no deje una ranura visible, también en salas bajas.
- [x] Añadir pasillos estrechos y galerías grandes con varias salidas, compatibles con conexiones de ancho distinto y aperturas amplias.
- [ ] Rehacer la ocupación y colocación de la sala circular para permitir conexiones laterales tangentes a su perímetro y completar el piso expuesto sin conservar una caja cuadrada.
- [ ] Revisar visualmente colisiones y aperturas, incluida la variante circular y salas con múltiples puertas cercanas.
- [ ] Medir por separado el tiempo de generación matemática y el de instanciación de escenas para 24/36/48/60/72 salas; registrar dispositivo, semilla y resultados.
- [ ] Revisar Proyecto > Configuración > Rendering > Limits > Cluster Builder y confirmar el límite de luces frente a la cantidad activa del mapa.
- [ ] Reducir el costo de nodos por sala: evaluar mallas combinadas y quitar colisiones a decoración que no sea transitable.
- [ ] Extender solo las salas nuevas al ampliar el mapa, evitando borrar e instanciar de nuevo todas las anteriores.
- [ ] Descargar salas lejanas y conservar sus datos para regenerarlas; coordinarlo con el registro rectangular de ocupación.

**Estado de esta iteración:** la colocación, las puertas del editor y las de la
escena jugable usan rectángulos y un cálculo compartido. Se añadieron pruebas
automatizadas, pero todavía no se ejecutaron en Godot. Los paneles de altura y
las correcciones del editor necesitan validación visual. La ocupación circular
es deliberadamente conservadora porque usa su cuadrado envolvente.

## Hito 5 — Atmósfera y publicación

- [ ] Cerrar materiales, iluminación, niebla y sonido ambiental; la iluminación actual es editable desde F4.
- [ ] Revisar el zumbido de fluorescentes con pruebas auditivas y atenuación por distancia.
- [ ] Preparar build, video corto y publicación en itch.io.

## Hito 6 — Editor de mapas

- [x] Crear un editor 2D por módulos con catálogo, rotación, colocación sobre grilla, zoom y borrado.
- [x] Guardar y cargar mapas personalizados como JSON desde el selector de archivos.
- [x] Autoguardar los cambios en `user://saves`, reabrir archivos guardados para editarlos, mover piezas con arrastre y jugar el mapa actual.
- [x] Reconstruir conexiones compatibles por posición/dirección y cerrar las salidas que no conectan en la escena jugable.
- [x] Detectar paredes compartidas entre módulos aunque los sockets del catálogo no coincidan; generar aberturas enfrentadas y evitar huecos en paredes exteriores.
- [x] Reparar mapas guardados antiguos al reabrirlos y admitir pequeños huecos entre bordes, creando un puente de piso para mantener el paso transitable.
- [x] Añadir una opción en el editor para quitar por completo paredes compartidas cuando los dos lados tienen la misma longitud y están alineados.
- [x] Usar una resolución base de 1920 × 1080 y una interfaz que se adapta al tamaño de ventana.
- [x] Añadir paneles para diferencias de altura en puertas y paredes completamente abiertas entre salas del mapa personalizado.
- [ ] Validar en Godot los paneles con "Pasaje bajo", "Cámara alta" y "Gran cámara", tanto con puertas comunes como con paredes completamente abiertas.
- [x] Centralizar el cálculo de puertas en `datos/conexiones_mapa.gd`, compartido por editor y escena jugable, y añadir `pruebas/prueba_conexiones.gd`.
- [ ] Ejecutar `pruebas/prueba_conexiones.gd` en Godot y confirmar `=== TODO OK ===`.
- [ ] En el mapa guardado de seis módulos, confirmar en la salida `módulos: 6 · puertas: 7` y revisar que cada sala reciba sockets antes de construir sus paredes.
- [x] Mostrar las conexiones en el editor (verde: puerta; celeste: pared abierta) y señalar salas superpuestas en rojo.
- [x] Evitar nuevas superposiciones al mover salas con arrastre.
- [x] Al cargar mapas, evitar autoguardados prematuros, conservar filas de tipos desconocidos y mostrar avisos de estado.
- [x] Recibir la tecla R desde el nodo raíz para girar piezas.
- [ ] Conectar salas circulares al perímetro curvo en el editor; sus salidas todavía requieren tratamiento específico.

## Criterios transversales

- Mantener la matemática de grilla/colocación separada de la construcción de escenas.
- Documentar decisiones, límites y problemas conocidos en `docs/`.
- Seguir el flujo Git Flow descrito en `CONTRIBUTING.md`.
