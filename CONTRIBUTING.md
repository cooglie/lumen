# 🤝 Zu Lumen beitragen

Danke, dass du Lumen verbessern willst! Lumen lebt von zwei Communitys:
**Shader-Künstlern** (Aurora) und **Choreografen** (Mosaic).

## 🧩 Wie du beitragen kannst

### 1. Shader beisteuern (Aurora)
- Schreibe einen Metal-Fragment-Shader im Stil von `Sources/Lumen/Resources/Shaders/Nebula.metal`
- Nutze den Vertex-Shader & `VertexOut` aus `Common.metal`
- Dein Fragment erhält UV (`in.uv`, 0..1) und die Zeit (`time`, Sekunden, `buffer(0)`)
- Füge einen Eintrag in `ShaderPackLoader.bundled` hinzu
- Öffne einen PR mit dem Shader + einem GIF/Screenshot

### 2. Choreografien beisteuern (Mosaic)
- Erstelle eine `.lumen-choreography.json` (Vorlage in `Resources/Choreographies/`)
- Beschreibe Layout, Parameter und Hotkey
- Öffne einen PR

### 3. Code beisteuern
- Swift 5.7+, macOS 12+
- Bitte kein Xcode-spezifischer Code, der SPM bricht (wir bleiben SPM-kompatibel)
- Neue öffentliche Typen bekommen eine Doku-Kommentar

## 🔄 Workflow

1. **Issue aufmachen** für größere Änderungen (damit nichts doppelt gebaut wird)
2. **Branch**: `feat/<name>` oder `fix/<name>`
3. **Commit-Style**: Conventional Commits — `feat:`, `fix:`, `shader:`, `choreo:`, `docs:`
4. **PR** gegen `main`
5. Wir mergen nach Review

## 🏗️ Lokal bauen

```bash
swift build
swift run Lumen
```

> Hinweis: Vollständige Wallpaper-/Accessibility-Funktionen brauchen Xcode + TCC-Berechtigungen.
> Das SPM-Gerüst dient der Modul-Entwicklung.

## 📜 Lizenz-Beitrag

By submitting a pull request, you agree that your contribution is licensed under the MIT license.

## 💬 Kontakt

- Issues für Bugs & Features
- Discussions für Ideen & Shader-Showcases

Danke! 🌌🎭
