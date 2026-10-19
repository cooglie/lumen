# Sicherheits-Audit

Stand: P0-Härtung abgeschlossen · Audit von Shell-Aufrufen, externen Prozessen,
Shader-Ladepfad, Accessibility und Netzwerkzugriffen.

---

## 1. Shell-Aufrufe & externe Prozesse (P0.4) — ✅ Sauber

**Befund:** Lumen verwendet **keine** Shell-Aufrufe und startet **keine** externen Prozesse.

Geprüft (Stand P0):

| Muster | Treffer in .swift | Bewertung |
|---|---|---|
| `Process(` / `NSTask` | 0 | Keine Prozessstarts |
| `system(` / `popen(` | 0 | Keine C-Runtime-Shell-Aufrufe |
| `/bin/sh` / `/bin/bash` | 0 | Keine Shell-Pfade |
| `shell:` (Swift Regex/Process) | 0 | — |
| `URLSession` / `URLRequest` | 0 | Keine Netzwerkzugriffe (siehe §3) |
| `WKWebView` | 0 | Keine Web-Views |
| `dlopen` / `dlsym` | 0 | Kein dynamisches Laden von Bibliotheken |
| `ProcessInfo.processInfo.processIdentifier` | 1 | **Unbedenklich** — reiner Lesezugriff auf eigene PID, wird in `WindowService.allVisibleWindows()` verwendet, um das eigene Fenster von der Enumeration auszuschließen. Startet keinen Prozess. |

### Richtlinie für künftige Änderungen

- **Native APIs bevorzugen.** Für Dateioperationen `FileManager`, für JSON `JSONDecoder`, für Prozesse — falls jemals nötig — `Process` mit **festen** ausführbaren Pfaden und **getrennten Argumenten** (nie `launchPath = "/bin/sh" -c "..."`).
- **Keine Interpolation** von Dateinamen, Shader-Metadaten, JSON-Inhalten oder Fensterprofilen in Befehlsstrings.
- **Nutzereingaben** dürfen niemals in einen Prozess-Aufruf gelangen.
- Falls ein externer Prozess unvermeidbar wird: Pfad härteten (`Bundle.main.url(forResource:)`), Argumente als Array, Output-Capture ohne Shell.

**Akzeptanzkriterium erfüllt:** Keine durch Dateinamen, Shader-Metadaten, JSON oder Fensterprofile steuerbare Kommandoausführung.

---

## 2. Shader-Ladepfad (P0.2) — ✅ Abgesichert

Siehe `ShaderPackLoader.swift` und `ShaderSafety`. Maßnahmen:

- **Dateityp-Limit:** Nur `.metal` wird akzeptiert (Endung geprüft).
- **Größen-Limit:** Max. 256 KB pro Datei, 512 KB kombiniert. Verhindert Speicher-DoS.
- **Path-Traversal-Schutz:** Dateinamen werden gegen `/`, `\`, `..`, führende `.` und Null-Bytes validiert. `Bundle.main.url(forResource:)` sucht ohnehin nur im Bundle.
- **Symlink-Schutz:** Jede Datei-URL wird aufgelöst (`resolvingSymlinksInPath`) und geprüft, ob sie innerhalb des Bundle-Ressourcen-Verzeichnisses liegt (`isFileInside`).
- **NULL-Byte-Check:** Shader-Quelltext mit eingebetteten Null-Bytes wird abgelehnt.
- **Fehlerbehandlung:** Alle Fehler (Lesen, Kompilieren, Pipeline) werden abgefangen und geloggt — die App stürzt nicht ab, sondern lädt keinen Shader.
- **Keine Metadaten-Ausführung:** Shader-Metadaten (Name, Funktionsname, Dateiname) werden **nicht** in Shell-Befehle oder Dateipfade interpoliert. Der Funktionsname geht ausschließlich an `library.makeFunction(name:)`.

### Was Metal-Shader können (und nicht)

**Können:** GPU-Speicher (Textures/Buffer, die der Renderer übergibt) lesen/schreiben, mathematische Berechnungen ausführen, auf Uniforms (Zeit, Auflösung) zugreifen.

**Können nicht:** Dateisystem-Zugriff, Netzwerk, Prozesse starten, Shell-Befehle, Accessibility-APIs, beliebigen CPU-Code ausführen.

**Risiko fremder Shader:** GPU-Ressourcen-DoS, GPU-Hang (endlose Schleifen), ungültige Pixel. **Kein** CPU-Code, keine Systemkompromittierung. Nutzer-Import ist derzeit nicht implementiert; wenn er kommt, gelten fremde Shader als nicht vertrauenswürdig.

**Akzeptanzkriterium erfüllt:** Ein manipuliertes Shader-Paket kann keine beliebigen Dateien überschreiben, keine zusätzlichen Prozesse starten und die App nicht durch triviale Eingaben dauerhaft blockieren.

---

## 3. Netzwerkzugriffe & Telemetrie (P1) — ✅ Offline

Lumen baut **keine** Netzwerkverbindungen auf. Kein `URLSession`, kein Update-Check, kein Telemetrie-Endpoint, kein Download fremder Ressourcen. Die App funktioniert vollständig offline.

---

## 4. Accessibility (P0.3) — ✅ Minimiert & transparent

- **Wallpaper-Modus (Aurora):** Funktioniert **ohne** Accessibility-Berechtigung. Startet automatisch, fragt nie nach AX.
- **Mosaic (Fenstersteuerung):** AX wird **lazy** angefordert — nur wenn der Nutzer aktiv eine Choreografie startet und die Berechtigung fehlt.
- **Erklärung vor Prompt:** `AccessibilityPrompt.explainAndRequest()` zeigt eine `NSAlert`, die erklärt: welche Rechte, wofür, dass Aurora sie nicht braucht, dass widerrufbar. Erst danach erscheint der System-Prompt.
- **Menü-Status:** Das Mosaic-Menü zeigt den AX-Status (`✓ Bedienhilfen aktiv` / `⚠ fehlen`), damit der Nutzer vorab weiß, ob die Funktion bereit ist.
- **Keine automatisierten Eingaben:** Lumen verschiebt ausschließlich Fenster (`kAXPositionAttribute`/`kAXSizeAttribute`). Keine Tastatur-, Klick- oder Scroll-Simulation.

**Akzeptanzkriterium erfüllt:** Lumen funktioniert im reinen Wallpaper-Modus ohne Accessibility-Berechtigung und fragt nicht schon beim ersten Start unnötig danach.

---

## 5. Quarantäne (P0.1) — ✅ Entfernt

`build.sh` entfernt den `com.apple.quarantine`-Marker **nicht mehr**. Gatekeeper-Checks bleiben aktiv. Unsignierte Builds werden als solche behandelt (Hinweis im Build-Output). Für verteilbare Builds: Signierung + Notarisierung (P2).

---

## 6. Noch offen (P1 / P2)

- **P1.5 — JSON-Validation:** Choreografien-JSON mit striktem Schema validieren (Größe, Aktionszahl, numerische Limits, keine Endlosschleifen).
- **P1.7 — Sicherheits-Tests:** Automatisierte Tests für manipulierte Shader-Pakete, fehlerhafte JSON, ungültige Pfade.
- **P1.8 — Renderer/AX-Trennung:** GPU-Renderer unabhängig von AX-Code halten (architektonisch bereits gegeben: Aurora ↔ Mosaic sind getrennt).
- **P2 — Signierung & Notarisierung, Doku, reproduzierbare Builds.**
