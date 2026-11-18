import Foundation

protocol NftService: Sendable {
    func loadNft(id: String) async throws -> Nft
    /// Загружает NFT параллельно и возвращает их в порядке `ids`.
    func loadNfts(ids: [String]) async throws -> [Nft]
}

actor NftServiceImpl: NftService {
    /// Сколько запросов NFT выполняется одновременно.
    static let maxConcurrentRequests = 6

    private let networkClient: NetworkClient
    private let storage: NftStorage

    init(networkClient: NetworkClient, storage: NftStorage) {
        self.networkClient = networkClient
        self.storage = storage
    }

    func loadNft(id: String) async throws -> Nft {
        if let nft = await storage.getNft(with: id) {
            return nft
        }
        let nft: Nft = try await networkClient.send(request: NFTRequest(id: id))
        await storage.saveNft(nft)
        return nft
    }

    func loadNfts(ids: [String]) async throws -> [Nft] {
        guard !ids.isEmpty else { return [] }

        return try await withThrowingTaskGroup(of: (Int, Nft).self) { group in
            var results = [Nft?](repeating: nil, count: ids.count)
            var nextIndex = 0

            func addTask(for index: Int) {
                let id = ids[index]
                group.addTask {
                    let nft = try await self.loadNft(id: id)
                    return (index, nft)
                }
            }

            // Скользящее окно: не больше maxConcurrentRequests запросов одновременно.
            while nextIndex < min(Self.maxConcurrentRequests, ids.count) {
                addTask(for: nextIndex)
                nextIndex += 1
            }
            while let (index, nft) = try await group.next() {
                results[index] = nft
                if nextIndex < ids.count {
                    addTask(for: nextIndex)
                    nextIndex += 1
                }
            }
            return results.compactMap { $0 }
        }
    }
}

#if DEBUG
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
#endif
