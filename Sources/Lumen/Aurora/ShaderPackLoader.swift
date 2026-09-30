import Foundation
import Metal
import QuartzCore
import AppKit

/// Ein Shader-Paket: Name + Fragment-Funktionsname + Quelldatei.
struct ShaderDescriptor: Equatable {
    let name: String
    let fragmentFunction: String
    let sourceFile: String // Dateiname im Resources/Shaders-Ordner
}

/// Lädt Shader-Quelltext aus dem App-Bundle und (später) aus Nutzer-Packs.
enum ShaderPackLoader {

    static let bundled: [ShaderDescriptor] = [
        ShaderDescriptor(name: "Nebula",         fragmentFunction: "nebula_fragment",  sourceFile: "Nebula.metal"),
        ShaderDescriptor(name: "Aurora Borealis", fragmentFunction: "aurora_fragment", sourceFile: "AuroraBorealis.metal"),
        ShaderDescriptor(name: "Plasma Field",   fragmentFunction: "plasma_fragment",  sourceFile: "PlasmaField.metal")
    ]

    /// Liefert den kombinierten Quelltext (Common + Shader) für makeLibrary(source:).
    static func source(for shader: ShaderDescriptor) -> String? {
        let dir = "Shaders"
        guard
            let commonURL = Bundle.main.url(forResource: "Common", withExtension: "metal", subdirectory: dir),
            let shaderURL = Bundle.main.url(forResource: shader.sourceFile, withExtension: nil, subdirectory: dir),
            let common = try? String(contentsOf: commonURL, encoding: .utf8),
            let body   = try? String(contentsOf: shaderURL, encoding: .utf8)
        else {
            LumenLog.error("Shader-Quelltext nicht gefunden: \(shader.sourceFile)", category: "aurora")
            return nil
        }
        return common + "\n" + body
    }
}
