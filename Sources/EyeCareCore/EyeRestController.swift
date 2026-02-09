import Foundation

@MainActor
public protocol ReminderScheduling: AnyObject {
    var nextFireDate: Date? { get }
    func start(every interval: TimeInterval, handler: @escaping () -> Void)
    func stop()
}

@MainActor
public protocol OverlayPresenting: AnyObject {
    func showOverlay(for duration: TimeInterval)
}

@MainActor
public final class EyeRestController {
    private(set) public var settings: AlertSettings

    private let scheduler: ReminderScheduling
    private let overlayPresenter: OverlayPresenting
    private let nowProvider: () -> Date
    private var isRunning = false
    private var isSchedulerActive = false
    private var activeInterval: TimeInterval?

    public init(
        settings: AlertSettings,
        scheduler: ReminderScheduling,
        overlayPresenter: OverlayPresenting,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.settings = settings.normalized()
        self.scheduler = scheduler
        self.overlayPresenter = overlayPresenter
        self.nowProvider = nowProvider
    }

    public func start() {
        isRunning = true
        rescheduleIfNeeded(now: nowProvider(), forceReschedule: true)
    }

    public func stop() {
        isRunning = false
        scheduler.stop()
        isSchedulerActive = false
        activeInterval = nil
    }

    public func apply(settings: AlertSettings) {
        self.settings = settings.normalized()

        guard isRunning else {
            return
        }

        rescheduleIfNeeded(now: nowProvider(), forceReschedule: true)
    }

    public func refreshSchedule(for date: Date? = nil) {
        guard isRunning else {
            return
        }

        rescheduleIfNeeded(now: date ?? nowProvider())
    }

    public func triggerNow() {
        overlayPresenter.showOverlay(for: settings.borderDuration)
    }

    private func rescheduleIfNeeded(
        now: Date = Date(),
        forceReschedule: Bool = false
    ) {
        let shouldSchedule = settings.isEnabled && settings.isReminderAllowed(at: now)
        let needsReschedule = forceReschedule
            || shouldSchedule != isSchedulerActive
            || (shouldSchedule && activeInterval != settings.intervalSeconds)

        guard needsReschedule else {
            return
        }

        scheduler.stop()
        isSchedulerActive = false
        activeInterval = nil

        guard shouldSchedule else {
            return
        }

        let interval = settings.intervalSeconds
        scheduler.start(every: interval) { [weak self] in
            guard let self else {
                return
            }
            self.overlayPresenter.showOverlay(for: self.settings.borderDuration)
        }
        isSchedulerActive = true
        activeInterval = interval
    }
}
