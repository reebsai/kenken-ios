import Foundation

// MARK: - PuzzleProvider Protocol

protocol PuzzleProvider {
    func makePuzzle(size: Int) -> KenKenPuzzle
}

// MARK: - Default Implementation

struct DefaultPuzzleProvider: PuzzleProvider {
    let seed: UInt64?

    init(seed: UInt64? = nil) {
        self.seed = seed
    }

    func makePuzzle(size: Int) -> KenKenPuzzle {
        KenKenGenerator.makePuzzle(size: size, seed: seed)
    }
}