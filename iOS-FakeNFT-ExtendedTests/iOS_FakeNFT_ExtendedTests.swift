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

/// Сетевой клиент-заглушка: запоминает запросы и отдаёт заданный JSON.
private actor NetworkClientStub: NetworkClient {
    private let response: Data
    private(set) var requests: [NetworkRequest] = []

    init(response: String) {
        self.response = Data(response.utf8)
    }

    func send(request: NetworkRequest) async throws -> Data {
        requests.append(request)
        return response
    }

    func send<T: Decodable>(request: NetworkRequest) async throws -> T {
        let data = try await send(request: request)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

final class ProfileServiceTests: XCTestCase {
    private let profileJSON = """
    {"name": "Имя", "avatar": "", "description": "", "website": "", "nfts": [], "likes": ["1", "2"], "id": "1"}
    """

    func testLoadProfileSendsGet() async throws {
        let client = NetworkClientStub(response: profileJSON)
        let service = ProfileServiceImpl(networkClient: client)

        let profile = try await service.loadProfile()

        XCTAssertEqual(profile.likes, ["1", "2"])
        let requests = await client.requests
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.httpMethod, .get)
        XCTAssertEqual(request.endpoint?.path, "/api/v1/profile/1")
        XCTAssertNil(request.formFields)
    }

    func testUpdateLikesSendsOnlyLikes() async throws {
        let client = NetworkClientStub(response: profileJSON)
        let service = ProfileServiceImpl(networkClient: client)

        _ = try await service.updateLikes(["1", "2"])

        let requests = await client.requests
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.httpMethod, .put)
        XCTAssertEqual(request.formFields, ["likes": .array(["1", "2"])])
    }

    func testUpdateProfileSendsOnlyChangedFields() async throws {
        let client = NetworkClientStub(response: profileJSON)
        let service = ProfileServiceImpl(networkClient: client)

        _ = try await service.updateProfile(name: "Новое имя", description: nil, website: "https://ya.ru", avatar: nil)

        let requests = await client.requests
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.httpMethod, .put)
        XCTAssertEqual(request.formFields, ["name": .string("Новое имя"), "website": .string("https://ya.ru")])
    }

    func testUpdateProfileWithoutChangesOnlyLoads() async throws {
        let client = NetworkClientStub(response: profileJSON)
        let service = ProfileServiceImpl(networkClient: client)

        _ = try await service.updateProfile(name: nil, description: nil, website: nil, avatar: nil)

        let requests = await client.requests
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests.first?.httpMethod, .get)
    }
}

final class OrderServiceTests: XCTestCase {
    private let orderJSON = #"{"nfts": ["1", "2"], "id": "1"}"#

    func testLoadOrderSendsGet() async throws {
        let client = NetworkClientStub(response: orderJSON)
        let service = OrderServiceImpl(networkClient: client)

        let order = try await service.loadOrder()

        XCTAssertEqual(order.nfts, ["1", "2"])
        let requests = await client.requests
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.httpMethod, .get)
        XCTAssertEqual(request.endpoint?.path, "/api/v1/orders/1")
    }

    func testUpdateOrderSendsNfts() async throws {
        let client = NetworkClientStub(response: orderJSON)
        let service = OrderServiceImpl(networkClient: client)

        _ = try await service.updateOrder(nfts: ["1", "2"])

        let requests = await client.requests
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.httpMethod, .put)
        XCTAssertEqual(request.formFields, ["nfts": .array(["1", "2"])])
    }

    func testClearOrderSendsEmptyArray() async throws {
        let client = NetworkClientStub(response: #"{"nfts": [], "id": "1"}"#)
        let service = OrderServiceImpl(networkClient: client)

        let order = try await service.updateOrder(nfts: [])

        XCTAssertTrue(order.nfts.isEmpty)
        let requests = await client.requests
        XCTAssertEqual(requests.first?.formFields, ["nfts": .array([])])
    }
}

private struct StubError: Error {}

/// Профиль, который умеет падать на PUT.
private actor ProfileServiceStub: ProfileService {
    var shouldFail = false
    private(set) var sentLikes: [[String]] = []
    private var profile = Profile(id: "1", name: "", avatar: "", description: "", website: "", nfts: [], likes: ["1"])

    func setShouldFail(_ value: Bool) { shouldFail = value }

    func loadProfile() async throws -> Profile { profile }

    func updateLikes(_ ids: [String]) async throws -> Profile {
        sentLikes.append(ids)
        if shouldFail { throw StubError() }
        return profile
    }

    func updateProfile(name: String?, description: String?, website: String?, avatar: String?) async throws -> Profile {
        profile
    }
}

private actor OrderServiceStub: OrderService {
    var shouldFail = false
    private(set) var sentNfts: [[String]] = []

    func setShouldFail(_ value: Bool) { shouldFail = value }

    func loadOrder() async throws -> Order {
        if shouldFail { throw StubError() }
        return Order(id: "1", nfts: ["10", "11"])
    }

    func updateOrder(nfts: [String]) async throws -> Order {
        sentNfts.append(nfts)
        if shouldFail { throw StubError() }
        return Order(id: "1", nfts: nfts)
    }
}

@MainActor
final class UserStoreTests: XCTestCase {
    func testLoadFillsLikesAndCart() async {
        let store = UserStore(profileService: ProfileServiceStub(), orderService: OrderServiceStub())

        await store.load()

        XCTAssertEqual(store.loadState, .loaded)
        XCTAssertEqual(store.likedIds, ["1"])
        XCTAssertEqual(store.cartIds, ["10", "11"])
    }

    func testLoadFailure() async {
        let orders = OrderServiceStub()
        await orders.setShouldFail(true)
        let store = UserStore(profileService: ProfileServiceStub(), orderService: orders)

        await store.load()

        XCTAssertEqual(store.loadState, .failed)
        XCTAssertNotNil(store.lastError)
    }

    func testToggleLikeIsOptimisticAndSendsFullList() async {
        let profiles = ProfileServiceStub()
        let store = UserStore(profileService: profiles, orderService: OrderServiceStub())
        await store.load()

        let task = store.toggleLike("2")
        XCTAssertTrue(store.isLiked("2"), "Лайк виден сразу, до ответа сервера")
        await task.value

        let sent = await profiles.sentLikes
        XCTAssertEqual(sent, [["1", "2"]])
        XCTAssertTrue(store.isLiked("2"))
    }

    func testToggleLikeRollsBackOnError() async {
        let profiles = ProfileServiceStub()
        let store = UserStore(profileService: profiles, orderService: OrderServiceStub())
        await store.load()
        await profiles.setShouldFail(true)

        await store.toggleLike("1").value

        XCTAssertTrue(store.isLiked("1"), "Снятый лайк вернулся после ошибки")
        XCTAssertNotNil(store.lastError)
    }

    func testCartRequestsAreSerialized() async {
        let orders = OrderServiceStub()
        let store = UserStore(profileService: ProfileServiceStub(), orderService: orders)
        await store.load()

        store.toggleCart("12")
        await store.toggleCart("10").value

        let sent = await orders.sentNfts
        XCTAssertEqual(sent.last, ["11", "12"], "Последний PUT содержит итоговое состояние")
        XCTAssertEqual(store.cartIds, ["11", "12"])
    }

    func testToggleCartRollsBackOnError() async {
        let orders = OrderServiceStub()
        let store = UserStore(profileService: ProfileServiceStub(), orderService: orders)
        await store.load()
        await orders.setShouldFail(true)

        await store.toggleCart("12").value

        XCTAssertFalse(store.isInCart("12"))
        XCTAssertEqual(store.cartIds, ["10", "11"])
    }
}

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

final class SplashTimelineTests: XCTestCase {
    private typealias T = SplashTimeline

    private func assertPose(_ pose: LogoPose, equals expected: LogoPose, accuracy: CGFloat = 0.001, file: StaticString = #filePath, line: UInt = #line) {
        let pairs: [(CGFloat, CGFloat)] = [
            (pose.leftPillarScaleY, expected.leftPillarScaleY),
            (pose.rightPillarScaleY, expected.rightPillarScaleY),
            (pose.lintelOffsetY, expected.lintelOffsetY),
            (pose.lintelScaleX, expected.lintelScaleX),
            (pose.lintelScaleY, expected.lintelScaleY),
            (pose.portalReveal, expected.portalReveal),
            (pose.zoomProgress, expected.zoomProgress),
            (pose.logoOpacity, expected.logoOpacity),
            (pose.backgroundOpacity, expected.backgroundOpacity)
        ]
        for (value, target) in pairs {
            XCTAssertEqual(value, target, accuracy: accuracy, file: file, line: line)
        }
    }

    func testIntroStartsExactlyAsLaunchScreen() {
        assertPose(T.intro(at: 0), equals: .rest)
    }

    func testIntroEndsAtRestSoIdleContinuesSeamlessly() {
        assertPose(T.intro(at: T.introEnd), equals: .rest)
        assertPose(T.idle(at: 0), equals: .rest)
    }

    func testPillarsAreMostCompressedAtHapticTaps() {
        XCTAssertEqual(T.intro(at: T.leftImpact).leftPillarScaleY, T.tapSquash, accuracy: 0.001)
        XCTAssertEqual(T.intro(at: T.rightImpact).rightPillarScaleY, T.tapSquash, accuracy: 0.001)
    }

    func testLintelHitsAtSlamImpact() {
        XCTAssertEqual(T.intro(at: T.slamImpact).lintelOffsetY, T.slamOvershoot, accuracy: 0.001)
        XCTAssertLessThan(T.intro(at: T.slamStart).lintelOffsetY, -T.liftHeight + 0.001)
    }

    func testExitContinuesFromIdleOffsetAndEndsHidden() {
        let offset = T.idle(at: T.idlePeriod / 2).lintelOffsetY
        XCTAssertEqual(T.exit(at: 0, startOffset: offset).lintelOffsetY, offset, accuracy: 0.001)

        let end = T.exit(at: T.exitEnd, startOffset: offset)
        XCTAssertEqual(end.portalReveal, 1)
        XCTAssertEqual(end.zoomProgress, 1)
        XCTAssertEqual(end.logoOpacity, 0)
        XCTAssertEqual(end.backgroundOpacity, 0)
    }

    func testIntroHapticsMatchAnimationBeats() {
        let transients = HapticScript.intro.events
            .filter { $0.kind == .transient }
            .map(\.time)
        XCTAssertEqual(transients, [T.leftImpact, T.rightImpact, T.slamImpact])
    }

    func testExitHapticClickWhenPassingThroughGate() {
        let transients = HapticScript.exit.events.filter { $0.kind == .transient }
        XCTAssertEqual(transients.map(\.time), [T.zoomEnd])
    }

    func testIntensityCurveIsFullOnEveryTap() {
        for time in [T.leftImpact, T.rightImpact, T.slamImpact] {
            XCTAssertEqual(curveValue(HapticScript.intro.intensityCurve, at: time), 1, accuracy: 0.001)
        }
        XCTAssertEqual(curveValue(HapticScript.exit.intensityCurve, at: T.zoomEnd), 1, accuracy: 0.001)
    }

    /// Линейная интерполяция — так же, как CHHapticParameterCurve.
    private func curveValue(_ points: [HapticScript.CurvePoint], at time: TimeInterval) -> Float {
        guard let next = points.firstIndex(where: { $0.time >= time }) else { return points.last?.value ?? 1 }
        guard next > 0 else { return points[next].value }
        let a = points[next - 1], b = points[next]
        let p = Float((time - a.time) / (b.time - a.time))
        return a.value + (b.value - a.value) * p
    }
}
