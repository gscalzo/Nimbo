import Foundation

struct PathToolArguments: Decodable {
    let rawPath: String?

    var trimmedPath: String? {
        guard let rawPath else { return nil }
        let trimmed = rawPath.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private enum CodingKeys: String, CodingKey {
        case rawPath = "path"
    }
}

extension Data? {
    func asPath(defaultPath: String?) -> String? {
        guard let self, !self.isEmpty else {
            return defaultPath
        }

        guard let args = try? JSONDecoder().decode(PathToolArguments.self, from: self) else {
            return defaultPath
        }

        return args.trimmedPath ?? defaultPath
    }
}

extension String {
    var asURL: URL {
        if hasPrefix("/") || hasPrefix("~") {
            return URL(fileURLWithPath: NSString(string: self).expandingTildeInPath)
        }

        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return cwd.appendingPathComponent(self)
    }
}

extension URL {
    
    var isDirectory: Bool {
        let values = try? self.resourceValues(forKeys: [.isDirectoryKey])
        return values?.isDirectory == true
    }
    
    var exists: Bool {
        FileManager.default.fileExists(atPath: self.path)
    }
    
    func contentsOfDirectory() throws -> [URL] {
        try FileManager.default.contentsOfDirectory(
            at: self,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
            options: []
        )
    }
    
        
    
    func formatted() -> String {
        let values = try? self.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
        var name = self.lastPathComponent
        if values?.isDirectory == true {
            name.append("/")
        }
        if values?.isSymbolicLink == true {
            name.append("@")
        }
        return name
    }
}
