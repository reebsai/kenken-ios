import Foundation

/// Generates KenKen puzzles backed by a Latin square solution.
/// For v1 we support:
/// - 9x9 default size
/// - Cages composed of +, −, ×, ÷, or single-cell targets
/// - Optional deterministic mode for debugging (seeded RNG)
enum KenKenGenerator {

    /// Create a puzzle.
    /// - Parameters:
    ///   - size: Grid size (default 9).
    ///   - seed: Optional seed for deterministic generation (for debugging / snapshots).
    static func makePuzzle(size: Int = 9, seed: UInt64? = nil) -> KenKenPuzzle {
        var rng = seed.map(SeededGenerator.init(seed:)) // deterministic if seed provided
        let solution = makeLatinSolution(size: size, rng: &rng)
        let cages = createCages(from: solution, rng: &rng)
        return KenKenPuzzle(size: size, solution: solution, cages: cages)
    }

    /// Build a Latin square by permuting a simple base pattern.
    /// If rng is provided, shuffles are deterministic.
    private static func makeLatinSolution<R: RandomNumberGenerator>(size: Int, rng: inout R?) -> [[Int]] {
        let base = (0..<size).map { row in
            (0..<size).map { column in ((row + column) % size) + 1 }
        }

        var rowOrder = Array(0..<size)
        var columnOrder = Array(0..<size)
        var valueOrder = Array(1...size)

        if var seeded = rng {
            rowOrder.shuffle(using: &seeded)
            columnOrder.shuffle(using: &seeded)
            valueOrder.shuffle(using: &seeded)
            rng = seeded
        } else {
            rowOrder.shuffle()
            columnOrder.shuffle()
            valueOrder.shuffle()
        }

        let permutedRows = rowOrder.map { base[$0] }
        let permutedGrid = permutedRows.map { row in
            columnOrder.map { columnIndex in row[columnIndex] }
        }

        return permutedGrid.map { row in
            row.map { valueOrder[$0 - 1] }
        }
    }

    /// Create contiguous cages over the solution grid.
    /// If rng is provided, cage layout and operation choices are deterministic.
    private static func createCages<R: RandomNumberGenerator>(from solution: [[Int]], rng: inout R?) -> [KenKenCage] {
        let size = solution.count
        var available = Set((0..<size).flatMap { row in
            (0..<size).map { GridPosition(row: row, col: $0) }
        })

        var cages: [KenKenCage] = []

        func randomElement<T>(_ array: [T]) -> T? {
            if var seeded = rng {
                let idx = Int.random(in: 0..<array.count, using: &seeded)
                rng = seeded
                return array[idx]
            }
            return array.randomElement()
        }

        while let start = randomElement(Array(available)) {
            available.remove(start)

            var cageCells: [GridPosition] = [start]
            var frontier = Set(neighbors(of: start, size: size).filter { available.contains($0) })

            // Prefer 2-3 cell cages, max 4.
            let maxSize = min(4, 1 + frontier.count)
            let desiredSize: Int
            if frontier.isEmpty {
                desiredSize = 1
            } else {
                let options = Array(2...maxSize)
                desiredSize = randomElement(options) ?? maxSize
            }

            while cageCells.count < desiredSize, let next = randomElement(Array(frontier)) {
                frontier.remove(next)
                guard available.contains(next) else { continue }
                available.remove(next)
                cageCells.append(next)

                let newNeighbors = neighbors(of: next, size: size).filter { available.contains($0) }
                frontier.formUnion(newNeighbors)
            }

            let cage = makeCage(from: cageCells, solution: solution, rng: &rng)
            cages.append(cage)
        }

        let merged = mergeSingletonCagesIfNeeded(cages, solution: solution, rng: &rng)
        return merged
    }

    /// Choose operation and target for a cage.
    /// Restricts to KenKenOperation set and keeps values reasonable.
    private static func makeCage<R: RandomNumberGenerator>(from cells: [GridPosition], solution: [[Int]], rng: inout R?) -> KenKenCage {
        let values = cells.map { solution[$0.row][$0.col] }

        if cells.count == 1, let value = values.first {
            return KenKenCage(cells: cells, operation: .single, target: value)
        }

        func randomChoice<T>(_ options: [T]) -> T? {
            guard !options.isEmpty else { return nil }
            if var seeded = rng {
                let idx = Int.random(in: 0..<options.count, using: &seeded)
                rng = seeded
                return options[idx]
            }
            return options.randomElement()
        }

        if cells.count == 2 {
            let sorted = values.sorted()
            let sum = values.reduce(0, +)
            let product = values.reduce(1, *)
            let difference = sorted[1] - sorted[0]
            let quotient = sorted[0] != 0 && sorted[1] % sorted[0] == 0 ? sorted[1] / sorted[0] : nil

            var options: [(KenKenOperation, Int)] = []
            if let quotient, quotient > 1 {
                options.append((.division, quotient))
            }
            if difference > 0 {
                options.append((.subtraction, difference))
            }
            options.append((.multiplication, product))
            options.append((.addition, sum))

            let choice = randomChoice(options) ?? (.addition, sum)
            return KenKenCage(cells: cells, operation: choice.0, target: choice.1)
        }

        // 3-4 cell cages: prefer +, sometimes × if not exploding.
        let sum = values.reduce(0, +)
        let product = values.reduce(1, *)
        let canUseMultiplication = product <= 500
        let useMultiplication: Bool
        if canUseMultiplication {
            if var seeded = rng {
                useMultiplication = Bool.random(using: &seeded)
                rng = seeded
            } else {
                useMultiplication = Bool.random()
            }
        } else {
            useMultiplication = false
        }

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

    /// Merge singleton cages into neighboring cages when possible.
    /// Ensures resulting cages stay contiguous and reasonably sized.
    private static func mergeSingletonCagesIfNeeded<R: RandomNumberGenerator>(_ cages: [KenKenCage], solution: [[Int]], rng: inout R?) -> [KenKenCage] {
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

        func randomChoice<T>(_ array: [T]) -> T? {
            guard !array.isEmpty else { return nil }
            if var seeded = rng {
                let idx = Int.random(in: 0..<array.count, using: &seeded)
                rng = seeded
                return array[idx]
            }
            return array.randomElement()
        }

        var cellToCage = rebuildIndexMap()
        var index = 0

        while index < cages.count {
            let cage = cages[index]
            guard cage.cells.count == 1, let cell = cage.cells.first else {
                index += 1
                continue
            }

            // Candidate neighbors: adjacent cages that won't exceed size 4 after merge.
            let neighborCandidates: [(GridPosition, Int)] = neighbors(of: cell, size: size).compactMap { neighbor in
                guard let neighborIndex = cellToCage[neighbor], neighborIndex != index else { return nil }
                return (neighbor, neighborIndex)
            }

            let preferred = neighborCandidates.filter { cages[$0.1].cells.count < 4 }
            guard let target = randomChoice(preferred.isEmpty ? neighborCandidates : preferred) else {
                index += 1
                continue
            }

            let neighborIndex = target.1
            var combinedCells = cages[neighborIndex].cells
            combinedCells.append(cell)

            // Rebuild cage with new operation/target, keeping contiguity due to adjacency choice.
            cages[neighborIndex] = makeCage(from: combinedCells, solution: solution, rng: &rng)
            cages.remove(at: index)
            cellToCage = rebuildIndexMap()
        }

        return cages
    }
}

/// Simple deterministic RNG for debug builds.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid zero state
        self.state = seed == 0 ? 0xBAD_CAFE : seed
    }

    mutating func next() -> UInt64 {
        // xorshift64*
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        return state &* 2685821657736338717
    }
}
