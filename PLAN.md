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
- [x] Alinear las caras inferiores visibles de placas, luminarias y vigas en salas modulares y circulares; construir las placas completas con BoxMesh e inclinar/elevar algunas sin mover las luminarias.
- [x] Separar las placas normales 1,5 cm de la retícula y dar una inclinación leve adicional a las placas levantadas.
- [x] Ampliar el catálogo con una sala abierta de columnas.
- [ ] Implementado; pendiente de prueba manual: centrar las retículas de placas y vigas según las dimensiones de cada huella y compartir el origen con la vista de techo.
- [ ] Implementado; pendiente de prueba manual: cambiar cualquier baldosa entre placa normal, luz encendida, intermitente y averiada desde la vista de techo, conservando el estado en el mapa.
- [ ] Implementado; pendiente de prueba manual: añadir salas de 2,5 × 2,5 m para las alturas modulares disponibles en el catálogo.
- [ ] Implementado; pendiente de prueba manual: agregar y quitar columnas de tamaño configurable por sala desde el editor y persistirlas en el mapa.
- [ ] Implementado; pendiente de prueba manual: desactivar la generación automática para que solo se creen las luminarias elegidas manualmente, reduciendo el número total de luces.
- [ ] Implementado; pendiente de prueba manual: evitar el redibujado completo de la vista de techo cuando solo se mueve el cursor.
- [ ] Recorrer el catálogo y comprobar visualmente puertas, colisiones, techos y materiales.
- [ ] Validar manualmente las placas centradas en salas rectangulares, circulares y de 2,5 × 2,5 m; convertir placas normales en luces y comprobar los cuatro estados dentro de la partida.
- [ ] Validar manualmente columnas personalizadas: tamaños, límites de sala, guardado/carga, duplicado y aparición en la partida.

## Hito 3 — Dos formas de explorar

- [x] Crear un menú inicial que ofrece el plano diseñado o el generador aleatorio.
- [x] Ampliar el plano curado hasta 39 salas, con nuevas alas grandes al este y ramales conectados.
- [x] Ampliar el plano con una sala de columnas y una cámara de 8 m accesibles por el recorrido.
- [x] Abrir los pasos entre alas principales para que se perciban como zonas amplias conectadas.
- [ ] Diseñar precipicios jugables con bordes seguros y acceso claro a cada plataforma explorable.
- [x] Reservar 1,9 m de cámara técnica sobre las placas; añadir tendidos de agua, gas, electricidad y ventilación visibles por placas ausentes/desplazadas; sellar el perímetro y abrir el faldón sobre sockets conectados.
- [ ] Revisar en Godot la cámara técnica en salas rectangulares, poligonales y circulares; confirmar que los tendidos se vean por las aberturas y no salgan de la huella ni atraviesen las placas.
- [ ] Añadir rutas transitables de mantenimiento y conectarlas a escaleras o conectores entre niveles, manteniendo sellado el exterior.
- [x] Añadir ajustes de desarrollo accesibles desde el menú de pausa y una vista de techo superpuesta en el editor de mapas; mostrar placas y luces, cambiar el estado de cada luz con un clic y guardar los cambios en el mapa.
- [x] Usar el conteo de salas para extender o acortar el plano curado; usar los pesos para priorizar ramales grandes y abiertos.
- [x] Reconstruir el mapa actual desde los ajustes de desarrollo y sellar las salidas de ramales omitidos.
- [x] Mantener `pruebas/escenario_generado.tscn` como modo de exploración procedural con semilla y ampliación por bloques.
- [x] Hacer opcional la impresión de la huella completa para que el log no crezca con cada ampliación.
- [ ] Recorrer ambos modos desde el menú, probar los ajustes de desarrollo y verificar que todas las conexiones coinciden en posición y altura.
- [ ] Verificar distintas semillas y el agotamiento de conexiones en el modo aleatorio.

## Hito 4 — Continuidad y rendimiento

- [x] Crear pruebas separadas de una escalera entre dos plantas y de una galería junto a una caída.
- [ ] Añadir al editor un selector de piso de trabajo y guardar el nivel vertical de cada sala en intervalos fijos de 5 m, con niveles arriba y abajo del inicial.
- [ ] Implementar rampas/túneles inclinados y escaleras transitables que unan pisos; admitir conectores que abarquen varios niveles y abrir las superficies atravesadas.
- [ ] Resolver las superficies coincidentes de salas apiladas como una sola losa con cara superior de piso e inferior de techo.
- [ ] Integrar la cámara técnica de 1,9 m con los pisos verticales: resolver su relación con la altura libre de salas y el intervalo estructural de 5 m, y habilitar pasadizos transitables solo en sectores previstos.
- [ ] Normalizar cada forma del catálogo en alturas común/media/alta de 5/10/15 m; conservar el pasaje bajo de 1,35 m como excepción funcional.
- [ ] Conectar paredes, pisos, techos y accesos entre niveles según su altura real, conservando alcanzables las entradas y salidas de los conectores.
- [ ] Convertir las salas de altura variable y las conexiones verticales en parte del plano jugable.
- [ ] Continuar el modo diseñado con módulos de plano curados, manteniendo recorridos amplios y legibles.
- [ ] Descargar regiones lejanas y conservar datos para regenerarlas.
- [ ] Medir y corregir las pausas de carga con una escena reproducible.

**Problema de rendimiento registrado:** el log de la última ejecución muestra
ampliaciones de 24 a 36, 48, 60 y 72 salas. Cada ampliación reconstruye todas las
salas y produce una pausa cercana a un segundo. Se posterga la optimización por
ahora. El modo diseñado reconstruye como máximo 39 salas al aplicar cambios desde
los ajustes de desarrollo;
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
- [x] Completar ocupación y colocación procedural sin solapes automáticos, comparando huellas poligonales exactas.
- [ ] Revisar visualmente colisiones y aperturas, incluida la variante circular y salas con múltiples puertas cercanas.
- [ ] Medir por separado el tiempo de generación matemática y el de instanciación de escenas para 24/36/48/60/72 salas; registrar dispositivo, semilla y resultados.
- [ ] Revisar Proyecto > Configuración > Rendering > Limits > Cluster Builder y confirmar el límite de luces frente a la cantidad activa del mapa.
- [ ] Reducir el costo de nodos por sala: evaluar mallas combinadas y quitar colisiones a decoración que no sea transitable.
- [ ] Extender solo las salas nuevas al ampliar el mapa, evitando borrar e instanciar de nuevo todas las anteriores.
- [ ] Descargar salas lejanas y conservar sus datos para regenerarlas; coordinarlo con el registro rectangular de ocupación.

**Estado de esta iteración:** el editor, la ocupación procedural y la escena
jugable comparten huellas poligonales convexas. El generador procedural sigue
sin crear solapes automáticos. Las pruebas automatizadas existentes y la
geometría nueva quedan pendientes de validación en Godot; no se ejecutaron
durante esta iteración.

## Hito 5 — Atmósfera y publicación

- [ ] Cerrar materiales, iluminación, niebla y sonido ambiental; la iluminación actual es editable desde los ajustes de desarrollo.
- [ ] Verificar visualmente que al averiar todas las luminarias el ambiente quede oscuro, conservando la linterna del jugador.
- [ ] Verificar a distancia que los focos se conserven hasta 50 m con el desvanecimiento gradual desactivado en la configuración actual.
- [ ] Ajustar visualmente la intensidad 0,5 y el cono cuadrado ampliado al 115 % (semilado actual 9,2 m); confirmar que ilumina paredes cercanas y el piso de salas de 8 m y 12 m sin lavar el techo.
- [ ] Revisar el relleno Omni local (0,045 de energía, 2,4 m de alcance) sobre la pared cercana y el techo; comprobar también que sigue los estados apagado e intermitente.
- [ ] Revisar en Godot el nuevo margen uniforme de placas y luminarias frente a la retícula, en salas rectangulares y circulares; confirmar que desapareció el solapamiento visual.
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
- [x] Ejecutar `pruebas/prueba_conexiones.gd` en Godot y confirmar `=== TODO OK ===`.
- [ ] En el mapa guardado de seis módulos, confirmar en la salida `módulos: 6 · puertas: 7` y revisar que cada sala reciba sockets antes de construir sus paredes.
- [x] Mostrar las conexiones en el editor (verde: puerta; celeste: pared abierta) y señalar salas superpuestas en rojo.
- [x] Permitir mover salas con arrastre y conservar los solapes configurables.
- [x] Al cargar mapas, evitar autoguardados prematuros, conservar filas de tipos desconocidos y mostrar avisos de estado.
- [x] Recibir la tecla R desde el nodo raíz para girar piezas.
- [ ] Revisar las paredes y aberturas de salas circulares: pruebas manuales encontraron paredes que sobran y faltan.
- [x] Elegir el estado de cada conexión en el editor (click: puerta, abierta, cerrada; Mayús+click: automático) con ids estables de módulo, guardado en `conexiones` y uso en la escena jugable.
- [x] Probar en Godot los cuatro estados por conexión (incluida abierta entre salas desalineadas y cerrada), confirmar `=== TODO OK ===` en `prueba_conexiones.gd` con `_prueba_estados`.
- [x] Añadir pruebas del planificador de solapes y confirmar `=== TODO OK ===` en Godot.
- [x] Quitar la opción "Pared completa abierta": cada conexión es una puerta salvo que se elija otro estado a mano.
- [x] Conectar salas solo si sus paredes se tocan (tolerancia 1 cm) y eliminar el piso puente que tapaba huecos.
- [x] Corregir el panel sobre el techo bajo en conexiones "interseccion" entre salas de distinta altura.
- [x] Iluminación: focos dirigidos con sombras (solo las cercanas), luz ambiente baja, niebla leve y linterna con sombras.
- [ ] Probar en Godot la nueva iluminación (rendimiento a 60 FPS con sombras, brillo general, parpadeo) y ajustar `salas/luminaria.gd`.
- [x] Permitir rotación de salas en pasos de 5°.
- [x] Añadir ajuste de posición a paredes tangentes, controles de giro positivo/negativo, rotación de sala seleccionada, indicador visible y barra adaptable.
- [x] Confirmar salida con Escape tras cambios; el mapa actual sigue autoguardándose.
- [ ] Corregir y validar el manejo de Escape: la prueba manual encontró `!is_inside_tree()` al marcar el evento después de cambiar de escena.
- [ ] Completar validación en Godot de colocación/arrastre, ajuste, selección, giro y estados de conexión; la captura confirma el indicador de giro, pero los enlaces siguen pendientes.
- [ ] Validar paredes, aberturas y solapes circulares mediante la geometría poligonal común; la prueba manual mostró segmentos sobrantes y faltantes.
- [x] Añadir las tres huellas triangulares aprobadas (60°/60°/60°, 45°/45°/90°, 30°/60°/90°) al catálogo común con sockets de arista.
- [x] Generalizar huellas, contactos, sockets y solapes poligonales para todos los tipos con cualquier rotación, incluidos los círculos.
- [x] Recortar pisos, techos, placas y luminarias según las huellas superpuestas; conservar piso prioritario y techo más alto.
- [x] Generar paredes y segmentos interiores por arista poligonal, permitiendo elegir el estado de cada tramo entre salas rotadas.
- [x] Evitar ramas de geometría específicas por tipo; expresar diferencias de forma mediante huellas y datos compartidos.
- [x] Revisar en Godot los controles de iluminación en pausa, probar valores en vivo y guardar la configuración aprobada en `user://iluminacion.cfg`.
- [x] Cerrar el ajuste visual de iluminación con la configuración aprobada por el usuario.
- [x] Ampliar el catálogo con salas no cuadradas, diámetros circulares variados y salas abiertas con columnas de dimensiones individuales, evitando variantes cuadradas redundantes.
- [ ] Implementado; pendiente de prueba manual: salas compactas de 2,5 × 2,5 m para todas las alturas modulares incluidas en el catálogo.
- [ ] Implementado; pendiente de prueba manual: edición de columnas personalizadas por sala, con dimensiones independientes y persistencia.
- [ ] Implementado; pendiente de prueba manual: centrar placas, vigas y luminarias; convertir una placa normal en luminaria desde la vista de techo.
- [ ] Implementado; pendiente de prueba manual: con generación automática desactivada, confirmar que solo aparezcan las luces elegidas manualmente y que el ajuste persista al guardar y volver a jugar.
- [ ] Implementado; pendiente de prueba manual: verificar que la vista de techo siga respondiendo al hacer clic, paneo y zoom tras eliminar redibujados sin cambios visuales.
- [ ] Revisar en Godot la colocación y el tamaño individual de columnas, las conexiones de las nuevas galerías y los diámetros circulares nuevos.
- [ ] Revisar en Godot el centrado de placas y vigas, la conversión placa/luz y la colocación, guardado y carga de columnas personalizadas.
- [ ] Etapa 2: validar visualmente la superposición parcial de salas y la elección independiente de cada pared interior.
- [ ] Validar visualmente que pisos, techos, vigas, placas y luces no se dupliquen y que prevalezca el techo más alto.
- [ ] Validar visualmente solapes parciales, paredes abiertas y tabiques entre salas de distintas alturas.
- [ ] Revisar en Godot el encastre a esquinas y huecos entre salas; el ajuste debe preferir contactos válidos y dejar los solapes deliberados disponibles.
- [ ] Revisar en Godot que las caras superiores de pisos y placas se vean desde arriba, las inferiores desde abajo, y que las laterales cierren el espesor sin solapes visibles en las esquinas.
- [ ] Revisar apoyos para salas pequeñas totalmente abiertas cuando el editor 3D permita ubicar salas a distintas cotas.
- [ ] Revisar los solapes circulares mediante la misma representación poligonal compartida.

## Criterios transversales

- Mantener la matemática de grilla/colocación separada de la construcción de escenas.
- Documentar decisiones, límites y problemas conocidos en `docs/`.
- Seguir el flujo Git Flow descrito en `CONTRIBUTING.md`.
