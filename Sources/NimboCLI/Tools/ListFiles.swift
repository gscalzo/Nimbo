import Foundation
import SwiftOpenAI

struct ListFiles: Tool {
    private static let toolName = "list_files"
    private static let entryLimit = 200
    private static let defaultPath = "."

    var name = ListFiles.toolName

    var chatTool: ChatCompletionParameters.Tool = {
        let objSchema = JSONSchema(
            type: .object,
            properties: ["path": JSONSchema(type: .string)]
        )
        let function = ChatCompletionParameters.ChatFunction(
            name: ListFiles.toolName,
            strict: nil,
            description: """
                List files and directories at a given relative path. \
                Use this when you need to inspect the project structure. \
                Defaults to the current working directory when no path is supplied.
                """,
            parameters: objSchema
        )
        return .init(function: function)
    }()

    var exec: (Data?) -> String = { input in
        guard let path = input.asPath(defaultPath: defaultPath) else {
            return "<error> Invalid JSON arguments for list_files. Expected: {\"path\": \"...\"}"
        }
        return ListFiles.listDirectory(atPath: path.asURL)
    }

    private static func listDirectory(atPath pathURL: URL) -> String {
        guard pathURL.exists else {
            return "<error> Path not found: \(pathURL.path)"
        }

        if !pathURL.isDirectory {
            return "file \(pathURL.path)"
        }

        var lines = ["directory \(pathURL.path)"]

        do {
            let contents = try pathURL.contentsOfDirectory()

            guard !contents.isEmpty else {
                lines.append("<empty>")
                return lines.joined(separator: "\n")
            }

            let sorted = contents.sorted {
                $0.lastPathComponent.localizedCompare($1.lastPathComponent) == .orderedAscending
            }
            let displayedEntries = sorted.prefix(entryLimit)

            lines.append(contentsOf: displayedEntries.map { $0.formatted() })

            if sorted.count > entryLimit {
                lines.append("… \(sorted.count - entryLimit) more")
            }

            return lines.joined(separator: "\n")
        } catch {
            return "<error> Could not list path \(pathURL.path). Error: \(error.localizedDescription)"
        }
    }
}


