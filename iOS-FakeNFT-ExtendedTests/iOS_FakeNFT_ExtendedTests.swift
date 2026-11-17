import XCTest
@testable import iOS_FakeNFT_Extended

/// Проверка декодирования сетевых моделей на JSON из API.html.
final class NetworkModelsDecodingTests: XCTestCase {
    private let decoder = JSONDecoder()

    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try decoder.decode(T.self, from: Data(json.utf8))
    }

    func testNftDecoding() throws {
        let json = """
        {
          "createdAt": "2023-04-20T02:22:27Z",
          "name": "April",
          "images": [
            "https://code.s3.yandex.net/Mobile/iOS/NFT/Beige/April/1.png",
            "https://code.s3.yandex.net/Mobile/iOS/NFT/Beige/April/2.png"
          ],
          "rating": 5,
          "description": "A 3D model of a mythical creature.",
          "price": 8.81,
          "author": "49",
          "website": "http://author.website",
          "id": "1"
        }
        """
        let nft = try decode(Nft.self, json)
        XCTAssertEqual(nft.id, "1")
        XCTAssertEqual(nft.name, "April")
        XCTAssertEqual(nft.images.count, 2)
        XCTAssertEqual(nft.rating, 5)
        XCTAssertEqual(nft.price, 8.81, accuracy: 0.001)
        XCTAssertEqual(nft.author, "49")
    }

    func testNftCollectionDecodingWithCyrillicCover() throws {
        let json = """
        [{
          "createdAt": "2023-04-20T02:22:27Z",
          "name": "Beige",
          "cover": "https://code.s3.yandex.net/Mobile/iOS/NFT/Обложки_коллекций/Beige.png",
          "nfts": ["1", "2", "3"],
          "description": "A series of one-of-a-kind NFTs featuring historic moments in sports history.",
          "author": "49",
          "website": "http://author.website",
          "id": "1"
        }]
        """
        let collections = try decode([NftCollection].self, json)
        XCTAssertEqual(collections.count, 1)
        XCTAssertEqual(collections[0].nfts, ["1", "2", "3"])
        XCTAssertNotNil(collections[0].coverURL)
    }

    func testProfileDecoding() throws {
        let json = """
        {
          "name": "Студентус Практикумус",
          "avatar": "https://code.s3.yandex.net/landings-v2-ios-developer/space.PNG",
          "description": "Прошел 5-й спринт, и этот пройду",
          "website": "https://practicum.yandex.ru/ios-developer",
          "nfts": ["68", "69"],
          "likes": ["5", "13"],
          "id": "1"
        }
        """
        let profile = try decode(Profile.self, json)
        XCTAssertEqual(profile.name, "Студентус Практикумус")
        XCTAssertEqual(profile.likes, ["5", "13"])
        XCTAssertNotNil(profile.avatarURL)
    }

    func testProfileWithEmptyWebsite() throws {
        let json = """
        {"name": "Name", "avatar": "", "description": "", "website": "", "nfts": [], "likes": [], "id": "1"}
        """
        let profile = try decode(Profile.self, json)
        XCTAssertNil(profile.avatarURL)
        XCTAssertNil(profile.websiteURL)
    }

    func testOrderDecoding() throws {
        let order = try decode(Order.self, #"{"nfts": ["93", "94", "95"], "id": "1"}"#)
        XCTAssertEqual(order.id, "1")
        XCTAssertEqual(order.nfts.count, 3)
    }

    func testCurrencyDecoding() throws {
        let json = """
        [{"title": "Bitcoin", "name": "BTC", "image": "https://code.s3.yandex.net/Mobile/iOS/Currencies/Bitcoin_(BTC).png", "id": "1"}]
        """
        let currencies = try decode([Currency].self, json)
        XCTAssertEqual(currencies[0].title, "Bitcoin")
        XCTAssertEqual(currencies[0].name, "BTC")
        XCTAssertNotNil(currencies[0].imageURL)
    }

    func testUserDecodingWithStringRating() throws {
        let json = """
        {
          "name": "Alex",
          "avatar": "https://example.com/avatar.png",
          "description": "Collector",
          "website": "https://example.com",
          "nfts": ["1", "2"],
          "rating": "51",
          "id": "8996ae12-3aa3-47fe-938e-270e993bfcc3"
        }
        """
        let user = try decode(User.self, json)
        XCTAssertEqual(user.rating, 51)
        XCTAssertEqual(user.nfts, ["1", "2"])
    }

    func testUserDecodingWithIntRating() throws {
        let json = """
        {"name": "Alex", "avatar": "", "description": "", "website": "", "nfts": [], "rating": 7, "id": "2"}
        """
        XCTAssertEqual(try decode(User.self, json).rating, 7)
    }

    func testPaymentResultDecoding() throws {
        let result = try decode(PaymentResult.self, #"{"success": true, "orderId": "1", "id": "3"}"#)
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.orderId, "1")
        XCTAssertEqual(result.id, "3")
    }
}

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
