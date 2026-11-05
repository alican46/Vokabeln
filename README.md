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
- **Mehrere Wörter auf einmal einfügen**, eins pro Zeile, z. B. `av = Wasser`.
- **Statistik**: Serie, Tagesziel, Diagramm der letzten 14 Tage, Liste der schweren und der sofort gewussten Wörter.
- **Grammatik-Spickzettel**: Aussprache, Pronomen, Kopula, Verben, Imperativ, Ergativ, Futur, Verneinung, Ezafe.
- **Backup** als Datei, z. B. in iCloud Drive, und Wiederherstellen.
- Dunkelmodus und Haptik-Feedback. Die App läuft komplett offline.

## Auf das iPhone bringen

Apple erlaubt Apps nur über Xcode, TestFlight/App Store oder Sideloading. Je nachdem, was du hast, gibt es drei Wege:

### Weg A: Mit einem Mac (kostenlos, empfohlen)
1. Installiere **Xcode** aus dem Mac App Store.
2. Lade dieses Repository herunter und öffne `Ferheng.xcodeproj`.
3. Verbinde dein iPhone per Kabel. Aktiviere auf dem iPhone unter *Einstellungen → Datenschutz & Sicherheit* den **Entwicklermodus**.
4. Wähle in Xcode unter *Signing & Capabilities* bei „Team“ deine Apple-ID aus. Ändere bei Bedarf den Bundle Identifier, z. B. auf `com.deinname.ferheng`.
5. Wähle oben dein iPhone aus und drücke ▶︎.
6. Auf dem iPhone: *Einstellungen → Allgemein → VPN & Geräteverwaltung* → deinem Entwickler-Zertifikat vertrauen.

> Mit einer kostenlosen Apple-ID läuft die App **7 Tage**. Danach einfach erneut in Xcode auf ▶︎ drücken. Deine Daten bleiben dabei erhalten. Mit dem Apple-Developer-Programm (99 €/Jahr) gilt die Installation 1 Jahr lang. Darüber kannst du die App auch per TestFlight verteilen.

### Weg B: Ohne Mac (Windows-PC), per Sideloading
1. Öffne auf GitHub den Tab **Actions** → **iOS Build** → den neuesten erfolgreichen Durchlauf. Lade unten das Artefakt **Ferheng-ipa** herunter und entpacke es. Darin liegt die Datei `Ferheng.ipa`.
2. Installiere [Sideloadly](https://sideloadly.io) oder AltStore auf deinem PC.
3. Verbinde das iPhone, ziehe `Ferheng.ipa` in Sideloadly und melde dich mit deiner Apple-ID an.
4. Auf dem iPhone den Entwicklermodus aktivieren und dem Zertifikat vertrauen (siehe oben).

Auch hier gilt bei kostenloser Apple-ID: alle 7 Tage neu signieren. AltStore kann das automatisch erledigen.

### Weg C: Apple-Developer-Account + TestFlight
Mit einem kostenpflichtigen Developer-Account kannst du die App über Xcode archivieren und per TestFlight auf dein iPhone laden. Dort hält sie 90 Tage pro Build.

## Projektstruktur

```
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
