import Domain
import SwiftUI

/// Vista sin estado de "Mis notas". Los filtros, el orden y los ajustes se dibujan como vistas
/// estáticas: no tienen función todavía (spec 001, RF-29 a RF-31). "Nueva nota" y las tarjetas abren
/// el editor (spec 002, RF-1 y RF-4). Tras eliminar una nota muestra un aviso con "Deshacer", y sin
/// notas, el estado vacío (spec 003). El buscador filtra las notas al escribir (spec 004).
struct NoteListScreen: View {
    let state: NoteListState
    let now: Date
    let isPad: Bool
    let onIntent: (NoteListIntent) -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    /// Solo el foco del teclado: el texto buscado vive en el estado del ViewModel.
    @FocusState private var isSearchFocused: Bool
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
            // Desplazar los resultados oculta el teclado sin tocar la búsqueda (spec 004, RF-24).
            // `scrollDismissesKeyboard` no suelta el foco de un campo que está dentro del propio ScrollView.
            .onScrollPhaseChange { _, phase in
                if phase == .interacting { isSearchFocused = false }
            }
            // En el ScrollView y no en el contenedor: si no, sustituye el identificador de "Nueva nota".
            .accessibilityIdentifier(NoteListAccessibilityID.screen)
            .overlay(alignment: .bottomTrailing) {
                VStack(alignment: .trailing, spacing: 12) {
                    if let banner = state.banner {
                        bannerView(banner)
                            .padding(.horizontal, 24)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    newNoteButton
                }
                .animation(.easeInOut(duration: 0.2), value: state.banner)
            }
        }
        .background(Palette.background.ignoresSafeArea())
        .onChange(of: state.banner) { _, banner in
            // Anuncio para VoiceOver al aparecer el aviso (spec 003, RF-32).
            if case .deleted = banner {
                AccessibilityNotification.Announcement(String(localized: "Nota eliminada", bundle: .module)).post()
            }
        }
    }

    // MARK: - Aviso tras eliminar (spec 003)

    /// Cápsula sobre "Nueva nota". Solo ocupa su tamaño: el resto de la pantalla se puede desplazar (RF-11).
    private func bannerView(_ banner: NoteListBanner) -> some View {
        HStack(spacing: 16) {
            switch banner {
            case .deleted:
                Text("Nota eliminada", bundle: .module)
                Spacer(minLength: 0)
                Button {
                    onIntent(.undoTapped)
                } label: {
                    Text("Deshacer", bundle: .module)
                        .fontWeight(.bold)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(NoteListAccessibilityID.undoButton)
            case .restoreFailed:
                Text("No se pudo recuperar la nota", bundle: .module)
                Spacer(minLength: 0)
            }
        }
        .font(.subheadline)
        .foregroundStyle(Palette.textPrimary)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(Palette.surface, in: Capsule())
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(NoteListAccessibilityID.undoBanner)
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
                    Text(subtitle)
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

    /// Con búsqueda, el número de resultados sustituye al contador (spec 004, RF-15 a RF-17).
    private var subtitle: String {
        state.isSearching ? NoteListStrings.results(state.results.count) : NoteListStrings.counter(state.notes.count)
    }

    /// Buscador (spec 004). El texto vive en el estado: la vista solo envía cada cambio.
    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Palette.textSecondary)
                .accessibilityHidden(true)
            TextField(
                text: Binding(
                    get: { state.searchText },
                    set: { onIntent(.searchTextChanged($0)) }
                ),
                prompt: Text("Buscar en tus notas", bundle: .module).foregroundStyle(Palette.textSecondary)
            ) {
                // Etiqueta de VoiceOver; también lee el texto buscado (RF-40).
                Text("Buscar en tus notas", bundle: .module)
            }
            .foregroundStyle(Palette.textPrimary)
            .submitLabel(.search)
            .autocorrectionDisabled()
            .focused($isSearchFocused)
            // Explícita: la etiqueta del `TextField` no llega a VoiceOver ni a XCUITest (RF-40).
            .accessibilityLabel(Text("Buscar en tus notas", bundle: .module))
            .accessibilityIdentifier(NoteListAccessibilityID.searchField)
            if !state.searchText.isEmpty {
                Button {
                    onIntent(.clearSearchTapped)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Palette.textSecondary)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Borrar búsqueda", bundle: .module))
                .accessibilityIdentifier(NoteListAccessibilityID.searchClearButton)
            }
        }
        .font(.body)
        .padding(.leading, 18)
        .padding(.trailing, state.searchText.isEmpty ? 18 : 6)
        .frame(minHeight: 50)
        .background(Palette.surface, in: Capsule())
        // Sin notas, cargando o con error no se puede buscar (RF-32, RF-35, RF-36).
        .disabled(!state.isSearchEnabled)
        .opacity(state.isSearchEnabled ? 1 : 0.6)
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
        } else if state.isEmpty {
            emptyView
        } else if state.hasNoResults {
            noResultsView
        } else {
            AlternatingColumnsLayout(
                columns: GridColumns.count(
                    isPad: isPad,
                    isRegularWidth: horizontalSizeClass == .regular,
                    isLandscape: isLandscape
                ),
                spacing: 12
            ) {
                ForEach(state.visibleNotes) { note in
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

    /// Sin notas (spec 003, RF-24); "Nueva nota" sigue visible encima (RF-25).
    private var emptyView: some View {
        VStack(spacing: 6) {
            Text("Aún no tienes notas.", bundle: .module)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Palette.textPrimary)
            Text("Crea la primera.", bundle: .module)
                .font(.body)
                .foregroundStyle(Palette.textSecondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, minHeight: 240)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(NoteListAccessibilityID.emptyState)
    }

    /// Ninguna nota coincide (spec 004, RF-18); el texto se muestra completo aunque sea largo.
    private var noResultsView: some View {
        Text(NoteListStrings.noMatches(state.searchText))
            .font(.body)
            .foregroundStyle(Palette.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 240)
            .accessibilityIdentifier(NoteListAccessibilityID.noResults)
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

    static var deletedBanner: NoteListState {
        let notes = notes
        return NoteListState(isLoading: false, notes: Array(notes.dropFirst()), banner: .deleted(notes[0]))
    }

    static var emptyWithBanner: NoteListState {
        NoteListState(isLoading: false, banner: .deleted(notes[0]))
    }

    static let restoreFailed = NoteListState(isLoading: false, notes: notes, banner: .restoreFailed)

    static func searching(_ text: String) -> NoteListState {
        let notes = notes
        return NoteListState(
            isLoading: false,
            notes: notes,
            searchText: text,
            results: NoteSearch.filter(notes, query: text)
        )
    }

    static let loadingWithSearch = NoteListState(searchText: "reunion")
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

#Preview("Vacío") {
    NoteListScreen(state: NoteListState(isLoading: false), now: PreviewData.now, isPad: false, onIntent: { _ in })
}

#Preview("Vacío · oscuro") {
    NoteListScreen(state: NoteListState(isLoading: false), now: PreviewData.now, isPad: false, onIntent: { _ in })
        .preferredColorScheme(.dark)
}

#Preview("Vacío con aviso") {
    NoteListScreen(state: PreviewData.emptyWithBanner, now: PreviewData.now, isPad: false, onIntent: { _ in })
}

#Preview("Nota eliminada") {
    NoteListScreen(state: PreviewData.deletedBanner, now: PreviewData.now, isPad: false, onIntent: { _ in })
}

#Preview("Nota eliminada · oscuro") {
    NoteListScreen(state: PreviewData.deletedBanner, now: PreviewData.now, isPad: false, onIntent: { _ in })
        .preferredColorScheme(.dark)
}

#Preview("Error al deshacer") {
    NoteListScreen(state: PreviewData.restoreFailed, now: PreviewData.now, isPad: false, onIntent: { _ in })
}

#Preview("Nota eliminada · texto grande") {
    NoteListScreen(state: PreviewData.deletedBanner, now: PreviewData.now, isPad: false, onIntent: { _ in })
        .dynamicTypeSize(.accessibility2)
}

#Preview("Buscando") {
    NoteListScreen(state: PreviewData.searching("reunion"), now: PreviewData.now, isPad: false, onIntent: { _ in })
}

#Preview("Buscando · texto grande") {
    NoteListScreen(state: PreviewData.searching("reunion"), now: PreviewData.now, isPad: false, onIntent: { _ in })
        .dynamicTypeSize(.accessibility2)
}

#Preview("Sin resultados") {
    NoteListScreen(state: PreviewData.searching("proveedores"), now: PreviewData.now, isPad: false, onIntent: { _ in })
}

#Preview("Sin resultados · oscuro") {
    NoteListScreen(state: PreviewData.searching("proveedores"), now: PreviewData.now, isPad: false, onIntent: { _ in })
        .preferredColorScheme(.dark)
}

#Preview("Cargando con búsqueda") {
    NoteListScreen(state: PreviewData.loadingWithSearch, now: PreviewData.now, isPad: false, onIntent: { _ in })
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
