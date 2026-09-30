import Foundation
import AppKit
import CoreGraphics

// Lumen-Icon-Generator: zeichnet einen leuchtenden Aurora-Lichtbogen
// (L-Form) auf dunklem, abgerundetem Quadrat. Output: 1024x1024 PNG.

let size = 1024
let rect = CGRect(x: 0, y: 0, width: size, height: size)

let cs = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(data: nil, width: size, height: size,
                          bitsPerComponent: 8, bytesPerRow: 0,
                          space: cs,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
    fatalError("Context fehlgeschlagen")
}

// --- Hintergrund: dunkles, abgerundetes Quadrat mit Verlauf ---
let bgPath = CGPath(roundedRect: rect.insetBy(dx: 0, dy: 0),
                    cornerWidth: 230, cornerHeight: 230,
                    transform: nil)
ctx.addPath(bgPath)
ctx.closePath()
ctx.clip()

let dark = CGColor(red: 0.04, green: 0.03, blue: 0.09, alpha: 1)
let darker = CGColor(red: 0.01, green: 0.01, blue: 0.03, alpha: 1)
let grad = CGGradient(colorsSpace: cs, colors: [dark, darker] as CFArray,
                      locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: size),
                       end: CGPoint(x: size, y: 0), options: [])

// --- Mehrere leuchtende Bänder (Aurora) in L-Form ---
// Die L-Form: ein vertikaler Strich links + horizontaler Bogen unten.
func drawBand(color: CGColor, width: CGFloat, offset: CGFloat, alpha: CGFloat) {
    ctx.setLineWidth(width)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)

    // Schatten/Glow simulieren durch mehrfaches Zeichnen mit Blur-ähnlicher Deckung.
    for (i, blurW) in [width * 3.5, width * 2.2, width].enumerated() {
        let a = alpha * (i == 0 ? 0.15 : (i == 1 ? 0.35 : 1.0))
        var c = color.components!
        let glow = CGColor(red: c[0], green: c[1], blue: c[2], alpha: a)
        ctx.setStrokeColor(glow)
        ctx.setLineWidth(blurW)

        // Vertikaler Teil der L (links, von oben nach unten)
        let vTop = CGPoint(x: 340 + offset, y: 720)
        let vBottom = CGPoint(x: 340 + offset, y: 300)
        ctx.move(to: vTop)
        ctx.addLine(to: vBottom)

        // Horizontaler Bogen (von der L-Ecke nach rechts, leicht geschwungen)
        let hEnd = CGPoint(x: 700 + offset, y: 300)
        let ctrl = CGPoint(x: 520 + offset, y: 280)
        ctx.addQuadCurve(to: hEnd, control: ctrl)
        ctx.strokePath()
    }
}

// Teal-Band
drawBand(color: CGColor(red: 0.1, green: 0.9, blue: 0.7, alpha: 1),
         width: 46, offset: 0, alpha: 0.9)
// Magenta-Band (leicht versetzt)
drawBand(color: CGColor(red: 0.9, green: 0.2, blue: 0.85, alpha: 1),
         width: 40, offset: 26, alpha: 0.7)
// Violet-Band (weiter versetzt)
drawBand(color: CGColor(red: 0.55, green: 0.3, blue: 1.0, alpha: 1),
         width: 34, offset: 48, alpha: 0.55)

// --- Glanzpunkt oben links (Lichtquelle) ---
let glowGrad = CGGradient(colorsSpace: cs,
    colors: [CGColor(red: 1, green: 1, blue: 1, alpha: 0.9),
             CGColor(red: 1, green: 1, blue: 1, alpha: 0)] as CFArray,
    locations: [0, 1])!
ctx.drawRadialGradient(glowGrad,
    startCenter: CGPoint(x: 340, y: 730), startRadius: 0,
    endCenter: CGPoint(x: 340, y: 730), endRadius: 60,
    options: [])

// --- Output ---
guard let img = ctx.makeImage() else { fatalError("Image fehlgeschlagen") }
let rep = NSBitmapImageRep(cgImage: img)
guard let data = rep.representation(using: .png, properties: [:]) else {
    fatalError("PNG fehlgeschlagen")
}

let outPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "lumen-icon.png"
try! data.write(to: URL(fileURLWithPath: outPath))
print("Icon geschrieben: \(outPath) (\(size)x\(size))")
