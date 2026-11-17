import SwiftUI

@main
@MainActor
struct iOS_FakeNFT_ExtendedApp: App {
    @State private var servicesAssembly: ServicesAssembly
    @State private var userStore: UserStore

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
            ContentView()
                .environment(servicesAssembly)
                .environment(userStore)
                .task {
                    await userStore.load()
                }
        }
    }
}
