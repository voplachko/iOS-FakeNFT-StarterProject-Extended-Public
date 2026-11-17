import SwiftUI

/// Анимированная заставка поверх приложения. Первый кадр в точности совпадает
/// с LaunchScreen.storyboard, поэтому переход со статичного лаунчскрина незаметен.
struct SplashView: View {
    /// Данные для первого экрана загружены (или загрузка завершилась ошибкой).
    let isReady: Bool
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var haptics = SplashHaptics()
    @State private var phase: Phase = .launch
    @State private var phaseStart = Date()
    @State private var exitStartOffset: CGFloat = 0
    @State private var isReadyLatched = false
    @State private var fadeOpacity: Double = 1

    private enum Phase {
        case launch
        case intro
        case idle
        case exit
    }

    var body: some View {
        TimelineView(.animation(paused: phase == .launch)) { context in
            let pose = pose(at: context.date)
            Canvas { canvas, size in
                SplashRenderer.draw(pose, in: &canvas, size: size)
            }
        }
        .ignoresSafeArea()
        .opacity(fadeOpacity)
        .accessibilityHidden(true)
        .onChange(of: isReady, initial: true) { _, ready in
            isReadyLatched = isReadyLatched || ready
            if ready { startExitIfIdle() }
        }
        .task {
            await run()
        }
    }

    // MARK: - Сценарий

    private func run() async {
        if !reduceMotion {
            haptics.prepare()
            begin(.intro)
            haptics.play(.intro)
            try? await Task.sleep(for: .seconds(SplashTimeline.introEnd))
        }
        begin(.idle)
        if isReadyLatched {
            startExitIfIdle()
            return
        }
        // Не держим пользователя дольше разумного, даже если сеть медленная.
        try? await Task.sleep(for: .seconds(SplashTimeline.maxIdle))
        startExitIfIdle()
    }

    private func startExitIfIdle() {
        guard phase == .idle else { return }

        if reduceMotion {
            phase = .exit
            withAnimation(.easeOut(duration: 0.3)) {
                fadeOpacity = 0
            } completion: {
                onFinish()
            }
            return
        }

        exitStartOffset = SplashTimeline.idle(at: Date().timeIntervalSince(phaseStart)).lintelOffsetY
        begin(.exit)
        haptics.play(.exit)
        Task {
            try? await Task.sleep(for: .seconds(SplashTimeline.exitEnd))
            haptics.stop()
            onFinish()
        }
    }

    private func begin(_ newPhase: Phase) {
        phaseStart = Date()
        phase = newPhase
    }

    private func pose(at date: Date) -> LogoPose {
        let t = date.timeIntervalSince(phaseStart)
        switch phase {
        case .launch:
            return .rest
        case .intro:
            return SplashTimeline.intro(at: t)
        case .idle:
            return reduceMotion ? .rest : SplashTimeline.idle(at: t)
        case .exit:
            return reduceMotion ? .rest : SplashTimeline.exit(at: t, startOffset: exitStartOffset)
        }
    }
}

/// Рисует фон с проёмом и три бруска логотипа для заданной позы.
enum SplashRenderer {
    private typealias G = LogoGeometry

    static func draw(_ pose: LogoPose, in context: inout GraphicsContext, size: CGSize) {
        let origin = CGPoint(
            x: (size.width - G.size.width) / 2,
            y: (size.height - G.size.height) / 2
        )
        let t = G.barThickness

        let left = pillarRect(x: origin.x, origin: origin, scaleY: pose.leftPillarScaleY)
        let right = pillarRect(x: origin.x + G.size.width - t, origin: origin, scaleY: pose.rightPillarScaleY)

        let lintelWidth = G.lintelWidth * pose.lintelScaleX
        let lintelHeight = t * pose.lintelScaleY
        let lintelCenter = CGPoint(
            x: origin.x + (G.lintelMinX + G.lintelMaxX) / 2,
            y: origin.y + t / 2 + pose.lintelOffsetY
        )
        let lintel = CGRect(
            x: lintelCenter.x - lintelWidth / 2,
            y: lintelCenter.y - lintelHeight / 2,
            width: lintelWidth,
            height: lintelHeight
        )

        // Проём между колоннами, открывается снизу вверх.
        let holeBottom = origin.y + G.size.height
        let holeTop = holeBottom - (holeBottom - lintel.maxY) * pose.portalReveal
        let hole = CGRect(
            x: origin.x + t,
            y: holeTop,
            width: G.size.width - 2 * t,
            height: holeBottom - holeTop
        )

        // Камера летит в центр проёма; масштаб растёт экспоненциально — скорость ощущается равномерной.
        let anchor = CGPoint(x: origin.x + G.size.width / 2, y: origin.y + (t + G.size.height) / 2)
        let scale = pow(maxZoom(anchor: anchor, size: size), pose.zoomProgress)
        let transform = CGAffineTransform(translationX: anchor.x, y: anchor.y)
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: -anchor.x, y: -anchor.y)

        var background = Path(CGRect(origin: .zero, size: size))
        if pose.portalReveal > 0 {
            background.addPath(Path(hole).applying(transform))
        }
        context.fill(
            background,
            with: .color(Color.ypWhite.opacity(pose.backgroundOpacity)),
            style: FillStyle(eoFill: true)
        )

        var bars = Path()
        bars.addRects([left, right, lintel])
        context.fill(
            bars.applying(transform),
            with: .color(Color.ypBlack.opacity(pose.logoOpacity))
        )
    }

    private static func pillarRect(x: CGFloat, origin: CGPoint, scaleY: CGFloat) -> CGRect {
        let height = G.pillarHeight * scaleY
        return CGRect(
            x: x,
            y: origin.y + G.size.height - height,
            width: G.barThickness,
            height: height
        )
    }

    /// Масштаб, при котором открытый проём гарантированно перекрывает экран.
    private static func maxZoom(anchor: CGPoint, size: CGSize) -> CGFloat {
        let halfWidth = (G.size.width - 2 * G.barThickness) / 2
        let halfHeight = (G.size.height - G.barThickness) / 2
        let needX = max(anchor.x, size.width - anchor.x) / halfWidth
        let needY = max(anchor.y, size.height - anchor.y) / halfHeight
        return max(needX, needY) * 1.1
    }
}

#Preview("Заставка") {
    ZStack {
        Color.ypBlue.ignoresSafeArea()
        Text("Приложение")
            .font(.ypBold22)
            .foregroundStyle(.ypWhiteUniversal)
        SplashView(isReady: true) {}
    }
}
