import XCTest
@testable import KenKenApp

final class KenKenAppTests: XCTestCase {

    // MARK: - Generator / Latin Square

    func testGeneratorProducesLatinSquare() {
        let size = 9
        let puzzle = KenKenGenerator.makePuzzle(size: size)

        XCTAssertEqual(puzzle.solution.count, size, "Solution should have \(size) rows")

        for row in puzzle.solution {
            XCTAssertEqual(row.count, size, "Each row should have \(size) columns")
            XCTAssertEqual(Set(row), Set(1...size), "Each row must be a permutation of 1...\(size)")
        }

        for column in 0..<size {
            let columnValues = puzzle.solution.map { $0[column] }
            XCTAssertEqual(Set(columnValues), Set(1...size), "Each column must be a permutation of 1...\(size)")
        }
    }

    func testGeneratorDeterministicWithSeed() {
        let size = 6
        let seed: UInt64 = 42

        let puzzleA = KenKenGenerator.makePuzzle(size: size, seed: seed)
        let puzzleB = KenKenGenerator.makePuzzle(size: size, seed: seed)

        XCTAssertEqual(puzzleA.size, size)
        XCTAssertEqual(puzzleB.size, size)
        XCTAssertEqual(puzzleA.solution, puzzleB.solution, "Same seed should produce identical solutions")
        XCTAssertEqual(puzzleA.cages.count, puzzleB.cages.count, "Same seed should produce identical cage count")
        XCTAssertEqual(
            cageSignature(puzzleA.cages),
            cageSignature(puzzleB.cages),
            "Same seed should produce identical cage layout and parameters"
        )
    }

    func testGeneratorDifferentSeedsUsuallyDiffer() {
        let size = 6
        let puzzleA = KenKenGenerator.makePuzzle(size: size, seed: 1)
        let puzzleB = KenKenGenerator.makePuzzle(size: size, seed: 2)

        // Not guaranteed, but highly likely; this is a smoke-test heuristic.
        XCTAssertNotEqual(
            cageSignature(puzzleA.cages),
            cageSignature(puzzleB.cages),
            "Different seeds should typically produce different cage layouts"
        )
    }

    // MARK: - Puzzle invariants

    func testAllCellsCoveredByExactlyOneCage() {
        let size = 6
        let puzzle = KenKenGenerator.makePuzzle(size: size)
        var seen: [GridPosition: Int] = [:]

        for (index, cage) in puzzle.cages.enumerated() {
            for cell in cage.cells {
                XCTAssertNil(seen[cell], "Cell \(cell) appears in multiple cages")
                seen[cell] = index
            }
        }

        XCTAssertEqual(
            seen.count,
            size * size,
            "All \(size * size) cells must be covered by exactly one cage"
        )
    }

    func testCageTargetsMatchSolution() {
        let size = 5
        let puzzle = KenKenGenerator.makePuzzle(size: size)

        for cage in puzzle.cages {
            let eval = cage.evaluate(using: puzzle.solution.map { row in row.map(Optional.init) })
            XCTAssertEqual(
                eval,
                .satisfied,
                "Cage \(cage) must be satisfied by the puzzle solution"
            )
        }
    }

    // MARK: - KenKenPuzzle isSolved

    func testIsSolvedMatchesSolution() {
        let size = 4
        let puzzle = KenKenGenerator.makePuzzle(size: size)

        var userGrid = Array(
            repeating: Array(repeating: Optional<Int>.none, count: size),
            count: size
        )

        // Empty grid not solved
        XCTAssertFalse(puzzle.isSolved(by: userGrid))

        // Fill with correct solution => solved
        for row in 0..<size {
            for col in 0..<size {
                userGrid[row][col] = puzzle.solution[row][col]
            }
        }
        XCTAssertTrue(puzzle.isSolved(by: userGrid))

        // Introduce a wrong value => not solved
        userGrid[0][0] = (puzzle.solution[0][0] % size) + 1
        XCTAssertFalse(puzzle.isSolved(by: userGrid))
    }

    // MARK: - ViewModel behaviors (with FakePuzzleProvider)

    func testViewModelUsesProviderAndReportsSolved() {
        let size = 4
        let fakePuzzle = makeTrivialPuzzle(size: size)
        let provider = FakePuzzleProvider(puzzle: fakePuzzle)

        let viewModel = KenKenGameViewModel(size: size, puzzleProvider: provider, seed: nil)

        // Initially not solved
        XCTAssertFalse(viewModel.isSolved)

        // Fill userGrid through public API
        for row in 0..<size {
            for col in 0..<size {
                viewModel.selectedPosition = GridPosition(row: row, col: col)
                viewModel.enter(fakePuzzle.solution[row][col])
            }
        }

        XCTAssertTrue(viewModel.isSolved, "ViewModel should report solved when userGrid matches solution")
    }

    func testViewModelNewPuzzleWithSeedIsDeterministic() {
        let size = 4
        let seed: UInt64 = 99
        let provider = DefaultPuzzleProvider() // actual generator; seed handled in view model

        let vmA = KenKenGameViewModel(size: size, puzzleProvider: provider, seed: seed)
        let initialPuzzle = vmA.puzzle

        vmA.newPuzzle(seed: seed)
        let regenerated = vmA.puzzle

        XCTAssertEqual(initialPuzzle.size, regenerated.size)
        XCTAssertEqual(initialPuzzle.solution, regenerated.solution, "Seeded newPuzzle should be deterministic for same size/seed")
    }

    // MARK: - Helpers

    private func cageSignature(_ cages: [KenKenCage]) -> String {
        cages
            .sorted { lhs, rhs in lhs.id.uuidString < rhs.id.uuidString }
            .map { cage in
                let cells = cage.cells
                    .sorted { a, b in (a.row, a.col) < (b.row, b.col) }
                    .map { "\($0.row),\($0.col)" }
                    .joined(separator: ";")
                return "\(cage.operation)-\(cage.target)-[\(cells)]"
            }
            .joined(separator: "|")
    }

    private func makeTrivialPuzzle(size: Int) -> KenKenPuzzle {
        let solution: [[Int]] = (0..<size).map { row in
            (0..<size).map { col in ((row + col) % size) + 1 }
        }
        // Single-cell cages for simplicity; always satisfied by solution
        let cages: [KenKenCage] = (0..<size).flatMap { row in
            (0..<size).map { col in
                let pos = GridPosition(row: row, col: col)
                return KenKenCage(cells: [pos], operation: .single, target: solution[row][col])
            }
        }
        return KenKenPuzzle(size: size, solution: solution, cages: cages)
    }
}

// MARK: - Fake Provider

private struct FakePuzzleProvider: PuzzleProvider {
    let puzzle: KenKenPuzzle
    func makePuzzle(size: Int) -> KenKenPuzzle {
        XCTAssertEqual(size, puzzle.size, "FakePuzzleProvider should be requested with expected size")
        return puzzle
    }
}
