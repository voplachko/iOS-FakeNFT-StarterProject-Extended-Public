import XCTest
@testable import iOS_FakeNFT_Extended

final class NetworkLoggerTests: XCTestCase {
    private let logger = NetworkLogger()
    private let url = URL(string: "https://example.com/api/v1/profile/1")!

    func testShortPath() {
        XCTAssertEqual(NetworkLogger.shortPath(URL(string: "https://host.net/api/v1/profile/1")), "v1/profile/1")
        XCTAssertEqual(NetworkLogger.shortPath(URL(string: "https://host.net/api/v1/nft?page=1&size=10")), "v1/nft?page=1&size=10")
        XCTAssertEqual(NetworkLogger.shortPath(URL(string: "https://host.net/other")), "other")
    }

    func testTokenIsMasked() {
        XCTAssertEqual(NetworkLogger.mask("431a48d1-aaaa-bbbb-cccc-1234c2f1"), "431a…c2f1")
        XCTAssertEqual(NetworkLogger.mask(""), "(пусто)")
        XCTAssertEqual(NetworkLogger.mask("short"), "•••••")
    }

    func testRequestShowsDecodedFormBodyAndMaskedToken() {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("431a48d1-aaaa-bbbb-cccc-1234c2f1", forHTTPHeaderField: NetworkLogger.tokenHeader)
        request.httpBody = FormURLEncoder().encode(["name": .string("Студент & Ко"), "likes": .array(["1", "2"])])

        let text = logger.formatRequest(request, id: 3)

        XCTAssertTrue(text.contains("REQUEST #3"))
        XCTAssertTrue(text.contains("PUT v1/profile/1\n"))
        XCTAssertFalse(text.contains("example.com"))
        XCTAssertTrue(text.contains("name = Студент & Ко"))
        XCTAssertTrue(text.contains("likes = 1"))
        XCTAssertTrue(text.contains("likes = 2"))
        XCTAssertTrue(text.contains("431a…c2f1"))
        XCTAssertFalse(text.contains("431a48d1-aaaa"), "Токен целиком не печатается")
        XCTAssertFalse(text.contains("Токен пустой"))
    }

    func testRequestWarnsAboutEmptyToken() {
        var request = URLRequest(url: url)
        request.setValue("", forHTTPHeaderField: NetworkLogger.tokenHeader)
        XCTAssertTrue(logger.formatRequest(request, id: 1).contains("Токен пустой"))
    }

    func testResponseShowsStatusAndPrettyJSON() throws {
        let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
        let data = Data(#"{"name":"Имя","likes":["1"]}"#.utf8)

        let text = logger.formatResponse(response, data: data, request: URLRequest(url: url), id: 3, duration: .milliseconds(352))

        XCTAssertTrue(text.contains("RESPONSE #3"))
        XCTAssertTrue(text.contains("✅ 200"))
        XCTAssertTrue(text.contains("352 ms"))
        XCTAssertTrue(text.contains(#""name" : "Имя""#), "JSON отформатирован, кириллица не экранирована")
    }

    func testErrorStatusIsMarked() throws {
        let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 406, httpVersion: nil, headerFields: nil))
        let text = logger.formatResponse(response, data: Data(), request: URLRequest(url: url), id: 1, duration: .zero)
        XCTAssertTrue(text.contains("❌ 406"))
        XCTAssertTrue(text.contains("(пусто)"))
    }

    func testLongBodyIsTruncated() throws {
        let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
        let short = NetworkLogger(maxBodyLength: 10)
        let text = short.formatResponse(response, data: Data(String(repeating: "a", count: 50).utf8), request: URLRequest(url: url), id: 1, duration: .zero)
        XCTAssertTrue(text.contains("ещё 40 символов"))
    }

    func testOfflineErrorHintsAboutVPN() {
        let text = logger.formatError(URLError(.notConnectedToInternet), request: URLRequest(url: url), id: 2, duration: .zero)
        XCTAssertTrue(text.contains("ERROR #2"))
        XCTAssertTrue(text.contains("VPN"))
    }

    func testDecodingErrorNamesTheField() {
        let data = Data(#"{"id": "1", "nfts": "oops"}"#.utf8)
        do {
            _ = try JSONDecoder().decode(Order.self, from: data)
            XCTFail("Ожидалась ошибка")
        } catch {
            let text = logger.formatDecodingError(error, type: Order.self, data: data, id: 5)
            XCTAssertTrue(text.contains("PARSING ERROR #5"))
            XCTAssertTrue(text.contains("«nfts»"))
        }
    }
}
