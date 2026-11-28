# Spec 004 — Buscar notas

## Contexto y objetivo
"Mis notas" muestra un buscador ("Buscar en tus notas") desde la spec 001, pero es solo visual: no hace nada (RF-29 y RF-31 de la spec 001). A medida que el usuario acumula notas, encontrar algo que escribió hace tiempo obliga a recorrer la cuadrícula a ojo o a abrir nota por nota. Esta iteración hace funcionar el buscador para que el usuario recupere en segundos cualquier nota a partir de lo que recuerda haber escrito, aunque no recuerde el texto exacto, sus mayúsculas o sus acentos. Toma como base la spec "Buscar en mis notas" de la versión Android (2026-10-13), adaptada a lo que ya existe en iOS: aquí los filtros "Todas", "Trabajo" y "Personal" todavía no funcionan, así que la búsqueda no interactúa con ellos.

## Usuarios / actores
- Persona que usa la app en iPhone o iPad con muchas notas: sabe que escribió algo ("la reunión con proveedores", "la receta") pero no dónde ni cuándo.

## Historias de usuario
- H1: Como usuario quiero escribir una palabra en el buscador y ver solo las notas que la contienen para encontrar rápido lo que busco.
- H2: Como usuario quiero que la búsqueda encuentre la nota aunque escriba sin acentos, en otras mayúsculas o con las palabras en otro orden para no tener que recordar el texto exacto.
- H3: Como usuario quiero que la búsqueda incluya el texto de mis listas de tareas para encontrar, por ejemplo, la lista de la compra por uno de sus productos.
- H4: Como usuario quiero abrir una nota de los resultados y, al volver, seguir viendo mi búsqueda para revisar varios resultados sin volver a escribirla.
- H5: Como usuario quiero saber cuántas notas coinciden y enterarme claramente cuando ninguna lo hace para no pensar que la app falló.
- H6: Como usuario de VoiceOver quiero oír cuántos resultados hay sin que me interrumpan con cada letra que escribo.

## Requisitos funcionales (criterios de aceptación en EARS)

**Búsqueda al escribir**
- RF-1: CUANDO el usuario escriba en el buscador, EL SISTEMA mostrará en la cuadrícula de "Mis notas" solo las notas que coincidan con el texto buscado.
- RF-2: EL SISTEMA mostrará los resultados en la misma pantalla "Mis notas", sin pedir confirmación ni abrir otra pantalla.
- RF-3: CUANDO el usuario modifique o borre caracteres del texto buscado, EL SISTEMA actualizará los resultados para reflejar el texto nuevo.
- RF-4: MIENTRAS el buscador esté vacío o contenga solo espacios, EL SISTEMA mostrará todas las notas como si no hubiera búsqueda.

**Dónde se busca**
- RF-5: EL SISTEMA considerará que una nota coincide cuando el texto buscado aparezca en su título o en su contenido.
- RF-6: EL SISTEMA considerará parte del contenido el texto de cada tarea de la nota, esté completada o pendiente.
- RF-7: EL SISTEMA no considerará como coincidencia el nombre de la categoría, el color ni la fecha de la nota.

**Coincidencia flexible**
- RF-8: EL SISTEMA ignorará la diferencia entre mayúsculas y minúsculas al comparar, incluidas "Ñ" y "ñ".
- RF-9: EL SISTEMA ignorará las tildes y la diéresis al comparar (por ejemplo, "reunion" coincide con "Reunión" y "pinguino" con "pingüino").
- RF-10: EL SISTEMA tratará la "ñ" como una letra distinta de la "n" (por ejemplo, "ano" no coincide con "año").
- RF-11: EL SISTEMA considerará coincidencia una parte de una palabra (por ejemplo, "reun" coincide con "reunión").
- RF-12: CUANDO el texto buscado tenga varias palabras, EL SISTEMA mostrará solo las notas que contengan todas esas palabras, en cualquier orden y repartidas entre el título y el contenido.
- RF-13: EL SISTEMA ignorará los espacios al inicio, al final y repetidos entre palabras del texto buscado.

**Orden de los resultados**
- RF-14: EL SISTEMA ordenará los resultados con el mismo criterio que "Mis notas" sin búsqueda: primero las fijadas y después el resto, cada grupo de la última editada a la más antigua (RF-10 y RF-11 de la spec 001).

**Número de resultados**
- RF-15: MIENTRAS haya texto en el buscador, EL SISTEMA mostrará bajo el título el número de notas que coinciden ("1 resultado", "3 resultados") en lugar del contador habitual ("6 notas · un espacio para tus ideas").
- RF-16: SI ninguna nota coincide, ENTONCES EL SISTEMA mostrará bajo el título "0 resultados".
- RF-17: CUANDO el usuario vacíe el buscador, EL SISTEMA volverá a mostrar el contador habitual bajo el título.

**Sin resultados**
- RF-18: SI ninguna nota coincide con el texto buscado, ENTONCES EL SISTEMA mostrará en lugar de la cuadrícula el mensaje "No hay notas que coincidan con «texto»", con el texto buscado sin los espacios exteriores.
- RF-19: SI ninguna nota coincide con el texto buscado, ENTONCES EL SISTEMA no mostrará el mensaje "Aún no tienes notas. Crea la primera." (RF-24 de la spec 003).

**Limpiar la búsqueda**
- RF-20: MIENTRAS haya texto en el buscador, EL SISTEMA mostrará dentro del buscador un botón para borrarlo.
- RF-21: CUANDO el usuario toque el botón de borrar, EL SISTEMA vaciará el buscador.
- RF-22: CUANDO el usuario toque el botón de borrar, EL SISTEMA volverá a mostrar todas las notas.

**Teclado**
- RF-23: CUANDO el usuario toque la tecla "Buscar" del teclado, EL SISTEMA ocultará el teclado sin cambiar el texto buscado ni los resultados.
- RF-24: CUANDO el usuario desplace la cuadrícula de resultados, EL SISTEMA ocultará el teclado sin cambiar el texto buscado ni los resultados.

**Conservar la búsqueda**
- RF-25: CUANDO el usuario abra una nota desde los resultados y vuelva a "Mis notas", EL SISTEMA conservará el texto buscado.
- RF-26: CUANDO el usuario vuelva a "Mis notas" tras editar una nota, EL SISTEMA recalculará los resultados con el contenido actual de las notas.
- RF-27: CUANDO el usuario vuelva a "Mis notas" tras crear una nota nueva con una búsqueda activa, EL SISTEMA la mostrará en los resultados solo si coincide con el texto buscado.
- RF-28: CUANDO el usuario vuelva a "Mis notas" tras eliminar una nota con una búsqueda activa, EL SISTEMA conservará el texto buscado y dejará de mostrar esa nota en los resultados.
- RF-29: CUANDO el usuario recupere con "Deshacer" una nota eliminada durante una búsqueda, EL SISTEMA la mostrará en los resultados solo si coincide con el texto buscado.
- RF-30: CUANDO el usuario vuelva a la app después de que el sistema la cerrara en segundo plano, EL SISTEMA mostrará en el buscador el mismo texto buscado que había antes del cierre.
- RF-31: CUANDO el usuario abra la app después de haberla cerrado él mismo desde el selector de apps, EL SISTEMA mostrará "Mis notas" sin búsqueda.

**Buscador sin notas, cargando o con error**
- RF-32: MIENTRAS no haya ninguna nota, EL SISTEMA mostrará el buscador deshabilitado.
- RF-33: SI el usuario elimina la última nota con una búsqueda activa, ENTONCES EL SISTEMA vaciará el buscador.
- RF-34: CUANDO pase a haber al menos una nota, EL SISTEMA habilitará el buscador.
- RF-35: MIENTRAS las notas se estén cargando, EL SISTEMA mostrará el buscador deshabilitado.
- RF-36: MIENTRAS se muestre el mensaje de error de carga (RF-35 de la spec 001), EL SISTEMA mostrará el buscador deshabilitado.
- RF-37: MIENTRAS el buscador esté deshabilitado por carga o por error de carga, EL SISTEMA conservará el texto buscado que hubiera.
- RF-38: CUANDO las notas terminen de cargarse, EL SISTEMA aplicará el texto buscado conservado a los resultados.

**Filtros**
- RF-39: MIENTRAS haya texto en el buscador, EL SISTEMA mostrará los filtros "Todas", "Trabajo" y "Personal" con el mismo aspecto que sin búsqueda y sin función, como establece RF-31 de la spec 001.

**Accesibilidad**
- RF-40: CUANDO VoiceOver enfoque el buscador, EL SISTEMA leerá "Buscar en tus notas" y el texto buscado, si lo hay.
- RF-41: CUANDO VoiceOver enfoque el botón de borrar, EL SISTEMA leerá "Borrar búsqueda".
- RF-42: CUANDO el usuario deje de cambiar el texto buscado durante 1 segundo, EL SISTEMA anunciará a VoiceOver el número de resultados ("3 resultados").
- RF-43: SI ninguna nota coincide cuando el usuario deja de cambiar el texto buscado durante 1 segundo, ENTONCES EL SISTEMA anunciará a VoiceOver el mensaje de RF-18 en lugar del número de resultados.
- RF-44: MIENTRAS el usuario siga cambiando el texto buscado con pausas de menos de 1 segundo, EL SISTEMA no anunciará resultados a VoiceOver.
- RF-45: CUANDO el usuario cambie el tamaño de texto del sistema, EL SISTEMA ajustará el tamaño del texto del buscador, del número de resultados y del mensaje de sin resultados.

## Requisitos no funcionales
- Plataformas: iPhone y iPad con iOS 27 o posterior.
- Rapidez: con hasta 1 000 notas guardadas, los resultados se ven en menos de 300 ms desde la última tecla pulsada.
- Fluidez: escribir en el buscador no congela la pantalla ni pierde caracteres.
- Privacidad: la búsqueda ocurre solo en el dispositivo. El texto buscado no se envía a ningún servicio ni se guarda como historial, salvo para RF-30.
- Sin conexión: la búsqueda funciona sin internet.
- Apariencia: el buscador mantiene el diseño del Figma ("Inicio · Mis notas"). El botón de borrar, el número de resultados y el mensaje de sin resultados no tienen diseño de referencia: usan los colores y la tipografía de la app. Todo sigue el modo claro u oscuro del dispositivo.
- Idioma: todos los textos visibles nuevos en español, con singular y plural correctos.

## Casos límite
- Texto con solo espacios: se comporta como buscador vacío (RF-4).
- Texto con signos, números o emojis: se busca tal cual, sin error.
- Texto muy largo (por ejemplo, un párrafo pegado): la app no se bloquea; lo normal es que no haya resultados (RF-18).
- Nota sin título, solo con contenido (o al revés): puede coincidir por el campo que sí tiene (RF-5).
- Nota con lista de tareas: coincide por el texto de cualquiera de sus tareas, completada o pendiente (RF-6).
- "ñ" frente a "n": "año" no coincide con "ano", pero "AÑO" sí coincide con "año" (RF-8, RF-10).
- El usuario no tiene ninguna nota: buscador deshabilitado y mensaje "Aún no tienes notas. Crea la primera." (RF-32, RF-19).
- Con una búsqueda activa, el usuario elimina la última nota: se muestra el mensaje de lista vacía y el buscador se vacía y se deshabilita (RF-32, RF-33). Si toca "Deshacer", vuelve la nota y el buscador se habilita, vacío (RF-34).
- Con una búsqueda activa, el usuario elimina una nota y toca "Deshacer": la nota vuelve a los resultados solo si coincide (RF-29).
- Con una búsqueda activa, el usuario edita un resultado y deja de coincidir: al volver ya no aparece (RF-26).
- Con una búsqueda activa, el usuario crea una nota nueva: al volver aparece solo si coincide (RF-27).
- La app se abre tras un cierre del sistema con búsqueda guardada: el buscador muestra el texto deshabilitado mientras cargan las notas y los resultados aparecen al terminar la carga (RF-30, RF-35, RF-37, RF-38).
- Falla la carga con una búsqueda activa: mensaje de error y buscador deshabilitado con el texto conservado; al reintentar con éxito, se aplica la búsqueda (RF-36 a RF-38).
- El usuario escribe rápido con VoiceOver activo: solo se anuncia el resultado tras 1 segundo sin cambios (RF-42, RF-44).

## Fuera de alcance
- Buscar por categoría, color o fecha.
- Hacer funcionar los filtros "Todas", "Trabajo" y "Personal", o combinarlos con la búsqueda (irá en la spec de filtros).
- Asignar a una nota nueva la categoría del filtro seleccionado.
- Resaltar el texto coincidente dentro de las tarjetas.
- Historial o sugerencias de búsquedas recientes.
- Recordar la búsqueda después de que el usuario cierre la app él mismo.
- Búsqueda tolerante a errores de escritura (por ejemplo, "reunoin" → "reunión").
- Crear una nota a partir del texto buscado desde el mensaje de sin resultados.
- Una pantalla de búsqueda separada.
- Buscar dentro del editor de una nota.
- Ordenar los resultados por relevancia.
- Cambiar el orden de "Mis notas" (la etiqueta y el botón de orden siguen sin función).
- Sincronización entre dispositivos o con la nube.

## Criterios de finalización
- Todos los RF con prueba en verde (unitarias y de UI). RF-30 y RF-31 se comprueban también a mano.
- Los casos límite tienen prueba.
- La rapidez con 1 000 notas se respalda con el diseño y una comprobación manual con las notas existentes; no se mide con 1 000 notas.
- La app compila sin errores.
- El agente `architecture-reviewer` responde "Sin violaciones de arquitectura".
- Demo manual en el simulador de iPhone, en modo claro y oscuro: buscar y ver el número de resultados; buscar sin acentos y en mayúsculas; buscar por una tarea de "La compra"; abrir un resultado y volver con la búsqueda conservada; borrar la búsqueda; ver el mensaje de sin resultados; desplazar los resultados con el teclado abierto; repetir una búsqueda con VoiceOver activo.
- Demo manual en iPad, si para entonces hay un simulador de iPad disponible.

## Dudas abiertas
Ninguna. Las 6 dudas de la adaptación desde Android se resolvieron con el usuario el 2026-11-27: filtros sin cambios, búsqueda en tareas, restaurar la búsqueda tras un cierre del sistema, buscador deshabilitado al cargar o con error, cuándo se oculta el teclado y cuándo anuncia VoiceOver.
