import AppKit
import EyeCareCore

@MainActor
final class ScreenBorderOverlayManager: NSObject, OverlayPresenting {
    private var windowsByScreenIdentifier: [String: BorderOverlayWindow] = [:]
    private var hideWorkItem: DispatchWorkItem?

    private let borderWidth: CGFloat
    private let insideCornerRadius: CGFloat
    private let borderColor: NSColor
    private let notificationCenter: NotificationCenter

    init(
        borderWidth: CGFloat = 10,
        insideCornerRadius: CGFloat = 12,
        borderColor: NSColor = .systemRed,
        notificationCenter: NotificationCenter = .default
    ) {
        self.borderWidth = borderWidth
        self.insideCornerRadius = insideCornerRadius
        self.borderColor = borderColor
        self.notificationCenter = notificationCenter

        super.init()

        rebuildWindows()

        notificationCenter.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    func showOverlay(for duration: TimeInterval) {
        rebuildWindows()

        for window in windowsByScreenIdentifier.values {
            window.contentView?.needsDisplay = true
            window.orderFrontRegardless()
        }

        hideWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.hideOverlay()
        }
        hideWorkItem = workItem

        DispatchQueue.main.asyncAfter(deadline: .now() + max(0.1, duration), execute: workItem)
    }

    private func hideOverlay() {
        for window in windowsByScreenIdentifier.values {
            window.orderOut(nil)
        }
    }

    @objc
    private func screenParametersDidChange() {
        rebuildWindows()
    }

    private func rebuildWindows() {
        let screens = NSScreen.screens
        var activeIdentifiers = Set<String>()

        for screen in screens {
            let identifier = screenIdentifier(for: screen)
            activeIdentifiers.insert(identifier)

            if let window = windowsByScreenIdentifier[identifier] {
                window.setFrame(screen.frame, display: true)
            } else {
                let window = BorderOverlayWindow(
                    screen: screen,
                    borderWidth: borderWidth,
                    insideCornerRadius: insideCornerRadius,
                    borderColor: borderColor
                )
                windowsByScreenIdentifier[identifier] = window
            }
        }

        let existingIdentifiers = Set(windowsByScreenIdentifier.keys)
        let removedIdentifiers = existingIdentifiers.subtracting(activeIdentifiers)

        for identifier in removedIdentifiers {
            windowsByScreenIdentifier[identifier]?.orderOut(nil)
            windowsByScreenIdentifier[identifier] = nil
        }
    }

    private func screenIdentifier(for screen: NSScreen) -> String {
        guard
            let value = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
        else {
            return UUID().uuidString
        }

        return value.stringValue
    }
}

@MainActor
private final class BorderOverlayWindow: NSWindow {
    init(
        screen: NSScreen,
        borderWidth: CGFloat,
        insideCornerRadius: CGFloat,
        borderColor: NSColor
    ) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        level = .screenSaver
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        animationBehavior = .none
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]

        let overlayView = BorderOverlayView(frame: NSRect(origin: .zero, size: screen.frame.size))
        overlayView.autoresizingMask = [.width, .height]
        overlayView.borderWidth = borderWidth
        overlayView.insideCornerRadius = insideCornerRadius
        overlayView.borderColor = borderColor

        contentView = overlayView
    }

    override var canBecomeKey: Bool {
        false
    }

    override var canBecomeMain: Bool {
        false
    }
}

@MainActor
private final class BorderOverlayView: NSView {
    var borderWidth: CGFloat = 10 {
        didSet { needsDisplay = true }
    }
    var insideCornerRadius: CGFloat = 12 {
        didSet { needsDisplay = true }
    }
    var borderColor: NSColor = .systemRed {
        didSet { needsDisplay = true }
    }

    override var isOpaque: Bool {
        false
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let width = max(1, borderWidth)
        let innerRect = bounds.insetBy(dx: width, dy: width)
        guard !innerRect.isEmpty else {
            return
        }

        let maxRadius = min(innerRect.width, innerRect.height) / 2
        let radius = max(0, min(insideCornerRadius, maxRadius))

        guard let context = NSGraphicsContext.current?.cgContext else {
            return
        }

        context.clear(bounds)

        let path = CGMutablePath()
        path.addRect(bounds)
        path.addPath(
            CGPath(
                roundedRect: innerRect,
                cornerWidth: radius,
                cornerHeight: radius,
                transform: nil
            )
        )

        context.addPath(path)
        context.setFillColor(borderColor.cgColor)
        context.drawPath(using: .eoFill)
    }
}
