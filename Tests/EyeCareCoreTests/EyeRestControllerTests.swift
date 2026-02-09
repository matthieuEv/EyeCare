import EyeCareCore
import XCTest

@MainActor
final class EyeRestControllerTests: XCTestCase {
    func testStartSchedulesReminderWhenEnabled() {
        let scheduler = MockScheduler()
        let overlay = MockOverlayPresenter()
        let settings = AlertSettings(isEnabled: true, intervalMinutes: 20, borderDurationSeconds: 5)

        let controller = EyeRestController(
            settings: settings,
            scheduler: scheduler,
            overlayPresenter: overlay
        )

        controller.start()

        XCTAssertEqual(scheduler.startIntervals, [1200])
    }

    func testStartDoesNotScheduleWhenDisabled() {
        let scheduler = MockScheduler()
        let overlay = MockOverlayPresenter()
        let settings = AlertSettings(isEnabled: false, intervalMinutes: 20, borderDurationSeconds: 5)

        let controller = EyeRestController(
            settings: settings,
            scheduler: scheduler,
            overlayPresenter: overlay
        )

        controller.start()

        XCTAssertTrue(scheduler.startIntervals.isEmpty)
        XCTAssertEqual(scheduler.stopCallCount, 1)
    }

    func testTimerEventShowsOverlayWithConfiguredDuration() {
        let scheduler = MockScheduler()
        let overlay = MockOverlayPresenter()
        let settings = AlertSettings(isEnabled: true, intervalMinutes: 20, borderDurationSeconds: 7)

        let controller = EyeRestController(
            settings: settings,
            scheduler: scheduler,
            overlayPresenter: overlay
        )

        controller.start()
        scheduler.fire()

        XCTAssertEqual(overlay.durations, [7])
    }

    func testApplySettingsReschedulesWhenRunning() {
        let scheduler = MockScheduler()
        let overlay = MockOverlayPresenter()
        let settings = AlertSettings(isEnabled: true, intervalMinutes: 20, borderDurationSeconds: 5)

        let controller = EyeRestController(
            settings: settings,
            scheduler: scheduler,
            overlayPresenter: overlay
        )

        controller.start()
        controller.apply(settings: AlertSettings(isEnabled: true, intervalMinutes: 15, borderDurationSeconds: 4))

        XCTAssertEqual(scheduler.startIntervals, [1200, 900])
        XCTAssertEqual(scheduler.stopCallCount, 2)
    }

    func testApplyDisabledSettingsStopsScheduler() {
        let scheduler = MockScheduler()
        let overlay = MockOverlayPresenter()
        let settings = AlertSettings(isEnabled: true, intervalMinutes: 20, borderDurationSeconds: 5)

        let controller = EyeRestController(
            settings: settings,
            scheduler: scheduler,
            overlayPresenter: overlay
        )

        controller.start()
        controller.apply(settings: AlertSettings(isEnabled: false, intervalMinutes: 20, borderDurationSeconds: 5))

        XCTAssertEqual(scheduler.startIntervals, [1200])
        XCTAssertEqual(scheduler.stopCallCount, 2)
    }

    func testTriggerNowShowsOverlayEvenWithoutTimerEvent() {
        let scheduler = MockScheduler()
        let overlay = MockOverlayPresenter()
        let settings = AlertSettings(isEnabled: false, intervalMinutes: 20, borderDurationSeconds: 6)

        let controller = EyeRestController(
            settings: settings,
            scheduler: scheduler,
            overlayPresenter: overlay
        )

        controller.triggerNow()

        XCTAssertEqual(overlay.durations, [6])
    }
}

@MainActor
private final class MockScheduler: ReminderScheduling {
    private(set) var startIntervals: [TimeInterval] = []
    private(set) var stopCallCount = 0
    private var handler: (() -> Void)?
    var nextFireDate: Date?

    func start(every interval: TimeInterval, handler: @escaping () -> Void) {
        startIntervals.append(interval)
        self.handler = handler
        nextFireDate = Date().addingTimeInterval(interval)
    }

    func stop() {
        stopCallCount += 1
        handler = nil
        nextFireDate = nil
    }

    func fire() {
        handler?()
    }
}

@MainActor
private final class MockOverlayPresenter: OverlayPresenting {
    private(set) var durations: [TimeInterval] = []

    func showOverlay(for duration: TimeInterval) {
        durations.append(duration)
    }
}
