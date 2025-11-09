import SwiftUI

struct ContentView: View {
    // For debugging: inject a fixed seed here (e.g. 42) to get a stable puzzle layout.
    // For production builds, keep this nil to preserve randomness.
    private static let debugSeed: UInt64? = nil

    // Currently selected grid size; nil means show size selection screen.
    @State private var selectedSize: Int? = nil

    // Lazily created when a size is chosen.
    @StateObject private var viewModelHolder = ViewModelHolder()

    private let backgroundGradient = LinearGradient(
        colors: [Color(hex: 0x17153B), Color(hex: 0x433D8B), Color(hex: 0x6C63FF)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        Group {
            if let size = selectedSize, let viewModel = viewModelHolder.viewModel {
                gameView(size: size, viewModel: viewModel)
            } else {
                SizeSelectionView { size in
                    let clampedSize = min(max(size, 4), 9)
                    let vm = KenKenGameViewModel(size: clampedSize, seed: ContentView.debugSeed)
                    viewModelHolder.viewModel = vm
                    selectedSize = clampedSize
                }
            }
        }
    }

    @ViewBuilder
    private func gameView(size: Int, viewModel: KenKenGameViewModel) -> some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 28) {
                header(size: size, viewModel: viewModel)

                KenKenGridView(
                    puzzle: viewModel.puzzle,
                    userGrid: viewModel.userGrid,
                    cellStateProvider: viewModel.cellState,
                    cageEvaluationProvider: viewModel.cageEvaluation,
                    onSelect: viewModel.select
                )
                .aspectRatio(1, contentMode: .fit)
                .padding(.horizontal)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1.2)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 12)

                NumberPadView(
                    numbers: Array(1...viewModel.puzzle.size),
                    onNumberSelected: viewModel.enter,
                    onClear: viewModel.clearSelection
                )
                .padding(.horizontal)

                if viewModel.isSolved {
                    solvedBanner
                }
            }
            .padding(.vertical, 32)
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isSolved)
    }

    // Holder type to allow recreating the view model after @State changes.
    final class ViewModelHolder: ObservableObject {
        @Published var viewModel: KenKenGameViewModel?
    }

    private func header(size: Int, viewModel: KenKenGameViewModel) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("KenKen \(size)×\(size)")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.95))

                Text("Sharpen your logic with elegant arithmetic cages.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.7))
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    // Regenerate puzzle with the same selected size.
                    viewModel.newPuzzle(seed: ContentView.debugSeed)
                }
            } label: {
                Label("New", systemImage: "arrow.2.circlepath")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 18)
            }
            .buttonStyle(SoftButtonStyle(tint: Color.white.opacity(0.22)))

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    // Go back to size selection; discard current game.
                    selectedSize = nil
                    viewModelHolder.viewModel = nil
                }
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.backward")
                    .font(.system(size: 18, weight: .bold))
                    .padding(10)
            }
            .buttonStyle(SoftButtonStyle(tint: Color.white.opacity(0.18)))
        }
        .padding(.horizontal)
    }

    private var solvedBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 22, weight: .bold))
            Text("Brilliant! Puzzle complete.")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 28)
        .padding(.vertical, 14)
        .background(.thinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.3), lineWidth: 1.2)
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

private extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xff) / 255
        let green = Double((hex >> 8) & 0xff) / 255
        let blue = Double(hex & 0xff) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}
