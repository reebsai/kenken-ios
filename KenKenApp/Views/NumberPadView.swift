import SwiftUI

struct NumberPadView: View {
    let numbers: [Int]
    let onNumberSelected: (Int) -> Void
    let onClear: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(numbers, id: \.self) { number in
                    Button {
                        onNumberSelected(number)
                    } label: {
                        Text("\(number)")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(NumberButtonStyle())
                }
            }

            Button {
                onClear()
            } label: {
                Text("Clear")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(SoftButtonStyle(tint: .pink.opacity(0.7)))
        }
    }
}

private struct NumberButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal)
            .background(SoftButtonBackground(isPressed: configuration.isPressed, tint: Color.white.opacity(0.18)))
    }
}
