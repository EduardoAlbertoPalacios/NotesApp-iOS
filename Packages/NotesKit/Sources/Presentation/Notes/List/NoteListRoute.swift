import Domain
import SwiftUI
import UIKit

/// Pantalla "Mis notas" (spec 001). Es lo único público de la feature.
public struct NoteListRoute: View {
    @State private var viewModel: NoteListViewModel
    @Environment(\.accessibilityVoiceOverEnabled) private var isVoiceOverEnabled
    @Environment(\.scenePhase) private var scenePhase
    /// iOS lo restaura si el sistema cerró la app en segundo plano y lo descarta si la cerró
    /// el usuario desde el selector de apps (spec 004, RF-30, RF-31).
    @SceneStorage("noteList.searchText") private var storedSearchText = ""
    private let deletion: NoteDeletion?
    private let onOpen: @MainActor (NotesDestination) -> Void

    /// - Parameters:
    ///   - deletion: última nota eliminada en el editor, para ofrecer "Deshacer" (spec 003).
    ///   - onOpen: abre el destino pedido (editor de nota nueva o existente, spec 002).
    public init(
        observeNotes: ObserveNotesUseCase,
        seedSampleNotes: SeedSampleNotesUseCase,
        restoreNote: RestoreNoteUseCase,
        deletion: NoteDeletion? = nil,
        clock: any Clock<Duration> = ContinuousClock(),
        onOpen: @escaping @MainActor (NotesDestination) -> Void
    ) {
        _viewModel = State(
            initialValue: NoteListViewModel(
                observeNotes: observeNotes,
                seedSampleNotes: seedSampleNotes,
                restoreNote: restoreNote,
                clock: clock
            )
        )
        self.deletion = deletion
        self.onOpen = onOpen
    }

    public var body: some View {
        // Se reevalúa cada minuto para que "Hoy"/"Ayer" cambien al pasar la medianoche.
        TimelineView(.everyMinute) { context in
            NoteListScreen(
                state: viewModel.state,
                now: context.date,
                isPad: UIDevice.current.userInterfaceIdiom == .pad,
                onIntent: { viewModel.send($0) }
            )
        }
        // Antes que `deletion`, para que el aviso ya sepa si VoiceOver está activo.
        .onChange(of: isVoiceOverEnabled, initial: true) { _, isEnabled in
            viewModel.send(.voiceOverChanged(isEnabled))
        }
        .onChange(of: deletion, initial: true) { _, deletion in
            if let deletion { viewModel.send(.noteDeleted(deletion)) }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { viewModel.send(.movedToBackground) }
        }
        .onAppear {
            // Al volver del editor ya coinciden y el ViewModel lo ignora.
            if !storedSearchText.isEmpty { viewModel.send(.searchTextChanged(storedSearchText)) }
        }
        .onChange(of: viewModel.state.searchText) { _, text in
            storedSearchText = text
        }
        .task(id: viewModel.reloadToken) {
            await viewModel.start()
        }
        .task {
            for await effect in viewModel.effects() {
                switch effect {
                case .open(let destination):
                    onOpen(destination)
                case .announce(let announcement):
                    AccessibilityNotification.Announcement(NoteListStrings.announcement(announcement)).post()
                }
            }
        }
    }
}
