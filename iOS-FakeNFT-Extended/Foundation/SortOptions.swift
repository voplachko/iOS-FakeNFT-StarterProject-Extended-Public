import Foundation

/// Вариант сортировки экрана. Хранится в @AppStorage по rawValue.
///
/// ```swift
/// @AppStorage(CatalogSortOption.storageKey) private var sort = CatalogSortOption.defaultValue
/// ```
protocol SortOption: RawRepresentable, CaseIterable, Identifiable, Hashable
where RawValue == String, AllCases: RandomAccessCollection {
    /// Отдельный ключ UserDefaults для каждого экрана.
    static var storageKey: String { get }
    /// Значение по умолчанию из ТЗ.
    static var defaultValue: Self { get }
    /// Название пункта в диалоге сортировки.
    var title: String { get }
}

extension SortOption {
    var id: String { rawValue }
}

// MARK: - Каталог

enum CatalogSortOption: String, SortOption {
    case name
    case nftCount

    static let storageKey = "sort.catalog"
    static let defaultValue: Self = .nftCount

    var title: String {
        switch self {
        case .name: NSLocalizedString("Sort.byName", comment: "")
        case .nftCount: NSLocalizedString("Sort.byNftCount", comment: "")
        }
    }
}

// MARK: - Корзина

enum CartSortOption: String, SortOption {
    case price
    case rating
    case name

    static let storageKey = "sort.cart"
    static let defaultValue: Self = .name

    var title: String {
        switch self {
        case .price: NSLocalizedString("Sort.byPrice", comment: "")
        case .rating: NSLocalizedString("Sort.byRating", comment: "")
        case .name: NSLocalizedString("Sort.byTitle", comment: "")
        }
    }
}

// MARK: - Мои NFT

enum MyNftSortOption: String, SortOption {
    case price
    case rating
    case name

    static let storageKey = "sort.myNft"
    static let defaultValue: Self = .rating

    var title: String {
        switch self {
        case .price: NSLocalizedString("Sort.byPrice", comment: "")
        case .rating: NSLocalizedString("Sort.byRating", comment: "")
        case .name: NSLocalizedString("Sort.byTitle", comment: "")
        }
    }
}

// MARK: - Статистика

enum StatisticsSortOption: String, SortOption {
    case name
    case rating

    static let storageKey = "sort.statistics"
    static let defaultValue: Self = .rating

    var title: String {
        switch self {
        case .name: NSLocalizedString("Sort.byName", comment: "")
        case .rating: NSLocalizedString("Sort.byRating", comment: "")
        }
    }
}

// MARK: - Применение сортировки

extension Sequence where Element == NftCollection {
    /// Название — по алфавиту, количество NFT — от большего к меньшему.
    func sorted(by option: CatalogSortOption) -> [NftCollection] {
        switch option {
        case .name:
            sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .nftCount:
            sorted { $0.nfts.count > $1.nfts.count }
        }
    }
}

extension Sequence where Element == Nft {
    /// Цена — от дешёвых к дорогим, рейтинг — от высокого к низкому, название — по алфавиту.
    func sorted(by option: CartSortOption) -> [Nft] {
        switch option {
        case .price: sortedByPrice()
        case .rating: sortedByRating()
        case .name: sortedByName()
        }
    }

    func sorted(by option: MyNftSortOption) -> [Nft] {
        switch option {
        case .price: sortedByPrice()
        case .rating: sortedByRating()
        case .name: sortedByName()
        }
    }

    private func sortedByPrice() -> [Nft] {
        sorted { $0.price < $1.price }
    }

    private func sortedByRating() -> [Nft] {
        sorted { $0.rating > $1.rating }
    }

    private func sortedByName() -> [Nft] {
        sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}

extension Sequence where Element == User {
    /// Имя — по алфавиту, рейтинг — от высокого к низкому.
    func sorted(by option: StatisticsSortOption) -> [User] {
        switch option {
        case .name:
            sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .rating:
            sorted { $0.rating > $1.rating }
        }
    }
}
