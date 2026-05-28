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

    static let supplemental: [VocabularyEntry] = [
        VocabularyEntry(word: "深刻", reading: "しんこく", meaning: "nghiêm trọng, sâu sắc", level: "N2"),
        VocabularyEntry(word: "思わぬ", reading: "おもわぬ", meaning: "không ngờ tới, bất ngờ", level: "N2"),
        VocabularyEntry(word: "潜む", reading: "ひそむ", meaning: "ẩn nấp; tiềm ẩn, ẩn chứa", level: "N1"),
        VocabularyEntry(word: "卓越", reading: "たくえつ", meaning: "vượt trội, xuất sắc", level: "N1"),
        VocabularyEntry(word: "芳しい", reading: "かんばしい", meaning: "tốt, thuận lợi; thường dùng dạng phủ định 芳しくない = không tốt", level: "N1"),
        VocabularyEntry(word: "管轄", reading: "かんかつ", meaning: "thẩm quyền quản lý, phạm vi phụ trách", level: "N1"),
        VocabularyEntry(word: "一環", reading: "いっかん", meaning: "một phần trong chuỗi/hoạt động chung", level: "N1"),
        VocabularyEntry(word: "前半", reading: "ぜんはん", meaning: "nửa đầu, hiệp đầu", level: "N2"),
        VocabularyEntry(word: "後半", reading: "こうはん", meaning: "nửa sau, hiệp sau", level: "N2"),
        VocabularyEntry(word: "逆転", reading: "ぎゃくてん", meaning: "lội ngược dòng, đảo ngược tình thế", level: "N2"),
        VocabularyEntry(word: "リード", reading: "リード", meaning: "dẫn trước, dẫn điểm", level: "N2"),
        VocabularyEntry(word: "互角", reading: "ごかく", meaning: "ngang tài ngang sức", level: "N1"),
        VocabularyEntry(word: "若手", reading: "わかて", meaning: "người trẻ, lớp trẻ có triển vọng", level: "N2"),
        VocabularyEntry(word: "実力", reading: "じつりょく", meaning: "thực lực, năng lực thật", level: "N2"),
        VocabularyEntry(word: "割り当てる", reading: "わりあてる", meaning: "phân công, phân bổ, giao cho", level: "N2"),
        VocabularyEntry(word: "周到", reading: "しゅうとう", meaning: "chu đáo, chuẩn bị kỹ lưỡng", level: "N1"),
        VocabularyEntry(word: "臨む", reading: "のぞむ", meaning: "tham dự, bước vào; đối mặt với", level: "N1"),
        VocabularyEntry(word: "ひとまず", reading: "ひとまず", meaning: "tạm thời, trước hết", level: "N2"),
        VocabularyEntry(word: "むしゃくしゃ", reading: "むしゃくしゃ", meaning: "bực bội, khó chịu trong lòng", level: "N2"),
        VocabularyEntry(word: "誇張", reading: "こちょう", meaning: "phóng đại, nói quá", level: "N1"),
        VocabularyEntry(word: "ひそか", reading: "ひそか", meaning: "âm thầm, bí mật, kín đáo", level: "N1"),
        VocabularyEntry(word: "試練", reading: "しれん", meaning: "thử thách, gian nan", level: "N1"),
        VocabularyEntry(word: "苦難", reading: "くなん", meaning: "khó khăn, gian khổ", level: "N1"),
        VocabularyEntry(word: "うろたえる", reading: "うろたえる", meaning: "lúng túng, hoảng hốt, mất bình tĩnh", level: "N1"),
        VocabularyEntry(word: "慌てる", reading: "あわてる", meaning: "vội vàng, hoảng hốt", level: "N2"),
        VocabularyEntry(word: "当面", reading: "とうめん", meaning: "trước mắt, trong thời gian hiện tại", level: "N2"),
        VocabularyEntry(word: "しばらく", reading: "しばらく", meaning: "một lúc, một thời gian", level: "N3"),
        VocabularyEntry(word: "憩い", reading: "いこい", meaning: "sự nghỉ ngơi, thư giãn; nơi nghỉ chân", level: "N1"),
        VocabularyEntry(word: "憩う", reading: "いこう", meaning: "nghỉ ngơi, thư giãn", level: "N1"),
        VocabularyEntry(word: "自前", reading: "じまえ", meaning: "tự mình lo; đồ của mình, tự có", level: "N1"),
        VocabularyEntry(word: "衣装", reading: "いしょう", meaning: "trang phục, phục trang", level: "N2")
    ]
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
        return (vocabulary + VocabularyEntry.supplemental)
            .filter { entry in
                guard entry.word.count >= 2 || containsKanji(entry.word) else { return false }
                return matches(entry, in: haystack)
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

    func matches(_ entry: VocabularyEntry, in text: String) -> Bool {
        surfaceForms(for: entry.word).contains { text.contains($0) }
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
            question.passage ?? "",
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

    private func surfaceForms(for word: String) -> [String] {
        var forms = Set([word])
        if word.hasSuffix("む") {
            let stem = String(word.dropLast())
            forms.formUnion([stem + "んで", stem + "んだ", stem + "まない", stem + "みます", stem + "めば"])
        }
        if word.hasSuffix("ぶ") {
            let stem = String(word.dropLast())
            forms.formUnion([stem + "んで", stem + "んだ", stem + "ばない", stem + "びます", stem + "べば"])
        }
        if word.hasSuffix("ぬ") {
            let stem = String(word.dropLast())
            forms.formUnion([stem + "んで", stem + "んだ", stem + "なない", stem + "にます", stem + "ねば"])
        }
        if word.hasSuffix("ぐ") {
            let stem = String(word.dropLast())
            forms.formUnion([stem + "いで", stem + "いだ", stem + "がない", stem + "ぎます", stem + "げば"])
        }
        if word.hasSuffix("く") {
            let stem = String(word.dropLast())
            forms.formUnion([stem + "いて", stem + "いた", stem + "かない", stem + "きます", stem + "けば"])
        }
        if word.hasSuffix("す") {
            let stem = String(word.dropLast())
            forms.formUnion([stem + "して", stem + "した", stem + "さない", stem + "します", stem + "せば"])
        }
        if word.hasSuffix("う") {
            let stem = String(word.dropLast())
            forms.formUnion([stem + "って", stem + "った", stem + "わない", stem + "います", stem + "えば", stem + "い"])
        }
        if word.hasSuffix("る") {
            let stem = String(word.dropLast())
            forms.formUnion([stem + "て", stem + "た", stem + "ない", stem + "ます", stem + "れば"])
        }
        if word.hasSuffix("い") {
            let stem = String(word.dropLast())
            forms.formUnion([stem + "く", stem + "くない", stem + "かった", stem + "ければ"])
        }
        return Array(forms)
    }
}
