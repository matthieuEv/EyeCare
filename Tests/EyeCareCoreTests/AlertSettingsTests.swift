import EyeCareCore
import XCTest

final class AlertSettingsTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        self.calendar = calendar
    }

    func testInitializerClampsInvalidValues() {
        let settings = AlertSettings(
            isEnabled: true,
            intervalMinutes: -4,
            borderDurationSeconds: 100,
            restrictToOfficeHours: true,
            officeHoursStartMinutes: -90,
            officeHoursEndMinutes: 2_000
        )

        XCTAssertEqual(settings.intervalMinutes, AlertSettings.minimumIntervalMinutes)
        XCTAssertEqual(settings.borderDurationSeconds, AlertSettings.maximumBorderDurationSeconds)
        XCTAssertEqual(settings.officeHoursStartMinutes, AlertSettings.minimumOfficeHoursMinutes)
        XCTAssertEqual(settings.officeHoursEndMinutes, AlertSettings.maximumOfficeHoursMinutes)
    }

    func testIntervalSecondsConversion() {
        let settings = AlertSettings(
            isEnabled: true,
            intervalMinutes: 12,
            borderDurationSeconds: 5
        )

        XCTAssertEqual(settings.intervalSeconds, 720)
    }

    func testOfficeHoursAllowsRemindersOnlyInsideDayRange() {
        let settings = AlertSettings(
            isEnabled: true,
            intervalMinutes: 20,
            borderDurationSeconds: 5,
            restrictToOfficeHours: true,
            officeHoursStartMinutes: 9 * 60,
            officeHoursEndMinutes: 17 * 60
        )

        XCTAssertFalse(settings.isReminderAllowed(at: date(hour: 8, minute: 59), calendar: calendar))
        XCTAssertTrue(settings.isReminderAllowed(at: date(hour: 9, minute: 0), calendar: calendar))
        XCTAssertTrue(settings.isReminderAllowed(at: date(hour: 16, minute: 30), calendar: calendar))
        XCTAssertFalse(settings.isReminderAllowed(at: date(hour: 17, minute: 0), calendar: calendar))
    }

    func testOfficeHoursSupportsOvernightRanges() {
        let settings = AlertSettings(
            isEnabled: true,
            intervalMinutes: 20,
            borderDurationSeconds: 5,
            restrictToOfficeHours: true,
            officeHoursStartMinutes: 22 * 60,
            officeHoursEndMinutes: 6 * 60
        )

        XCTAssertTrue(settings.isReminderAllowed(at: date(hour: 23, minute: 0), calendar: calendar))
        XCTAssertTrue(settings.isReminderAllowed(at: date(hour: 2, minute: 0), calendar: calendar))
        XCTAssertFalse(settings.isReminderAllowed(at: date(hour: 12, minute: 0), calendar: calendar))
    }

    func testNextOfficeHoursStartReturnsNextEntryTimeWhenOutsideRange() {
        let settings = AlertSettings(
            isEnabled: true,
            intervalMinutes: 20,
            borderDurationSeconds: 5,
            restrictToOfficeHours: true,
            officeHoursStartMinutes: 9 * 60,
            officeHoursEndMinutes: 17 * 60
        )

        let now = date(hour: 18, minute: 10)
        let nextStart = settings.nextOfficeHoursStart(after: now, calendar: calendar)

        XCTAssertEqual(
            nextStart,
            calendar.date(
                byAdding: .day,
                value: 1,
                to: date(hour: 9, minute: 0)
            )
        )
    }

    private func date(hour: Int, minute: Int) -> Date {
        date(hour: hour, minute: minute, calendar: calendar)
    }

    private func date(hour: Int, minute: Int, calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 1, day: 15, hour: hour, minute: minute))!
    }
}
