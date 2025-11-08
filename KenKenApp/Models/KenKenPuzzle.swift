import Foundation

struct GridPosition: Hashable {
    let row: Int
    let col: Int

    func neighbor(dRow: Int, dCol: Int, size: Int) -> GridPosition? {
        let newRow = row + dRow
        let newCol = col + dCol
        guard (0..<size).contains(newRow), (0..<size).contains(newCol) else { return nil }
        return GridPosition(row: newRow, col: newCol)
    }
}

enum KenKenOperation: CaseIterable {
    case addition
    case subtraction
    case multiplication
    case division
    case single

    var symbol: String {
        switch self {
        case .addition:
            return "+"
        case .subtraction:
            return "−"
        case .multiplication:
            return "×"
        case .division:
            return "÷"
        case .single:
            return ""
        }
    }
}

struct KenKenCage: Identifiable, Hashable {
    let id = UUID()
    let cells: [GridPosition]
    let operation: KenKenOperation
    let target: Int

    var header: GridPosition {
        cells.min { lhs, rhs in
            if lhs.row == rhs.row {
                return lhs.col < rhs.col
            }
            return lhs.row < rhs.row
        } ?? cells[0]
    }

    func contains(_ position: GridPosition) -> Bool {
        cells.contains(position)
    }

    enum Evaluation {
        case incomplete
        case satisfied
        case violated
    }

    func evaluate(using inputs: [[Int?]]) -> Evaluation {
        let values = cells.compactMap { inputs[$0.row][$0.col] }
        guard values.count == cells.count else { return .incomplete }

        switch operation {
        case .single:
            return values.first == target ? .satisfied : .violated
        case .addition:
            return values.reduce(0, +) == target ? .satisfied : .violated
        case .multiplication:
            return values.reduce(1, *) == target ? .satisfied : .violated
        case .subtraction:
            guard values.count == 2 else { return .violated }
            let sorted = values.sorted()
            return sorted[1] - sorted[0] == target ? .satisfied : .violated
        case .division:
            guard values.count == 2 else { return .violated }
            let sorted = values.sorted()
            guard sorted[0] != 0, sorted[1] % sorted[0] == 0 else { return .violated }
            return sorted[1] / sorted[0] == target ? .satisfied : .violated
        }
    }
}

struct KenKenPuzzle {
    let size: Int
    let solution: [[Int]]
    let cages: [KenKenCage]

    private let cageIndexByCell: [GridPosition: Int]

    init(size: Int, solution: [[Int]], cages: [KenKenCage]) {
        self.size = size
        self.solution = solution
        self.cages = cages
        self.cageIndexByCell = Dictionary(uniqueKeysWithValues: cages.enumerated().flatMap { index, cage in
            cage.cells.map { ($0, index) }
        })
    }

    func cage(for position: GridPosition) -> KenKenCage? {
        guard let index = cageIndexByCell[position] else { return nil }
        return cages[index]
    }

    func isHeader(_ position: GridPosition) -> Bool {
        guard let cage = cage(for: position) else { return false }
        return cage.header == position
    }
}
