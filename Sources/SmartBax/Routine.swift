import Foundation

struct Routine {
    let hitMarks: [[UInt8]] = []
    let hitTime: TimeInterval = 0
}

struct RoutineResults {
    var hits: [Hit] = []
    var start: Date!
    var end: Date!
}