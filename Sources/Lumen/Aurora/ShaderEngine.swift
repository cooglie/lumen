import Foundation
import Metal
import QuartzCore
import AppKit

/// Die Aurora-Shader-Engine. Kompiliert Metal-Shader zur Laufzeit und rendert
/// sie als animierten Desktop-Hintergrund (Window-Level = Desktop, über Wallpaper,
/// unter Icons). Pro Bildschirm ein Overlay-Window.
final class ShaderEngine {

    static let shared = ShaderEngine()

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var library: MTLLibrary?
    private var pipeline: MTLRenderPipelineState?
    private var uniformBuffer: MTLBuffer?

    private(set) var activeShader: ShaderDescriptor
    private(set) var isRunning = false

    /// Ein Overlay pro Bildschirm.
    private var overlays: [AuroraOverlay] = []

    private var displayLink: CVDisplayLink?
    private var startTime: CFTimeInterval = 0
    private var renderTimer: Timer?

    private init() {
        device = MTLCreateSystemDefaultDevice()!
        commandQueue = device.makeCommandQueue()
        activeShader = ShaderPackLoader.bundled.first
            ?? ShaderDescriptor(name: "Nebula", fragmentFunction: "nebula_fragment", sourceFile: "Nebula.metal")
        // 4-Byte Float für das Zeit-Uniform.
        uniformBuffer = device.makeBuffer(length: MemoryLayout<Float>.size, options: [])
    }

    // MARK: - Steuerung

    func select(_ shader: ShaderDescriptor) {
        activeShader = shader
        LumenLog.info("Shader aktiv: \(shader.name)", category: "aurora")
        buildPipeline()
        if isRunning { overlays.forEach { $0.shaderChanged() } }
    }

    func start() {
        guard !isRunning else { return }
        guard buildPipeline() else { return }
        isRunning = true
        startTime = CACurrentMediaTime()

        installOverlays()
        startRenderLoop()
        LumenLog.info("Aurora-Engine gestartet mit '\(activeShader.name)'", category: "aurora")
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        renderTimer?.invalidate()
        renderTimer = nil
        overlays.forEach { $0.close() }
        overlays.removeAll()
        LumenLog.info("Aurora-Engine gestoppt", category: "aurora")
    }

    func toggle() {
        isRunning ? stop() : start()
    }

    // MARK: - Pipeline

    @discardableResult
    private func buildPipeline() -> Bool {
        guard let source = ShaderPackLoader.source(for: activeShader) else { return false }

        do {
            library = try device.makeLibrary(source: source, options: nil)
        } catch {
            LumenLog.error("Shader-Kompilierung fehlgeschlagen: \(error)", category: "aurora")
            return false
        }

        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = library?.makeFunction(name: "lumen_vertex")
        desc.fragmentFunction = library?.makeFunction(name: activeShader.fragmentFunction)
        desc.colorAttachments[0].pixelFormat = .bgra8Unorm

        do {
            pipeline = try device.makeRenderPipelineState(descriptor: desc)
            return true
        } catch {
            LumenLog.error("Pipeline-Erstellung fehlgeschlagen: \(error)", category: "aurora")
            return false
        }
    }

    // MARK: - Overlays

    private func installOverlays() {
        overlays.forEach { $0.close() }
        overlays.removeAll()
        for screen in NSScreen.screens {
            let overlay = AuroraOverlay(screen: screen, device: device)
            overlay.orderFrontRegardless()
            overlays.append(overlay)
        }
    }

    // MARK: - Render-Loop

    private func startRenderLoop() {
        renderTimer?.invalidate()
        // ~60 FPS. Pausiert automatisch, wenn die App inaktiv wird (RunLoop common).
        renderTimer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.renderFrame()
        }
        RunLoop.main.add(renderTimer!, forMode: .common)
    }

    private func renderFrame() {
        guard isRunning, let pipeline = pipeline, let queue = commandQueue as MTLCommandQueue? else { return }

        let t = Float(CACurrentMediaTime() - startTime)
        if let ub = uniformBuffer, let ptr = ub.contents().bindMemory(to: Float.self, capacity: 1) {
            ptr.pointee = t
        }

        for overlay in overlays {
            guard let drawable = overlay.drawable() else { continue }
            guard let cmd = queue.makeCommandBuffer(),
                  let enc = cmd.makeRenderCommandEncoder(descriptor: overlay.passDescriptor()) else { continue }
            enc.setRenderPipelineState(pipeline)
            enc.setFragmentBuffer(uniformBuffer, offset: 0, index: 0)
            enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            enc.endEncoding()
            cmd.present(drawable)
            cmd.commit()
        }
    }
}
