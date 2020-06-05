import Foundation
import SwiftyGPIO

class MAX7219SPI {

    private var spi: VirtualSPI

    init() {
        let gpios = SwiftyGPIO.GPIOs(for: .RaspberryPi3)
        let cs = gpios[.P27]!
        let mosi = gpios[.P22]!
        let miso = gpios[.P4]!
        let clk = gpios[.P17]!
        let spi = VirtualSPI.init(mosiGPIO: mosi, misoGPIO: miso, clockGPIO: clk, csGPIO: cs)
        usleep(100)
        self.spi = spi
    }

    func write(column: Int, value: UInt8) {
        spi.sendData([UInt8(column), value])
        usleep(100)
    }

    func write(hitMark: [UInt8]) {
        for (column, value) in hitMark.enumerated() {
            write(column: column, value: value)
        }
    }

    func clearMatrix() {
        for i in 0..<8 {
           write(column: i, value: 0) 
        }
    }

}