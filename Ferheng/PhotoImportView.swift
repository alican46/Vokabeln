import SwiftUI
import PhotosUI
import Vision
import UIKit

// MARK: - Texterkennung (Apple Vision, läuft komplett auf dem Gerät)

struct OCRWord {
    let text: String
    let x0: CGFloat, x1: CGFloat, y0: CGFloat, y1: CGFloat
    var yc: CGFloat { (y0 + y1) / 2 }
    var xc: CGFloat { (x0 + x1) / 2 }
}

enum TextRecognizer {
    enum Failure: Error { case noImage }

    static func recognize(_ image: UIImage) async throws -> [OCRWord] {
        try await Task.detached(priority: .userInitiated) {
            try TextRecognizer.recognizeSync(image)
        }.value
    }

    fileprivate static func recognizeSync(_ image: UIImage) throws -> [OCRWord] {
        guard let cg = image.cgImage else { throw Failure.noImage }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        // Kurdisch gibt es nicht direkt – Deutsch, Französisch (ê î û) und Türkisch (ç ş) decken alle Zeichen ab.
        let wanted = ["de-DE", "fr-FR", "tr-TR", "en-US"]
        let supported = (try? request.supportedRecognitionLanguages()) ?? []
        let languages = wanted.filter { supported.contains($0) }
        if !languages.isEmpty { request.recognitionLanguages = languages }

        let handler = VNImageRequestHandler(cgImage: cg, orientation: CGImagePropertyOrientation(image.imageOrientation))
        try handler.perform([request])

        let width = image.size.width * image.scale
        let height = image.size.height * image.scale
        var words: [OCRWord] = []
        for observation in request.results ?? [] {
            guard let candidate = observation.topCandidates(1).first else { continue }
            let s = candidate.string
            var index = s.startIndex
            while index < s.endIndex {
                while index < s.endIndex, s[index].isWhitespace { index = s.index(after: index) }
                let start = index
                while index < s.endIndex, !s[index].isWhitespace { index = s.index(after: index) }
                guard start < index else { continue }
                let range = start..<index
                let box = (try? candidate.boundingBox(for: range))?.boundingBox ?? observation.boundingBox
                words.append(OCRWord(
                    text: String(s[range]),
                    x0: box.minX * width, x1: box.maxX * width,
                    y0: (1 - box.maxY) * height, y1: (1 - box.minY) * height
                ))
            }
        }
        return words
    }
}

extension CGImagePropertyOrientation {
    init(_ o: UIImage.Orientation) {
        switch o {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

// MARK: - Aus Wörtern Vokabelpaare machen

struct ImportRow: Identifiable, Hashable {
    let id = UUID()
    var kurdish: String
    var german: String
    var selected: Bool
}

enum VocabParser {
    private static let separatorToken = try! NSRegularExpression(pattern: "^[-–—=:;|>→]+$")
    private static let junk = try! NSRegularExpression(pattern: "^[|_~•·*©®°^`´'\"]+$")
    private static let headingWords = try! NSRegularExpression(
        pattern: "\\b(lektion|kapitel|seite|übung|wortschatz|vokabeln?|ders|beş|rûpel|peyv|ferheng|unit|lesson)\\b",
        options: [.caseInsensitive])

    private static func matches(_ re: NSRegularExpression, _ s: String) -> Bool {
        re.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) != nil
    }

    private static func median(_ values: [CGFloat]) -> CGFloat {
        let sorted = values.sorted()
        return sorted.isEmpty ? 0 : sorted[sorted.count / 2]
    }

    private struct Row {
        var yc: CGFloat
        var words: [OCRWord]
        var height: CGFloat = 0
    }

    private struct Pair {
        var kurdish: String
        var german: String
        var yc: CGFloat
        var heading: Bool
    }

    static func rows(from rawWords: [OCRWord]) -> [ImportRow] {
        let words = rawWords
            .map { OCRWord(text: $0.text.trimmed, x0: $0.x0, x1: $0.x1, y0: $0.y0, y1: $0.y1) }
            .filter { !$0.text.isEmpty && !matches(junk, $0.text) }
        guard !words.isEmpty else { return [] }
        let h = max(1, median(words.map { $0.y1 - $0.y0 }))

        // 1) Zeilen bilden
        var rows: [Row] = []
        for w in words.sorted(by: { $0.yc < $1.yc }) {
            if let i = rows.firstIndex(where: { abs($0.yc - w.yc) < h * 0.7 }) {
                rows[i].words.append(w)
                let n = CGFloat(rows[i].words.count)
                rows[i].yc = (rows[i].yc * (n - 1) + w.yc) / n
            } else {
                rows.append(Row(yc: w.yc, words: [w]))
            }
        }
        rows.sort { $0.yc < $1.yc }
        for i in rows.indices {
            rows[i].words.sort { $0.x0 < $1.x0 }
            rows[i].height = rows[i].words.map { $0.y1 - $0.y0 }.max() ?? h
        }
        let rowH = median(rows.map(\.height))

        // 2) Gemeinsame Spaltengrenze finden
        var splits: [CGFloat] = []
        for r in rows where r.words.count > 1 {
            for i in 0..<(r.words.count - 1) {
                let gap = r.words[i + 1].x0 - r.words[i].x1
                if gap > h * 1.6 { splits.append((r.words[i].x1 + r.words[i + 1].x0) / 2) }
            }
        }
        let colX: CGFloat? = (splits.count >= 2 && Double(splits.count) >= Double(rows.count) * 0.25) ? median(splits) : nil

        // 3) Zeilen aufteilen
        var pairs: [Pair] = rows.map { r in
            let ws = r.words
            let joined = ws.map(\.text).joined(separator: " ")
            let bigOrTitle = r.height > rowH * 1.6 || matches(headingWords, joined)
            var left: [OCRWord] = ws
            var right: [OCRWord] = []
            if let sep = ws.indices.first(where: { $0 > 0 && $0 < ws.count - 1 && matches(separatorToken, ws[$0].text) }) {
                left = Array(ws[..<sep]); right = Array(ws[(sep + 1)...])
            } else if joined.range(of: "[=;]|\\s[-–—]\\s", options: .regularExpression) != nil,
                      let pair = AppStore.splitLine(joined) {
                return mark(clean(pair.0, pair.1), yc: r.yc, bigOrTitle: bigOrTitle)
            } else if let colX {
                left = ws.filter { $0.xc < colX }; right = ws.filter { $0.xc >= colX }
            } else if ws.count > 1 {
                var best = 0
                var bestGap = -CGFloat.infinity
                for i in 0..<(ws.count - 1) {
                    let gap = ws[i + 1].x0 - ws[i].x1
                    if gap > bestGap { bestGap = gap; best = i }
                }
                if bestGap > h * 1.6 { left = Array(ws[...best]); right = Array(ws[(best + 1)...]) }
            }
            return mark(clean(left.map(\.text).joined(separator: " "), right.map(\.text).joined(separator: " ")),
                        yc: r.yc, bigOrTitle: bigOrTitle)
        }

        // 4) Halbe Zeilen zusammenführen (schiefe Fotos)
        if pairs.count > 1 {
            for i in 0..<(pairs.count - 1) where abs(pairs[i + 1].yc - pairs[i].yc) <= h * 1.4 {
                if !pairs[i].kurdish.isEmpty && pairs[i].german.isEmpty && !pairs[i + 1].german.isEmpty && pairs[i + 1].kurdish.isEmpty {
                    pairs[i].german = pairs[i + 1].german; pairs[i + 1].german = ""
                } else if pairs[i].kurdish.isEmpty && !pairs[i].german.isEmpty && !pairs[i + 1].kurdish.isEmpty && pairs[i + 1].german.isEmpty {
                    pairs[i].kurdish = pairs[i + 1].kurdish; pairs[i + 1].kurdish = ""
                }
            }
        }

        var result = pairs
            .filter { !$0.kurdish.isEmpty || !$0.german.isEmpty }
            .map { ImportRow(kurdish: $0.kurdish, german: $0.german,
                             selected: !$0.kurdish.isEmpty && !$0.german.isEmpty && !$0.heading) }
        if looksSwapped(result) {
            result = result.map { ImportRow(kurdish: $0.german, german: $0.kurdish, selected: $0.selected) }
        }
        return result
    }

    private static func mark(_ p: (String, String), yc: CGFloat, bigOrTitle: Bool) -> Pair {
        let hasDigit = (p.0 + p.1).rangeOfCharacter(from: .decimalDigits) != nil
        return Pair(kurdish: p.0, german: p.1, yc: yc, heading: bigOrTitle || hasDigit)
    }

    private static func clean(_ a: String, _ b: String) -> (String, String) {
        func strip(_ s: String) -> String {
            var t = s.trimmed
            t = t.replacingOccurrences(of: "^(\\d+[.)]|[a-zA-Z][.)]|[-–—•·*])\\s+", with: "", options: .regularExpression)
            t = t.replacingOccurrences(of: "^[-–—=:;|]+|[-–—=:;|,]+$", with: "", options: .regularExpression)
            return t.trimmed
        }
        return (strip(a), strip(b))
    }

    /// Steht Deutsch links und Kurdisch rechts?
    static func looksSwapped(_ rows: [ImportRow]) -> Bool {
        func count(_ s: String, _ pattern: String) -> Int {
            (try? NSRegularExpression(pattern: pattern))?.numberOfMatches(in: s, range: NSRange(s.startIndex..., in: s)) ?? 0
        }
        func kurdishScore(_ s: String) -> Int { count(s, "[êîûçşÊÎÛÇŞ]") }
        func germanScore(_ s: String) -> Int {
            count(s, "[äöüßÄÖÜ]|sch|ch(?!a)|ei|ie|tz") + (count(s.lowercased(), "^(der|die|das|ein|eine|sich)\\s") > 0 ? 2 : 0)
        }
        var left = 0, right = 0
        for r in rows {
            left += kurdishScore(r.kurdish) - germanScore(r.kurdish)
            right += kurdishScore(r.german) - germanScore(r.german)
        }
        return right > left
    }
}

// MARK: - Kamera

struct CameraPicker: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onImage(image) }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}

// MARK: - Ansicht

struct PhotoImportView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var folderSelection: UUID?
    @State private var type: WordType = .other
    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var image: UIImage?
    @State private var working = false
    @State private var message: String?
    @State private var rows: [ImportRow] = []
    @State private var reviewing = false

    init(folderID: UUID?) {
        _folderSelection = State(initialValue: folderID)
    }

    private var selectedCount: Int {
        rows.filter { $0.selected && !$0.kurdish.trimmed.isEmpty && !$0.german.trimmed.isEmpty }.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if reviewing { review } else { intro }
            }
            .navigationTitle(reviewing ? "Erkannte Wörter" : "Wörter fotografieren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                if reviewing {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("\(selectedCount) einfügen") { insert() }
                            .disabled(selectedCount == 0 || folderSelection == nil)
                            .fontWeight(.bold)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { process($0) }
                .ignoresSafeArea()
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: data) {
                    process(img)
                } else {
                    message = "Das Foto konnte nicht geladen werden."
                }
                pickerItem = nil
            }
        }
    }

    // MARK: Start

    private var intro: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    ZStack {
                        Circle().fill(Theme.brandGradient).frame(width: 110, height: 110)
                            .shadow(color: Theme.brand.opacity(0.35), radius: 20, y: 8)
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 20)
                }

                if working {
                    ProgressView("Text wird erkannt …")
                        .padding()
                } else {
                    Text("Fotografiere eine Vokabelliste – z. B. aus deinem Lernbuch. Am besten gerade von oben, gut beleuchtet, eine Spalte Kurdisch und eine Spalte Deutsch.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)

                    if let message {
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 12) {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            Button {
                                showCamera = true
                            } label: {
                                Label("Foto aufnehmen", systemImage: "camera.fill")
                            }
                            .buttonStyle(GradientButtonStyle())
                        }
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            Label("Aus Fotos auswählen", systemImage: "photo.on.rectangle")
                        }
                        .buttonStyle(SoftButtonStyle())
                    }
                }

                Text("Die Erkennung läuft komplett auf deinem iPhone – auch ohne Internet. Das Foto wird nicht gespeichert oder hochgeladen.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: Prüfen & bestätigen

    private var review: some View {
        Form {
            Section {
                HStack(spacing: 10) {
                    Button {
                        for i in rows.indices { (rows[i].kurdish, rows[i].german) = (rows[i].german, rows[i].kurdish) }
                    } label: {
                        Label("Spalten tauschen", systemImage: "arrow.left.arrow.right")
                    }
                    .buttonStyle(SoftButtonStyle())
                    Button {
                        let all = rows.allSatisfy(\.selected)
                        for i in rows.indices { rows[i].selected = !all }
                    } label: {
                        Text("Alle an/aus")
                    }
                    .buttonStyle(SoftButtonStyle(tint: .secondary))
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } footer: {
                Text("Prüfe die Wörter, korrigiere Fehler und wähle aus, was übernommen werden soll. Erst mit „Einfügen“ wird gespeichert.")
            }

            Section {
                ForEach($rows) { $row in
                    HStack(spacing: 10) {
                        Button {
                            row.selected.toggle()
                        } label: {
                            Image(systemName: row.selected ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(row.selected ? Theme.brand : Color(.tertiaryLabel))
                        }
                        .buttonStyle(.plain)
                        TextField("Kurdisch", text: $row.kurdish)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.body.weight(.semibold))
                        Divider()
                        TextField("Deutsch", text: $row.german)
                            .autocorrectionDisabled()
                    }
                }
                .onDelete { rows.remove(atOffsets: $0) }
                Button {
                    rows.append(ImportRow(kurdish: "", german: "", selected: true))
                } label: {
                    Label("Zeile hinzufügen", systemImage: "plus")
                }
            } header: {
                HStack {
                    Text("Kurdisch")
                    Spacer()
                    Text("Deutsch")
                    Spacer()
                }
                .padding(.leading, 34)
            }

            Section("Speichern in") {
                FolderPicker(title: "Ordner", selection: $folderSelection)
                Picker("Wortart", selection: $type) {
                    ForEach(WordType.allCases) { Text($0.label).tag($0) }
                }
            }

            Section {
                Button("Anderes Foto wählen") {
                    rows = []
                    reviewing = false
                    image = nil
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                ForEach(["ê", "î", "û", "ç", "ş"], id: \.self) { ch in
                    Button(ch) { insertIntoFocused(ch) }
                        .font(.title3)
                }
                Spacer()
            }
        }
    }

    /// Fügt ein Sonderzeichen ein, ohne die Tastatur zu schließen.
    private func insertIntoFocused(_ ch: String) {
        UIApplication.shared.sendAction(#selector(UIKeyInput.insertText(_:)), to: nil, from: ch, for: nil)
    }

    // MARK: Aktionen

    private func process(_ img: UIImage) {
        image = img
        working = true
        message = nil
        Task {
            do {
                let words = try await TextRecognizer.recognize(img)
                let parsed = VocabParser.rows(from: words)
                await MainActor.run {
                    working = false
                    if parsed.isEmpty {
                        message = "Keine Wörter erkannt. Versuch es mit einem schärferen, geraden Foto."
                    } else {
                        rows = parsed
                        reviewing = true
                    }
                }
            } catch {
                await MainActor.run {
                    working = false
                    message = "Die Texterkennung ist fehlgeschlagen. Bitte versuch es nochmal."
                }
            }
        }
    }

    private func insert() {
        guard let folderID = folderSelection else { return }
        for row in rows where row.selected && !row.kurdish.trimmed.isEmpty && !row.german.trimmed.isEmpty {
            store.cards.append(Card(folderID: folderID, kurdish: row.kurdish.trimmed, german: row.german.trimmed, type: type))
        }
        store.save()
        dismiss()
    }
}
