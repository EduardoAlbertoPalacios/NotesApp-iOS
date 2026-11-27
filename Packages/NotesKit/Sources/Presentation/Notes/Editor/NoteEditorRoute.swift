import Common
import Domain
import SwiftUI

/// Editor de notas (spec 002). Es lo único público de la feature.
public struct NoteEditorRoute: View {
    @State private var viewModel: NoteEditorViewModel
    @Environment(\.dismiss) private var dismiss
    private let onDeleted: @MainActor (Note) -> Void

    /// - Parameter onDeleted: recibe la copia de la nota eliminada, para ofrecer "Deshacer" en "Mis notas" (spec 003).
    public init(
        destination: NotesDestination,
        saveNote: SaveNoteUseCase,
        deleteNote: DeleteNoteUseCase,
        onDeleted: @escaping @MainActor (Note) -> Void,
        clock: any Clock<Duration> = ContinuousClock(),
        dateProvider: any DateProvider = SystemDateProvider()
    ) {
        _viewModel = State(
            initialValue: NoteEditorViewModel(
                destination: destination,
                saveNote: saveNote,
                deleteNote: deleteNote,
                clock: clock,
                dateProvider: dateProvider
            )
        )
        self.onDeleted = onDeleted
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
                case .deleted(let note):
                    onDeleted(note)
                    dismiss()
                }
            }
        }
    }
}
