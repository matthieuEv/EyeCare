import EyeCareCore
import XCTest

final class AlertSettingsTests: XCTestCase {
    func testInitializerClampsInvalidValues() {
        let settings = AlertSettings(
            isEnabled: true,
            intervalMinutes: -4,
            borderDurationSeconds: 100
        )

        XCTAssertEqual(settings.intervalMinutes, AlertSettings.minimumIntervalMinutes)
        XCTAssertEqual(settings.borderDurationSeconds, AlertSettings.maximumBorderDurationSeconds)
    }

    func testIntervalSecondsConversion() {
        let settings = AlertSettings(
            isEnabled: true,
            intervalMinutes: 12,
            borderDurationSeconds: 5
        )

        XCTAssertEqual(settings.intervalSeconds, 720)
    }
}
