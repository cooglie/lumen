import Foundation
import AppKit

/// Der Mosaic-Choreograf. Nimmt eine Choreografie und wendet sie animiert
/// auf alle sichtbaren Fenster an — mit Easing (Smoothstep).
final class Choreographer {

    private let windowService = WindowService()
    private var animationTimer: Timer?

    /// Führt eine Choreografie aus. Prüft zuerst Accessibility-Berechtigung.
    func perform(_ choreography: Choreography) {
        // Laufende Animation stoppen.
        animationTimer?.invalidate()

        guard windowService.hasAccessibilityPermission() else {
            LumenLog.error("Keine Accessibility-Berechtigung — Fenster lassen sich nicht bewegen.", category: "mosaic")
            windowService.requestAccessibilityPermission()
            return
        }

        let windows = windowService.allVisibleWindows()
        guard !windows.isEmpty else {
            LumenLog.info("Keine Fenster gefunden.", category: "mosaic")
            return
        }

        let screen = windowService.screenFrame()
        let targets = choreography.targetFrames(for: windows, in: screen)
        let startFrames = windows.map { $0.frame }

        LumenLog.info("Choreografie '\(choreography.name)' auf \(windows.count) Fenster", category: "mosaic")

        // Animation über ~0.5s mit Smoothstep-Easing.
        let duration: TimeInterval = 0.5
        let steps = 30
        var currentStep = 0

        animationTimer = Timer(timeInterval: duration / TimeInterval(steps), repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            currentStep += 1
            let progress = CGFloat(currentStep) / CGFloat(steps)
            let eased = self.smoothstep(progress)

            for i in 0..<min(windows.count, targets.count) {
                let from = startFrames[i]
                let to = targets[i]
                let frame = self.interpolate(from: from, to: to, t: eased)
                self.windowService.setFrame(frame, for: windows[i])
            }

            if currentStep >= steps {
                timer.invalidate()
                LumenLog.info("Choreografie '\(choreography.name)' abgeschlossen.", category: "mosaic")
            }
        }
        RunLoop.main.add(animationTimer!, forMode: .common)
    }

    // MARK: - Easing

    private func smoothstep(_ t: CGFloat) -> CGFloat {
        return t * t * (3 - 2 * t)
    }

    private func interpolate(from: CGRect, to: CGRect, t: CGFloat) -> CGRect {
        CGRect(
            x: from.minX + (to.minX - from.minX) * t,
            y: from.minY + (to.minY - from.minY) * t,
            width: from.width + (to.width - from.width) * t,
            height: from.height + (to.height - from.height) * t
        )
    }
}
