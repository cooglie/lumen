import Foundation
import Metal

/// Die Aurora-Shader-Engine. Rendert Metal-Shader und stellt sie als
/// animierten Desktop-Hintergrund bereit.
///
/// Status: Gerüst. Das echte Rendering (MTKView / CAMetalLayer) und die
/// Wallpaper-Bridge (NSWorkspace / Spaces) folgen im nächsten Schritt.
final class ShaderEngine {

    /// Aktuell geladener Shader (z. B. "Nebula").
    private(set) var activeShader: ShaderDescriptor

    /// Alle verfügbaren Shader aus dem Pack-System.
    private(set) var availableShaders: [ShaderDescriptor] = []

    init() {
        availableShaders = ShaderPackLoader.loadBundledShaders()
        activeShader = availableShaders.first
            ?? ShaderDescriptor(name: "Default", sourcePath: nil)
    }

    func select(_ shader: ShaderDescriptor) {
        activeShader = shader
        LumenLog.info("Shader aktiv: \(shader.name)", category: "aurora")
        // TODO: Pipeline neu kompilieren, Render-Loop neu starten
    }

    /// Startet den Render-Loop (Stub).
    func start() {
        LumenLog.info("Aurora-Engine gestartet mit '\(activeShader.name)'", category: "aurora")
    }

    func pause() {
        LumenLog.info("Aurora-Engine pausiert", category: "aurora")
    }
}
