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

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $path) {
                NoteListRoute(
                    observeNotes: container.observeNotes,
                    seedSampleNotes: container.seedSampleNotes,
                    onOpen: { path.append($0) }
                )
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: NotesDestination.self) { destination in
                    NoteEditorRoute(
                        destination: destination,
                        saveNote: container.saveNote,
                        deleteNote: container.deleteNote,
                        // Se conecta con "Mis notas" en el paso 4 del plan 003 (T-24).
                        onDeleted: { _ in }
                    )
                }
            }
        }
    }
}
