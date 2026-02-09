import EyeCareCore
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var isEnabled: Bool
    @Published var intervalMinutes: Double
    @Published var borderDurationSeconds: Double
    @Published var restrictToOfficeHours: Bool
    @Published var officeHoursStartMinutes: Double
    @Published var officeHoursEndMinutes: Double

    var onChange: ((AlertSettings) -> Void)?

    init(settings: AlertSettings) {
        let normalized = settings.normalized()
        self.isEnabled = normalized.isEnabled
        self.intervalMinutes = normalized.intervalMinutes
        self.borderDurationSeconds = normalized.borderDurationSeconds
        self.restrictToOfficeHours = normalized.restrictToOfficeHours
        self.officeHoursStartMinutes = Self.roundedQuarterHourMinutes(fromTotalMinutes: normalized.officeHoursStartMinutes)
        self.officeHoursEndMinutes = Self.roundedQuarterHourMinutes(fromTotalMinutes: normalized.officeHoursEndMinutes)
    }

    func load(_ settings: AlertSettings) {
        let normalized = settings.normalized()
        isEnabled = normalized.isEnabled
        intervalMinutes = normalized.intervalMinutes
        borderDurationSeconds = normalized.borderDurationSeconds
        restrictToOfficeHours = normalized.restrictToOfficeHours
        officeHoursStartMinutes = Self.roundedQuarterHourMinutes(fromTotalMinutes: normalized.officeHoursStartMinutes)
        officeHoursEndMinutes = Self.roundedQuarterHourMinutes(fromTotalMinutes: normalized.officeHoursEndMinutes)
    }

    func commit() {
        onChange?(makeSettings())
    }

    private func makeSettings() -> AlertSettings {
        AlertSettings(
            isEnabled: isEnabled,
            intervalMinutes: intervalMinutes,
            borderDurationSeconds: borderDurationSeconds,
            restrictToOfficeHours: restrictToOfficeHours,
            officeHoursStartMinutes: officeHoursStartMinutes,
            officeHoursEndMinutes: officeHoursEndMinutes
        )
    }

    private static func roundedQuarterHourMinutes(fromTotalMinutes minutesFromMidnight: Double) -> Double {
        let rounded = Int(minutesFromMidnight.rounded())
        let clamped = max(0, min(rounded, 1_439))
        let hours = clamped / 60
        let minutes = clamped % 60
        let roundedMinutes = (Int(round(Double(minutes) / 15.0)) * 15) % 60
        return Double(hours * 60 + roundedMinutes)
    }
}

private enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "General"
    case officeHours = "Office Hours"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .general:
            return "gearshape"
        case .officeHours:
            return "clock"
        }
    }
}

struct SettingsPopupView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var selectedSection: SettingsSection = .officeHours

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            detailContent
        }
        .frame(minWidth: 680, minHeight: 440)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(SettingsSection.allCases) { section in
                Button {
                    selectedSection = section
                } label: {
                    Label(section.rawValue, systemImage: section.iconName)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(
                                    selectedSection == section
                                        ? Color.white.opacity(0.14)
                                        : Color.clear
                                )
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(14)
        .frame(width: 180, alignment: .topLeading)
        .foregroundStyle(.white)
        .background(Color.black.opacity(0.86))
    }

    private var detailContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(selectedSection.rawValue)
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Divider()
                .overlay(.white.opacity(0.25))

            if selectedSection == .officeHours {
                officeHoursPanel
            } else {
                generalPanel
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(Color.black.opacity(0.76))
    }

    private var officeHoursPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            Toggle("Enable office hours", isOn: officeHoursToggleBinding)
                .tint(.blue)
                .foregroundStyle(.white)

            HStack {
                Text("Start")
                    .foregroundStyle(.white)
                Spacer()
                HStack(spacing: 8) {
                    Picker("", selection: startHourBinding) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(String(format: "%02d h", hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 88)

                    Picker("", selection: startMinuteBinding) {
                        ForEach([0, 15, 30, 45], id: \.self) { minute in
                            Text(String(format: "%02d", minute)).tag(minute)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 72)
                }
            }

            HStack {
                Text("End")
                    .foregroundStyle(.white)
                Spacer()
                HStack(spacing: 8) {
                    Picker("", selection: endHourBinding) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(String(format: "%02d h", hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 88)

                    Picker("", selection: endMinuteBinding) {
                        ForEach([0, 15, 30, 45], id: \.self) { minute in
                            Text(String(format: "%02d", minute)).tag(minute)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 72)
                }
            }

            Text("Reminders are active only inside this time range.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var generalPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("General settings stay available from the menu bar panel.")
                .foregroundStyle(.white)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var officeHoursToggleBinding: Binding<Bool> {
        Binding(
            get: { viewModel.restrictToOfficeHours },
            set: { newValue in
                viewModel.restrictToOfficeHours = newValue
                viewModel.commit()
            }
        )
    }

    private var startHourBinding: Binding<Int> {
        Binding(
            get: { startHour },
            set: { newValue in
                viewModel.officeHoursStartMinutes = Double((newValue * 60) + startMinute)
                viewModel.commit()
            }
        )
    }

    private var startMinuteBinding: Binding<Int> {
        Binding(
            get: { startMinute },
            set: { newValue in
                viewModel.officeHoursStartMinutes = Double((startHour * 60) + newValue)
                viewModel.commit()
            }
        )
    }

    private var endHourBinding: Binding<Int> {
        Binding(
            get: { endHour },
            set: { newValue in
                viewModel.officeHoursEndMinutes = Double((newValue * 60) + endMinute)
                viewModel.commit()
            }
        )
    }

    private var endMinuteBinding: Binding<Int> {
        Binding(
            get: { endMinute },
            set: { newValue in
                viewModel.officeHoursEndMinutes = Double((endHour * 60) + newValue)
                viewModel.commit()
            }
        )
    }

    private var startHour: Int {
        let total = Int(viewModel.officeHoursStartMinutes.rounded())
        return max(0, min(total / 60, 23))
    }

    private var startMinute: Int {
        let minute = Int(viewModel.officeHoursStartMinutes.rounded()) % 60
        return nearestQuarter(minute)
    }

    private var endHour: Int {
        let total = Int(viewModel.officeHoursEndMinutes.rounded())
        return max(0, min(total / 60, 23))
    }

    private var endMinute: Int {
        let minute = Int(viewModel.officeHoursEndMinutes.rounded()) % 60
        return nearestQuarter(minute)
    }

    private func nearestQuarter(_ minute: Int) -> Int {
        let quarters = [0, 15, 30, 45]
        return quarters.min(by: { abs($0 - minute) < abs($1 - minute) }) ?? 0
    }
}
