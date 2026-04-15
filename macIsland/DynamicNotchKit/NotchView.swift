import SwiftUI

struct NotchView<Content>: View where Content: View {
    @ObservedObject var dynamicNotch: DynamicNotch<Content>

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    Spacer()
                        .frame(width: dynamicNotch.notchWidth, height: dynamicNotch.notchHeight)

                    if dynamicNotch.isNotificationVisible {
                        dynamicNotch.content()
                            .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: 15) }
                            .safeAreaInset(edge: .leading, spacing: 0) { Color.clear.frame(width: 15) }
                            .safeAreaInset(edge: .trailing, spacing: 0) { Color.clear.frame(width: 15) }
                            .blur(radius: dynamicNotch.isVisible ? 0 : 10)
                            .scaleEffect(dynamicNotch.isVisible ? 1 : 0.8)
                            .offset(y: dynamicNotch.isVisible ? 0 : 5)
                            .padding(.horizontal, 15)
                            .transition(.blur.animation(.smooth))
                    }

                    if dynamicNotch.isMouseInside {
                        ExpandedIslandView(
                            nowPlayingService: dynamicNotch.nowPlayingService,
                            taskStore: dynamicNotch.taskStore,
                            selectedTab: $dynamicNotch.selectedTab
                        )
                            .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: 15) }
                            .safeAreaInset(edge: .leading, spacing: 0) { Color.clear.frame(width: 15) }
                            .safeAreaInset(edge: .trailing, spacing: 0) { Color.clear.frame(width: 15) }
                            .blur(radius: dynamicNotch.isVisible ? 0 : 10)
                            .scaleEffect(dynamicNotch.isVisible ? 1 : 0.8)
                            .offset(y: dynamicNotch.isVisible ? 0 : 5)
                            .padding(.horizontal, 15)
                            .transition(.blur.animation(.smooth))
                    }
                }
                .fixedSize()
                .frame(minWidth: dynamicNotch.notchWidth)
                .background {
                    Rectangle()
                        .foregroundStyle(.black)
                        .padding(-50)
                }
                .mask {
                    GeometryReader { _ in
                        HStack {
                            Spacer(minLength: 0)
                            NotchShape(cornerRadius: dynamicNotch.isVisible ? 20 : nil)
                                .frame(
                                    width: dynamicNotch.isVisible ? nil : dynamicNotch.notchWidth,
                                    height: dynamicNotch.isVisible ? nil : dynamicNotch.notchHeight
                                )
                            Spacer(minLength: 0)
                        }
                    }
                }
                .shadow(color: .black.opacity(0.6), radius: dynamicNotch.isVisible ? 10 : 0)
                .animation(dynamicNotch.animation, value: dynamicNotch.contentID)

                Spacer()
            }

            Spacer()
        }
    }
}
