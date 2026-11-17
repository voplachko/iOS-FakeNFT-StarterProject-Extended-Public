import Foundation

@Observable
@MainActor
final class ServicesAssembly {

    private let networkClient: NetworkClient
    private let nftStorage: NftStorage

    let profileService: ProfileService
    let orderService: OrderService

    init(
        networkClient: NetworkClient,
        nftStorage: NftStorage
    ) {
        self.networkClient = networkClient
        self.nftStorage = nftStorage
        self.profileService = ProfileServiceImpl(networkClient: networkClient)
        self.orderService = OrderServiceImpl(networkClient: networkClient)
    }

    var nftService: NftService {
        NftServiceImpl(
            networkClient: networkClient,
            storage: nftStorage
        )
    }
}
