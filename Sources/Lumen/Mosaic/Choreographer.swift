import Foundation

/// Der Mosaic-Choreograf. Nimmt eine Choreografie-Beschreibung und wendet
/// sie auf alle sichtbaren Fenster an — animiert mit Feder-Physik.
///
/// Status: Gerüst. Fenster-Enumeration (AXUIElement) und Physik-Engine
/// folgen im nächsten Schritt.
final class Choreographer {

    private let windowService = WindowService()

    /// Führt eine benannte Choreografie aus.
    func perform(_ choreography: Choreography) {
        let windows = windowService.allVisibleWindows()
        LumenLog.info(
            "Choreografie '\(choreography.name)' auf \(windows.count) Fenster",
            category: "mosaic"
        )

        let targets = choreography.targetFrames(for: windows, in: windowService.screenFrame())

        for (index, window) in windows.enumerated() {
            guard index < targets.count else { break }
            // TODO: Physik-Animation statt hartem Setzen
            windowService.move(window, to: targets[index])
        }
    }
}
