import Foundation
import AppKit

/// Beschreibt eine Fenster-Choreografie. Built-in-Muster sind Grid, Spiral,
/// Fan, Cascade, Orbit. Eigene Muster als JSON ladbar.
struct Choreography {

    let name: String
    let layout: Layout

    enum Layout: String, CaseIterable {
        case grid, spiral, fan, cascade, orbit
    }

    /// Liefert die Ziel-Frames für jedes Fenster im übergebenen Bildschirmbereich.
    func targetFrames(for windows: [LumenWindow], in screen: CGRect) -> [CGRect] {
        let count = max(windows.count, 1)
        switch layout {
        case .grid:     return gridLayout(count: count, screen: screen)
        case .spiral:   return spiralLayout(count: count, screen: screen)
        case .fan:      return fanLayout(count: count, screen: screen)
        case .cascade:  return cascadeLayout(count: count, screen: screen)
        case .orbit:    return orbitLayout(count: count, screen: screen)
        }
    }

    // MARK: - Layouts

    private func gridLayout(count: Int, screen: CGRect) -> [CGRect] {
        let cols = Int(ceil(sqrt(Double(count))))
        let rows = Int(ceil(Double(count) / Double(cols)))
        let cell = CGSize(width: screen.width / CGFloat(cols),
                          height: screen.height / CGFloat(rows))
        return (0..<count).map { i in
            let col = i % cols
            let row = i / cols
            return CGRect(x: screen.minX + CGFloat(col) * cell.width,
                          y: screen.minY + CGFloat(row) * cell.height,
                          width: cell.width, height: cell.height)
        }
    }

    private func spiralLayout(count: Int, screen: CGRect) -> [CGRect] {
        // Goldene Spirale vom Zentrum nach außen.
        let cx = screen.midX
        let cy = screen.midY
        let golden = 1.618
        let baseScale = min(screen.width, screen.height) * 0.15

        return (0..<count).map { i in
            let t = Double(i)
            let angle = t * 2.4 // Bogenmaß pro Schritt
            let radius = baseScale * pow(golden, t * 0.25)
            let x = cx + CGFloat(cos(angle) * radius)
            let y = cy + CGFloat(sin(angle) * radius)
            let size = baseScale * 0.8
            return CGRect(x: x - size / 2, y: y - size / 2, width: size, height: size)
        }
    }

    private func fanLayout(count: Int, screen: CGRect) -> [CGRect] {
        // Fächer vom unteren Bildschirmrand aufgespannt.
        let cx = screen.midX
        let baseY = screen.minY + 40
        let radius = screen.height * 0.45
        let spread: CGFloat = .pi / 2.2 // Fächerbreite
        let size = min(screen.width, screen.height) * 0.25

        return (0..<count).map { i in
            let t = count == 1 ? 0.5 : CGFloat(i) / CGFloat(count - 1)
            let angle = (.pi / 2) - spread * t + spread / 2  // von links nach rechts
            let x = cx + CGFloat(cos(angle)) * radius
            let y = baseY + CGFloat(sin(angle)) * radius
            return CGRect(x: x - size / 2, y: y - size / 2, width: size, height: size)
        }
    }

    private func cascadeLayout(count: Int, screen: CGRect) -> [CGRect] {
        // Klassische Kaskade: jedes Fenster leicht versetzt.
        let offset: CGFloat = 30
        let w = screen.width * 0.55
        let h = screen.height * 0.75
        return (0..<count).map { i in
            let off = CGFloat(i) * offset
            return CGRect(x: screen.minX + off, y: screen.minY + off, width: w, height: h)
        }
    }

    private func orbitLayout(count: Int, screen: CGRect) -> [CGRect] {
        // Gleichmäßig auf einem Kreis verteilt.
        let cx = screen.midX
        let cy = screen.midY
        let radius = min(screen.width, screen.height) * 0.3
        let size = min(screen.width, screen.height) * 0.18

        return (0..<count).map { i in
            let angle = (CGFloat(i) / CGFloat(count)) * 2 * .pi
            let x = cx + CGFloat(cos(angle)) * radius - size / 2
            let y = cy + CGFloat(sin(angle)) * radius - size / 2
            return CGRect(x: x, y: y, width: size, height: size)
        }
    }

    // MARK: - Built-in-Katalog

    static let builtin: [Choreography] = [
        Choreography(name: "Grid",    layout: .grid),
        Choreography(name: "Spiral",  layout: .spiral),
        Choreography(name: "Fan",     layout: .fan),
        Choreography(name: "Cascade", layout: .cascade),
        Choreography(name: "Orbit",   layout: .orbit)
    ]
}
