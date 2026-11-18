import XCTest
@testable import iOS_FakeNFT_Extended

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
