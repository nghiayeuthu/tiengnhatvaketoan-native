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

}

@MainActor
final class StudyDictionaryStore: ObservableObject {
    @Published private(set) var vocabulary: [VocabularyEntry] = []
    @Published private(set) var grammar: [GrammarEntry] = []
    @Published private(set) var hanViet: [String: String] = [:]
    private var vocabularyMatchCache: [String: [VocabularyEntry]] = [:]
    private var grammarMatchCache: [String: [GrammarEntry]] = [:]

    init() {
        load()
    }

    func vocabularyMatches(for question: PracticeQuestion, limit: Int = 6) -> [VocabularyEntry] {
        let cacheKey = "\(question.id)-\(limit)"
        if let cached = vocabularyMatchCache[cacheKey] {
            return cached
        }

        let haystack = studyText(for: question, includeLongPassage: question.sectionTitle != "Đọc hiểu")
        var usedWords = Set<String>()
        let vocabularyResults = vocabulary
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
        vocabularyMatchCache[cacheKey] = vocabularyResults
        return vocabularyResults
    }

    func grammarMatches(for question: PracticeQuestion, limit: Int = 4) -> [GrammarEntry] {
        let cacheKey = "\(question.id)-\(limit)"
        if let cached = grammarMatchCache[cacheKey] {
            return cached
        }

        let haystack = studyText(for: question, includeLongPassage: question.sectionTitle != "Đọc hiểu") + "\n" + (question.explanation ?? "")
        var usedPatterns = Set<String>()
        let grammarResults = grammar
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
        grammarMatchCache[cacheKey] = grammarResults
        return grammarResults
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

    func flashcardText(offset: Int = 0) -> String? {
        let daySeed = Calendar(identifier: .gregorian).ordinality(of: .day, in: .era, for: Date()) ?? 0
        let seed = max(0, daySeed + offset)
        let vocabularyPool = vocabulary
            .filter { ["N1", "N2"].contains($0.level) && !$0.word.isEmpty && !$0.meaning.isEmpty }
        let grammarPool = (grammar)
            .filter { !$0.pattern.isEmpty && !$0.meaning.isEmpty }

        if seed.isMultiple(of: 3), !grammarPool.isEmpty {
            let entry = grammarPool[seed % grammarPool.count]
            return "文法: \(entry.pattern)\n\(entry.meaning)"
        }
        guard !vocabularyPool.isEmpty else {
            return grammarPool.isEmpty ? nil : {
                let entry = grammarPool[seed % grammarPool.count]
                return "文法: \(entry.pattern)\n\(entry.meaning)"
            }()
        }
        let entry = vocabularyPool[seed % vocabularyPool.count]
        return "\(entry.level) 語彙: \(note(for: entry))"
    }

    func inferredUnderlineTerm(for question: PracticeQuestion) -> String? {
        guard question.sectionTitle == "Từ vựng" else { return nil }
        let text = question.text.removingAppMarkers
        guard !text.isEmpty else { return nil }

        let answer = question.correctAnswer.flatMap { index in
            question.options.indices.contains(index - 1) ? question.options[index - 1] : nil
        } ?? question.answerText ?? ""

        if isReadingQuestion(question),
           let reading = (question.answerText?.nonEmpty ?? answer.nonEmpty) {
            return readingQuestionUnderlineTerm(in: text, reading: reading)
        }

        if (6...10).contains(question.number),
           let kanjiAnswer = (question.answerText?.nonEmpty ?? answer.nonEmpty),
           let term = kanaTermForKanjiAnswer(kanjiAnswer, in: text) {
            return term
        }
        if (6...10).contains(question.number),
           let term = longestKanaTerm(in: text) {
            return term
        }

        if isSynonymQuestion(question),
           let term = synonymUnderlineTerm(for: question, in: text, excluding: answer) {
            return term
        }

        if let leadingTerm = leadingVocabularyUsageTerm(in: text, question: question) {
            return leadingTerm
        }

        return nil
    }

    func confidentKanjiUnderlineTerm(for question: PracticeQuestion) -> String? {
        guard question.sectionTitle == "Từ vựng",
              (1...10).contains(question.number) else {
            return nil
        }
        let text = question.text.removingAppMarkers
        guard !text.isEmpty else { return nil }

        let answer = question.correctAnswer.flatMap { index in
            question.options.indices.contains(index - 1) ? question.options[index - 1] : nil
        } ?? question.answerText ?? ""

        if isReadingQuestion(question),
           let reading = (question.answerText?.nonEmpty ?? answer.nonEmpty) {
            return readingQuestionUnderlineTerm(in: text, reading: reading)
        }

        if question.examLevel == "N2",
           let kanjiAnswer = (question.answerText?.nonEmpty ?? answer.nonEmpty) {
            return kanaTermForKanjiAnswer(kanjiAnswer, in: text)
        }

        return nil
    }

    private func isReadingQuestion(_ question: PracticeQuestion) -> Bool {
        let text = question.text.removingAppMarkers
        let instruction = question.instruction ?? ""
        let answer = question.correctAnswer.flatMap { index in
            question.options.indices.contains(index - 1) ? question.options[index - 1] : nil
        } ?? question.answerText ?? ""

        guard question.sectionTitle == "Từ vựng",
              !answer.isEmpty,
              isKanaText(answer),
              containsKanji(text) else {
            return false
        }

        return text.contains("読み方")
            || instruction.contains("読み方")
            || instruction.contains("言葉の読み方")
            || (question.number <= 10 && question.options.allSatisfy { option in
                isKanaText(option)
            })
    }

    private func isSynonymQuestion(_ question: PracticeQuestion) -> Bool {
        let instruction = question.instruction ?? ""
        let text = question.text.removingAppMarkers
        return instruction.contains("意味が最も近い")
            || instruction.contains("意味に最も近い")
            || (instruction.contains("最も近い") && instruction.contains("言葉"))
            || text.contains("意味が近い")
            || text.contains("意味に近い")
            || text.contains("意味が最も近い")
            || text.contains("意味に最も近い")
            || instruction.localizedCaseInsensitiveContains("đồng nghĩa")
            || instruction.localizedCaseInsensitiveContains("gần nghĩa")
            || (instruction.isEmpty && (21...27).contains(question.number))
    }

    private func synonymUnderlineTerm(for question: PracticeQuestion, in text: String, excluding answer: String) -> String? {
        let coreText = synonymPromptCore(in: text)

        if let explanationTerm = synonymTermFromExplanation(question.explanation),
           let surface = surfaceForDictionaryHead(explanationTerm, in: coreText) {
            return surface
        }

        if let phrase = finalSynonymFocusPhrase(in: coreText) {
            return phrase
        }

        if let term = longestVocabularyWordContained(in: coreText, excluding: answer) {
            return term
        }

        if let katakana = katakanaFocusTerm(in: coreText) {
            return katakana
        }

        return longestVocabularyWordContained(in: text, excluding: answer)
    }

    private func synonymPromptCore(in text: String) -> String {
        let markers = ["。意味", "意味が", "意味に", "意味は"]
        for marker in markers {
            if let range = text.range(of: marker) {
                return String(text[..<range.lowerBound])
            }
        }
        return text
    }

    private func finalSynonymFocusPhrase(in text: String) -> String? {
        let separators = CharacterSet(charactersIn: "。\n")
        guard let candidate = text
            .components(separatedBy: separators)
            .map({ $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)) })
            .last(where: { !$0.isEmpty }) else {
            return nil
        }
        guard candidate.range(of: #"[ァ-ヶー]"#, options: .regularExpression) != nil else {
            return nil
        }
        let particles = ["は", "が", "を", "に", "で", "と", "へ", "も"]
        let pieces = candidate.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if pieces.count == 1 {
            let compact = pieces[0]
            for particle in particles.reversed() {
                if let range = compact.range(of: particle, options: .backwards),
                   range.upperBound < compact.endIndex {
                    let tail = String(compact[range.upperBound...])
                    if tail.count >= 2 { return tail }
                }
            }
            return compact.count <= 12 ? compact : nil
        }
        return pieces.last.map { String($0.prefix(12)) }
    }

    private func synonymTermFromExplanation(_ raw: String?) -> String? {
        guard let raw = raw else { return nil }
        let normalized = raw
            .replacingOccurrences(of: "＝", with: "=")
            .components(separatedBy: CharacterSet(charactersIn: "\n。"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        for line in normalized where line.contains("=") {
            guard let head = line.components(separatedBy: "=").first?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !head.isEmpty else {
                continue
            }
            return head
                .replacingOccurrences(of: "「", with: "")
                .replacingOccurrences(of: "」", with: "")
                .replacingOccurrences(of: "『", with: "")
                .replacingOccurrences(of: "』", with: "")
        }
        return nil
    }

    private func surfaceForDictionaryHead(_ term: String, in text: String) -> String? {
        let cleaned = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }

        var forms = Set(surfaceForms(for: cleaned))
        forms.insert(cleaned)
        if cleaned.hasSuffix("する") {
            let stem = String(cleaned.dropLast(2))
            forms.formUnion([stem, stem + "して", stem + "した", stem + "しない", stem + "します", stem + "される", stem + "された"])
        }

        return forms
            .filter { !$0.isEmpty && text.contains($0) }
            .sorted { $0.count > $1.count }
            .first
    }

    private func katakanaFocusTerm(in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: #"[ァ-ヶー]{2,}(?:して|する|した|しない|される|された)?"#) else {
            return nil
        }
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: nsRange)
            .compactMap { Range($0.range, in: text).map { String(text[$0]) } }
            .sorted { $0.count > $1.count }
            .first
    }

    func matches(_ entry: VocabularyEntry, in text: String) -> Bool {
        surfaceForms(for: entry.word).contains { containsSurface($0, in: text) }
            || surfaceForms(for: entry.reading).contains { containsSurface($0, in: text) }
    }

    private func leadingVocabularyUsageTerm(in text: String, question: PracticeQuestion) -> String? {
        let instruction = question.instruction ?? ""
        let hasUsageHint = instruction.contains("使い方")
            || instruction.localizedCaseInsensitiveContains("cách dùng")
            || instruction.localizedCaseInsensitiveContains("dùng từ")
        guard hasUsageHint else { return nil }
        guard question.number >= 26 else { return nil }
        let candidates = text
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "：:。、「」『』()（）")) }
            .filter { !$0.isEmpty }
        guard let first = candidates.first, first.count <= 8 else { return nil }
        return first
    }

    private func longestVocabularyWord(in text: String, reading: String) -> String? {
        let normalizedReading = reading.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedReading.isEmpty else { return nil }
        return vocabulary
            .compactMap { entry -> String? in
                let readingForms = surfaceForms(for: entry.reading)
                guard entry.reading == normalizedReading || readingForms.contains(normalizedReading) else {
                    return nil
                }
                return surfaceForms(for: entry.word)
                    .filter { !$0.isEmpty && text.contains($0) }
                    .sorted { $0.count > $1.count }
                    .first
            }
            .sorted { $0.count > $1.count }
            .first
    }

    private func readingQuestionUnderlineTerm(in text: String, reading: String) -> String? {
        let normalizedReading = reading
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .removingAppMarkers
        guard !normalizedReading.isEmpty else { return nil }

        let entries = vocabulary
            .filter { containsKanji($0.word) }

        var candidates: [(surface: String, score: Int)] = []
        for entry in entries {
            let wordForms = surfaceForms(for: entry.word).filter { !$0.isEmpty }
            let readingForms = surfaceForms(for: entry.reading).filter { !$0.isEmpty }

            for readingForm in readingForms where readingForm == normalizedReading {
                for wordForm in wordForms where text.contains(wordForm) {
                    candidates.append((wordForm, 1_000 + wordForm.count))
                }
            }

            candidates.append(contentsOf: inflectedReadingMatches(
                entry: entry,
                text: text,
                normalizedReading: normalizedReading
            ))
        }

        return candidates
            .sorted {
                if $0.score == $1.score { return $0.surface.count > $1.surface.count }
                return $0.score > $1.score
            }
            .first?
            .surface
    }

    private func inflectedReadingMatches(
        entry: VocabularyEntry,
        text: String,
        normalizedReading: String
    ) -> [(surface: String, score: Int)] {
        var matches: [(surface: String, score: Int)] = []

        if entry.word.hasSuffix("い"), entry.reading.hasSuffix("い") {
            let wordStem = String(entry.word.dropLast())
            let readingStem = String(entry.reading.dropLast())
            let suffixes = ["くて", "く", "かった", "ければ", "くない", "くなかった", "さ", "そう"]
            for suffix in suffixes {
                let surface = wordStem + suffix
                if text.contains(surface), normalizedReading == readingStem + suffix {
                    matches.append((surface, 2_000 + surface.count))
                }
            }
        }

        if entry.word.hasSuffix("る"), entry.reading.hasSuffix("る") {
            let wordStem = String(entry.word.dropLast())
            let readingStem = String(entry.reading.dropLast())
            let suffixes = ["て", "た", "ます", "ました", "ない", "なかった", "れば", "よう", "られる", "させる"]
            for suffix in suffixes {
                let surface = wordStem + suffix
                if text.contains(surface), normalizedReading == readingStem + suffix {
                    matches.append((surface, 1_900 + surface.count))
                }
            }
        }

        if entry.word.hasSuffix("う"), entry.reading.hasSuffix("う") {
            let wordStem = String(entry.word.dropLast())
            let readingStem = String(entry.reading.dropLast())
            let pairs = [
                ("います", "います"),
                ("いました", "いました"),
                ("って", "って"),
                ("った", "った"),
                ("わない", "わない"),
                ("えば", "えば"),
                ("いたい", "いたい"),
                ("おう", "おう")
            ]
            for (surfaceSuffix, readingSuffix) in pairs {
                let surface = wordStem + surfaceSuffix
                if text.contains(surface), normalizedReading == readingStem + readingSuffix {
                    matches.append((surface, 1_800 + surface.count))
                }
            }
        }

        let godanPairs: [(String, String, [(String, String)])] = [
            ("す", "す", [("して", "して"), ("した", "した"), ("します", "します"), ("したい", "したい"), ("さない", "さない")]),
            ("く", "く", [("いて", "いて"), ("いた", "いた"), ("きます", "きます"), ("きたい", "きたい"), ("かない", "かない")]),
            ("ぐ", "ぐ", [("いで", "いで"), ("いだ", "いだ"), ("ぎます", "ぎます"), ("ぎたい", "ぎたい"), ("がない", "がない")]),
            ("む", "む", [("んで", "んで"), ("んだ", "んだ"), ("みます", "みます"), ("みたい", "みたい"), ("まない", "まない")]),
            ("ぶ", "ぶ", [("んで", "んで"), ("んだ", "んだ"), ("びます", "びます"), ("びたい", "びたい"), ("ばない", "ばない")]),
            ("ぬ", "ぬ", [("んで", "んで"), ("んだ", "んだ"), ("にます", "にます"), ("にたい", "にたい"), ("なない", "なない")]),
            ("つ", "つ", [("って", "って"), ("った", "った"), ("ちます", "ちます"), ("ちたい", "ちたい"), ("たない", "たない")]),
            ("る", "る", [("って", "って"), ("った", "った"), ("ります", "ります"), ("りたい", "りたい"), ("らない", "らない")])
        ]
        for (wordEnding, readingEnding, suffixes) in godanPairs
            where entry.word.hasSuffix(wordEnding) && entry.reading.hasSuffix(readingEnding) {
            let wordStem = String(entry.word.dropLast())
            let readingStem = String(entry.reading.dropLast())
            for (surfaceSuffix, readingSuffix) in suffixes {
                let surface = wordStem + surfaceSuffix
                if text.contains(surface), normalizedReading == readingStem + readingSuffix {
                    matches.append((surface, 1_850 + surface.count))
                }
            }
        }

        return matches
    }

    private func kanaTermForKanjiAnswer(_ answer: String, in text: String) -> String? {
        let entries = vocabulary
            .filter { $0.word == answer || answer.contains($0.word) || $0.word.contains(answer) }
            .sorted { $0.reading.count > $1.reading.count }

        for entry in entries {
            for form in surfaceForms(for: entry.reading).sorted(by: { $0.count > $1.count }) {
                if text.contains(form) {
                    return form
                }
            }
        }

        return nil
    }

    private func longestVocabularyWordContained(in text: String, excluding answer: String) -> String? {
        let ignored = Set(["今日", "昨日", "明日", "私", "彼", "彼女", "人", "年", "月", "日"])
        return vocabulary
            .compactMap { entry -> (entry: VocabularyEntry, surface: String)? in
                guard entry.word.count >= 2, !answer.contains(entry.word), !ignored.contains(entry.word) else { return nil }
                let surfaces = (surfaceForms(for: entry.word) + surfaceForms(for: entry.reading))
                    .filter { $0.count >= 2 && !answer.contains($0) }
                    .sorted { $0.count > $1.count }
                guard let surface = surfaces.first(where: { text.contains($0) }) else { return nil }
                return (entry, surface)
            }
            .sorted {
                if $0.surface.count == $1.surface.count { return $0.entry.level < $1.entry.level }
                return $0.surface.count > $1.surface.count
            }
            .first?
            .surface
    }

    private func longestKanjiTerm(in text: String) -> String? {
        let ignored = Set(["私", "彼", "彼女", "今日", "昨日", "明日"])
        var terms: [String] = []
        let characters = Array(text)
        var index = 0

        while index < characters.count {
            guard containsKanji(String(characters[index])) else {
                index += 1
                continue
            }

            var term = String(characters[index])
            index += 1
            while index < characters.count, containsKanji(String(characters[index])) {
                term.append(characters[index])
                index += 1
            }

            let cleaned = term.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleaned.isEmpty, !ignored.contains(cleaned) {
                terms.append(cleaned)
            }
        }

        return terms.sorted {
            if $0.count == $1.count { return $0 < $1 }
            return $0.count > $1.count
        }.first
    }

    private func longestKanaTerm(in text: String) -> String? {
        let ignored = Set(["ので", "から", "こと", "ため", "です", "ます", "した", "して", "いる", "ある", "なる", "とても"])
        var terms: [String] = []
        var current = ""

        for character in text {
            if isHiraganaCharacter(character) {
                current.append(character)
            } else {
                if current.count >= 3, !ignored.contains(current) {
                    terms.append(current)
                }
                current = ""
            }
        }
        if current.count >= 3, !ignored.contains(current) {
            terms.append(current)
        }

        return terms.sorted {
            if $0.count == $1.count { return $0 < $1 }
            return $0.count > $1.count
        }.first
    }

    private func isKanaCharacter(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy(isKana)
    }

    private func isKanaText(_ text: String) -> Bool {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return false }
        return cleaned.allSatisfy { character in
            character == "ー" || isKanaCharacter(character)
        }
    }

    private func isHiraganaCharacter(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy { scalar in
            (0x3040...0x309F).contains(Int(scalar.value))
        }
    }

    private func isKana(_ scalar: UnicodeScalar) -> Bool {
        (0x3040...0x30FF).contains(Int(scalar.value))
    }

    private func containsSurface(_ surface: String, in text: String) -> Bool {
        guard !surface.isEmpty else { return false }
        if containsKanji(surface) || surface.count >= 4 {
            return text.contains(surface)
        }

        var searchStart = text.startIndex
        while let range = text.range(of: surface, range: searchStart..<text.endIndex) {
            let before = range.lowerBound > text.startIndex ? text[text.index(before: range.lowerBound)] : nil
            let after = range.upperBound < text.endIndex ? text[range.upperBound] : nil
            if !isJapaneseLetter(before) && !isJapaneseLetter(after) {
                return true
            }
            searchStart = range.upperBound
        }
        return false
    }

    private func isJapaneseLetter(_ character: Character?) -> Bool {
        guard let character else { return false }
        return character.unicodeScalars.contains { scalar in
            let value = Int(scalar.value)
            return (0x3040...0x30FF).contains(value) || (0x4E00...0x9FFF).contains(value)
        }
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
            vocabularyMatchCache = [:]
            grammarMatchCache = [:]
        } catch {
            vocabulary = []
            grammar = []
            hanViet = [:]
            vocabularyMatchCache = [:]
            grammarMatchCache = [:]
        }
    }

    private func studyText(for question: PracticeQuestion, includeLongPassage: Bool) -> String {
        var parts = [
            question.text,
            question.options.joined(separator: "\n"),
            question.answerText ?? "",
            question.correctAnswer.flatMap { index in
                question.options.indices.contains(index - 1) ? question.options[index - 1] : nil
            } ?? ""
        ]
        if includeLongPassage, let passage = question.passage {
            parts.append(passage)
        }
        return parts.joined(separator: "\n")
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
            forms.formUnion([stem + "んで", stem + "んだ", stem + "まない", stem + "まず", stem + "まずに", stem + "みます", stem + "めば", stem + "める"])
        }
        if word.hasSuffix("ぶ") {
            let stem = String(word.dropLast())
            forms.formUnion([stem + "んで", stem + "んだ", stem + "ばない", stem + "ばず", stem + "ばずに", stem + "びます", stem + "べば", stem + "べる"])
        }
        if word.hasSuffix("ぬ") {
            let stem = String(word.dropLast())
            forms.formUnion([stem + "んで", stem + "んだ", stem + "なない", stem + "なず", stem + "なずに", stem + "にます", stem + "ねば"])
        }
        if word.hasSuffix("ぐ") {
            let stem = String(word.dropLast())
            forms.formUnion([stem + "いで", stem + "いだ", stem + "がない", stem + "がず", stem + "がずに", stem + "ぎます", stem + "げば", stem + "げる"])
        }
        if word.hasSuffix("く") {
            let stem = String(word.dropLast())
            forms.formUnion([stem + "いて", stem + "いた", stem + "かない", stem + "かず", stem + "かずに", stem + "きます", stem + "けば", stem + "ける"])
        }
        if word.hasSuffix("す") {
            let stem = String(word.dropLast())
            forms.formUnion([stem + "して", stem + "した", stem + "さない", stem + "さず", stem + "さずに", stem + "します", stem + "せば", stem + "される", stem + "されて", stem + "された"])
        }
        if word.hasSuffix("う") {
            let stem = String(word.dropLast())
            forms.formUnion([stem + "って", stem + "った", stem + "わない", stem + "わず", stem + "わずに", stem + "います", stem + "えば", stem + "い", stem + "われる", stem + "われて"])
        }
        if word.hasSuffix("る") {
            let stem = String(word.dropLast())
            forms.formUnion([stem + "て", stem + "た", stem + "ない", stem + "ず", stem + "ずに", stem + "ます", stem + "れば", stem + "られる", stem + "られて", stem + "られた", stem + "よう"])
            forms.formUnion([stem + "って", stem + "った", stem + "らない", stem + "らず", stem + "らずに", stem + "ります", stem + "れ", stem + "れる"])
        }
        if word.hasSuffix("い") {
            let stem = String(word.dropLast())
            forms.formUnion([stem + "く", stem + "くない", stem + "かった", stem + "ければ"])
        }
        return Array(forms)
    }
}
