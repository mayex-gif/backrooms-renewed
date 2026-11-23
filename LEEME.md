# Entrega 2 (copiar encima de entrega 1 + 1b) — solo sintaxis verificada
- **Placas iguales**: las de borde y las del centro salen del mismo código (mismas UV, tangentes, relieve y variante), separadas con el mismo margen.
- **Nada aleatorio en el techo**: ya no hay placas faltantes/sueltas al azar ni luces averiadas/intermitentes al azar (`FALLAS_ALEATORIAS` en `luminaria.gd`; poné `true` para volver a lo viejo). Todo lo decide el editor.
- **Editor, vista de techo**: se ven todas las luces automáticas (círculo), y los caños (agua cobre, gas amarillo, ducto gris, bandeja). Nuevo estado **placa faltante** (hueco: se ve el plenum y los caños). Ciclo: normal, encendida, intermitente, averiada, rota, rotada, faltante. Derecho siguiente, izquierdo anterior.
- **Mapas viejos**: las placas que antes faltaban al azar ahora están todas; marcá las faltantes a mano.
- **Paredes**: alfombra con más relieve (normal_scale 2), repetición más fina (0.55 m) y leve luz de borde. Ajustable en `materiales_ambiente.gd`.
