import Foundation
import SwiftOpenAI

struct ReadFile: Tool {
    private static let toolName = "read_file"
    
    var name = ReadFile.toolName
    var chatTool: ChatCompletionParameters.Tool = {
        let objSchema = JSONSchema(
            type: .object,
            properties: ["path": JSONSchema(type: .string)],
        )
        let readFileFunction = ChatCompletionParameters.ChatFunction(
            name: ReadFile.toolName,
            strict: nil,
            description: """
                Read the contents of a given relative file path. 
                Use this when you want to see what's inside a file. 
                Do not use this with directory names.
                """,
            parameters: objSchema
        )
        return  .init(function: readFileFunction)
    }()
    
    var exec: (Data?) -> String = { input in
        guard let path = input.asPath(defaultPath: nil) else {
            return "<error> Invalid JSON arguments for read_file. Expected: {\"path\": \"...\"}"
        }
        return ReadFile.readFile(atPath: path)
    }
    
    private static func readFile(atPath path: String) -> String {
        do {
            let fileData = try Data(contentsOf: path.asURL)
            // Cap to 100 KB to avoid flooding the chat
            let capped = fileData.prefix(100_000)
            if let text = String(data: capped, encoding: .utf8) {
                return text
            } else {
                return "<error> File is not valid UTF-8 or is binary."
            }
        } catch {
            return "<error> Could not read file at path: \(path). Error: \(error.localizedDescription)"
        }
    }
}
