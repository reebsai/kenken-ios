import Foundation

// MARK: - PuzzleProvider Protocol

public protocol PuzzleProvider {
    func makePuzzle(size: Int) -> KenKenPuzzle
}

// MARK: - Default Implementation

public struct DefaultPuzzleProvider: PuzzleProvider {
    public let seed: UInt64?

    public init(seed: UInt64? = nil) {
        self.seed = seed
    }

    public func makePuzzle(size: Int) -> KenKenPuzzle {
        KenKenGenerator.makePuzzle(size: size, seed: seed)
    }
}