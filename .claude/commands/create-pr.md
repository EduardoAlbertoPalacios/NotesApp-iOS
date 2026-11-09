---
description: Crea una rama, hace commit, push y abre un PR hacia main
argument-hint: [descripción breve del cambio]
---

Crea un pull request con mis cambios actuales. Contexto opcional: $ARGUMENTS

1. Revisa `git status --porcelain` y `git diff HEAD` para entender los cambios (incluidos los archivos nuevos sin seguimiento).
   Si no hay cambios que commitear, dímelo y no hagas nada más.
2. Comprueba que se puede publicar antes de tocar nada:
    - Debe existir el remoto `origin` (`git remote -v`).
    - Debe haber una forma de abrir el PR: el MCP de GitHub, o si no está disponible, `gh` autenticado (`gh auth status`).
   Si falta algo, dime qué falta y no hagas nada más.
3. Verifica que el proyecto compila y las pruebas de los módulos afectados pasan, usando el agente `test-runner`.
   Si algo falla, muéstrame el resumen y no sigas.
4. Si estoy en `main`, crea una rama con formato `tipo/descripcion-corta` en kebab-case.
   El tipo es uno de los de `CLAUDE.md`, según los cambios: `feat`, `fix`, `test`, `refactor`, `chore` o `docs`.
5. Haz commit con Conventional Commits, con el módulo como scope cuando aplique (`feat(data): ...`).
   Agrega los archivos por nombre, no con `git add -A`. No incluyas:
    - archivos que parezcan secretos (`.env`, claves, certificados, `*.p12`, `*.mobileprovision`, `GoogleService-Info.plist`);
    - configuración local o personal (`.claude/settings.local.json`, `xcuserdata/`, `*.xcuserstate`, `.DS_Store`, `DerivedData/`, `*.xcresult`).
   Si alguno de esos ya está en seguimiento o aparece en el diff, avísame en lugar de commitearlo.
6. Haz push de la rama con `git push -u origin <rama>`.
7. Abre el PR hacia `main` (MCP de GitHub o `gh pr create --base main`), con:
    - Título en formato Conventional Commits
    - Descripción con: qué cambia, por qué, y cómo probarlo (comandos `xcodebuild` de `CLAUDE.md` y, si hay UI, los pasos manuales en el simulador)
8. Devuélveme el link del PR.
