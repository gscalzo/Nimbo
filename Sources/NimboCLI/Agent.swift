import Foundation
import SwiftOpenAI

final class Agent {
    private let client: OpenAIService
    private var history: [ChatCompletionParameters.Message]
    private let tools: [Tool]

    init(apiKey: String, system: String) {
        client = OpenAIServiceFactory.service(apiKey: apiKey)
        history = [.init(role: .system, content: .text(system))]
        tools = [ListFiles(), ReadFile()]
    }

    func respond(_ text: String) async -> String {
        history.append(.init(role: .user, content: .text(text)))
        do {
            let maxToolIterations = 8
            var iteration = 0

            while iteration < maxToolIterations {
                let params = ChatCompletionParameters(
                    messages: history,
                    model: .gpt5Mini,
                    toolChoice: .auto,
                    tools: tools.map { $0.chatTool }
                )

                let response = try await client.startChat(parameters: params)
                guard let message = response.choices?.first?.message else {
                    return "<error> Empty response from model."
                }

                let textContent = message.content ?? ""
                let assistantMessage = ChatCompletionParameters.Message(
                    role: .assistant,
                    content: .text(textContent),
                    toolCalls: message.toolCalls
                )
                history.append(assistantMessage)

                if let calls = message.toolCalls, !calls.isEmpty {
                    iteration += 1
                    for call in calls {
                        let toolMsg = perform(call)
                        history.append(toolMsg)
                    }
                    continue
                }

                return textContent
            }

            return "<error> Exceeded maximum tool iterations."
        } catch {
            return "<error> \(error.localizedDescription)"
        }
    }

    private func perform(_ call: ToolCall) -> ChatCompletionParameters.Message {
        let id = call.id ?? UUID().uuidString
        let toolName = call.function.name ?? "<nil>"
        let rawArgs = call.function.arguments

        print("tool: \(toolName)(\(rawArgs))")

        let result = {
            if let tool = tools.first(where: { $0.name == toolName }) {
                return tool.exec(rawArgs.data(using: .utf8))
            } else {
                return "<error> Unknown tool: \(toolName)"
            }
        }()

        return .init(role: .tool, content: .text(result), toolCallID: id)
    }
}
