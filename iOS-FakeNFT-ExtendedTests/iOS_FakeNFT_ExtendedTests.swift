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
