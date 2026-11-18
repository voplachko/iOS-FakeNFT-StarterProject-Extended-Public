import XCTest
@testable import iOS_FakeNFT_Extended

final class SortOptionsTests: XCTestCase {
    func testDefaultsFromSpec() {
        XCTAssertEqual(CatalogSortOption.defaultValue, .nftCount)
        XCTAssertEqual(CartSortOption.defaultValue, .name)
        XCTAssertEqual(MyNftSortOption.defaultValue, .rating)
        XCTAssertEqual(StatisticsSortOption.defaultValue, .rating)
    }

    func testEachScreenHasOwnStorageKey() {
        let keys = [
            CatalogSortOption.storageKey,
            CartSortOption.storageKey,
            MyNftSortOption.storageKey,
            StatisticsSortOption.storageKey
        ]
        XCTAssertEqual(Set(keys).count, keys.count)
    }

    /// @AppStorage хранит rawValue — проверяем, что выбор переживает «перезапуск».
    func testSelectionSurvivesRestoreFromDefaults() throws {
        let suite = "SortOptionsTests"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        defaults.set(CartSortOption.price.rawValue, forKey: CartSortOption.storageKey)

        let restored = defaults.string(forKey: CartSortOption.storageKey).flatMap(CartSortOption.init(rawValue:))
        XCTAssertEqual(restored, .price)
    }

    func testCatalogSorting() {
        let collections = [
            NftCollection(id: "1", name: "Beige", cover: "", nfts: ["1"], description: "", author: ""),
            NftCollection(id: "2", name: "aqua", cover: "", nfts: ["1", "2", "3"], description: "", author: ""),
            NftCollection(id: "3", name: "Coral", cover: "", nfts: ["1", "2"], description: "", author: "")
        ]
        XCTAssertEqual(collections.sorted(by: CatalogSortOption.name).map(\.id), ["2", "1", "3"])
        XCTAssertEqual(collections.sorted(by: CatalogSortOption.nftCount).map(\.id), ["2", "3", "1"])
    }

    func testNftSorting() {
        let url = URL(string: "https://example.com/1.png")!
        let nfts = [
            Nft(id: "1", name: "Lilo", images: [url], rating: 3, price: 2.5, author: ""),
            Nft(id: "2", name: "april", images: [url], rating: 5, price: 8.1, author: ""),
            Nft(id: "3", name: "Bella", images: [url], rating: 1, price: 0.9, author: "")
        ]
        XCTAssertEqual(nfts.sorted(by: CartSortOption.price).map(\.id), ["3", "1", "2"])
        XCTAssertEqual(nfts.sorted(by: CartSortOption.rating).map(\.id), ["2", "1", "3"])
        XCTAssertEqual(nfts.sorted(by: MyNftSortOption.name).map(\.id), ["2", "3", "1"])
    }

    func testStatisticsSorting() {
        let users = [
            User(id: "1", name: "Bob", avatar: "", description: "", website: "", nfts: [], rating: 10),
            User(id: "2", name: "alex", avatar: "", description: "", website: "", nfts: [], rating: 51)
        ]
        XCTAssertEqual(users.sorted(by: StatisticsSortOption.rating).map(\.id), ["2", "1"])
        XCTAssertEqual(users.sorted(by: StatisticsSortOption.name).map(\.id), ["2", "1"])
    }
}
