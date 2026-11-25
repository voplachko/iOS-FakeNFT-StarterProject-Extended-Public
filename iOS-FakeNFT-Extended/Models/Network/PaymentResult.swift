import Foundation

struct PaymentResult: Decodable, Sendable, Identifiable, Hashable {
    /// id валюты, которой оплачен заказ.
    let id: String
    let success: Bool
    let orderId: String
}
