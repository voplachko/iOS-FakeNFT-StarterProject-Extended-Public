import Foundation

private enum OrderEndpoint {
    static let url = URL(string: "\(RequestConstants.baseURL)/api/v1/orders/1")
}

struct OrderRequest: NetworkRequest {
    var endpoint: URL? { OrderEndpoint.url }
}

struct OrderUpdateRequest: NetworkRequest {
    let nfts: [String]

    var endpoint: URL? { OrderEndpoint.url }
    var httpMethod: HttpMethod { .put }
    var formFields: [String: FormValue]? { ["nfts": .array(nfts)] }
}
