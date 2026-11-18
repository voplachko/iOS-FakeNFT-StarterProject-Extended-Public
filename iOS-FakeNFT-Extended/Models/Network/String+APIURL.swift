import Foundation

extension String {
    /// URL из строки ответа API: пустая строка даёт nil,
    /// кириллица и пробелы (например, в обложках коллекций) кодируются.
    var apiURL: URL? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed) { return url }
        guard let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: encoded)
    }
}
