import Foundation

enum KenKenGenerator {
    static func makePuzzle(size: Int = 9) -> KenKenPuzzle {
        let solution = makeLatinSolution(size: size)
        let cages = createCages(from: solution)
        return KenKenPuzzle(size: size, solution: solution, cages: cages)
    }

    private static func makeLatinSolution(size: Int) -> [[Int]] {
        let base = (0..<size).map { row in
            (0..<size).map { column in ((row + column) % size) + 1 }
        }

        var rowOrder = Array(0..<size)
        var columnOrder = Array(0..<size)
        var valueOrder = Array(1...size)

        rowOrder.shuffle()
        columnOrder.shuffle()
        valueOrder.shuffle()

        let permutedRows = rowOrder.map { base[$0] }
        let permutedGrid = permutedRows.map { row in
            columnOrder.map { columnIndex in row[columnIndex] }
        }

        return permutedGrid.map { row in
            row.map { valueOrder[$0 - 1] }
        }
    }

    private static func createCages(from solution: [[Int]]) -> [KenKenCage] {
        let size = solution.count
        var available = Set((0..<size).flatMap { row in
            (0..<size).map { GridPosition(row: row, col: $0) }
        })

        var cages: [KenKenCage] = []

        while let start = available.randomElement() {
            available.remove(start)

            var cageCells: [GridPosition] = [start]
            var frontier = Set(neighbors(of: start, size: size).filter { available.contains($0) })

            let maxSize = min(4, 1 + frontier.count)
            let desiredSize: Int
            if frontier.isEmpty {
                desiredSize = 1
            } else {
                desiredSize = Int.random(in: 2...maxSize)
            }

            while cageCells.count < desiredSize, let next = frontier.randomElement() {
                frontier.remove(next)
                guard available.contains(next) else { continue }
                available.remove(next)
                cageCells.append(next)

                let newNeighbors = neighbors(of: next, size: size).filter { available.contains($0) }
                frontier.formUnion(newNeighbors)
            }

            let cage = makeCage(from: cageCells, solution: solution)
            cages.append(cage)
        }

        return mergeSingletonCagesIfNeeded(cages, solution: solution)
    }

    private static func makeCage(from cells: [GridPosition], solution: [[Int]]) -> KenKenCage {
        let values = cells.map { solution[$0.row][$0.col] }

        if cells.count == 1, let value = values.first {
            return KenKenCage(cells: cells, operation: .single, target: value)
        }

        if cells.count == 2 {
            let sorted = values.sorted()
            let sum = values.reduce(0, +)
            let product = values.reduce(1, *)
            let difference = sorted[1] - sorted[0]
            let quotient = sorted[0] != 0 && sorted[1] % sorted[0] == 0 ? sorted[1] / sorted[0] : nil

            var options: [(KenKenOperation, Int)] = []
            if let quotient { options.append((.division, quotient)) }
            if difference > 0 { options.append((.subtraction, difference)) }
            options.append((.multiplication, product))
            options.append((.addition, sum))

            let choice = options.randomElement() ?? (.addition, sum)
            return KenKenCage(cells: cells, operation: choice.0, target: choice.1)
        }

        let sum = values.reduce(0, +)
        let product = values.reduce(1, *)
        let useMultiplication = product <= 500 && Bool.random()
        let operation: KenKenOperation = useMultiplication ? .multiplication : .addition
        let target = useMultiplication ? product : sum

        return KenKenCage(cells: cells, operation: operation, target: target)
    }

    private static func neighbors(of position: GridPosition, size: Int) -> [GridPosition] {
        [
            position.neighbor(dRow: -1, dCol: 0, size: size),
            position.neighbor(dRow: 1, dCol: 0, size: size),
            position.neighbor(dRow: 0, dCol: -1, size: size),
            position.neighbor(dRow: 0, dCol: 1, size: size)
        ].compactMap { $0 }
    }

    private static func mergeSingletonCagesIfNeeded(_ cages: [KenKenCage], solution: [[Int]]) -> [KenKenCage] {
        guard cages.contains(where: { $0.cells.count == 1 }) else { return cages }

        var cages = cages
        let size = solution.count

        func rebuildIndexMap() -> [GridPosition: Int] {
            var map: [GridPosition: Int] = [:]
            for (idx, cage) in cages.enumerated() {
                for cell in cage.cells {
                    map[cell] = idx
                }
            }
            return map
        }

        var cellToCage = rebuildIndexMap()
        var index = 0

        while index < cages.count {
            let cage = cages[index]
            guard cage.cells.count == 1, let cell = cage.cells.first else {
                index += 1
                continue
            }

            let neighborCandidates: [(GridPosition, Int)] = neighbors(of: cell, size: size).compactMap { neighbor in
                guard let neighborIndex = cellToCage[neighbor], neighborIndex != index else { return nil }
                return (neighbor, neighborIndex)
            }

            guard let target = neighborCandidates.first(where: { cages[$0.1].cells.count < 4 }) ?? neighborCandidates.first else {
                index += 1
                continue
            }

            let neighborIndex = target.1

            var combinedCells = cages[neighborIndex].cells
            combinedCells.append(cell)
            cages[neighborIndex] = makeCage(from: combinedCells, solution: solution)
            cages.remove(at: index)
            cellToCage = rebuildIndexMap()
        }

        return cages
    }
}
