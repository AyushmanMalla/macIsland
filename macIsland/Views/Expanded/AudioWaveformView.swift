import SwiftUI

struct AudioWaveformView: View {
    @State private var targetScales: [CGFloat] = Array(repeating: 0.2, count: 8)
    @State private var isAnimating: Bool = false

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
                    .frame(width: barWidth, height: maxBarHeight)
                    .scaleEffect(
                        y: isAnimating ? targetScales[index] : (minBarHeight / maxBarHeight),
                        anchor: .bottom
                    )
                    .animation(
                        .easeInOut(duration: 0.3 + Double(index) * 0.05)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.08),
                        value: isAnimating
                    )
            }
        }
        .frame(alignment: .bottom)
        .onAppear {
            startAnimating()
        }
    }

    private func startAnimating() {
        for i in 0..<barCount {
            let normalizedHeight = (sin(Double.random(in: 0...(2 * .pi))) + 1) / 2
            targetScales[i] = (minBarHeight + (maxBarHeight - minBarHeight) * CGFloat(normalizedHeight)) / maxBarHeight
        }
        isAnimating = true
    }
}
