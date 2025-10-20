import Foundation
import SwiftOpenAI

final class Agent {
    private let client: OpenAIService
    private var history: [ChatCompletionParameters.Message]
    private let tools: [ChatCompletionParameters.Tool]

    init(apiKey: String, system: String) {
        client = OpenAIServiceFactory.service(apiKey: apiKey)
        history = [.init(role: .system, content: .text(system))]
        tools = Agent.buildTools()
    }

    func respond(_ text: String) -> String {
        history.append(.init(role: .user, content: .text(text)))
        var output = ""
        let g = DispatchGroup(); g.enter()
        Task {
            do {
                // Tool loop: up to 3 iterations to resolve tool calls
                var iteration = 0
                while iteration < 3 {
                    iteration += 1
                    let params = ChatCompletionParameters(
                        messages: history,
                        model: .gpt4omini,
                        toolChoice: .auto,
                        tools: tools
                    )
                    let r = try await client.startChat(parameters: params)
                    guard let msg = r.choices?.first?.message else {
                        output = "<error> Empty response from model."
                        break
                    }

                    if let calls = msg.toolCalls, !calls.isEmpty {
                        let assistantToolMessage = ChatCompletionParameters.Message(
                            role: .assistant,
                            content: .text(msg.content ?? ""),
                            toolCalls: calls
                        )
                        history.append(assistantToolMessage)
                        for call in calls {
                            let toolMsg = Agent.performToolCall(call)
                            history.append(toolMsg)
                        }
                        // Continue to next iteration so the model can see tool results
                        continue
                    }

                    output = msg.content ?? ""
                    if !output.isEmpty {
                        history.append(.init(role: .assistant, content: .text(output)))
                    }
                    break
                }
            } catch {
                output = "<error> \(error.localizedDescription)"
            }
            g.leave()
        }
        g.wait()
        return output
    }

    // MARK: Tools
    private static func buildTools() -> [ChatCompletionParameters.Tool] {
        let pathSchema = JSONSchema(
            type: .string,
            description: "Path to a UTF-8 text file relative to the workspace root."
        )
        let objSchema = JSONSchema(
            type: .object,
            description: "Read a UTF-8 text file from the local workspace and return its contents.",
            properties: ["path": pathSchema],
            items: nil,
            required: ["path"],
            additionalProperties: false
        )
        let readFileFunction = ChatCompletionParameters.ChatFunction(
            name: "read_file",
            strict: nil,
            description: "Read a local text file from the workspace.",
            parameters: objSchema
        )
        return [ .init(function: readFileFunction) ]
    }

    private struct ReadFileArgs: Decodable { let path: String }

    private static func performToolCall(_ call: ToolCall) -> ChatCompletionParameters.Message {
        let id = call.id ?? UUID().uuidString
        var result = ""
        let toolName = call.function.name ?? "<nil>"
        let rawArgs = call.function.arguments
        // Show tool usage in the CLI
        print("tool: \(toolName)(\(rawArgs))")
        if toolName == "read_file" {
            if let data = call.function.arguments.data(using: .utf8),
               let args = try? JSONDecoder().decode(ReadFileArgs.self, from: data) {
                let path = args.path
                let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                let fileURL: URL
                if path.hasPrefix("/") || path.hasPrefix("~") {
                    fileURL = URL(fileURLWithPath: NSString(string: path).expandingTildeInPath)
                } else {
                    fileURL = cwd.appendingPathComponent(path)
                }
                do {
                    let fileData = try Data(contentsOf: fileURL)
                    // Cap to 100 KB to avoid flooding the chat
                    let capped = fileData.prefix(100_000)
                    if let text = String(data: capped, encoding: .utf8) {
                        result = text
                    } else {
                        result = "<error> File is not valid UTF-8 or is binary."
                    }
                } catch {
                    result = "<error> Could not read file at path: \(path). Error: \(error.localizedDescription)"
                }
            } else {
                result = "<error> Invalid JSON arguments for read_file. Expected: {\"path\": \"...\"}"
            }
        } else {
            result = "<error> Unknown tool: \(toolName)"
        }

        return .init(role: .tool, content: .text(result), toolCallID: id)
    }
}
