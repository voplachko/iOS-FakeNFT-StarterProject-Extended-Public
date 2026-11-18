import XCTest
@testable import iOS_FakeNFT_Extended

@MainActor
final class CollectionViewModelTests: XCTestCase {
    private func nft(_ id: String) -> Nft {
        Nft(id: id, name: "N\(id)", images: [], rating: 3, price: 1, author: "")
    }

    private func collection(nfts: [String]) -> NftCollection {
        NftCollection(id: "7", name: "Peach", cover: "", nfts: nfts, description: "", author: "John Doe")
    }

    func testLoadsNftsInCollectionOrder() async {
        let ids = ["3", "1", "2"]
        let viewModel = CollectionViewModel(
            collection: collection(nfts: ids),
            collectionsService: CollectionsServiceMock(collections: [collection(nfts: ids)]),
            nftService: NftServiceMock(nfts: ["1", "2", "3"].map(nft))
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.nfts.map(\.id), ids)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }

    func testReloadsNftsWhenCollectionChangedOnServer() async {
        let nftService = NftServiceMock(nfts: ["1", "2", "3"].map(nft))
        let viewModel = CollectionViewModel(
            collection: collection(nfts: ["1"]),
            collectionsService: CollectionsServiceMock(collections: [collection(nfts: ["2", "3"])]),
            nftService: nftService
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.collection.nfts, ["2", "3"])
        XCTAssertEqual(viewModel.nfts.map(\.id), ["2", "3"])
        let requested = await nftService.requestedIds
        XCTAssertEqual(requested, [["1"], ["2", "3"]])
    }

    func testCollectionRefreshFailureIsNotFatal() async {
        let viewModel = CollectionViewModel(
            collection: collection(nfts: ["1"]),
            collectionsService: CollectionsServiceMock(error: NetworkClientError.httpStatusCode(500)),
            nftService: NftServiceMock(nfts: [nft("1")])
        )

        await viewModel.load()

        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.nfts.map(\.id), ["1"])
    }

    func testNftFailureIsExposed() async {
        let viewModel = CollectionViewModel(
            collection: collection(nfts: ["1"]),
            collectionsService: CollectionsServiceMock(collections: [collection(nfts: ["1"])]),
            nftService: NftServiceMock(error: NetworkClientError.httpStatusCode(500))
        )

        await viewModel.load()

        XCTAssertTrue(viewModel.isErrorPresented)
        XCTAssertTrue(viewModel.nfts.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadIfNeededDoesNotReload() async {
        let nftService = NftServiceMock(nfts: [nft("1")])
        let viewModel = CollectionViewModel(
            collection: collection(nfts: ["1"]),
            collectionsService: CollectionsServiceMock(collections: [collection(nfts: ["1"])]),
            nftService: nftService
        )

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        let requested = await nftService.requestedIds
        XCTAssertEqual(requested.count, 1)
    }
}
