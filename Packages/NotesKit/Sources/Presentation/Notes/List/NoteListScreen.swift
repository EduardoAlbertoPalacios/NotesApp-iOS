import Domain
import SwiftUI

/// Vista sin estado de "Mis notas". Los controles de búsqueda, filtros, orden y ajustes se dibujan
/// como vistas estáticas: no tienen función todavía (spec 001, RF-29 a RF-31). "Nueva nota" y las
/// tarjetas abren el editor (spec 002, RF-1 y RF-4).
struct NoteListScreen: View {
    let state: NoteListState
    let now: Date
    let isPad: Bool
    let onIntent: (NoteListIntent) -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private let dateFormatter = NoteDateFormatter()

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    searchField
                    filters
                    content(isLandscape: proxy.size.width > proxy.size.height)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 112)
            }
            // En el ScrollView y no en el contenedor: si no, sustituye el identificador de "Nueva nota".
            .accessibilityIdentifier(NoteListAccessibilityID.screen)
            .overlay(alignment: .bottomTrailing) { newNoteButton }
        }
        .background(Palette.background.ignoresSafeArea())
    }

    // MARK: - Cabecera y controles

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Mis notas", bundle: .module)
                    .font(.largeTitle.bold())
                    .foregroundStyle(Palette.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                if state.loadError == nil, !state.isLoading {
                    Text(NoteListStrings.counter(state.notes.count))
                        .font(.subheadline)
                        .foregroundStyle(Palette.textSecondary)
                        .accessibilityIdentifier(NoteListAccessibilityID.counter)
                }
            }
            Spacer()
            Image(systemName: "gearshape")
                .font(.title3)
                .foregroundStyle(Palette.textPrimary)
                .frame(width: 48, height: 48)
                .background(Palette.surface, in: Circle())
                .accessibilityHidden(true)
                .accessibilityIdentifier(NoteListAccessibilityID.settingsButton)
        }
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
            Text("Buscar en tus notas", bundle: .module)
            Spacer()
        }
        .font(.body)
        .foregroundStyle(Palette.textSecondary)
        .padding(.horizontal, 18)
        .frame(minHeight: 50)
        .background(Palette.surface, in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(NoteListAccessibilityID.searchField)
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 8) {
                chip("Todas", isSelected: true, id: NoteListAccessibilityID.filterAll)
                chip("Trabajo", isSelected: false, id: NoteListAccessibilityID.filterWork)
                chip("Personal", isSelected: false, id: NoteListAccessibilityID.filterPersonal)
            }
            HStack {
                Text("Última edición", bundle: .module)
                    .font(.footnote)
                    .foregroundStyle(Palette.textSecondary)
                Spacer()
                Image(systemName: "arrow.up.arrow.down")
                    .font(.footnote)
                    .foregroundStyle(Palette.textSecondary)
                    .accessibilityHidden(true)
                    .accessibilityIdentifier(NoteListAccessibilityID.sortButton)
            }
        }
    }

    private func chip(_ title: LocalizedStringKey, isSelected: Bool, id: String) -> some View {
        Text(title, bundle: .module)
            .font(.subheadline.weight(isSelected ? .semibold : .regular))
            .foregroundStyle(isSelected ? Palette.onCard : Palette.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Palette.accent : Palette.surface, in: Capsule())
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityIdentifier(id)
    }

    private var newNoteButton: some View {
        Button {
            onIntent(.newNoteTapped)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                Text("Nueva nota", bundle: .module)
            }
            .font(.headline)
            .foregroundStyle(Palette.onCard)
            .padding(.horizontal, 24)
            .frame(minHeight: 60)
            .background(Palette.accent, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 24)
        .padding(.bottom, 16)
        .accessibilityIdentifier(NoteListAccessibilityID.newNoteButton)
    }

    // MARK: - Contenido

    @ViewBuilder
    private func content(isLandscape: Bool) -> some View {
        if state.loadError != nil {
            errorView
        } else if state.isLoading {
            ProgressView {
                Text("Cargando notas", bundle: .module)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
            .accessibilityIdentifier(NoteListAccessibilityID.loading)
        } else {
            AlternatingColumnsLayout(
                columns: GridColumns.count(
                    isPad: isPad,
                    isRegularWidth: horizontalSizeClass == .regular,
                    isLandscape: isLandscape
                ),
                spacing: 12
            ) {
                ForEach(state.notes) { note in
                    Button {
                        onIntent(.noteTapped(note))
                    } label: {
                        NoteCardView(note: note, dateText: dateFormatter.string(for: note.updatedAt, now: now))
                    }
                    .buttonStyle(.plain)
                    // En el botón: es el elemento que ven VoiceOver y las pruebas de UI.
                    .accessibilityIdentifier(NoteListAccessibilityID.card)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(NoteListAccessibilityID.grid)
        }
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            Text("No pudimos cargar tus notas.", bundle: .module)
                .font(.body)
                .foregroundStyle(Palette.textPrimary)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier(NoteListAccessibilityID.error)
            Button {
                onIntent(.retryTapped)
            } label: {
                Text("Reintentar", bundle: .module)
                    .font(.headline)
                    .foregroundStyle(Palette.onCard)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Palette.accent, in: Capsule())
            }
            .accessibilityIdentifier(NoteListAccessibilityID.retryButton)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

// MARK: - Previews

private enum PreviewData {
    static let now = Date(timeIntervalSince1970: 1_793_354_280) // 9 nov 2026, 09:38 UTC aprox.

    /// Notas de ejemplo con fechas variadas para parecerse al Figma.
    static var notes: [Note] {
        let day: TimeInterval = 86_400
        let offsets: [TimeInterval] = [0, -5_000, -day, -day - 3_600, -36 * day, -37 * day]
        return zip(SampleNotes.make(now: now), offsets).map { note, offset in
            var note = note
            note.updatedAt = now.addingTimeInterval(offset)
            return note
        }
    }

    static let loaded = NoteListState(isLoading: false, notes: notes)
}

#Preview("Con notas") {
    NoteListScreen(state: PreviewData.loaded, now: PreviewData.now, isPad: false, onIntent: { _ in })
}

#Preview("Con notas · oscuro") {
    NoteListScreen(state: PreviewData.loaded, now: PreviewData.now, isPad: false, onIntent: { _ in })
        .preferredColorScheme(.dark)
}

#Preview("Cargando") {
    NoteListScreen(state: NoteListState(), now: PreviewData.now, isPad: false, onIntent: { _ in })
}

/// No puede ocurrir en la spec 001 (no se borran notas), pero `CLAUDE.md` pide una preview por estado.
#Preview("Vacío") {
    NoteListScreen(state: NoteListState(isLoading: false), now: PreviewData.now, isPad: false, onIntent: { _ in })
}

#Preview("Error") {
    NoteListScreen(
        state: NoteListState(isLoading: false, loadError: .loadFailed),
        now: PreviewData.now,
        isPad: false,
        onIntent: { _ in }
    )
}

#Preview("Texto grande") {
    NoteListScreen(state: PreviewData.loaded, now: PreviewData.now, isPad: false, onIntent: { _ in })
        .dynamicTypeSize(.accessibility2)
}

#Preview("iPad vertical", traits: .portrait) {
    NoteListScreen(state: PreviewData.loaded, now: PreviewData.now, isPad: true, onIntent: { _ in })
        .environment(\.horizontalSizeClass, .regular)
}

#Preview("iPad horizontal", traits: .landscapeLeft) {
    NoteListScreen(state: PreviewData.loaded, now: PreviewData.now, isPad: true, onIntent: { _ in })
        .environment(\.horizontalSizeClass, .regular)
}
