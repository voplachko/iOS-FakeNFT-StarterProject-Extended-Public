import Foundation

protocol OrderService: Sendable {
    func loadOrder() async throws -> Order
    /// Полностью заменяет список NFT в заказе. Пустой массив очищает корзину.
    func updateOrder(nfts: [String]) async throws -> Order
}

actor OrderServiceImpl: OrderService {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func loadOrder() async throws -> Order {
        try await networkClient.send(request: OrderRequest())
    }

    func updateOrder(nfts: [String]) async throws -> Order {
        try await networkClient.send(request: OrderUpdateRequest(nfts: nfts))
    }
}

#if DEBUG
/// Сервис для Preview: хранит заказ в памяти, сеть не трогает.
actor OrderServiceMock: OrderService {
    private var order: Order

    init(order: Order = .preview) {
        self.order = order
    }

    func loadOrder() async throws -> Order {
        order
    }

    func updateOrder(nfts: [String]) async throws -> Order {
        order = Order(id: order.id, nfts: nfts)
        return order
    }
}
#endif
