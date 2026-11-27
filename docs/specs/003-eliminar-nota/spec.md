# Spec 003 — Eliminar notas

## Contexto y objetivo
Tras la spec 002 el usuario puede crear y editar notas, pero no puede quitar las que ya no le sirven: el botón de menú (⋯) del editor se ve pero no hace nada, y la única forma de que una nota desaparezca es dejar vacía una nota nueva (RF-32 y RF-33 de la spec 002). Esta iteración añade la opción "Eliminar nota" al menú ⋯ del editor. La eliminación no pide confirmación; a cambio, al volver a "Mis notas" aparece un aviso con la opción "Deshacer", que recupera la nota exactamente como estaba, para que un toque por error no cueste una nota. Como ahora se pueden eliminar todas las notas, "Mis notas" también necesita un estado vacío.

## Usuarios / actores
- Persona que usa la app en iPhone o iPad para guardar notas personales y de trabajo.

## Historias de usuario
- H1: Como usuario quiero eliminar una nota que ya no necesito para mantener mi lista ordenada.
- H2: Como usuario quiero deshacer una eliminación hecha por error para no perder la nota.
- H3: Como usuario quiero que, si la eliminación falla, la nota siga intacta y se me avise.
- H4: Como usuario quiero ver un mensaje claro cuando no tengo notas para saber qué hacer.

## Requisitos funcionales (criterios de aceptación en EARS)

**Menú ⋯ del editor**
- RF-1: CUANDO el usuario toque el botón de menú (⋯) del editor, EL SISTEMA mostrará bajo ese botón un menú con una única opción, "Eliminar nota".
- RF-2: EL SISTEMA mostrará la opción "Eliminar nota" en el color de texto normal, no en rojo.
- RF-3: CUANDO el usuario cierre el menú ⋯ sin elegir ninguna opción, EL SISTEMA lo mantendrá en el editor sin cambiar la nota.

**Eliminar**
- RF-4: CUANDO el usuario elija "Eliminar nota", EL SISTEMA eliminará la nota abierta sin pedir confirmación.
- RF-5: CUANDO el sistema elimine la nota, EL SISTEMA regresará a "Mis notas".
- RF-6: CUANDO el sistema elimine la nota, EL SISTEMA dejará de mostrarla en "Mis notas".
- RF-7: EL SISTEMA permitirá eliminar cualquier nota abierta en el editor: existente, nueva ya guardada o nueva aún sin guardar.
- RF-8: CUANDO el usuario elimine una nota con cambios que todavía no se habían guardado, EL SISTEMA no guardará esos cambios en la lista de notas.
- RF-9: SI el usuario elige "Eliminar nota" en una nota nueva con el título y el contenido vacíos, ENTONCES EL SISTEMA la descartará y regresará a "Mis notas" sin mostrar el aviso de RF-10.

**Aviso y deshacer**
- RF-10: CUANDO el sistema regrese a "Mis notas" tras eliminar una nota, EL SISTEMA mostrará en la parte inferior un aviso con el texto "Nota eliminada" y un botón "Deshacer".
- RF-11: MIENTRAS el aviso de RF-10 esté visible, EL SISTEMA permitirá desplazar y ver "Mis notas" con normalidad.
- RF-12: MIENTRAS VoiceOver esté desactivado, EL SISTEMA ocultará el aviso cuando pasen 5 segundos desde que apareció.
- RF-13: MIENTRAS VoiceOver esté activado, EL SISTEMA mantendrá el aviso visible sin límite de tiempo hasta que el usuario toque "Deshacer" o ocurra una de las acciones de RF-20 a RF-22.
- RF-14: CUANDO el aviso se oculte sin que el usuario haya tocado "Deshacer", EL SISTEMA dará la eliminación por definitiva.
- RF-15: CUANDO el usuario toque "Deshacer", EL SISTEMA ocultará el aviso.
- RF-16: CUANDO el usuario toque "Deshacer", EL SISTEMA volverá a mostrar la nota en "Mis notas".
- RF-17: CUANDO el sistema recupere una nota con "Deshacer", EL SISTEMA la restaurará con el título y el contenido que tenía en el editor justo antes de eliminarla, incluidos los cambios que aún no se habían guardado.
- RF-18: CUANDO el sistema recupere una nota con "Deshacer", EL SISTEMA conservará su fecha, su categoría, su color, sus tareas y su estado de fijada.
- RF-19: CUANDO el sistema recupere una nota con "Deshacer", EL SISTEMA la mostrará en la misma posición de "Mis notas" que ocupaba antes de eliminarla.
- RF-20: SI el usuario toca una tarjeta de nota mientras el aviso está visible, ENTONCES EL SISTEMA ocultará el aviso y dará la eliminación por definitiva.
- RF-21: SI el usuario toca "Nueva nota" mientras el aviso está visible, ENTONCES EL SISTEMA ocultará el aviso y dará la eliminación por definitiva.
- RF-22: SI la app pasa a segundo plano mientras el aviso está visible, ENTONCES EL SISTEMA ocultará el aviso y dará la eliminación por definitiva.
- RF-23: CUANDO una eliminación sea definitiva, EL SISTEMA no ofrecerá ninguna forma de recuperar la nota.

**Estado vacío de "Mis notas"**
- RF-24: MIENTRAS no haya ninguna nota, EL SISTEMA mostrará en "Mis notas" el mensaje "Aún no tienes notas. Crea la primera." en lugar de la cuadrícula.
- RF-25: MIENTRAS no haya ninguna nota, EL SISTEMA mantendrá visible el botón "Nueva nota".
- RF-26: CUANDO el usuario recupere con "Deshacer" la única nota, EL SISTEMA ocultará el mensaje de RF-24 y mostrará la nota en la cuadrícula.

**Errores**
- RF-27: SI la eliminación falla, ENTONCES EL SISTEMA mantendrá al usuario en el editor.
- RF-28: SI la eliminación falla, ENTONCES EL SISTEMA mostrará en el editor un mensaje comprensible para el usuario, sin detalles técnicos.
- RF-29: SI la eliminación falla, ENTONCES EL SISTEMA conservará la nota y lo que el usuario tenía escrito en el editor.
- RF-30: SI la recuperación con "Deshacer" falla, ENTONCES EL SISTEMA mostrará en "Mis notas" el mensaje "No se pudo recuperar la nota".
- RF-31: SI la recuperación con "Deshacer" falla, ENTONCES EL SISTEMA dará la eliminación por definitiva.

**Accesibilidad**
- RF-32: CUANDO aparezca el aviso de RF-10, EL SISTEMA anunciará "Nota eliminada" a VoiceOver.
- RF-33: CUANDO VoiceOver enfoque el botón ⋯, la opción "Eliminar nota" o el botón "Deshacer", EL SISTEMA leerá su nombre ("Más opciones", "Eliminar nota", "Deshacer").
- RF-34: CUANDO el usuario cambie el tamaño de texto del sistema, EL SISTEMA ajustará el tamaño del texto del menú ⋯, del aviso y del mensaje de estado vacío.

## Requisitos no funcionales
- Plataformas: iPhone y iPad con iOS 27 o posterior.
- Apariencia: el menú ⋯ sigue la captura de referencia de la versión Android (menú pequeño bajo el botón ⋯ con una sola opción). El aviso y el estado vacío no tienen diseño de referencia: usan los colores y la tipografía de la app. Todo sigue el modo claro u oscuro del dispositivo.
- Idioma: todos los textos visibles en español.
- Las notas se eliminan solo en el dispositivo.
- Una eliminación definitiva se mantiene aunque la app se cierre o se reinicie.

## Casos límite
- Nota nueva vacía (sin título ni contenido), aunque tenga categoría o esté fijada: se descarta sin aviso, como en RF-32 de la spec 002 (RF-9).
- Nota nueva con texto que nunca llegó a guardarse: se elimina con aviso, y "Deshacer" la recupera con lo que tenía escrito (RF-7, RF-17).
- Eliminar justo después de escribir, antes del guardado automático: lo escrito no se guarda en la lista, pero "Deshacer" lo recupera (RF-8, RF-17).
- Eliminar una nota con cambios que no se pudieron guardar (RF-38 de la spec 002): "Deshacer" la recupera con esos cambios (RF-17).
- Eliminar una nota fijada: al deshacer vuelve al grupo de fijadas, en su posición (RF-18, RF-19).
- Eliminar una nota con lista de tareas: al deshacer conserva sus tareas y su estado (RF-18).
- Dos eliminaciones seguidas: nunca hay dos avisos a la vez, porque para eliminar otra nota hay que abrirla, y al abrirla la primera eliminación ya es definitiva (RF-20).
- Eliminar la última nota: "Mis notas" muestra el estado vacío mientras el aviso está visible; si se deshace, vuelve la cuadrícula (RF-24 a RF-26).
- Con VoiceOver activo, el aviso no caduca solo (RF-13).
- La app se cierra a la fuerza con el aviso visible: la eliminación queda definitiva (RF-22, requisitos no funcionales).
- Almacenamiento no disponible al eliminar: el usuario se queda en el editor con un mensaje y la nota intacta (RF-27 a RF-29).
- Almacenamiento no disponible al deshacer: mensaje de error y la nota se pierde (RF-30, RF-31).

## Fuera de alcance
- Eliminar notas desde "Mis notas" (pulsación larga, deslizar o selección múltiple).
- Eliminar una nota existente cuando el usuario vacía su título y su contenido (sigue pendiente desde la spec 002).
- Pedir confirmación antes de eliminar.
- Papelera o "Eliminadas recientemente": una vez definitiva, la eliminación no se puede recuperar.
- Reintentar una recuperación fallida.
- Recuperar más de una eliminación a la vez.
- Cualquier otra opción del menú ⋯ distinta de "Eliminar nota".
- El botón de deshacer de la barra del editor (sigue sin función).
- Ilustraciones o botones propios en el estado vacío.
- Sincronización entre dispositivos o con la nube.

## Criterios de finalización
- Todos los RF con prueba en verde (unitarias y de UI).
- La app compila sin errores.
- El agente `architecture-reviewer` responde "Sin violaciones de arquitectura".
- Demo manual en el simulador de iPhone, en modo claro y oscuro: eliminar una nota de ejemplo y comprobar que desaparece; eliminar otra, tocar "Deshacer" y comprobar que vuelve en su sitio con su texto, categoría y estado de fijada; eliminar otra y dejar pasar 5 segundos; eliminar una nota nueva sin guardar y recuperarla; eliminar todas y ver el estado vacío; repetir una eliminación con VoiceOver activo.
- Demo manual en iPad, si para entonces hay un simulador de iPad disponible.

## Dudas abiertas
Ninguna. Las 6 dudas de la primera versión se resolvieron con el usuario el 2026-11-26.
