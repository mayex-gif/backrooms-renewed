# Entrega 1 (sobre 84494af) — no probada en Godot, solo sintaxis verificada
Probar en este orden y avisarme qué falla:
1. **Pared/piso**: pared = alfombra mía (amarillo suave, `TINTE_PARED`), piso = Carpet001 más oscuro (`COLOR_PISO`), ambos en `salas/materiales_ambiente.gd`.
2. **Placas lisas**: eran las placas recortadas por paredes (color liso). Ahora llevan la misma textura de placa.
3. **Editor, vista de techo**: click derecho = estado siguiente, izquierdo = anterior. Orden: normal → luz encendida → intermitente → averiada → **rota** → **rotada**. Rota = mitad de la placa colgando torcida; rotada = placa montada torcida encima de la grilla.
4. **Puertas/paredes interiores** (vista plano): derecho = siguiente, izquierdo = anterior; si no hay puerta bajo el cursor, el derecho sigue borrando salas. Verde = puerta (paso angosto con dintel), celeste = abierta (todo el tramo, con dintel), violeta = intersección (sin dintel), naranja = cerrada.
5. **Paredes que faltan**: al jugar, la consola imprime `[MapaGuardado] pared oculta: ...`. Pegame esas líneas + captura + `mapa_actual.json`.
6. Plenum: ya era gris (0.36); si lo querés más claro, `assets/texturas/PlenumOscuro.tres`.
Plan completo y orden de lo que sigue: `docs/PLAN_SIGUIENTE.md`.
