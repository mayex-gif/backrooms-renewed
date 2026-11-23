# Assets externos

## Modelos incluidos

| Archivo | Fuente | Autor | Licencia | Uso |
| --- | --- | --- | --- | --- |
| `modelos/linterna_tactica.glb` | [Flashlight — Haunted House and Ghost Hunting Kit](https://3dassets.dev/assets/paranormal-investigation-house-flashlight-aced9f95) | 3DAssets.dev | CC0 1.0 | Linterna de mano con anillos de agarre y lente emisiva; la luz funcional sigue siendo la `SpotLight3D` del jugador. |
| `modelos/personaje_casual.glb` | [MakeHuman human.glb (vsim)](https://github.com/kunalkushwaha/vsim/blob/main/packages/assets/library/CREDITS.md) | MakeHuman / MPFB 2; rig y clips del proyecto vsim | CC0 1.0 | Personaje humano realista, riggeado y animado; se usa como representación visible del jugador y en la escena de prueba física. |
| `modelos/personaje_guardia_seguridad.glb` | [The Security Guard — Ara 3D Gen](https://ara3dgen.com/app/#preset=The%20Security%20Guard&download) | MakeHuman; animaciones de CMU Graphics Lab Motion Capture Database | Datos del personaje CC0; las animaciones CMU son gratuitas para uso comercial y no pueden revenderse por separado | Modelo seleccionable del jugador; rig con socket `WeaponR` y clips `Idle`, `Walk` y `Run`. |
| `texturas/Carpet001/` | [Carpet 001](https://ambientcg.com/view?id=Carpet001) | ambientCG | CC0 1.0 | Texturas PBR originales conservadas como referencia; el material de juego usa un acabado amarillo liso para evitar un patrón repetido. |
| `texturas/CeilingTiles0013/` | [Office Ceiling Tiles](https://www.texturecan.com/details/131/) | TextureCan | CC0 1.0 | Mapas originales conservados como referencia; el cielorraso usa un acabado mate liso y la retícula geométrica marca cada placa. |
| `texturas/YesoPintado.tres` | Material procedural de Godot | Proyecto | — | Revoque pintado para columnas y retícula del techo. |
| `texturas/Piso.tres` | Material procedural de Godot | Proyecto | — | Base gris cálida y mate para pisos. |
| `texturas/PlenumOscuro.tres` | Material procedural de Godot | Proyecto | — | Interior oscuro sobre las placas, visible a través de huecos del cielorraso. |
| `texturas/VidrioVentana.tres` | Material procedural de Godot | Proyecto | — | Vidrio traslúcido verdoso para futuras ventanas. Las salas actuales no tienen mallas de ventana. |

CC0 no exige atribución; se conserva esta ficha como procedencia y registro de licencia. Ara 3D Gen indica que las animaciones proceden de CMU Graphics Lab; sus términos permiten su uso, incluso comercial, y prohíben revenderlas por separado ([licencias y uso](https://ara3dgen.com/docs/cli/)). El personaje casual tiene esqueleto y clips idle, walk, run y wave, pero el archivo no trae un ragdoll configurado. Para que Godot lo importe, la geometría cuantizada de la linterna se convirtió a atributos float estándar de glTF.

## Materiales y texturas candidatos

| Superficie | Recurso | Licencia / notas |
| --- | --- | --- |
| Alfombra de pared amarilla | [Carpet 001 — ambientCG](https://ambientcg.com/view?id=Carpet001) | CC0. La textura de origen es gris; aplicar tinte amarillo mostaza en el material para ajustarla a las paredes del proyecto. |
| Placas acústicas del techo | [Office Ceiling Tiles — TextureCan](https://www.texturecan.com/details/131/) | CC0; mapas ya incluidos en `texturas/CeilingTiles0013/`. |
| Yeso / revoque pintado | `texturas/YesoPintado.tres` | Material procedural del proyecto, aplicado a columnas y retícula del techo. |
| Vidrio de ventana | `texturas/VidrioVentana.tres` | Material procedural translúcido verdoso; listo para asignar cuando haya mallas de ventana. |

Las paredes y placas de salas modulares y circulares usan colores lisos, sin mapas de patrón; las juntas geométricas definen cada placa del cielorraso. El piso, la retícula y el plenum usan materiales propios. El material de vidrio queda listo, pero no se aplica porque el catálogo actual no tiene ventanas.

## Física del personaje

El menú principal permite elegir entre el personaje casual y el guardia; esa selección se guarda en `user://preferencias_personaje.cfg` y se aplica al iniciar cada nivel. El controlador reproduce `idle`, `walk` y `run` según el movimiento. La linterna está organizada como un conjunto independiente bajo el anclaje del brazo para que después pueda convertirse en un objeto recogible. Abrí `pruebas/escenario_personaje_fisico.tscn` para ver el modelo casual sobre una cápsula de colisión y un `RigidBody3D` de 75 kg. Esto da al personaje colisión y movimiento como un cuerpo rígido completo. El GLB mantiene su esqueleto y clips, pero aún no se configuró ragdoll por hueso.
