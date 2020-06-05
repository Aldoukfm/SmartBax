import Foundation

struct Coordinates: Hashable {
    
    var x: Int
    var y: Int

    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    var row: UInt8 { UInt8(1 << 7 - x) }
    var column: UInt8 { UInt8(1 << 7 - y) }
    
    static func == (lhs: Coordinates, rhs: Coordinates) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}

class Hit {

    var shape: HitShape
    var points: [Coordinates: HitPointValue]
    var closedPointCount: Int
    var timeStamp: Date
    var accuracy: Double = 0
    var force: Double = 0

    init() {
        shape = HitShape()
        points = [:]
        closedPointCount = 0
        timeStamp = Date()
    }

    func addPoint(at coordinates: Coordinates, value: Double) {
        points[coordinates] = HitPointValue(value)
        shape.addPoint(at: coordinates)
    }
}

struct HitShape {

    var activeColumns: UInt8 = UInt8(0)
    var columns: [UInt8]

    init(columns: [UInt8]) {
        self.columns = columns
        for i in 0..<8 {
            if columns[i] > 0 {
                activeColumns |= 1 << (7 - i)
            }
        }
    }

    init() {
        columns = [UInt8](repeating: 0, count: 8)
    }

    func pointCount() -> Int {
        return columns.reduce(0, { $0 + $1.nonzeroBitCount })
    }

    func intersection(_ shape: HitShape) -> HitShape {
        HitShape(columns: zip(shape.columns, columns).map(&))
    }

    func isAdjacentToPoint(at coordinates: Coordinates) -> Bool {
        let activeColumn = coordinates.row
        let column = coordinates.column 

        let mask = column | column << 1 | column >> 1

        if activeColumns & activeColumn > 0 {
            return columns[coordinates.x] & mask > 0
        }

        if activeColumns & activeColumn << 1 > 0 {
            return columns[coordinates.x - 1] & mask > 0
        }

        if activeColumns & activeColumn >> 1 > 0 {
            return columns[coordinates.x + 1] & mask > 0
        }

        return false
    }

    mutating func addPoint(at coordinates: Coordinates) {
        activeColumns |= coordinates.row
        columns[coordinates.x] = columns[coordinates.x] | coordinates.column

    }

}

class HitPointValue {

    var value: Double
    var f1: Bool = false

    init(_ value: Double) {
        self.value = value
    }

}