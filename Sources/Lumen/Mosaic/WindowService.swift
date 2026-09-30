import Foundation
import AppKit

/// Abstraktion über die Fenster-APIs (Accessibility + später CGS* private).
/// Im Gerüst wird nur der sichtbare Bildschirmbereich geliefert; echte
/// Fenster-Enumeration via `AXUIElement` folgt.
struct LumenWindow: Equatable {
    let id: Int
    let frame: CGRect
}

final class WindowService {

    func allVisibleWindows() -> [LumenWindow] {
        // TODO: AXUIElementCopyAttributeValue für kAXWindowsAttribute pro App
        return []
    }

    func screenFrame() -> CGRect {
        NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
    }

    func move(_ window: LumenWindow, to frame: CGRect) {
        // TODO: AXUIElementSetAttributeValue kAXPositionAttribute / kAXSizeAttribute
        LumenLog.info("Fenster \(window.id) → \(frame)", category: "mosaic")
    }
}
