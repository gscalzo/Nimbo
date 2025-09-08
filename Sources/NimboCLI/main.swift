import Foundation
import Darwin

private enum AnsiColor: String {
    case reset = "\u{001B}[0m"
    case blue  = "\u{001B}[34m"
    case green = "\u{001B}[32m"
}

private func display(_ text: String, in color: AnsiColor) -> String {
    return "\(color.rawValue)\(text)\(AnsiColor.reset.rawValue)"
}

@discardableResult
private func input() -> String? {
    print("\(display("You", in: .blue)): ", terminator: "")  
    fflush(stdout)
    return readLine()?.trimmingCharacters(in: .whitespacesAndNewlines)
}

private func runLoop() {
    print("\nChat with Nimbo (use 'ctrl-c' to quit)\n")

    while let line = input() {
        let input = line

        print("\(display("Nimbo", in: .green)): \(input)")
    }
}

runLoop()

