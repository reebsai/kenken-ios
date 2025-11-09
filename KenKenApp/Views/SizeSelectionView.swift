import SwiftUI

struct SizeSelectionView: View {
    let onSizeSelected: (Int) -> Void

    private let availableSizes = Array(4...9)

    private let backgroundGradient = LinearGradient(
        colors: [Color(hex: 0x17153B), Color(hex: 0x433D8B), Color(hex: 0x6C63FF)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 32) {
                header

                sizeButtons

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 48)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Field size")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.96))

            Text("Choose a grid from 4×4 up to 9×9. Larger grids are trickier and take longer to solve.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sizeButtons: some View {
        VStack(spacing: 18) {
            ForEach(availableSizes, id: \.self) { size in
                Button {
                    onSizeSelected(size)
                } label: {
                    HStack {
                        Text("\(size)×\(size)")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(0.10))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// Reuse the same Color(hex:) helper as in ContentView to keep visuals consistent.
private extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xff) / 255
        let green = Double((hex >> 8) & 0xff) / 255
        let blue = Double(hex & 0xff) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}