import SwiftUI

struct GrammarView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Grammar.sections) { section in
                        NavigationLink(value: section) {
                            HStack(spacing: 14) {
                                Text(section.emoji)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(Theme.brand.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                Text(section.title).font(.body.weight(.medium))
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } footer: {
                    Text("Spickzettel für Kurmancî (Nordkurdisch).")
                }
            }
            .navigationTitle("Grammatik")
            .navigationDestination(for: GrammarSection.self) { section in
                GrammarDetailView(section: section)
            }
        }
    }
}

struct GrammarDetailView: View {
    let section: GrammarSection

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(section.emoji).font(.system(size: 54))
                ForEach(Array(section.blocks.enumerated()), id: \.offset) { _, block in
                    blockView(block)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(section.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func blockView(_ block: GrammarBlock) -> some View {
        switch block {
        case .text(let s):
            Text(LocalizedStringKey(s))
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        case .bullets(let items):
            VStack(alignment: .leading, spacing: 10) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Circle().fill(Theme.brand).frame(width: 6, height: 6)
                        Text(LocalizedStringKey(item))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .cardStyle()
        case .table(let rows):
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(Array(row.enumerated()), id: \.offset) { col, cell in
                            Text(LocalizedStringKey(cell))
                                .font(col == 0 ? .subheadline.weight(.medium) : .subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(index % 2 == 0 ? Color.clear : Theme.brand.opacity(0.05))
                }
            }
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}
