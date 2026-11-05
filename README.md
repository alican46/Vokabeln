# Ferheng – Kurdisch lernen ☀️

Native iPhone-App (Swift/SwiftUI, ab iOS 17) zum Lernen von Kurdisch (Kurmancî) und eigenen Vokabeln.
*„Ferheng“ heißt auf Kurdisch „Wörterbuch“.*

## Funktionen

- **Ordner & Unterordner**: Ordne deine Vokabeln beliebig tief nach Themen.
- **Ordner zusammenfügen**:
  - *Verknüpfen*: Du bekommst einen neuen Sammel-Ordner aus mehreren Ordnern. Die Originale bleiben bestehen und der Lernfortschritt ist geteilt.
  - *Zusammenführen*: Alle Wörter werden in einen neuen Ordner verschoben, die alten Ordner werden entfernt.
- **Lernt mit dir mit (Spaced Repetition)**: Die App merkt sich für jedes Wort, wie oft du es richtig oder falsch hattest. Schwere Wörter kommen öfter, leichte seltener. Wörter, die du sofort konntest, springen direkt weit nach hinten.
- **Lernmodi**: Smart lernen (fällige und neue Wörter), Schwierige Wörter, Freies Üben (gewichtet nach Schwierigkeit) und Verb-Trainer.
- **Abfragearten**: Karteikarte, Auswahl (Multiple Choice), Schreiben (tolerant bei Tippfehlern und mit Tasten für ê î û ç ş) oder gemischt. Du kannst in beide Richtungen abfragen.
- **Verb-Trainer**: Pro Verb fragt die App Präsensstamm, Präsens, Vergangenheit, Imperativ und Futur einzeln ab. Du kannst außerdem markieren, ob ein Verb transitiv oder intransitiv ist (wichtig für die Ergativ-Konstruktion).
- **Nomen**: Geschlecht (m/f) und Plural, wichtig für die Ezafe.
- **Beispielsätze & Eselsbrücken** zu jedem Wort.
- **Wörter fotografieren**: Du fotografierst eine Vokabelliste, z. B. aus dem Lernbuch. Die App erkennt die Wortpaare, du prüfst und korrigierst sie, und erst nach deiner Bestätigung werden sie eingefügt. In der iPhone-App läuft die Erkennung offline mit Apple Vision, in der Web-App auf dem Gerät mit Tesseract (dafür ist Internet nötig).
- **Mehrere Wörter auf einmal einfügen**, eins pro Zeile, z. B. `av = Wasser`.
- **Statistik**: Serie, Tagesziel, Diagramm der letzten 14 Tage, Liste der schweren und der sofort gewussten Wörter.
- **Grammatik-Spickzettel**: Aussprache, Pronomen, Kopula, Verben, Imperativ, Ergativ, Futur, Verneinung, Ezafe.
- **Backup** als Datei, z. B. in iCloud Drive, und Wiederherstellen.
- Dunkelmodus und Haptik-Feedback. Die App läuft komplett offline.

## 🌐 Web-Version (ohne Kabel, ohne PC)

Im Ordner `web/` liegt dieselbe App als Web-App. Sie wird über Safari auf dem Home-Bildschirm installiert und verhält sich dann wie eine normale App: eigenes Icon, Vollbild, funktioniert offline. Updates kommen automatisch, und es gibt **kein 7-Tage-Limit**.

**Adresse:** https://alican46.github.io/Vokabeln/

### Einmalig einrichten (auf GitHub, geht auch am Handy im Browser)
1. Repo öffentlich machen: **Settings → General → Danger Zone → Change visibility → Make public**.
2. **Settings → Pages → Build and deployment → Source: „GitHub Actions“** auswählen.
3. **Actions → „Web-App veröffentlichen“ → Run workflow** tippen (oder einfach auf das nächste Update warten).

### Auf dem iPhone installieren
1. Die Adresse oben in **Safari** öffnen.
2. Unten auf **Teilen** (Quadrat mit Pfeil) tippen → **„Zum Home-Bildschirm“** → **Hinzufügen**.
3. Ab jetzt Ferheng über das Icon auf dem Home-Bildschirm starten.

### Gut zu wissen
- Deine Daten liegen nur auf deinem iPhone, im Speicher der Web-App. Mach ab und zu unter *Mehr → Backup erstellen* eine Sicherung.
- Backups sind mit der iPhone-App (SideStore) **austauschbar**. Du kannst also jederzeit zwischen den Versionen wechseln.
- Updates: Wenn eine neue Version veröffentlicht ist, lädt die App sie beim nächsten Öffnen automatisch, solange Internet da ist.

## Auf das iPhone bringen (kostenlos mit SideStore)

SideStore ist eine App für das iPhone, mit der du Apps direkt auf dem Handy installierst und aktualisierst. Den PC brauchst du **nur einmal** für die Einrichtung.

> ⚠️ Die Programme rund um SideStore ändern sich gelegentlich (Namen, Downloads). Falls ein Schritt unten nicht mehr passt, gilt die offizielle Anleitung: **https://docs.sidestore.io**

### Voraussetzungen
- iPhone mit iOS 17 oder neuer
- Ein PC (Windows, Mac oder Linux) und ein USB-Kabel
- Eine Apple-ID. Eine zusätzliche, nur dafür angelegte Apple-ID ist empfehlenswert, aber nicht nötig.
- Dieses GitHub-Repository muss **öffentlich** sein (siehe unten), damit SideStore die Updates herunterladen kann.

### Einmalige Einrichtung
1. **iPhone:** Lade im App Store die App [**LocalDevVPN**](https://apps.apple.com/app/localdevvpn/id6755608044). SideStore braucht sie, um ohne PC zu installieren und zu erneuern.
2. **PC (nur Windows):** Installiere [**iTunes von der Apple-Webseite**](https://www.apple.com/itunes/download/win64). Darüber erkennt der PC das iPhone.
3. **PC:** Lade das Installationsprogramm **iloader** herunter und installiere es. Windows: [iloader-windows-x64.msi](https://github.com/nab138/iloader/releases/latest/download/iloader-windows-x64.msi), Mac: [iloader-darwin-universal.dmg](https://github.com/nab138/iloader/releases/latest/download/iloader-darwin-universal.dmg).
4. Schließe das iPhone per Kabel an, entsperre es und tippe auf **„Vertrauen“**.
5. Starte iloader, melde dich mit deiner Apple-ID an und wähle dein iPhone und dann **„Install SideStore (Stable)“**. iloader installiert SideStore und richtet die nötige Kopplungsdatei („Pairing File“) ein.
6. **iPhone:**
   - *Einstellungen → Datenschutz & Sicherheit → Entwicklermodus* einschalten. Das iPhone startet danach neu.
   - *Einstellungen → Allgemein → VPN & Geräteverwaltung* → deiner Apple-ID **vertrauen**.
7. Öffne **LocalDevVPN** und tippe auf **Verbinden**. Öffne dann **SideStore** und melde dich mit derselben Apple-ID an.

Ab hier brauchst du den PC nicht mehr.

### Ferheng installieren
1. Öffne in SideStore den Tab **Quellen (Sources)**, tippe auf **＋** und füge diese Adresse ein:
   ```
   https://github.com/alican46/Vokabeln/releases/latest/download/source.json
   ```
2. Öffne den Tab **Durchsuchen (Browse)** → **Ferheng** → **Installieren**.

### Updates
- Wenn es eine neue Version gibt, erscheint sie in SideStore unter **Meine Apps** → **Aktualisieren** tippen. LocalDevVPN muss dabei verbunden sein.
- Deine Vokabeln und dein Lernfortschritt bleiben bei Updates erhalten. Lösche die App also nicht vorher.
- Unter *Mehr → Version* in Ferheng siehst du, welche Version installiert ist.

### Alle 7 Tage erneuern (wichtig!)
Mit einer kostenlosen Apple-ID läuft eine installierte App nur 7 Tage. Öffne deshalb mindestens einmal pro Woche **LocalDevVPN (verbinden)** und dann **SideStore** → **Meine Apps** → **Alle erneuern (Refresh All)**.
Tipp: Mit der Kurzbefehle-App kannst du dafür eine tägliche Automation anlegen.

Wenn du es doch vergisst, startet die App nicht mehr. Dann einfach in SideStore erneuern. Deine Daten sind weiterhin da.

### Sicherheitsnetz: Backup
Ab und zu unter *Mehr → Backup erstellen* sichern, z. B. in iCloud Drive. Falls du die App einmal neu installieren musst, kannst du alles wiederherstellen.

## Repository öffentlich machen (einmalig)
SideStore kann nur von öffentlichen Adressen laden. Auf GitHub: **Settings → General → ganz unten „Danger Zone“ → Change visibility → Make public**.
Im Code stehen keine Passwörter oder persönlichen Daten, denn deine Vokabeln liegen nur auf deinem iPhone. Nebeneffekt: Bei öffentlichen Repos sind die GitHub-Builds kostenlos und unbegrenzt.

## Wie eine neue Version entsteht (für Entwickler)
1. Code ändern.
2. Die Zahl in der Datei `VERSION` erhöhen, z. B. `1.0.0` → `1.1.0`.
3. Pushen. Der Workflow **Release (SideStore-Update)** baut die App, erstellt das GitHub-Release mit `Ferheng.ipa` und `source.json`, und SideStore zeigt das Update an.

Ohne SideStore geht es auch mit Xcode auf einem Mac (Projekt öffnen, iPhone anschließen, ▶︎) oder mit Sideloadly und der `.ipa` aus dem neuesten Release.

## Projektstruktur

```
web/                      Web-Version (HTML/CSS/JS, läuft ohne Build-Schritt)
  index.html, styles.css  Oberfläche
  app.js                  Logik (gleicher Algorithmus & Datenformat wie iOS)
  content.js              Startvokabeln & Grammatik
  sw.js                   Offline-Unterstützung & automatische Updates
Ferheng.xcodeproj         Xcode-Projekt (Xcode 16 oder neuer)
Ferheng/
  FerhengApp.swift        App-Start, Tabs, Willkommensbildschirm
  Models.swift            Datenmodelle (Ordner, Wörter, Lernstand …)
  SRS.swift               Wiederholungs-Algorithmus & Antwortprüfung
  Store.swift             Speicherung, Ordner-Logik, Zusammenfügen, Lernrunden
  HomeView.swift          „Heute“: Tagesziel, Serie, Wort des Tages
  FoldersView.swift       Ordner-Übersicht & Detailansicht
  Editors.swift           Wort-/Ordner-Editor, Mehrfach-Eingabe, Zusammenfügen
  LearnSetupView.swift    Auswahl von Lernmodus & Abfrageart
  SessionView.swift       Die Lernrunde (Karteikarte, Auswahl, Schreiben)
  StatsView.swift         Statistik mit Diagrammen
  GrammarView.swift       Grammatik-Spickzettel
  SettingsView.swift      Einstellungen & Backup
  StarterPack.swift       Beispielvokabeln
  Grammar.swift           Grammatik-Inhalte
```

Die Daten werden lokal als JSON im Dokumente-Ordner der App gespeichert.
