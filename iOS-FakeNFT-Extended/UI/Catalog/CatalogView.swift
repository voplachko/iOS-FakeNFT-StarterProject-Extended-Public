import Kingfisher
import SwiftUI

/// Экран «Каталог»: список коллекций NFT.
struct CatalogView: View {
    @State private var viewModel: CatalogViewModel

    init(service: CollectionsService) {
        _viewModel = State(initialValue: CatalogViewModel(service: service))
    }

    var body: some View {
        List(viewModel.sortedCollections) { collection in
            CatalogCell(collection: collection)
                .background {
                    NavigationLink(value: collection) { EmptyView() }
                        .opacity(0)
                }
                .listRowInsets(EdgeInsets(
                    top: 0,
                    leading: Spacing.x4,
                    bottom: Constants.rowSpacing,
                    trailing: Spacing.x4
                ))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.ypWhite)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, Spacing.x5, for: .scrollContent)
        .background(.ypWhite)
        .refreshable { await viewModel.load() }
        .loadingOverlay(viewModel.isLoading && viewModel.collections.isEmpty)
        .sortable(selection: $viewModel.sortOption)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: NftCollection.self) { collection in
            // TODO: заменить на CollectionView (задача 1.18).
            PlaceholderView(title: collection.name)
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
}

/// Ячейка коллекции: обложка во всю ширину и подпись «Название (количество)».
private struct CatalogCell: View {
    let collection: NftCollection

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.x1) {
            Color.ypLightGrey
                .frame(height: Constants.coverHeight)
                .overlay {
                    KFImage(collection.coverURL)
                        .placeholder { ProgressView() }
                        .cancelOnDisappear(true)
                        .resizable()
                        .scaledToFill()
                }
                .clipShape(RoundedRectangle(cornerRadius: Radius.medium))

            Text(title)
                .font(.ypBold17)
                .foregroundStyle(.ypBlack)
                .lineLimit(1)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityAddTraits(.isButton)
    }

    private var title: String {
        String(
            format: NSLocalizedString("Catalog.collectionTitle", comment: ""),
            collection.name,
            collection.nfts.count
        )
    }
}

private enum Constants {
    static let coverHeight: CGFloat = 140
    static let rowSpacing: CGFloat = 21
}

#if DEBUG
#Preview("Данные") {
    NavigationStack {
        CatalogView(service: CollectionsServiceMock(delay: .seconds(1)))
    }
}

#Preview("Ошибка") {
    NavigationStack {
        CatalogView(service: CollectionsServiceMock(error: NetworkClientError.httpStatusCode(500)))
    }
}
#endif
