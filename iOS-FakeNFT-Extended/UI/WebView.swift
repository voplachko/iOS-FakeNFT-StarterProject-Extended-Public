import SwiftUI
import WebKit

/// Обёртка над WKWebView. Сообщает прогресс загрузки страницы (0...1).
struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var progress: Double
    @Binding var isLoading: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(progress: $progress, isLoading: $isLoading)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.allowsBackForwardNavigationGestures = true
        context.coordinator.observe(webView)
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.progress = $progress
        context.coordinator.isLoading = $isLoading
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.stopLoading()
        coordinator.stopObserving()
    }

    @MainActor
    final class Coordinator {
        var progress: Binding<Double>
        var isLoading: Binding<Bool>
        private var observations: [NSKeyValueObservation] = []

        init(progress: Binding<Double>, isLoading: Binding<Bool>) {
            self.progress = progress
            self.isLoading = isLoading
        }

        func observe(_ webView: WKWebView) {
            // KVO у WKWebView приходит на главном потоке.
            observations = [
                webView.observe(\.estimatedProgress, options: [.initial, .new]) { [weak self] webView, _ in
                    MainActor.assumeIsolated {
                        self?.progress.wrappedValue = webView.estimatedProgress
                    }
                },
                webView.observe(\.isLoading, options: [.initial, .new]) { [weak self] webView, _ in
                    MainActor.assumeIsolated {
                        self?.isLoading.wrappedValue = webView.isLoading
                    }
                }
            ]
        }

        func stopObserving() {
            observations.forEach { $0.invalidate() }
            observations.removeAll()
        }
    }
}

/// Экран веб-страницы: кнопка «назад» и полоса прогресса загрузки (макет «Вебвью»).
struct WebScreen: View {
    let url: URL

    @Environment(\.dismiss) private var dismiss
    @State private var progress: Double = 0
    @State private var isLoading = true

    var body: some View {
        WebView(url: url, progress: $progress, isLoading: $isLoading)
            .ignoresSafeArea(edges: .bottom)
            .overlay(alignment: .top) {
                if isLoading {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .tint(.ypBlue)
                        .accessibilityLabel(Text(NSLocalizedString("Web.loading", comment: "")))
                }
            }
            .background(.ypWhite)
            .toolbar(.visible, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.backward")
                            .font(.ypBold17)
                            .foregroundStyle(.ypBlack)
                    }
                    .accessibilityLabel(Text(NSLocalizedString("Common.back", comment: "")))
                }
            }
            .toolbar(.hidden, for: .tabBar)
    }
}

/// Постоянные ссылки приложения.
enum AppLinks {
    static let userAgreement = URL(string: "https://yandex.ru/legal/practicum_termsofuse")
}

#Preview {
    NavigationStack {
        if let url = AppLinks.userAgreement {
            WebScreen(url: url)
        }
    }
}
