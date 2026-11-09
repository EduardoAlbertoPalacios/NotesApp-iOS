---
description: Crea un commit con Conventional Commits a partir de los cambios actuales
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Bash(git log:*)
---

Crea un commit de los cambios actuales siguiendo estos pasos:

1. Ejecuta `git status` y `git diff HEAD` (incluye los cambios en stage y fuera de stage) para entender qué cambió. Los archivos nuevos sin seguimiento solo aparecen en `git status`: revísalos también.
2. Si hay cambios que no pertenecen al mismo propósito, detente y propón separarlos en varios commits.
3. No incluyas archivos sensibles, locales ni generados. Si aparecen, avísame:
    - Secretos: `.env`, `*.p12`, `*.cer`, `*.mobileprovision`, `GoogleService-Info.plist`.
    - Configuración local: `.claude/settings.local.json`, `xcuserdata/`, `*.xcuserstate`, `.DS_Store`.
    - Generados: `DerivedData/`, `build/`, `.build/`, `*.xcresult`, `.swiftpm/`.
4. Redacta el mensaje con Conventional Commits:
    - Formato: `tipo(módulo): descripción`
    - Tipos: `feat`, `fix`, `test`, `refactor`, `chore`, `docs`
    - Módulo como scope cuando aplique: `app` (target `NotesApp`), `presentation`, `domain`, `data`, `common`
    - Descripción en inglés, en imperativo, en minúsculas, sin punto final y de máximo 72 caracteres
    - Agrega cuerpo solo si el porqué del cambio no es obvio
5. Muéstrame el mensaje propuesto y los archivos que se incluirán, y espera mi confirmación.
6. Haz `git add` solo de los archivos acordados (por nombre, nunca `git add -A` ni `git add .`) y luego `git commit`.
7. No hagas `git push`.

Contexto adicional del usuario: $ARGUMENTS
