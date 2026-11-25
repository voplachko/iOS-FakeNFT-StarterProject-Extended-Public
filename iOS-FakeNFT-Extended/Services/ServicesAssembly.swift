import Foundation

@Observable
@MainActor
final class ServicesAssembly {

    private let networkClient: NetworkClient
    private let nftStorage: NftStorage

    let profileService: ProfileService
    let orderService: OrderService
    let collectionsService: CollectionsService
    /// Один экземпляр на приложение — общий кэш NFT для всех экранов.
    let nftService: NftService

    init(
        networkClient: NetworkClient,
        nftStorage: NftStorage
    ) {
        self.networkClient = networkClient
        self.nftStorage = nftStorage
        self.profileService = ProfileServiceImpl(networkClient: networkClient)
        self.orderService = OrderServiceImpl(networkClient: networkClient)
        self.collectionsService = CollectionsServiceImpl(networkClient: networkClient)
        self.nftService = NftServiceImpl(networkClient: networkClient, storage: nftStorage)
    }
}
