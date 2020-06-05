import Foundation
import PerfectMosquitto

struct Queue {
    static let synchronization: DispatchQueue = DispatchQueue(label: "com.sync", qos: .userInteractive)
    static let matrix: DispatchQueue = DispatchQueue(label: "com.matrix", qos: .userInteractive, attributes: .concurrent)
    static let processing: DispatchQueue = DispatchQueue(label: "com.matrix", qos: .background)
}

@propertyWrapper struct Synchronized<Value> {

    var queue: DispatchQueue = Queue.synchronization
    var value: Value
    
    var wrappedValue: Value {
        get {
            queue.sync {
                value
            }
        }
        set {
            queue.sync {
                value = newValue
            }
        }
    }

    init(wrappedValue: Value) {
        self.value = wrappedValue
    }
}

class SmartBax {

    let max: MAX7219SPI
    let adc: ADCSPI

    let matrixQueue: DispatchQueue
    let processingQueue: DispatchQueue

    var routine: Routine!

    var results: [Hit]
    @Synchronized var hitMarkIndex: Int
    @Synchronized var isFinished: Bool

    var currentHitMark: [UInt8] {
        routine.hitMarks[hitMarkIndex]
    }

    var mosquitto: Mosquitto

    init() {
        max = MAX7219SPI()
        adc = ADCSPI()
        matrixQueue = Queue.matrix
        processingQueue = Queue.processing

        results = []
        hitMarkIndex = 0
        isFinished = false

        Mosquitto.OpenLibrary()
        mosquitto = Mosquitto()
        
    }

    func run() throws {
        //TODO: Connect to broker
        //TODO: Subscribe to receive routine start, pause, stop, resume
        //TODO: Publish end of routine
        
        try mosquitto.connect(host: "smartbax.xyz", port: 1883)

        try mosquitto.start()

        mosquitto.OnMessage = { message in
            print(message.id)
            print(message.payload)
        }
        
        try mosquitto.subscribe(topic: "matpr")

        RunLoop.main.run()
    }

    deinit {
        do {
            try mosquitto.stop()
        } catch {
            print(error)
        }
        
        Mosquitto.CloseLibrary()
    }

    func startRoutine() {
        
        matrixQueue.async {
            self.startLedMatrix()
        }

        matrixQueue.async {
            self.startSensorMatrix()
        }

    }

    func pauseRoutine() {
        matrixQueue.suspend()
    }

    func resumeRoutine() {
        matrixQueue.resume()
    }

    func stopRoutine() {
        isFinished = true
        max.clearMatrix()
        sendResults()
    }

    func sendResults() {

    }

    func startLedMatrix() {
        guard hitMarkIndex < routine.hitMarks.count, isFinished else {
            stopRoutine()
            return
        }
        let delay = routine.hitTime
        max.write(hitMark: currentHitMark)
        hitMarkIndex += 1
        matrixQueue.asyncAfter(deadline: .now() + delay, execute: startLedMatrix)
    }

    func closeHit(_ hit: Hit) {
        let currentHitShape = HitShape(columns: currentHitMark)
        let intersection = hit.shape.intersection(currentHitShape)
        let accuracy = Double(intersection.pointCount()) / Double(hit.shape.pointCount()) * 100

        hit.timeStamp = Date()
        hit.accuracy = accuracy

        results.append(hit)
    }

    func startSensorMatrix() {

        var hits: [Hit] = []
        
        while !isFinished {

            for column in 0..<8 {
                for row in 0..<8 {

                    if isFinished { return }
                    
                    let coordinates = Coordinates(x: column, y: row)
                    let sensorValue = adc.readADC(row: row, column: column)

                    processingQueue.async {

                    for (i, hit) in hits.enumerated()  {
                        if let point = hit.points[coordinates] {
                            
                            if point.f1 { return }

                            if hit.force < sensorValue {
                                hit.force = sensorValue
                            }

                            if point.value < sensorValue {
                                
                                point.value = sensorValue
                                point.f1 = false
                            
                            } else if sensorValue < point.value / 2 {
                                
                                point.f1 = true
                                hit.closedPointCount += 1
                                if hit.closedPointCount >= hit.points.count {
                                    hits.remove(at: i)

                                    if self.isFinished { return }
                                    self.closeHit(hit)

                                }
                            }

                            return
                        } else if hit.shape.isAdjacentToPoint(at: coordinates) {
                            hit.addPoint(at: coordinates, value: sensorValue)
                            return
                        }
                    }
                    
                    let hit = Hit()
                    hit.addPoint(at: coordinates, value: sensorValue)
                    hits.append(hit)

                    }

                }
            }
        }
    }

}