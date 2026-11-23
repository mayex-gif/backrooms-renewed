# Plan siguiente (pedido del 23/11)

Estado: ☐ pendiente · ◐ en curso · ☑ hecho (sin probar en Godot: probar y marcar).
Regla de trabajo: un cambio a la vez, se prueba, se marca. Nada se da por bueno hasta que se probó en Godot.

## Orden recomendado
1. Materiales y placas (2, 3, 4) — chico, visible.
2. Editor: placas rotas/rotadas, click izq/der (1).
3. HUD: batería, estamina, pulso de ruido (6, 7, 8).
4. Caños de luz reactivos (9).
5. Separar el editor en archivos (5) — antes de agregar pisos al editor.
6. Pisos / alturas / rampas / escaleras / toboganes (12) — el grande, ver diseño abajo.
7. Muebles (10), monstruo (11), tela para trepar (12b): solo diseño por ahora.

## 1. Placas rotas / rotadas, click izq/der ☐
- Estados de placa en `_modos_luces` (mismo JSON): -1 normal, 0 luz encendida, 1 intermitente, 2 luz averiada, **3 rota**, **4 rotada**.
- Click derecho = estado siguiente, izquierdo = anterior (vista de techo). Igual para puertas/paredes interiores: derecho siguiente, izquierdo anterior; borrar sala con click derecho solo si no hay puerta/pared bajo el cursor.
- Puerta verde = "puerta" (paso de ancho limitado con dintel). Celeste = "abierta" (todo el largo del tramo, con dintel). Violeta = "intersección" (sin dintel, abierta hasta el techo). Naranja = cerrada.
- Prueba: en vista de techo recorrer los 6 estados en ambos sentidos; guardar, jugar, ver la placa colgando (rota) y la placa montada torcida sobre la grilla (rotada).

## 2–4. Materiales ☐
- Placas recortadas por paredes eran un color liso (`_placa_recortada`); ahora usan la textura de placa triplanar.
- Pared = mi alfombra (amarillo suave), piso = `Carpet001` (shader) más oscuro. Ajustar `TINTE_PARED` y `COLOR_PISO` en `materiales_ambiente.gd`.
- Plenum: `PlenumOscuro.tres` gris concreto.
- Paredes que faltan: sin datos no se puede decidir. Pasar captura + `mapa_actual.json`. Se agregó un print `[MapaGuardado] ocultos` en consola con los tramos de pared ocultados por solape.

## 5. Editor en varios archivos ☐
`herramientas/editor/editor_mapa.gd` (1500 líneas) → carpeta con:
- `editor_mapa.gd`: raíz, estado compartido, guardado/cargado.
- `editor_interfaz.gd`: barra superior, panel lateral, diálogos.
- `editor_lienzo.gd`: dibujo (plano, techo, leyenda, fantasma).
- `editor_entrada.gd`: mouse/teclas.
- `editor_ajuste.gd`: snap/colisión de huellas (`_centro_ajustado`, `_huella_choca`…).
- `editor_historial.gd`: deshacer/rehacer.
- `editor_techo.gd`: placas/luces del techo.
Cada uno es un `RefCounted` que recibe una referencia al editor. Mover de a una pieza, probar, seguir.

## 6–8. HUD ☐
- `interfaz/hud_barras.gd` (CanvasLayer): batería (icono simple de pila) y estamina (barra lisa gris, sin adornos). Aparecen al cambiar el valor o al usarlos y se desvanecen a los ~3 s (siempre visibles si el valor está bajo).
- Batería: se gasta con la linterna encendida; `Pickup` de batería la recarga.
- Estamina: correr gasta, se recarga sola tras una pausa; bebida energética +75 %. Sin estamina no se corre hasta recuperar un mínimo.
- Pulso de ruido: en la barra, pulso por paso. Ruido: correr 1.0, caminar 0.5, agachado/sigiloso 0.2, arrastrarse 0.1, quieto 0. Señal `ruido_emitido(intensidad, posicion)` en el jugador (la usará el monstruo). Futuro: interactuables y zonas ruidosas llaman a la misma señal.

## 9. Caños de luz reactivos ☐
`servicios_techo.gd` debe recibir las posiciones de luminarias de la sala (y su modo) y tender un conduit desde la parte superior de cada luminaria hasta la bandeja más cercana. Cada luminaria guarda su `id_editor`; el conduit lleva la misma meta para poder "arreglar" una luz (cambiar modo) y que el cable/caño muestre chispa/parpadeo.

## 10. Muebles (solo diseño) ☐
- `datos/mueble_def.gd` (Resource): nombre, escena, tamaño de huella, altura, colisión, interactuable, ruido al empujar.
- `salas/muebles/` con escenas; catálogo `catalogo_muebles.gd`.
- Editor: pestaña "Muebles", se colocan sobre la grilla con rotación en pasos de 15°, guardados en `muebles` dentro del JSON de mapa (x, z, nivel, ángulo, tipo).
- Estilo realista: mismas texturas y paleta que el nivel, UI igual que el resto del editor.

## 11. Monstruo que oye (solo diseño) ☐
- Escucha `ruido_emitido`. Radio de oído = intensidad × alcance_base (sube con eco en salas grandes, baja con puertas cerradas).
- Estados: patrulla → investiga último ruido → persigue si ve → busca → vuelve.
- `NavigationRegion3D` por nivel, horneada al cargar el mapa.

## 12. Pisos, alturas, bajadas y subidas (crítico) ☐
Diseño:
- Cada sala gana `nivel` (entero) y `cota_m` (altura del piso). Un nivel = piso + alto de sala + plenum (`ALTURA_CAMARA_TECNICA` 1.9) + losa. Cota del nivel n = suma de (alto + plenum + losa) de los niveles inferiores.
- El editor tiene selector de nivel; se dibuja el nivel actual y el de abajo atenuado. Los solapes y conexiones solo se calculan entre salas del mismo nivel (o conectores).
- Conectores (nuevas piezas del catálogo, con `SalaDef.tipo = CONECTOR`):
  - **Rampa/escalera**: sube de nivel n a n+1; huella rectangular, pendiente ≤ 35°, colisión rampa (escalera = rampa con escalones visuales).
  - **Hueco/caída**: abertura en el techo/piso con borde; bajar de n+1 a n tirándose.
  - **Tobogán/túnel**: tubo casi del alto de una persona en diagonal, solo baja; control de velocidad fija, sin salto.
  - Futuro: **tela** para colgarse (cuerda con estado enganchado, velocidad controlada).
- Plenum: la losa del nivel superior queda sobre el plenum del inferior; las aberturas de los conectores recortan losa, plenum y placas (`zonas_techo_excluidas` y `zonas_suelo_excluidas` ya existen).
- Ya existen `pruebas/escenario_multinivel.gd` y `escenario_abismo.gd`: revisarlos antes de escribir nada nuevo.
- Orden: (a) datos `nivel`/`cota_m` + guardado; (b) selector de nivel en el editor; (c) carga y colocación a la altura correcta; (d) rampa; (e) hueco; (f) tobogán; (g) escalera visual.

## 13. Pendientes que vayan apareciendo
Anotarlos acá con fecha.
