import Foundation

/// Stub für den globalen Hotkey-Manager.
/// Später: KeyboardShortcuts-Package oder Carbon Event-Taps für ⌥⇧M etc.
final class HotkeyManager {
    static let shared = HotkeyManager()

    func registerDefaults() {
        LumenLog.info("Hotkey-Manager initialisiert (Stub)", category: "hotkeys")
    }
}
