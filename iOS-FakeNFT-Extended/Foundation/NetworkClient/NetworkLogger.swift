import Foundation

/// Читаемый лог сети в консоли Xcode. Печатает только в Debug-сборке.
///
/// ```
/// ─────────────── REQUEST #3 ───────────────
/// PUT v1/profile/1
///
/// Headers:
///   Accept: application/json
///   Content-Type: application/x-www-form-urlencoded
///   X-Practicum-Mobile-Token: 431a…9f2c
///
/// Body (form):
///   likes = 1
///   name = Студентус Практикумус
/// ──────────────────────────────────────────
/// ```
struct NetworkLogger: Sendable {
    /// Длинные ответы (список NFT) обрезаются, чтобы не заливать консоль.
    var maxBodyLength = 4_000

    // MARK: - Печать

    func logRequest(_ request: URLRequest, id: Int) {
        log(formatRequest(request, id: id))
    }

    func logResponse(_ response: HTTPURLResponse, data: Data, request: URLRequest, id: Int, duration: Duration) {
        log(formatResponse(response, data: data, request: request, id: id, duration: duration))
    }

    func logError(_ error: Error, request: URLRequest, id: Int, duration: Duration) {
        log(formatError(error, request: request, id: id, duration: duration))
    }

    func logDecodingError(_ error: Error, type: Any.Type, data: Data, id: Int) {
        log(formatDecodingError(error, type: type, data: data, id: id))
    }

    private func log(_ message: String) {
        #if DEBUG
        print(message)
        #endif
    }

    // MARK: - Форматирование

    func formatRequest(_ request: URLRequest, id: Int) -> String {
        var lines = [requestLine(request)]
        lines += section("Headers", headerLines(request.allHTTPHeaderFields ?? [:]))

        if let body = request.httpBody, !body.isEmpty {
            let contentType = request.value(forHTTPHeaderField: "Content-Type") ?? ""
            if contentType.contains("x-www-form-urlencoded") {
                lines += section("Body (form)", formLines(body))
            } else {
                lines += section("Body", bodyLines(body))
            }
        }
        if request.value(forHTTPHeaderField: Self.tokenHeader)?.isEmpty ?? true {
            lines += ["", "⚠️ Токен пустой — сервер отклонит запрос (RequestConstants.token)"]
        }
        return frame(title: "REQUEST #\(id)", lines: lines)
    }

    func formatResponse(
        _ response: HTTPURLResponse,
        data: Data,
        request: URLRequest,
        id: Int,
        duration: Duration
    ) -> String {
        let isSuccess = 200 ..< 300 ~= response.statusCode
        let status = HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
        var lines = [
            requestLine(request),
            "Status: \(isSuccess ? "✅" : "❌") \(response.statusCode) \(status) · \(milliseconds(duration)) · \(byteCount(data.count))"
        ]
        lines += section("Body", data.isEmpty ? ["(пусто)"] : bodyLines(data))
        return frame(title: "RESPONSE #\(id)", lines: lines)
    }

    func formatError(_ error: Error, request: URLRequest, id: Int, duration: Duration) -> String {
        var lines = [requestLine(request)]
        lines.append("❌ \(error.localizedDescription)")
        if let urlError = error as? URLError {
            lines.append("URLError code: \(urlError.code.rawValue)")
            if urlError.code == .notConnectedToInternet || urlError.code == .cannotFindHost || urlError.code == .timedOut {
                lines.append("Подсказка: сервер доступен только через VPN")
            }
        }
        lines.append("Время: \(milliseconds(duration))")
        return frame(title: "ERROR #\(id)", lines: lines)
    }

    func formatDecodingError(_ error: Error, type: Any.Type, data: Data, id: Int) -> String {
        var lines = ["Не удалось разобрать ответ в \(type)", "❌ \(Self.describe(error))"]
        lines += section("Body", bodyLines(data))
        return frame(title: "PARSING ERROR #\(id)", lines: lines)
    }

    // MARK: - Части

    static let tokenHeader = "X-Practicum-Mobile-Token"

    private func requestLine(_ request: URLRequest) -> String {
        "\(request.httpMethod ?? "GET") \(Self.shortPath(request.url))"
    }

    /// `https://host/api/v1/nft?page=1` → `v1/nft?page=1`: хост и `/api/` одинаковые у всех запросов.
    static func shortPath(_ url: URL?) -> String {
        guard let url else { return "-" }
        var path = url.path
        for prefix in ["/api/", "/"] where path.hasPrefix(prefix) {
            path.removeFirst(prefix.count)
            break
        }
        if let query = url.query, !query.isEmpty {
            path += "?\(query)"
        }
        return path.isEmpty ? "/" : path
    }

    private func headerLines(_ headers: [String: String]) -> [String] {
        headers
            .sorted { $0.key < $1.key }
            .map { key, value in
                "\(key): \(key == Self.tokenHeader ? Self.mask(value) : value)"
            }
    }

    private func formLines(_ body: Data) -> [String] {
        guard let query = String(data: body, encoding: .utf8) else { return ["(не UTF-8)"] }
        return query
            .split(separator: "&")
            .map { pair in
                let parts = pair.split(separator: "=", maxSplits: 1).map {
                    String($0).removingPercentEncoding ?? String($0)
                }
                return "\(parts.first ?? "") = \(parts.count > 1 ? parts[1] : "")"
            }
    }

    private func bodyLines(_ data: Data) -> [String] {
        truncate(Self.prettyJSON(data) ?? String(decoding: data, as: UTF8.self))
            .components(separatedBy: "\n")
    }

    private func section(_ title: String, _ lines: [String]) -> [String] {
        guard !lines.isEmpty else { return [] }
        return ["", "\(title):"] + lines.map { "  \($0)" }
    }

    private func frame(title: String, lines: [String]) -> String {
        let width = 44
        let side = String(repeating: "─", count: max(3, (width - title.count - 2) / 2))
        let top = "\(side) \(title) \(side)"
        let bottom = String(repeating: "─", count: top.count)
        return ([top] + lines + [bottom]).joined(separator: "\n") + "\n"
    }

    private func truncate(_ text: String) -> String {
        guard text.count > maxBodyLength else { return text }
        return String(text.prefix(maxBodyLength)) + "\n… (ещё \(text.count - maxBodyLength) символов)"
    }

    private func milliseconds(_ duration: Duration) -> String {
        let ms = Double(duration.components.seconds) * 1_000
            + Double(duration.components.attoseconds) / 1e15
        return "\(Int(ms.rounded())) ms"
    }

    private func byteCount(_ count: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(count), countStyle: .file)
    }

    // MARK: - Утилиты

    /// `431a48d1-…-c2f1` → `431a…c2f1`. Токен не попадает в логи целиком.
    static func mask(_ token: String) -> String {
        guard !token.isEmpty else { return "(пусто)" }
        guard token.count > 8 else { return String(repeating: "•", count: token.count) }
        return "\(token.prefix(4))…\(token.suffix(4))"
    }

    static func prettyJSON(_ data: Data) -> String? {
        guard
            let object = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]),
            let pretty = try? JSONSerialization.data(
                withJSONObject: object,
                options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes, .fragmentsAllowed]
            )
        else { return nil }
        return String(data: pretty, encoding: .utf8)
    }

    /// Понятное описание DecodingError: какое поле и что не так.
    static func describe(_ error: Error) -> String {
        guard let decodingError = error as? DecodingError else { return error.localizedDescription }
        func path(_ context: DecodingError.Context) -> String {
            let keys = context.codingPath.map { $0.intValue.map { "[\($0)]" } ?? $0.stringValue }
            return keys.isEmpty ? "<корень>" : keys.joined(separator: ".")
        }
        switch decodingError {
        case .typeMismatch(let type, let context):
            return "Неверный тип в «\(path(context))»: ожидался \(type). \(context.debugDescription)"
        case .valueNotFound(let type, let context):
            return "Нет значения \(type) в «\(path(context))»"
        case .keyNotFound(let key, let context):
            return "Нет ключа «\(key.stringValue)» в «\(path(context))»"
        case .dataCorrupted(let context):
            return "Повреждённые данные в «\(path(context))»: \(context.debugDescription)"
        @unknown default:
            return decodingError.localizedDescription
        }
    }
}
