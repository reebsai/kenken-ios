import SwiftUI

struct KenKenGridView: View {
    let puzzle: KenKenPuzzle
    let userGrid: [[Int?]]
    let cellStateProvider: (GridPosition) -> KenKenGameViewModel.CellState
    let cageEvaluationProvider: (KenKenCage) -> KenKenCage.Evaluation
    let onSelect: (GridPosition) -> Void

    struct Direction: OptionSet, Hashable {
        let rawValue: Int

        static let top = Direction(rawValue: 1 << 0)
        static let right = Direction(rawValue: 1 << 1)
        static let bottom = Direction(rawValue: 1 << 2)
        static let left = Direction(rawValue: 1 << 3)
    }

    var body: some View {
        GeometryReader { proxy in
            let gridSize = min(proxy.size.width, proxy.size.height)
            let cellSize = gridSize / CGFloat(puzzle.size)
            let columns = Array(repeating: GridItem(.fixed(cellSize), spacing: 0), count: puzzle.size)

            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(0..<puzzle.size, id: \.self) { row in
                    ForEach(0..<puzzle.size, id: \.self) { column in
                        let position = GridPosition(row: row, col: column)
                        let cage = puzzle.cage(for: position)
                        let cellState = cellStateProvider(position)
                        let cageEvaluation = cage.map(cageEvaluationProvider) ?? .incomplete

                        CellView(
                            cellState: cellState,
                            cage: cage,
                            cageEvaluation: cageEvaluation,
                            value: userGrid[row][column],
                            isHeader: puzzle.isHeader(position),
                            borders: borderDirections(for: position, cage: cage)
                        )
                        .frame(width: cellSize, height: cellSize)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelect(position)
                        }
                    }
                }
            }
            .frame(width: gridSize, height: gridSize, alignment: .topLeading)
        }
    }

    private func borderDirections(for position: GridPosition, cage: KenKenCage?) -> [Direction: CGFloat] {
        var map: [Direction: CGFloat] = [:]

        let size = puzzle.size
        let directions: [(Direction, Int, Int)] = [
            (.top, -1, 0),
            (.right, 0, 1),
            (.bottom, 1, 0),
            (.left, 0, -1)
        ]

        for (dir, dRow, dCol) in directions {
            let neighbor = position.neighbor(dRow: dRow, dCol: dCol, size: size)

            guard let neighbor else {
                map[dir] = 3
                continue
            }

            guard let cage, let neighborCage = puzzle.cage(for: neighbor) else {
                map[dir] = 2.5
                continue
            }

            map[dir] = cage.id == neighborCage.id ? 0.8 : 2.5
        }

        return map
    }
}

private struct CellView: View {
    let cellState: KenKenGameViewModel.CellState
    let cage: KenKenCage?
    let cageEvaluation: KenKenCage.Evaluation
    let value: Int?
    let isHeader: Bool
    let borders: [KenKenGridView.Direction: CGFloat]

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor)

            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(cellOutlineColor, lineWidth: 1)

            if let cage, isHeader {
                VStack(alignment: .leading, spacing: 2) {
                    Text(headerText(for: cage))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(headerColor)
                        .padding(.top, 6)
                        .padding(.leading, 6)

                    Spacer()
                }
            }

            if let value {
                Text("\(value)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(valueColor)
            }
        }
        .overlay(alignment: .topLeading) {
            if let top = borders[.top] {
                Rectangle()
                    .frame(height: top)
                    .foregroundStyle(cageBorderColor(for: top))
                    .offset(y: -0.5)
            }
        }
        .overlay(alignment: .bottomLeading) {
            if let bottom = borders[.bottom] {
                Rectangle()
                    .frame(height: bottom)
                    .foregroundStyle(cageBorderColor(for: bottom))
                    .offset(y: 0.5)
            }
        }
        .overlay(alignment: .topLeading) {
            if let left = borders[.left] {
                Rectangle()
                    .frame(width: left)
                    .foregroundStyle(cageBorderColor(for: left))
                    .offset(x: -0.5)
            }
        }
        .overlay(alignment: .topTrailing) {
            if let right = borders[.right] {
                Rectangle()
                    .frame(width: right)
                    .foregroundStyle(cageBorderColor(for: right))
                    .offset(x: 0.5)
            }
        }
        .padding(1.5)
    }

    private var backgroundColor: Color {
        switch cellState {
        case .selected:
            return Color.accentColor.opacity(0.2)
        case .conflict:
            return Color.red.opacity(0.2)
        case .correct:
            return Color.green.opacity(0.18)
        case .filled:
            return Color.white.opacity(0.2)
        case .empty:
            return Color.white.opacity(0.08)
        }
    }

    private var cellOutlineColor: Color {
        switch cellState {
        case .selected:
            return Color.accentColor.opacity(0.6)
        case .conflict:
            return Color.red.opacity(0.6)
        case .correct:
            return Color.green.opacity(0.6)
        default:
            return Color.white.opacity(0.25)
        }
    }

    private var valueColor: Color {
        cellState == .conflict ? .red : .white
    }

    private var headerColor: Color {
        switch cageEvaluation {
        case .satisfied:
            return .green
        case .violated:
            return .red
        case .incomplete:
            return Color.white
        }
    }

    private func headerText(for cage: KenKenCage) -> String {
        if cage.operation == .single {
            return "\(cage.target)"
        }
        return "\(cage.target)\(cage.operation.symbol)"
    }

    private func cageBorderColor(for thickness: CGFloat) -> Color {
        thickness >= 2.5 ? Color.white.opacity(0.85) : Color.white.opacity(0.4)
    }
}
