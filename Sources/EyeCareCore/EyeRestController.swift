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
    private var isRunning = false

    public init(
        settings: AlertSettings,
        scheduler: ReminderScheduling,
        overlayPresenter: OverlayPresenting
    ) {
        self.settings = settings.normalized()
        self.scheduler = scheduler
        self.overlayPresenter = overlayPresenter
    }

    public func start() {
        isRunning = true
        rescheduleIfNeeded()
    }

    public func stop() {
        isRunning = false
        scheduler.stop()
    }

    public func apply(settings: AlertSettings) {
        self.settings = settings.normalized()

        guard isRunning else {
            return
        }

        rescheduleIfNeeded()
    }

    public func triggerNow() {
        overlayPresenter.showOverlay(for: settings.borderDuration)
    }

    private func rescheduleIfNeeded() {
        scheduler.stop()

        guard settings.isEnabled else {
            return
        }

        let interval = settings.intervalSeconds
        scheduler.start(every: interval) { [weak self] in
            guard let self else {
                return
            }
            self.overlayPresenter.showOverlay(for: self.settings.borderDuration)
        }
    }
}
