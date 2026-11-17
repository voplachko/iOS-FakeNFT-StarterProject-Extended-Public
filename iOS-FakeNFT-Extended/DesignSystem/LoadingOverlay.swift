import SwiftUI

/// Полноэкранный индикатор загрузки по центру экрана.
struct FullScreenLoader: View {
    var body: some View {
        ProgressView()
            .controlSize(.large)
            .tint(.ypBlack)
            .frame(width: Constants.boxSize, height: Constants.boxSize)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Constants.cornerRadius))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
    }
}

private enum Constants {
    static let boxSize: CGFloat = 82
    static let cornerRadius: CGFloat = 16
}

private struct LoadingOverlayModifier: ViewModifier {
    let isLoading: Bool

    func body(content: Content) -> some View {
        content
            .allowsHitTesting(!isLoading)
            .overlay {
                if isLoading {
                    FullScreenLoader()
                }
            }
    }
}

extension View {
    /// Показывает лоадер поверх экрана и блокирует нажатия, пока идёт загрузка.
    func loadingOverlay(_ isLoading: Bool) -> some View {
        modifier(LoadingOverlayModifier(isLoading: isLoading))
    }
}

#Preview {
    List(1...20, id: \.self) { index in
        Text("Строка \(index)")
            .font(.ypRegular17)
    }
    .loadingOverlay(true)
}
