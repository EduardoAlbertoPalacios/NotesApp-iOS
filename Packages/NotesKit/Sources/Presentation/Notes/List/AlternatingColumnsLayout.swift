import SwiftUI

/// Número de columnas de la cuadrícula (spec 001, RF-4 a RF-7).
enum GridColumns {
    static func count(isPad: Bool, isRegularWidth: Bool, isLandscape: Bool) -> Int {
        guard isPad, isRegularWidth else { return 2 }
        return isLandscape ? 4 : 3
    }
}

/// Coloca los elementos alternando columnas (el elemento *i* va a la columna *i mod n*)
/// y apila cada columna sin huecos (spec 001, RF-8 y RF-9).
struct AlternatingColumnsLayout: Layout {
    var columns: Int
    var spacing: CGFloat

    /// Cálculo puro de posiciones, separado del protocolo `Layout` para poder probarlo.
    static func frames(
        heights: [CGFloat],
        columnWidth: CGFloat,
        columns: Int,
        spacing: CGFloat
    ) -> (frames: [CGRect], height: CGFloat) {
        let columns = max(columns, 1)
        var columnHeights = [CGFloat](repeating: 0, count: columns)
        var frames: [CGRect] = []
        for (index, height) in heights.enumerated() {
            let column = index % columns
            let y = columnHeights[column] == 0 ? 0 : columnHeights[column] + spacing
            frames.append(CGRect(
                x: CGFloat(column) * (columnWidth + spacing),
                y: y,
                width: columnWidth,
                height: height
            ))
            columnHeights[column] = y + height
        }
        return (frames, columnHeights.max() ?? 0)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let result = Self.frames(
            heights: heights(subviews, columnWidth: columnWidth(for: width)),
            columnWidth: columnWidth(for: width),
            columns: columns,
            spacing: spacing
        )
        return CGSize(width: width, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let columnWidth = columnWidth(for: bounds.width)
        let result = Self.frames(
            heights: heights(subviews, columnWidth: columnWidth),
            columnWidth: columnWidth,
            columns: columns,
            spacing: spacing
        )
        for (subview, frame) in zip(subviews, result.frames) {
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(width: frame.width, height: frame.height)
            )
        }
    }

    private func columnWidth(for width: CGFloat) -> CGFloat {
        let columns = CGFloat(max(columns, 1))
        return max((width - spacing * (columns - 1)) / columns, 0)
    }

    private func heights(_ subviews: Subviews, columnWidth: CGFloat) -> [CGFloat] {
        subviews.map { $0.sizeThatFits(ProposedViewSize(width: columnWidth, height: nil)).height }
    }
}
