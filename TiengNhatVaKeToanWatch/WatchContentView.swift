import SwiftUI

struct WatchContentView: View {
    @StateObject private var store = WatchStudyStore()
    @State private var selectedIndex = 0
    @State private var showsMeaning = false

    private var current: WatchVocab? {
        guard store.cards.indices.contains(selectedIndex) else { return nil }
        return store.cards[selectedIndex]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    countdownCard
                    if let current {
                        vocabCard(current)
                    } else {
                        Text("Đang tải từ vựng...")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    controls
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("N1")
        }
    }

    private var countdownCard: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(daysUntilJLPT)")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.green)
            Text("ngày tới JLPT 5/7")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.green.opacity(0.16), in: RoundedRectangle(cornerRadius: 14))
    }

    private func vocabCard(_ vocab: WatchVocab) -> some View {
        Button {
            showsMeaning.toggle()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(vocab.word)
                    .font(.title3.weight(.bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(vocab.reading)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if showsMeaning {
                    Text(vocab.meaning)
                        .font(.footnote)
                        .foregroundStyle(.primary)
                } else {
                    Text("Chạm để xem nghĩa")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
            .padding()
            .background(.yellow.opacity(0.16), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private var controls: some View {
        HStack {
            Button {
                selectedIndex = max(0, selectedIndex - 1)
                showsMeaning = false
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(selectedIndex == 0)

            Spacer()

            Text(store.cards.isEmpty ? "0/0" : "\(selectedIndex + 1)/\(store.cards.count)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                selectedIndex = min(max(store.cards.count - 1, 0), selectedIndex + 1)
                showsMeaning = false
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(selectedIndex >= store.cards.count - 1)
        }
    }

    private var daysUntilJLPT: Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        let now = calendar.startOfDay(for: Date())
        let target = calendar.date(from: DateComponents(year: 2026, month: 7, day: 5)) ?? Date()
        return max(calendar.dateComponents([.day], from: now, to: target).day ?? 0, 0)
    }
}
