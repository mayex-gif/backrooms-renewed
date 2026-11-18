# Jugador de prueba

## Origen

La referencia es el commit `afb5cd2` ("Personaje creado y falta arreglar las animaciones") del repositorio anterior, rama `main`, en particular `jugador/jugador.gd` y `jugador/jugador.tscn`. Ese controlador usaba `CharacterBody3D`, movimiento relativo a la orientación, gravedad, cámara en primera persona, toggle de agachado, correr, head bobbing y pasos sincronizados con el bob.

## Qué se reutilizó y qué se dejó fuera

Se conserva el enfoque probado de CharacterBody3D, cámara hija que rota en pitch, movimiento WASD relativo al jugador, mouse capturado con Escape, y alturas de colisión/cámara para agacharse. El movimiento fue recreado en un script pequeño, con velocidades moderadas y sin acceso a archivos del repo viejo.

No se importaron modelos/animaciones: el commit los ligaba a un GLB y recursos `.res` que no existen en este proyecto; además el propio mensaje del commit señala que las animaciones requerían arreglo. Tampoco se portó el audio de pasos: usaba sonidos del proyecto anterior y dependía de la fase del head bob para marcar pisadas. El bobbing quedó fuera para evitar acoplar cámara, locomoción y sonido antes de validar el movimiento básico.

## Prueba

`pruebas/escenario_jugador.tscn` es el escenario mínimo con piso físico, luz y el jugador instanciado. Es la escena principal del proyecto. Los controles se registran al iniciar desde `jugador.gd`: WASD/flechas, Shift correr, C agacharse, mouse mirar, Escape liberar o capturar cursor; clic vuelve a capturarlo.

## Diferencias y problemas conocidos del prototipo viejo

- Velocidades del último commit: caminar 6, correr 10 y agachado 0,75. Eran valores elevados para el ritmo buscado acá; la versión nueva usa 4, 6 y 2 m/s como punto de partida ajustable.
- El freno antiguo movía la velocidad hacia cero por `velocidad_actual` cada tick, por lo que el frenado variaba con la tasa de física. La versión nueva lo escala por `delta`.
- Cambiar `shape.height` mientras se agacha no comprobaba si había techo encima. En esta versión también falta esa comprobación; antes de añadir techos al escenario se debería impedir ponerse de pie cuando la cápsula ampliada choque.
- El jugador anterior componía animaciones y pasos con head bobbing; el commit reporta animaciones por arreglar y otras ramas posteriores resolvieron el zumbido de luces con variación aleatoria de pitch, atenuación y distancia. Se dejan esos sistemas fuera del primer prototipo aislado.

## Siguiente validación

Probar en Godot que la cápsula permanece apoyada al agacharse y ponerse de pie, que no atraviesa paredes y que la sensibilidad de mouse es cómoda. Luego agregar techo al escenario y resolver el bloqueo de postura antes de integrar el jugador con salas generadas.
