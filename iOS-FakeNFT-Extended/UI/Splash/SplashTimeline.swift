import CoreGraphics
import Foundation

/// Геометрия логотипа в точках — совпадает с ассетом logoLaunch (75×78 pt) на лаунчскрине.
enum LogoGeometry {
    static let size = CGSize(width: 75, height: 78)
    static let barThickness: CGFloat = 32.0 / 3
    static let pillarTop: CGFloat = 16
    static let lintelMinX: CGFloat = 40.0 / 3
    static let lintelMaxX: CGFloat = 185.0 / 3

    static var pillarHeight: CGFloat { size.height - pillarTop }
    static var lintelWidth: CGFloat { lintelMaxX - lintelMinX }
}

/// Положение частей логотипа в конкретный момент анимации.
struct LogoPose: Equatable {
    /// Сжатие колонн по вертикали, якорь — низ колонны.
    var leftPillarScaleY: CGFloat = 1
    var rightPillarScaleY: CGFloat = 1
    /// Сдвиг перемычки по вертикали (минус — вверх).
    var lintelOffsetY: CGFloat = 0
    var lintelScaleX: CGFloat = 1
    var lintelScaleY: CGFloat = 1
    /// 0 — проём закрыт фоном, 1 — сквозь проём целиком видно приложение.
    var portalReveal: CGFloat = 0
    /// 0 — исходный масштаб, 1 — проём закрыл весь экран.
    var zoomProgress: CGFloat = 0
    var logoOpacity: CGFloat = 1
    var backgroundOpacity: CGFloat = 1

    static let rest = LogoPose()
}

/// Таймлайн анимации заставки «Врата».
///
/// Интро: левая колонна «пружинит» → правая → перемычка поднимается и с силой
/// встаёт на место. Ожидание: перемычка едва заметно «дышит», пока грузятся данные.
/// Выход: проём «открывается» снизу вверх, камера пролетает сквозь врата в приложение.
///
/// Все моменты ударов — общие константы для анимации и вибрации, поэтому они совпадают такт в такт.
enum SplashTimeline {
    // MARK: Интро

    static let leftTap: TimeInterval = 0.30
    static let rightTap: TimeInterval = 0.50
    static let tapCompress: TimeInterval = 0.08
    static let tapRecover: TimeInterval = 0.22
    static var leftImpact: TimeInterval { leftTap + tapCompress }
    static var rightImpact: TimeInterval { rightTap + tapCompress }

    static let liftStart: TimeInterval = 0.72
    static let slamStart: TimeInterval = 0.92
    static let slamImpact: TimeInterval = 1.00
    static let slamSettle: TimeInterval = 0.24
    static var introEnd: TimeInterval { slamImpact + slamSettle }

    // MARK: Ожидание данных

    static let idlePeriod: TimeInterval = 1.4
    static let idleAmplitude: CGFloat = 1.5
    static let maxIdle: TimeInterval = 2.5

    // MARK: Выход

    static let portalOpen: TimeInterval = 0.30
    static let zoomEnd: TimeInterval = 0.80
    static let fadeStart: TimeInterval = 0.66
    static var exitEnd: TimeInterval { zoomEnd + 0.06 }

    // MARK: Амплитуды

    static let tapSquash: CGFloat = 0.84
    static let liftHeight: CGFloat = 14
    static let anticipationScaleX: CGFloat = 0.96
    static let slamOvershoot: CGFloat = 2
    static let impactPillarSquash: CGFloat = 0.92
    static let impactLintelStretchX: CGFloat = 1.08
    static let impactLintelSquashY: CGFloat = 0.8

    // MARK: Позы

    static func intro(at t: TimeInterval) -> LogoPose {
        var pose = LogoPose.rest
        pose.leftPillarScaleY = tapScale(at: t - leftTap)
        pose.rightPillarScaleY = tapScale(at: t - rightTap)

        switch t {
        case ..<liftStart:
            break
        case ..<slamStart:
            let p = easeOutCubic(progress(t, from: liftStart, to: slamStart))
            pose.lintelOffsetY = -liftHeight * p
            pose.lintelScaleX = lerp(1, anticipationScaleX, p)
        case ..<slamImpact:
            let p = easeInQuad(progress(t, from: slamStart, to: slamImpact))
            pose.lintelOffsetY = lerp(-liftHeight, slamOvershoot, p)
            pose.lintelScaleX = lerp(anticipationScaleX, 1, p)
        default:
            let s = springProgress(progress(t, from: slamImpact, to: slamImpact + slamSettle))
            pose.lintelOffsetY = lerp(slamOvershoot, 0, s)
            pose.lintelScaleX = lerp(impactLintelStretchX, 1, s)
            pose.lintelScaleY = lerp(impactLintelSquashY, 1, s)
            let squash = lerp(impactPillarSquash, 1, s)
            pose.leftPillarScaleY *= squash
            pose.rightPillarScaleY *= squash
        }
        return pose
    }

    static func idle(at t: TimeInterval) -> LogoPose {
        var pose = LogoPose.rest
        pose.lintelOffsetY = -idleAmplitude * (1 - CGFloat(cos(2 * .pi * t / idlePeriod))) / 2
        return pose
    }

    /// - Parameter startOffset: положение перемычки в момент старта выхода (из фазы ожидания).
    static func exit(at t: TimeInterval, startOffset: CGFloat) -> LogoPose {
        var pose = LogoPose.rest
        pose.lintelOffsetY = lerp(startOffset, 0, easeOutCubic(progress(t, from: 0, to: 0.15)))
        pose.portalReveal = easeInOutCubic(progress(t, from: 0, to: portalOpen))
        pose.zoomProgress = easeInCubic(progress(t, from: portalOpen, to: zoomEnd))
        pose.logoOpacity = 1 - progress(t, from: fadeStart, to: zoomEnd)
        pose.backgroundOpacity = 1 - progress(t, from: fadeStart + 0.06, to: exitEnd)
        return pose
    }

    private static func tapScale(at dt: TimeInterval) -> CGFloat {
        if dt < 0 { return 1 }
        if dt < tapCompress {
            return lerp(1, tapSquash, easeOutCubic(CGFloat(dt / tapCompress)))
        }
        let p = progress(dt, from: tapCompress, to: tapCompress + tapRecover)
        return lerp(tapSquash, 1, springProgress(p))
    }
}

// MARK: - Easing

private func progress(_ t: TimeInterval, from start: TimeInterval, to end: TimeInterval) -> CGFloat {
    guard end > start else { return t >= end ? 1 : 0 }
    return CGFloat(min(max((t - start) / (end - start), 0), 1))
}

private func lerp(_ a: CGFloat, _ b: CGFloat, _ p: CGFloat) -> CGFloat {
    a + (b - a) * p
}

private func easeOutCubic(_ p: CGFloat) -> CGFloat { 1 - pow(1 - p, 3) }
private func easeInCubic(_ p: CGFloat) -> CGFloat { p * p * p }
private func easeInQuad(_ p: CGFloat) -> CGFloat { p * p }
private func easeInOutCubic(_ p: CGFloat) -> CGFloat {
    p < 0.5 ? 4 * p * p * p : 1 - pow(-2 * p + 2, 3) / 2
}

/// Затухающая пружина: перелёт ~9% и точное попадание в 1 при p = 1.
private func springProgress(_ p: CGFloat) -> CGFloat {
    guard p < 1 else { return 1 }
    return 1 - exp(-6 * p) * cos(2.5 * .pi * p)
}

// MARK: - Вибрация

/// Описание вибрации на той же шкале времени, что и анимация.
struct HapticScript: Equatable {
    struct Event: Equatable {
        enum Kind: Equatable {
            case transient
            case continuous(duration: TimeInterval)
        }

        let time: TimeInterval
        let kind: Kind
        let intensity: Float
        let sharpness: Float
    }

    struct CurvePoint: Equatable {
        let time: TimeInterval
        let value: Float
    }

    let events: [Event]
    /// Множитель интенсивности всего паттерна (0...1).
    let intensityCurve: [CurvePoint]
    /// Добавка к резкости всего паттерна (-1...1).
    let sharpnessCurve: [CurvePoint]
}

extension HapticScript {
    private typealias T = SplashTimeline

    /// Тук (левая) — тук (правая) — нарастающее напряжение подъёма — удар перемычки с гулом.
    static let intro = HapticScript(
        events: [
            Event(time: T.leftImpact, kind: .transient, intensity: 0.5, sharpness: 0.6),
            Event(time: T.rightImpact, kind: .transient, intensity: 0.6, sharpness: 0.6),
            Event(time: T.liftStart, kind: .continuous(duration: T.slamStart - T.liftStart), intensity: 0.3, sharpness: 0.15),
            Event(time: T.slamImpact, kind: .transient, intensity: 1.0, sharpness: 0.45),
            Event(time: T.slamImpact, kind: .continuous(duration: 0.14), intensity: 0.6, sharpness: 0.1)
        ],
        intensityCurve: [
            CurvePoint(time: 0, value: 1),
            CurvePoint(time: T.rightImpact + 0.02, value: 1),
            CurvePoint(time: T.liftStart, value: 0.2),
            CurvePoint(time: T.slamStart, value: 1),
            CurvePoint(time: T.slamImpact, value: 1),
            CurvePoint(time: T.slamImpact + 0.14, value: 0.1)
        ],
        sharpnessCurve: []
    )

    /// Мягкое открытие проёма — разгон «пролёта» с ростом силы и резкости — щелчок на проходе.
    static let exit = HapticScript(
        events: [
            Event(time: 0, kind: .continuous(duration: T.portalOpen), intensity: 0.45, sharpness: 0.3),
            Event(time: T.portalOpen, kind: .continuous(duration: T.zoomEnd - T.portalOpen), intensity: 1.0, sharpness: 0.45),
            Event(time: T.zoomEnd, kind: .transient, intensity: 0.9, sharpness: 1.0)
        ],
        intensityCurve: [
            CurvePoint(time: 0, value: 0.3),
            CurvePoint(time: T.portalOpen, value: 1),
            CurvePoint(time: T.portalOpen + 0.001, value: 0.2),
            CurvePoint(time: T.zoomEnd, value: 1)
        ],
        sharpnessCurve: [
            CurvePoint(time: 0, value: 0),
            CurvePoint(time: T.portalOpen, value: 0),
            CurvePoint(time: T.portalOpen + 0.001, value: -0.25),
            CurvePoint(time: T.zoomEnd, value: 0.35)
        ]
    )
}
