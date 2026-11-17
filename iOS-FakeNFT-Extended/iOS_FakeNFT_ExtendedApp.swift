import SwiftUI

@main
@MainActor
struct iOS_FakeNFT_ExtendedApp: App {
    @State private var servicesAssembly: ServicesAssembly
    @State private var userStore: UserStore
    @State private var isSplashVisible = true

    init() {
        let assembly = ServicesAssembly(
            networkClient: DefaultNetworkClient(),
            nftStorage: NftStorageImpl()
        )
        _servicesAssembly = State(initialValue: assembly)
        _userStore = State(initialValue: UserStore(
            profileService: assembly.profileService,
            orderService: assembly.orderService
        ))
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .task {
                        await userStore.load()
                    }

                if isSplashVisible {
                    SplashView(isReady: isInitialLoadFinished) {
                        isSplashVisible = false
                    }
                    .zIndex(1)
                }
            }
            .environment(servicesAssembly)
            .environment(userStore)
        }
    }

    private var isInitialLoadFinished: Bool {
        userStore.loadState == .loaded || userStore.loadState == .failed
    }
}
