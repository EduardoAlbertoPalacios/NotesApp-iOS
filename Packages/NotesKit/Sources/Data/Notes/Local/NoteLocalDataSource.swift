import Common
import Domain
import Foundation
import SwiftData

/// Único punto de acceso a SwiftData para las notas. Todo el trabajo con `ModelContext`
/// ocurre en este actor, fuera del hilo principal; hacia fuera solo salen modelos de dominio.
@ModelActor
actor NoteLocalDataSource {
    func fetchAll() throws(AppError) -> [Note] {
        let entities: [NoteEntity]
        do {
            entities = try modelContext.fetch(FetchDescriptor<NoteEntity>())
        } catch {
            // Límite con SwiftData: `fetch` lanza `any Error`; se traduce a AppError.
            throw .storageUnavailable
        }
        return try entities.map { (entity) throws(AppError) -> Note in
            try entity.toDomain()
        }
    }

    /// Inserta o reemplaza por `id`, en una sola operación de guardado.
    func save(_ notes: [Note]) throws(AppError) {
        do {
            for note in notes {
                let id = note.id
                var descriptor = FetchDescriptor<NoteEntity>(predicate: #Predicate { $0.id == id })
                descriptor.fetchLimit = 1
                if let existing = try modelContext.fetch(descriptor).first {
                    try existing.update(from: note)
                } else {
                    modelContext.insert(try note.toEntity())
                }
            }
            try modelContext.save()
        } catch let error as AppError {
            modelContext.rollback()
            throw error
        } catch {
            // Límite con SwiftData: `fetch`/`save` lanzan `any Error`; se traduce a AppError.
            modelContext.rollback()
            throw .storageUnavailable
        }
    }

    /// Borra la nota con ese `id`; no hace nada si no existe.
    func delete(id: UUID) throws(AppError) {
        do {
            let descriptor = FetchDescriptor<NoteEntity>(predicate: #Predicate { $0.id == id })
            for entity in try modelContext.fetch(descriptor) {
                modelContext.delete(entity)
            }
            try modelContext.save()
        } catch {
            // Límite con SwiftData: `fetch`/`save` lanzan `any Error`; se traduce a AppError.
            modelContext.rollback()
            throw .storageUnavailable
        }
    }

    /// El mayor `sequence` guardado más uno, o 0 si no hay notas.
    func nextSequence() throws(AppError) -> Int {
        var descriptor = FetchDescriptor<NoteEntity>(sortBy: [SortDescriptor(\.sequence, order: .reverse)])
        descriptor.fetchLimit = 1
        do {
            guard let last = try modelContext.fetch(descriptor).first else { return 0 }
            return last.sequence + 1
        } catch {
            // Límite con SwiftData: `fetch` lanza `any Error`; se traduce a AppError.
            throw .storageUnavailable
        }
    }
}
