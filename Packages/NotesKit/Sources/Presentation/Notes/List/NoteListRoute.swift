import Domain
import SwiftUI
import UIKit

/// Pantalla "Mis notas" (spec 001). Es lo único público de la feature.
public struct NoteListRoute: View {
    @State private var viewModel: NoteListViewModel
    private let onOpen: @MainActor (NotesDestination) -> Void

    /// - Parameter onOpen: abre el destino pedido (editor de nota nueva o existente, spec 002).
    public init(
        observeNotes: ObserveNotesUseCase,
        seedSampleNotes: SeedSampleNotesUseCase,
        onOpen: @escaping @MainActor (NotesDestination) -> Void
    ) {
        _viewModel = State(
            initialValue: NoteListViewModel(observeNotes: observeNotes, seedSampleNotes: seedSampleNotes)
        )
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
        .task(id: viewModel.reloadToken) {
            await viewModel.start()
        }
        .task {
            for await effect in viewModel.effects() {
                switch effect {
                case .open(let destination):
                    onOpen(destination)
                }
            }
        }
    }
}
