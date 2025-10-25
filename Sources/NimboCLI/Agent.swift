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
            for _ in 0..<Agent.maxToolIterations {
                let response = try await requestCompletion()
                let assistantMessage = try firstAssistantMessage(from: response)
                appendAssistantMessage(assistantMessage)

                if let calls = assistantMessage.toolCalls, !calls.isEmpty {
                    executeToolCalls(calls)
                    continue
                }

                return assistantMessage.content ?? ""
            }

            throw AgentError.toolIterationLimitReached
        } catch let error as AgentError {
            return error.readableMessage
        } catch {
            return "<error> \(error.localizedDescription)"
        }
    }

    private static let maxToolIterations = 8

    private func requestCompletion() async throws -> ChatCompletionObject {
        let params = ChatCompletionParameters(
            messages: history,
            model: .gpt5Mini,
            toolChoice: .auto,
            tools: tools.map { $0.chatTool }
        )
        return try await client.startChat(parameters: params)
    }

    private func firstAssistantMessage(from response: ChatCompletionObject) throws -> ChatCompletionObject.ChatChoice.ChatMessage {
        guard let message = response.choices?.first?.message else {
            throw AgentError.missingAssistantMessage
        }
        return message
    }

    private func appendAssistantMessage(_ message: ChatCompletionObject.ChatChoice.ChatMessage) {
        let textContent = message.content ?? ""
        history.append(.init(role: .assistant, content: .text(textContent), toolCalls: message.toolCalls))
    }

    private func executeToolCalls(_ calls: [ToolCall]) {
        for call in calls {
            let toolMessage = perform(call)
            history.append(toolMessage)
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

    private enum AgentError: Error {
        case missingAssistantMessage
        case toolIterationLimitReached

        var readableMessage: String {
            switch self {
            case .missingAssistantMessage:
                return "<error> Empty response from model."
            case .toolIterationLimitReached:
                return "<error> Exceeded maximum tool iterations."
            }
        }
    }
}
