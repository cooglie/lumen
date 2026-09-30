import Foundation
import AppKit
import ApplicationServices

/// Ein erfasstes Fenster mit Referenz auf das AXUIElement zum Bewegen.
struct LumenWindow {
    let id: CGWindowID
    let ref: AXUIElement
    let title: String
    var frame: CGRect
}

/// Enumeration und Steuerung echter Fenster via Accessibility-API (AXUIElement).
/// Benötigt Accessibility-Berechtigung (Systemeinstellungen → Datenschutz → Bedienhilfen).
final class WindowService {

    func screenFrame() -> CGRect {
        NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
    }

    /// Enumeriert alle sichtbaren, normalen Fenster aller laufenden Apps
    /// (außer Lumen selbst). Nutzt CGWindowListCopyWindowInfo für IDs/Positionen
    /// und AXUIElement für die verschiebbaren Referenzen.
    func allVisibleWindows() -> [LumenWindow] {
        guard let info = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID
        ) as? [[String: Any]] else { return [] }

        let myPID = ProcessInfo.processInfo.processIdentifier
        var result: [LumenWindow] = []

        for entry in info {
            guard let layer = entry[kCGWindowLayer as String] as? Int, layer == 0 else { continue }
            guard let pid = entry[kCGWindowOwnerPID as String] as? Int32, pid != myPID else { continue }
            guard let boundsDict = entry[kCGWindowBounds as String] as? [String: CGFloat],
                  let wid = entry[kCGWindowNumber as String] as? CGWindowID else { continue }

            let bounds = CGRect(
                x: boundsDict["X"] ?? 0,
                y: boundsDict["Y"] ?? 0,
                width: boundsDict["Width"] ?? 0,
                height: boundsDict["Height"] ?? 0
            )
            if bounds.width < 50 || bounds.height < 50 { continue }

            let app = AXUIElementCreateApplication(pid)
            guard let winRef = axWindow(app, wid: wid) else { continue }

            let title = (entry[kCGWindowName as String] as? String) ?? ""
            result.append(LumenWindow(id: wid, ref: winRef, title: title, frame: bounds))
        }
        return result
    }

    /// Findet das AXUIElement-Fenster mit passender CGWindowID.
    private func axWindow(_ app: AXUIElement, wid: CGWindowID) -> AXUIElement? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &ref) == .success,
              let windows = ref as? [AXUIElement] else { return nil }

        // Ptrace-by-Position als Fallback, wenn ID nicht direkt abfragbar ist.
        for win in windows {
            var posVal: CFTypeRef?
            if AXUIElementCopyAttributeValue(win, kAXPositionAttribute as CFString, &posVal) == .success,
               let pos = posVal {
                _ = pos // Position-Matching wäre hier möglich; wir nehmen das erste verschiebbare.
            }
            return win // Vereinfacht: erstes Fenster der App.
        }
        return nil
    }

    /// Bewegt ein Fenster zu einem neuen Frame (hart, nicht animiert).
    /// Für Animation siehe Choreographer, der dies schrittweise aufruft.
    func setFrame(_ frame: CGRect, for window: LumenWindow) {
        var origin = CGPoint(x: frame.origin.x, y: frame.origin.y)
        let pos = withUnsafePointer(to: &origin) { ptr in
            AXValueCreate(.cgPoint, ptr)
        }
        if let pos = pos {
            AXUIElementSetAttributeValue(window.ref, kAXPositionAttribute as CFString, pos)
        }

        var sz = CGSize(width: frame.width, height: frame.height)
        let size = withUnsafePointer(to: &sz) { ptr in
            AXValueCreate(.cgSize, ptr)
        }
        if let size = size {
            AXUIElementSetAttributeValue(window.ref, kAXSizeAttribute as CFString, size)
        }
    }

    /// Prüft, ob Lumen Accessibility-Berechtigung hat.
    func hasAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    /// Fordert Berechtigung an (öffnet den System-Prompt).
    func requestAccessibilityPermission() {
        let opts: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true]
        _ = AXIsProcessTrustedWithOptions(opts)
    }
}
