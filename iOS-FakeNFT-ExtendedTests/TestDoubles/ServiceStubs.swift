import XCTest
@testable import iOS_FakeNFT_Extended

struct StubError: Error {}

/// Профиль, который умеет падать на PUT.
actor ProfileServiceStub: ProfileService {
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

actor OrderServiceStub: OrderService {
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
