import Foundation

struct WatchDictionaryDocument: Decodable {
    let vocabulary: [WatchVocab]
}

struct WatchVocab: Decodable, Identifiable {
    let word: String
    let reading: String
    let meaning: String
    let level: String?

    var id: String { "\(word)-\(reading)-\(meaning)" }
}

@MainActor
final class WatchStudyStore: ObservableObject {
    @Published private(set) var cards: [WatchVocab] = []

    init() {
        load()
    }

    private func load() {
        guard let url = Bundle.main.url(forResource: "WatchDictionary", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let document = try? JSONDecoder().decode(WatchDictionaryDocument.self, from: data) else {
            cards = []
            return
        }
        cards = document.vocabulary
    }
}
