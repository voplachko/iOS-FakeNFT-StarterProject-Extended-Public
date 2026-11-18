import XCTest
@testable import iOS_FakeNFT_Extended

@MainActor
final class CatalogViewModelTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suiteName = "CatalogViewModelTests"

    override func setUp() async throws {
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
    }

    private let collections = [
        NftCollection(id: "1", name: "Peach", cover: "", nfts: ["1"], description: "", author: ""),
        NftCollection(id: "2", name: "Blue", cover: "", nfts: ["1", "2", "3"], description: "", author: ""),
        NftCollection(id: "3", name: "Green", cover: "", nfts: ["1", "2"], description: "", author: "")
    ]

    func testLoadSuccess() async {
        let viewModel = CatalogViewModel(service: CollectionsServiceMock(collections: collections), defaults: defaults)

        await viewModel.load()

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.collections.count, 3)
    }

    func testDefaultSortIsByNftCount() async {
        let viewModel = CatalogViewModel(service: CollectionsServiceMock(collections: collections), defaults: defaults)
        await viewModel.load()

        XCTAssertEqual(viewModel.sortOption, .nftCount)
        XCTAssertEqual(viewModel.sortedCollections.map(\.id), ["2", "3", "1"])
    }

    func testSortByNameAndPersist() async {
        let viewModel = CatalogViewModel(service: CollectionsServiceMock(collections: collections), defaults: defaults)
        await viewModel.load()

        viewModel.sortOption = .name

        XCTAssertEqual(viewModel.sortedCollections.map(\.name), ["Blue", "Green", "Peach"])
        // «Перезапуск»: новая ViewModel читает выбор из того же хранилища.
        let restored = CatalogViewModel(service: CollectionsServiceMock(), defaults: defaults)
        XCTAssertEqual(restored.sortOption, .name)
    }

    func testErrorIsExposedAndRetryClearsIt() async {
        let failing = CatalogViewModel(
            service: CollectionsServiceMock(error: NetworkClientError.httpStatusCode(500)),
            defaults: defaults
        )
        await failing.load()

        XCTAssertNotNil(failing.error)
        XCTAssertTrue(failing.isErrorPresented)
        XCTAssertFalse(failing.isLoading)

        failing.isErrorPresented = false
        XCTAssertNil(failing.error)
    }

    func testLoadIfNeededLoadsOnlyOnce() async {
        let viewModel = CatalogViewModel(service: CollectionsServiceMock(collections: collections), defaults: defaults)
        await viewModel.loadIfNeeded()
        let first = viewModel.collections
        await viewModel.loadIfNeeded()
        XCTAssertEqual(viewModel.collections, first)
    }

    func testCancellationIsNotAnError() {
        XCTAssertTrue(CancellationError().isCancellation)
        XCTAssertTrue(URLError(.cancelled).isCancellation)
        XCTAssertFalse(URLError(.notConnectedToInternet).isCancellation)
    }
}
