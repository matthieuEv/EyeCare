import EyeCareCore
import XCTest

final class UserDefaultsAlertSettingsStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "UserDefaultsAlertSettingsStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testLoadReturnsFallbackWhenNoValueWasSaved() {
        let fallback = AlertSettings(isEnabled: false, intervalMinutes: 30, borderDurationSeconds: 4)
        let store = UserDefaultsAlertSettingsStore(defaults: defaults, fallbackSettings: fallback)

        XCTAssertEqual(store.load(), fallback)
    }

    func testSaveThenLoadRoundTripsValues() {
        let store = UserDefaultsAlertSettingsStore(defaults: defaults)
        let expected = AlertSettings(
            isEnabled: true,
            intervalMinutes: 18,
            borderDurationSeconds: 8,
            accentColor: .blue,
            restrictToOfficeHours: true,
            officeHoursStartMinutes: 8 * 60,
            officeHoursEndMinutes: 18 * 60
        )

        store.save(expected)

        XCTAssertEqual(store.load(), expected)
    }

    func testLoadUsesFallbackOfficeHoursValuesForLegacyStoredData() {
        defaults.set(true, forKey: "eye_rest_alert.is_enabled")
        defaults.set(22.0, forKey: "eye_rest_alert.interval_minutes")
        defaults.set(7.0, forKey: "eye_rest_alert.border_duration_seconds")

        let fallback = AlertSettings(
            isEnabled: false,
            intervalMinutes: 30,
            borderDurationSeconds: 6,
            accentColor: .green,
            restrictToOfficeHours: true,
            officeHoursStartMinutes: 10 * 60,
            officeHoursEndMinutes: 19 * 60
        )
        let store = UserDefaultsAlertSettingsStore(defaults: defaults, fallbackSettings: fallback)

        let loaded = store.load()

        XCTAssertEqual(loaded.isEnabled, true)
        XCTAssertEqual(loaded.intervalMinutes, 22)
        XCTAssertEqual(loaded.borderDurationSeconds, 7)
        XCTAssertEqual(loaded.accentColor, fallback.accentColor)
        XCTAssertEqual(loaded.restrictToOfficeHours, fallback.restrictToOfficeHours)
        XCTAssertEqual(loaded.officeHoursStartMinutes, fallback.officeHoursStartMinutes)
        XCTAssertEqual(loaded.officeHoursEndMinutes, fallback.officeHoursEndMinutes)
    }
}
