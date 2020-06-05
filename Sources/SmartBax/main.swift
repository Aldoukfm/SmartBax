import Foundation

let smartBax = SmartBax()

do {
    try smartBax.run()
} catch {
    print("Error starting smartbax")
}