import XCTest
@testable import iOS_FakeNFT_Extended

final class CollectionsServiceTests: XCTestCase {
    private let collectionJSON = """
    {"name": "Peach", "cover": "https://example.com/c.png", "nfts": ["1", "2"], "description": "", "author": "1", "id": "7"}
    """

    func testLoadCollections() async throws {
        let client = RoutingNetworkClientStub(routes: ["/api/v1/collections": "[\(collectionJSON)]"])
        let collections = try await CollectionsServiceImpl(networkClient: client).loadCollections()
        XCTAssertEqual(collections.map(\.id), ["7"])
    }

    func testLoadCollectionById() async throws {
        let client = RoutingNetworkClientStub(routes: ["/api/v1/collections/7": collectionJSON])
        let collection = try await CollectionsServiceImpl(networkClient: client).loadCollection(id: "7")
        XCTAssertEqual(collection.nfts, ["1", "2"])
    }
}
