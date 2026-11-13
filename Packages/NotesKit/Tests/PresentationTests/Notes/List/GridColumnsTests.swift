import Testing
@testable import Presentation

struct GridColumnsTests {
    @Test(
        "given iPhone when counting columns then always 2",
        arguments: [false, true], [false, true]
    )
    func iPhoneAlwaysTwo(isRegularWidth: Bool, isLandscape: Bool) {
        #expect(GridColumns.count(isPad: false, isRegularWidth: isRegularWidth, isLandscape: isLandscape) == 2)
    }

    @Test("given iPad with compact width when counting columns then 2", arguments: [false, true])
    func iPadCompactIsTwo(isLandscape: Bool) {
        #expect(GridColumns.count(isPad: true, isRegularWidth: false, isLandscape: isLandscape) == 2)
    }

    @Test("given iPad regular width in portrait when counting columns then 3")
    func iPadPortraitIsThree() {
        #expect(GridColumns.count(isPad: true, isRegularWidth: true, isLandscape: false) == 3)
    }

    @Test("given iPad regular width in landscape when counting columns then 4")
    func iPadLandscapeIsFour() {
        #expect(GridColumns.count(isPad: true, isRegularWidth: true, isLandscape: true) == 4)
    }
}
