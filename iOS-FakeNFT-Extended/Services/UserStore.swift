import Foundation
import Observation

/// Общее состояние лайков и корзины для всех вкладок.
///
/// Изменения применяются сразу (оптимистично), затем на сервер уходит весь список.
/// Запросы одного типа выполняются строго по очереди, чтобы более старый PUT
/// не перезаписал более новый. Пока запрос по NFT не завершён, повторное нажатие
/// по нему игнорируется. При ошибке откатывается только изменённый id и показывается алерт.
@MainActor
@Observable
final class UserStore {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed
    }

    private(set) var likedIds: Set<String> = []
    private(set) var cartIds: Set<String> = []
    private(set) var loadState: LoadState = .idle

    /// NFT, по которым сейчас идёт запрос, — их кнопки заблокированы.
    private(set) var pendingLikeIds: Set<String> = []
    private(set) var pendingCartIds: Set<String> = []

    /// Не удалось загрузить лайки и корзину при старте.
    private(set) var loadError: Error?
    /// Не удалось сохранить лайк или корзину — показывается алертом, изменение уже откатено.
    var syncError: Error?

    var isSyncErrorPresented: Bool {
        get { syncError != nil }
        set { if !newValue { syncError = nil } }
    }

    private let profileService: ProfileService
    private let orderService: OrderService
    @ObservationIgnored private var likesSync: Task<Void, Never>?
    @ObservationIgnored private var cartSync: Task<Void, Never>?

    init(profileService: ProfileService, orderService: OrderService) {
        self.profileService = profileService
        self.orderService = orderService
    }

    // MARK: - Queries

    func isLiked(_ id: String) -> Bool {
        likedIds.contains(id)
    }

    func isInCart(_ id: String) -> Bool {
        cartIds.contains(id)
    }

    func isLikePending(_ id: String) -> Bool {
        pendingLikeIds.contains(id)
    }

    func isCartPending(_ id: String) -> Bool {
        pendingCartIds.contains(id)
    }

    // MARK: - Loading

    /// Загружает лайки из профиля и корзину из заказа параллельно.
    func load() async {
        guard loadState != .loading else { return }
        loadState = .loading
        loadError = nil
        do {
            async let profile = profileService.loadProfile()
            async let order = orderService.loadOrder()
            let (loadedProfile, loadedOrder) = try await (profile, order)
            likedIds = Set(loadedProfile.likes)
            cartIds = Set(loadedOrder.nfts)
            loadState = .loaded
        } catch {
            loadError = error
            loadState = .failed
        }
    }

    // MARK: - Mutations

    /// - Returns: задача синхронизации или `nil`, если по этому NFT уже идёт запрос.
    @discardableResult
    func toggleLike(_ id: String) -> Task<Void, Never>? {
        let service = profileService
        return toggle(id, in: \.likedIds, pending: \.pendingLikeIds, queue: \.likesSync) { ids in
            _ = try await service.updateLikes(ids.sorted())
        }
    }

    /// - Returns: задача синхронизации или `nil`, если по этому NFT уже идёт запрос.
    @discardableResult
    func toggleCart(_ id: String) -> Task<Void, Never>? {
        let service = orderService
        return toggle(id, in: \.cartIds, pending: \.pendingCartIds, queue: \.cartSync) { ids in
            _ = try await service.updateOrder(nfts: ids.sorted())
        }
    }

    // MARK: - Private

    private typealias IdsKeyPath = ReferenceWritableKeyPath<UserStore, Set<String>>

    private func toggle(
        _ id: String,
        in ids: IdsKeyPath,
        pending: IdsKeyPath,
        queue: ReferenceWritableKeyPath<UserStore, Task<Void, Never>?>,
        send: @escaping (Set<String>) async throws -> Void
    ) -> Task<Void, Never>? {
        guard !self[keyPath: pending].contains(id) else { return nil }

        let wasMember = self[keyPath: ids].contains(id)
        setMembership(of: id, in: ids, to: !wasMember)
        self[keyPath: pending].insert(id)

        let previous = self[keyPath: queue]
        let task = Task { [weak self] in
            await previous?.value
            guard let self else { return }
            do {
                // Отправляем актуальный список на момент запроса — с учётом всех нажатий до него.
                try await send(self[keyPath: ids])
            } catch {
                setMembership(of: id, in: ids, to: wasMember)
                if !error.isCancellation {
                    syncError = error
                }
            }
            self[keyPath: pending].remove(id)
        }
        self[keyPath: queue] = task
        return task
    }

    private func setMembership(of id: String, in keyPath: IdsKeyPath, to isMember: Bool) {
        if isMember {
            self[keyPath: keyPath].insert(id)
        } else {
            self[keyPath: keyPath].remove(id)
        }
    }
}

#if DEBUG
extension UserStore {
    static func preview(
        profile: Profile = .preview,
        order: Order = .preview
    ) -> UserStore {
        UserStore(
            profileService: ProfileServiceMock(profile: profile),
            orderService: OrderServiceMock(order: order)
        )
    }
}
#endif
