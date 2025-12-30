import SwiftUI

struct MiniRecorderView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var whisperState: WhisperState

    var body: some View {
        VStack(spacing: 12) {
            // Audio Visualizer
            AudioVisualizerView(level: appState.audioLevel)
                .frame(height: 40)

            // Status Row
            HStack {
                // Recording indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(.red)
                        .frame(width: 10, height: 10)
                        .opacity(appState.isRecording ? 1 : 0)

                    Text(appState.formattedDuration)
                        .font(.system(.title3, design: .monospaced))
                        .monospacedDigit()
                }

                Spacer()

                // Mode indicator (shows which hotkey's mode is active)
                let activeMode = appState.currentSessionMode ?? appState.processingMode
                Label(activeMode.rawValue, systemImage: activeMode.icon)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(activeMode == .advanced ? Color.purple.opacity(0.3) : Color.gray.opacity(0.2))
                    .cornerRadius(4)

                Spacer()

                // Cancel button
                Button {
                    appState.cancelRecording()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
            }
        }
        .padding(16)
        .frame(width: 280, height: 100)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(radius: 10)
    }
}

// MARK: - Audio Visualizer

struct AudioVisualizerView: View {
    let level: Float
    let barCount = 20

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 3) {
                ForEach(0..<barCount, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor(for: index))
                        .frame(width: barWidth(in: geometry), height: barHeight(for: index, in: geometry))
                        .animation(.linear(duration: 0.05), value: level)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func barWidth(in geometry: GeometryProxy) -> CGFloat {
        let totalSpacing = CGFloat(barCount - 1) * 3
        return (geometry.size.width - totalSpacing) / CGFloat(barCount)
    }

    private func barHeight(for index: Int, in geometry: GeometryProxy) -> CGFloat {
        let maxHeight = geometry.size.height
        let minHeight: CGFloat = 4

        // Create a wave pattern based on level
        let centerIndex = barCount / 2
        let distanceFromCenter = abs(index - centerIndex)
        let normalizedDistance = CGFloat(distanceFromCenter) / CGFloat(centerIndex)

        // Bars closer to center are taller
        let heightMultiplier = 1.0 - (normalizedDistance * 0.5)
        let levelHeight = CGFloat(level) * maxHeight * heightMultiplier

        // Add some randomness for more natural look
        let randomFactor = CGFloat.random(in: 0.8...1.2)

        return max(minHeight, min(maxHeight, levelHeight * randomFactor))
    }

    private func barColor(for index: Int) -> Color {
        let intensity = CGFloat(level)
        if intensity > 0.8 {
            return .red
        } else if intensity > 0.5 {
            return .orange
        } else {
            return .green
        }
    }
}

// MARK: - Preview

#Preview("Recording") {
    MiniRecorderView()
        .environmentObject({
            let state = AppState.shared
            return state
        }())
        .environmentObject(WhisperState.shared)
        .background(.black.opacity(0.3))
        .padding(50)
}
