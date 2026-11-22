# Diseño de Backrooms Renewed

Este documento registra la dirección actual del proyecto y las razones detrás
de sus sistemas.

## Dirección de juego

El jugador puede elegir entre dos modos:

- **Plano diseñado:** `pruebas/escenario_plano.tscn` parte de una red curada de
  hasta 39 salas en
  coordenadas fijas. El recorrido parte de un vestíbulo grande, abre cuatro
  alas, incluye un circuito por una sala circular y tiene ramales más pequeños,
  incluso un tramo que exige arrastrarse. Esta es la base principal para darle
  al espacio una lógica de edificio y evitar el aspecto de laberinto.
- **Generación aleatoria:** `pruebas/escenario_generado.tscn` sigue disponible
  para comparar distribuciones con semilla variable o fija. Cuando el jugador
  llega a un borde, sube el límite de salas y vuelve a construir el mapa con la
  misma semilla.

El modo diseñado todavía es finito y tiene un máximo de 39 piezas en su plano
actual. Desde **Ajustes de desarrollo** en el menú de pausa, el conteo determina
la extensión del recorrido; los pesos
priorizan salas grandes y espacios abiertos al elegir cada ramal. Solo agrega
salas adyacentes a una ya seleccionada; las puertas que quedan sin pareja se
sellan. Al pulsar **Aplicar al mapa actual**, reconstruye el nivel en ejecución
y recoloca al jugador en el vestíbulo. Así se puede comparar el resultado sin
salir de la partida. La selección usa una semilla fija para que cada ajuste sea
reproducible. La continuación prevista es ensamblar
módulos de plano diseñados, con rutas amplias y conexiones legibles; el modo
aleatorio queda como alternativa de exploración y banco de pruebas. Cada sala
del plano debe pertenecer a una ruta alcanzable. Un precipicio solo se agrega
cuando su borde, caída, destino y forma segura de recorrer el área están
definidos; `escenario_abismo.tscn` sigue separado.

## Datos y presentación

- `datos/` contiene direcciones, sockets, definiciones, huellas y colocación.
- `salas/` construye la geometría, las colisiones, la retícula del techo y las
  luces a partir de las definiciones.
- `pruebas/` contiene escenas de juego, prototipos y pruebas de datos.

La lógica de colocación no instancia nodos. El visor procedural consume sus
resultados y construye las salas. El plano fijo comparte el catálogo de salas,
pero selecciona sockets concretos y ajusta algunos anchos para que coincidan
con el recorrido previsto.

## Grilla, direcciones y puertas

- La grilla mide **0,5 m** por celda. Una sala ocupa las celdas que intersectan
  su huella; el origen es la esquina mínima de la sala.
- NORTE = -Z, ESTE = +X, SUR = +Z, OESTE = -X.
- Un socket registra posición, dirección y ancho de una abertura. Al conectar
  dos salas, sus centros y alturas de piso deben coincidir.
- Las puertas ordinarias del catálogo se ampliaron para permitir el paso con
  holgura. El pasillo bajo conserva un acceso estrecho y una altura de 1,35 m.
- Las aberturas que no se usan quedan cerradas; las transiciones de altura
  reciben un panel sobre la puerta.

## Rotación y contactos en el editor de mapas

Las salas rectangulares se pueden girar en pasos de 5°. La pieza en colocación
y la sala seleccionada tienen controles positivo y negativo separados; R y
Mayús+R giran la sala seleccionada, o ajustan la pieza si no hay una sala
seleccionada. El mapa guarda el centro y el ángulo en grados; al abrir mapas
anteriores, sus coordenadas de esquina y giros de 90° se convierten al formato
nuevo.

Las salas giradas se unen solo cuando dos paredes rectas coinciden dentro de
1 cm. Al colocar o mover una pieza, el editor intenta ajustar su centro a la
pared cercana. Las huellas poligonales gobiernan selección, contacto y solapes
en piezas rectangulares, triangulares y circulares con cualquier rotación.
Cada tramo interior de pared conserva un estado independiente. La misma
geometría gobierna detección, ajuste, pisos, techos, luces y paredes para que
no queden huecos ni piezas duplicadas; las diferencias entre piezas se
expresan en sus huellas y datos, no en ramas especiales por tipo.

La prueba visual mostró paredes sobrantes y faltantes en salas circulares. Se
quitaron los rellenos rectangulares cardinales y el perímetro se representa
como huella poligonal con cuatro aristas planas para sockets. La geometría usa
el constructor común de piso, techo, paredes, conexiones y solapes. El cambio
requiere todavía validación visual en Godot.

Se aprobó agregar tres huellas triangulares para enlazar salas a distintos
ángulos: equilátera (60°/60°/60°, lados de 5 m), rectángula isósceles
(45°/45°/90°, catetos de 5 m) y rectángula de 30°/60°/90° (cateto corto de
5 m). Ya están en el catálogo y usan sockets de arista. El filtro del catálogo compara dimensiones, altura, columnas y forma,
pero ignora la distribución de sockets porque las puertas se eligen en el
editor; por eso variantes como `Giro 5x5` se descartan si otra sala tiene la
misma geometría. Para triángulos, huella, detección de contacto y solape,
selección en el editor, paredes con aberturas, piso y techo deben compartir la
misma lista de vértices. No se deben introducir triángulos solo en el editor:
el catálogo, los sockets, el generador procedural y el constructor 3D deben
usar el mismo contrato geométrico antes de publicarlos como piezas disponibles.

La ampliación reciente del catálogo agrega galerías rectangulares alargadas,
salas circulares de 7,5 y 20 m, otra sala abierta de 15 × 25 m con columnas
de ancho y profundidad independientes, y salas compactas de 2,5 × 2,5 m. Estas
últimas se ofrecen en las alturas modulares actuales: 1,35; 3,2; 4,2; 8 y 12 m.
`SalaDef.columnas_tamanos` se alinea por índice con `columnas_locales`; si falta
una medida, se conserva el tamaño legado de 1,3 × 1,3 m. El editor también
permite agregar columnas personalizadas de ancho y largo independientes dentro
de la huella de una sala; se guardan por sala en el JSON del mapa y se construyen
en la partida. La revisión visual de estas piezas queda pendiente.

La decisión de alcance es permitir solapes configurables en el editor para
cualquier par de huellas; el generador procedural mantiene la colocación sin
solapes automáticos. La conexión procedural sí debe aceptar sockets sobre
cualquier arista, para que el catálogo común no dependa de direcciones
cardinales.

## Solapes en el editor de mapas

El editor usa huellas poligonales para ubicar, girar y superponer piezas. Cada
segmento interior recorre de forma independiente los estados puerta, abertura
con dintel, tabique y abertura completa. El contrato aprobado permite que
cualquier huella se cruce con cualquier otra a cualquier rotación, incluidos
los círculos. La implementación todavía está en curso; generación procedural,
validación de sockets y construcción 3D deben consumir el mismo modelo de
aristas y huellas antes de considerar la función terminada.
La abertura completa llega como máximo al techo más alto de las salas que
ocupan el otro lado del muro; si el módulo actual es más alto, conserva el
paño superior hasta su propio techo.

Con la cota de piso actual, el piso compartido queda a cargo de la primera sala
del mapa. En el área superpuesta prevalece el techo más alto: se quitan las
placas y luminarias del nivel bajo dentro de esa huella, y se conservan las
paredes necesarias hasta el techo que corresponda. La propiedad debe basarse
en la cota de cada superficie cuando el editor permita niveles de piso
distintos. El soporte estructural de salas pequeñas completamente abiertas se
revisará junto con el editor 3D y la colocación a distintas cotas.

## Salas y techos

El catálogo combina pasillos, giros, cruces, bifurcaciones, salas medianas y
abiertas, cámaras altas, un pasaje bajo, huellas circulares y triangulares, y
variantes compactas de 2,5 × 2,5 m para las alturas modulares disponibles.

Las salas modulares usan placas de 1,5 m. La retícula se centra respecto de los
límites de la huella para repartir por igual los recortes perimetrales; las
barras y los paneles usan ese mismo origen. La vista de techo del editor
reproduce la misma retícula para que las celdas clicables correspondan con las
placas generadas en 3D. En posiciones normales, las caras
inferiores visibles de placas, luminarias y retícula coinciden a la misma altura
respecto del piso. Las
luminarias ocupan casi el tile completo y parten de una distribución cada tres
tiles; hay placas ausentes, desplazadas, quemadas o intermitentes. La sala
circular usa la retícula común recortada por su huella. La
geometría volvió a materiales por defecto, sin tintes ni texturas.

En salas modulares y circulares, las placas y luminarias restan 8 cm al lado
del módulo de 1,5 m (4 cm por lado); así queda una junta de 5 mm con las barras
de 7 cm y se evita que se crucen sus mallas. La cara inferior de las
placas y los paneles luminosos queda al mismo nivel, 0,5 cm sobre la retícula.
Algunas placas completas se levantan además entre 4 y 12 cm y se inclinan hasta
3 grados. Las placas recortadas por bordes o solapes conservan su posición.
Las placas completas usan `BoxMesh`; las piezas recortadas conservan la malla
poligonal común.

Los pisos y las placas del techo se construyen como prismas cerrados: incluyen
caras superiores, inferiores y laterales. El orden de vértices debe dejar cada
cara visible desde su lado exterior con el descarte de caras de Godot. Las
placas ausentes siguen siendo huecos intencionales del cielorraso, cubiertos
por el plenum superior.

Cada foco se centra en su placa y proyecta una mancha cuadrada, calculada para
alcanzar las esquinas del piso según la altura real. El semilado, el borde y la
atenuación se pueden cambiar en vivo. La configuración aceptada usa intensidad
0,6, semilado 16,5 m y borde 0,74. Cada luminaria añade un rebote Omni local de
energía 0,06, alcance 1,9 m y altura -0,04 m. El rebote lateral usa energía
0,007, semilado 2,2 m y altura -0,07 m. Las placas apagadas usan gris 0,6. El
relleno amplio por sala queda desactivado de forma predeterminada y se puede
activar durante la prueba. Se pueden ajustar los parámetros de cada rebote.
manchas en las paredes. El ambiente base actual es 0,025; SSIL depende de la
opción de rebote en pantalla y SDFGI queda apagado. SSAO y Glow siguen activos.
La linterna del jugador es
independiente. El menú de pausa abre los ajustes de ambiente e intensidad.
**Vista de techo** superpone
las celdas de placas sobre el mismo plano del editor. Un clic recorre placa
normal, luz encendida, intermitente, averiada y de nuevo placa normal; los
estados se guardan en el JSON del mapa y se aplican al construir las salas de la
partida. El editor incluye **Generar luces automáticamente**, activado por
defecto para conservar la distribución procedural. Al desactivarlo, la partida
solo crea luminarias en las placas modificadas manualmente; las demás placas
quedan normales y se evita sumar luces de patrón a la selección del usuario.
El ajuste y las selecciones manuales se guardan por mapa. SSR sigue apagado
porque las superficies actuales son mates y no deberían reflejar el entorno.
Los focos se conservan hasta 50 m de la cámara y las sombras empiezan a
desvanecerse a 50 m. El usuario revisó y aprobó visualmente la configuración
actual.
Los ajustes de desarrollo también permiten reconstruir mapas compatibles con
cantidad y pesos distintos.
Desde ese mismo panel en pausa se puede ajustar en vivo la intensidad, forma,
color, atenuación, tamaño, sombras y distancias del foco; emisión del panel;
activación, energía, alcance, altura y atenuación de los rebotes locales,
laterales y amplios por sala; gris de placas apagadas; y parámetros de
parpadeo/fallas. Las probabilidades de falla e intermitencia se aplican a las
luminarias nuevas. **Guardar iluminación** persiste los valores en
`user://iluminacion.cfg`; se cargan al iniciar y afectan también a las luminarias
de salas generadas después. La configuración aprobada se fijó también como
valores iniciales del proyecto: intensidad 0,6; haz de semilado 16,5 m; rebote
local 0,06; rebote lateral 0,007; relleno de sala desactivado y sin fallas ni
parpadeos aleatorios.

Se observaron anteriormente manchas en paredes cercanas. Los rebotes y el foco
se dejaron ajustables para poder afinar su apariencia desde el menú durante el
recorrido visual.
Los dinteles tienen una abertura de 2,45 m; se quitaron los marcos extra para
evitar z-fighting.

El plenum se acerca a las placas para ocultar el exterior a través de huecos
accidentales. Queda registrada la futura construcción de cañerías visibles y
una zona superior explorable, con acceso y colisiones planeados.

Los materiales siguen siendo provisionales. El relieve, la textura de papel,
la alfombra, los reflejos y el balance de luz necesitan una pasada visual.

## Semillas y pausa de carga conocida

El generador usa una cola de sockets pendientes, rechaza huellas ocupadas y
elige candidatos con pesos y semilla. La semilla `-1` crea una distribución
aleatoria y retorna la semilla utilizada; cualquier otra conserva un mapa
repetible. La huella completa solo se imprime si se activa
`imprimir_huella_completa` en el Inspector.

En la última ejecución, la extensión avanzó 24 → 36 → 48 → 60 → 72 salas y
generó una pausa de cerca de un segundo por bloque. El código vuelve a calcular
y reconstruir todas las instancias al ampliar el límite, y el visor no descarga
zonas lejanas. Se registra como trabajo pendiente de rendimiento; por ahora se
prioriza el modo de plano fijo para jugar.

## Límites actuales

- El plano principal aún no conecta pisos verticales. La rampa/escalera y el
  abismo existen como escenas de prototipo independientes.
- La selección de sockets del plano es manual; hay que revisar en Godot sus
  uniones, especialmente la puerta hacia el pasaje bajo y el cierre sobre ella.
- El no-clip F3 solo se añade en compilaciones de desarrollo. WASD y el mouse
  controlan el vuelo, E sube y Q baja.
- La extensión procedural no hace streaming ni libera nodos lejanos.
