import CoreGraphics

/// Отступы по сетке 4 pt: `x1` = 4, `x2` = 8 … Для padding и spacing в стеках.
///
/// Значения не из сетки (например, 9 pt между колонками в макете) объявляются
/// рядом с экраном как именованная константа с комментарием «из макета».
enum Spacing {
    static let x0_5: CGFloat = 2
    static let x1: CGFloat = 4
    static let x2: CGFloat = 8
    static let x3: CGFloat = 12
    static let x4: CGFloat = 16
    static let x5: CGFloat = 20
    static let x6: CGFloat = 24
    static let x7: CGFloat = 28
    static let x8: CGFloat = 32
    static let x10: CGFloat = 40
    static let x12: CGFloat = 48
}
