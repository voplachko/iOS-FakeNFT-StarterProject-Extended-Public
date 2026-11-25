import SwiftUI

struct NftDetailBridgeView: UIViewControllerRepresentable {
    @Environment(ServicesAssembly.self) var servicesAssembly
    /// По умолчанию — тестовый id из шаблона.
    var nftId = "7773e33c-ec15-4230-a102-92426a3a6d5a"

    func makeUIViewController(context: Context) -> UIViewController {
        NftDetailAssembly(servicesAssembler: servicesAssembly)
            .build(with: NftDetailInput(id: nftId))
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Обновляет состояние указанного контроллера представления новой информацией из SwiftUI.
    }
}
