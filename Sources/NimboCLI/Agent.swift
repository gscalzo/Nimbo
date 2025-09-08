import Foundation
import SwiftOpenAI

final class Agent {
    private let client: OpenAIService
    private var history: [ChatCompletionParameters.Message]

    init(apiKey: String, system: String) {
        client = OpenAIServiceFactory.service(apiKey: apiKey)
        history = [.init(role: .system, content: .text(system))]
    }

    func respond(_ text: String) -> String {
        history.append(.init(role: .user, content: .text(text)))
        var output = ""
        let g = DispatchGroup(); g.enter()
        Task {
            let params = ChatCompletionParameters(messages: history, model: .gpt4omini)
            let r = try! await client.startChat(parameters: params)
            output = r.choices?.first?.message?.content ?? ""
            history.append(.init(role: .assistant, content: .text(output)))
            g.leave()
        }
        g.wait()
        return output
    }
}
