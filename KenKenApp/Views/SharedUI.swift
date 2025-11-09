import SwiftUI

// MARK: - Color Helpers

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xff) / 255
        let green = Double((hex >> 8) & 0xff) / 255
        let blue = Double(hex & 0xff) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    static var kkBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0x17153B), Color(hex: 0x433D8B), Color(hex: 0x6C63FF)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Shared Button Styles

struct SoftButtonStyle: ButtonStyle {
    var tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal)
            .background(
                SoftButtonBackground(
                    isPressed: configuration.isPressed,
                    tint: tint
                )
            )
    }
}

struct SoftButtonBackground: View {
    let isPressed: Bool
    let tint: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(tint)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(isPressed ? 0.1 : 0.3), lineWidth: 1.2)
            )
            .shadow(
                color: Color.black.opacity(isPressed ? 0.1 : 0.2),
                radius: isPressed ? 4 : 8,
                x: 0,
                y: isPressed ? 1 : 4
            )
            .scaleEffect(isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
    }
}