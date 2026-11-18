import Foundation

struct Nft: Decodable, Sendable, Identifiable, Hashable {
    let id: String
    let name: String
    let images: [URL]
    let rating: Int
    let price: Double
    let author: String
}
