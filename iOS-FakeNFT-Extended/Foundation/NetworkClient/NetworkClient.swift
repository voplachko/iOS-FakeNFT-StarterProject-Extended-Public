import Foundation

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
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let formEncoder: FormURLEncoder
    private let logger: NetworkLogger
    /// Номер запроса в логе — чтобы сопоставить REQUEST и RESPONSE при параллельной загрузке.
    private var requestCounter = 0

    init(
        session: URLSession = URLSession.shared,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
        formEncoder: FormURLEncoder = FormURLEncoder(),
        logger: NetworkLogger = NetworkLogger()
    ) {
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
        self.formEncoder = formEncoder
        self.logger = logger
    }

    func send(request: NetworkRequest) async throws -> Data {
        try await perform(request).data
    }

    func send<T: Decodable>(request: NetworkRequest) async throws -> T {
        let (data, id) = try await perform(request)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            logger.logDecodingError(error, type: T.self, data: data, id: id)
            throw NetworkClientError.parsingError
        }
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
        urlRequest.addValue(RequestConstants.token, forHTTPHeaderField: NetworkLogger.tokenHeader)

        return urlRequest
    }

    private func perform(_ request: NetworkRequest) async throws -> (data: Data, id: Int) {
        let urlRequest = try create(request: request)
        requestCounter += 1
        let id = requestCounter
        logger.logRequest(urlRequest, id: id)

        let clock = ContinuousClock()
        let start = clock.now
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            if !error.isCancellation {
                logger.logError(error, request: urlRequest, id: id, duration: clock.now - start)
            }
            throw error
        }

        guard let response = response as? HTTPURLResponse else {
            throw NetworkClientError.urlSessionError
        }
        logger.logResponse(response, data: data, request: urlRequest, id: id, duration: clock.now - start)

        guard 200 ..< 300 ~= response.statusCode else {
            throw NetworkClientError.httpStatusCode(response.statusCode)
        }
        return (data, id)
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
