//
//  NotesAppApp.swift
//  NotesApp
//
//  Created by Eduardo Palacios on 09/11/26.
//

import Presentation
import SwiftUI

@main
struct NotesAppApp: App {
    private let container = AppContainer.make()
    @State private var path: [NotesDestination] = []
    /// Última nota eliminada en el editor: la lista ofrece "Deshacer" (spec 003, RF-10).
    @State private var lastDeletion: NoteDeletion?

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $path) {
                NoteListRoute(
                    observeNotes: container.observeNotes,
                    seedSampleNotes: container.seedSampleNotes,
                    restoreNote: container.restoreNote,
                    deletion: lastDeletion,
                    onOpen: { path.append($0) }
                )
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: NotesDestination.self) { destination in
                    NoteEditorRoute(
                        destination: destination,
                        saveNote: container.saveNote,
                        deleteNote: container.deleteNote,
                        onDeleted: { lastDeletion = NoteDeletion(note: $0) }
                    )
                }
            }
        }
    }
}
