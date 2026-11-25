import CoreHaptics

/// Проигрывает HapticScript через Core Haptics.
/// На устройствах без Taptic Engine и в симуляторе молча ничего не делает.
final class SplashHaptics {
    private var engine: CHHapticEngine?

    /// Запускает движок заранее, чтобы первый удар не опаздывал относительно анимации.
    func prepare() {
        guard engine == nil, CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let engine = try CHHapticEngine()
            engine.playsHapticsOnly = true
            engine.isAutoShutdownEnabled = true
            engine.resetHandler = { [weak engine] in
                try? engine?.start()
            }
            try engine.start()
            self.engine = engine
        } catch {
            engine = nil
        }
    }

    func play(_ script: HapticScript) {
        guard let engine else { return }
        do {
            let pattern = try CHHapticPattern(
                events: script.events.map(Self.makeEvent),
                parameterCurves: Self.makeCurves(script)
            )
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Вибрация — украшение: при ошибке анимация продолжается без неё.
        }
    }

    func stop() {
        engine?.stop()
        engine = nil
    }

    private static func makeEvent(_ event: HapticScript.Event) -> CHHapticEvent {
        let parameters = [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: event.intensity),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: event.sharpness)
        ]
        switch event.kind {
        case .transient:
            return CHHapticEvent(
                eventType: .hapticTransient,
                parameters: parameters,
                relativeTime: event.time
            )
        case .continuous(let duration):
            return CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: parameters,
                relativeTime: event.time,
                duration: duration
            )
        }
    }

    private static func makeCurves(_ script: HapticScript) -> [CHHapticParameterCurve] {
        var curves: [CHHapticParameterCurve] = []
        if !script.intensityCurve.isEmpty {
            curves.append(makeCurve(.hapticIntensityControl, script.intensityCurve))
        }
        if !script.sharpnessCurve.isEmpty {
            curves.append(makeCurve(.hapticSharpnessControl, script.sharpnessCurve))
        }
        return curves
    }

    private static func makeCurve(
        _ id: CHHapticDynamicParameter.ID,
        _ points: [HapticScript.CurvePoint]
    ) -> CHHapticParameterCurve {
        CHHapticParameterCurve(
            parameterID: id,
            controlPoints: points.map {
                CHHapticParameterCurve.ControlPoint(relativeTime: $0.time, value: $0.value)
            },
            relativeTime: 0
        )
    }
}
