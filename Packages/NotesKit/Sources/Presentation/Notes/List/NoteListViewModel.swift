import Domain
import Foundation
import Observation

@MainActor
@Observable
final class NoteListViewModel {
    /// Tiempo que se muestra el aviso tras eliminar, con VoiceOver desactivado (spec 003, RF-12).
    static let bannerDuration: Duration = .seconds(5)
    /// Tiempo sin cambios en el buscador antes de anunciar el resultado a VoiceOver (spec 004, RF-42).
    static let announcementDelay: Duration = .seconds(1)

    private(set) var state = NoteListState()
    /// Cambia con cada reintento; la Route lo usa como `id` de su `.task` para reiniciar la carga.
    private(set) var reloadToken = 0
    @ObservationIgnored private var effectContinuation: AsyncStream<NoteListEffect>.Continuation?
    /// Última eliminación recibida: la misma no vuelve a mostrar el aviso.
    @ObservationIgnored private var lastDeletionID: UUID?
    @ObservationIgnored private var isVoiceOverRunning = false
    @ObservationIgnored private var bannerTimeout: Task<Void, Never>?
    @ObservationIgnored private var pendingAnnouncement: Task<Void, Never>?

    private let observeNotes: ObserveNotesUseCase
    private let seedSampleNotes: SeedSampleNotesUseCase
    private let restoreNote: RestoreNoteUseCase
    private let clock: any Clock<Duration>

    init(
        observeNotes: ObserveNotesUseCase,
        seedSampleNotes: SeedSampleNotesUseCase,
        restoreNote: RestoreNoteUseCase,
        clock: any Clock<Duration>
    ) {
        self.observeNotes = observeNotes
        self.seedSampleNotes = seedSampleNotes
        self.restoreNote = restoreNote
        self.clock = clock
    }

    /// Crea un stream nuevo por suscripción (ver `CLAUDE.md`).
    func effects() -> AsyncStream<NoteListEffect> {
        effectContinuation?.finish()
        let (stream, continuation) = AsyncStream.makeStream(of: NoteListEffect.self)
        effectContinuation = continuation
        return stream
    }

    func send(_ intent: NoteListIntent) {
        switch intent {
        case .retryTapped:
            reloadToken &+= 1
        case .newNoteTapped:
            // Abrir otra pantalla deja la eliminación como definitiva (spec 003, RF-20, RF-21).
            hideBanner()
            emit(.open(.newNote))
        case .noteTapped(let note):
            hideBanner()
            emit(.open(.note(note)))
        case .noteDeleted(let deletion):
            guard deletion.id != lastDeletionID else { return }
            lastDeletionID = deletion.id
            showBanner(.deleted(deletion.note))
        case .undoTapped:
            guard case .deleted(let note) = state.banner else { return }
            hideBanner()
            Task { await restore(note) }
        case .voiceOverChanged(let isRunning):
            guard isRunning != isVoiceOverRunning else { return }
            isVoiceOverRunning = isRunning
            // Al desactivar VoiceOver, el aviso visible empieza una espera nueva de 5 s.
            if state.banner != nil { scheduleBannerTimeout() }
        case .movedToBackground:
            hideBanner()
        case .searchTextChanged(let text):
            // Se acepta también cargando o con error: se aplica al llegar las notas (spec 004, RF-37, RF-38).
            guard text != state.searchText else { return }
            setSearchText(text)
        case .clearSearchTapped:
            guard !state.searchText.isEmpty else { return }
            setSearchText("")
        }
    }

    // MARK: - Búsqueda (spec 004)

    private func setSearchText(_ text: String) {
        state.searchText = text
        updateResults()
        scheduleAnnouncement()
    }

    /// Vuelve a filtrar con el texto y las notas actuales (RF-1, RF-3, RF-26 a RF-29).
    private func updateResults() {
        state.results = state.isSearching ? NoteSearch.filter(state.notes, query: state.searchText) : []
    }

    /// Cada cambio reinicia la espera: solo se anuncia tras 1 s sin cambios (RF-42 a RF-44).
    private func scheduleAnnouncement() {
        pendingAnnouncement?.cancel()
        pendingAnnouncement = nil
        guard state.isSearching else { return }
        let clock = clock
        pendingAnnouncement = Task { [weak self] in
            // `try?` justificado: `Clock.sleep` no usa typed throws y solo falla al cancelarse
            // (el texto volvió a cambiar), lo que se comprueba justo después.
            try? await clock.sleep(for: Self.announcementDelay)
            guard !Task.isCancelled else { return }
            self?.announceResults()
        }
    }

    private func announceResults() {
        // Sin notas cargadas no hay resultado que anunciar (buscador deshabilitado, RF-32 a RF-36).
        guard state.isSearching, state.isSearchEnabled else { return }
        if state.hasNoResults {
            emit(.announce(.noMatches(state.searchText.trimmingCharacters(in: .whitespacesAndNewlines))))
        } else {
            emit(.announce(.results(state.results.count)))
        }
    }

    // MARK: - Aviso tras eliminar (spec 003)

    private func restore(_ note: Note) async {
        do {
            try await restoreNote(note)
        } catch {
            // `error` es `AppError` (typed throws): mensaje sin detalles técnicos y la nota se da por perdida (RF-30, RF-31).
            showBanner(.restoreFailed)
        }
    }

    private func showBanner(_ banner: NoteListBanner) {
        state.banner = banner
        scheduleBannerTimeout()
    }

    /// Ocultar el aviso descarta la copia: la eliminación queda definitiva (RF-14, RF-23).
    private func hideBanner() {
        bannerTimeout?.cancel()
        bannerTimeout = nil
        state.banner = nil
    }

    /// Con VoiceOver activo el aviso no caduca (RF-13); si no, se oculta a los 5 s (RF-12).
    private func scheduleBannerTimeout() {
        bannerTimeout?.cancel()
        bannerTimeout = nil
        guard !isVoiceOverRunning else { return }
        let clock = clock
        bannerTimeout = Task { [weak self] in
            // `try?` justificado: `Clock.sleep` no usa typed throws y solo falla al cancelarse
            // (el aviso cambió o se ocultó antes), lo que se comprueba justo después.
            try? await clock.sleep(for: Self.bannerDuration)
            guard !Task.isCancelled else { return }
            self?.hideBanner()
        }
    }

    private func emit(_ effect: NoteListEffect) {
        effectContinuation?.yield(effect)
    }

    /// Siembra las notas de ejemplo si hace falta y observa las notas hasta que se cancele la tarea.
    func start() async {
        state.isLoading = true
        state.loadError = nil
        do {
            try await seedSampleNotes()
        } catch {
            // `error` es `AppError` (typed throws). Una cancelación no se muestra como error.
            guard !Task.isCancelled else { return }
            showLoadError()
            return
        }
        for await result in observeNotes() {
            switch result {
            case .success(let notes):
                state.notes = notes
                state.isLoading = false
                state.loadError = nil
                // Sin notas, el buscador se deshabilita: un texto que no se puede borrar no se conserva (RF-33).
                if notes.isEmpty, !state.searchText.isEmpty {
                    state.searchText = ""
                    pendingAnnouncement?.cancel()
                    pendingAnnouncement = nil
                }
                updateResults()
            case .failure:
                guard !Task.isCancelled else { return }
                showLoadError()
            }
        }
    }

    private func showLoadError() {
        state.isLoading = false
        state.loadError = .loadFailed
    }
}
