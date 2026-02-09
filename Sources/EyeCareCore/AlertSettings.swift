import Foundation

public enum AlertAccentColor: String, CaseIterable, Sendable {
    case red
    case orange
    case yellow
    case green
    case blue
    case pink
}

public struct AlertSettings: Equatable, Sendable {
    public static let minimumIntervalMinutes: Double = 1
    public static let maximumIntervalMinutes: Double = 240
    public static let minimumBorderDurationSeconds: Double = 1
    public static let maximumBorderDurationSeconds: Double = 30
    public static let minimumOfficeHoursMinutes: Double = 0
    public static let maximumOfficeHoursMinutes: Double = 1_439

    public var isEnabled: Bool
    public var intervalMinutes: Double
    public var borderDurationSeconds: Double
    public var accentColor: AlertAccentColor
    public var restrictToOfficeHours: Bool
    public var officeHoursStartMinutes: Double
    public var officeHoursEndMinutes: Double

    public init(
        isEnabled: Bool = true,
        intervalMinutes: Double = 20,
        borderDurationSeconds: Double = 5,
        accentColor: AlertAccentColor = .red,
        restrictToOfficeHours: Bool = false,
        officeHoursStartMinutes: Double = 9 * 60,
        officeHoursEndMinutes: Double = 17 * 60
    ) {
        self.isEnabled = isEnabled
        self.intervalMinutes = Self.clamp(
            intervalMinutes,
            lowerBound: Self.minimumIntervalMinutes,
            upperBound: Self.maximumIntervalMinutes
        )
        self.borderDurationSeconds = Self.clamp(
            borderDurationSeconds,
            lowerBound: Self.minimumBorderDurationSeconds,
            upperBound: Self.maximumBorderDurationSeconds
        )
        self.accentColor = accentColor
        self.restrictToOfficeHours = restrictToOfficeHours
        self.officeHoursStartMinutes = Self.clamp(
            round(officeHoursStartMinutes),
            lowerBound: Self.minimumOfficeHoursMinutes,
            upperBound: Self.maximumOfficeHoursMinutes
        )
        self.officeHoursEndMinutes = Self.clamp(
            round(officeHoursEndMinutes),
            lowerBound: Self.minimumOfficeHoursMinutes,
            upperBound: Self.maximumOfficeHoursMinutes
        )
    }

    public var intervalSeconds: TimeInterval {
        intervalMinutes * 60
    }

    public var borderDuration: TimeInterval {
        borderDurationSeconds
    }

    public func isReminderAllowed(
        at date: Date,
        calendar: Calendar = .current
    ) -> Bool {
        guard restrictToOfficeHours else {
            return true
        }

        let startMinutes = Int(officeHoursStartMinutes)
        let endMinutes = Int(officeHoursEndMinutes)

        // A matching start/end is treated as an always-on window.
        guard startMinutes != endMinutes else {
            return true
        }

        let minuteOfDay = Self.minuteOfDay(for: date, calendar: calendar)

        if startMinutes < endMinutes {
            return minuteOfDay >= startMinutes && minuteOfDay < endMinutes
        }

        // Overnight window (for example: 22:00 -> 06:00).
        return minuteOfDay >= startMinutes || minuteOfDay < endMinutes
    }

    public func nextOfficeHoursStart(
        after date: Date,
        calendar: Calendar = .current
    ) -> Date? {
        guard restrictToOfficeHours else {
            return nil
        }

        let startMinutes = Int(officeHoursStartMinutes)
        let endMinutes = Int(officeHoursEndMinutes)

        guard startMinutes != endMinutes else {
            return nil
        }

        guard !isReminderAllowed(at: date, calendar: calendar) else {
            return nil
        }

        let todayStart = Self.date(
            onSameDayAs: date,
            minutesFromMidnight: startMinutes,
            calendar: calendar
        )

        if todayStart > date {
            return todayStart
        }

        return calendar.date(byAdding: .day, value: 1, to: todayStart)
    }

    public func normalized() -> AlertSettings {
        AlertSettings(
            isEnabled: isEnabled,
            intervalMinutes: intervalMinutes,
            borderDurationSeconds: borderDurationSeconds,
            accentColor: accentColor,
            restrictToOfficeHours: restrictToOfficeHours,
            officeHoursStartMinutes: officeHoursStartMinutes,
            officeHoursEndMinutes: officeHoursEndMinutes
        )
    }

    private static func clamp(
        _ value: Double,
        lowerBound: Double,
        upperBound: Double
    ) -> Double {
        min(max(value, lowerBound), upperBound)
    }

    private static func minuteOfDay(for date: Date, calendar: Calendar) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        return hour * 60 + minute
    }

    private static func date(
        onSameDayAs date: Date,
        minutesFromMidnight: Int,
        calendar: Calendar
    ) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .minute, value: minutesFromMidnight, to: startOfDay) ?? startOfDay
    }
}
