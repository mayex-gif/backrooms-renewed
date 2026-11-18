# Contribuir a Backrooms Renewed

Esta guía define cómo trabajar en el repositorio con un flujo Git Flow simple. `main` conserva versiones estables; el trabajo nuevo se desarrolla en ramas cortas y se integra mediante pull request.

## Ramas

- `main`: versión estable y jugable. No trabajar directamente aquí.
- `develop`: integración de la próxima versión. Se crea cuando comience el primer ciclo de integración; hasta entonces, `main` es la base de las ramas `feature/*`.
- `feature/<tema>`: funcionalidad nueva, por ejemplo `feature/jugador-prueba` o `feature/generador-salas`; nace de `develop` si existe, o de `main` mientras no exista.
- `bugfix/<tema>`: corrección de un problema detectado durante el desarrollo; nace de `develop` si existe.
- `release/<version>`: preparación y correcciones finales de una versión; nace de `develop`.
- `hotfix/<tema>`: arreglo urgente sobre una versión publicada; nace de `main`.

Usar nombres cortos, descriptivos y en minúscula. No reutilizar ramas ya integradas.

## Ciclo de trabajo

1. Actualizar la rama base y crear una rama para una sola tarea.
2. Implementar y revisar el diff. Ejecutar la comprobación manual o automatizada apropiada y anotar qué se verificó.
3. Hacer commits pequeños con mensajes en español y verbo en imperativo, por ejemplo `Agrega escenario mínimo para el jugador`.
4. Publicar la rama y abrir un pull request hacia su rama base. El PR debe explicar motivo, cambios, cómo probarlos y limitaciones conocidas; incluir capturas cuando un cambio visual lo amerite.
5. Tras revisar y validar, integrar con **Squash and merge** para mantener el historial de `main`/`develop` legible. Borrar la rama remota integrada.

## Releases y urgencias

Una `release/*` se integra en `main` y `develop`; se etiqueta `vMAJOR.MINOR.PATCH` en `main`. Un `hotfix/*` se integra tanto en `main` como en `develop` (o se propaga al siguiente release si todavía no existe `develop`). No crear ramas `release` o `hotfix` para cambios ordinarios.

## Reglas del proyecto

- No versionar `.godot/`, builds, cachés o archivos temporales.
- Mantener escenas, scripts, recursos y documentación dentro de sus carpetas existentes; explicar decisiones de arquitectura en `docs/`.
- Preferir recursos y controles reproducibles, sin referencias a rutas locales ni dependencias del repositorio anterior.
- Actualizar README/plan cuando cambie el estado de un hito. Una tarea solo se marca terminada después de validar el comportamiento descrito.
- No incorporar assets externos sin registrar su fuente y licencia.

## Convención de commits

Usar mensajes breves que describan el resultado: `Agrega ...`, `Corrige ...`, `Documenta ...`. Evitar commits que mezclen tareas independientes. Antes de integrar, comprobar `git status`, revisar `git diff` y confirmar que ningún archivo de usuario ajeno a la tarea quedó incluido.
