import Kingfisher
import SwiftUI

/// Экран коллекции (макет «Collection»): обложка, название, автор, описание и сетка NFT.
struct CollectionView: View {
    @State private var viewModel: CollectionViewModel
    @State private var selectedNft: Nft?
    @Environment(\.dismiss) private var dismiss

    init(
        collection: NftCollection,
        collectionsService: CollectionsService,
        nftService: NftService
    ) {
        _viewModel = State(initialValue: CollectionViewModel(
            collection: collection,
            collectionsService: collectionsService,
            nftService: nftService
        ))
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    CollectionCover(url: viewModel.collection.coverURL)
                    info
                        .padding(.horizontal, Spacing.x4)
                        .padding(.top, Spacing.x4)
                    grid
                        .padding(.horizontal, Spacing.x4)
                        .padding(.top, Spacing.x6)
                        .padding(.bottom, Spacing.x6)
                }
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)
            .refreshable { await viewModel.load() }

            backButton
        }
        .background(.ypWhite)
        .toolbar(.hidden, for: .navigationBar)
        // По макету на экране коллекции таббара нет.
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
        .sheet(item: $selectedNft) { nft in
            // Экран NFT из шаблона (делает наставник).
            NftDetailBridgeView(nftId: nft.id)
                .ignoresSafeArea()
        }
        .alert(
            Text(NSLocalizedString("Error.loadData", comment: "")),
            isPresented: $viewModel.isErrorPresented
        ) {
            Button(NSLocalizedString("Error.cancel", comment: ""), role: .cancel) {}
            Button(NSLocalizedString("Error.repeat", comment: "")) {
                Task { await viewModel.load() }
            }
        }
        .task { await viewModel.loadIfNeeded() }
    }

    // MARK: - Части

    private var info: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(viewModel.collection.name)
                .font(.ypBold22)
                .foregroundStyle(.ypBlack)
                .accessibilityAddTraits(.isHeader)

            author
                .padding(.top, Spacing.x2)

            Text(viewModel.collection.description)
                .font(.ypRegular13)
                .foregroundStyle(.ypBlack)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Spacing.x1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var author: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.x1) {
            Text(NSLocalizedString("Collection.author", comment: ""))
                .font(.ypRegular13)
                .foregroundStyle(.ypBlack)

            if let url = viewModel.collection.websiteURL {
                NavigationLink {
                    WebScreen(url: url)
                } label: {
                    Text(viewModel.collection.author)
                        .font(.ypRegular15)
                        .foregroundStyle(.ypBlue)
                        .lineLimit(1)
                }
                .accessibilityHint(Text(NSLocalizedString("Collection.authorHint", comment: "")))
            } else {
                Text(viewModel.collection.author)
                    .font(.ypRegular15)
                    .foregroundStyle(.ypBlack)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private var grid: some View {
        if viewModel.nfts.isEmpty && viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.x6)
        } else {
            LazyVGrid(columns: NftGrid.columns, spacing: NftGrid.rowSpacing) {
                ForEach(viewModel.nfts) { nft in
                    NftCardView(nft: nft)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedNft = nft }
                        .accessibilityAction(named: Text(NSLocalizedString("Nft.open", comment: ""))) {
                            selectedNft = nft
                        }
                }
            }
        }
    }

    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.backward")
                .font(.ypBold17)
                .foregroundStyle(.ypBlack)
                .frame(width: Constants.backButtonSize, height: Constants.backButtonSize)
                .contentShape(Rectangle())
        }
        .padding(.leading, Spacing.x1)
        .accessibilityLabel(Text(NSLocalizedString("Common.back", comment: "")))
    }
}

private struct CollectionCover: View {
    let url: URL?

    var body: some View {
        GeometryReader { geometry in
            let stretch = max(0, geometry.frame(in: .scrollView).minY)
            Color.ypLightGrey
                .overlay {
                    KFImage(url)
                        .placeholder { ProgressView() }
                        .resizable()
                        .scaledToFill()
                }
                .frame(width: geometry.size.width, height: Constants.coverHeight + stretch)
                .clipShape(UnevenRoundedRectangle(
                    bottomLeadingRadius: Radius.medium,
                    bottomTrailingRadius: Radius.medium
                ))
                .offset(y: -stretch)
        }
        .frame(height: Constants.coverHeight)
        .accessibilityHidden(true)
    }
}

private enum Constants {
    static let coverHeight: CGFloat = 310
    static let backButtonSize: CGFloat = 24
}

#if DEBUG
#Preview {
    let store = UserStore.preview()
    NavigationStack {
        CollectionView(
            collection: NftCollection.previews[0],
            collectionsService: CollectionsServiceMock(),
            nftService: NftServiceMock(delay: .seconds(1))
        )
    }
    .environment(store)
    .task { await store.load() }
}
#endif
