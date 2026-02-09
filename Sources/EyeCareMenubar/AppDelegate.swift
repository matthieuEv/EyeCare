import AppKit
import EyeCareCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settingsStore: AlertSettingsStoring
    private let scheduler: ReminderScheduling
    private let overlayManager: ScreenBorderOverlayManager
    private let controller: EyeRestController

    private var currentSettings: AlertSettings

    private var statusItem: NSStatusItem?
    private var countdownTitleLabel: NSTextField?
    private var countdownValueLabel: NSTextField?
    private var countdownDotView: NSView?
    private var enabledMenuItem: NSMenuItem?
    private var intervalValueLabel: NSTextField?
    private var borderDurationValueLabel: NSTextField?
    private var intervalStepper: NSStepper?
    private var borderDurationStepper: NSStepper?
    private var countdownRefreshTimer: Timer?

    override init() {
        let settingsStore = UserDefaultsAlertSettingsStore()
        let settings = settingsStore.load()

        self.settingsStore = settingsStore
        self.scheduler = TimerReminderScheduler()
        self.overlayManager = ScreenBorderOverlayManager()
        self.currentSettings = settings
        self.controller = EyeRestController(
            settings: settings,
            scheduler: scheduler,
            overlayPresenter: overlayManager
        )

        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureStatusItem()
        controller.start()
        startCountdownRefreshTimer()
        updateMenuContent()
    }

    func applicationWillTerminate(_ notification: Notification) {
        countdownRefreshTimer?.invalidate()
        controller.stop()
    }

    @objc
    private func toggleEnabled() {
        var updated = currentSettings
        updated.isEnabled.toggle()
        applySettings(updated)
    }

    @objc
    private func intervalStepperDidChange(_ sender: NSStepper) {
        var updated = currentSettings
        updated.intervalMinutes = sender.doubleValue
        applySettings(updated)
    }

    @objc
    private func borderDurationStepperDidChange(_ sender: NSStepper) {
        var updated = currentSettings
        updated.borderDurationSeconds = sender.doubleValue
        applySettings(updated)
    }

    @objc
    private func quitApplication() {
        NSApplication.shared.terminate(nil)
    }

    private func configureStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let menu = NSMenu()

        configureStatusButtonIcon(for: statusItem)

        let dashboard = makeDashboardMenuItem(
            countdownText: "--:--",
            intervalValueText: formattedInterval(currentSettings.intervalMinutes),
            durationValueText: formattedBorderDuration(currentSettings.borderDurationSeconds)
        )
        menu.addItem(dashboard.item)
        countdownTitleLabel = dashboard.countdownTitleLabel
        countdownValueLabel = dashboard.countdownValueLabel
        countdownDotView = dashboard.countdownDotView
        intervalValueLabel = dashboard.intervalValueLabel
        intervalStepper = dashboard.intervalStepper
        borderDurationValueLabel = dashboard.borderDurationValueLabel
        borderDurationStepper = dashboard.borderDurationStepper

        let enabledMenuItem = NSMenuItem(
            title: "Enable reminders",
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        enabledMenuItem.target = self
        enabledMenuItem.state = currentSettings.isEnabled ? .on : .off
        menu.addItem(enabledMenuItem)

        menu.addItem(.separator())

        let quitMenuItem = NSMenuItem(
            title: "Quit",
            action: #selector(quitApplication),
            keyEquivalent: "q"
        )
        quitMenuItem.target = self
        menu.addItem(quitMenuItem)

        statusItem.menu = menu

        self.statusItem = statusItem
        self.enabledMenuItem = enabledMenuItem
    }

    private func applySettings(_ settings: AlertSettings) {
        let normalized = settings.normalized()
        currentSettings = normalized
        settingsStore.save(normalized)
        controller.apply(settings: normalized)
        updateMenuContent()
    }

    private func startCountdownRefreshTimer() {
        countdownRefreshTimer?.invalidate()
        let timer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(countdownTimerDidFire),
            userInfo: nil,
            repeats: true
        )
        timer.tolerance = 0.2
        RunLoop.main.add(timer, forMode: .common)
        countdownRefreshTimer = timer
    }

    @objc
    private func countdownTimerDidFire() {
        updateCountdownDisplay()
    }

    private func makeDashboardMenuItem(
        countdownText: String,
        intervalValueText: String,
        durationValueText: String
    ) -> (
        item: NSMenuItem,
        countdownTitleLabel: NSTextField,
        countdownValueLabel: NSTextField,
        countdownDotView: NSView,
        intervalValueLabel: NSTextField,
        intervalStepper: NSStepper,
        borderDurationValueLabel: NSTextField,
        borderDurationStepper: NSStepper
    ) {
        let countdownDotView = NSView(frame: NSRect(x: 0, y: 0, width: 8, height: 8))
        countdownDotView.wantsLayer = true
        countdownDotView.layer?.cornerRadius = 4
        countdownDotView.layer?.backgroundColor = NSColor.systemGreen.cgColor
        countdownDotView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            countdownDotView.widthAnchor.constraint(equalToConstant: 8),
            countdownDotView.heightAnchor.constraint(equalToConstant: 8)
        ])

        let countdownTitleLabel = NSTextField(labelWithString: "Next break")
        countdownTitleLabel.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        countdownTitleLabel.textColor = .secondaryLabelColor

        let countdownValueLabel = NSTextField(labelWithString: countdownText)
        countdownValueLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 18, weight: .bold)
        countdownValueLabel.alignment = .right

        let titleWithDotRow = NSStackView(views: [countdownDotView, countdownTitleLabel])
        titleWithDotRow.orientation = .horizontal
        titleWithDotRow.alignment = .centerY
        titleWithDotRow.spacing = 7

        let countdownRow = NSStackView(views: [titleWithDotRow, countdownValueLabel])
        countdownRow.orientation = .horizontal
        countdownRow.alignment = .centerY
        countdownRow.distribution = .fill

        let intervalCard = makeStepperCard(
            title: "Interval",
            valueText: intervalValueText,
            minValue: AlertSettings.minimumIntervalMinutes,
            maxValue: AlertSettings.maximumIntervalMinutes,
            currentValue: currentSettings.intervalMinutes,
            action: #selector(intervalStepperDidChange(_:))
        )
        let borderDurationCard = makeStepperCard(
            title: "Alert duration",
            valueText: durationValueText,
            minValue: AlertSettings.minimumBorderDurationSeconds,
            maxValue: AlertSettings.maximumBorderDurationSeconds,
            currentValue: currentSettings.borderDurationSeconds,
            action: #selector(borderDurationStepperDidChange(_:))
        )

        let cardsRow = NSStackView(views: [intervalCard.cardView, borderDurationCard.cardView])
        cardsRow.orientation = .horizontal
        cardsRow.alignment = .top
        cardsRow.distribution = .fillEqually
        cardsRow.spacing = 10

        let recommendationTitleLabel = NSTextField(labelWithString: "Recommended values (20-20-20)")
        recommendationTitleLabel.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        recommendationTitleLabel.textColor = .secondaryLabelColor

        let recommendationBodyLabel = NSTextField(
            wrappingLabelWithString: "Use 20 min / 20 sec. Every 20 min, look at something far away for 20 sec."
        )
        recommendationBodyLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        recommendationBodyLabel.textColor = .secondaryLabelColor

        let recommendationStack = NSStackView(views: [recommendationTitleLabel, recommendationBodyLabel])
        recommendationStack.orientation = .vertical
        recommendationStack.alignment = .leading
        recommendationStack.spacing = 4
        recommendationStack.translatesAutoresizingMaskIntoConstraints = false

        let recommendationCard = NSView(frame: NSRect(x: 0, y: 0, width: 316, height: 62))
        recommendationCard.wantsLayer = true
        recommendationCard.layer?.cornerRadius = 8
        recommendationCard.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.3).cgColor
        recommendationCard.layer?.borderWidth = 1
        recommendationCard.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.2).cgColor
        recommendationCard.translatesAutoresizingMaskIntoConstraints = false
        recommendationCard.addSubview(recommendationStack)

        NSLayoutConstraint.activate([
            recommendationStack.leadingAnchor.constraint(equalTo: recommendationCard.leadingAnchor, constant: 8),
            recommendationStack.trailingAnchor.constraint(equalTo: recommendationCard.trailingAnchor, constant: -8),
            recommendationStack.topAnchor.constraint(equalTo: recommendationCard.topAnchor, constant: 8),
            recommendationStack.bottomAnchor.constraint(equalTo: recommendationCard.bottomAnchor, constant: -8),
            recommendationCard.heightAnchor.constraint(equalToConstant: 62)
        ])

        let contentStack = NSStackView(views: [countdownRow, cardsRow, recommendationCard])
        contentStack.orientation = .vertical
        contentStack.alignment = .leading
        contentStack.spacing = 10
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 336, height: 184))
        container.wantsLayer = true
        container.layer?.cornerRadius = 10
        container.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.6).cgColor
        container.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            contentStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            contentStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            contentStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10)
        ])

        let menuItem = NSMenuItem()
        menuItem.view = container
        return (
            menuItem,
            countdownTitleLabel,
            countdownValueLabel,
            countdownDotView,
            intervalCard.valueLabel,
            intervalCard.stepper,
            borderDurationCard.valueLabel,
            borderDurationCard.stepper
        )
    }

    private func makeStepperCard(
        title: String,
        valueText: String,
        minValue: Double,
        maxValue: Double,
        currentValue: Double,
        action: Selector
    ) -> (cardView: NSView, valueLabel: NSTextField, stepper: NSStepper) {
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        titleLabel.textColor = .secondaryLabelColor

        let valueLabel = NSTextField(labelWithString: valueText)
        valueLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 14, weight: .semibold)
        valueLabel.textColor = .labelColor
        valueLabel.lineBreakMode = .byClipping
        valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let stepper = NSStepper()
        stepper.minValue = minValue
        stepper.maxValue = maxValue
        stepper.increment = 1
        stepper.doubleValue = currentValue
        stepper.controlSize = .small
        stepper.target = self
        stepper.action = action
        stepper.setContentHuggingPriority(.required, for: .horizontal)
        stepper.setContentCompressionResistancePriority(.required, for: .horizontal)

        let valueRow = NSStackView(views: [valueLabel, stepper])
        valueRow.orientation = .horizontal
        valueRow.alignment = .centerY
        valueRow.spacing = 8
        valueRow.distribution = .fill

        let stack = NSStackView(views: [titleLabel, valueRow])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 5
        stack.translatesAutoresizingMaskIntoConstraints = false

        let cardView = NSView(frame: NSRect(x: 0, y: 0, width: 150, height: 56))
        cardView.wantsLayer = true
        cardView.layer?.cornerRadius = 8
        cardView.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.4).cgColor
        cardView.layer?.borderWidth = 1
        cardView.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.25).cgColor
        cardView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -8)
        ])

        return (cardView, valueLabel, stepper)
    }

    private func updateMenuContent() {
        enabledMenuItem?.state = currentSettings.isEnabled ? .on : .off
        intervalValueLabel?.stringValue = formattedInterval(currentSettings.intervalMinutes)
        borderDurationValueLabel?.stringValue = formattedBorderDuration(currentSettings.borderDurationSeconds)
        intervalStepper?.doubleValue = currentSettings.intervalMinutes
        borderDurationStepper?.doubleValue = currentSettings.borderDurationSeconds
        updateCountdownDisplay()
    }

    private func updateCountdownDisplay() {
        guard currentSettings.isEnabled else {
            updateStatusButtonState(
                isEnabled: false,
                toolTip: "EyeCare - reminders disabled"
            )
            updateCountdownPanel(
                title: "Reminders disabled",
                value: "--:--",
                dotColor: .systemGray
            )
            return
        }

        guard let nextFireDate = scheduler.nextFireDate else {
            updateStatusButtonState(
                isEnabled: true,
                toolTip: "EyeCare - next break pending"
            )
            updateCountdownPanel(
                title: "Next break",
                value: "--:--",
                dotColor: .systemOrange
            )
            return
        }

        let countdown = formatRemainingTime(nextFireDate.timeIntervalSinceNow)
        updateStatusButtonState(
            isEnabled: true,
            toolTip: "EyeCare - next break in \(countdown)"
        )
        updateCountdownPanel(
            title: "Next break",
            value: countdown,
            dotColor: .systemGreen
        )
    }

    private func updateCountdownPanel(title: String, value: String, dotColor: NSColor) {
        countdownTitleLabel?.stringValue = title
        countdownValueLabel?.stringValue = value
        countdownDotView?.layer?.backgroundColor = dotColor.cgColor
    }

    private func configureStatusButtonIcon(for statusItem: NSStatusItem) {
        guard let button = statusItem.button else {
            return
        }

        button.title = ""
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
        button.image = statusButtonIconImage()
    }

    private func statusButtonIconImage() -> NSImage {
        let image = loadAppIconImage()
            ?? NSImage(systemSymbolName: "eye.fill", accessibilityDescription: "EyeCare")
            ?? NSImage()

        let sizedImage = (image.copy() as? NSImage) ?? image
        sizedImage.size = NSSize(width: 18, height: 18)
        sizedImage.isTemplate = false
        return sizedImage
    }

    private func loadAppIconImage() -> NSImage? {
        if let image = NSImage(named: "AppIcon") {
            return image
        }

        guard
            let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
            let image = NSImage(contentsOf: iconURL)
        else {
            return nil
        }

        return image
    }

    private func updateStatusButtonState(isEnabled: Bool, toolTip: String) {
        guard let button = statusItem?.button else {
            return
        }

        button.alphaValue = isEnabled ? 1 : 0.55
        button.toolTip = toolTip
    }

    private func formatRemainingTime(_ remaining: TimeInterval) -> String {
        let totalSeconds = max(0, Int(ceil(remaining)))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func formattedInterval(_ minutes: Double) -> String {
        "\(Int(minutes)) min"
    }

    private func formattedBorderDuration(_ seconds: Double) -> String {
        "\(Int(seconds)) s"
    }
}
