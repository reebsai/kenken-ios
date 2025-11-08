import XCTest
@testable import KenKenApp

final class KenKenAppTests: XCTestCase {
    func testGeneratorProducesLatinSquare() {
        let puzzle = KenKenGenerator.makePuzzle(size: 9)
        XCTAssertEqual(puzzle.solution.count, 9)
        for row in puzzle.solution {
            XCTAssertEqual(Set(row).count, 9)
        }
        for column in 0..<9 {
            let columnValues = puzzle.solution.map { $0[column] }
            XCTAssertEqual(Set(columnValues).count, 9)
        }
    }

    func testCageEvaluationPositive() {
        let puzzle = KenKenGenerator.makePuzzle(size: 4)
        guard let cage = puzzle.cages.first, let position = cage.cells.first else {
            XCTFail("No cages available")
            return
        }

        var inputs = Array(repeating: Array(repeating: Optional<Int>.none, count: puzzle.size), count: puzzle.size)
        for cell in cage.cells {
            inputs[cell.row][cell.col] = puzzle.solution[cell.row][cell.col]
        }

        XCTAssertEqual(cage.evaluate(using: inputs), .satisfied)

        if case .single = cage.operation {
            inputs[position.row][position.col] = puzzle.solution[position.row][position.col] + 1
        } else {
            inputs[position.row][position.col] = 0
        }

        let evaluation = cage.evaluate(using: inputs)
        XCTAssertNotEqual(evaluation, .satisfied)
    }
}
