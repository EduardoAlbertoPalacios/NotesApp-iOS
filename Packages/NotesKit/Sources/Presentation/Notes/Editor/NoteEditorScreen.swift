import Domain
import SwiftUI

/// Vista sin estado del editor (Figma "Editor"). Compartir, el menú ⋯ y la barra inferior se
/// dibujan como vistas estáticas: no tienen función en esta iteración (RF-45, RF-46).
struct NoteEditorScreen: View {
    let state: NoteEditorState
    let now: Date
    let onIntent: (NoteEditorIntent) -> Void

    private let dateFormatter = NoteDateFormatter()

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    categorySelector
                    titleField
                    content
                    saveStatusView
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            // En el ScrollView y no en el contenedor: si no, sustituye los identificadores
            // de las barras superior e inferior (como en `NoteListScreen`).
            .accessibilityIdentifier(NoteEditorAccessibilityID.screen)
            bottomBar
        }
        .background(Palette.background.ignoresSafeArea())
        .alert(
            Text("No se pudieron guardar los cambios", bundle: .module),
            isPresented: Binding(
                get: { state.isDiscardDialogPresented },
                set: { isPresented in
                    if !isPresented, state.isDiscardDialogPresented { onIntent(.keepEditingTapped) }
                }
            )
        ) {
            Button(role: .destructive) {
                onIntent(.discardConfirmed)
            } label: {
                Text("Descartar cambios", bundle: .module)
            }
            Button(role: .cancel) {
                onIntent(.keepEditingTapped)
            } label: {
                Text("Seguir editando", bundle: .module)
            }
        } message: {
            Text("Si sales ahora, perderás lo que no se pudo guardar.", bundle: .module)
        }
    }

    // MARK: - Barra superior

    private var topBar: some View {
        HStack(spacing: 8) {
            Button {
                onIntent(.backTapped)
            } label: {
                barIcon("arrow.left")
            }
            .accessibilityLabel(Text("Volver", bundle: .module))
            .accessibilityIdentifier(NoteEditorAccessibilityID.backButton)

            Spacer()

            Button {
                onIntent(.pinTapped)
            } label: {
                barIcon(state.isPinned ? "pin.fill" : "pin")
            }
            .accessibilityLabel(Text("Fijar nota", bundle: .module))
            .accessibilityValue(
                state.isPinned ? Text("Fijada", bundle: .module) : Text("Sin fijar", bundle: .module)
            )
            .accessibilityIdentifier(NoteEditorAccessibilityID.pinButton)

            staticIcon("square.and.arrow.up", label: "Compartir", id: NoteEditorAccessibilityID.shareButton)
            staticIcon("ellipsis", label: "Más opciones", id: NoteEditorAccessibilityID.moreButton)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    private func barIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.title3)
            .foregroundStyle(Palette.textPrimary)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
    }

    /// Icono sin función: no es un `Button`, pero VoiceOver lee su función (RF-49).
    private func staticIcon(_ systemName: String, label: LocalizedStringKey, id: String) -> some View {
        barIcon(systemName)
            .accessibilityElement()
            .accessibilityLabel(Text(label, bundle: .module))
            .accessibilityIdentifier(id)
    }

    // MARK: - Cabecera y categoría

    private var header: some View {
        HStack(spacing: 10) {
            if let category = state.category {
                Text(category.title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.onCard)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Palette.accent, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityIdentifier(NoteEditorAccessibilityID.headerCategory)
            }
            Text(dateFormatter.string(for: state.headerDate, now: now))
                .font(.footnote)
                .foregroundStyle(Palette.textSecondary)
                .accessibilityIdentifier(NoteEditorAccessibilityID.headerDate)
        }
    }

    private var categorySelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categoría", bundle: .module)
                .font(.headline)
                .foregroundStyle(Palette.textPrimary)
                .accessibilityAddTraits(.isHeader)
            HStack(alignment: .top, spacing: 12) {
                ForEach(NoteCategory.allCases, id: \.self) { category in
                    categoryOption(category)
                }
            }
        }
    }

    private func categoryOption(_ category: NoteCategory) -> some View {
        let isSelected = state.category == category
        return Button {
            onIntent(.categoryTapped(category))
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(category.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? Palette.onCard : Palette.textPrimary)
                Text(category.summary)
                    .font(.footnote)
                    .foregroundStyle(isSelected ? Palette.onCard : Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(12)
            .background(
                isSelected ? Palette.accent : Palette.surface,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? Color.clear : Palette.textSecondary.opacity(0.2))
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(NoteEditorAccessibilityID.category(category))
    }

    // MARK: - Título y contenido

    private var titleField: some View {
        TextField(
            text: Binding(get: { state.title }, set: { onIntent(.titleChanged($0)) }),
            prompt: Text("Título", bundle: .module),
            axis: .vertical
        ) {
            Text("Título", bundle: .module)
        }
        .font(.largeTitle.bold())
        .foregroundStyle(Palette.textPrimary)
        .accessibilityIdentifier(NoteEditorAccessibilityID.titleField)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(state.blocks.enumerated()), id: \.offset) { index, block in
                switch block {
                case .text(let text):
                    textBlockField(index: index, text: text)
                case .task(let task):
                    taskRow(task, index: index)
                }
            }
        }
    }

    private func textBlockField(index: Int, text: String) -> some View {
        TextField(
            text: Binding(get: { text }, set: { onIntent(.textBlockChanged(index: index, text: $0)) }),
            prompt: state.isContentEmpty ? Text("Escribir nota…", bundle: .module) : nil,
            axis: .vertical
        ) {
            Text("Contenido", bundle: .module)
        }
        .font(.body)
        .foregroundStyle(Palette.textPrimary)
        .accessibilityIdentifier(NoteEditorAccessibilityID.textBlock(index))
    }

    /// Tarea de solo lectura: se ve con su casilla, pero no se marca ni se edita (RF-11, RF-12).
    private func taskRow(_ task: NoteTask, index: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: task.isDone ? "checkmark.square.fill" : "square")
                .foregroundStyle(task.isDone ? Palette.accent : Palette.textSecondary)
            Text(task.text)
                .strikethrough(task.isDone)
                .foregroundStyle(task.isDone ? Palette.textSecondary : Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.body)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(task.text))
        .accessibilityValue(
            task.isDone ? Text("completada", bundle: .module) : Text("pendiente", bundle: .module)
        )
        .accessibilityIdentifier(NoteEditorAccessibilityID.task(index))
    }

    // MARK: - Estado del guardado

    @ViewBuilder
    private var saveStatusView: some View {
        switch state.saveStatus {
        case .idle:
            EmptyView()
        case .saved:
            Label {
                Text("Todos los cambios guardados", bundle: .module)
            } icon: {
                Image(systemName: "checkmark")
            }
            .font(.caption)
            .foregroundStyle(Palette.textSecondary)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(NoteEditorAccessibilityID.saveStatus)
        case .failed:
            Label {
                Text("No se pudieron guardar los cambios. Lo que escribiste sigue aquí.", bundle: .module)
            } icon: {
                Image(systemName: "exclamationmark.triangle")
            }
            .font(.footnote)
            .foregroundStyle(Palette.textPrimary)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(NoteEditorAccessibilityID.saveError)
        }
    }

    // MARK: - Barra inferior

    private var bottomBar: some View {
        HStack {
            staticIcon("textformat", label: "Formato de texto", id: NoteEditorAccessibilityID.formatButton)
            Spacer()
            staticIcon("checklist", label: "Lista de tareas", id: NoteEditorAccessibilityID.checklistButton)
            Spacer()
            staticIcon("photo", label: "Insertar imagen", id: NoteEditorAccessibilityID.imageButton)
            Spacer()
            staticIcon("arrow.uturn.backward", label: "Deshacer", id: NoteEditorAccessibilityID.undoButton)
            Spacer()
            Circle()
                .fill(Palette.accent)
                .frame(width: 24, height: 24)
                .frame(width: 44, height: 44)
                .accessibilityElement()
                .accessibilityLabel(Text("Color de la nota", bundle: .module))
                .accessibilityIdentifier(NoteEditorAccessibilityID.colorButton)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - Previews

private enum EditorPreviewData {
    static let now = Date(timeIntervalSince1970: 1_793_354_280)
    static let samples = SampleNotes.make(now: now)

    static func state(_ destination: NotesDestination) -> NoteEditorState {
        .initial(for: destination, now: now)
    }

    static var withText: NoteEditorState {
        state(.note(samples[0]))
    }

    static var withTasks: NoteEditorState {
        let shopping = samples.first { note in
            note.blocks.contains { if case .task = $0 { true } else { false } }
        }
        return state(.note(shopping ?? samples[0]))
    }

    static var pinnedWithCategory: NoteEditorState {
        var state = withText
        state.isPinned = true
        state.category = .work
        return state
    }

    static var failed: NoteEditorState {
        var state = withText
        state.saveStatus = .failed
        return state
    }

    static var discardDialog: NoteEditorState {
        var state = failed
        state.isDiscardDialogPresented = true
        return state
    }
}

#Preview("Nota nueva vacía") {
    NoteEditorScreen(state: EditorPreviewData.state(.newNote), now: EditorPreviewData.now, onIntent: { _ in })
}

#Preview("Con texto") {
    NoteEditorScreen(state: EditorPreviewData.withText, now: EditorPreviewData.now, onIntent: { _ in })
}

#Preview("Con tareas") {
    NoteEditorScreen(state: EditorPreviewData.withTasks, now: EditorPreviewData.now, onIntent: { _ in })
}

#Preview("Fijada con categoría") {
    NoteEditorScreen(state: EditorPreviewData.pinnedWithCategory, now: EditorPreviewData.now, onIntent: { _ in })
}

#Preview("Error al guardar") {
    NoteEditorScreen(state: EditorPreviewData.failed, now: EditorPreviewData.now, onIntent: { _ in })
}

#Preview("Diálogo de descarte") {
    NoteEditorScreen(state: EditorPreviewData.discardDialog, now: EditorPreviewData.now, onIntent: { _ in })
}

#Preview("Texto grande") {
    NoteEditorScreen(state: EditorPreviewData.pinnedWithCategory, now: EditorPreviewData.now, onIntent: { _ in })
        .dynamicTypeSize(.accessibility2)
}

#Preview("Oscuro") {
    NoteEditorScreen(state: EditorPreviewData.pinnedWithCategory, now: EditorPreviewData.now, onIntent: { _ in })
        .preferredColorScheme(.dark)
}
