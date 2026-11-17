import Foundation

struct NftCollection: Decodable, Sendable, Identifiable, Hashable {
    let id: String
    let name: String
    let cover: String
    let nfts: [String]
    let description: String
    let author: String

    var coverURL: URL? { cover.apiURL }
}
