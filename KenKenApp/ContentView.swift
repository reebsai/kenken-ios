import SwiftUI

struct ContentView: View {
    // For debugging: inject a fixed seed here (e.g. 42) to get a stable puzzle layout.
    // For production builds, keep this nil to preserve randomness.
    private static let debugSeed: UInt64? = nil

    // Currently selected grid size; nil means show size selection screen.
    @State private var selectedSize: Int? = nil

    // Lazily created when a size is chosen.
    @StateObject private var viewModelHolder = ViewModelHolder()

    var body: some View {
        Group {
            if let size = selectedSize, let viewModel = viewModelHolder.viewModel {
                gameView(size: size, viewModel: viewModel)
            } else {
                // Let the user choose any size from 4...9.
                // We always render puzzles as square grids driven by device width.
                SizeSelectionView { requestedSize in
                    let clamped = KenKenGameViewModel.clampedSize(requestedSize)
                    let vm = KenKenGameViewModel(
                        size: clamped,
                        puzzleProvider: DefaultPuzzleProvider(seed: ContentView.debugSeed),
                        seed: ContentView.debugSeed
                    )
                    viewModelHolder.viewModel = vm
                    selectedSize = clamped
                    #if DEBUG
                    print("[Size] requested=\(requestedSize), effective=\(clamped)")
                    #endif
                }
            }
        }
    }

    @ViewBuilder
    private func gameView(size: Int, viewModel: KenKenGameViewModel) -> some View {
        GeometryReader { proxy in
            ZStack {
                Color.kkBackgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    header(size: viewModel.puzzle.size, viewModel: viewModel)

                    // Square puzzle area strictly driven by device width.
                    let gridSide = proxy.size.width - 32

                    KenKenGridView(
                        puzzle: viewModel.puzzle,
                        userGrid: viewModel.userGrid,
                        cellStateProvider: viewModel.cellState,
                        cageEvaluationProvider: viewModel.cageEvaluation,
                        onSelect: viewModel.select
                    )
                    .frame(width: gridSide, height: gridSide)
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
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

                    Spacer(minLength: 0)
                }
                .padding(.vertical, 24)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            }
            .onAppear {
                print("[Layout] gameView screenSize=\(proxy.size), puzzleSize=\(viewModel.puzzle.size)")
            }
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

