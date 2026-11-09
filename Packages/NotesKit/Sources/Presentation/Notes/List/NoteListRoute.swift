import Domain
import SwiftUI
import UIKit

/// Pantalla "Mis notas" (spec 001). Es lo único público de la feature.
public struct NoteListRoute: View {
    @State private var viewModel: NoteListViewModel

    public init(observeNotes: ObserveNotesUseCase, seedSampleNotes: SeedSampleNotesUseCase) {
        _viewModel = State(
            initialValue: NoteListViewModel(observeNotes: observeNotes, seedSampleNotes: seedSampleNotes)
        )
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
    }
}
