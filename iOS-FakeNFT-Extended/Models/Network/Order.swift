import Foundation

struct Order: Decodable, Sendable, Identifiable, Hashable {
    let id: String
    let nfts: [String]
}
