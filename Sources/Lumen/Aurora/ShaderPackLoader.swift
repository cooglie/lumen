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

// MARK: - Sicherheitskonstanten

/// Sicherheits-Limits für den Shader-Ladepfad.
/// Shader-Quelltext ist GPU-Code — er wird von Metal zur Laufzeit kompiliert
/// und kann (eingeschränkt) auf GPU-Ressourcen zugreifen. Daher werden alle
/// Eingaben begrenzt und validiert.
enum ShaderSafety {
    /// Maximale Größe einer einzelnen .metal-Quelldatei (256 KB).
    /// Ausreichend für komplexe Shader; verhindert ressourcenfressende Inputs.
    static let maxSourceBytes = 256 * 1024

    /// Maximale Größe des kombinierten Quelltexts (Common + Shader).
    static let maxCombinedBytes = 512 * 1024

    /// Erlaubte Dateiendung für Shader-Quelltext.
    static let allowedExtension = "metal"

    /// Maximale Länge eines Dateinamens (schutz vor Path-Traversal).
    static let maxFilenameLength = 128

    /// Validiert einen Dateinamen gegen Path-Traversal und ungültige Zeichen.
    /// - Parameter filename: Der zu prüfende Dateiname (kein Pfad!).
    /// - Returns: `true` wenn der Name sicher ist.
    static func isSafeFilename(_ filename: String) -> Bool {
        guard filename.count <= maxFilenameLength else { return false }
        guard !filename.isEmpty else { return false }

        // Keine Pfad-Trenner, keine relativen Pfade, keine Null-Bytes.
        if filename.contains("/") || filename.contains("\\") { return false }
        if filename.contains("..") { return false }
        if filename.contains("\0") { return false }
        if filename.hasPrefix(".") { return false } // versteckte/relative Pfade

        return true
    }
}

/// Lädt Shader-Quelltext aus dem App-Bundle und (später) aus Nutzer-Packs.
///
/// # Sicherheitshinweis: Metal-Shader
///
/// Metal-Shader sind GPU-Code, der zur Laufzeit kompiliert wird (`device.makeLibrary(source:)`).
/// Was Metal-Shader **können**:
/// - GPU-Speicher (Textures, Buffers) lesen/schreiben, die der Renderer ihnen übergibt
/// - Mathematische Berechnungen ausführen
/// - Auf Uniforms (z. B. Zeit, Auflösung) zugreifen
///
/// Was Metal-Shader **nicht** können:
/// - Dateisystem-Zugriffe (kein File I/O auf der GPU)
/// - Netzwerkverbindungen aufbauen
/// - Prozesse starten oder Shell-Befehle ausführen
/// - Auf Accessibility-APIs zugreifen
/// - Beliebigen CPU-Code ausführen
///
/// Lumen übergibt an Shader ausschließlich: Zeit-Uniform (Float), Vertex-Buffer (Vollbild-Quad),
/// und die Render-Target-Texture. Es werden **keine** Dateipfade, JSON, Shader-Metadaten
/// oder Nutzereingaben in den Shader-Quelltext interpoliert.
///
/// Fremde Shader (falls künftig Nutzer-Import unterstützt wird) sind als **nicht vertrauenswürdig**
/// zu behandeln. Sie könnten: GPU-Ressourcen erschöpfen (Ressourcen-DoS), endlose Schleifen
/// bauen (GPU-Hang), oder ungültige Pixel schreiben. Sie können jedoch **keinen** CPU-Code
/// ausführen oder das System kompromittieren.
enum ShaderPackLoader {

    static let bundled: [ShaderDescriptor] = [
        ShaderDescriptor(name: "Nebula",          fragmentFunction: "nebula_fragment",   sourceFile: "Nebula.metal"),
        ShaderDescriptor(name: "Aurora Borealis",  fragmentFunction: "aurora_fragment",  sourceFile: "AuroraBorealis.metal"),
        ShaderDescriptor(name: "Plasma Field",    fragmentFunction: "plasma_fragment",  sourceFile: "PlasmaField.metal"),
        ShaderDescriptor(name: "Starfield",       fragmentFunction: "starfield_fragment", sourceFile: "Starfield.metal"),
        ShaderDescriptor(name: "Lava Lamp",       fragmentFunction: "lavalamp_fragment", sourceFile: "LavaLamp.metal"),
        ShaderDescriptor(name: "Cyber Grid",      fragmentFunction: "cybergrid_fragment", sourceFile: "CyberGrid.metal"),
        ShaderDescriptor(name: "Ocean",           fragmentFunction: "ocean_fragment",    sourceFile: "Ocean.metal"),
        ShaderDescriptor(name: "Fireworks",       fragmentFunction: "fireworks_fragment", sourceFile: "Fireworks.metal"),
        ShaderDescriptor(name: "Voronoi",         fragmentFunction: "voronoi_fragment",   sourceFile: "Voronoi.metal"),
        ShaderDescriptor(name: "Rain Ripples",    fragmentFunction: "rainripples_fragment", sourceFile: "RainRipples.metal"),
        ShaderDescriptor(name: "Matrix Rain",     fragmentFunction: "matrixrain_fragment", sourceFile: "MatrixRain.metal"),
        ShaderDescriptor(name: "Kaleidoscope",    fragmentFunction: "kaleidoscope_fragment", sourceFile: "Kaleidoscope.metal"),
        ShaderDescriptor(name: "Sunset",           fragmentFunction: "sunset_fragment",    sourceFile: "Sunset.metal"),
        ShaderDescriptor(name: "Galaxy",           fragmentFunction: "galaxy_fragment",    sourceFile: "Galaxy.metal")
    ]

    /// Liefert den kombinierten Quelltext (Common + Shader) für makeLibrary(source:).
    /// Validiert Dateityp, Dateigröße und Pfad-Sicherheit vor dem Laden.
    /// - Parameter shader: Der zu ladende Shader-Deskriptor.
    /// - Returns: Quelltext oder `nil` bei Sicherheitsverstoß oder Lesefehler.
    static func source(for shader: ShaderDescriptor) -> String? {
        // 1. Dateinamen validieren (Path-Traversal-Schutz).
        guard ShaderSafety.isSafeFilename(shader.sourceFile) else {
            LumenLog.error("Shader-Dateiname abgelehnt (ungültig/Path-Traversal): \(shader.sourceFile)", category: "aurora")
            return nil
        }

        // 2. Dateiendung prüfen — nur .metal erlaubt.
        let ext = (shader.sourceFile as NSString).pathExtension.lowercased()
        guard ext == ShaderSafety.allowedExtension else {
            LumenLog.error("Shader-Datei abgelehnt (falscher Typ, nur .metal): \(shader.sourceFile)", category: "aurora")
            return nil
        }

        let dir = "Shaders"

        // 3. URLs aus Bundle auflösen. Bundle.main.url ist sicher gegen Path-Traversal,
        //    da es nur innerhalb des App-Bundles sucht.
        guard
            let commonURL = Bundle.main.url(forResource: "Common", withExtension: "metal", subdirectory: dir),
            let shaderURL = Bundle.main.url(forResource: shader.sourceFile, withExtension: nil, subdirectory: dir)
        else {
            LumenLog.error("Shader-Quelltext nicht gefunden: \(shader.sourceFile)", category: "aurora")
            return nil
        }

        // 4. Symlink-Schutz: Nur Dateien innerhalb des Bundle-Ressourcen-Verzeichnisses akzeptieren.
        guard let bundleResDir = Bundle.main.resourceURL else {
            LumenLog.error("Bundle-Ressourcenverzeichnis nicht verfügbar", category: "aurora")
            return nil
        }
        guard
            isFileInside(commonURL, base: bundleResDir),
            isFileInside(shaderURL, base: bundleResDir)
        else {
            LumenLog.error("Shader-Pfad liegt außerhalb des Bundles (möglicher Symlink-Angriff)", category: "aurora")
            return nil
        }

        // 5. Datei-Größen prüfen (vor dem Laden, um Speicher-DoS zu verhindern).
        guard
            let commonSize = fileSize(commonURL),
            let shaderSize = fileSize(shaderURL),
            commonSize <= ShaderSafety.maxSourceBytes,
            shaderSize <= ShaderSafety.maxSourceBytes,
            commonSize + shaderSize <= ShaderSafety.maxCombinedBytes
        else {
            LumenLog.error("Shader-Datei überschreitet Größenlimit (\(ShaderSafety.maxSourceBytes/1024)KB)", category: "aurora")
            return nil
        }

        // 6. Quelltext laden (UTF-8, Fehler explizit abfangen).
        let common: String, body: String
        do {
            common = try String(contentsOf: commonURL, encoding: .utf8)
            body   = try String(contentsOf: shaderURL, encoding: .utf8)
        } catch {
            LumenLog.error("Shader-Quelltext nicht lesbar: \(error)", category: "aurora")
            return nil
        }

        // 7. NULL-Byte-Check — verhindert verschleierten Code in Binär-Strings.
        if common.contains("\0") || body.contains("\0") {
            LumenLog.error("Shader-Quelltext enthält NULL-Bytes (abgelehnt)", category: "aurora")
            return nil
        }

        let combined = common + "\n" + body

        // 8. Finaler Größencheck des kombinierten Strings.
        guard combined.utf8.count <= ShaderSafety.maxCombinedBytes else {
            LumenLog.error("Kombinierter Shader-Quelltext überschreitet Größenlimit", category: "aurora")
            return nil
        }

        return combined
    }

    // MARK: - Helpers

    /// Prüft, ob eine Datei-URL (aufgelöst, inkl. Symlinks) innerhalb eines Basis-Verzeichnisses liegt.
    private static func isFileInside(_ fileURL: URL, base: URL) -> Bool {
        let resolved = fileURL.standardizedFileURL.resolvingSymlinksInPath()
        let basePath = base.standardizedFileURL.resolvingSymlinksInPath().path
        return resolved.path.hasPrefix(basePath + "/") || resolved.path == basePath
    }

    /// Liefert die Dateigröße in Bytes oder `nil` bei Fehler.
    private static func fileSize(_ url: URL) -> Int? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path) else { return nil }
        return attrs[.size] as? Int
    }
}
