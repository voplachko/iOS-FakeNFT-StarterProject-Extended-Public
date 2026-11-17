import SwiftUI

/// Рейтинг NFT: 5 звёзд, заполненные — жёлтые, остальные — серые.
struct RatingView: View {
    static let maxRating = 5

    let rating: Int

    var body: some View {
        HStack(spacing: Constants.spacing) {
            ForEach(1...Self.maxRating, id: \.self) { index in
                Image(systemName: "star.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: Constants.starSize, height: Constants.starSize)
                    .foregroundStyle(index <= clampedRating ? Color.ypYellow : Color.ypLightGrey)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(String(
            format: NSLocalizedString("Rating.accessibility", comment: ""),
            clampedRating,
            Self.maxRating
        )))
    }

    private var clampedRating: Int {
        min(max(rating, 0), Self.maxRating)
    }
}

private enum Constants {
    static let starSize: CGFloat = 12
    static let spacing: CGFloat = 2
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        ForEach(0...5, id: \.self) { rating in
            RatingView(rating: rating)
        }
    }
    .padding()
    .background(.ypWhite)
}
