import Foundation

struct StudyDictionaryDocument: Decodable {
    let vocabulary: [VocabularyEntry]
    let grammar: [GrammarEntry]
    let hanViet: [String: String]
}

struct VocabularyEntry: Decodable, Identifiable, Hashable {
    let word: String
    let reading: String
    let meaning: String
    let level: String

    var id: String { "\(level)-\(word)-\(reading)-\(meaning)" }
}

struct GrammarEntry: Decodable, Identifiable, Hashable {
    let pattern: String
    let meaning: String
    let aliases: [String]?

    var id: String { pattern }
    var searchTerms: [String] { [pattern] + (aliases ?? []) }

    static let supplemental: [GrammarEntry] = [
        GrammarEntry(pattern: "はずだ", meaning: "chắc là, lẽ ra phải; suy luận có căn cứ", aliases: ["はず", "はずです", "はずだった"]),
        GrammarEntry(pattern: "てくる", meaning: "dần trở nên; thay đổi từ trước đến nay", aliases: ["てきた", "てくる"]),
        GrammarEntry(pattern: "らしい", meaning: "có vẻ, nghe nói; suy đoán dựa trên thông tin", aliases: ["らしい", "らしく"]),
        GrammarEntry(pattern: "わけだ", meaning: "thảo nào, nghĩa là; kết luận từ lý do", aliases: ["わけ", "わけです"]),
        GrammarEntry(pattern: "わけではない", meaning: "không hẳn là, không có nghĩa là", aliases: ["わけではない", "わけじゃない"]),
        GrammarEntry(pattern: "わけにはいかない", meaning: "không thể làm vì hoàn cảnh/đạo lý không cho phép", aliases: ["わけにはいかない", "わけにもいかない"]),
        GrammarEntry(pattern: "に違いない", meaning: "chắc chắn là", aliases: ["に違いない"]),
        GrammarEntry(pattern: "かもしれない", meaning: "có thể, biết đâu", aliases: ["かもしれない"]),
        GrammarEntry(pattern: "ようだ", meaning: "có vẻ như, dường như", aliases: ["ようだ", "ようです"]),
        GrammarEntry(pattern: "べきだ", meaning: "nên, cần phải", aliases: ["べき", "べきだ", "べきではない"]),
        GrammarEntry(pattern: "というときに限って", meaning: "đúng vào lúc... thì lại; thường dùng cho việc không mong muốn", aliases: ["という時に限って", "ときに限って", "時に限って"]),
        GrammarEntry(pattern: "に限って", meaning: "chính vào/lại đúng; riêng... thì", aliases: ["に限って"])
    ]
}

@MainActor
final class StudyDictionaryStore: ObservableObject {
    @Published private(set) var vocabulary: [VocabularyEntry] = []
    @Published private(set) var grammar: [GrammarEntry] = []
    @Published private(set) var hanViet: [String: String] = [:]

    init() {
        load()
    }

    func vocabularyMatches(for question: PracticeQuestion, limit: Int = 6) -> [VocabularyEntry] {
        let haystack = studyText(for: question)
        var usedWords = Set<String>()
        return vocabulary
            .filter { entry in
                guard entry.word.count >= 2 || containsKanji(entry.word) else { return false }
                return haystack.contains(entry.word)
            }
            .sorted {
                if $0.word.count == $1.word.count { return $0.level < $1.level }
                return $0.word.count > $1.word.count
            }
            .filter { entry in
                if usedWords.contains(entry.word) { return false }
                usedWords.insert(entry.word)
                return true
            }
            .prefix(limit)
            .map { $0 }
    }

    func grammarMatches(for question: PracticeQuestion, limit: Int = 4) -> [GrammarEntry] {
        let haystack = studyText(for: question) + "\n" + (question.explanation ?? "")
        var usedPatterns = Set<String>()
        return (grammar + GrammarEntry.supplemental)
            .filter { entry in
                entry.searchTerms.contains { term in
                    let normalized = term.replacingOccurrences(of: "〜", with: "")
                    return normalized.count >= 2 && haystack.contains(normalized)
                }
            }
            .filter { entry in
                if usedPatterns.contains(entry.pattern) { return false }
                usedPatterns.insert(entry.pattern)
                return true
            }
            .prefix(limit)
            .map { $0 }
    }

    func hanVietText(for word: String) -> String? {
        let values = word.map { String($0) }.compactMap { hanViet[$0] }
        return values.isEmpty ? nil : values.joined(separator: " ")
    }

    func note(for entry: VocabularyEntry) -> String {
        let pronunciation = [entry.reading.nonEmpty, hanVietText(for: entry.word)]
            .compactMap { $0 }
            .joined(separator: ", ")
        let readingPart = pronunciation.isEmpty ? "" : "（\(pronunciation)）"
        return "\(entry.word)\(readingPart) = \(entry.meaning)"
    }

    private func load() {
        guard let url = Bundle.main.url(forResource: "StudyDictionary", withExtension: "json") else {
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let document = try JSONDecoder().decode(StudyDictionaryDocument.self, from: data)
            vocabulary = document.vocabulary
            grammar = document.grammar
            hanViet = document.hanViet
        } catch {
            vocabulary = []
            grammar = []
            hanViet = [:]
        }
    }

    private func studyText(for question: PracticeQuestion) -> String {
        [
            question.text,
            question.options.joined(separator: "\n"),
            question.answerText ?? "",
            question.correctAnswer.flatMap { index in
                question.options.indices.contains(index - 1) ? question.options[index - 1] : nil
            } ?? ""
        ].joined(separator: "\n")
    }

    private func containsKanji(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            (0x4E00...0x9FFF).contains(Int(scalar.value))
        }
    }
}
