import Foundation
import SwiftUI

@MainActor
final class KenKenGameViewModel: ObservableObject {
    @Published private(set) var puzzle: KenKenPuzzle
    @Published var userGrid: [[Int?]]
    @Published var selectedPosition: GridPosition?
    @Published private(set) var isSolved: Bool = false

    init(size: Int, seed: UInt64? = nil) {
        let clampedSize = min(max(size, 4), 9)
        // Allow deterministic puzzles when a seed is provided (debugging / snapshots).
        let puzzle = KenKenGenerator.makePuzzle(size: clampedSize, seed: seed)
        self.puzzle = puzzle
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
        // If a seed is provided, generation is deterministic; otherwise remains random.
        let currentSize = min(max(puzzle.size, 4), 9)
        let puzzle = KenKenGenerator.makePuzzle(size: currentSize, seed: seed)
        self.puzzle = puzzle
        self.userGrid = Array(repeating: Array(repeating: nil, count: puzzle.size), count: puzzle.size)
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
        isSolved = zip(userGrid, puzzle.solution).allSatisfy { userRow, solutionRow in
            zip(userRow, solutionRow).allSatisfy { entry, target in
                guard let value = entry else { return false }
                return value == target
            }
        }
    }
}
