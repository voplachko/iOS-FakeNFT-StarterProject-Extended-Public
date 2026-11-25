import Foundation

struct Currency: Decodable, Sendable, Identifiable, Hashable {
    let id: String
    /// Полное название, например «Bitcoin».
    let title: String
    /// Тикер, например «BTC».
    let name: String
    let image: String

    var imageURL: URL? { image.apiURL }
}
