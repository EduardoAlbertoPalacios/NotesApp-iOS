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

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                NoteListRoute(
                    observeNotes: container.observeNotes,
                    seedSampleNotes: container.seedSampleNotes,
                    // Provisional hasta el paso 5 del plan 002, que añade la navegación al editor.
                    onOpen: { _ in }
                )
                .toolbar(.hidden, for: .navigationBar)
            }
        }
    }
}
