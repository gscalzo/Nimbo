import Foundation
import SwiftOpenAI

struct ListFiles: Tool {
    private struct ListFilesArgs: Decodable {
        let path: String?
    }

    private static let toolName = "list_files"
    private static let entryLimit = 200

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
        let requestedPath: String
        if let data = input, !data.isEmpty {
            guard let args = try? JSONDecoder().decode(ListFilesArgs.self, from: data) else {
                return "<error> Invalid JSON arguments for list_files. Expected: {\"path\": \"...\"}"
            }
            let trimmed = args.path?.trimmingCharacters(in: .whitespacesAndNewlines)
            requestedPath = (trimmed?.isEmpty ?? true) ? "." : (trimmed ?? ".")
        } else {
            requestedPath = "."
        }

        let directoryURL = ListFiles.fileURL(from: requestedPath)
        let fm = FileManager.default
        var isDirectory: ObjCBool = false

        guard fm.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory) else {
            return "<error> Path not found: \(requestedPath)"
        }

        if !isDirectory.boolValue {
            return "file \(directoryURL.path)"
        }

        do {
            let contents = try fm.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
                options: []
            )
            let sorted = contents.sorted { $0.lastPathComponent.localizedCompare($1.lastPathComponent) == .orderedAscending }
            var lines: [String] = ["directory \(directoryURL.path)"]

            if sorted.isEmpty {
                lines.append("<empty>")
            } else {
                for (index, entry) in sorted.enumerated() {
                    if index >= ListFiles.entryLimit {
                        lines.append("… \(sorted.count - ListFiles.entryLimit) more")
                        break
                    }

                    let values = try? entry.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
                    var name = entry.lastPathComponent
                    if values?.isDirectory == true {
                        name.append("/")
                    }
                    if values?.isSymbolicLink == true {
                        name.append("@")
                    }
                    lines.append(name)
                }
            }

            return lines.joined(separator: "\n")
        } catch {
            return "<error> Could not list path \(requestedPath). Error: \(error.localizedDescription)"
        }
    }

    private static func fileURL(from path: String) -> URL {
        if path.hasPrefix("/") || path.hasPrefix("~") {
            return URL(fileURLWithPath: NSString(string: path).expandingTildeInPath)
        } else {
            let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            return cwd.appendingPathComponent(path)
        }
    }
}
