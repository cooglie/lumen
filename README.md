# 🌌 Lumen

> **Licht trifft Bewegung.** Eine Open-Source macOS-Menüleisten-App, die deinen Desktop in eine lebende Leinwand verwandelt — durch GPU-Shader-Hintergründe und choreografierte Fenster-Performances.



- **🪐 Aurora** 
- **🎭 Mosaic**

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



## 📦 Build

```bash
swift build
swift run Lumen
```





## 📜 Lizenz

MIT — siehe [LICENSE](LICENSE).
