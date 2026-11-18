import XCTest
@testable import iOS_FakeNFT_Extended

final class PriceFormattingTests: XCTestCase {
    /// Форматтер ставит неразрывный пробел — приводим к обычному для сравнения.
    private func normalized(_ string: String) -> String {
        string.replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{202F}", with: " ")
    }

    func testRussianLocale() {
        XCTAssertEqual(normalized(1.78.ethFormatted(locale: Locale(identifier: "ru_RU"))), "1,78 ETH")
    }

    func testRoundsToTwoDigits() {
        XCTAssertEqual(normalized(8.811.ethFormatted(locale: Locale(identifier: "ru_RU"))), "8,81 ETH")
        XCTAssertEqual(normalized(3.0.ethFormatted(locale: Locale(identifier: "ru_RU"))), "3,00 ETH")
    }

    func testEnglishLocaleUsesDot() {
        XCTAssertTrue(1.78.ethFormatted(locale: Locale(identifier: "en_US")).contains("1.78"))
    }
}
