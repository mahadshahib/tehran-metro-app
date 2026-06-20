import XCTest
@testable import MetroDomain

final class NumberLocalizationTests: XCTestCase {

    func testEnglishUsesWesternDigits() {
        XCTAssertEqual(NumberLocalization.string(2026, language: .english), "2026")
        XCTAssertEqual(NumberLocalization.string(7, language: .english), "7")
    }

    func testFarsiUsesPersianDigits() {
        XCTAssertEqual(NumberLocalization.string(7, language: .farsi), "۷")
        XCTAssertEqual(NumberLocalization.string(12, language: .farsi), "۱۲")
        XCTAssertEqual(NumberLocalization.string(0, language: .farsi), "۰")
    }

    func testNoGroupingSeparator() {
        // Large numbers must not gain a thousands separator.
        XCTAssertFalse(NumberLocalization.string(1500, language: .english).contains(","))
        XCTAssertFalse(NumberLocalization.string(1500, language: .farsi).contains("٬"))
    }
}
