import Foundation
import Observation

/// Общее состояние лайков и корзины для всех вкладок.
///
/// Изменения применяются сразу (оптимистично), затем на сервер уходит весь список.
/// Запросы одного типа выполняются строго по очереди, чтобы более старый PUT
/// не перезаписал более новый. При ошибке откатывается только изменённый id.
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
    /// Последняя ошибка синхронизации — для показа алерта.
    var lastError: Error?

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

    // MARK: - Loading

    /// Загружает лайки из профиля и корзину из заказа параллельно.
    func load() async {
        guard loadState != .loading else { return }
        loadState = .loading
        do {
            async let profile = profileService.loadProfile()
            async let order = orderService.loadOrder()
            let (loadedProfile, loadedOrder) = try await (profile, order)
            likedIds = Set(loadedProfile.likes)
            cartIds = Set(loadedOrder.nfts)
            loadState = .loaded
        } catch {
            lastError = error
            loadState = .failed
        }
    }

    // MARK: - Mutations

    @discardableResult
    func toggleLike(_ id: String) -> Task<Void, Never> {
        let wasLiked = likedIds.contains(id)
        setMembership(of: id, in: \.likedIds, to: !wasLiked)

        let previous = likesSync
        let task = Task { [weak self] in
            await previous?.value
            guard let self else { return }
            do {
                _ = try await profileService.updateLikes(likedIds.sorted())
            } catch {
                setMembership(of: id, in: \.likedIds, to: wasLiked)
                lastError = error
            }
        }
        likesSync = task
        return task
    }

    @discardableResult
    func toggleCart(_ id: String) -> Task<Void, Never> {
        let wasInCart = cartIds.contains(id)
        setMembership(of: id, in: \.cartIds, to: !wasInCart)

        let previous = cartSync
        let task = Task { [weak self] in
            await previous?.value
            guard let self else { return }
            do {
                _ = try await orderService.updateOrder(nfts: cartIds.sorted())
            } catch {
                setMembership(of: id, in: \.cartIds, to: wasInCart)
                lastError = error
            }
        }
        cartSync = task
        return task
    }

    // MARK: - Private

    private func setMembership(
        of id: String,
        in keyPath: ReferenceWritableKeyPath<UserStore, Set<String>>,
        to isMember: Bool
    ) {
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
