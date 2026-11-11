import Common
import Domain
import SwiftUI

/// Editor de notas (spec 002). Es lo único público de la feature.
public struct NoteEditorRoute: View {
    @State private var viewModel: NoteEditorViewModel
    @Environment(\.dismiss) private var dismiss

    public init(
        destination: NotesDestination,
        saveNote: SaveNoteUseCase,
        clock: any Clock<Duration> = ContinuousClock(),
        dateProvider: any DateProvider = SystemDateProvider()
    ) {
        _viewModel = State(
            initialValue: NoteEditorViewModel(
                destination: destination,
                saveNote: saveNote,
                clock: clock,
                dateProvider: dateProvider
            )
        )
    }

    public var body: some View {
        // Se reevalúa cada minuto para que "Hoy"/"Ayer" de la cabecera cambien al pasar la medianoche.
        TimelineView(.everyMinute) { context in
            NoteEditorScreen(state: viewModel.state, now: context.date, onIntent: { viewModel.send($0) })
        }
        // Sin barra ni botón de volver del sistema: toda salida pasa por `.backTapped`, que guarda
        // y puede preguntar si descartar (RF-25, RF-42). Esto también desactiva el gesto de volver.
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .task {
            for await effect in viewModel.effects() {
                switch effect {
                case .close:
                    dismiss()
                }
            }
        }
    }
}
