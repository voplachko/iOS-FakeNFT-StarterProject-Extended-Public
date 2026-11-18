import XCTest
@testable import iOS_FakeNFT_Extended

/// Проверка сборки тела x-www-form-urlencoded.
final class FormURLEncoderTests: XCTestCase {
    func testArrayAsRepeatedKeys() {
        let encoder = FormURLEncoder(arrayEncoding: .repeatedKeys)
        XCTAssertEqual(encoder.query(["likes": .array(["1", "2", "3"])]), "likes=1&likes=2&likes=3")
    }

    func testArrayAsCommaSeparated() {
        let encoder = FormURLEncoder(arrayEncoding: .commaSeparated)
        XCTAssertEqual(encoder.query(["nfts": .array(["1", "2"])]), "nfts=1%2C2")
    }

    func testEmptyArray() {
        XCTAssertEqual(FormURLEncoder().query(["nfts": .array([])]), "nfts=null")
    }

    func testEscaping() {
        let query = FormURLEncoder().query(["name": .string("Студент Практикум & co=1+2")])
        XCTAssertEqual(
            query,
            "name=%D0%A1%D1%82%D1%83%D0%B4%D0%B5%D0%BD%D1%82%20%D0%9F%D1%80%D0%B0%D0%BA%D1%82%D0%B8%D0%BA%D1%83%D0%BC%20%26%20co%3D1%2B2"
        )
    }

    func testURLValueIsEscaped() {
        let query = FormURLEncoder().query(["website": .string("https://practicum.yandex.ru/ios-developer?a=1&b=2")])
        XCTAssertEqual(query, "website=https%3A%2F%2Fpracticum.yandex.ru%2Fios-developer%3Fa%3D1%26b%3D2")
    }

    func testOnlyChangedProfileFieldsAreSent() {
        let update = ProfileUpdate(name: "Имя", likes: [])
        XCTAssertEqual(Set(update.formFields.keys), ["name", "likes"])
        XCTAssertEqual(FormURLEncoder().query(update.formFields), "likes=null&name=%D0%98%D0%BC%D1%8F")
    }
}
