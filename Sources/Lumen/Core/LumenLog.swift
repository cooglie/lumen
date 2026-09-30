import Foundation

/// Loggt strukturiert nach os_log / Konsole. Ein zentraler Einstiegspunkt,
/// damit wir später Logging-Backend tauschen können.
enum LumenLog {
    static func info(_ message: String, category: String = "general") {
        NSLog("[Lumen:\(category)] \(message)")
    }

    static func error(_ message: String, category: String = "general") {
        NSLog("[Lumen:\(category) ❌] \(message)")
    }
}
