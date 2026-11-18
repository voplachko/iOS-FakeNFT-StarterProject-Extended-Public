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
