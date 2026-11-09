# Spec 001 — Listado de notas en cuadrícula

## Contexto y objetivo
La app aún no muestra nada: es la plantilla de Xcode. Esta primera iteración construye la pantalla de inicio "Mis notas" tal como está en el diseño de Figma (marcos "Inicio · Mis notas" claro y oscuro), mostrando las notas guardadas en una cuadrícula. Es la base visual sobre la que se agregarán después la búsqueda, los filtros, el orden, la creación y la edición de notas; por eso esos controles aparecen ya en pantalla, pero sin función.

## Usuarios / actores
- Persona que usa la app en iPhone o iPad para guardar notas personales y de trabajo.

## Historias de usuario
- H1: Como usuario quiero ver todas mis notas en una cuadrícula para recorrerlas de un vistazo.
- H2: Como usuario quiero ver primero mis notas fijadas para tener a mano las importantes.
- H3: Como usuario nuevo quiero encontrar notas de ejemplo la primera vez para entender cómo se ve la app.
- H4: Como usuario quiero saber cuándo edité cada nota por última vez para ubicarla en el tiempo.
- H5: Como usuario de VoiceOver o de texto grande quiero poder leer mis notas igual que cualquier otra persona.

## Requisitos funcionales (criterios de aceptación en EARS)

**Pantalla y cabecera**
- RF-1: EL SISTEMA mostrará la pantalla "Mis notas" al abrir la app.
- RF-2: EL SISTEMA mostrará bajo el título el número de notas guardadas seguido de "· un espacio para tus ideas" (ej. "6 notas · un espacio para tus ideas").
- RF-3: SI hay exactamente una nota guardada, ENTONCES EL SISTEMA mostrará el contador en singular ("1 nota · un espacio para tus ideas").

**Cuadrícula**
- RF-4: EL SISTEMA mostrará las notas en una cuadrícula de dos columnas en iPhone.
- RF-5: MIENTRAS un iPad esté en vertical, EL SISTEMA mostrará la cuadrícula en tres columnas.
- RF-6: MIENTRAS un iPad esté en horizontal, EL SISTEMA mostrará la cuadrícula en cuatro columnas.
- RF-7: SI en iPad la app ocupa una ventana tan estrecha como la pantalla de un iPhone (por ejemplo en Split View), ENTONCES EL SISTEMA mostrará la cuadrícula en dos columnas.
- RF-8: EL SISTEMA colocará las notas, en su orden, alternando columnas de izquierda a derecha y volviendo a la primera (con dos columnas: 1.ª a la izquierda, 2.ª a la derecha, 3.ª a la izquierda…).
- RF-9: EL SISTEMA apilará las tarjetas de cada columna una debajo de otra, sin huecos entre ellas más allá del espaciado del diseño.
- RF-10: EL SISTEMA mostrará primero las notas fijadas, ordenadas de la última editada a la más antigua.
- RF-11: EL SISTEMA mostrará después de las fijadas el resto de notas, ordenadas de la última editada a la más antigua.
- RF-12: SI varias notas de ejemplo tienen la misma fecha de última edición, ENTONCES EL SISTEMA las mostrará en el orden del Figma: "Reunión de equipo", "La compra", "Ideas sueltas", "Escapada", "Para leer", "Una buena idea".
- RF-13: EL SISTEMA mostrará en cada tarjeta el título completo de la nota.
- RF-14: EL SISTEMA mostrará en cada tarjeta el contenido completo de la nota, sin cortarlo.
- RF-15: EL SISTEMA ajustará la altura de cada tarjeta a su contenido.
- RF-16: DONDE una nota contenga una lista de tareas, EL SISTEMA mostrará cada tarea con una casilla marcada si está completada o vacía si está pendiente.
- RF-17: MIENTRAS una nota esté fijada, EL SISTEMA mostrará el icono de chincheta en su tarjeta.
- RF-18: EL SISTEMA mostrará cada tarjeta con el color de fondo asignado a su nota, de entre los colores del diseño.
- RF-19: CUANDO las notas no quepan en la pantalla, EL SISTEMA permitirá desplazar la cuadrícula verticalmente.

**Fecha de última edición**
- RF-20: SI la última edición fue hoy, ENTONCES EL SISTEMA mostrará "Hoy, " seguido de la hora (ej. "Hoy, 9:38").
- RF-21: EL SISTEMA mostrará la hora en formato de 12 o 24 horas según la configuración del dispositivo.
- RF-22: SI la última edición fue ayer, ENTONCES EL SISTEMA mostrará "Ayer".
- RF-23: SI la última edición fue antes de ayer y en el año en curso, ENTONCES EL SISTEMA mostrará el día y el mes abreviado (ej. "4 oct").
- RF-24: SI la última edición fue en un año anterior al actual, ENTONCES EL SISTEMA mostrará el día, el mes abreviado y el año (ej. "4 oct 2025").

**Notas de ejemplo**
- RF-25: CUANDO la app se abra por primera vez, EL SISTEMA guardará las seis notas de ejemplo del diseño: "Reunión de equipo" (fijada), "La compra" (lista de tareas), "Ideas sueltas", "Escapada", "Para leer" y "Una buena idea", con el contenido y color que muestra el Figma.
- RF-26: EL SISTEMA tomará como fecha de última edición de cada nota de ejemplo el momento en que se guardó en la primera apertura.
- RF-27: CUANDO la app se abra después de la primera vez, EL SISTEMA mostrará las notas guardadas sin volver a crear las de ejemplo.
- RF-28: CUANDO la app se cierre y se vuelva a abrir, EL SISTEMA mostrará las mismas notas que antes de cerrarla.

**Controles sin función en esta iteración**
- RF-29: EL SISTEMA mostrará el buscador, los filtros "Todas", "Trabajo" y "Personal", la etiqueta de orden "Última edición", el botón de orden, el botón de ajustes y el botón "Nueva nota" como en el diseño.
- RF-30: EL SISTEMA mostrará el filtro "Todas" como seleccionado.
- RF-31: CUANDO el usuario toque cualquiera de los controles de RF-29, EL SISTEMA no cambiará la pantalla ni las notas mostradas.
- RF-32: CUANDO el usuario toque una tarjeta de nota, EL SISTEMA no cambiará la pantalla ni la nota.
- RF-33: CUANDO el usuario toque una casilla de tarea en una tarjeta, EL SISTEMA no cambiará el estado de la tarea.

**Carga y errores**
- RF-34: MIENTRAS las notas se estén cargando, EL SISTEMA mostrará un indicador de carga en lugar de la cuadrícula.
- RF-35: SI las notas guardadas no se pueden cargar, ENTONCES EL SISTEMA mostrará un mensaje comprensible para el usuario, sin detalles técnicos, en lugar de la cuadrícula.
- RF-36: MIENTRAS se muestre el mensaje de error de RF-35, EL SISTEMA mostrará un botón para reintentar la carga.
- RF-37: MIENTRAS se muestre el mensaje de error de RF-35, EL SISTEMA mantendrá visibles el título y los controles de RF-29.
- RF-38: MIENTRAS se muestre el mensaje de error de RF-35, EL SISTEMA no mostrará el contador de notas.
- RF-39: CUANDO el usuario toque el botón de reintentar, EL SISTEMA volverá a intentar cargar las notas.

**Accesibilidad**
- RF-40: CUANDO VoiceOver enfoque una tarjeta, EL SISTEMA leerá el título, el contenido y la fecha de última edición de la nota.
- RF-41: CUANDO VoiceOver enfoque la tarjeta de una nota fijada, EL SISTEMA indicará además que está fijada.
- RF-42: CUANDO VoiceOver enfoque una tarea de una tarjeta, EL SISTEMA indicará si está completada o pendiente.
- RF-43: CUANDO el usuario cambie el tamaño de texto del sistema, EL SISTEMA ajustará el tamaño de todos los textos de la pantalla.

## Requisitos no funcionales
- Plataformas: iPhone y iPad con iOS 27 o posterior.
- Apariencia: la pantalla sigue el modo claro u oscuro del dispositivo, según los marcos "Inicio · Mis notas · Claro" e "Inicio · Mis notas" del Figma. Los colores de las tarjetas son los mismos en ambos modos.
- Idioma: todos los textos visibles en español.
- Las notas se guardan solo en el dispositivo.

## Casos límite
- Primera apertura: se crean las notas de ejemplo (RF-25) una sola vez (RF-27), todas con la misma fecha de última edición (RF-26) y en el orden del Figma (RF-12). Ese día todas muestran "Hoy, HH:mm"; al día siguiente, "Ayer".
- Una sola nota: contador en singular (RF-3).
- Notas muy largas: la tarjeta crece hasta mostrar todo el contenido (RF-14, RF-15).
- Varias notas fijadas: van todas antes que las no fijadas, ordenadas entre sí por última edición (RF-10).
- Notas editadas en un año anterior: la fecha incluye el año (RF-24).
- Rotación del iPad o cambio de tamaño de ventana: el número de columnas se adapta (RF-5 a RF-7).
- Texto grande del sistema: los textos crecen y las tarjetas con ellos (RF-15, RF-43).
- Almacenamiento dañado o ilegible: mensaje y reintentar, con título y controles visibles (RF-35 a RF-39).
- Cero notas: no puede ocurrir en esta iteración, porque no se pueden borrar notas y las de ejemplo se crean en la primera apertura.

## Fuera de alcance
- Buscar notas (el buscador se ve pero no funciona).
- Filtrar por "Todas", "Trabajo" o "Personal" (los filtros se ven pero no funcionan).
- Cambiar el orden (la etiqueta y el botón se ven pero no funcionan).
- Pantalla de ajustes (el botón se ve pero no funciona).
- Crear notas (el botón "Nueva nota" se ve pero no funciona).
- Abrir, editar, borrar, fijar o desfijar notas.
- Marcar o desmarcar tareas desde la tarjeta.
- Cambiar el color de una nota.
- Las variantes "Inicio · Lista con vista previa" del Figma.
- Sincronización entre dispositivos o con la nube.
- Estado vacío (sin notas), porque no puede ocurrir en esta iteración.

## Criterios de finalización
- Todos los RF con prueba en verde (unitarias y de UI).
- La app compila sin errores.
- El agente `architecture-reviewer` responde "Sin violaciones de arquitectura".
- Demo manual en el simulador: primera apertura con las seis notas de ejemplo, en modo claro y oscuro, comparada con el Figma.
- Demo manual en un simulador de iPad, en vertical y en horizontal, con VoiceOver y con texto grande.

## Dudas abiertas
- Ninguna.
