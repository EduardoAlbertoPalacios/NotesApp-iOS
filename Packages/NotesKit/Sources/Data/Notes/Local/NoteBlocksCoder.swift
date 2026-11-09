import Common
import Domain
import Foundation

/// Codifica `[NoteBlock]` como JSON para guardarlo en `NoteEntity.blocksData`.
enum NoteBlocksCoder {
    private struct BlockDTO: Codable {
        enum Kind: String, Codable {
            case text
            case task
        }

        let kind: Kind
        let text: String
        let isDone: Bool?
    }

    static func encode(_ blocks: [NoteBlock]) throws(AppError) -> Data {
        let dtos = blocks.map { block -> BlockDTO in
            switch block {
            case .text(let text):
                BlockDTO(kind: .text, text: text, isDone: nil)
            case .task(let task):
                BlockDTO(kind: .task, text: task.text, isDone: task.isDone)
            }
        }
        do {
            return try JSONEncoder().encode(dtos)
        } catch {
            // Límite con Foundation: JSONEncoder lanza `any Error`; se traduce a AppError.
            throw .corruptedData
        }
    }

    static func decode(_ data: Data) throws(AppError) -> [NoteBlock] {
        let dtos: [BlockDTO]
        do {
            dtos = try JSONDecoder().decode([BlockDTO].self, from: data)
        } catch {
            // Límite con Foundation: JSONDecoder lanza `any Error`; se traduce a AppError.
            throw .corruptedData
        }
        return dtos.map { dto in
            switch dto.kind {
            case .text:
                .text(dto.text)
            case .task:
                .task(NoteTask(text: dto.text, isDone: dto.isDone ?? false))
            }
        }
    }
}
