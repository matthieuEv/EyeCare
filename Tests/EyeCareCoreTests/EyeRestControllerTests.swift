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

    func testStartDoesNotScheduleOutsideOfficeHoursWhenRestricted() {
        let scheduler = MockScheduler()
        let overlay = MockOverlayPresenter()
        let outsideOfficeDate = makeDate(hour: 8, minute: 30)
        let settings = AlertSettings(
            isEnabled: true,
            intervalMinutes: 20,
            borderDurationSeconds: 5,
            restrictToOfficeHours: true,
            officeHoursStartMinutes: 9 * 60,
            officeHoursEndMinutes: 17 * 60
        )

        let controller = EyeRestController(
            settings: settings,
            scheduler: scheduler,
            overlayPresenter: overlay,
            nowProvider: { outsideOfficeDate }
        )

        controller.start()

        XCTAssertTrue(scheduler.startIntervals.isEmpty)
        XCTAssertEqual(scheduler.stopCallCount, 1)
    }

    func testRefreshScheduleTransitionsWhenEnteringAndLeavingOfficeHours() {
        let scheduler = MockScheduler()
        let overlay = MockOverlayPresenter()
        var now = makeDate(hour: 8, minute: 45)
        let settings = AlertSettings(
            isEnabled: true,
            intervalMinutes: 20,
            borderDurationSeconds: 5,
            restrictToOfficeHours: true,
            officeHoursStartMinutes: 9 * 60,
            officeHoursEndMinutes: 17 * 60
        )

        let controller = EyeRestController(
            settings: settings,
            scheduler: scheduler,
            overlayPresenter: overlay,
            nowProvider: { now }
        )

        controller.start()
        XCTAssertTrue(scheduler.startIntervals.isEmpty)
        XCTAssertEqual(scheduler.stopCallCount, 1)

        now = makeDate(hour: 9, minute: 0)
        controller.refreshSchedule()
        XCTAssertEqual(scheduler.startIntervals, [1200])
        XCTAssertEqual(scheduler.stopCallCount, 2)

        now = makeDate(hour: 9, minute: 5)
        controller.refreshSchedule()
        XCTAssertEqual(scheduler.startIntervals, [1200])
        XCTAssertEqual(scheduler.stopCallCount, 2)

        now = makeDate(hour: 17, minute: 0)
        controller.refreshSchedule()
        XCTAssertEqual(scheduler.startIntervals, [1200])
        XCTAssertEqual(scheduler.stopCallCount, 3)
    }

    private func makeDate(hour: Int, minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.date(from: DateComponents(year: 2026, month: 1, day: 15, hour: hour, minute: minute))!
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
