import AppKit

/// Einstiegspunkt der App. Da Lumen eine Menüleisten-App ist (kein Dock-Icon),
/// nutzen wir `NSApplication` direkt statt SwiftUI-App-Lifecycle.
@main
struct LumenMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = LumenAppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory) // kein Dock-Icon, nur Menüleiste
        app.run()
    }
}
