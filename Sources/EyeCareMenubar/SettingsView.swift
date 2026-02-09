import EyeCareCore
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var isEnabled: Bool
    @Published var intervalMinutes: Double
    @Published var borderDurationSeconds: Double

    var onChange: ((AlertSettings) -> Void)?

    init(settings: AlertSettings) {
        self.isEnabled = settings.isEnabled
        self.intervalMinutes = settings.intervalMinutes
        self.borderDurationSeconds = settings.borderDurationSeconds
    }

    func load(_ settings: AlertSettings) {
        let normalized = settings.normalized()
        isEnabled = normalized.isEnabled
        intervalMinutes = normalized.intervalMinutes
        borderDurationSeconds = normalized.borderDurationSeconds
    }

    func commit() {
        onChange?(makeSettings())
    }

    private func makeSettings() -> AlertSettings {
        AlertSettings(
            isEnabled: isEnabled,
            intervalMinutes: intervalMinutes,
            borderDurationSeconds: borderDurationSeconds
        )
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Reduce eye strain")
                .font(.title3.weight(.semibold))

            Toggle("Enable reminders", isOn: enabledBinding)

            VStack(alignment: .leading, spacing: 8) {
                Text("Interval")
                    .font(.headline)
                Stepper(value: intervalBinding, in: AlertSettings.minimumIntervalMinutes...AlertSettings.maximumIntervalMinutes, step: 1) {
                    Text("\(Int(viewModel.intervalMinutes)) min")
                        .monospacedDigit()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Alert duration")
                    .font(.headline)
                Stepper(value: durationBinding, in: AlertSettings.minimumBorderDurationSeconds...AlertSettings.maximumBorderDurationSeconds, step: 1) {
                    Text("\(Int(viewModel.borderDurationSeconds)) sec")
                        .monospacedDigit()
                }
            }

            Text("A red break cue is shown on all connected displays.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(20)
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isEnabled },
            set: { newValue in
                viewModel.isEnabled = newValue
                viewModel.commit()
            }
        )
    }

    private var intervalBinding: Binding<Double> {
        Binding(
            get: { viewModel.intervalMinutes },
            set: { newValue in
                viewModel.intervalMinutes = newValue
                viewModel.commit()
            }
        )
    }

    private var durationBinding: Binding<Double> {
        Binding(
            get: { viewModel.borderDurationSeconds },
            set: { newValue in
                viewModel.borderDurationSeconds = newValue
                viewModel.commit()
            }
        )
    }
}
