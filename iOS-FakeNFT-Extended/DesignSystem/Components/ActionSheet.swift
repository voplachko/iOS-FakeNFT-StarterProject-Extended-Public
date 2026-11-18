import SwiftUI
import UIKit

/// Пункт action sheet.
struct ActionSheetAction: Identifiable {
    enum Role {
        case regular
        case destructive
    }

    let id: String
    let title: String
    var role: Role = .regular
    let handler: () -> Void
}

extension View {
    func actionSheet(
        isPresented: Binding<Bool>,
        title: String?,
        actions: [ActionSheetAction],
        cancelTitle: String = NSLocalizedString("Sort.close", comment: "")
    ) -> some View {
        background(
            ActionSheetPresenter(
                isPresented: isPresented,
                title: title,
                actions: actions,
                cancelTitle: cancelTitle
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        )
    }
}

private struct ActionSheetPresenter: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let title: String?
    let actions: [ActionSheetAction]
    let cancelTitle: String

    final class Coordinator {
        var alert: UIAlertController?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        controller.view.isUserInteractionEnabled = false
        return controller
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {
        let coordinator = context.coordinator

        if isPresented, coordinator.alert == nil {
            let alert = makeAlert(coordinator: coordinator)
            if controller.traitCollection.userInterfaceIdiom == .pad {
                // На iPad action sheet обязан иметь точку привязки.
                alert.popoverPresentationController?.sourceView = controller.view
                alert.popoverPresentationController?.sourceRect = controller.view.bounds
            }
            coordinator.alert = alert
            // Показываем после текущего прохода обновления SwiftUI.
            Task { @MainActor in
                controller.present(alert, animated: true)
            }
        } else if !isPresented, let alert = coordinator.alert {
            coordinator.alert = nil
            alert.dismiss(animated: true)
        }
    }

    private func makeAlert(coordinator: Coordinator) -> UIAlertController {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        let isPresented = $isPresented

        for action in actions {
            let style: UIAlertAction.Style = action.role == .destructive ? .destructive : .default
            alert.addAction(UIAlertAction(title: action.title, style: style) { _ in
                coordinator.alert = nil
                isPresented.wrappedValue = false
                action.handler()
            })
        }
        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel) { _ in
            coordinator.alert = nil
            isPresented.wrappedValue = false
        })
        return alert
    }
}

#Preview {
    @Previewable @State var isPresented = false
    Button("Показать") { isPresented = true }
        .actionSheet(
            isPresented: $isPresented,
            title: "Сортировка",
            actions: [
                ActionSheetAction(id: "a", title: "По названию") {},
                ActionSheetAction(id: "b", title: "По количеству NFT") {}
            ]
        )
}
