import SwiftUI
import UIKit

// MARK: - SwiftUI

extension Color {
    // Day / Night
    static let ypBlack = Color(ColorResource.ypBlack)
    static let ypWhite = Color(ColorResource.ypWhite)
    static let ypLightGrey = Color(ColorResource.ypLightGrey)

    // Universal
    static let ypGrey = Color(ColorResource.ypGrey)
    static let ypRed = Color(ColorResource.ypRed)
    static let ypBackground = Color(ColorResource.ypBackground)
    static let ypGreen = Color(ColorResource.ypGreen)
    static let ypBlue = Color(ColorResource.ypBlue)
    static let ypBlackUniversal = Color(ColorResource.ypBlackUniversal)
    static let ypWhiteUniversal = Color(ColorResource.ypWhiteUniversal)
    static let ypYellow = Color(ColorResource.ypYellow)
}

/// Позволяет писать `.foregroundStyle(.ypBlack)` и `.background(.ypWhite)`.
extension ShapeStyle where Self == Color {
    static var ypBlack: Color { Color(ColorResource.ypBlack) }
    static var ypWhite: Color { Color(ColorResource.ypWhite) }
    static var ypLightGrey: Color { Color(ColorResource.ypLightGrey) }
    static var ypGrey: Color { Color(ColorResource.ypGrey) }
    static var ypRed: Color { Color(ColorResource.ypRed) }
    static var ypBackground: Color { Color(ColorResource.ypBackground) }
    static var ypGreen: Color { Color(ColorResource.ypGreen) }
    static var ypBlue: Color { Color(ColorResource.ypBlue) }
    static var ypBlackUniversal: Color { Color(ColorResource.ypBlackUniversal) }
    static var ypWhiteUniversal: Color { Color(ColorResource.ypWhiteUniversal) }
    static var ypYellow: Color { Color(ColorResource.ypYellow) }
}

// MARK: - UIKit (экран NFT из шаблона)

extension UIColor {
    static let segmentActive = UIColor(resource: ColorResource.ypBlack)
    static let segmentInactive = UIColor(resource: ColorResource.ypLightGrey)
    static let closeButton = UIColor(resource: ColorResource.ypBlack)
}
