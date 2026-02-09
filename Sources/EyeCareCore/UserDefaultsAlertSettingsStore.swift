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
        static let accentColor = "eye_rest_alert.accent_color"
        static let restrictToOfficeHours = "eye_rest_alert.restrict_to_office_hours"
        static let officeHoursStartMinutes = "eye_rest_alert.office_hours_start_minutes"
        static let officeHoursEndMinutes = "eye_rest_alert.office_hours_end_minutes"
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
            borderDurationSeconds: defaults.double(forKey: Keys.borderDurationSeconds),
            accentColor: colorValue(
                forKey: Keys.accentColor,
                fallback: fallbackSettings.accentColor
            ),
            restrictToOfficeHours: boolValue(
                forKey: Keys.restrictToOfficeHours,
                fallback: fallbackSettings.restrictToOfficeHours
            ),
            officeHoursStartMinutes: doubleValue(
                forKey: Keys.officeHoursStartMinutes,
                fallback: fallbackSettings.officeHoursStartMinutes
            ),
            officeHoursEndMinutes: doubleValue(
                forKey: Keys.officeHoursEndMinutes,
                fallback: fallbackSettings.officeHoursEndMinutes
            )
        )

        return settings.normalized()
    }

    public func save(_ settings: AlertSettings) {
        let normalizedSettings = settings.normalized()
        defaults.set(normalizedSettings.isEnabled, forKey: Keys.isEnabled)
        defaults.set(normalizedSettings.intervalMinutes, forKey: Keys.intervalMinutes)
        defaults.set(normalizedSettings.borderDurationSeconds, forKey: Keys.borderDurationSeconds)
        defaults.set(normalizedSettings.accentColor.rawValue, forKey: Keys.accentColor)
        defaults.set(normalizedSettings.restrictToOfficeHours, forKey: Keys.restrictToOfficeHours)
        defaults.set(normalizedSettings.officeHoursStartMinutes, forKey: Keys.officeHoursStartMinutes)
        defaults.set(normalizedSettings.officeHoursEndMinutes, forKey: Keys.officeHoursEndMinutes)
    }

    private func boolValue(forKey key: String, fallback: Bool) -> Bool {
        guard defaults.object(forKey: key) != nil else {
            return fallback
        }
        return defaults.bool(forKey: key)
    }

    private func doubleValue(forKey key: String, fallback: Double) -> Double {
        guard defaults.object(forKey: key) != nil else {
            return fallback
        }
        return defaults.double(forKey: key)
    }

    private func colorValue(forKey key: String, fallback: AlertAccentColor) -> AlertAccentColor {
        guard
            let rawValue = defaults.string(forKey: key),
            let color = AlertAccentColor(rawValue: rawValue)
        else {
            return fallback
        }

        return color
    }
}
