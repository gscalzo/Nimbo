import Foundation
import Darwin
import Dispatch

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

private func apiKey() throws -> String {
    if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"].flatMap({ $0.isEmpty ? nil : $0 }) {
        return key
    }
    throw NSError(domain: "NimboCLI", code: 1, userInfo: [NSLocalizedDescriptionKey: "OPENAI_API_KEY not set"])
}

private func runLoop() async {
    print("\nChat with Nimbo (use 'ctrl-c' to quit)\n")

    guard let apiKey = try? apiKey() else {
        fputs("Missing or empty OPENAI_API_KEY.\n", stderr)
        return
    }

    let agent = Agent(apiKey: apiKey, system: "You are Nimbo, a concise CLI assistant.")

    while let line = input() {
        if line.isEmpty { continue }
        let answer = await agent.respond(line)
        print("\(display("Nimbo", in: .green)): \(answer)")
    }
}

Task {
    await runLoop()
    exit(EXIT_SUCCESS)
}

dispatchMain()
