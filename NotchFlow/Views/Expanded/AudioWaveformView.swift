import SwiftUI

struct AudioWaveformView: View {
    @State private var phases: [Double] = Array(repeating: 0, count: 8)

    private let barCount = 8
    private let barWidth: CGFloat = 3
    private let barSpacing: CGFloat = 2
    private let maxBarHeight: CGFloat = 18
    private let minBarHeight: CGFloat = 3

    var body: some View {
        HStack(spacing: barSpacing) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.purple.opacity(0.9),
                                Color(red: 0.42, green: 0.36, blue: 0.91) // #6C5CE7
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(
                        width: barWidth,
                        height: barHeight(for: index)
                    )
                    .animation(
                        .easeInOut(duration: 0.3 + Double(index) * 0.05)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.08),
                        value: phases[index]
                    )
            }
        }
        .frame(alignment: .bottom)
        .onAppear {
            startAnimating()
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        // Generate different heights using sine waves with different frequencies
        let phase = phases[index]
        let normalizedHeight = (sin(phase) + 1) / 2 // 0 to 1
        return minBarHeight + (maxBarHeight - minBarHeight) * CGFloat(normalizedHeight)
    }

    private func startAnimating() {
        for i in 0..<barCount {
            phases[i] = Double.random(in: 0...(2 * .pi))
        }

        // Continuously update phases with a timer
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            for i in 0..<barCount {
                withAnimation(.easeInOut(duration: 0.3)) {
                    phases[i] += Double.random(in: 0.8...2.0)
                }
            }
        }
    }
}
