import Foundation
import SwiftOpenAI

final class Agent {
    private let client: OpenAIService
    private var history: [ChatCompletionParameters.Message]
    private let tools: [Tool]

    init(apiKey: String, system: String) {
        client = OpenAIServiceFactory.service(apiKey: apiKey)
        history = [.init(role: .system, content: .text(system))]
        tools = [ReadFile()]
    }

    func respond(_ text: String) async -> String {
        history.append(.init(role: .user, content: .text(text)))
        do {
            // Single-pass tool flow: allow one tool invocation followed by a follow-up response.
            let initialParams = ChatCompletionParameters(
                messages: history,
                model: .gpt4omini,
                toolChoice: .auto,
                tools: tools.map { $0.chatTool }
            )
            let initialResponse = try await client.startChat(parameters: initialParams)
            guard let initialMessage = initialResponse.choices?.first?.message else {
                return "<error> Empty response from model."
            }

            if let calls = initialMessage.toolCalls, !calls.isEmpty {
                let assistantToolMessage = ChatCompletionParameters.Message(
                    role: .assistant,
                    content: .text(initialMessage.content ?? ""),
                    toolCalls: calls
                )
                history.append(assistantToolMessage)

                for call in calls {
                    let toolMsg = perform(call)
                    history.append(toolMsg)
                }

                let followUpParams = ChatCompletionParameters(
                    messages: history,
                    model: .gpt4omini,
                    toolChoice: ToolChoice.none,
                    tools: tools.map { $0.chatTool }
                )
                let followUpResponse = try await client.startChat(parameters: followUpParams)
                guard let followUpMessage = followUpResponse.choices?.first?.message else {
                    return "<error> Empty follow-up response from model."
                }

                if let extraCalls = followUpMessage.toolCalls, !extraCalls.isEmpty {
                    return "<error> Model requested additional tool calls in single-pass mode."
                }

                let reply = followUpMessage.content ?? ""
                if !reply.isEmpty {
                    history.append(.init(role: .assistant, content: .text(reply)))
                }
                return reply
            } else {
                let reply = initialMessage.content ?? ""
                if !reply.isEmpty {
                    history.append(.init(role: .assistant, content: .text(reply)))
                }
                return reply
            }
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
