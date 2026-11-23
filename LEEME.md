# Ajustes tras tu prueba (sobre el commit 9ce77fe)
Copiá las carpetas encima de tu proyecto (mantienen rutas). **No lo pude ejecutar en Godot**: solo verifiqué la sintaxis.

- **Pared**: vuelve a `Carpet001_1K-JPG.tres` (el de antes). Piso: mi alfombra, más amarilla (`TINTE_PISO` en `materiales_ambiente.gd`).
- **Oscuridad**: ambiente 0.1 → 0.025, niebla casi negra, fondo negro, glow menor. Con luces apagadas solo debería verse lo que ilumina la linterna. Si queda muy oscuro, subí `ENERGIA_AMBIENTE` en `jugador.gd`.
- **Plenum**: gris concreto (`PlenumOscuro.tres`) para que la linterna lo ilumine.
- **Caños** (`servicios_techo.gd`): sin emisión; agua en cobre, gas amarillo con bridas, ducto galvanizado con refuerzos, bandeja con cables y conduit, varillas que cuelgan del forjado. Una malla por material (mejor rendimiento).
- **Pies**: la velocidad de la animación se calibra con la zancada medida de cada clip (casual 1.06/3.6 m/s, guardia 1.65/3.95 m/s caminar/correr). Al bajar `velocidad_caminar/correr` la animación se enlentece sola. Con tus 4 y 6 m/s la animación va acelerada (hasta 3×): conviene bajar las velocidades (~1.6 y ~3.5).
- **Linterna torcida**: brazo menos extendido (`extension_maxima` 0.78), codo hacia abajo, agarre más cerca del cuerpo. Es un ajuste a ciegas: si sigue torcida, mandame captura y lo afino.
- **Paredes que no aparecen**: no pude diagnosticarlo. Mandame una captura desde dentro donde falte y tu `mapa_actual.json` (Proyecto → Abrir carpeta de datos de usuario).
