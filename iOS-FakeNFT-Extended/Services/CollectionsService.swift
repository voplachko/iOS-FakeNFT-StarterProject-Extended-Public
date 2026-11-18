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

/// Сервис NFT для Preview.
actor NftServiceMock: NftService {
    private let nfts: [String: Nft]
    private let error: Error?
    private let delay: Duration
    private(set) var requestedIds: [[String]] = []

    init(nfts: [Nft] = Nft.previews, error: Error? = nil, delay: Duration = .zero) {
        self.nfts = Dictionary(uniqueKeysWithValues: nfts.map { ($0.id, $0) })
        self.error = error
        self.delay = delay
    }

    func loadNft(id: String) async throws -> Nft {
        try await simulateNetwork()
        guard let nft = nfts[id] else { throw NetworkClientError.httpStatusCode(404) }
        return nft
    }

    func loadNfts(ids: [String]) async throws -> [Nft] {
        requestedIds.append(ids)
        try await simulateNetwork()
        return ids.compactMap { nfts[$0] }
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

extension NftCollection {
    static let previews: [NftCollection] = [
        NftCollection(
            id: "1",
            name: "Peach",
            cover: "https://code.s3.yandex.net/Mobile/iOS/NFT/Обложки_коллекций/Peach.png",
            nfts: ["1", "2", "3"],
            description: "Персиковый — как облака над закатным солнцем в океане. В этой коллекции совмещены трогательная нежность и живая игривость сказочных зефирных зверей.",
            author: "John Doe",
            website: "https://practicum.yandex.ru/ios-developer"
        ),
        NftCollection(
            id: "2",
            name: "Blue",
            cover: "https://code.s3.yandex.net/Mobile/iOS/NFT/Обложки_коллекций/Blue.png",
            nfts: ["1", "2"],
            description: "Голубая коллекция.",
            author: "2"
        )
    ]
}
#endif
