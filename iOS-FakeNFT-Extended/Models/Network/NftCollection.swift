import Foundation

struct NftCollection: Decodable, Sendable, Identifiable, Hashable {
    let id: String
    let name: String
    let cover: String
    let nfts: [String]
    let description: String
    let author: String
    /// Сайт автора коллекции (открывается во WebView).
    var website: String?

    var coverURL: URL? { cover.apiURL }
    var websiteURL: URL? { website?.apiURL }
}
