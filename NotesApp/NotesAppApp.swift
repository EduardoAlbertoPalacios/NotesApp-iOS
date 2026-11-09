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
                    seedSampleNotes: container.seedSampleNotes
                )
                .toolbar(.hidden, for: .navigationBar)
            }
        }
    }
}
