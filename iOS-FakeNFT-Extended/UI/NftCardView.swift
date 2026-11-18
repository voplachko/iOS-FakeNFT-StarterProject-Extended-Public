import Kingfisher
import SwiftUI

/// Карточка NFT для сетки (макеты «Collection» и «Users collection»).
/// Лайк и корзина берутся из общего UserStore, поэтому сразу видны на других вкладках.
struct NftCardView: View {
    let nft: Nft

    @Environment(UserStore.self) private var userStore

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.x2) {
            image
            VStack(alignment: .leading, spacing: Spacing.x1) {
                RatingView(rating: nft.rating)
                info
            }
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Части

    private var image: some View {
        Color.ypLightGrey
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                KFImage(nft.images.first)
                    .placeholder { ProgressView() }
                    .cancelOnDisappear(true)
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
            .overlay(alignment: .topTrailing) {
                likeButton
            }
            .accessibilityHidden(true)
    }

    private var likeButton: some View {
        let isLiked = userStore.isLiked(nft.id)
        return Button {
            userStore.toggleLike(nft.id)
        } label: {
            Image(.ic40Heart)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(isLiked ? Color.ypRed : Color.ypWhiteUniversal)
                .frame(width: Constants.buttonSize, height: Constants.buttonSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(userStore.isLikePending(nft.id))
        .sensoryFeedback(.selection, trigger: isLiked)
        .accessibilityLabel(Text(NSLocalizedString(isLiked ? "Nft.unlike" : "Nft.like", comment: "")))
    }

    private var info: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.x1) {
                Text(nft.name)
                    .font(.ypBold17)
                    .foregroundStyle(.ypBlack)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(nft.price.ethFormatted())
                    .font(.ypMedium10)
                    .foregroundStyle(.ypBlack)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)

            Spacer(minLength: 0)

            cartButton
        }
    }

    private var cartButton: some View {
        let isInCart = userStore.isInCart(nft.id)
        return Button {
            userStore.toggleCart(nft.id)
        } label: {
            CartIcon(isInCart: isInCart)
                .frame(width: Constants.buttonSize, height: Constants.buttonSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(userStore.isCartPending(nft.id))
        .sensoryFeedback(.impact(weight: .light), trigger: isInCart)
        .accessibilityLabel(Text(NSLocalizedString(isInCart ? "Nft.removeFromCart" : "Nft.addToCart", comment: "")))
    }
}

/// Иконка корзины: обычная или с крестиком, если NFT уже в корзине.
private struct CartIcon: View {
    let isInCart: Bool

    var body: some View {
        Image(isInCart ? .ic40CartRemove : .ic40Cart)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: Constants.buttonSize, height: Constants.buttonSize)
            .foregroundStyle(.ypBlack)
    }
}

private enum Constants {
    static let buttonSize: CGFloat = 40
}

/// Сетка карточек NFT — общая для экрана коллекции и коллекции пользователя.
enum NftGrid {
    /// Расстояние между колонками — из макета (не кратно 4).
    static let columnSpacing: CGFloat = 9
    static let rowSpacing: CGFloat = Spacing.x7
    static let columns = Array(
        repeating: GridItem(.flexible(), spacing: columnSpacing, alignment: .top),
        count: 3
    )
}

#if DEBUG
extension Nft {
    static let previews: [Nft] = [
        Nft(
            id: "1",
            name: "Archie",
            images: [URL(string: "https://code.s3.yandex.net/Mobile/iOS/NFT/Pink/Archie/1.png")].compactMap { $0 },
            rating: 3,
            price: 1.78,
            author: "1"
        ),
        Nft(
            id: "2",
            name: "Ruby",
            images: [URL(string: "https://code.s3.yandex.net/Mobile/iOS/NFT/Pink/Ruby/1.png")].compactMap { $0 },
            rating: 5,
            price: 8.81,
            author: "1"
        ),
        Nft(
            id: "3",
            name: "Nacho Cheese Flamin Hot",
            images: [URL(string: "https://code.s3.yandex.net/Mobile/iOS/NFT/Pink/Nacho/1.png")].compactMap { $0 },
            rating: 1,
            price: 0.3,
            author: "1"
        )
    ]
}

#Preview {
    let store = UserStore.preview(
        profile: Profile(id: "1", name: "", avatar: "", description: "", website: "", nfts: [], likes: ["1"]),
        order: Order(id: "1", nfts: ["2"])
    )
    ScrollView {
        LazyVGrid(columns: NftGrid.columns, spacing: NftGrid.rowSpacing) {
            ForEach(Nft.previews) { nft in
                NftCardView(nft: nft)
            }
        }
        .padding(.horizontal, Spacing.x4)
    }
    .background(.ypWhite)
    .environment(store)
    .task { await store.load() }
}
#endif
