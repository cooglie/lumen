# 🌌 Lumen

> **Licht trifft Bewegung.** Eine Open-Source macOS-Menüleisten-App, die deinen Desktop in eine lebende Leinwand verwandelt — durch GPU-Shader-Hintergründe und choreografierte Fenster-Performances.

Lumen vereint zwei fancy Konzepte in einem nativen Mac-Projekt:

- **🪐 Aurora** — eine Shader-Wallpaper-Engine: Ersetze statische Desktop-Hintergründe durch fließende Metal-Shader (Nebel, Partikel, Tag/Nacht-Übergänge). Mit eingebautem Editor und Community-Sharen.
- **🎭 Mosaic** — Fenster-Choreografie: Kein Tiling-Manager, sondern Fenster als *Performance*. Hotkeys lassen alle Fenster in choreografierten Mustern gleiten — Spiralen, Gitter, Fächer — mit Physik (Federung, Trägheit).

---

## ✨ Vision

Die meisten Mac-Tools sind funktional und grau. Lumen macht den Desktop zu einem **Sinnesraum**: Dein Hintergrund atmet, deine Fenster tanzen. Beides ist nützlich *und* spektakulär — und beides lebt von einer Community, die Shader und Choreografien teilt.

## 🧩 Features

### Aurora — Shader-Wallpaper-Engine
- Live-Metal-Shader als Desktop-Hintergrund (pro Space/Monitor)
- Tag/Nacht-Übergänge, reaktiv auf Uhrzeit & Batterie
- Eingebauter Shader-Editor mit Live-Vorschau
- Shader-Pakete als GitHub-Repos teilbar (`.lumen-shader` Bundle)
- Geringer Energieverbrauch: pausiert bei vollem Bildschirm / Inaktivität

### Mosaic — Fenster-Choreografie
- Choreografierte Fenster-Bewegung mit Feder-Physik
- Vorlagen: Spiral, Grid, Fan, Cascade, Orbit
- Eigene Choreografien als JSON-Skripte
- Hotkeys pro Choreografie (z. B. ⌥⇧M = Mosaic-Mix)
- Nutzt Accessibility- & WindowServer-APIs

## 🏗️ Architektur

```
Sources/Lumen/
├── App/                  # @main Einstieg, AppDelegate, Menüleiste (NSStatusItem)
├── Aurora/               # Shader-Engine: Metal-Renderer, Wallpaper-Bridge
│   ├── Editor/           # Live-Shader-Editor
│   └── PackSystem/       # .lumen-shader Bundle-Loading
├── Mosaic/               # Fenster-Choreografie
│   ├── Choreography/     # JSON-Skripte & Built-in-Muster
│   ├── Physics/          # Feder-/Trägheits-Animationen
│   └── WindowAPI/        # AXUIElement / CGS Bindings
├── Core/                 # Gemeinsame Utilities (Hotkeys, Logger, Speicher)
└── UI/                   # SwiftUI-Panels (Glas, Vibrancy)
```

## 🚀 Roadmap

- [x] Repo-Setup & Architektur
- [ ] Aurora: Metal-Renderer + erstes Shader-Beispiel
- [ ] Aurora: Wallpaper-Bridge (`NSWorkspace`/Spaces)
- [ ] Aurora: Shader-Editor
- [ ] Mosaic: Window-Enumeration via Accessibility-API
- [ ] Mosaic: Physik-Engine & erste Choreografie (Grid)
- [ ] Core: Globaler Hotkey-Manager
- [ ] UI: Menüleisten-Dropdown + Settings
- [ ] v0.1 Release (Universal Binary, notarized)

## 🛠️ Tech-Stack

| Bereich | Technologie |
|---|---|
| Sprache | Swift 5.9+ |
| UI | SwiftUI + AppKit (Menüleiste) |
| Shader | Metal Shading Language (MSL) / GLSL→MSL |
| Fenster | `AXUIElement`, `CGS*` private APIs |
| Speicher | SwiftData / JSON |
| Bau | Swift Package Manager |

## 📦 Build

```bash
swift build
swift run Lumen
```

> Hinweis: Für Wallpaper- & WindowServer-APIs wird später ein signiertes Xcode-Projekt nötig (TCC-Berechtigungen). Das SPM-Gerüst dient der Modul-Entwicklung.

## 🤝 Beitragen

Lumen ist Open Source (MIT). Wir suchen besonders:
- **Shader-Künstler** für Aurora-Vorlagen
- **Choreografen** für Mosaic-Muster (JSON)
- Swift/Metal-Entwickler für die Engine

Siehe `CONTRIBUTING.md` (folgt).

## 📜 Lizenz

MIT — siehe [LICENSE](LICENSE).
