import Domain
import Observation

/// Sin `NoteListEffect` ni `effects()` en esta iteración: no hay navegación ni mensajes
/// de un solo uso (excepción aprobada en el plan 001).
@MainActor
@Observable
final class NoteListViewModel {
    private(set) var state = NoteListState()
    /// Cambia con cada reintento; la Route lo usa como `id` de su `.task` para reiniciar la carga.
    private(set) var reloadToken = 0

    private let observeNotes: ObserveNotesUseCase
    private let seedSampleNotes: SeedSampleNotesUseCase

    init(observeNotes: ObserveNotesUseCase, seedSampleNotes: SeedSampleNotesUseCase) {
        self.observeNotes = observeNotes
        self.seedSampleNotes = seedSampleNotes
    }

    func send(_ intent: NoteListIntent) {
        switch intent {
        case .retryTapped:
            reloadToken &+= 1
        }
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
