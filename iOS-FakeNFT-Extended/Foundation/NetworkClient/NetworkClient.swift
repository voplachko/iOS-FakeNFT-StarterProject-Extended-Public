import Foundation
import OSLog

enum NetworkClientError: Error {
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case urlSessionError
    case parsingError
    case incorrectRequest(String)
}

protocol NetworkClient: Sendable {
    func send(request: NetworkRequest) async throws -> Data
    func send<T: Decodable>(request: NetworkRequest) async throws -> T
}

actor DefaultNetworkClient: NetworkClient {
    private static let logger = Logger(subsystem: "FakeNFT", category: "Network")

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let formEncoder: FormURLEncoder

    init(
        session: URLSession = URLSession.shared,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
        formEncoder: FormURLEncoder = FormURLEncoder()
    ) {
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
        self.formEncoder = formEncoder
    }

    func send(request: NetworkRequest) async throws -> Data {
        let urlRequest = try create(request: request)
        let method = urlRequest.httpMethod ?? "GET"
        let path = urlRequest.url?.path ?? "-"

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            if !error.isCancellation {
                Self.logger.error("\(method) \(path) failed: \(error.localizedDescription)")
            }
            throw error
        }

        guard let response = response as? HTTPURLResponse else {
            throw NetworkClientError.urlSessionError
        }
        guard 200 ..< 300 ~= response.statusCode else {
            let body = String(data: data.prefix(300), encoding: .utf8) ?? ""
            Self.logger.error("\(method) \(path) → \(response.statusCode) \(body)")
            throw NetworkClientError.httpStatusCode(response.statusCode)
        }
        Self.logger.debug("\(method) \(path) → \(response.statusCode)")
        return data
    }

    func send<T: Decodable>(request: NetworkRequest) async throws -> T {
        let data = try await send(request: request)
        return try await parse(data: data)
    }

    // MARK: - Private

    private func create(request: NetworkRequest) throws -> URLRequest {
        guard let endpoint = request.endpoint else {
            throw NetworkClientError.incorrectRequest("Empty endpoint")
        }

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = request.httpMethod.rawValue

        if let formFields = request.formFields {
            urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = formEncoder.encode(formFields)
        } else if let dto = request.dto,
           let dtoEncoded = try? encoder.encode(dto) {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = dtoEncoded
        }
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        if RequestConstants.token.isEmpty {
            Self.logger.fault("RequestConstants.token is empty — server will reject requests")
        }
        urlRequest.addValue(RequestConstants.token, forHTTPHeaderField: "X-Practicum-Mobile-Token")

        return urlRequest
    }

    private func parse<T: Decodable>(data: Data) async throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkClientError.parsingError
        }
    }
}

extension Error {
    /// Отмена задачи: Swift Concurrency или URLSession. Такие ошибки не показываем пользователю.
    var isCancellation: Bool {
        if self is CancellationError { return true }
        if let urlError = self as? URLError, urlError.code == .cancelled { return true }
        return false
    }
}
