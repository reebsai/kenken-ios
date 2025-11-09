import Foundation
import SwiftUI

@MainActor
final class KenKenGameViewModel: ObservableObject {
    @Published private(set) var puzzle: KenKenPuzzle
    @Published var userGrid: [[Int?]]
    @Published var selectedPosition: GridPosition?
    @Published private(set) var isSolved: Bool = false

    static func clampedSize(_ size: Int) -> Int {
        min(max(size, 4), 9)
    }

    private let puzzleProvider: PuzzleProvider

    init(size: Int, puzzleProvider: PuzzleProvider = DefaultPuzzleProvider(), seed: UInt64? = nil) {
        let clampedSize = Self.clampedSize(size)
        self.puzzleProvider = puzzleProvider
        // If a seed is provided, prefer a seeded provider for deterministic generation.
        if let seed {
            let seededProvider = DefaultPuzzleProvider(seed: seed)
            let puzzle = seededProvider.makePuzzle(size: clampedSize)
            self.puzzle = puzzle
        } else {
            let puzzle = puzzleProvider.makePuzzle(size: clampedSize)
            self.puzzle = puzzle
        }
        self.userGrid = Array(repeating: Array(repeating: nil, count: puzzle.size), count: puzzle.size)
    }

    func select(_ position: GridPosition) {
        selectedPosition = position
    }

    func enter(_ value: Int) {
        guard let position = selectedPosition, (1...puzzle.size).contains(value) else { return }
        userGrid[position.row][position.col] = value
        refreshSolvedState()
    }

    func clearSelection() {
        guard let position = selectedPosition else { return }
        userGrid[position.row][position.col] = nil
        refreshSolvedState()
    }

    func newPuzzle(seed: UInt64? = nil) {
        let currentSize = Self.clampedSize(puzzle.size)
        let nextPuzzle: KenKenPuzzle
        if let seed {
            // Deterministic puzzle for the same size.
            let seededProvider = DefaultPuzzleProvider(seed: seed)
            nextPuzzle = seededProvider.makePuzzle(size: currentSize)
        } else {
            nextPuzzle = puzzleProvider.makePuzzle(size: currentSize)
        }

        self.puzzle = nextPuzzle
        self.userGrid = Array(repeating: Array(repeating: nil, count: nextPuzzle.size), count: nextPuzzle.size)
        selectedPosition = nil
        isSolved = false
    }

    enum CellState {
        case empty
        case selected
        case conflict
        case filled
        case correct
    }

    func cellState(for position: GridPosition) -> CellState {
        if selectedPosition == position {
            return .selected
        }

        guard let value = userGrid[position.row][position.col] else {
            return .empty
        }

        if hasConflict(at: position, value: value) {
            return .conflict
        }

        if puzzle.solution[position.row][position.col] == value {
            return .correct
        }

        return .filled
    }

    func cageEvaluation(for cage: KenKenCage) -> KenKenCage.Evaluation {
        cage.evaluate(using: userGrid)
    }

    private func hasConflict(at position: GridPosition, value: Int) -> Bool {
        hasRowConflict(at: position, value: value) || hasColumnConflict(at: position, value: value) || hasCageConflict(at: position)
    }

    private func hasRowConflict(at position: GridPosition, value: Int) -> Bool {
        userGrid[position.row].enumerated().contains { column, otherValue in
            column != position.col && otherValue == value
        }
    }

    private func hasColumnConflict(at position: GridPosition, value: Int) -> Bool {
        userGrid.enumerated().contains { row, rowValues in
            row != position.row && rowValues[position.col] == value
        }
    }

    private func hasCageConflict(at position: GridPosition) -> Bool {
        guard let cage = puzzle.cage(for: position) else { return false }
        return cage.evaluate(using: userGrid) == .violated
    }

    private func refreshSolvedState() {
        isSolved = puzzle.isSolved(by: userGrid)
    }
}
