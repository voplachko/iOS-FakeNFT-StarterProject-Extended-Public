import Foundation

/// Значение поля формы: строка или массив строк (likes, nfts).
enum FormValue: Sendable, Equatable {
    case string(String)
    case array([String])
}

/// Собирает тело `application/x-www-form-urlencoded`.
///
/// Формат массивов (проверить в Postman повторным GET):
/// - `["1", "2"]` → `likes=1&likes=2` (`.repeatedKeys`) или `likes=1,2` (`.commaSeparated`);
/// - `[]` → `likes=null` — сервер очищает массив.
struct FormURLEncoder: Sendable {
    enum ArrayEncoding: Sendable {
        case repeatedKeys
        case commaSeparated
    }

    static let emptyArrayValue = "null"

    var arrayEncoding: ArrayEncoding = .repeatedKeys

    func encode(_ fields: [String: FormValue]) -> Data {
        Data(query(fields).utf8)
    }

    /// Строка вида `key=value&key2=value2`, ключи отсортированы для стабильного результата.
    func query(_ fields: [String: FormValue]) -> String {
        fields
            .sorted { $0.key < $1.key }
            .flatMap { pairs(key: $0.key, value: $0.value) }
            .map { "\(Self.escape($0.key))=\(Self.escape($0.value))" }
            .joined(separator: "&")
    }

    private func pairs(key: String, value: FormValue) -> [(key: String, value: String)] {
        switch value {
        case .string(let string):
            return [(key: key, value: string)]
        case .array(let items) where items.isEmpty:
            return [(key: key, value: Self.emptyArrayValue)]
        case .array(let items):
            switch arrayEncoding {
            case .repeatedKeys:
                return items.map { (key: key, value: $0) }
            case .commaSeparated:
                return [(key: key, value: items.joined(separator: ","))]
            }
        }
    }

    /// Экранирует всё, кроме unreserved-символов RFC 3986: кириллицу, пробелы, `&`, `=`, `+` и т.д.
    static func escape(_ string: String) -> String {
        string.addingPercentEncoding(withAllowedCharacters: unreserved) ?? string
    }

    private static let unreserved: CharacterSet = {
        var set = CharacterSet()
        set.insert(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return set
    }()
}
