import XCTest
@testable import MetroDomain

final class PersianNormalizerTests: XCTestCase {

    func testArabicYehNormalizedToPersian() {
        // Arabic yeh (ي) vs Persian yeh (ی) must compare equal.
        let arabic = "تجريش"   // with Arabic yeh
        let persian = "تجریش"  // with Persian yeh
        XCTAssertEqual(PersianNormalizer.normalize(arabic), PersianNormalizer.normalize(persian))
    }

    func testArabicKafNormalizedToPersian() {
        let arabic = "كرج"     // Arabic kaf
        let persian = "کرج"    // Persian kaf
        XCTAssertEqual(PersianNormalizer.normalize(arabic), PersianNormalizer.normalize(persian))
    }

    func testZWNJTreatedAsEquivalent() {
        let withZWNJ = "دروازه\u{200C}دولت"
        let withSpace = "دروازه دولت"
        XCTAssertEqual(PersianNormalizer.normalize(withZWNJ), PersianNormalizer.normalize(withSpace))
    }

    func testPersianDigitsNormalizedToAscii() {
        XCTAssertEqual(PersianNormalizer.normalize("خط ۷"), PersianNormalizer.normalize("خط 7"))
    }

    func testCaseAndWhitespaceInsensitive() {
        XCTAssertEqual(
            PersianNormalizer.normalize("  Imam   Khomeini "),
            PersianNormalizer.normalize("imam khomeini")
        )
    }

    func testMatchesSubstring() {
        XCTAssertTrue(PersianNormalizer.matches(query: "tajr", candidate: "Tajrish"))
        XCTAssertTrue(PersianNormalizer.matches(query: "تجريش", candidate: "تجریش"))
        XCTAssertFalse(PersianNormalizer.matches(query: "xyz", candidate: "Tajrish"))
    }

    func testEmptyQueryMatchesEverything() {
        XCTAssertTrue(PersianNormalizer.matches(query: "", candidate: "anything"))
    }
}
