import Foundation
import AppKit

/// Beschreibt eine Fenster-Choreografie. Built-in-Muster sind Grid, Spiral,
/// Fan, Cascade, Orbit. Eigene Muster als JSON ladbar.
struct Choreography {

    let name: String
    let layout: Layout

    enum Layout: String {
        case grid, spiral, fan, cascade, orbit
    }

    func targetFrames(for windows: [LumenWindow], in screen: CGRect) -> [CGRect] {
        // Stub-Implementierung: gleichmäßiges Gitter über den sichtbaren Bereich.
        // Die echten Layouts (Spiral/Fan/…) kommen mit der Physik-Engine.
        let count = max(windows.count, 1)
        let cols = Int(ceil(sqrt(Double(count))))
        let rows = Int(ceil(Double(count) / Double(cols)))
        let cell = CGSize(width: screen.width / CGFloat(cols),
                          height: screen.height / CGFloat(rows))

        return (0..<count).map { i in
            let col = i % cols
            let row = i / cols
            return CGRect(
                x: screen.minX + CGFloat(col) * cell.width,
                y: screen.minY + CGFloat(row) * cell.height,
                width: cell.width,
                height: cell.height
            )
        }
    }
}
