import Foundation

public protocol AlertSettingsStoring {
    func load() -> AlertSettings
    func save(_ settings: AlertSettings)
}

public final class UserDefaultsAlertSettingsStore: AlertSettingsStoring {
    private enum Keys {
        static let isEnabled = "eye_rest_alert.is_enabled"
        static let intervalMinutes = "eye_rest_alert.interval_minutes"
        static let borderDurationSeconds = "eye_rest_alert.border_duration_seconds"
    }

    private let defaults: UserDefaults
    private let fallbackSettings: AlertSettings

    public init(
        defaults: UserDefaults = .standard,
        fallbackSettings: AlertSettings = AlertSettings()
    ) {
        self.defaults = defaults
        self.fallbackSettings = fallbackSettings
    }

    public func load() -> AlertSettings {
        let hasSavedValue = defaults.object(forKey: Keys.intervalMinutes) != nil

        guard hasSavedValue else {
            return fallbackSettings
        }

        let settings = AlertSettings(
            isEnabled: defaults.bool(forKey: Keys.isEnabled),
            intervalMinutes: defaults.double(forKey: Keys.intervalMinutes),
            borderDurationSeconds: defaults.double(forKey: Keys.borderDurationSeconds)
        )

        return settings.normalized()
    }

    public func save(_ settings: AlertSettings) {
        let normalizedSettings = settings.normalized()
        defaults.set(normalizedSettings.isEnabled, forKey: Keys.isEnabled)
        defaults.set(normalizedSettings.intervalMinutes, forKey: Keys.intervalMinutes)
        defaults.set(normalizedSettings.borderDurationSeconds, forKey: Keys.borderDurationSeconds)
    }
}
