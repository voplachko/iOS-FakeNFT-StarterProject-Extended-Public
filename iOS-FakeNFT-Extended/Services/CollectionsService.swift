import Foundation

protocol CollectionsService: Sendable {
    func loadCollections() async throws -> [NftCollection]
    func loadCollection(id: String) async throws -> NftCollection
}

actor CollectionsServiceImpl: CollectionsService {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func loadCollections() async throws -> [NftCollection] {
        try await networkClient.send(request: CollectionsRequest())
    }

    func loadCollection(id: String) async throws -> NftCollection {
        try await networkClient.send(request: CollectionRequest(id: id))
    }
}

#if DEBUG
/// Сервис для Preview и тестов: отдаёт коллекции из памяти, умеет «тормозить» и падать.
actor CollectionsServiceMock: CollectionsService {
    private let collections: [NftCollection]
    private let error: Error?
    private let delay: Duration

    init(
        collections: [NftCollection] = NftCollection.previews,
        error: Error? = nil,
        delay: Duration = .zero
    ) {
        self.collections = collections
        self.error = error
        self.delay = delay
    }

    func loadCollections() async throws -> [NftCollection] {
        try await simulateNetwork()
        return collections
    }

    func loadCollection(id: String) async throws -> NftCollection {
        try await simulateNetwork()
        guard let collection = collections.first(where: { $0.id == id }) else {
            throw NetworkClientError.httpStatusCode(404)
        }
        return collection
    }

    private func simulateNetwork() async throws {
        if delay > .zero {
            try await Task.sleep(for: delay)
        }
        if let error {
            throw error
        }
    }
}
#endif
