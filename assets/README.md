# Assets externos

## Modelos incluidos

| Archivo | Fuente | Autor | Licencia | Uso |
| --- | --- | --- | --- | --- |
| `modelos/linterna_tactica.glb` | [Flashlight — Haunted House and Ghost Hunting Kit](https://3dassets.dev/assets/paranormal-investigation-house-flashlight-aced9f95) | 3DAssets.dev | CC0 1.0 | Linterna de mano con anillos de agarre y lente emisiva; la luz funcional sigue siendo la `SpotLight3D` del jugador. |
| `modelos/personaje_casual.glb` | [MakeHuman human.glb (vsim)](https://github.com/kunalkushwaha/vsim/blob/main/packages/assets/library/CREDITS.md) | MakeHuman / MPFB 2; rig y clips del proyecto vsim | CC0 1.0 | Personaje humano realista, riggeado y animado; se usa como representación visible del jugador y en la escena de prueba física. |
| `texturas/Carpet001/` | [Carpet 001](https://ambientcg.com/view?id=Carpet001) | ambientCG | CC0 1.0 | Mapas PBR 1K: color, normal OpenGL, roughness y displacement. Aplicar tinte mostaza para la alfombra de pared. |
| `texturas/CeilingTiles0013/` | [Office Ceiling Tiles](https://www.texturecan.com/details/131/) | TextureCan | CC0 1.0 | Mapas PBR 1K para placas acústicas de oficina; licencia permite uso comercial y redistribución con el proyecto. |

CC0 no exige atribución; se conserva esta ficha como procedencia y registro de licencia. El personaje tiene esqueleto y clips idle, walk, run y wave, pero el archivo no trae un ragdoll configurado. Para que Godot lo importe, la geometría cuantizada de la linterna se convirtió a atributos float estándar de glTF.

## Materiales y texturas candidatos

| Superficie | Recurso | Licencia / notas |
| --- | --- | --- |
| Alfombra de pared amarilla | [Carpet 001 — ambientCG](https://ambientcg.com/view?id=Carpet001) | CC0. La textura de origen es gris; aplicar tinte amarillo mostaza en el material para ajustarla a las paredes del proyecto. |
| Placas acústicas del techo | [Office Ceiling Tiles — TextureCan](https://www.texturecan.com/details/131/) | CC0; mapas ya incluidos en `texturas/CeilingTiles0013/`. |
| Yeso / revoque pintado | [Concrete Wall 001 — Poly Haven](https://polyhaven.com/a/concrete_wall_001) | CC0; buena base para placas lisas de yeso, con variación leve de roughness y color. |
| Vidrio de ventana | Material procedural de Godot, sin textura fotográfica: transparencia, roughness y leve tinte verdoso. | Evita mapas innecesarios y permite ajustar el vidrio para las ventanas interiores. |

Las texturas de alfombra y placas de techo ya están incluidas junto con recursos `StandardMaterial3D` iniciales. Todavía no se aplicaron a la geometría de las salas. El yeso y el vidrio quedan como candidatos para integrar al trabajar los materiales de pared y ventanas.

## Física del personaje

El modelo también está instanciado en `jugador/jugador.tscn`: el controlador reproduce `idle`, `walk` y `run` según el movimiento. La linterna está organizada como un conjunto independiente bajo la cámara para que después pueda convertirse en un objeto recogible. Abrí `pruebas/escenario_personaje_fisico.tscn` para ver el modelo sobre una cápsula de colisión y un `RigidBody3D` de 75 kg. Esto da al personaje colisión y movimiento como un cuerpo rígido completo. El GLB mantiene su esqueleto y clips, pero aún no se configuró ragdoll por hueso.
