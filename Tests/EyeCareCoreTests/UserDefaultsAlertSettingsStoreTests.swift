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
        let expected = AlertSettings(isEnabled: true, intervalMinutes: 18, borderDurationSeconds: 8)

        store.save(expected)

        XCTAssertEqual(store.load(), expected)
    }
}
