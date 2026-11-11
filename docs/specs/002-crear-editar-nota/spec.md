# Spec 002 — Crear y editar notas

## Contexto y objetivo
Tras la spec 001 la app muestra las notas en "Mis notas", pero no permite crear ninguna ni cambiar las existentes: el botón "Nueva nota" y las tarjetas no hacen nada. Esta iteración añade el editor (marco "Editor" del Figma, ejemplo "Editor · Reunión de equipo · Claro") para crear una nota nueva desde "Nueva nota" y para abrir y editar una existente tocando su tarjeta. Se limita a escribir texto simple, elegir la categoría y fijar la nota; el resto de controles del editor aparecen como en el diseño, pero sin función. Los cambios se guardan solos mientras el usuario escribe, sin botón de guardar.

## Usuarios / actores
- Persona que usa la app en iPhone o iPad para guardar notas personales y de trabajo.

## Historias de usuario
- H1: Como usuario quiero crear una nota nueva para apuntar una idea en el momento.
- H2: Como usuario quiero abrir una nota existente y cambiar su texto para mantenerla al día.
- H3: Como usuario quiero clasificar una nota como "Trabajo" o "Personal" para distinguir sus ámbitos.
- H4: Como usuario quiero fijar o desfijar una nota desde el editor para tener a mano las importantes.
- H5: Como usuario quiero que lo que escribo se guarde solo para no perderlo si olvido guardar.
- H6: Como usuario quiero que una nota que abrí por error y dejé vacía no se quede en mi lista.

## Requisitos funcionales (criterios de aceptación en EARS)

**Abrir el editor**
- RF-1: CUANDO el usuario toque el botón "Nueva nota", EL SISTEMA abrirá el editor con el título y el contenido vacíos.
- RF-2: CUANDO el usuario toque el botón "Nueva nota", EL SISTEMA abrirá el editor sin ninguna categoría seleccionada.
- RF-3: CUANDO el usuario toque el botón "Nueva nota", EL SISTEMA abrirá el editor con la nota sin fijar.
- RF-4: CUANDO el usuario toque una tarjeta de nota en "Mis notas", EL SISTEMA abrirá el editor con el título, el contenido, la categoría y el estado de fijada de esa nota.
- RF-5: CUANDO el usuario toque el botón de volver del editor, EL SISTEMA regresará a "Mis notas".

**Escribir**
- RF-6: EL SISTEMA permitirá escribir y modificar el título de la nota como texto simple.
- RF-7: EL SISTEMA permitirá escribir y modificar el contenido de la nota como texto simple.
- RF-8: MIENTRAS el título esté vacío, EL SISTEMA mostrará en su lugar el texto de ayuda "Título".
- RF-9: MIENTRAS el contenido esté vacío, EL SISTEMA mostrará en su lugar el texto de ayuda "Escribir nota…".
- RF-10: CUANDO el contenido no quepa en la pantalla, EL SISTEMA permitirá desplazar el editor verticalmente.
- RF-11: DONDE una nota contenga una lista de tareas, EL SISTEMA mostrará en el editor cada tarea con una casilla marcada si está completada o vacía si está pendiente.
- RF-12: CUANDO el usuario toque una tarea o su casilla en el editor, EL SISTEMA no cambiará su texto ni su estado.
- RF-13: CUANDO se guarde una nota con lista de tareas, EL SISTEMA conservará sus tareas sin cambios.

**Categoría**
- RF-14: EL SISTEMA mostrará el selector de categoría con las opciones "Trabajo" ("Proyectos, reuniones y tareas") y "Personal" ("Recordatorios y vida diaria"), como en el diseño.
- RF-15: CUANDO el usuario toque una categoría, EL SISTEMA la marcará como la categoría de la nota.
- RF-16: CUANDO el usuario toque una categoría distinta de la seleccionada, EL SISTEMA sustituirá la categoría anterior por la nueva.
- RF-17: MIENTRAS la nota tenga categoría, EL SISTEMA mostrará la etiqueta de esa categoría junto a la fecha de última edición, en la cabecera del editor.
- RF-18: MIENTRAS la nota no tenga categoría, EL SISTEMA no mostrará ninguna etiqueta de categoría en la cabecera del editor.
- RF-19: EL SISTEMA permitirá guardar una nota sin categoría.

**Fijar**
- RF-20: CUANDO el usuario toque el botón de fijar de una nota sin fijar, EL SISTEMA fijará la nota.
- RF-21: CUANDO el usuario toque el botón de fijar de una nota fijada, EL SISTEMA desfijará la nota.
- RF-22: MIENTRAS la nota esté fijada, EL SISTEMA mostrará el botón de fijar en estado activado.

**Guardado automático**
- RF-23: CUANDO el usuario cambie el título, el contenido, la categoría o el estado de fijada, EL SISTEMA guardará la nota sin que el usuario tenga que pulsar ningún botón.
- RF-24: CUANDO pase 1 segundo desde el último cambio sin que el usuario haga otro, EL SISTEMA guardará los cambios pendientes.
- RF-25: CUANDO el usuario toque el botón de volver con cambios aún sin guardar, EL SISTEMA los guardará antes de regresar a "Mis notas".
- RF-26: MIENTRAS todos los cambios de la nota estén guardados, EL SISTEMA mostrará "Todos los cambios guardados" al final del contenido.
- RF-27: CUANDO se guarde un cambio, EL SISTEMA actualizará la fecha de última edición de la nota al momento del guardado.
- RF-28: SI el usuario abre una nota existente y vuelve sin cambiar nada, ENTONCES EL SISTEMA no modificará su fecha de última edición.
- RF-29: CUANDO el usuario regrese a "Mis notas", EL SISTEMA mostrará la nota creada o editada en la posición que le corresponde según el orden de la spec 001 (RF-10 y RF-11 de la 001).
- RF-30: CUANDO el usuario regrese a "Mis notas" tras crear una nota, EL SISTEMA actualizará el contador de notas.
- RF-31: CUANDO la app se cierre y se vuelva a abrir, EL SISTEMA mostrará las notas creadas y editadas con su último contenido guardado.

**Notas vacías y sin título**
- RF-32: SI el usuario regresa a "Mis notas" desde una nota nueva con el título y el contenido vacíos, ENTONCES EL SISTEMA no guardará la nota.
- RF-33: SI una nota nueva llegó a guardarse y el usuario borra su título y su contenido antes de regresar a "Mis notas", ENTONCES EL SISTEMA eliminará esa nota.
- RF-34: SI una nota tiene contenido y el título vacío, ENTONCES EL SISTEMA la guardará con el título "Sin título".
- RF-35: SI una nota tiene título y el contenido vacío, ENTONCES EL SISTEMA la guardará con normalidad.
- RF-36: MIENTRAS una nota existente tenga el título y el contenido vacíos, EL SISTEMA no guardará ese estado vacío.
- RF-37: SI el usuario regresa a "Mis notas" desde una nota existente con el título y el contenido vacíos, ENTONCES EL SISTEMA mostrará la nota con su último título y contenido guardados.

**Errores al guardar**
- RF-38: SI un guardado falla, ENTONCES EL SISTEMA mostrará en el editor un mensaje comprensible para el usuario, sin detalles técnicos.
- RF-39: SI un guardado falla, ENTONCES EL SISTEMA conservará en el editor el título, el contenido, la categoría y el estado de fijada que había escrito o elegido el usuario.
- RF-40: SI un guardado falla, ENTONCES EL SISTEMA no mostrará "Todos los cambios guardados".
- RF-41: SI un guardado falla, ENTONCES EL SISTEMA mantendrá al usuario en el editor.
- RF-42: SI el usuario toca el botón de volver y hay cambios que no se pudieron guardar, ENTONCES EL SISTEMA le preguntará si quiere descartarlos, con las opciones de descartar o seguir editando.
- RF-43: CUANDO el usuario elija descartar en la pregunta de RF-42, EL SISTEMA regresará a "Mis notas" mostrando la nota con su última versión guardada, o sin la nota si nunca llegó a guardarse.
- RF-44: CUANDO el usuario elija seguir editando en la pregunta de RF-42, EL SISTEMA lo mantendrá en el editor con sus cambios intactos.

**Controles sin función en esta iteración**
- RF-45: EL SISTEMA mostrará los botones de compartir, menú (⋯), formato de texto, lista de tareas, imagen, deshacer y color como en el diseño.
- RF-46: CUANDO el usuario toque cualquiera de los controles de RF-45, EL SISTEMA no cambiará la pantalla ni la nota.

**Accesibilidad**
- RF-47: CUANDO VoiceOver enfoque el botón de fijar, EL SISTEMA indicará si la nota está fijada o no.
- RF-48: CUANDO VoiceOver enfoque una opción de categoría, EL SISTEMA indicará su nombre y si está seleccionada.
- RF-49: CUANDO VoiceOver enfoque un botón del editor, EL SISTEMA leerá su función (volver, fijar, compartir, más opciones, formato, lista de tareas, imagen, deshacer, color).
- RF-50: CUANDO el usuario cambie el tamaño de texto del sistema, EL SISTEMA ajustará el tamaño de todos los textos del editor.

## Requisitos no funcionales
- Plataformas: iPhone y iPad con iOS 27 o posterior.
- Apariencia: el editor sigue el diseño del marco "Editor" del Figma y el modo claro u oscuro del dispositivo.
- Idioma: todos los textos visibles en español.
- Las notas se guardan solo en el dispositivo.
- Ningún cambio confirmado como guardado ("Todos los cambios guardados") se pierde al cerrar la app.

## Casos límite
- Nota nueva abierta y cerrada sin escribir nada: no se crea (RF-32), aunque se haya elegido categoría o fijado.
- Nota nueva que se guardó mientras se escribía y luego se vació: se elimina al volver (RF-33).
- Solo contenido: se guarda como "Sin título" (RF-34).
- Nota existente vaciada: el estado vacío no se guarda y, al volver, la nota aparece con su último texto guardado (RF-36, RF-37). Si el usuario borró primero el título y pasó 1 segundo antes de borrar el contenido, ese último texto guardado ya es "Sin título" con el contenido anterior (RF-34).
- Solo título: se guarda con normalidad (RF-35).
- Nota sin categoría: se guarda y la cabecera no muestra etiqueta (RF-18, RF-19).
- Volver justo después de escribir, antes del guardado automático: los cambios se guardan al salir (RF-25).
- Abrir una nota y salir sin tocar nada: conserva su fecha y su posición en la cuadrícula (RF-28).
- Fijar o desfijar en el editor: al volver, la nota cambia de grupo en la cuadrícula (RF-29).
- Almacenamiento no disponible al guardar: mensaje en el editor, sin perder lo escrito (RF-38 a RF-41).
- Volver con cambios que no se pudieron guardar: se pregunta si descartarlos; descartar deja la última versión guardada, o ninguna nota si era nueva y nunca se guardó (RF-42 a RF-44).
- Varios cambios seguidos con menos de 1 segundo entre ellos: se guardan juntos al pasar 1 segundo desde el último (RF-24).
- Texto muy largo: el editor se desplaza (RF-10).
- Nota con lista de tareas, como "La compra": las tareas se ven con su casilla, pero no se pueden marcar, desmarcar ni editar, y se conservan al guardar (RF-11 a RF-13).

## Fuera de alcance
- Formato de texto: subtítulos, viñetas u otros estilos (el botón se ve pero no funciona).
- Crear, marcar o desmarcar listas de tareas (el botón se ve pero no funciona).
- Editar el texto de las tareas existentes (se ven, pero no se pueden modificar).
- Insertar imágenes (el botón se ve pero no funciona).
- Deshacer (el botón se ve pero no funciona).
- Cambiar el color de la nota (el botón se ve pero no funciona).
- Compartir la nota (el botón se ve pero no funciona).
- Las opciones del menú ⋯, incluido borrar una nota (el botón se ve pero no funciona).
- Borrar notas de forma explícita (solo se descarta una nota nueva vacía, RF-32 y RF-33).
- Borrar una nota existente cuando el usuario vacía su título y su contenido: es el comportamiento deseado, pero se deja para una iteración posterior.
- Buscar, filtrar y cambiar el orden en "Mis notas".
- Marcar o desmarcar tareas desde la tarjeta en "Mis notas".
- Sincronización entre dispositivos o con la nube.

## Criterios de finalización
- Todos los RF con prueba en verde (unitarias y de UI).
- La app compila sin errores.
- El agente `architecture-reviewer` responde "Sin violaciones de arquitectura".
- Demo manual en el simulador de iPhone: crear una nota, editar una de ejemplo, fijarla, cambiar su categoría, dejar una nueva vacía y comprobar que no aparece, en modo claro y oscuro, comparada con el Figma.
- Demo manual en iPad, si para entonces hay un simulador de iPad disponible.

## Dudas abiertas
- [NECESITA ACLARACIÓN: ¿qué muestra el indicador mientras hay cambios sin guardar o se está guardando: "Guardando…", nada u otro texto?]
- [NECESITA ACLARACIÓN: tras un fallo de guardado (RF-38 a RF-41), ¿se reintenta solo con el siguiente cambio, hay un botón de reintentar, o ambos?]
- [NECESITA ACLARACIÓN: al abrir una nota guardada como "Sin título", ¿el campo de título muestra "Sin título" como texto editable o aparece vacío?]
- [NECESITA ACLARACIÓN: ¿se puede quitar la categoría de una nota después de elegirla (por ejemplo, tocando de nuevo la seleccionada) o solo cambiarla por la otra?]
- [NECESITA ACLARACIÓN: ¿qué fecha muestra la cabecera de una nota nueva antes de su primer guardado?]
- [NECESITA ACLARACIÓN: ¿existe un marco "Editor" en modo oscuro en el Figma? Solo se revisó la captura en modo claro.]
