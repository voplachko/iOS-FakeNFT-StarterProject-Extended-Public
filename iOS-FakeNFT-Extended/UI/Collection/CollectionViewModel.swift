import Foundation
import Observation

/// Экран коллекции: шапка коллекции и сетка её NFT.
///
/// Лайки и корзина не дублируются здесь — карточки берут их из общего UserStore,
/// поэтому изменения сразу видны на других вкладках.
@MainActor
@Observable
final class CollectionViewModel {
    private(set) var collection: NftCollection
    /// NFT в том же порядке, что и `collection.nfts`.
    private(set) var nfts: [Nft] = []
    private(set) var isLoading = false
    var error: Error?

    var isErrorPresented: Bool {
        get { error != nil }
        set { if !newValue { error = nil } }
    }

    @ObservationIgnored private let collectionsService: CollectionsService
    @ObservationIgnored private let nftService: NftService
    @ObservationIgnored private var hasLoaded = false

    init(
        collection: NftCollection,
        collectionsService: CollectionsService,
        nftService: NftService
    ) {
        self.collection = collection
        self.collectionsService = collectionsService
        self.nftService = nftService
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await load()
    }

    /// Параллельно: свежая версия коллекции и NFT по уже известным id.
    /// NFT внутри сервиса тоже грузятся параллельно (withThrowingTaskGroup) с сохранением порядка.
    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }

        let knownIds = collection.nfts
        async let freshCollection = collectionsService.loadCollection(id: collection.id)
        do {
            var loaded = try await nftService.loadNfts(ids: knownIds)

            // Обновление коллекции не критично: если не удалось — остаёмся с тем, что пришло из каталога.
            if let fresh = try? await freshCollection {
                collection = fresh
                if fresh.nfts != knownIds {
                    loaded = try await nftService.loadNfts(ids: fresh.nfts)
                }
            }

            nfts = loaded
            hasLoaded = true
        } catch {
            guard !error.isCancellation else { return }
            self.error = error
        }
    }
}
