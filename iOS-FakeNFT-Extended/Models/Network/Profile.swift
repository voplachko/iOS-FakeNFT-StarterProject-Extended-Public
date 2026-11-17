import Foundation

struct Profile: Decodable, Sendable, Identifiable, Hashable {
    let id: String
    let name: String
    let avatar: String
    let description: String
    let website: String
    let nfts: [String]
    let likes: [String]

    var avatarURL: URL? { avatar.apiURL }
    var websiteURL: URL? { website.apiURL }
}
