import SwiftUI

struct MicrowaveControlView: View {
    // MARK: - State
    @State private var selectedPreset: Preset? = nil
    @State private var customSeconds: Int = 0
    @State private var isRunning: Bool = false
    @State private var isPaused: Bool = false
    @State private var remainingSeconds: Int = 0
    @State private var timer: Timer? = nil

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.gray.opacity(0.9)]),
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // Timer display
                Text(displayTime)
                    .font(.system(size: 64, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(.darkGray)))
                    .shadow(radius: 5)

                // Preset buttons
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                    ForEach(Preset.allCases) { preset in
                        Button(action: { applyPreset(preset) }) {
                            VStack(spacing: 8) {
                                preset.image.font(.title2)
                                Text(preset.rawValue).font(.caption)
                            }
                            .foregroundColor(selectedPreset == preset ? .white : .primary)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedPreset == preset ? Color.orange : Color(.systemGray5))
                            )
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 2, y: 2)
                        }
                    }
                }
                .padding(.horizontal)

                // Custom time increments
                HStack(spacing: 16) {
                    ForEach([600, 60, 10, 1], id: \.self) { sec in
                        Button(action: { adjustTime(by: sec) }) {
                            Text(customLabel(for: sec))
                                .font(.headline)
                                .frame(width: 60, height: 40)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray5)))
                        }
                        .disabled(isRunning)
                    }
                }

                // Controls: Start/Pause toggle + Cancel
                HStack(spacing: 24) {
                    ControlButton(
                        systemName: (isRunning && !isPaused) ? "pause.fill" : "play.fill",
                        title: (isRunning && !isPaused) ? "Pause" : "Start",
                        action: toggleStartPause,
                        disabled: !isRunning && remainingSeconds == 0
                    )
                    ControlButton(
                        systemName: "stop.fill",
                        title: "Cancel",
                        action: cancel,
                        disabled: !isRunning && remainingSeconds == 0
                    )
                }
                .padding(.bottom, 20)
            }
            .padding()
        }
    }

    // MARK: - Display
    private var displayTime: String {
        let sec = remainingSeconds
        return String(format: "%02d:%02d", sec / 60, sec % 60)
    }

    // MARK: - Actions
    private func applyPreset(_ preset: Preset) {
        selectedPreset = preset
        let secs = preset.seconds
        remainingSeconds = secs
        customSeconds = secs
        resetTimerState()
    }

    private func adjustTime(by delta: Int) {
        selectedPreset = nil
        customSeconds = max(0, customSeconds + delta)
        customSeconds = min(customSeconds, 3600)
        remainingSeconds = customSeconds
    }

    private func start() {
        guard remainingSeconds > 0 else { return }
        isRunning = true
        isPaused = false
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            tick()
        }
    }

    private func toggleStartPause() {
        if isRunning && !isPaused {
            // Pause
            timer?.invalidate()
            isPaused = true
        } else {
            // Start or Resume
            start()
        }
    }

    private func cancel() {
        resetTimerState()
        remainingSeconds = 0
        customSeconds = 0
        selectedPreset = nil
    }

    private func tick() {
        if remainingSeconds > 0 {
            remainingSeconds -= 1
        } else {
            timer?.invalidate()
            isRunning = false
        }
    }

    private func resetTimerState() {
        timer?.invalidate()
        isRunning = false
        isPaused = false
    }

    // MARK: - Helpers
    private func customLabel(for sec: Int) -> String {
        switch sec {
        case 600: return "+10m"
        case 60: return "+1m"
        case 10: return "+10s"
        case 1: return "+1s"
        default: return ""
        }
    }
}

// MARK: - Preset Model
enum Preset: String, CaseIterable, Identifiable {
    case popcorn = "Popcorn"
    case beverage = "Beverage"
    case vegetable = "Vegetable"
    case dumplings = "Dumplings"
    case fish = "Fish"
    case stirFry = "Stir Fry"

    var id: String { rawValue }
    var seconds: Int {
        switch self {
        case .popcorn: return 120
        case .beverage: return 60
        case .vegetable: return 180
        case .dumplings: return 150
        case .fish: return 200
        case .stirFry: return 180
        }
    }
    var iconName: String {
        switch self {
        case .popcorn: return "popcorn"
        case .beverage: return "cup.and.saucer"
        case .vegetable: return "leaf"
        case .dumplings: return "takeoutbag.and.cup.and.straw"
        case .fish: return "fish"
        case .stirFry: return "flame"
        }
    }
    var image: Image {
        if let uiImage = UIImage(systemName: iconName) {
            return Image(uiImage: uiImage)
        } else {
            return Image(systemName: "questionmark.circle")
        }
    }
}

// MARK: - Control Button View
struct ControlButton: View {
    let systemName: String
    let title: String
    let action: () -> Void
    let disabled: Bool

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemName).font(.title2)
                Text(title).font(.caption)
            }
            .padding(12)
            .frame(width: 70)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(disabled ? Color(.systemGray3) : Color.orange)
            )
            .foregroundColor(.white)
            .shadow(radius: 3)
        }
        .disabled(disabled)
    }
}

// MARK: - Preview
struct ContentView: View { var body: some View { MicrowaveControlView() } }
struct ContentView_Previews: PreviewProvider { static var previews: some View { ContentView() } }
