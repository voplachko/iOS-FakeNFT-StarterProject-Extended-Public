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
/// Сервис для Preview: отдаёт коллекции из памяти.
actor CollectionsServiceMock: CollectionsService {
    private let collections: [NftCollection]

    init(collections: [NftCollection] = NftCollection.previews) {
        self.collections = collections
    }

    func loadCollections() async throws -> [NftCollection] {
        collections
    }

    func loadCollection(id: String) async throws -> NftCollection {
        guard let collection = collections.first(where: { $0.id == id }) else {
            throw NetworkClientError.httpStatusCode(404)
        }
        return collection
    }
}

/// Сервис NFT для Preview.
actor NftServiceMock: NftService {
    private let nfts: [String: Nft]

    init(nfts: [Nft] = Nft.previews) {
        self.nfts = Dictionary(uniqueKeysWithValues: nfts.map { ($0.id, $0) })
    }

    func loadNft(id: String) async throws -> Nft {
        guard let nft = nfts[id] else { throw NetworkClientError.httpStatusCode(404) }
        return nft
    }

    func loadNfts(ids: [String]) async throws -> [Nft] {
        ids.compactMap { nfts[$0] }
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
            author: "1"
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
