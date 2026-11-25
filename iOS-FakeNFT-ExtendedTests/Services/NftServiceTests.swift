import XCTest
@testable import iOS_FakeNFT_Extended

final class NftServiceTests: XCTestCase {
    private func nftJSON(_ id: String) -> String {
        #"{"name": "N\#(id)", "images": ["https://example.com/\#(id).png"], "rating": 3, "price": 1.5, "author": "1", "id": "\#(id)"}"#
    }

    private func makeClient(ids: [String]) -> RoutingNetworkClientStub {
        RoutingNetworkClientStub(routes: Dictionary(uniqueKeysWithValues: ids.map { ("/api/v1/nft/\($0)", nftJSON($0)) }))
    }

    func testLoadNftsKeepsOriginalOrder() async throws {
        let ids = (1...15).map(String.init).shuffled()
        let service = NftServiceImpl(networkClient: makeClient(ids: ids), storage: NftStorageImpl())

        let nfts = try await service.loadNfts(ids: ids)

        XCTAssertEqual(nfts.map(\.id), ids)
    }

    func testLoadNftsLimitsConcurrency() async throws {
        let ids = (1...20).map(String.init)
        let client = makeClient(ids: ids)
        let service = NftServiceImpl(networkClient: client, storage: NftStorageImpl())

        _ = try await service.loadNfts(ids: ids)

        let maxInFlight = await client.maxInFlight
        XCTAssertLessThanOrEqual(maxInFlight, NftServiceImpl.maxConcurrentRequests)
        XCTAssertGreaterThan(maxInFlight, 1, "Запросы идут параллельно")
    }

    func testCachedNftIsNotRequestedAgain() async throws {
        let client = makeClient(ids: ["1"])
        let service = NftServiceImpl(networkClient: client, storage: NftStorageImpl())

        _ = try await service.loadNft(id: "1")
        _ = try await service.loadNft(id: "1")

        let paths = await client.requestedPaths
        XCTAssertEqual(paths, ["/api/v1/nft/1"])
    }

    func testLoadNftsFailsIfAnyNftFails() async {
        let service = NftServiceImpl(networkClient: makeClient(ids: ["1"]), storage: NftStorageImpl())
        do {
            _ = try await service.loadNfts(ids: ["1", "missing"])
            XCTFail("Ожидалась ошибка")
        } catch {}
    }
}
