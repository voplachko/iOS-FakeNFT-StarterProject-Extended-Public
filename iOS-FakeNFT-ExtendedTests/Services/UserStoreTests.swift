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
        XCTAssertNotNil(store.loadError)
    }

    func testToggleLikeIsOptimisticAndSendsFullList() async {
        let profiles = ProfileServiceStub()
        let store = UserStore(profileService: profiles, orderService: OrderServiceStub())
        await store.load()

        let task = store.toggleLike("2")
        XCTAssertTrue(store.isLiked("2"), "Лайк виден сразу, до ответа сервера")
        await task?.value

        let sent = await profiles.sentLikes
        XCTAssertEqual(sent, [["1", "2"]])
        XCTAssertTrue(store.isLiked("2"))
    }

    func testToggleLikeRollsBackOnError() async {
        let profiles = ProfileServiceStub()
        let store = UserStore(profileService: profiles, orderService: OrderServiceStub())
        await store.load()
        await profiles.setShouldFail(true)

        await store.toggleLike("1")?.value

        XCTAssertTrue(store.isLiked("1"), "Снятый лайк вернулся после ошибки")
        XCTAssertNotNil(store.syncError)
    }

    func testCartRequestsAreSerialized() async {
        let orders = OrderServiceStub()
        let store = UserStore(profileService: ProfileServiceStub(), orderService: orders)
        await store.load()

        store.toggleCart("12")
        await store.toggleCart("10")?.value

        let sent = await orders.sentNfts
        XCTAssertEqual(sent.last, ["11", "12"], "Последний PUT содержит итоговое состояние")
        XCTAssertEqual(store.cartIds, ["11", "12"])
    }

    func testToggleCartRollsBackOnError() async {
        let orders = OrderServiceStub()
        let store = UserStore(profileService: ProfileServiceStub(), orderService: orders)
        await store.load()
        await orders.setShouldFail(true)

        await store.toggleCart("12")?.value

        XCTAssertFalse(store.isInCart("12"))
        XCTAssertEqual(store.cartIds, ["10", "11"])
    }

    func testRepeatedTapWhileRequestInFlightIsIgnored() async {
        let profiles = ProfileServiceStub()
        let store = UserStore(profileService: profiles, orderService: OrderServiceStub())
        await store.load()

        let first = store.toggleLike("2")
        XCTAssertTrue(store.isLikePending("2"))
        let second = store.toggleLike("2")

        XCTAssertNil(second, "Второе нажатие игнорируется, пока идёт запрос")
        XCTAssertTrue(store.isLiked("2"))
        await first?.value

        XCTAssertFalse(store.isLikePending("2"))
        let sent = await profiles.sentLikes
        XCTAssertEqual(sent.count, 1)
    }

    func testOtherNftCanBeToggledWhileOneIsPending() async {
        let orders = OrderServiceStub()
        let store = UserStore(profileService: ProfileServiceStub(), orderService: orders)
        await store.load()

        let first = store.toggleCart("12")
        let second = store.toggleCart("13")

        XCTAssertNotNil(second)
        await first?.value
        await second?.value
        XCTAssertEqual(store.cartIds, ["10", "11", "12", "13"])
    }

    func testPendingIsClearedAfterErrorAndAlertIsShown() async {
        let orders = OrderServiceStub()
        let store = UserStore(profileService: ProfileServiceStub(), orderService: orders)
        await store.load()
        await orders.setShouldFail(true)

        await store.toggleCart("12")?.value

        XCTAssertFalse(store.isCartPending("12"))
        XCTAssertTrue(store.isSyncErrorPresented)
        store.isSyncErrorPresented = false
        XCTAssertNil(store.syncError)
        XCTAssertNil(store.loadError, "Ошибка сохранения не путается с ошибкой загрузки")
    }
}
