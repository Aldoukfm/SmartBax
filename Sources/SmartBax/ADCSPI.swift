import Foundation
import SwiftyGPIO

class ADCSPI {

    private var arduino_spi: SysFSSPI
    private var shift_spi: SysFSSPI

    init() {
        let spis = SwiftyGPIO.hardwareSPIs(for: .RaspberryPi3) as! [SysFSSPI]
        let arduino_spi = spis[0]
        let shift_spi = spis[1]
        usleep(100)
        self.shift_spi = shift_spi
        self.arduino_spi = arduino_spi
    }

    @discardableResult
    func transfer(byte: UInt8) -> Character {
        let res = arduino_spi.sendDataAndRead([byte])
        usleep(100)
        return res.toString().first!
    }

    @discardableResult
    func transfer(char: Character) -> Character {
        let byte = UInt8(char: char)
        return transfer(byte: byte)
    }

    func readBytes(count: Int) -> [UInt8] {
        let tx: [UInt8] = Array(repeating: UInt8(char: "r"), count: count)
        let res = arduino_spi.sendDataAndRead(tx)
        usleep(100)
        return res
    }

    func write(column: Int) {
        shift_spi.sendData([UInt8(1 << column)])
        usleep(100)
    }

    func readADC(row: Int, column: Int) -> Double {
        if transfer(char: "s") != "1" {
            print("device not ready")
            return -1 
        }

        write(column: column)
        
        if transfer(byte: UInt8(row)) != "a" {
            print("device not acknowledge")
            return -1
        }
        usleep(1000) //Wait for arduino to read ADC

        let rawValue = readBytes(count: 2)
        let value = Double(rawValue.join()) //TODO: Convert 0-1023 to force
        return value
    }

}

extension Array where Element == UInt8 {
    func join() -> Int {
        self.reduce(0, { accumulator, byte in 
            accumulator << 8 | Int(byte)
        })
    }
    func toString() -> String {
        String(data: Data(self), encoding: .utf8)!
    }
}

extension UInt8 {
    init(char: Character) {
        self.init(char.utf8.first!)
    }
}