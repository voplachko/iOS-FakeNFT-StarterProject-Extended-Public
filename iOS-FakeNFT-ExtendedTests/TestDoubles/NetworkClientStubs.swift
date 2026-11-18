import XCTest
@testable import iOS_FakeNFT_Extended

/// Сетевой клиент-заглушка: запоминает запросы и отдаёт заданный JSON.
actor NetworkClientStub: NetworkClient {
    private let response: Data
    private(set) var requests: [NetworkRequest] = []

    init(response: String) {
        self.response = Data(response.utf8)
    }

    func send(request: NetworkRequest) async throws -> Data {
        requests.append(request)
        return response
    }

    func send<T: Decodable>(request: NetworkRequest) async throws -> T {
        let data = try await send(request: request)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

/// Клиент, который отвечает по пути запроса и отдаёт ответы в случайном порядке.
actor RoutingNetworkClientStub: NetworkClient {
    private let routes: [String: String]
    private(set) var requestedPaths: [String] = []
    private var inFlight = 0
    private(set) var maxInFlight = 0

    init(routes: [String: String]) {
        self.routes = routes
    }

    func send(request: NetworkRequest) async throws -> Data {
        let path = request.endpoint?.path ?? ""
        requestedPaths.append(path)
        inFlight += 1
        maxInFlight = max(maxInFlight, inFlight)
        // Случайная задержка — ответы приходят не по порядку.
        try await Task.sleep(for: .milliseconds(Int.random(in: 1...20)))
        inFlight -= 1
        guard let json = routes[path] else { throw NetworkClientError.httpStatusCode(404) }
        return Data(json.utf8)
    }

    func send<T: Decodable>(request: NetworkRequest) async throws -> T {
        let data = try await send(request: request)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
