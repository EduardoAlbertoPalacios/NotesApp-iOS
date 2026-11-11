import Common
import Domain
import Foundation
import Observation

/// Editor de una nota nueva o existente (spec 002). Guarda solo tras `autosaveDelay` sin cambios
/// y al volver; las reglas de qué se guarda viven en `SaveNoteUseCase`.
@MainActor
@Observable
final class NoteEditorViewModel {
    /// Espera sin cambios antes del guardado automático (RF-21).
    static let autosaveDelay: Duration = .seconds(1)

    private(set) var state: NoteEditorState

    @ObservationIgnored private var effectContinuation: AsyncStream<NoteEditorEffect>.Continuation?
    @ObservationIgnored private let noteID: UUID
    @ObservationIgnored private let isNew: Bool
    /// Última versión guardada; `nil` si la nota nunca se guardó (o se eliminó por quedar vacía).
    @ObservationIgnored private var lastSaved: Note?
    @ObservationIgnored private var hasUnsavedChanges = false
    @ObservationIgnored private var pendingSave: Task<Void, Never>?
    @ObservationIgnored private var isLeaving = false

    private let saveNote: SaveNoteUseCase
    private let clock: any Clock<Duration>

    init(
        destination: NotesDestination,
        saveNote: SaveNoteUseCase,
        clock: any Clock<Duration>,
        dateProvider: any DateProvider
    ) {
        self.saveNote = saveNote
        self.clock = clock
        state = .initial(for: destination, now: dateProvider.now())
        switch destination {
        case .newNote:
            noteID = UUID()
            isNew = true
            lastSaved = nil
        case .note(let note):
            noteID = note.id
            isNew = false
            lastSaved = note
        }
    }

    /// Crea un stream nuevo por suscripción (ver `CLAUDE.md`).
    func effects() -> AsyncStream<NoteEditorEffect> {
        effectContinuation?.finish()
        let (stream, continuation) = AsyncStream.makeStream(of: NoteEditorEffect.self)
        effectContinuation = continuation
        return stream
    }

    func send(_ intent: NoteEditorIntent) {
        switch intent {
        case .titleChanged(let title):
            guard title != state.title else { return }
            state.title = title
            contentChanged()
        case .textBlockChanged(let index, let text):
            guard state.blocks.indices.contains(index), case .text(let current) = state.blocks[index],
                current != text
            else { return }
            state.blocks[index] = .text(text)
            contentChanged()
        case .categoryTapped(let category):
            // Tocar la categoría ya elegida no la quita (propuesta aprobada en el plan 002).
            guard state.category != category else { return }
            state.category = category
            contentChanged()
        case .pinTapped:
            state.isPinned.toggle()
            contentChanged()
        case .backTapped:
            guard !isLeaving else { return }
            isLeaving = true
            Task { await leave() }
        case .discardConfirmed:
            state.isDiscardDialogPresented = false
            pendingSave?.cancel()
            emit(.close)
        case .keepEditingTapped:
            state.isDiscardDialogPresented = false
        }
    }

    // MARK: - Guardado

    private func contentChanged() {
        hasUnsavedChanges = true
        // Tras un fallo, el mensaje sigue visible hasta que un guardado funcione (RF-38 a RF-40).
        if state.saveStatus != .failed {
            state.saveStatus = .idle
        }
        scheduleSave()
    }

    /// Reinicia la espera: varios cambios seguidos se guardan juntos (RF-21).
    private func scheduleSave() {
        pendingSave?.cancel()
        let clock = clock
        pendingSave = Task { [weak self] in
            do {
                try await clock.sleep(for: Self.autosaveDelay)
            } catch {
                // Solo lanza `CancellationError`: llegó otro cambio o el usuario volvió. No es un error.
                return
            }
            await self?.saveNow()
        }
    }

    /// Guarda lo pendiente. Devuelve `false` si el guardado falló.
    @discardableResult
    private func saveNow() async -> Bool {
        guard hasUnsavedChanges else { return true }
        let draft = currentDraft()
        let result: NoteSaveResult
        do {
            result = try await saveNote(draft, lastSaved: lastSaved)
        } catch {
            // `error` es `AppError` (typed throws): se muestra un mensaje sin detalles técnicos.
            state.saveStatus = .failed
            return false
        }
        switch result {
        case .saved(let note):
            lastSaved = note
            state.headerDate = note.updatedAt
        case .deleted:
            lastSaved = nil
        case .skipped:
            break
        }
        // Si el usuario escribió mientras se guardaba, quedan cambios para el siguiente guardado.
        hasUnsavedChanges = draft != currentDraft()
        state.saveStatus = (hasUnsavedChanges || lastSaved == nil || draft.isBlank) ? .idle : .saved
        return true
    }

    /// Volver: guarda lo pendiente y cierra; si no se puede guardar, pregunta si descartar (RF-25, RF-42).
    private func leave() async {
        defer { isLeaving = false }
        let waiting = pendingSave
        waiting?.cancel()
        // Si la espera ya terminó y está guardando, se aguarda a que acabe para no guardar dos veces a la vez.
        await waiting?.value
        pendingSave = nil
        if await saveNow() {
            emit(.close)
        } else {
            state.isDiscardDialogPresented = true
        }
    }

    private func currentDraft() -> NoteDraft {
        NoteDraft(
            id: noteID,
            isNew: isNew,
            title: state.title,
            blocks: state.blocks,
            category: state.category,
            isPinned: state.isPinned
        )
    }

    private func emit(_ effect: NoteEditorEffect) {
        effectContinuation?.yield(effect)
    }
}

extension NoteDraft {
    /// Sin título ni contenido escrito: lo que `SaveNoteUseCase` trata como nota vacía.
    fileprivate var isBlank: Bool {
        let hasContent = blocks.contains { block in
            guard case .text(let text) = block else { return true }
            return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !hasContent
    }
}
