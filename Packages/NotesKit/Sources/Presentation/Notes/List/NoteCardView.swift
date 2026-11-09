import Domain
import SwiftUI

struct NoteCardView: View {
    let note: Note
    let dateText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 8) {
                Text(note.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Palette.onCard)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.footnote)
                        .foregroundStyle(Palette.onCard)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(note.blocks.enumerated()), id: \.offset) { _, block in
                    blockView(block)
                }
            }
            Text(dateText)
                .font(.caption)
                .foregroundStyle(Palette.onCardSecondary)
                .padding(.top, 8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(note.color.fill, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        // Una sola parada de VoiceOver por tarjeta, con el estado de cada tarea en la lectura (RF-40 a RF-42).
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(NoteCardAccessibility.label(for: note, dateText: dateText))
        .accessibilityIdentifier(NoteListAccessibilityID.card)
    }

    @ViewBuilder
    private func blockView(_ block: NoteBlock) -> some View {
        switch block {
        case .text(let text):
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Palette.onCard)
                .fixedSize(horizontal: false, vertical: true)
        case .task(let task):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: task.isDone ? "checkmark.square.fill" : "square")
                    .font(.subheadline)
                Text(task.text)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(Palette.onCard)
        }
    }
}

/// Texto que lee VoiceOver para una tarjeta.
enum NoteCardAccessibility {
    static func label(for note: Note, dateText: String) -> String {
        var parts = [note.title]
        if note.isPinned {
            parts.append(String(localized: "Fijada", bundle: .module))
        }
        for block in note.blocks {
            switch block {
            case .text(let text):
                parts.append(text)
            case .task(let task):
                let status = task.isDone
                    ? String(localized: "completada", bundle: .module)
                    : String(localized: "pendiente", bundle: .module)
                parts.append("\(task.text), \(status)")
            }
        }
        parts.append(dateText)
        return parts.joined(separator: ". ")
    }
}
