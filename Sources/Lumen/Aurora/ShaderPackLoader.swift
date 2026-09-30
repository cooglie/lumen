import Foundation

/// Beschreibt einen Shader (Name + Quelldatei). Später erweitert um
/// Uniforms (Zeit, Batterie, Helligkeit) und Metadaten (Autor, Lizenz).
struct ShaderDescriptor: Equatable {
    let name: String
    let sourcePath: String?
}

/// Lädt Shader aus dem App-Bundle (Resources/Shaders) und später aus
/// `.lumen-shader` Bundles, die Nutzer hinzufügen.
enum ShaderPackLoader {

    static func loadBundledShaders() -> [ShaderDescriptor] {
        let bundled = ["Nebula", "AuroraBorealis", "PlasmaField"]
        return bundled.map { name in
            let path = Bundle.main.url(forResource: name, withExtension: "metal", subdirectory: "Shaders")?.path
            return ShaderDescriptor(name: name, sourcePath: path)
        }
    }

    static func loadUserPacks(from directory: URL) -> [ShaderDescriptor] {
        // TODO: ~/.lumen/shaders/ scannen nach .lumen-shader Bundles
        return []
    }
}
