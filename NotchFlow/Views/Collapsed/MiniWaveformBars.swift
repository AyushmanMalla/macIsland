import SwiftUI

struct MiniWaveformBars: View {
    @State private var animating = false

    private let barCount = 3
    private let barWidth: CGFloat = 2.5
    private let maxHeight: CGFloat = 14
    private let minHeight: CGFloat = 3

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(0.8))
                    .frame(width: barWidth, height: maxHeight)
                    .scaleEffect(
                        y: animating ? randomScale(for: index) : (minHeight / maxHeight),
                        anchor: .bottom
                    )
                    .animation(
                        .easeInOut(duration: 0.4 + Double(index) * 0.15)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.1),
                        value: animating
                    )
            }
        }
        .frame(height: maxHeight)
        .onAppear {
            animating = true
        }
    }

    private func randomScale(for index: Int) -> CGFloat {
        let heights: [CGFloat] = [12, 8, 10]
        return heights[index % heights.count] / maxHeight
    }
}
