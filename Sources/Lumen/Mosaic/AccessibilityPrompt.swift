import AppKit
import ApplicationServices

/// Verantwortlich für die Nutzer-Erklärung der Accessibility-Berechtigung.
///
/// **Prinzip:** Accessibility wird niemals beim App-Start oder im Hintergrund angefordert.
/// Der System-Prompt erscheint **ausschließlich**, wenn der Nutzer aktiv eine
/// Mosaic-Choreografie startet und die Berechtigung noch fehlt. Zuvor erhält der
/// Nutzer eine erklärende `NSAlert`, die transparent macht:
/// - welche Rechte Lumen benötigt (Bedienhilfen)
/// - wofür sie gebraucht werden (Fenster verschieben)
/// - dass Aurora (Wallpaper) die Berechtigung nicht braucht
/// - dass die Berechtigung jederzeit widerrufen werden kann
///
/// Aurora (Shader-Wallpaper) benötigt **keine** Accessibility-Berechtigung und
/// funktioniert auch ohne sie vollständig.
enum AccessibilityPrompt {

    /// Zeigt eine erklärende Alert-Box und löst danach den System-Prompt aus.
    static func explainAndRequest() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Mosaic benötigt Bedienhilfen-Berechtigung"
        alert.informativeText = """
            Lumen muss Fenster anderer Apps verschieben können, um die Choreografie auszuführen. \
            Dafür benötigt es die Berechtigung »Bedienhilfen«.

            • Lumen führt keine Tastatureingaben oder Klicks aus — es verschiebt ausschließlich Fenster.
            • Aurora (Shader-Hintergrund) funktioniert auch OHNE diese Berechtigung.
            • Du kannst die Berechtigung jederzeit widerrufen: \
            Systemeinstellungen → Datenschutz → Bedienhilfen.

            Klicke »Systemeinstellung öffnen«, um Lumen in der Liste zu aktivieren. \
            Starte danach die Choreografie erneut.
            """
        alert.addButton(withTitle: "Systemeinstellung öffnen")
        alert.addButton(withTitle: "Abbrechen")

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }

        // System-Prompt auslösen (öffnet »Datenschutz → Bedienhilfen«).
        requestSystemPrompt()
    }

    /// Löst den macOS-System-Prompt für Accessibility aus.
    /// Wird nur nach expliziter Bestätigung durch den Nutzer aufgerufen.
    private static func requestSystemPrompt() {
        let opts: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true]
        _ = AXIsProcessTrustedWithOptions(opts)
    }
}
