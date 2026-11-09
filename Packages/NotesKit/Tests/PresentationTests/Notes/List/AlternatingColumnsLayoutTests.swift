import CoreGraphics
import Testing
@testable import Presentation

struct AlternatingColumnsLayoutTests {
    @Test("given two columns when computing frames then items alternate and stack with only the spacing between them")
    func twoColumns() {
        let result = AlternatingColumnsLayout.frames(
            heights: [100, 50, 30, 40, 20],
            columnWidth: 150,
            columns: 2,
            spacing: 12
        )

        #expect(result.frames == [
            CGRect(x: 0, y: 0, width: 150, height: 100),
            CGRect(x: 162, y: 0, width: 150, height: 50),
            CGRect(x: 0, y: 112, width: 150, height: 30),
            CGRect(x: 162, y: 62, width: 150, height: 40),
            CGRect(x: 0, y: 154, width: 150, height: 20),
        ])
        #expect(result.height == 174)
    }

    @Test("given three columns when computing frames then item i goes to column i mod 3")
    func threeColumns() {
        let result = AlternatingColumnsLayout.frames(
            heights: [10, 20, 30, 40, 50, 60],
            columnWidth: 100,
            columns: 3,
            spacing: 8
        )

        #expect(result.frames.map(\.minX) == [0, 108, 216, 0, 108, 216])
        #expect(result.frames.map(\.minY) == [0, 0, 0, 18, 28, 38])
        #expect(result.height == 98)
    }

    @Test("given four columns when computing frames then height is the tallest column")
    func fourColumns() {
        let result = AlternatingColumnsLayout.frames(
            heights: [10, 20, 30, 40, 50],
            columnWidth: 50,
            columns: 4,
            spacing: 10
        )

        #expect(result.frames.map(\.minX) == [0, 60, 120, 180, 0])
        #expect(result.frames.map(\.minY) == [0, 0, 0, 0, 20])
        #expect(result.height == 70)
    }

    @Test("given no items when computing frames then no frames and zero height")
    func empty() {
        let result = AlternatingColumnsLayout.frames(heights: [], columnWidth: 100, columns: 2, spacing: 12)

        #expect(result.frames.isEmpty)
        #expect(result.height == 0)
    }
}
