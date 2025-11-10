import Foundation

// MARK: - PuzzleProvider Protocol
//
// This protocol and its default implementation are kept internal to the app
// module. We avoid exposing `KenKenPuzzle` as `public` API, which keeps CI
// builds simple and prevents access-control violations when building as an
// app (not a reusable framework).

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