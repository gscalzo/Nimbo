import Foundation
import SwiftOpenAI

protocol Tool {
    var name: String { get }
    var chatTool: ChatCompletionParameters.Tool { get }
    var exec: (Data?) -> String { get }
}
