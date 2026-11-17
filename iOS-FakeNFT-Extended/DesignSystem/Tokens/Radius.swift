import CoreGraphics

/// Радиусы скругления углов.
enum Radius {
    /// 8 pt — мелкие элементы: поля ввода, бейджи.
    static let small: CGFloat = 8
    /// 12 pt — изображения NFT, обложки коллекций, аватары-карточки.
    static let medium: CGFloat = 12
    /// 16 pt — кнопки, плашки, лоадер.
    static let large: CGFloat = 16
}
