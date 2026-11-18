import Foundation

struct User: Decodable, Sendable, Identifiable, Hashable {
    let id: String
    let name: String
    let avatar: String
    let description: String
    let website: String
    let nfts: [String]
    let rating: Int

    var avatarURL: URL? { avatar.apiURL }
    var websiteURL: URL? { website.apiURL }
}

// init(from:) вынесен в расширение, чтобы сохранился memberwise-инициализатор для превью и тестов.
extension User {
    private enum CodingKeys: String, CodingKey {
        case id, name, avatar, description, website, nfts, rating
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        avatar = try container.decodeIfPresent(String.self, forKey: .avatar) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        website = try container.decodeIfPresent(String.self, forKey: .website) ?? ""
        nfts = try container.decodeIfPresent([String].self, forKey: .nfts) ?? []

        // API отдаёт rating строкой ("51"), но на всякий случай принимаем и число.
        if let value = try? container.decode(Int.self, forKey: .rating) {
            rating = value
        } else {
            let string = try container.decode(String.self, forKey: .rating)
            guard let value = Int(string) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .rating,
                    in: container,
                    debugDescription: "Rating is not a number: \(string)"
                )
            }
            rating = value
        }
    }
}
