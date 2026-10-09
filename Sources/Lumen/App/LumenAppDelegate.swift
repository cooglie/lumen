import AppKit

/// Verwaltet das Menüleisten-Icon (`NSStatusItem`) und das Dropdown-Menü.
/// Verkabelt Aurora (Shader wählen, Toggle) und Mosaic (Choreografien).
final class LumenAppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private let shaderEngine = ShaderEngine.shared
    private let choreographer = Choreographer()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            if #available(macOS 11.0, *) {
                button.image = NSImage(
                    systemSymbolName: "sparkles",
                    accessibilityDescription: "Lumen"
                )
            } else {
                button.image = LumenAppDelegate.legacyStatusIcon
            }
        }

        rebuildMenu()

        // Aurora automatisch starten.
        shaderEngine.start()
    }

    // MARK: - Menu Aufbau

    private func rebuildMenu() {
        let menu = NSMenu()

        // --- Aurora ---
        menu.addItem(makeHeader("🌌 Aurora"))
        let auroraToggle = NSMenuItem(title: shaderEngine.isRunning ? "Pausieren" : "Starten",
                                      action: #selector(toggleAurora), keyEquivalent: "")
        menu.addItem(auroraToggle)
        menu.addItem(.separator())

        let shaderHeader = NSMenuItem(title: "Shader wählen", action: nil, keyEquivalent: "")
        shaderHeader.isEnabled = false
        menu.addItem(shaderHeader)
        for shader in ShaderPackLoader.bundled {
            let item = NSMenuItem(title: shader.name, action: #selector(selectShader(_:)), keyEquivalent: "")
            item.representedObject = shader
            item.state = (shader == shaderEngine.activeShader) ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())

        // --- Mosaic ---
        menu.addItem(makeHeader("🎭 Mosaic"))
        for choreography in Choreography.builtin {
            menu.addItem(withTitle: choreography.name, action: #selector(runChoreography(_:)), keyEquivalent: "")
        }
        menu.addItem(.separator())

        menu.addItem(withTitle: "Einstellungen…", action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Lumen beenden", action: #selector(quit), keyEquivalent: "q")

        statusItem.menu = menu
    }

    // MARK: - Aurora Actions

    @objc private func toggleAurora() {
        shaderEngine.toggle()
        rebuildMenu()
    }

    @objc private func selectShader(_ sender: NSMenuItem) {
        guard let shader = sender.representedObject as? ShaderDescriptor else { return }
        shaderEngine.select(shader)
        rebuildMenu()
    }

    // MARK: - Mosaic Actions

    @objc private func runChoreography(_ sender: NSMenuItem) {
        guard let choreography = Choreography.builtin.first(where: { $0.name == sender.title }) else { return }
        choreographer.perform(choreography)
    }

    // MARK: - Misc

    @objc private func openSettings() {
        LumenLog.info("Einstellungen (noch nicht implementiert)", category: "ui")
    }

    @objc private func quit() {
        shaderEngine.stop()
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Helpers

    private func makeHeader(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    /// Einfach gezeichnetes Menüleisten-Icon für macOS < 11 (keine SF Symbols).
    private static let legacyStatusIcon: NSImage = {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.labelColor.setFill()
        let path = NSBezierPath(ovalIn: NSRect(x: 4, y: 4, width: 10, height: 10))
        path.fill()
        // Vier kleine Strahlen als "Sparkles".
        for angle in stride(from: 0.0, to: 360.0, by: 90.0) {
            let rad = angle * .pi / 180.0
            let ray = NSBezierPath()
            ray.move(to: NSPoint(x: 9 + cos(rad) * 6, y: 9 + sin(rad) * 6))
            ray.line(to: NSPoint(x: 9 + cos(rad) * 8, y: 9 + sin(rad) * 8))
            ray.lineWidth = 1.5
            ray.stroke()
        }
        image.unlockFocus()
        image.isTemplate = true
        return image
    }()
}
