import SwiftUI
import UIKit

struct TabBarView: View {
    @State private var selectedTab: Tab = .catalog

    init() {
        Self.configureAppearance()
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                PlaceholderView(title: Tab.profile.title)
            }
            .tabItem { Tab.profile.label }
            .tag(Tab.profile)

            NavigationStack {
                TestCatalogView()
            }
            .tabItem { Tab.catalog.label }
            .tag(Tab.catalog)

            NavigationStack {
                PlaceholderView(title: Tab.cart.title)
            }
            .tabItem { Tab.cart.label }
            .tag(Tab.cart)

            NavigationStack {
                PlaceholderView(title: Tab.statistics.title)
            }
            .tabItem { Tab.statistics.label }
            .tag(Tab.statistics)
        }
        .tint(.ypBlue)
    }

    private static func configureAppearance() {
        let activeColor = UIColor(resource: ColorResource.ypBlue)
        let inactiveColor = UIColor(resource: ColorResource.ypBlack)
        let titleFont = UIFont.systemFont(ofSize: 10, weight: .medium)

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(resource: ColorResource.ypWhite)
        appearance.shadowColor = .clear

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = inactiveColor
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: inactiveColor, .font: titleFont]
        itemAppearance.selected.iconColor = activeColor
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: activeColor, .font: titleFont]

        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

extension TabBarView {
    enum Tab: Hashable {
        case profile
        case catalog
        case cart
        case statistics

        var title: String {
            switch self {
            case .profile: NSLocalizedString("Tab.profile", comment: "")
            case .catalog: NSLocalizedString("Tab.catalog", comment: "")
            case .cart: NSLocalizedString("Tab.cart", comment: "")
            case .statistics: NSLocalizedString("Tab.statistics", comment: "")
            }
        }

        private var imageName: String {
            switch self {
            case .profile: "ic30Profile"
            case .catalog: "ic30Catalog"
            case .cart: "ic30Basket"
            case .statistics: "ic30Statistics"
            }
        }

        var label: some View {
            Label {
                Text(title)
            } icon: {
                Image(imageName)
                    .renderingMode(.template)
            }
        }
    }
}

#Preview {
    TabBarView()
        .environment(ServicesAssembly(networkClient: DefaultNetworkClient(), nftStorage: NftStorageImpl()))
        .environment(UserStore.preview())
}
