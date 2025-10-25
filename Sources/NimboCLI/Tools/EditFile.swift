import Foundation
import SwiftOpenAI

struct EditFile: Tool {
    fileprivate struct Arguments: Decodable {
        let path: String
        let oldStr: String
        let newStr: String

        enum CodingKeys: String, CodingKey {
            case path
            case oldStr = "old_str"
            case newStr = "new_str"
        }

        var trimmedPath: String {
            path.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private static let toolName = "edit_file"
    private static let contentPreviewLimit = 100_000
    private static let invalidArgumentsMessage = "<error> Invalid JSON arguments for edit_file. Expected: {\"path\": \"...\", \"old_str\": \"...\", \"new_str\": \"...\"}"

    var name = EditFile.toolName

    var chatTool: ChatCompletionParameters.Tool = {
        let schema = JSONSchema(
            type: .object,
            properties: [
                "path": JSONSchema(type: .string),
                "old_str": JSONSchema(type: .string),
                "new_str": JSONSchema(type: .string)
            ]
        )

        let function = ChatCompletionParameters.ChatFunction(
            name: EditFile.toolName,
            strict: nil,
            description: """
                Make edits to a text file by replacing an exact match of `old_str` with `new_str`. \
                The replacement must be unique and `old_str` must differ from `new_str`. \
                Creates the file when it does not exist and `old_str` is empty.
                """,
            parameters: schema
        )

        return .init(function: function)
    }()

    var exec: (Data?) -> String = { data in
        guard
            let data,
            let arguments = try? JSONDecoder().decode(Arguments.self, from: data)
        else {
            return EditFile.invalidArgumentsMessage
        }

        return EditFile.process(arguments)
    }
}

private extension EditFile {
    static func process(_ arguments: Arguments) -> String {
        let path = arguments.trimmedPath
        guard !path.isEmpty else {
            return "<error> Path must not be empty."
        }

        guard arguments.oldStr != arguments.newStr else {
            return "<error> old_str and new_str must be different."
        }

        let fileURL = path.asURL

        return fileURL.exists
            ? updateExistingFile(arguments, at: fileURL, path: path)
            : createNewFile(arguments, at: fileURL, path: path)
    }

    static func createNewFile(_ arguments: Arguments, at url: URL, path: String) -> String {
        guard arguments.oldStr.isEmpty else {
            return "<error> File does not exist. Use an empty old_str to create a new file."
        }

        do {
            try url.ensureParentDirectoryExists()
            try url.writeUTF8(arguments.newStr)
            return successMessage(for: path, updatedContent: arguments.newStr, created: true)
        } catch {
            return "<error> Could not create file at path: \(path). Error: \(error.localizedDescription)"
        }
    }

    static func updateExistingFile(_ arguments: Arguments, at url: URL, path: String) -> String {
        guard !arguments.oldStr.isEmpty else {
            return "<error> old_str must not be empty when editing an existing file."
        }

        do {
            let original = try url.readUTF8()
            let matches = original.countOccurrences(of: arguments.oldStr)

            switch matches {
            case 0:
                return "<error> old_str not found in \(path)."
            case 1:
                let updated = original.replacingOccurrences(of: arguments.oldStr, with: arguments.newStr)
                try url.writeUTF8(updated)
                return successMessage(for: path, updatedContent: updated, created: false)
            default:
                return "<error> old_str must match exactly one occurrence. Found \(matches)."
            }
        } catch {
            return "<error> Could not edit file at path: \(path). Error: \(error.localizedDescription)"
        }
    }

    static func successMessage(for path: String, updatedContent: String, created: Bool) -> String {
        let header = created ? "created file \(path)" : "updated file \(path)"
        let truncated = updatedContent.truncated(to: contentPreviewLimit)
        return "\(header)\n\(truncated)"
    }
}
