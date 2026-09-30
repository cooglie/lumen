import Foundation
import AppKit
import Metal
import QuartzCore

/// Ein randloses, klick-durchlässiges Overlay-Window pro Bildschirm.
/// Trägt ein CAMetalLayer und rendert den aktiven Shader. Window-Level
/// liegt knapp über dem Wallpaper, aber unter normalen Fenstern — so wirkt
/// der Shader wie ein lebender Desktop-Hintergrund.
final class AuroraOverlay: NSWindow {

    private let metalView: MetalPassThroughView
    private let device: MTLDevice

    init(screen: NSScreen, device: MTLDevice) {
        self.device = device
        self.metalView = MetalPassThroughView(device: device)

        let frame = screen.frame
        super.init(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        self.setFrame(frame, display: true)

        // Eigenschaften: kein Fokus, keine Interaktion, kein Schatten.
        isOpaque = false
        hasShadow = false
        backgroundColor = .clear
        ignoresMouseEvents = true       // Klicks fallen durch zu Icons/Fenstern
        isMovable = false
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        level = .init(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        title = "Lumen Aurora"
        isReleasedWhenClosed = false

        metalView.frame = contentView?.bounds ?? frame
        metalView.autoresizingMask = [.width, .height]
        contentView = metalView
    }

    /// Wird aufgerufen, wenn der Nutzer im Menü einen anderen Shader wählt.
    func shaderChanged() {
        // Nichts zu tun hier: die Pipeline wird zentral in ShaderEngine neu
        // gebaut und beim nächsten Frame automatisch verwendet.
    }

    /// Rendert einen Frame mit der übergebenen Pipeline + Zeit-Uniform.
    func render(pipeline: MTLRenderPipelineState, uniform: MTLBuffer?, queue: MTLCommandQueue) {
        guard let layer = metalView.metalLayer,
              let drawable = layer.nextDrawable() else { return }
        guard let cmd = queue.makeCommandBuffer() else { return }

        let passDesc = MTLRenderPassDescriptor()
        passDesc.colorAttachments[0].texture = drawable.texture
        passDesc.colorAttachments[0].loadAction = .clear
        passDesc.colorAttachments[0].storeAction = .store

        guard let enc = cmd.makeRenderCommandEncoder(descriptor: passDesc) else { return }
        enc.setRenderPipelineState(pipeline)
        enc.setFragmentBuffer(uniform, offset: 0, index: 0)
        enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        enc.endEncoding()

        cmd.present(drawable)
        cmd.commit()
    }
}

/// Ein NSView mit CAMetalLayer-Backing. Nimmt keine Maus-Events an.
private final class MetalPassThroughView: NSView {

    let metalLayer: CAMetalLayer?

    init(device: MTLDevice) {
        self.metalLayer = CAMetalLayer()
        super.init(frame: .zero)
        wantsLayer = true
        if let ml = metalLayer {
            ml.device = device
            ml.pixelFormat = .bgra8Unorm
            ml.framebufferOnly = true
            ml.contentsScale = 1.0
            // setFrameSize wird das drawableSize setzen
            layer = ml
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        metalLayer?.drawableSize = newSize
    }

    // Klicks durchreichen.
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { false }
    override func mouseDown(with event: NSEvent) {}
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}
