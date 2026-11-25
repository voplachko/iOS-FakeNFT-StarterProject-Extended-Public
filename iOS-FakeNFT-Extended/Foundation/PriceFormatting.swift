import Foundation

extension Double {
    /// Цена в ETH с учётом локали: «1,78 ETH» (ru), «ETH 1.78» (en).
    func ethFormatted(locale: Locale = .current) -> String {
        formatted(
            .currency(code: "ETH")
                .precision(.fractionLength(2))
                .locale(locale)
        )
    }
}
