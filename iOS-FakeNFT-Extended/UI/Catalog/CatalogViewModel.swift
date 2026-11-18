import Foundation
import Observation
import SwiftUI

/// Экран каталога: список коллекций с сортировкой.
@MainActor
@Observable
final class CatalogViewModel {
    private(set) var collections: [NftCollection] = []
    private(set) var isLoading = false
    /// Ошибка загрузки — показывается алертом «Не удалось получить данные».
    var error: Error?

    /// Выбранная сортировка. Хранится в @AppStorage, переживает перезапуск.
    var sortOption: CatalogSortOption {
        get {
            access(keyPath: \.sortOption)
            return storedSortOption
        }
        set {
            withMutation(keyPath: \.sortOption) {
                storedSortOption = newValue
            }
        }
    }

    /// Коллекции в выбранном порядке — их и показывает экран.
    var sortedCollections: [NftCollection] {
        collections.sorted(by: sortOption)
    }

    var isErrorPresented: Bool {
        get { error != nil }
        set { if !newValue { error = nil } }
    }

    @ObservationIgnored private let service: CollectionsService
    @ObservationIgnored @AppStorage private var storedSortOption: CatalogSortOption
    @ObservationIgnored private var hasLoaded = false

    init(service: CollectionsService, defaults: UserDefaults = .standard) {
        self.service = service
        _storedSortOption = AppStorage(
            wrappedValue: CatalogSortOption.defaultValue,
            CatalogSortOption.storageKey,
            store: defaults
        )
    }

    /// Первая загрузка при появлении экрана; повторные появления не дёргают сеть.
    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await load()
    }

    /// Загрузка (и повтор после ошибки, и pull-to-refresh).
    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            collections = try await service.loadCollections()
            hasLoaded = true
        } catch {
            // Экран закрыли во время загрузки — это не ошибка.
            guard !error.isCancellation else { return }
            self.error = error
        }
    }
}
