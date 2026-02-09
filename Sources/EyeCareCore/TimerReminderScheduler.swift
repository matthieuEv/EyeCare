import Foundation

@MainActor
public final class TimerReminderScheduler: NSObject, ReminderScheduling {
    private var timer: Timer?
    private var callback: (() -> Void)?

    public override init() {}

    public var nextFireDate: Date? {
        timer?.fireDate
    }

    public func start(every interval: TimeInterval, handler: @escaping () -> Void) {
        stop()

        callback = handler

        let timer = Timer.scheduledTimer(
            timeInterval: interval,
            target: self,
            selector: #selector(timerDidFire),
            userInfo: nil,
            repeats: true
        )

        timer.tolerance = min(interval * 0.1, 1)
        self.timer = timer
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
        callback = nil
    }

    @objc
    private func timerDidFire() {
        callback?()
    }
}
