import Foundation

public struct AlertSettings: Equatable, Sendable {
    public static let minimumIntervalMinutes: Double = 1
    public static let maximumIntervalMinutes: Double = 240
    public static let minimumBorderDurationSeconds: Double = 1
    public static let maximumBorderDurationSeconds: Double = 30

    public var isEnabled: Bool
    public var intervalMinutes: Double
    public var borderDurationSeconds: Double

    public init(
        isEnabled: Bool = true,
        intervalMinutes: Double = 20,
        borderDurationSeconds: Double = 5
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
    }

    public var intervalSeconds: TimeInterval {
        intervalMinutes * 60
    }

    public var borderDuration: TimeInterval {
        borderDurationSeconds
    }

    public func normalized() -> AlertSettings {
        AlertSettings(
            isEnabled: isEnabled,
            intervalMinutes: intervalMinutes,
            borderDurationSeconds: borderDurationSeconds
        )
    }

    private static func clamp(
        _ value: Double,
        lowerBound: Double,
        upperBound: Double
    ) -> Double {
        min(max(value, lowerBound), upperBound)
    }
}
