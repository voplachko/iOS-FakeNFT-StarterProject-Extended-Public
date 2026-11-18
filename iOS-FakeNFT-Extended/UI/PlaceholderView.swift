import SwiftUI

/// Временная заглушка экрана вкладки до реализации настоящего экрана.
struct PlaceholderView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.ypBold22)
            .foregroundStyle(.ypBlack)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.ypWhite)
    }
}

#Preview {
    PlaceholderView(title: "Профиль")
}
