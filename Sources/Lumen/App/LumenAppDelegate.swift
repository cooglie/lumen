import AppKit

/// Verwaltet das Menüleisten-Icon (`NSStatusItem`) und das Dropdown-Menü.
/// Hier wachsen die Einträge für Aurora (Shader wählen) und Mosaic (Choreografien) rein.
final class LumenAppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "sparkles",
                accessibilityDescription: "Lumen"
            )
        }

        let menu = NSMenu()
        menu.addItem(makeHeader("🌌 Aurora"))
        menu.addItem(withTitle: "Shader: Nebula", action: #selector(selectShader), keyEquivalent: "")
        menu.addItem(withTitle: "Shader: Aurora Borealis", action: #selector(selectShader), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(makeHeader("🎭 Mosaic"))
        menu.addItem(withTitle: "Choreografie: Grid", action: #selector(runChoreography), keyEquivalent: "")
        menu.addItem(withTitle: "Choreografie: Spiral", action: #selector(runChoreography), keyEquivalent: "")
        menu.addItem(withTitle: "Choreografie: Fan", action: #selector(runChoreography), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Einstellungen…", action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Lumen beenden", action: #selector(quit), keyEquivalent: "q")

        statusItem.menu = menu
    }

    // MARK: - Menu Actions (Stubs)

    @objc private func selectShader() {
        // TODO: Aurora.ShaderEngine aktiv übergeben
        NSLog("[Lumen] Shader ausgewählt (Stub)")
    }

    @objc private func runChoreography() {
        // TODO: Mosaic.Choreographer auslösen
        NSLog("[Lumen] Choreografie gestartet (Stub)")
    }

    @objc private func openSettings() {
        // TODO: UI.SettingsWindow öffnen
        NSLog("[Lumen] Einstellungen (Stub)")
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Helpers

    private func makeHeader(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }
}
