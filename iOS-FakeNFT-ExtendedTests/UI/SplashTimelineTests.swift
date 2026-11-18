import XCTest
@testable import iOS_FakeNFT_Extended

final class SplashTimelineTests: XCTestCase {
    private typealias T = SplashTimeline

    private func assertPose(_ pose: LogoPose, equals expected: LogoPose, accuracy: CGFloat = 0.001, file: StaticString = #filePath, line: UInt = #line) {
        let pairs: [(CGFloat, CGFloat)] = [
            (pose.leftPillarScaleY, expected.leftPillarScaleY),
            (pose.rightPillarScaleY, expected.rightPillarScaleY),
            (pose.lintelOffsetY, expected.lintelOffsetY),
            (pose.lintelScaleX, expected.lintelScaleX),
            (pose.lintelScaleY, expected.lintelScaleY),
            (pose.portalReveal, expected.portalReveal),
            (pose.zoomProgress, expected.zoomProgress),
            (pose.logoOpacity, expected.logoOpacity),
            (pose.backgroundOpacity, expected.backgroundOpacity)
        ]
        for (value, target) in pairs {
            XCTAssertEqual(value, target, accuracy: accuracy, file: file, line: line)
        }
    }

    func testIntroStartsExactlyAsLaunchScreen() {
        assertPose(T.intro(at: 0), equals: .rest)
    }

    func testIntroEndsAtRestSoIdleContinuesSeamlessly() {
        assertPose(T.intro(at: T.introEnd), equals: .rest)
        assertPose(T.idle(at: 0), equals: .rest)
    }

    func testPillarsAreMostCompressedAtHapticTaps() {
        XCTAssertEqual(T.intro(at: T.leftImpact).leftPillarScaleY, T.tapSquash, accuracy: 0.001)
        XCTAssertEqual(T.intro(at: T.rightImpact).rightPillarScaleY, T.tapSquash, accuracy: 0.001)
    }

    func testLintelHitsAtSlamImpact() {
        XCTAssertEqual(T.intro(at: T.slamImpact).lintelOffsetY, T.slamOvershoot, accuracy: 0.001)
        XCTAssertLessThan(T.intro(at: T.slamStart).lintelOffsetY, -T.liftHeight + 0.001)
    }

    func testExitContinuesFromIdleOffsetAndEndsHidden() {
        let offset = T.idle(at: T.idlePeriod / 2).lintelOffsetY
        XCTAssertEqual(T.exit(at: 0, startOffset: offset).lintelOffsetY, offset, accuracy: 0.001)

        let end = T.exit(at: T.exitEnd, startOffset: offset)
        XCTAssertEqual(end.portalReveal, 1)
        XCTAssertEqual(end.zoomProgress, 1)
        XCTAssertEqual(end.logoOpacity, 0)
        XCTAssertEqual(end.backgroundOpacity, 0)
    }

    func testIntroHapticsMatchAnimationBeats() {
        let transients = HapticScript.intro.events
            .filter { $0.kind == .transient }
            .map(\.time)
        XCTAssertEqual(transients, [T.leftImpact, T.rightImpact, T.slamImpact])
    }

    func testExitHapticClickWhenPassingThroughGate() {
        let transients = HapticScript.exit.events.filter { $0.kind == .transient }
        XCTAssertEqual(transients.map(\.time), [T.zoomEnd])
    }

    func testIntensityCurveIsFullOnEveryTap() {
        for time in [T.leftImpact, T.rightImpact, T.slamImpact] {
            XCTAssertEqual(curveValue(HapticScript.intro.intensityCurve, at: time), 1, accuracy: 0.001)
        }
        XCTAssertEqual(curveValue(HapticScript.exit.intensityCurve, at: T.zoomEnd), 1, accuracy: 0.001)
    }

    /// Линейная интерполяция — так же, как CHHapticParameterCurve.
    private func curveValue(_ points: [HapticScript.CurvePoint], at time: TimeInterval) -> Float {
        guard let next = points.firstIndex(where: { $0.time >= time }) else { return points.last?.value ?? 1 }
        guard next > 0 else { return points[next].value }
        let a = points[next - 1], b = points[next]
        let p = Float((time - a.time) / (b.time - a.time))
        return a.value + (b.value - a.value) * p
    }
}
