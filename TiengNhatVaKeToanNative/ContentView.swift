import PencilKit
import SwiftUI
import AVFoundation
#if canImport(UserNotifications)
import UserNotifications
#endif
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

#if os(macOS) || targetEnvironment(macCatalyst)
private let appLeadingToolbarPlacement: ToolbarItemPlacement = .navigation
private let appTrailingToolbarPlacement: ToolbarItemPlacement = .automatic
#else
private let appLeadingToolbarPlacement: ToolbarItemPlacement = .topBarLeading
private let appTrailingToolbarPlacement: ToolbarItemPlacement = .topBarTrailing
#endif

private enum PracticeDrill: String, CaseIterable, Identifiable {
    case kanjiReading
    case kanjiWriting
    case vocabularyFill
    case synonym
    case usage
    case grammar
    case starGrammar
    case grammarPassage
    case readingShort
    case readingMedium
    case readingLong
    case readingIntegrated
    case readingAuthor
    case readingInfo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .kanjiReading: return "Mondai Kanji - đọc âm"
        case .kanjiWriting: return "Mondai Kanji - viết chữ N2"
        case .vocabularyFill: return "Mondai điền từ"
        case .synonym: return "Mondai đồng nghĩa"
        case .usage: return "Mondai cách dùng từ"
        case .grammar: return "Mondai ngữ pháp"
        case .starGrammar: return "Mondai dấu sao"
        case .grammarPassage: return "Mondai ngữ pháp đoạn văn"
        case .readingShort: return "Mondai đọc hiểu ngắn"
        case .readingMedium: return "Mondai đọc hiểu vừa"
        case .readingLong: return "Mondai đọc hiểu dài"
        case .readingIntegrated: return "Mondai đọc hiểu tổng hợp A/B"
        case .readingAuthor: return "Mondai chủ trương tác giả"
        case .readingInfo: return "Mondai tìm thông tin"
        }
    }

    var systemImage: String {
        switch self {
        case .kanjiReading, .kanjiWriting: return "character.book.closed"
        case .vocabularyFill, .synonym, .usage: return "textformat"
        case .grammar, .starGrammar, .grammarPassage: return "text.book.closed"
        case .readingShort, .readingMedium, .readingLong, .readingIntegrated, .readingAuthor, .readingInfo:
            return "book.pages"
        }
    }

    var levelLabel: String {
        switch self {
        case .kanjiWriting:
            return "N2"
        case .readingShort, .readingMedium, .readingLong, .readingIntegrated, .readingAuthor, .readingInfo:
            return "N1/N2"
        default:
            return "N1/N2"
        }
    }

    func matches(_ question: PracticeQuestion) -> Bool {
        switch self {
        case .kanjiReading:
            return question.sectionTitle == "Từ vựng" && question.number <= 5
        case .kanjiWriting:
            return question.examLevel == "N2" && question.sectionTitle == "Từ vựng" && (6...10).contains(question.number)
        case .vocabularyFill:
            return question.sectionTitle == "Từ vựng"
                && isVocabularyFillQuestion(question)
                && !isSynonymQuestion(question)
                && !isUsageQuestion(question)
        case .synonym:
            return question.sectionTitle == "Từ vựng" && isSynonymQuestion(question)
        case .usage:
            return question.sectionTitle == "Từ vựng" && isUsageQuestion(question)
        case .grammar:
            return isGrammarFillQuestion(question)
        case .starGrammar:
            return isStarGrammarQuestion(question)
        case .grammarPassage:
            return isGrammarPassageQuestion(question)
        case .readingShort:
            return readingKind(for: question) == .short
        case .readingMedium:
            return readingKind(for: question) == .medium
        case .readingLong:
            return readingKind(for: question) == .long
        case .readingIntegrated:
            return readingKind(for: question) == .integrated
        case .readingAuthor:
            return readingKind(for: question) == .author
        case .readingInfo:
            return readingKind(for: question) == .info
        }
    }

    private enum ReadingKind {
        case short
        case medium
        case long
        case integrated
        case author
        case info
    }

    private func readingKind(for question: PracticeQuestion) -> ReadingKind? {
        guard question.sectionTitle == "Đọc hiểu" else { return nil }
        let instruction = (question.instruction ?? "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "　", with: "")
        let text = question.text
        let combined = instruction + text

        if combined.localizedCaseInsensitiveContains("tìm thông tin")
            || combined.contains("情報検索")
            || combined.contains("右のページ")
            || combined.contains("下のページ")
            || combined.contains("案内")
            || instruction.contains("問題13") && question.examLevel == "N1"
            || instruction.contains("問題14") && question.examLevel == "N2" {
            return .info
        }
        if combined.localizedCaseInsensitiveContains("chủ trương")
            || combined.localizedCaseInsensitiveContains("tác giả")
            || combined.contains("主張")
            || (question.examLevel == "N1" && instruction.contains("問題12")) {
            return .author
        }
        if combined.localizedCaseInsensitiveContains("tổng hợp")
            || combined.contains("AとB")
            || combined.contains("AとBの")
            || combined.contains("意見文")
            || (question.examLevel == "N1" && instruction.contains("問題11"))
            || (question.examLevel == "N2" && instruction.contains("問題12")) {
            return .integrated
        }
        if combined.localizedCaseInsensitiveContains("dài")
            || (question.examLevel == "N1" && instruction.contains("問題10"))
            || (question.examLevel == "N2" && instruction.contains("問題13")) {
            return .long
        }
        if combined.localizedCaseInsensitiveContains("vừa")
            || (question.examLevel == "N1" && instruction.contains("問題9"))
            || (question.examLevel == "N2" && instruction.contains("問題11")) {
            return .medium
        }
        if combined.localizedCaseInsensitiveContains("ngắn")
            || (question.examLevel == "N1" && instruction.contains("問題8"))
            || (question.examLevel == "N2" && instruction.contains("問題10")) {
            return .short
        }

        return readingKindByNumber(for: question)
    }

    private func readingKindByNumber(for question: PracticeQuestion) -> ReadingKind? {
        switch question.examLevel {
        case "N1":
            switch question.number {
            case 45...48: return .short
            case 49...56: return .medium
            case 57...59: return .long
            case 60...61: return .integrated
            case 62...64: return .author
            case 65...70: return .info
            default: return nil
            }
        case "N2":
            switch question.number {
            case 52...56: return .short
            case 57...64: return .medium
            case 65...66: return .integrated
            case 67...69: return .long
            case 70...72: return .info
            default: return nil
            }
        default:
            return nil
        }
    }

    private func isGrammarPassageQuestion(_ question: PracticeQuestion) -> Bool {
        guard question.sectionTitle == "Ngữ pháp" else { return false }
        guard !hasStarGrammarSignal(question) else { return false }
        if question.passage?.nonEmpty != nil { return true }
        let instruction = question.instruction ?? ""
        if question.text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("【") {
            return true
        }
        if instruction.localizedCaseInsensitiveContains("ngữ pháp") {
            if question.examLevel == "N1", (41...45).contains(question.number) { return true }
            if question.examLevel == "N2", (48...54).contains(question.number) { return true }
        }
        return instruction.localizedCaseInsensitiveContains("đoạn văn")
            || instruction.contains("問題9")
            || instruction.contains("文章")
            || instruction.contains("文を読んで")
    }

    private func isStarGrammarQuestion(_ question: PracticeQuestion) -> Bool {
        guard question.sectionTitle == "Ngữ pháp" else { return false }
        return hasStarGrammarSignal(question)
    }

    private func hasStarGrammarSignal(_ question: PracticeQuestion) -> Bool {
        let instruction = question.instruction ?? ""
        return instruction.contains("問題8")
            || instruction.contains("★")
            || question.correctOrder?.isEmpty == false
            || question.starOrder?.nonEmpty != nil
            || question.text.contains("★")
            || (question.textHtml?.contains("★") ?? false)
            || (instruction.localizedCaseInsensitiveContains("ngữ pháp")
                && question.examLevel == "N1"
                && (36...40).contains(question.number))
            || (instruction.localizedCaseInsensitiveContains("ngữ pháp")
                && question.examLevel == "N2"
                && (43...47).contains(question.number))
    }

    private func isGrammarFillQuestion(_ question: PracticeQuestion) -> Bool {
        guard question.sectionTitle == "Ngữ pháp" else { return false }
        guard !isGrammarPassageQuestion(question), !isStarGrammarQuestion(question) else { return false }
        let instruction = question.instruction ?? ""
        if instruction.contains("問題7")
            || instruction.contains("入れる")
            || instruction.localizedCaseInsensitiveContains("ngữ pháp") {
            return true
        }
        return instruction.isEmpty
            && question.correctOrder?.isEmpty != false
            && question.starOrder?.nonEmpty == nil
            && !question.text.contains("★")
            && !(question.textHtml?.contains("★") ?? false)
    }

    private func isVocabularyFillQuestion(_ question: PracticeQuestion) -> Bool {
        let instruction = question.instruction ?? ""
        if instruction.contains("入れる") || instruction.localizedCaseInsensitiveContains("điền") {
            return true
        }
        return instruction.isEmpty && (11...20).contains(question.number)
    }

    private func isSynonymQuestion(_ question: PracticeQuestion) -> Bool {
        let instruction = question.instruction ?? ""
        if instruction.contains("意味が最も近い")
            || instruction.contains("意味に最も近い")
            || (instruction.contains("最も近い") && instruction.contains("言葉"))
            || instruction.localizedCaseInsensitiveContains("đồng nghĩa")
            || instruction.localizedCaseInsensitiveContains("gần nghĩa") {
            return true
        }
        return instruction.isEmpty && (21...25).contains(question.number)
    }

    private func isUsageQuestion(_ question: PracticeQuestion) -> Bool {
        let instruction = question.instruction ?? ""
        if instruction.contains("使い方")
            || instruction.localizedCaseInsensitiveContains("cách dùng") {
            return true
        }
        return instruction.isEmpty && question.number >= 26
    }
}

private final class SpeechController: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var isSpeaking = false
    @Published var spokenText = ""
    @Published var spokenRange: NSRange?
    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) {
        let cleaned = text.speechCleanedJapanese
        guard !cleaned.isEmpty else { return }
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        spokenText = cleaned
        spokenRange = nil
        let utterance = AVSpeechUtterance(string: cleaned)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.86
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        spokenText = ""
        spokenRange = nil
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        spokenRange = characterRange
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        spokenText = ""
        spokenRange = nil
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        spokenText = ""
        spokenRange = nil
    }
}

private func applySpeechHighlight(to output: NSMutableAttributedString, range: NSRange?) {
    guard let range,
          range.location != NSNotFound,
          output.length > 0 else { return }
    let start = max(0, range.location)
    let end = min(output.length, range.location + range.length)
    guard end > start else { return }
    output.addAttributes([
        .backgroundColor: PlatformColor.appSystemOrange.withAlphaComponent(0.24),
        .foregroundColor: PlatformColor.appLabel
    ], range: NSRange(location: start, length: end - start))
}

private func speechHighlightRange(in original: String, cleanedRange: NSRange?) -> NSRange? {
    guard let cleanedRange,
          cleanedRange.location != NSNotFound else { return nil }
    let cleaned = original.speechCleanedJapanese
    let cleanedNSString = cleaned as NSString
    guard cleanedRange.location >= 0,
          cleanedRange.location < cleanedNSString.length else { return nil }

    let safeLength = min(cleanedRange.length, cleanedNSString.length - cleanedRange.location)
    guard safeLength > 0 else { return nil }
    let spokenFragment = cleanedNSString.substring(with: NSRange(location: cleanedRange.location, length: safeLength))
        .trimmingCharacters(in: .whitespacesAndNewlines)
    guard !spokenFragment.isEmpty else { return nil }

    let displayText = original.removingAppMarkers
    let displayNSString = displayText as NSString
    if let exactRange = firstDisplayRange(for: spokenFragment, in: displayNSString) {
        return exactRange
    }

    let compactFragment = spokenFragment
        .components(separatedBy: .whitespacesAndNewlines)
        .filter { !$0.isEmpty }
        .joined()
    if let compactRange = firstDisplayRange(for: compactFragment, in: displayNSString) {
        return compactRange
    }

    let tokens = japaneseSpeechTokens(in: spokenFragment)
    for token in tokens where token.count >= 2 {
        if let tokenRange = firstDisplayRange(for: token, in: displayNSString) {
            return tokenRange
        }
    }
    return nil
}

private func firstDisplayRange(for text: String, in displayNSString: NSString) -> NSRange? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, trimmed.count <= 80 else { return nil }
    let range = displayNSString.range(of: trimmed)
    return range.location == NSNotFound ? nil : range
}

private func japaneseSpeechTokens(in text: String) -> [String] {
    let pattern = #"[一-龯々〆ヵヶぁ-んァ-ヶーA-Za-z0-9]{2,}"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    return regex.matches(in: text, range: range)
        .compactMap { match in
            Range(match.range, in: text).map { String(text[$0]) }
        }
        .sorted { $0.count > $1.count }
}

private struct BossRunState: Codable, Equatable {
    var startedAt: Date
    var activeElapsed: TimeInterval
    var lastActiveAt: Date?
    var heartsLeft: Int
    var finishedAt: Date?
    var didWin: Bool
    var combo: Int = 0
    var wrongAnswerTickets: Int = 0

    init(startedAt: Date, activeElapsed: TimeInterval = 0, lastActiveAt: Date? = nil, heartsLeft: Int, finishedAt: Date?, didWin: Bool, combo: Int = 0, wrongAnswerTickets: Int = 0) {
        self.startedAt = startedAt
        self.activeElapsed = activeElapsed
        self.lastActiveAt = lastActiveAt
        self.heartsLeft = heartsLeft
        self.finishedAt = finishedAt
        self.didWin = didWin
        self.combo = combo
        self.wrongAnswerTickets = wrongAnswerTickets
    }

    private enum CodingKeys: String, CodingKey {
        case startedAt, activeElapsed, lastActiveAt, heartsLeft, finishedAt, didWin, combo, wrongAnswerTickets
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        activeElapsed = try container.decodeIfPresent(TimeInterval.self, forKey: .activeElapsed) ?? 0
        lastActiveAt = try container.decodeIfPresent(Date.self, forKey: .lastActiveAt)
        heartsLeft = try container.decode(Int.self, forKey: .heartsLeft)
        finishedAt = try container.decodeIfPresent(Date.self, forKey: .finishedAt)
        didWin = try container.decode(Bool.self, forKey: .didWin)
        combo = try container.decodeIfPresent(Int.self, forKey: .combo) ?? 0
        wrongAnswerTickets = try container.decodeIfPresent(Int.self, forKey: .wrongAnswerTickets) ?? 0
    }
}

private struct BossMetrics {
    let totalHP: Double
    let languageHP: Double
    let readingHP: Double
    let languageCorrect: Int
    let readingCorrect: Int
    let languageTotal: Int
    let readingTotal: Int

    var isDefeated: Bool { totalHP <= 0.01 }
}

private struct StudyReminderSlot: Codable, Identifiable, Hashable {
    var hour: Int
    var minute: Int

    var id: String { String(format: "%02d:%02d", hour, minute) }
    var label: String { id }
}

private enum GameScreen {
    case mainMenu
    case newGame
    case continueGame
    case bossMap
    case practice
    case settings
}

private struct PlayerProfile: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var createdAt: Date
    var lastPlayedAt: Date
    var answerHistory: [String: Int]
    var bossStates: [String: BossRunState]
    var isDead: Bool

    var defeatedBossCount: Int {
        bossStates.values.filter(\.didWin).count
    }
}

private final class GameAudioManager: ObservableObject {
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey)
            isEnabled ? startBGM() : stopAll()
        }
    }

    private static let enabledKey = "TiengNhatVaKeToan.audio.enabled"
    private var bgmPlayer: AVAudioPlayer?
    private var sfxPlayers: [AVAudioPlayer] = []

    init() {
        isEnabled = UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
        if isEnabled {
            startBGM()
        }
    }

    func startBGM() {
        guard isEnabled, bgmPlayer == nil else { return }
        bgmPlayer = makeBundledBGMPlayer() ?? makeCanonInDPlayer() ?? makePlayer(frequencies: [293.66, 440.0, 493.88, 587.33], duration: 4.0, volume: 0.16)
        bgmPlayer?.numberOfLoops = -1
        bgmPlayer?.play()
    }

    func stopAll() {
        bgmPlayer?.stop()
        bgmPlayer = nil
        sfxPlayers.forEach { $0.stop() }
        sfxPlayers.removeAll()
    }

    func play(_ event: GameSoundEvent) {
        guard isEnabled else { return }
        let player: AVAudioPlayer?
        switch event {
        case .correct:
            player = makePlayer(frequencies: [523.25, 659.25, 783.99], duration: 0.28, volume: 0.35)
        case .wrong:
            player = makePlayer(frequencies: [220.0, 174.61], duration: 0.32, volume: 0.36)
        case .boss:
            player = makePlayer(frequencies: [196.0, 293.66, 392.0], duration: 0.55, volume: 0.32)
        case .win:
            player = makePlayer(frequencies: [392.0, 523.25, 659.25, 783.99], duration: 0.75, volume: 0.38)
        case .lose:
            player = makePlayer(frequencies: [261.63, 220.0, 196.0, 164.81], duration: 0.85, volume: 0.36)
        case .combo:
            player = makePlayer(frequencies: [659.25, 783.99, 987.77], duration: 0.45, volume: 0.34)
        case .save:
            player = makePlayer(frequencies: [440.0, 587.33], duration: 0.28, volume: 0.30)
        }
        guard let player else { return }
        sfxPlayers.append(player)
        player.play()
        sfxPlayers.removeAll { !$0.isPlaying }
    }

    private func makePlayer(frequencies: [Double], duration: Double, volume: Float) -> AVAudioPlayer? {
        let sampleRate = 44_100
        let sampleCount = max(1, Int(duration * Double(sampleRate)))
        var samples = [Int16]()
        samples.reserveCapacity(sampleCount)

        for index in 0..<sampleCount {
            let t = Double(index) / Double(sampleRate)
            let progress = Double(index) / Double(sampleCount)
            let envelope = min(1, progress * 10) * max(0, 1 - progress)
            let frequency = frequencies[min(frequencies.count - 1, Int(progress * Double(frequencies.count)))]
            let value = sin(2 * Double.pi * frequency * t) * envelope * 0.55
            samples.append(Int16(value * Double(Int16.max)))
        }

        var data = Data()
        let byteRate = sampleRate * 2
        let blockAlign: UInt16 = 2
        let bitsPerSample: UInt16 = 16
        let dataSize = UInt32(samples.count * 2)
        data.append("RIFF".data(using: .ascii)!)
        data.append(UInt32(36 + dataSize).littleEndianData)
        data.append("WAVEfmt ".data(using: .ascii)!)
        data.append(UInt32(16).littleEndianData)
        data.append(UInt16(1).littleEndianData)
        data.append(UInt16(1).littleEndianData)
        data.append(UInt32(sampleRate).littleEndianData)
        data.append(UInt32(byteRate).littleEndianData)
        data.append(blockAlign.littleEndianData)
        data.append(bitsPerSample.littleEndianData)
        data.append("data".data(using: .ascii)!)
        data.append(dataSize.littleEndianData)
        samples.forEach { data.append($0.littleEndianData) }

        let player = try? AVAudioPlayer(data: data)
        player?.volume = volume
        player?.prepareToPlay()
        return player
    }

    private func makeBundledBGMPlayer() -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: "BGMCanonInD", withExtension: "mp3"),
              let player = try? AVAudioPlayer(contentsOf: url) else {
            return nil
        }
        player.volume = 0.34
        player.prepareToPlay()
        return player
    }

    private func makeCanonInDPlayer() -> AVAudioPlayer? {
        let sampleRate = 44_100
        let beat = 60.0 / 72.0
        let step = beat / 2.0
        let chordSteps = 8
        let chords: [[Double]] = [
            [146.83, 185.00, 220.00],
            [110.00, 164.81, 220.00],
            [123.47, 146.83, 185.00],
            [92.50, 138.59, 185.00],
            [98.00, 123.47, 196.00],
            [146.83, 185.00, 220.00],
            [98.00, 123.47, 196.00],
            [110.00, 138.59, 220.00]
        ]
        let melody: [Double] = [
            587.33, 554.37, 493.88, 440.00, 392.00, 369.99, 392.00, 440.00,
            493.88, 440.00, 392.00, 369.99, 329.63, 293.66, 329.63, 369.99,
            392.00, 440.00, 493.88, 440.00, 392.00, 369.99, 329.63, 293.66,
            246.94, 293.66, 329.63, 369.99, 392.00, 440.00, 493.88, 554.37
        ]
        let duration = Double(chords.count * chordSteps) * step
        let sampleCount = max(1, Int(duration * Double(sampleRate)))
        var mixed = Array(repeating: 0.0, count: sampleCount)

        func addTone(_ frequency: Double, start: Double, duration: Double, amplitude: Double) {
            let startIndex = max(0, Int(start * Double(sampleRate)))
            let endIndex = min(sampleCount, startIndex + Int(duration * Double(sampleRate)))
            guard startIndex < endIndex else { return }
            let toneLength = max(1, endIndex - startIndex)
            for offset in 0..<toneLength {
                let t = Double(offset) / Double(sampleRate)
                let progress = Double(offset) / Double(toneLength)
                let attack = min(1.0, progress * 24.0)
                let decay = pow(max(0.0, 1.0 - progress), 1.8)
                let envelope = attack * decay
                let harmonic = sin(2.0 * Double.pi * frequency * t)
                    + 0.35 * sin(2.0 * Double.pi * frequency * 2.0 * t)
                    + 0.12 * sin(2.0 * Double.pi * frequency * 3.0 * t)
                mixed[startIndex + offset] += harmonic * envelope * amplitude
            }
        }

        for chordIndex in chords.indices {
            let chordStart = Double(chordIndex * chordSteps) * step
            let chord = chords[chordIndex]
            addTone(chord[0], start: chordStart, duration: step * Double(chordSteps), amplitude: 0.07)
            for stepIndex in 0..<chordSteps {
                let start = chordStart + Double(stepIndex) * step
                let note = chord[[0, 2, 1, 2, 0, 2, 1, 2][stepIndex]]
                addTone(note * 2.0, start: start, duration: step * 1.8, amplitude: 0.075)
            }
        }

        for (index, note) in melody.enumerated() {
            addTone(note, start: Double(index) * step, duration: step * 1.6, amplitude: 0.11)
        }

        let samples = mixed.map { value -> Int16 in
            let clipped = max(-0.95, min(0.95, value))
            return Int16(clipped * Double(Int16.max))
        }
        return makePlayer(samples: samples, sampleRate: sampleRate, volume: 0.20)
    }

    private func makePlayer(samples: [Int16], sampleRate: Int, volume: Float) -> AVAudioPlayer? {
        var data = Data()
        let byteRate = sampleRate * 2
        let blockAlign: UInt16 = 2
        let bitsPerSample: UInt16 = 16
        let dataSize = UInt32(samples.count * 2)
        data.append("RIFF".data(using: .ascii)!)
        data.append(UInt32(36 + dataSize).littleEndianData)
        data.append("WAVEfmt ".data(using: .ascii)!)
        data.append(UInt32(16).littleEndianData)
        data.append(UInt16(1).littleEndianData)
        data.append(UInt16(1).littleEndianData)
        data.append(UInt32(sampleRate).littleEndianData)
        data.append(UInt32(byteRate).littleEndianData)
        data.append(blockAlign.littleEndianData)
        data.append(bitsPerSample.littleEndianData)
        data.append("data".data(using: .ascii)!)
        data.append(dataSize.littleEndianData)
        samples.forEach { data.append($0.littleEndianData) }

        let player = try? AVAudioPlayer(data: data)
        player?.volume = volume
        player?.prepareToPlay()
        return player
    }
}

private enum GameSoundEvent {
    case correct, wrong, boss, win, lose, combo, save
}

private extension FixedWidthInteger {
    var littleEndianData: Data {
        var value = littleEndian
        return Data(bytes: &value, count: MemoryLayout<Self>.size)
    }
}

private enum BossMood {
    case normal
    case pressured
    case angry
    case defeated
    case champion
}

#if canImport(UIKit) || canImport(AppKit)
#if canImport(UIKit)
private typealias BossPlatformImage = UIImage
#elseif canImport(AppKit)
private typealias BossPlatformImage = NSImage
#endif

private final class BossImageCache {
    static let shared = BossImageCache()

    private let cache = NSCache<NSString, BossPlatformImage>()

    func image(named fileName: String) -> BossPlatformImage? {
        let key = fileName as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        guard let url = Bundle.main.url(forResource: fileName, withExtension: nil, subdirectory: "BossImages"),
              let image = BossPlatformImage(contentsOfFile: url.path) else {
            return nil
        }
        cache.setObject(image, forKey: key)
        return image
    }

    func preload(fileNames: [String]) {
        for fileName in Set(fileNames) {
            _ = image(named: fileName)
        }
    }
}

private struct BossArtView: View {
    let exam: ExamDocument
    let mood: BossMood
    var size: CGFloat
    var hpRatio: Double = 1
    var showsYearBadge = true

    private var fileName: String {
        Self.fileName(for: exam)
    }

    var body: some View {
        Group {
            if let image = BossImageCache.shared.image(named: fileName) {
                bossImage(image)
            } else {
                BossMascotView(
                    level: exam.normalizedLevel,
                    examTag: "\(exam.year)/\(exam.month)",
                    hpRatio: hpRatio,
                    mood: mood,
                    size: size
                )
            }
        }
        .accessibilityLabel("Boss \(exam.normalizedLevel) \(exam.year) tháng \(exam.month)")
    }

    @ViewBuilder
    private func bossImage(_ image: BossPlatformImage) -> some View {
        ZStack(alignment: .topLeading) {
            platformImageView(image)
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.18, style: .continuous))
                .saturation(mood == .defeated ? 0.35 : 1)
                .brightness(mood == .angry ? -0.05 : 0)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                        .stroke(borderColor.opacity(0.82), lineWidth: max(1.2, size * 0.025))
                )
                .shadow(color: Color.black.opacity(0.16), radius: size * 0.08, y: size * 0.04)

            if showsYearBadge {
                Text("\(exam.normalizedLevel) \(exam.year)")
                    .font(.system(size: max(9, size * 0.105), weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, max(5, size * 0.055))
                    .padding(.vertical, max(3, size * 0.025))
                    .background(Color.black.opacity(0.52), in: Capsule())
                    .padding(max(5, size * 0.055))
            }
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private func platformImageView(_ image: BossPlatformImage) -> some View {
        #if canImport(UIKit)
        Image(uiImage: image)
            .resizable()
        #elseif canImport(AppKit)
        Image(nsImage: image)
            .resizable()
        #endif
    }

    private var borderColor: Color {
        switch mood {
        case .defeated, .champion:
            return .yellow
        case .angry:
            return .red
        case .pressured:
            return .orange
        case .normal:
            return .white
        }
    }

    static func fileName(for exam: ExamDocument) -> String {
        "\(exam.normalizedLevel.lowercased()) \(exam.year):\(exam.month).png"
    }
}
#else
private struct BossArtView: View {
    let exam: ExamDocument
    let mood: BossMood
    var size: CGFloat
    var hpRatio: Double = 1
    var showsYearBadge = true

    var body: some View {
        BossMascotView(
            level: exam.normalizedLevel,
            examTag: "\(exam.year)/\(exam.month)",
            hpRatio: hpRatio,
            mood: mood,
            size: size
        )
    }

    static func fileName(for exam: ExamDocument) -> String {
        "\(exam.normalizedLevel.lowercased()) \(exam.year):\(exam.month).png"
    }
}
#endif

private struct BossMascotView: View {
    let level: String
    var examTag: String? = nil
    let hpRatio: Double
    let mood: BossMood
    var size: CGFloat = 96
    var showsBackdrop: Bool = true

    private var evolutionStage: Int {
        switch hpRatio {
        case 0.80...: return 1
        case 0.60..<0.80: return 2
        case 0.40..<0.60: return 3
        case 0.20..<0.40: return 4
        default: return 5
        }
    }

    private var evolutionTitle: String {
        switch evolutionStage {
        case 1: return "100%"
        case 2: return "80%"
        case 3: return "60%"
        case 4: return "40%"
        default: return "20%"
        }
    }

    private var stageAccessory: String {
        switch evolutionStage {
        case 1: return level == "N1" ? "🎓" : "🌸"
        case 2: return "⚡️"
        case 3: return "🔥"
        case 4: return "💢"
        default: return "🌋"
        }
    }

    var body: some View {
        ZStack {
            if showsBackdrop {
                RoundedRectangle(cornerRadius: size * 0.18)
                    .fill(
                        LinearGradient(
                            colors: [
                                stageColor.opacity(0.92),
                                Color(red: 0.45, green: 0.29, blue: 0.45)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.18)
                            .stroke(stageColor.opacity(0.65), lineWidth: 1.2)
                    )
            } else {
                Circle()
                    .fill(stageColor.opacity(0.22))
                    .blur(radius: size * 0.08)
                    .frame(width: size * 0.94, height: size * 0.94)
            }

            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(stageColor.opacity(showsBackdrop ? 0.18 : 0.34))
                    .frame(width: size * 0.09, height: size * 0.09)
                    .offset(
                        x: CGFloat(index - 2) * size * 0.18,
                        y: CGFloat((index % 2 == 0) ? -1 : 1) * size * 0.34
                    )
            }

            mascotBody
                .frame(width: size * 0.78, height: size * 0.78)
                .offset(y: size * 0.08)

            Text(stageAccessory)
                .font(.system(size: size * 0.20))
                .offset(x: size * 0.34, y: -size * 0.34)

            Text(evolutionTitle)
                .font(.system(size: size * 0.075, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(stageColor.opacity(0.82))
                .clipShape(Capsule())
                .offset(x: -size * 0.30, y: -size * 0.42)

            if mood == .champion {
                Image(systemName: "crown.fill")
                    .font(.system(size: size * 0.18, weight: .bold))
                    .foregroundStyle(.yellow)
                    .offset(y: -size * 0.43)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.18))
        .shadow(color: Color.black.opacity(0.14), radius: size * 0.07, y: size * 0.035)
        .accessibilityLabel("Boss \(level)")
    }

    private var bossAnimalSeed: Int {
        let source = examTag ?? level
        let digits = source.compactMap { $0.wholeNumberValue }
        if digits.count >= 4 {
            return digits.prefix(4).reduce(0) { $0 * 10 + $1 }
        }
        return level == "N1" ? 2025 : 2010
    }

    private var bossAnimalEmoji: String {
        let animals = ["🐱", "🦊", "🐰", "🐼", "🦝", "🐶", "🦉", "🦫", "🐯", "🦦", "🐧", "🐲", "🐠", "🦌", "🐻", "🦁"]
        return animals[abs(bossAnimalSeed) % animals.count]
    }

    private var bossAnimalName: String {
        let names = [
            "Sakura Cat", "Kitsune Fox", "Mochi Rabbit", "Panda Sensei",
            "Tanuki Master", "Shiba Guard", "Owl Scholar", "Capybara JLPT",
            "Tiger Cub", "Otter Tutor", "Penguin Senpai", "Dragon Finalist",
            "Koi Reader", "Deer Shrine", "Bear Grammarian", "Lion Examiner"
        ]
        return names[abs(bossAnimalSeed) % names.count]
    }

    private var accentColor: Color {
        let palette = [
            Color(red: 1.00, green: 0.58, blue: 0.72),
            Color(red: 1.00, green: 0.62, blue: 0.28),
            Color(red: 0.74, green: 0.58, blue: 1.00),
            Color(red: 0.42, green: 0.76, blue: 0.96),
            Color(red: 0.72, green: 0.50, blue: 0.30),
            Color(red: 0.50, green: 0.78, blue: 0.48)
        ]
        return palette[abs(bossAnimalSeed) % palette.count]
    }

    private var stageColor: Color {
        switch evolutionStage {
        case 1: return accentColor
        case 2: return .cyan
        case 3: return .orange
        case 4: return .red
        default: return .purple
        }
    }

    private var mascotBody: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let robeColor = evolutionStage >= 4 ? Color(red: 0.38, green: 0.10, blue: 0.20) : Color(red: 0.18, green: 0.15, blue: 0.32)
            let isN1 = level == "N1"

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [stageColor.opacity(0.46), Color.clear],
                            center: .center,
                            startRadius: 2,
                            endRadius: width * 0.60
                        )
                    )
                    .frame(width: width * (1.02 + CGFloat(evolutionStage) * 0.03), height: width * (1.02 + CGFloat(evolutionStage) * 0.03))
                    .opacity(mood == .defeated ? 0.25 : 1)

                Capsule()
                    .fill(robeColor)
                    .frame(width: width * 0.82, height: height * 0.32)
                    .offset(y: height * 0.30)
                    .overlay(
                        Capsule()
                            .stroke(stageColor.opacity(0.55), lineWidth: 2)
                            .frame(width: width * 0.82, height: height * 0.32)
                            .offset(y: height * 0.30)
                    )

                Circle()
                    .fill(Color.white.opacity(0.82))
                    .frame(width: width * 0.62, height: width * 0.62)
                    .offset(y: -height * 0.02)
                    .shadow(color: stageColor.opacity(0.30), radius: width * 0.08)

                Text(bossAnimalEmoji)
                    .font(.system(size: width * (0.46 + CGFloat(evolutionStage) * 0.015)))
                    .scaleEffect(mood == .pressured ? 0.96 : 1)
                    .rotationEffect(.degrees(evolutionStage >= 3 ? -4 : 0))
                    .offset(y: -height * 0.02)
                    .shadow(color: stageColor.opacity(0.30), radius: width * 0.04, y: width * 0.02)

                Capsule()
                    .fill(Color.white)
                    .overlay(Capsule().stroke(stageColor.opacity(0.75), lineWidth: 1.2))
                    .frame(width: width * 0.70, height: height * 0.17)
                    .rotationEffect(.degrees(-4))
                    .offset(y: -height * 0.36)
                    .overlay(
                        Text("\(level) 合格")
                            .font(.system(size: width * 0.13, weight: .black, design: .rounded))
                            .foregroundStyle(Color(red: 0.16, green: 0.12, blue: 0.16))
                            .rotationEffect(.degrees(-4))
                            .offset(y: -height * 0.36)
                    )

                RoundedRectangle(cornerRadius: width * 0.07)
                    .fill(isN1 ? Color(red: 0.45, green: 0.10, blue: 0.28) : Color(red: 0.12, green: 0.32, blue: 0.22))
                    .overlay(RoundedRectangle(cornerRadius: width * 0.07).stroke(Color.yellow.opacity(0.55), lineWidth: 1))
                    .frame(width: width * 0.27, height: height * 0.31)
                    .rotationEffect(.degrees(-8))
                    .offset(x: width * 0.26, y: height * 0.17)
                    .overlay(
                        Text(level)
                            .font(.system(size: width * 0.08, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .rotationEffect(.degrees(-8))
                            .offset(x: width * 0.26, y: height * 0.17)
                    )

                if isN1 {
                    Image(systemName: "crown.fill")
                        .font(.system(size: width * 0.14, weight: .bold))
                        .foregroundStyle(.yellow)
                        .offset(x: -width * 0.25, y: -height * 0.30)
                } else {
                    Image(systemName: "pencil.and.outline")
                        .font(.system(size: width * 0.14, weight: .bold))
                        .foregroundStyle(stageColor)
                        .offset(x: -width * 0.27, y: -height * 0.29)
                }

                if evolutionStage >= 3 {
                    Text(evolutionStage >= 5 ? "!!" : "!")
                        .font(.system(size: width * 0.18, weight: .black, design: .rounded))
                        .foregroundStyle(evolutionStage >= 4 ? .red : .orange)
                        .offset(x: width * 0.34, y: -height * 0.21)
                }

                if mood == .defeated {
                    Text("zzz")
                        .font(.system(size: width * 0.13, weight: .black, design: .rounded))
                        .foregroundStyle(.gray)
                        .rotationEffect(.degrees(-12))
                        .offset(x: width * 0.25, y: -height * 0.18)
                }

                if let examTag {
                    Capsule()
                        .fill(Color(red: 1.0, green: 0.78, blue: 0.48))
                        .overlay(Capsule().stroke(Color.white.opacity(0.55), lineWidth: 1))
                        .frame(width: width * 0.46, height: height * 0.13)
                        .offset(x: width * 0.22, y: -height * 0.45)
                        .overlay(
                            Text(examTag)
                                .font(.system(size: width * 0.070, weight: .black, design: .rounded))
                                .foregroundStyle(Color(red: 0.20, green: 0.12, blue: 0.15))
                                .offset(x: width * 0.22, y: -height * 0.45)
                        )
                }

                HPBadge(ratio: hpRatio, color: stageColor, mood: mood)
                    .frame(width: width * 0.32, height: height * 0.08)
                    .offset(x: -width * 0.25, y: -height * 0.43)

                Text(bossAnimalName)
                    .font(.system(size: width * 0.065, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.86))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.34))
                    .clipShape(Capsule())
                    .offset(y: height * 0.43)
            }
        }
    }

    private struct HPBadge: View {
        let ratio: Double
        let color: Color
        let mood: BossMood

        var body: some View {
            Capsule()
                .fill(Color.black.opacity(0.36))
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(mood == .defeated ? Color.gray : color)
                        .frame(maxWidth: .infinity)
                        .scaleEffect(x: max(0.06, min(1, ratio)), y: 1, anchor: .leading)
                        .padding(2)
                }
                .overlay(Capsule().stroke(Color.white.opacity(0.35), lineWidth: 1))
        }
    }
}

private struct BossArenaBackground: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.16, green: 0.12, blue: 0.30),
                        Color(red: 0.52, green: 0.30, blue: 0.55),
                        Color(red: 0.98, green: 0.70, blue: 0.78)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [Color.white.opacity(0.35), Color.clear],
                    center: .topTrailing,
                    startRadius: 4,
                    endRadius: max(width, height) * 0.75
                )

                Path { path in
                    path.move(to: CGPoint(x: 0, y: height * 0.02))
                    path.addQuadCurve(
                        to: CGPoint(x: width, y: height * 0.08),
                        control: CGPoint(x: width * 0.46, y: height * 0.20)
                    )
                    path.addLine(to: CGPoint(x: width, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: 0))
                    path.closeSubpath()
                }
                .fill(Color(red: 0.18, green: 0.09, blue: 0.08).opacity(0.55))

                ForEach(0..<4, id: \.self) { index in
                    let x = width * (0.16 + CGFloat(index) * 0.22)
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color(red: 0.35, green: 0.18, blue: 0.12).opacity(0.65))
                            .frame(width: 2, height: height * 0.14)
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color(red: 1.0, green: 0.84, blue: 0.52).opacity(0.76))
                            .frame(width: 24, height: 32)
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(Color.white.opacity(0.45), lineWidth: 1)
                            )
                            .shadow(color: Color.orange.opacity(0.45), radius: 12)
                    }
                    .offset(x: x - width / 2, y: -height * 0.30 + CGFloat(index % 2) * 16)
                }

                ForEach(0..<18, id: \.self) { index in
                    SakuraPetal()
                        .fill(Color(red: 1.0, green: 0.62, blue: 0.72).opacity(0.42))
                        .frame(width: 12 + CGFloat(index % 4) * 3, height: 9 + CGFloat(index % 3) * 2)
                        .rotationEffect(.degrees(Double(index * 29)))
                        .offset(
                            x: width * (-0.46 + CGFloat((index * 37) % 100) / 100),
                            y: height * (-0.38 + CGFloat((index * 23) % 82) / 100)
                        )
                }

                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color(red: 1.0, green: 0.78, blue: 0.48).opacity(0.48), lineWidth: 1.5)
                    .padding(6)
            }
        }
    }
}

private struct SakuraPetal: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.midY), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        return path
    }
}

private struct GameAppBackground: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.91, blue: 0.82),
                        Color(red: 0.93, green: 0.88, blue: 0.98),
                        Color(red: 0.86, green: 0.95, blue: 0.91)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                RadialGradient(
                    colors: [Color(red: 1.0, green: 0.67, blue: 0.80).opacity(0.28), Color.clear],
                    center: .topTrailing,
                    startRadius: 12,
                    endRadius: max(width, height) * 0.70
                )
                RadialGradient(
                    colors: [Color(red: 0.93, green: 0.78, blue: 0.44).opacity(0.25), Color.clear],
                    center: .bottomLeading,
                    startRadius: 16,
                    endRadius: max(width, height) * 0.62
                )

                ForEach(0..<26, id: \.self) { index in
                    SakuraPetal()
                        .fill(Color(red: 1.0, green: 0.66, blue: 0.76).opacity(0.22))
                        .frame(width: 10 + CGFloat(index % 5) * 2, height: 8 + CGFloat(index % 4) * 2)
                        .rotationEffect(.degrees(Double(index * 31)))
                        .offset(
                            x: width * (-0.48 + CGFloat((index * 41) % 100) / 100),
                            y: height * (-0.46 + CGFloat((index * 29) % 100) / 100)
                        )
                }

                Path { path in
                    path.move(to: CGPoint(x: 0, y: height * 0.86))
                    path.addQuadCurve(
                        to: CGPoint(x: width, y: height * 0.78),
                        control: CGPoint(x: width * 0.46, y: height * 0.66)
                    )
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height))
                    path.closeSubpath()
                }
                .fill(Color(red: 0.16, green: 0.09, blue: 0.10).opacity(0.18))
            }
            .ignoresSafeArea()
        }
    }
}

private struct GamePaperBackground: View {
    var selected: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(
                selected
                ? LinearGradient(
                    colors: [Color.green, Color(red: 0.09, green: 0.54, blue: 0.48)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                : LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.95, blue: 0.84),
                        Color(red: 0.95, green: 0.88, blue: 0.75)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(red: 0.58, green: 0.33, blue: 0.20).opacity(selected ? 0.0 : 0.28), lineWidth: 1)
            )
    }
}

#if os(macOS)
private struct KeyboardNavigationHandler: NSViewRepresentable {
    let onMove: (Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onMove: onMove)
    }

    func makeNSView(context: Context) -> KeyCatcherNSView {
        let view = KeyCatcherNSView()
        context.coordinator.installMonitor()
        return view
    }

    func updateNSView(_ nsView: KeyCatcherNSView, context: Context) {
        context.coordinator.onMove = onMove
        context.coordinator.installMonitor()
    }

    static func dismantleNSView(_ nsView: KeyCatcherNSView, coordinator: Coordinator) {
        coordinator.removeMonitor()
    }

    final class Coordinator {
        var onMove: (Int) -> Void
        private var monitor: Any?

        init(onMove: @escaping (Int) -> Void) {
            self.onMove = onMove
        }

        func installMonitor() {
            guard monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self else { return event }
                if event.modifierFlags.intersection([.command, .option, .control]).isEmpty {
                    switch event.keyCode {
                    case 123:
                        self.onMove(-1)
                        return nil
                    case 124:
                        self.onMove(1)
                        return nil
                    default:
                        break
                    }
                }
                return event
            }
        }

        func removeMonitor() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
        }
    }
}

private final class KeyCatcherNSView: NSView {}
#elseif canImport(UIKit)
private struct KeyboardNavigationHandler: UIViewRepresentable {
    let onMove: (Int) -> Void

    func makeUIView(context: Context) -> KeyCatcherUIView {
        let view = KeyCatcherUIView()
        view.onMove = onMove
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        DispatchQueue.main.async {
            view.becomeFirstResponder()
        }
        return view
    }

    func updateUIView(_ uiView: KeyCatcherUIView, context: Context) {
        uiView.onMove = onMove
    }
}

private final class KeyCatcherUIView: UIView {
    var onMove: ((Int) -> Void)?

    override var canBecomeFirstResponder: Bool { true }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        DispatchQueue.main.async {
            self.becomeFirstResponder()
        }
    }

    override var keyCommands: [UIKeyCommand]? {
        [
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(previousQuestion)),
            UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(nextQuestion))
        ]
    }

    @objc private func previousQuestion() {
        onMove?(-1)
    }

    @objc private func nextQuestion() {
        onMove?(1)
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            guard let key = press.key,
                  key.modifierFlags.intersection([.command, .alternate, .control]).isEmpty else {
                continue
            }
            switch key.keyCode {
            case .keyboardLeftArrow:
                onMove?(-1)
                return
            case .keyboardRightArrow:
                onMove?(1)
                return
            default:
                break
            }
        }
        super.pressesBegan(presses, with: event)
    }
}
#else
private struct KeyboardNavigationHandler: View {
    let onMove: (Int) -> Void
    var body: some View { EmptyView() }
}
#endif

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = QuestionStore()
    @StateObject private var dictionary = StudyDictionaryStore()
    @StateObject private var speech = SpeechController()
    @StateObject private var audio = GameAudioManager()
    @State private var gameScreen: GameScreen = .mainMenu
    @State private var playerProfiles: [PlayerProfile] = ContentView.loadPlayerProfiles()
    @State private var activePlayerID: UUID?
    @State private var isBossRunMode = false
    @State private var newPlayerName = ""
    @State private var showsGameOverPrompt = false
    @State private var selectedExamID: String?
    @State private var selectedQuestionIndex = 0
    @State private var questionTransitionDirection = 1
    @State private var selectedAnswer: Int?
    @State private var answerHistory: [String: Int] = ContentView.loadAnswerHistory()
    @State private var bossStates: [String: BossRunState] = ContentView.loadBossStates()
    @State private var didPreloadGameAssets = false
    @State private var now = Date()
    @State private var showsQuestionPicker = false
    @State private var scratchDrawing = PKDrawing()
    @State private var showsScratchPad = false
    @State private var showsAnswerSheet = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var searchText = ""
    @State private var expandedExplanationQuestionIDs: Set<String> = []
    @State private var expandedStudyNoteQuestionIDs: Set<String> = []
    @State private var selectedLevel = "N1"
    @State private var selectedLibraryTab = "Từng phần"
    @State private var selectedDrill: PracticeDrill?
    @State private var drillQuestionsByType: [PracticeDrill: [PracticeQuestion]] = [:]
    @State private var questionSearchIndex: [String: String] = [:]
    @State private var bossHitPulse = false
    @State private var playerHitPulse = false
    @State private var battleFlashText: String?
    @State private var studyReminderStatus = ""
    @State private var studyReminderHour = UserDefaults.standard.integer(forKey: "TiengNhatVaKeToan.studyReminderHour.v1") == 0 ? 20 : UserDefaults.standard.integer(forKey: "TiengNhatVaKeToan.studyReminderHour.v1")
    @State private var studyReminderMinute = UserDefaults.standard.integer(forKey: "TiengNhatVaKeToan.studyReminderMinute.v1")
    @State private var studyReminderSlots: [StudyReminderSlot] = ContentView.loadStudyReminderSlots()
    @State private var studyReminderEnabled = UserDefaults.standard.bool(forKey: "TiengNhatVaKeToan.studyReminderEnabled.v1")
    @FocusState private var questionNavigationFocused: Bool
    private static let answerHistoryKey = "TiengNhatVaKeToan.answerHistory.v1"
    private static let bossStatesKey = "TiengNhatVaKeToan.bossStates.v1"
    private static let playerProfilesKey = "TiengNhatVaKeToan.playerProfiles.v1"
    private static let studyReminderEnabledKey = "TiengNhatVaKeToan.studyReminderEnabled.v1"
    private static let studyReminderHourKey = "TiengNhatVaKeToan.studyReminderHour.v1"
    private static let studyReminderMinuteKey = "TiengNhatVaKeToan.studyReminderMinute.v1"
    private static let studyReminderSlotsKey = "TiengNhatVaKeToan.studyReminderSlots.v1"
    private static let studyReminderLegacyID = "jlpt.daily.flashcard"
    private static let bossTotalHP: Double = 120
    private static let bossSectionHP: Double = 60
    private static let bossTimeLimit: TimeInterval = 100 * 60
    private static let bossStartingHearts = 5
    private static let bossMaxHearts = 20
    private let libraryTabs = ["Từng phần"]

    private var jlptDaysRemaining: Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        let today = calendar.startOfDay(for: now)
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = 2026
        components.month = 7
        components.day = 5
        let examDay = calendar.startOfDay(for: components.date ?? now)
        return max(0, calendar.dateComponents([.day], from: today, to: examDay).day ?? 0)
    }

    var selectedQuestions: [PracticeQuestion] {
        if let selectedDrill {
            return cachedQuestions(for: selectedDrill)
        }
        return store.questions(for: selectedExamID)
    }

    var currentQuestion: PracticeQuestion? {
        guard selectedQuestions.indices.contains(selectedQuestionIndex) else { return nil }
        return selectedQuestions[selectedQuestionIndex]
    }

    var searchResults: [PracticeQuestion] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        return store.allQuestions
            .filter { question in
                let searchableText = questionSearchIndex[question.id] ?? Self.questionSearchText(for: question)
                return searchableText.localizedCaseInsensitiveContains(query)
            }
    }

    var examsForSelectedLevel: [ExamDocument] {
        store.exams.filter { $0.normalizedLevel == selectedLevel }
    }

    private var supportsScratchPad: Bool {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        return UIDevice.current.userInterfaceIdiom == .pad
            && !ProcessInfo.processInfo.isiOSAppOnMac
        #else
        return false
        #endif
    }

    private func preloadGameAssetsIfNeeded() {
        guard !didPreloadGameAssets else { return }
        didPreloadGameAssets = true
        let questions = store.allQuestions
        let bossImageNames = store.exams.map { BossArtView.fileName(for: $0) }

        DispatchQueue.global(qos: .userInitiated).async {
            var drillCache: [PracticeDrill: [PracticeQuestion]] = [:]
            for drill in PracticeDrill.allCases {
                drillCache[drill] = questions.filter(drill.matches)
            }

            var searchIndex: [String: String] = [:]
            searchIndex.reserveCapacity(questions.count)
            for question in questions {
                searchIndex[question.id] = Self.questionSearchText(for: question)
            }

            DispatchQueue.main.async {
                drillQuestionsByType = drillCache
                questionSearchIndex = searchIndex
            }

            #if canImport(UIKit) || canImport(AppKit)
            BossImageCache.shared.preload(fileNames: bossImageNames)
            #endif
        }
    }

    private func rebuildDrillQuestionCache() {
        var cache: [PracticeDrill: [PracticeQuestion]] = [:]
        for drill in PracticeDrill.allCases {
            cache[drill] = store.allQuestions.filter(drill.matches)
        }
        drillQuestionsByType = cache
    }

    private func cachedQuestions(for drill: PracticeDrill) -> [PracticeQuestion] {
        if let cached = drillQuestionsByType[drill] {
            return cached
        }
        return store.allQuestions.filter(drill.matches)
    }

    var practiceTitle: String {
        if let selectedDrill {
            return selectedDrill.title
        }
        if let question = currentQuestion {
            return "\(question.examLevel) \(question.examTitle)"
        }
        return ""
    }

    var body: some View {
        ZStack {
            GameAppBackground()
            switch gameScreen {
            case .mainMenu:
                mainMenu
            case .newGame:
                newGameScreen
            case .continueGame:
                continueGameScreen
            case .bossMap:
                bossMapScreen
            case .practice:
                practiceAppShell
            case .settings:
                settingsScreen
            }
        }
        .alert("Thua cuộc", isPresented: $showsGameOverPrompt) {
            Button("Chơi lại từ đầu", role: .destructive) {
                restartActivePlayer()
            }
            Button("Về menu") {
                gameScreen = .mainMenu
            }
        } message: {
            Text("Bạn đã hết tim hoặc không đạt tối thiểu 100/120 điểm.")
        }
        .onAppear {
            preloadGameAssetsIfNeeded()
            sanitizeSavedTimers()
        }
        .onChange(of: gameScreen) { _, screen in
            if screen == .practice {
                resumeBossTimerIfNeeded()
            } else {
                pauseBossTimerIfNeeded()
            }
        }
    }

    @ViewBuilder
    private var practiceAppShell: some View {
        if horizontalSizeClass == .compact {
            NavigationStack {
                compactContent
            }
            .background(GameAppBackground())
        } else {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                sidebar
            } detail: {
                practiceShell
                    .toolbar {
                        ToolbarItemGroup(placement: appLeadingToolbarPlacement) {
                            if selectedExamID != nil || selectedDrill != nil {
                                Button {
                                    pauseBossTimerIfNeeded()
                                    saveCurrentProfile()
                                    gameScreen = .bossMap
                                } label: {
                                    Image(systemName: "map")
                                }
                                .accessibilityLabel("Map boss")

                                Button {
                                    speakCurrentQuestion()
                                } label: {
                                    Image(systemName: speech.isSpeaking ? "speaker.slash.circle" : "speaker.wave.2.circle")
                                }
                                .accessibilityLabel(speech.isSpeaking ? "Dừng đọc" : "Đọc câu hiện tại")

                                if supportsScratchPad {
                                    Button {
                                        showsScratchPad = true
                                    } label: {
                                        Image(systemName: "pencil.tip.crop.circle")
                                    }
                                    .accessibilityLabel("Nháp")
                                }

                                Button {
                                    showsAnswerSheet = true
                                } label: {
                                    Image(systemName: "checklist")
                                }
                                .accessibilityLabel("Đáp án")
                            }
                        }
                        ToolbarItem(placement: appTrailingToolbarPlacement) {
                            Button {
                                pauseBossTimerIfNeeded()
                                saveCurrentProfile()
                                audio.play(.save)
                                gameScreen = .mainMenu
                            } label: {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                            }
                            .accessibilityLabel("Lưu và thoát")
                        }
                    }
            }
            .background(GameAppBackground())
        }
    }

    private var mainMenu: some View {
        VStack(spacing: 22) {
            Spacer()
            VStack(spacing: 8) {
                Text("BOSS Japan")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.16, green: 0.12, blue: 0.20))
                Text("JLPT Boss Quest")
                    .font(.title3.bold())
                    .foregroundStyle(.orange)
                Label("\(jlptDaysRemaining) ngày tới JLPT 5/7", systemImage: "calendar.badge.clock")
                    .font(.headline.bold())
                    .foregroundStyle(.green)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.72))
                    .clipShape(Capsule())
            }
            if let heroExam = store.exams.last {
                BossArtView(exam: heroExam, mood: .normal, size: 170, hpRatio: 1)
            } else {
                BossMascotView(level: "N1", examTag: "2010→2025", hpRatio: 1, mood: .normal, size: 170)
            }
            VStack(spacing: 14) {
                gameMenuButton("Chơi mới", systemImage: "sparkles") {
                    newPlayerName = ""
                    gameScreen = .newGame
                }
                gameMenuButton("Tiếp tục", systemImage: "person.2.fill") {
                    gameScreen = .continueGame
                }
                gameMenuButton("Luyện từng phần", systemImage: "square.grid.2x2.fill") {
                    enterPracticeHome(tab: "Từng phần")
                }
                gameMenuButton("Cài đặt", systemImage: "gearshape.fill") {
                    gameScreen = .settings
                }
            }
            .frame(maxWidth: 420)
            Spacer()
        }
        .padding(28)
    }

    private var settingsScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Cài đặt")
                        .font(.largeTitle.bold())
                    Spacer()
                    gameSmallButton("Back", systemImage: "chevron.left") {
                        gameScreen = .mainMenu
                    }
                }

                settingsCard(title: "Âm thanh", systemImage: audio.isEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill") {
                    Toggle(isOn: $audio.isEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(audio.isEnabled ? "Âm thanh: Bật" : "Âm thanh: Tắt")
                                .font(.headline)
                            Text("Bật/tắt nhạc nền và hiệu ứng khi đánh boss.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .toggleStyle(.switch)
                }

                settingsCard(title: "Nhắc học + Flash Card", systemImage: "bell.badge.fill") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $studyReminderEnabled) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(studyReminderEnabled ? "Nhắc học: Bật" : "Nhắc học: Tắt")
                                    .font(.headline)
                                Text("Mỗi khung giờ gửi một flash card từ vựng/ngữ pháp.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .toggleStyle(.switch)
                        .onChange(of: studyReminderEnabled) { enabled in
                            if enabled {
                                scheduleStudyReminder()
                            } else {
                                cancelStudyReminder()
                            }
                        }

                        HStack {
                            Picker("Giờ", selection: $studyReminderHour) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text(String(format: "%02d", hour)).tag(hour)
                                }
                            }
                            #if os(macOS)
                            .pickerStyle(.menu)
                            .frame(width: 90)
                            #else
                            .pickerStyle(.wheel)
                            .frame(width: 90, height: 96)
                            .clipped()
                            #endif

                            Text(":")
                                .font(.title2.bold())

                            Picker("Phút", selection: $studyReminderMinute) {
                                ForEach([0, 10, 20, 30, 40, 50], id: \.self) { minute in
                                    Text(String(format: "%02d", minute)).tag(minute)
                                }
                            }
                            #if os(macOS)
                            .pickerStyle(.menu)
                            .frame(width: 90)
                            #else
                            .pickerStyle(.wheel)
                            .frame(width: 90, height: 96)
                            .clipped()
                            #endif

                            Spacer()

                            Button {
                                studyReminderEnabled = true
                                addStudyReminderSlot()
                            } label: {
                                Label("Thêm giờ", systemImage: "plus.circle.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }

                        if studyReminderSlots.isEmpty {
                            Text("Chưa có giờ nhắc học nào.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                                ForEach(studyReminderSlots) { slot in
                                    HStack(spacing: 6) {
                                        Image(systemName: "bell.fill")
                                            .font(.caption)
                                        Text(slot.label)
                                            .font(.headline.bold())
                                        Button {
                                            removeStudyReminderSlot(slot)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel("Xoá giờ \(slot.label)")
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.72))
                                    .clipShape(Capsule())
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Flash Card mẫu")
                                .font(.caption.bold())
                                .foregroundStyle(.orange)
                            Text(studyFlashcardText(offset: 0))
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.72))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        if !studyReminderStatus.isEmpty {
                            Text(studyReminderStatus)
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                        }
                    }
                }

                settingsCard(title: "Hướng dẫn chơi", systemImage: "questionmark.circle.fill") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Chọn đáp án bằng nút tròn bên phải.")
                        Text("• Bôi chữ Nhật để tra/copy như bình thường.")
                        Text("• Đánh boss bằng cách trả lời đúng. Đạt 100/120 điểm là thắng.")
                        Text("• Tim ban đầu 5/20. Combo 6 hồi dần tới tối đa 20/20.")
                        Text("• Thua boss thì save chuyển thành thua cuộc, chỉ xem lại được.")
                    }
                }

                settingsCard(title: "Combo", systemImage: "bolt.fill") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Combo 3: +10 phút thời gian.")
                        Text("Combo 5: mở lại 1 câu đã làm sai.")
                        Text("Combo 6: hồi 1 tim.")
                    }
                }

                settingsCard(title: "Boss tiến hóa theo HP", systemImage: "sparkles") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("100%: Bình thường")
                        Text("80%: Cảnh giác")
                        Text("60%: Tức giận")
                        Text("40%: Áp lực")
                        Text("20%: Cuồng nộ / sắp bị hạ")
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 760, alignment: .leading)
        }
        .background(GameAppBackground())
    }

    private func settingsCard<Content: View>(title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.title3.bold())
                .foregroundStyle(.orange)
            content()
                .font(.body)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GamePaperBackground())
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var newGameScreen: some View {
        VStack(spacing: 22) {
            Text("Chơi mới")
                .font(.largeTitle.bold())
            Text("Đặt tên người chơi để bắt đầu hành trình hạ boss từ 2010 đến 2025.")
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            TextField("Tên người chơi", text: $newPlayerName)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 420)
            HStack {
                gameMenuButton("Back", systemImage: "chevron.left") {
                    gameScreen = .mainMenu
                }
                gameMenuButton("Bắt đầu", systemImage: "play.fill") {
                    createNewPlayer()
                }
                .disabled(newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .frame(maxWidth: 520)
        }
        .padding(28)
    }

    private var continueGameScreen: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Tiếp tục")
                    .font(.largeTitle.bold())
                Spacer()
                gameSmallButton("Back", systemImage: "chevron.left") {
                    gameScreen = .mainMenu
                }
            }
            Text("Chọn người chơi còn sống")
                .font(.headline)
                .foregroundStyle(.secondary)

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(playerProfiles) { profile in
                        playerSaveRow(profile)
                    }
                    if playerProfiles.isEmpty {
                        ContentUnavailableView("Chưa có save", systemImage: "heart.slash", description: Text("Hãy tạo người chơi mới để bắt đầu."))
                            .padding()
                    }
                }
            }
        }
        .padding(28)
        .onAppear {
            pauseBossTimerIfNeeded()
            sanitizeSavedTimers()
        }
    }

    private func profilePerfectBossCount(_ profile: PlayerProfile) -> Int {
        profile.bossStates.values.filter { state in
            state.didWin && state.heartsLeft == Self.bossMaxHearts
        }.count
    }

    private func profileWinStreak(_ profile: PlayerProfile) -> Int {
        let exams = store.exams.sorted { lhs, rhs in
            if lhs.year != rhs.year { return lhs.year < rhs.year }
            if lhs.month != rhs.month { return lhs.month < rhs.month }
            if lhs.normalizedLevel != rhs.normalizedLevel {
                return lhs.normalizedLevel == "N2"
            }
            return lhs.id < rhs.id
        }
        var streak = 0
        for exam in exams {
            guard let state = profile.bossStates[exam.id] else { break }
            if state.didWin {
                streak += 1
            } else if state.finishedAt != nil {
                break
            } else {
                break
            }
        }
        return streak
    }

    private func profileCampaignRank(_ profile: PlayerProfile) -> String {
        let defeated = profile.defeatedBossCount
        let perfect = profilePerfectBossCount(profile)
        if defeated >= 32 && perfect >= 10 { return "SS" }
        if defeated >= 24 { return "S" }
        if defeated >= 16 { return "A" }
        if defeated >= 8 { return "B" }
        if defeated >= 3 { return "C" }
        return "D"
    }

    private func profileTimerInfo(_ profile: PlayerProfile) -> (text: String, isDanger: Bool) {
        let states = Self.pausedBossStates(profile.bossStates)
        if let activeExam = store.exams.first(where: { exam in
            guard let state = states[exam.id] else { return false }
            return state.finishedAt == nil
        }), let state = states[activeExam.id] {
            let remaining = max(0, Self.bossTimeLimit - state.activeElapsed)
            return ("\(activeExam.normalizedLevel) \(activeExam.title): \(formattedBossTime(remaining))", remaining <= 600)
        }

        if let nextExam = store.exams.first(where: { !profileHasPassed(profile, examID: $0.id) }) {
            return ("Boss tiếp: \(nextExam.normalizedLevel) \(nextExam.title) · \(formattedBossTime(Self.bossTimeLimit))", false)
        }

        return ("Đã hoàn thành toàn bộ map", false)
    }

    private func profileHasPassed(_ profile: PlayerProfile, examID: String) -> Bool {
        if profile.bossStates[examID]?.didWin == true { return true }
        return profileScore(profile, examID: examID) >= 100
    }

    private func profileScore(_ profile: PlayerProfile, examID: String) -> Int {
        let questions = store.questions(for: examID)
        guard !questions.isEmpty else { return 0 }
        var languageTotal = 0
        var readingTotal = 0
        var languageCorrect = 0
        var readingCorrect = 0

        for question in questions {
            let correctIndex = (question.correctAnswer ?? -1) - 1
            let isCorrect = profile.answerHistory[question.id] == correctIndex
            if question.sectionTitle == "Đọc hiểu" {
                readingTotal += 1
                if isCorrect { readingCorrect += 1 }
            } else {
                languageTotal += 1
                if isCorrect { languageCorrect += 1 }
            }
        }

        let languageDamage = languageTotal == 0 ? 0 : Self.bossSectionHP / Double(languageTotal)
        let readingDamage = readingTotal == 0 ? 0 : Self.bossSectionHP / Double(readingTotal)
        let languageHP = max(0, Self.bossSectionHP - Double(languageCorrect) * languageDamage)
        let readingHP = max(0, Self.bossSectionHP - Double(readingCorrect) * readingDamage)
        return Int((Self.bossTotalHP - languageHP - readingHP).rounded())
    }

    private var bossMapScreen: some View {
        let exams = store.exams.sorted { lhs, rhs in
            if lhs.year != rhs.year { return lhs.year < rhs.year }
            if lhs.month != rhs.month { return lhs.month < rhs.month }
            if lhs.normalizedLevel != rhs.normalizedLevel {
                return lhs.normalizedLevel == "N2"
            }
            return lhs.id < rhs.id
        }

        let years = Array(Set(exams.map(\.year))).sorted()
        let defeatedCount = exams.filter { bossHasPassed($0.id) }.count
        let unlockedCount = exams.enumerated().filter { bossMapIsUnlocked(index: $0.offset, exams: exams) }.count
        let currentStageText = bossMapCurrentStageText(exams: exams)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Map Boss")
                        .font(.largeTitle.bold())
                    Text("Chinh phục JLPT 2010 → 2025")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 10) {
                        Label("Đường đi boss", systemImage: "map.fill")
                        Label("100/120 để thắng", systemImage: "star.fill")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                }
                Spacer()
                gameSmallButton("Lưu & thoát", systemImage: "square.and.arrow.down") {
                    pauseBossTimerIfNeeded()
                    saveCurrentProfile()
                    audio.play(.save)
                    gameScreen = .mainMenu
                }
            }

            bossMapCampaignSummary(
                defeatedCount: defeatedCount,
                unlockedCount: unlockedCount,
                totalCount: exams.count,
                currentStageText: currentStageText
            )

            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(years, id: \.self) { year in
                        let yearExams = exams.filter { $0.year == year }
                        let yearDefeated = yearExams.filter { bossHasPassed($0.id) }.count

                        VStack(spacing: 0) {
                            bossMapWorldHeader(year: year, defeated: yearDefeated, total: yearExams.count)

                            ForEach(Array(yearExams.enumerated()), id: \.element.id) { localIndex, exam in
                                if let globalIndex = exams.firstIndex(where: { $0.id == exam.id }) {
                                    bossMapStageRow(
                                        exam,
                                        globalIndex: globalIndex,
                                        localIndex: localIndex,
                                        totalInCampaign: exams.count,
                                        exams: exams
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(20)
    }

    private func bossMapWorldHeader(year: Int, defeated: Int, total: Int) -> some View {
        let progress = total == 0 ? 0 : Double(defeated) / Double(total)
        let world = bossWorldTheme(for: year)

        return HStack(spacing: 12) {
            Text(world.icon)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("WORLD \(year)")
                    .font(.headline.bold())
                    .foregroundStyle(world.accent)
                Text(world.title)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: progress)
                .tint(defeated == total && total > 0 ? .green : world.accent)
            Text("\(defeated)/\(total)")
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(world.light.opacity(0.76))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(Color.white.opacity(0.55), lineWidth: 1)
        )
        .padding(.bottom, 4)
    }

    private func bossMapStageRow(
        _ exam: ExamDocument,
        globalIndex: Int,
        localIndex: Int,
        totalInCampaign: Int,
        exams: [ExamDocument]
    ) -> some View {
        let isLeft = localIndex.isMultiple(of: 2)
        let isUnlocked = bossMapIsUnlocked(index: globalIndex, exams: exams)

        return HStack(spacing: 0) {
            if isLeft {
                bossMapNodeCard(exam, isUnlocked: isUnlocked)
                Spacer(minLength: 12)
                bossMapSimpleRoadNode(exam: exam, isUnlocked: isUnlocked, isFirst: globalIndex == 0, isLast: globalIndex == totalInCampaign - 1)
                Spacer(minLength: 46)
            } else {
                Spacer(minLength: 46)
                bossMapSimpleRoadNode(exam: exam, isUnlocked: isUnlocked, isFirst: globalIndex == 0, isLast: globalIndex == totalInCampaign - 1)
                Spacer(minLength: 12)
                bossMapNodeCard(exam, isUnlocked: isUnlocked)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 132)
        .padding(.horizontal, 12)
        .opacity(isUnlocked ? 1 : 0.48)
    }

    private func bossMapSimpleRoadNode(exam: ExamDocument, isUnlocked: Bool, isFirst: Bool, isLast: Bool) -> some View {
        let state = bossStates[exam.id]
        let didWin = state?.didWin == true
        let isRunning = state != nil && state?.finishedAt == nil
        let nodeColor: Color = didWin ? .green : (isRunning ? .orange : (isUnlocked ? .orange : .gray))

        return VStack(spacing: 0) {
            Rectangle()
                .fill(isFirst ? Color.clear : Color(red: 0.62, green: 0.42, blue: 0.24).opacity(0.55))
                .frame(width: 8, height: 38)
                .clipShape(Capsule())
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.82))
                    .frame(width: 40, height: 40)
                Circle()
                    .strokeBorder(nodeColor.opacity(0.92), lineWidth: 4)
                    .frame(width: 30, height: 30)
                Image(systemName: !isUnlocked ? "lock.fill" : (didWin ? "crown.fill" : (isRunning ? "flame.fill" : "pawprint.fill")))
                    .font(.caption.bold())
                    .foregroundStyle(!isUnlocked ? .gray : (didWin ? .yellow : nodeColor))
            }
            Rectangle()
                .fill(isLast ? Color.clear : Color(red: 0.62, green: 0.42, blue: 0.24).opacity(didWin || isRunning ? 0.62 : 0.30))
                .frame(width: 8, height: 38)
                .clipShape(Capsule())
        }
        .frame(width: 48)
        .allowsHitTesting(false)
    }

    private func bossMapRoadSegment(isLeft: Bool, isFirst: Bool, isLast: Bool) -> some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 320)
            let height = proxy.size.height
            let currentX = isLeft ? width * 0.28 : width * 0.72
            let otherX = isLeft ? width * 0.72 : width * 0.28

            ZStack {
                Path { path in
                    if isFirst {
                        path.move(to: CGPoint(x: currentX, y: 0))
                        path.addLine(to: CGPoint(x: currentX, y: height * 0.50))
                    } else {
                        path.move(to: CGPoint(x: otherX, y: 0))
                        path.addCurve(
                            to: CGPoint(x: currentX, y: height * 0.50),
                            control1: CGPoint(x: otherX, y: height * 0.20),
                            control2: CGPoint(x: currentX, y: height * 0.24)
                        )
                    }

                    if !isLast {
                        path.addCurve(
                            to: CGPoint(x: otherX, y: height),
                            control1: CGPoint(x: currentX, y: height * 0.78),
                            control2: CGPoint(x: otherX, y: height * 0.74)
                        )
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.90, blue: 0.72),
                            Color(red: 0.92, green: 0.73, blue: 0.52)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 22, lineCap: .round, lineJoin: .round)
                )

                Path { path in
                    if isFirst {
                        path.move(to: CGPoint(x: currentX, y: 0))
                        path.addLine(to: CGPoint(x: currentX, y: height * 0.50))
                    } else {
                        path.move(to: CGPoint(x: otherX, y: 0))
                        path.addCurve(
                            to: CGPoint(x: currentX, y: height * 0.50),
                            control1: CGPoint(x: otherX, y: height * 0.20),
                            control2: CGPoint(x: currentX, y: height * 0.24)
                        )
                    }

                    if !isLast {
                        path.addCurve(
                            to: CGPoint(x: otherX, y: height),
                            control1: CGPoint(x: currentX, y: height * 0.78),
                            control2: CGPoint(x: otherX, y: height * 0.74)
                        )
                    }
                }
                .stroke(Color.white.opacity(0.38), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            }
        }
        .allowsHitTesting(false)
    }

    private func bossMapNodeCard(_ exam: ExamDocument, isUnlocked: Bool) -> some View {
        let metrics = bossMetrics(for: exam.id)
        let state = bossStates[exam.id]
        let score = bossScore(for: metrics)
        let didWin = state?.didWin == true
        let isRunning = state != nil && state?.finishedAt == nil
        let isPerfect = bossIsPerfect(state: state, score: score)
        let world = bossWorldTheme(for: exam.year)

        return Button {
            guard isUnlocked else { return }
            selectExam(exam.id)
            isBossRunMode = true
            audio.play(.boss)
            gameScreen = .practice
        } label: {
            VStack(spacing: 5) {
                ZStack(alignment: .topTrailing) {
                    BossArtView(
                        exam: exam,
                        mood: moodForMapNode(didWin: didWin, isRunning: isRunning),
                        size: 82,
                        hpRatio: metrics.totalHP / Self.bossTotalHP,
                        showsYearBadge: false
                    )

                    Image(systemName: !isUnlocked ? "lock.fill" : (didWin ? "crown.fill" : (isRunning ? "flame.fill" : "pawprint.fill")))
                        .font(.caption.bold())
                        .foregroundStyle(!isUnlocked ? .gray : (didWin ? .yellow : .orange))
                        .padding(5)
                        .background(Color.white.opacity(0.92))
                        .clipShape(Circle())
                }

                Text("\(exam.normalizedLevel) \(exam.month > 0 ? "\(exam.month)" : "")")
                    .font(.caption.bold())
                    .lineLimit(1)
                    .foregroundStyle(isUnlocked ? .primary : .secondary)

                HStack(spacing: 2) {
                    bossMapStar(index: 0, score: score, didWin: didWin)
                    bossMapStar(index: 1, score: score, didWin: didWin)
                    bossMapStar(index: 2, score: score, didWin: didWin || isPerfect)
                }

                Text("\(score)/120")
                    .font(.caption2.bold().monospacedDigit())
                    .foregroundStyle(score >= 100 ? .green : .secondary)
            }
            .padding(7)
            .frame(width: 112)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isUnlocked ? Color.white.opacity(0.84) : Color.gray.opacity(0.18))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(didWin ? Color.yellow.opacity(0.90) : (isUnlocked ? world.accent.opacity(0.50) : Color.gray.opacity(0.25)), lineWidth: didWin ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }

    private func moodForMapNode(didWin: Bool, isRunning: Bool) -> BossMood {
        if didWin { return .defeated }
        if isRunning { return .angry }
        return .normal
    }

    private func bossAnimalEmoji(for exam: ExamDocument) -> String {
        let animals = ["🐱", "🐰", "🦊", "🐼", "🦝", "🐶", "🦉", "🐹", "🐯", "🐧", "🐲", "🐸", "🦁", "🐨", "🦄", "🐉"]
        let offset = exam.normalizedLevel == "N1" ? 7 : 0
        return animals[(max(0, exam.year - 2010) + offset) % animals.count]
    }

    private struct BossWorldTheme {
        let title: String
        let icon: String
        let light: Color
        let accent: Color
    }

    private func bossWorldTheme(for year: Int) -> BossWorldTheme {
        switch year {
        case 2010...2011:
            return BossWorldTheme(title: "Sakura Garden", icon: "🌸", light: Color(red: 1.00, green: 0.84, blue: 0.90), accent: .pink)
        case 2012...2013:
            return BossWorldTheme(title: "Kitsune Shrine", icon: "⛩️", light: Color(red: 1.00, green: 0.82, blue: 0.66), accent: .orange)
        case 2014...2015:
            return BossWorldTheme(title: "Bamboo Forest", icon: "🎋", light: Color(red: 0.78, green: 0.94, blue: 0.68), accent: .green)
        case 2016...2017:
            return BossWorldTheme(title: "Snow Valley", icon: "❄️", light: Color(red: 0.82, green: 0.92, blue: 1.00), accent: .cyan)
        case 2018...2019:
            return BossWorldTheme(title: "Samurai Castle", icon: "🏯", light: Color(red: 0.92, green: 0.84, blue: 1.00), accent: .purple)
        case 2020...2021:
            return BossWorldTheme(title: "Spirit Coast", icon: "🌊", light: Color(red: 0.78, green: 0.93, blue: 1.00), accent: .blue)
        case 2022...2023:
            return BossWorldTheme(title: "Dragon Mountain", icon: "🌋", light: Color(red: 1.00, green: 0.78, blue: 0.62), accent: .red)
        case 2024:
            return BossWorldTheme(title: "Sky Kingdom", icon: "☁️", light: Color(red: 0.86, green: 0.90, blue: 1.00), accent: .indigo)
        default:
            return BossWorldTheme(title: "Dragon Throne", icon: "🐉", light: Color(red: 1.00, green: 0.90, blue: 0.56), accent: .yellow)
        }
    }

    private func bossMapStar(index: Int, score: Int, didWin: Bool) -> some View {
        let earnedStars: Int = {
            guard didWin || score >= 100 else { return 0 }
            if score >= 120 { return 3 }
            if score >= 110 { return 2 }
            return 1
        }()

        return Image(systemName: index < earnedStars ? "star.fill" : "star")
            .font(.caption2.bold())
            .foregroundStyle(index < earnedStars ? .yellow : .gray.opacity(0.42))
    }

    private static func studyReminderIdentifier(_ index: Int) -> String {
        "jlpt.daily.flashcard.\(index)"
    }

    private static var removableStudyReminderIdentifiers: [String] {
        [studyReminderLegacyID] + (0..<64).map { studyReminderIdentifier($0) }
    }

    private static func loadStudyReminderSlots() -> [StudyReminderSlot] {
        if let data = UserDefaults.standard.data(forKey: studyReminderSlotsKey),
           let slots = try? JSONDecoder().decode([StudyReminderSlot].self, from: data),
           !slots.isEmpty {
            return normalizedStudyReminderSlots(slots)
        }
        let hour = UserDefaults.standard.object(forKey: studyReminderHourKey) as? Int ?? 20
        let minute = UserDefaults.standard.object(forKey: studyReminderMinuteKey) as? Int ?? 0
        return [StudyReminderSlot(hour: min(max(hour, 0), 23), minute: min(max(minute, 0), 59))]
    }

    private static func normalizedStudyReminderSlots(_ slots: [StudyReminderSlot]) -> [StudyReminderSlot] {
        Array(Set(slots.map { StudyReminderSlot(hour: min(max($0.hour, 0), 23), minute: min(max($0.minute, 0), 59)) }))
            .sorted { lhs, rhs in
                lhs.hour == rhs.hour ? lhs.minute < rhs.minute : lhs.hour < rhs.hour
            }
    }

    private static func saveStudyReminderSlots(_ slots: [StudyReminderSlot]) {
        let normalized = normalizedStudyReminderSlots(slots)
        if let data = try? JSONEncoder().encode(normalized) {
            UserDefaults.standard.set(data, forKey: studyReminderSlotsKey)
        }
        if let first = normalized.first {
            UserDefaults.standard.set(first.hour, forKey: studyReminderHourKey)
            UserDefaults.standard.set(first.minute, forKey: studyReminderMinuteKey)
        }
    }

    private func studyFlashcardText(offset: Int = 0) -> String {
        dictionary.flashcardText(offset: offset) ?? "今日のカード：毎日少しずつ日本語を復習しましょう。"
    }

    private func addStudyReminderSlot() {
        let slot = StudyReminderSlot(hour: studyReminderHour, minute: studyReminderMinute)
        studyReminderSlots = Self.normalizedStudyReminderSlots(studyReminderSlots + [slot])
        Self.saveStudyReminderSlots(studyReminderSlots)
        studyReminderEnabled = true
        scheduleStudyReminder()
    }

    private func removeStudyReminderSlot(_ slot: StudyReminderSlot) {
        studyReminderSlots.removeAll { $0 == slot }
        Self.saveStudyReminderSlots(studyReminderSlots)
        if studyReminderSlots.isEmpty {
            studyReminderEnabled = false
            cancelStudyReminder()
        } else if studyReminderEnabled {
            scheduleStudyReminder()
        }
    }

    private func scheduleStudyReminder() {
        studyReminderSlots = Self.normalizedStudyReminderSlots(studyReminderSlots)
        if studyReminderSlots.isEmpty {
            studyReminderSlots = [StudyReminderSlot(hour: studyReminderHour, minute: studyReminderMinute)]
        }
        Self.saveStudyReminderSlots(studyReminderSlots)
        UserDefaults.standard.set(true, forKey: Self.studyReminderEnabledKey)

        #if canImport(UserNotifications)
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error {
                    studyReminderStatus = "Không bật được nhắc nhở: \(error.localizedDescription)"
                    studyReminderEnabled = false
                    UserDefaults.standard.set(false, forKey: Self.studyReminderEnabledKey)
                    return
                }
                guard granted else {
                    studyReminderStatus = "Bạn chưa cấp quyền thông báo."
                    studyReminderEnabled = false
                    UserDefaults.standard.set(false, forKey: Self.studyReminderEnabledKey)
                    return
                }

                center.removePendingNotificationRequests(withIdentifiers: Self.removableStudyReminderIdentifiers)
                let group = DispatchGroup()
                var lastError: Error?
                for (index, slot) in studyReminderSlots.enumerated() {
                    let content = UNMutableNotificationContent()
                    content.title = "BOSS Japan"
                    content.subtitle = index.isMultiple(of: 2) ? "Flash Card từ vựng" : "Flash Card ngữ pháp"
                    content.body = studyFlashcardText(offset: index)
                    content.sound = .default

                    var components = DateComponents()
                    components.hour = slot.hour
                    components.minute = slot.minute
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                    let request = UNNotificationRequest(identifier: Self.studyReminderIdentifier(index), content: content, trigger: trigger)
                    group.enter()
                    center.add(request) { error in
                        if let error {
                            lastError = error
                        }
                        group.leave()
                    }
                }

                group.notify(queue: .main) {
                    if let lastError {
                        studyReminderStatus = "Không đặt được nhắc học: \(lastError.localizedDescription)"
                        studyReminderEnabled = false
                        UserDefaults.standard.set(false, forKey: Self.studyReminderEnabledKey)
                    } else {
                        let labels = studyReminderSlots.map(\.label).joined(separator: ", ")
                        studyReminderStatus = "Đã bật nhắc học: \(labels)."
                        studyReminderEnabled = true
                        UserDefaults.standard.set(true, forKey: Self.studyReminderEnabledKey)
                    }
                }
            }
        }
        #else
        studyReminderStatus = "Thiết bị này không hỗ trợ thông báo cục bộ."
        studyReminderEnabled = false
        #endif
    }

    private func cancelStudyReminder() {
        UserDefaults.standard.set(false, forKey: Self.studyReminderEnabledKey)
        #if canImport(UserNotifications)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: Self.removableStudyReminderIdentifiers)
        #endif
        studyReminderStatus = "Đã tắt nhắc học."
    }

    private func gameMenuButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(GamePaperBackground())
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func gameSmallButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(GamePaperBackground())
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func playerSaveRow(_ profile: PlayerProfile) -> some View {
        let timerInfo = profileTimerInfo(profile)

        return HStack(spacing: 14) {
            BossMascotView(level: "SAVE", examTag: "\(profile.defeatedBossCount)", hpRatio: 1, mood: .normal, size: 72)
            VStack(alignment: .leading, spacing: 5) {
                Text(profile.name)
                    .font(.title3.bold())
                Text("Tiến độ: đã hạ \(profile.defeatedBossCount) boss")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    Label("Perfect \(profilePerfectBossCount(profile))", systemImage: "sparkles")
                    Label("Streak \(profileWinStreak(profile))", systemImage: "flame.fill")
                    Label("Rank \(profileCampaignRank(profile))", systemImage: "rosette")
                }
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                Label(timerInfo.text, systemImage: "timer")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(timerInfo.isDanger ? .red : .green)
                if profile.isDead {
                    Text("Đã thua cuộc")
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                }
                Text("Lần cuối: \(profile.lastPlayedAt.formatted(date: .numeric, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(role: .destructive) {
                deleteProfile(profile)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .background(GamePaperBackground())
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .contentShape(Rectangle())
        .onTapGesture {
            if !profile.isDead {
                continuePlayer(profile)
            }
        }
    }

    private func bossMapCampaignSummary(defeatedCount: Int, unlockedCount: Int, totalCount: Int, currentStageText: String) -> some View {
        let safeTotal = max(totalCount, 1)
        let progress = Double(defeatedCount) / Double(safeTotal)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                Label("Tiến độ chiến dịch", systemImage: "map.fill")
                    .font(.headline.bold())
                    .foregroundStyle(.orange)
                Spacer()
                Text("\(defeatedCount)/\(totalCount) boss")
                    .font(.headline.bold().monospacedDigit())
                    .foregroundStyle(defeatedCount == totalCount ? .green : .primary)
            }

            ProgressView(value: progress)
                .tint(defeatedCount == totalCount ? .green : .orange)

            HStack(spacing: 8) {
                achievementChip("First Blood", systemImage: "drop.fill", unlocked: defeatedCount >= 1)
                achievementChip("Boss Hunter", systemImage: "crown.fill", unlocked: defeatedCount >= 10)
                achievementChip("JLPT Hero", systemImage: "trophy.fill", unlocked: defeatedCount == totalCount && totalCount > 0)
            }

            HStack(spacing: 12) {
                Label("Mở: \(unlockedCount)/\(totalCount)", systemImage: "lock.open.fill")
                Label(currentStageText, systemImage: "location.fill")
                Spacer(minLength: 0)
            }
            .font(.caption.bold())
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(GamePaperBackground())
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func achievementChip(_ title: String, systemImage: String, unlocked: Bool) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(unlocked ? Color.yellow.opacity(0.18) : Color.gray.opacity(0.10))
            .foregroundStyle(unlocked ? .orange : .secondary)
            .clipShape(Capsule())
    }

    private func bossMapCurrentStageText(exams: [ExamDocument]) -> String {
        if exams.isEmpty { return "Chưa có boss" }
        if let current = exams.enumerated().first(where: { item in
            bossMapIsUnlocked(index: item.offset, exams: exams) && !bossHasPassed(item.element.id)
        })?.element {
            return "Hiện tại: \(current.normalizedLevel) \(current.title)"
        }
        return "Đã hoàn thành toàn bộ map"
    }

    private func bossMapStageRow(_ exam: ExamDocument, index: Int, exams: [ExamDocument]) -> some View {
        let isLeft = index.isMultiple(of: 2)
        let isUnlocked = bossMapIsUnlocked(index: index, exams: exams)
        let totalCount = exams.count

        return HStack(spacing: 0) {
            if isLeft {
                bossMapRow(exam, isUnlocked: isUnlocked)
                    .frame(maxWidth: 620)
                bossMapPathNode(exam: exam, index: index, totalCount: totalCount, isUnlocked: isUnlocked)
                Spacer(minLength: 24)
            } else {
                Spacer(minLength: 24)
                bossMapPathNode(exam: exam, index: index, totalCount: totalCount, isUnlocked: isUnlocked)
                bossMapRow(exam, isUnlocked: isUnlocked)
                    .frame(maxWidth: 620)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
        .opacity(isUnlocked ? 1 : 0.52)
    }

    private func bossMapPathNode(exam: ExamDocument, index: Int, totalCount: Int, isUnlocked: Bool) -> some View {
        let state = bossStates[exam.id]
        let didWin = state?.didWin == true
        let isRunning = state != nil && state?.finishedAt == nil
        let nodeColor: Color = didWin ? .green : (isRunning ? .orange : (isUnlocked ? .orange : .gray))

        return VStack(spacing: 0) {
            Rectangle()
                .fill(index == 0 ? Color.clear : Color.orange.opacity(0.28))
                .frame(width: 4, height: 28)
            ZStack {
                Circle()
                    .fill(nodeColor.opacity(0.18))
                    .frame(width: 50, height: 50)
                Circle()
                    .strokeBorder(nodeColor.opacity(0.85), lineWidth: 3)
                    .frame(width: 34, height: 34)
                Image(systemName: didWin ? "crown.fill" : (isRunning ? "flame.fill" : (isUnlocked ? "pawprint.fill" : "lock.fill")))
                    .font(.caption.bold())
                    .foregroundStyle(didWin ? .yellow : nodeColor)
            }
            Rectangle()
                .fill(index == totalCount - 1 ? Color.clear : Color.orange.opacity(0.28))
                .frame(width: 4, height: 28)
        }
        .frame(width: 64)
    }

    private func bossMapRow(_ exam: ExamDocument, isUnlocked: Bool) -> some View {
        let metrics = bossMetrics(for: exam.id)
        let state = bossStates[exam.id]
        let mood = bossMood(state: state, metrics: metrics)
        let score = bossScore(for: metrics)
        let rank = bossRank(for: score)
        let isPerfect = bossIsPerfect(state: state, score: score)
        let status: String = {
            if !isUnlocked { return "Đang khóa" }
            if state?.didWin == true { return "Đã hạ boss" }
            if state?.finishedAt != nil { return "Thua cuộc" }
            if state != nil { return "Đang đánh" }
            return "Chưa đánh"
        }()
        let statusColor: Color = {
            if !isUnlocked { return .gray }
            if state?.didWin == true { return .green }
            if state?.finishedAt != nil { return .red }
            if state != nil { return .orange }
            return .secondary
        }()
        let remaining = state == nil ? Self.bossTimeLimit : bossTimeRemaining(for: exam.id)

        return HStack(spacing: 14) {
            BossArtView(exam: exam, mood: mood, size: 88, hpRatio: metrics.totalHP / Self.bossTotalHP)

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Text("Stage \(exam.year)")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(.orange)
                    Text(exam.month > 0 ? "Tháng \(exam.month)" : "Boss")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }

                Text("\(exam.normalizedLevel) \(exam.title)")
                    .font(.title3.bold())

                HStack(spacing: 12) {
                    Label(status, systemImage: !isUnlocked ? "lock.fill" : (state?.didWin == true ? "checkmark.seal.fill" : "flame.fill"))
                        .foregroundStyle(statusColor)
                    Label("\(score)/120 điểm", systemImage: "star.fill")
                        .foregroundStyle(score >= 100 ? .green : .secondary)
                    Label("Rank \(rank)", systemImage: "rosette")
                        .foregroundStyle(bossRankColor(for: score))
                    if isPerfect {
                        Label("Perfect", systemImage: "sparkles")
                            .foregroundStyle(.yellow)
                    }
                    Label(formattedBossTime(remaining), systemImage: "timer")
                        .foregroundStyle(.secondary)
                }
                .font(.caption.bold())

                ProgressView(value: Double(score), total: Self.bossTotalHP)
                    .tint(score >= 100 ? .green : .orange)

                if let state {
                    Text("Tim \(state.heartsLeft)/\(Self.bossMaxHearts)")
                        .font(.caption.bold())
                        .foregroundStyle(state.heartsLeft <= 1 ? .red : .pink)
                }
            }

            Spacer(minLength: 8)
            Image(systemName: !isUnlocked ? "lock.circle.fill" : (state?.didWin == true ? "crown.fill" : "chevron.right.circle.fill"))
                .font(.title2)
                .foregroundStyle(!isUnlocked ? .gray : (state?.didWin == true ? .yellow : .orange))
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.96, blue: 0.80),
                    Color(red: 1.0, green: 0.86, blue: 0.62)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(state?.didWin == true ? Color.green.opacity(0.75) : Color.orange.opacity(isUnlocked ? 0.42 : 0.16), lineWidth: state?.didWin == true ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: Color.black.opacity(isUnlocked ? 0.12 : 0.04), radius: 12, y: 8)
        .contentShape(Rectangle())
        .onTapGesture {
            guard isUnlocked else { return }
            selectExam(exam.id)
            isBossRunMode = true
            audio.play(.boss)
            gameScreen = .practice
        }
    }

    private func bossMapIsUnlocked(index: Int, exams: [ExamDocument]) -> Bool {
        guard index > 0 else { return true }
        let exam = exams[index]
        if bossStates[exam.id] != nil { return true }
        let previousExam = exams[index - 1]
        return bossHasPassed(previousExam.id)
    }

    @ViewBuilder
    private var compactContent: some View {
        if selectedExamID == nil && selectedDrill == nil {
            examList
        } else if showsQuestionPicker, let selectedDrill {
            drillQuestionPicker(for: selectedDrill)
        } else if showsQuestionPicker, let selectedExamID, let exam = store.exams.first(where: { $0.id == selectedExamID }) {
            questionPicker(for: exam)
        } else {
            practiceShell
                .toolbar {
                    ToolbarItem(placement: appLeadingToolbarPlacement) {
                        Button {
                            showsQuestionPicker = true
                        } label: {
                            Label("Chọn câu", systemImage: "list.number")
                        }
                    }
                    ToolbarItem(placement: appTrailingToolbarPlacement) {
                        Button {
                            saveCurrentProfile()
                            gameScreen = .bossMap
                        } label: {
                            Label("Map", systemImage: "map")
                        }
                    }
                    if supportsScratchPad {
                        ToolbarItem(placement: .principal) {
                            Button {
                                showsScratchPad = true
                            } label: {
                                Image(systemName: "pencil.tip.crop.circle")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(.green)
                                    .padding(10)
                                    .background(.regularMaterial)
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel("Nháp")
                        }
                    }
                    ToolbarItemGroup(placement: appTrailingToolbarPlacement) {
                        Button {
                            speakCurrentQuestion()
                        } label: {
                            Label(speech.isSpeaking ? "Dừng đọc" : "Đọc", systemImage: speech.isSpeaking ? "speaker.slash.circle" : "speaker.wave.2.circle")
                        }
                        Button {
                            showsAnswerSheet = true
                        } label: {
                            Label("Đáp án", systemImage: "checklist")
                        }
                    }
                }
        }
    }

    private var practiceShell: some View {
        ZStack {
            questionDetail
            sideNavigationButtons
            battleEffectOverlay
        }
        .sheet(isPresented: $showsScratchPad) {
            if supportsScratchPad {
                ScratchPadView(drawing: $scratchDrawing)
            } else {
                EmptyView()
            }
        }
        .sheet(isPresented: $showsAnswerSheet) {
            answerSheet
        }
        .focusable()
        .focused($questionNavigationFocused)
        .onAppear {
            questionNavigationFocused = true
            resumeBossTimerIfNeeded()
        }
        .onChange(of: selectedQuestionIndex) { _, _ in
            questionNavigationFocused = true
            resumeBossTimerIfNeeded()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                resumeBossTimerIfNeeded()
            } else {
                pauseBossTimerIfNeeded()
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
            now = date
            updateBossTimeoutIfNeeded()
        }
        .onKeyPress(.leftArrow) {
            guard !showsScratchPad, !showsAnswerSheet else { return .ignored }
            moveQuestion(-1)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            guard !showsScratchPad, !showsAnswerSheet else { return .ignored }
            moveQuestion(1)
            return .handled
        }
        .background(KeyboardNavigationHandler { delta in
            moveQuestion(delta)
        })
        .background(GameAppBackground())
    }

    @ViewBuilder
    private var battleEffectOverlay: some View {
        if let battleFlashText {
            ZStack {
                if battleFlashText == "MISS!" {
                    Color.red.opacity(0.16)
                        .ignoresSafeArea()
                    VStack(spacing: 12) {
                        Image(systemName: "heart.slash.fill")
                            .font(.system(size: 84, weight: .black))
                            .foregroundStyle(.red)
                        Text("MISS!")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundStyle(.red)
                    }
                    .shadow(color: .black.opacity(0.20), radius: 14)
                } else {
                    Color.yellow.opacity(0.14)
                        .ignoresSafeArea()
                    VStack(spacing: 12) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 92, weight: .black))
                            .foregroundStyle(.yellow)
                            .shadow(color: .orange.opacity(0.8), radius: 18)
                        Text(battleFlashText)
                            .font(.system(size: 46, weight: .black, design: .rounded))
                            .foregroundStyle(.orange)
                            .shadow(color: .white.opacity(0.95), radius: 10)
                    }
                    .scaleEffect(bossHitPulse ? 1.08 : 0.82)
                }
            }
            .transition(.scale.combined(with: .opacity))
            .zIndex(100)
            .allowsHitTesting(false)
        }
    }

    private var sideNavigationButtons: some View {
        HStack {
            sideNavigationButton(systemImage: "chevron.left", isDisabled: selectedQuestionIndex == 0) {
                moveQuestion(-1)
            }
#if os(macOS) || targetEnvironment(macCatalyst)
            .keyboardShortcut(.leftArrow, modifiers: [])
#endif
            Spacer()
            sideNavigationButton(systemImage: "chevron.right", isDisabled: selectedQuestionIndex >= max(selectedQuestions.count - 1, 0)) {
                moveQuestion(1)
            }
#if os(macOS) || targetEnvironment(macCatalyst)
            .keyboardShortcut(.rightArrow, modifiers: [])
#endif
        }
        .padding(.horizontal, 6)
        .allowsHitTesting((selectedExamID != nil || selectedDrill != nil) && !selectedQuestions.isEmpty)
    }

    private func sideNavigationButton(systemImage: String, isDisabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title2.weight(.bold))
                .foregroundStyle(isDisabled ? Color.gray.opacity(0.25) : Color.red.opacity(0.9))
                .frame(width: 34, height: 64)
                .background(.ultraThinMaterial.opacity(isDisabled ? 0.35 : 0.72))
                .clipShape(Capsule())
        }
        .disabled(isDisabled)
        .buttonStyle(.plain)
        .accessibilityLabel(systemImage.contains("left") ? "Câu trước" : "Câu tiếp")
    }

    private func handleInstantLookupSelection(_ selectedText: String) {}

    private func speakCurrentQuestion() {
        if speech.isSpeaking {
            speech.stop()
            return
        }
        guard let question = currentQuestion else { return }
        speech.speak(question.fullSpeechText)
    }

    private func speechRange(for segment: String) -> NSRange? {
        let cleaned = segment.speechCleanedJapanese
        guard !cleaned.isEmpty, let spokenRange = speech.spokenRange else { return nil }
        if speech.spokenText == cleaned {
            return spokenRange
        }

        let spoken = speech.spokenText as NSString
        let segmentRange = spoken.range(of: cleaned)
        guard segmentRange.location != NSNotFound else { return nil }

        let spokenStart = spokenRange.location
        let spokenEnd = spokenRange.location + spokenRange.length
        let segmentStart = segmentRange.location
        let segmentEnd = segmentRange.location + segmentRange.length
        let intersectionStart = max(spokenStart, segmentStart)
        let intersectionEnd = min(spokenEnd, segmentEnd)
        guard intersectionEnd > intersectionStart else { return nil }

        return NSRange(
            location: intersectionStart - segmentStart,
            length: intersectionEnd - intersectionStart
        )
    }

    private func openMacDictionary(for term: String) -> Bool {
#if os(macOS) || targetEnvironment(macCatalyst)
        let allowed = CharacterSet.urlPathAllowed.union(.urlQueryAllowed)
        guard let encoded = term.addingPercentEncoding(withAllowedCharacters: allowed),
              let url = URL(string: "dict://\(encoded)") else {
            return false
        }
#if os(macOS)
        NSWorkspace.shared.open(url)
        return true
#else
        UIApplication.shared.open(url)
        return true
#endif
#else
        return false
#endif
    }

    @ViewBuilder
    private var sidebar: some View {
        if showsQuestionPicker, let selectedDrill {
            drillQuestionPicker(for: selectedDrill)
        } else if showsQuestionPicker, let selectedExamID, let exam = store.exams.first(where: { $0.id == selectedExamID }) {
            questionPicker(for: exam)
        } else {
            examList
        }
    }

    private var examList: some View {
        List {
            Section {
                Label("Tìm kiếm", systemImage: "magnifyingglass")
                    .font(.headline)
                    .foregroundStyle(.green)
                TextField("Nhập từ, kanji, ngữ pháp...", text: $searchText)
                    .disableAutocapitalizationIfAvailable()
                    .autocorrectionDisabled()
            }

            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Section("Kết quả tìm kiếm") {
                    if searchResults.isEmpty {
                        Text("Không tìm thấy")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(searchResults.prefix(50)) { question in
                            searchResultRow(question)
                        }
                    }
                }
            }

            Section("Luyện chuyên từng phần N1/N2") {
                ForEach(PracticeDrill.allCases) { drill in
                    drillRow(drill)
                }
            }
        }
        .navigationTitle("Luyện từng phần")
        .scrollContentBackground(.hidden)
        .background(GameAppBackground())
        .toolbar {
            ToolbarItem(placement: appLeadingToolbarPlacement) {
                Button {
                    pauseBossTimerIfNeeded()
                    saveCurrentProfile()
                    selectedExamID = nil
                    selectedDrill = nil
                    selectedQuestionIndex = 0
                    selectedAnswer = nil
                    showsQuestionPicker = false
                    gameScreen = .mainMenu
                } label: {
                    Label("Menu", systemImage: "house.fill")
                }
                .tint(.green)
            }
        }
    }

    private func bossCampaignSummary(for exams: [ExamDocument]) -> some View {
        let defeated = exams.filter { bossHasPassed($0.id) }.count
        let isChampion = defeated == exams.count && !exams.isEmpty

        return HStack(spacing: 10) {
            Image(systemName: isChampion ? "trophy.fill" : "shield.lefthalf.filled")
                .foregroundStyle(isChampion ? .yellow : .green)
            VStack(alignment: .leading, spacing: 2) {
                Text(isChampion ? "Vô địch \(selectedLevel)" : "Chiến dịch Boss \(selectedLevel)")
                    .font(.headline)
                Text("Đã hạ \(defeated)/\(exams.count) boss")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .listRowBackground(Color.clear)
    }

    private func questionPicker(for exam: ExamDocument) -> some View {
        let questions = store.questions(for: exam.id)
        let columns = [
            GridItem(.adaptive(minimum: 48, maximum: 64), spacing: 10)
        ]

        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Chọn câu")
                            .font(.title2.bold())
                        Text("\(exam.normalizedLevel) • \(exam.title) • \(questions.count) câu")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                    ForEach(questions.indices, id: \.self) { index in
                        questionNumberButton(index: index, question: questions[index])
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Chọn câu")
        .background(GameAppBackground())
        .toolbar {
            ToolbarItem(placement: appLeadingToolbarPlacement) {
                pickerBackButton {
                    if isBossRunMode {
                        saveCurrentProfile()
                        showsQuestionPicker = false
                        gameScreen = .bossMap
                    } else if horizontalSizeClass == .compact {
                        selectedExamID = nil
                        selectedQuestionIndex = 0
                        selectedAnswer = nil
                    } else {
                        showsQuestionPicker = false
                    }
                }
            }
        }
    }

    private func drillQuestionPicker(for drill: PracticeDrill) -> some View {
        let questions = selectedQuestions
        let columns = [
            GridItem(.adaptive(minimum: 48, maximum: 64), spacing: 10)
        ]

        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(drill.title)
                        .font(.title2.bold())
                    Text("N1/N2 • \(questions.count) câu")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                    ForEach(questions.indices, id: \.self) { index in
                        questionNumberButton(index: index, question: questions[index])
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Chọn câu")
        .background(GameAppBackground())
        .toolbar {
            ToolbarItem(placement: appLeadingToolbarPlacement) {
                pickerBackButton {
                    if horizontalSizeClass == .compact {
                        selectedDrill = nil
                        selectedQuestionIndex = 0
                        selectedAnswer = nil
                    } else {
                        showsQuestionPicker = false
                    }
                }
            }
            ToolbarItem(placement: appTrailingToolbarPlacement) {
                Button {
                    resetDrillHistory()
                } label: {
                    Label("Làm mới", systemImage: "arrow.clockwise")
                }
                .tint(.green)
            }
        }
    }

    private func pickerBackButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label("Back", systemImage: "chevron.left")
                .font(.headline)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.regularMaterial)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .tint(.green)
        .accessibilityLabel("Back")
    }

    private func questionNumberButton(index: Int, question: PracticeQuestion) -> some View {
        let result = answerResult(for: question)
        return Button {
            selectedQuestionIndex = index
            selectedAnswer = answerHistory[question.id]
            if horizontalSizeClass == .compact {
                showsQuestionPicker = false
            }
        } label: {
            Text("\(index + 1)")
                .font(.headline)
                .frame(width: 48, height: 44)
                .background(questionButtonBackground(isSelected: selectedQuestionIndex == index, result: result))
                .foregroundStyle(selectedQuestionIndex == index ? .white : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(questionButtonBorder(for: question, isSelected: selectedQuestionIndex == index, result: result), lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Câu \(question.number)")
    }

    private func searchResultRow(_ question: PracticeQuestion) -> some View {
        Button {
            selectQuestion(question)
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("\(question.examLevel) \(question.examTitle) • câu \(question.number)")
                        .font(.subheadline.bold())
                    Spacer()
                    Text(question.sectionTitle)
                        .font(.caption)
                        .foregroundStyle(sectionColor(question.sectionTitle))
                }
                Text(searchSnippet(for: question))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 1.0, green: 0.95, blue: 0.84))
                .padding(.vertical, 3)
        )
    }

    private func sectionColor(_ section: String) -> Color {
        switch section {
        case "Từ vựng": return .orange
        case "Ngữ pháp": return .blue
        case "Đọc hiểu": return .purple
        default: return .secondary
        }
    }

    private func questionButtonBackground(isSelected: Bool, result: AnswerResult) -> Color {
        if isSelected { return .green }
        switch result {
        case .correct: return Color.green.opacity(0.18)
        case .incorrect: return Color.red.opacity(0.16)
        case .unanswered: return Color(red: 1.0, green: 0.94, blue: 0.82)
        }
    }

    private func questionButtonBorder(for question: PracticeQuestion, isSelected: Bool, result: AnswerResult) -> Color {
        if isSelected { return .green }
        switch result {
        case .correct: return .green.opacity(0.85)
        case .incorrect: return .red.opacity(0.75)
        case .unanswered:
            switch question.sectionTitle {
            case "Từ vựng": return .orange.opacity(0.45)
            case "Ngữ pháp": return .blue.opacity(0.45)
            case "Đọc hiểu": return .purple.opacity(0.45)
            default: return .gray.opacity(0.3)
            }
        }
    }

    private func answerResult(for question: PracticeQuestion) -> AnswerResult {
        guard let saved = answerHistory[question.id] else {
            return .unanswered
        }
        guard let correct = question.correctAnswer else {
            return .incorrect
        }
        return saved == correct - 1 ? .correct : .incorrect
    }

    private enum AnswerResult {
        case unanswered
        case correct
        case incorrect
    }

    private var answerSheet: some View {
        let questions = selectedQuestions

        return NavigationStack {
            List {
                ForEach(questions.indices, id: \.self) { index in
                    answerRow(index: index, question: questions[index])
                }
            }
            .scrollContentBackground(.hidden)
            .background(GameAppBackground())
            .navigationTitle("Đáp án \(practiceTitle)")
            .toolbar {
                ToolbarItem(placement: appTrailingToolbarPlacement) {
                    Button("Đóng") {
                        showsAnswerSheet = false
                    }
                }
            }
        }
    }

    private func answerRow(index: Int, question: PracticeQuestion) -> some View {
        let correctText = question.correctAnswer.flatMap { correct in
            question.options.indices.contains(correct - 1) ? question.options[correct - 1].removingAppMarkers : nil
        } ?? "Chưa có đáp án"
        let result = answerResult(for: question)

        return Button {
            selectedQuestionIndex = index
            selectedAnswer = answerHistory[question.id]
            showsAnswerSheet = false
            if horizontalSizeClass == .compact {
                showsQuestionPicker = false
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(index + 1). \(question.examLevel) \(question.sectionTitle)")
                        .font(.headline)
                    Spacer()
                    answerStatusLabel(result)
                }
                Text("Đáp án: \(question.correctAnswer.map(String.init) ?? "-"). \(correctText)")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                if let saved = answerHistory[question.id],
                   question.options.indices.contains(saved) {
                    Text("Bạn chọn: \(saved + 1). \(question.options[saved].removingAppMarkers)")
                        .font(.caption)
                        .foregroundStyle(result == .correct ? .green : .red)
                }
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private func answerStatusLabel(_ result: AnswerResult) -> some View {
        Group {
            switch result {
            case .correct:
                Label("Đúng", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .incorrect:
                Label("Sai", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
            case .unanswered:
                Label("Chưa làm", systemImage: "circle")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption.bold())
    }

    private func examRow(_ exam: ExamDocument) -> some View {
        let count = store.questions(for: exam.id).count
        let isSelected = selectedExamID == exam.id
        let metrics = bossMetrics(for: exam.id)
        let state = bossStates[exam.id]
        let mood = bossMood(state: state, metrics: metrics)
        let hpRatio = metrics.totalHP / Self.bossTotalHP
        let hpText = "\(Int(metrics.totalHP.rounded()))/\(Int(Self.bossTotalHP)) HP"
        let bossLabel: String = {
            if state?.didWin == true { return "Đã hạ boss" }
            if state?.finishedAt != nil { return "Cần phục thù" }
            if state != nil { return "Đang đánh" }
            return "Boss mới"
        }()

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                BossArtView(exam: exam, mood: mood, size: 54, hpRatio: hpRatio, showsYearBadge: false)
                VStack(alignment: .leading, spacing: 4) {
                    Text(exam.title)
                        .font(.headline)
                        .foregroundStyle(isSelected ? .white : .primary)
                    Text("\(count) câu • \(exam.normalizedLevel) の試験官 • \(bossLabel)")
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(hpText)
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(isSelected ? .white : .red)
                    if let state {
                        Text("♥ \(state.heartsLeft)/\(Self.bossMaxHearts)")
                            .font(.caption2.bold())
                            .foregroundStyle(isSelected ? .white.opacity(0.9) : .pink)
                    }
                }
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: max(0, min(Self.bossTotalHP, metrics.totalHP)), total: Self.bossTotalHP)
                    .tint(isSelected ? .white : .red)
                HStack {
                    Text("TV+NP \(Int(metrics.languageHP.rounded()))/60")
                    Spacer()
                    Text("Đọc \(Int(metrics.readingHP.rounded()))/60")
                }
                .font(.caption2.monospacedDigit())
                .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GamePaperBackground(selected: isSelected))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .listRowBackground(Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            selectExam(exam.id)
        }
        .accessibilityAddTraits(.isButton)
    }

    private func drillRow(_ drill: PracticeDrill) -> some View {
        let count = drillQuestionsByType[drill]?.count ?? 0
        let isSelected = selectedDrill == drill

        return HStack(spacing: 12) {
            Image(systemName: drill.systemImage)
                .foregroundStyle(isSelected ? .white : .green)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(drill.title)
                    .font(.headline)
                    .foregroundStyle(isSelected ? .white : .primary)
                Text("\(drill.levelLabel) • \(count) câu")
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.white)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GamePaperBackground(selected: isSelected))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .listRowBackground(Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            selectDrill(drill)
        }
        .accessibilityAddTraits(.isButton)
    }

    private func selectExam(_ examID: String) {
        pauseBossTimerIfNeeded()
        isBossRunMode = false
        if let exam = store.exams.first(where: { $0.id == examID }) {
            selectedLevel = exam.normalizedLevel
            selectedLibraryTab = exam.normalizedLevel
        }
        selectedExamID = examID
        selectedDrill = nil
        selectedQuestionIndex = 0
        selectedAnswer = store.questions(for: examID).first.flatMap { answerHistory[$0.id] }
        startBossIfNeeded(for: examID)
        showsQuestionPicker = true
        columnVisibility = .all
    }

    private func selectDrill(_ drill: PracticeDrill) {
        pauseBossTimerIfNeeded()
        if drillQuestionsByType.isEmpty {
            rebuildDrillQuestionCache()
        }
        isBossRunMode = false
        selectedLibraryTab = "Từng phần"
        selectedDrill = drill
        selectedExamID = nil
        selectedQuestionIndex = 0
        let questions = cachedQuestions(for: drill)
        selectedAnswer = questions.first.flatMap { answerHistory[$0.id] }
        showsQuestionPicker = true
        columnVisibility = .all
    }

    private func selectQuestion(_ question: PracticeQuestion) {
        pauseBossTimerIfNeeded()
        isBossRunMode = false
        selectedExamID = question.examID
        selectedDrill = nil
        selectedLevel = question.examLevel
        selectedLibraryTab = question.examLevel
        let questions = store.questions(for: question.examID)
        if let index = questions.firstIndex(where: { $0.id == question.id }) {
            selectedQuestionIndex = index
        }
        selectedAnswer = answerHistory[question.id]
        showsQuestionPicker = horizontalSizeClass != .compact
        columnVisibility = .all
    }

    @ViewBuilder
    private var questionDetail: some View {
        if let error = store.loadError {
            ContentUnavailableView("Lỗi dữ liệu", systemImage: "exclamationmark.triangle", description: Text(error))
        } else if selectedExamID == nil && selectedDrill == nil {
            ContentUnavailableView("Chọn thư mục đề", systemImage: "book.closed", description: Text("Chọn một đề ở bên trái để bắt đầu luyện."))
        } else if let question = currentQuestion {
            let insertionEdge: Edge = questionTransitionDirection >= 0 ? .trailing : .leading
            let removalEdge: Edge = questionTransitionDirection >= 0 ? .leading : .trailing

            VStack(spacing: 0) {
                if selectedDrill == nil {
                    bossHUD(for: question.examID)
                        .padding(.horizontal, horizontalSizeClass == .compact ? 12 : 24)
                        .padding(.top, horizontalSizeClass == .compact ? 8 : 14)
                        .padding(.bottom, 8)
                        .background(GameAppBackground())
                        .zIndex(10)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header(for: question)
                        if let passage = question.passage?.nonEmpty {
                            ReadingPassageCard(
                                passage: passage,
                                currentQuestionNumber: question.number,
                                currentQuestionMarker: passageQuestionMarker(for: question),
                                speechRange: speechRange(for: passage),
                                onSelectionChange: handleInstantLookupSelection,
                                onSpeak: { speech.speak(passage) }
                            )
                            .equatable()
                        }
                        questionText(question)
                        options(for: question)
                        explanation(for: question)
                    }
                    .padding(.horizontal, horizontalSizeClass == .compact ? 18 : 28)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                    .frame(maxWidth: 980, alignment: .leading)
                }
                .id(question.id)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: insertionEdge).combined(with: .opacity),
                        removal: .move(edge: removalEdge).combined(with: .opacity)
                    )
                )
            }
            .background(GameAppBackground())
            .overlay {
                if bossHitPulse {
                    Color.clear
                        .allowsHitTesting(false)
                }
            }
        } else {
            ContentUnavailableView("Chọn thư mục đề", systemImage: "book.closed", description: Text("Chọn một đề ở bên trái để bắt đầu luyện."))
        }
    }

    private func header(for question: PracticeQuestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(question.examLevel) \(question.examTitle) - \(question.sectionTitle)")
                        .font(.headline)
                        .foregroundStyle(.orange)
                    if let instruction = question.instruction?.nonEmpty {
                        Text(instruction)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text("\(selectedQuestionIndex + 1)/\(selectedQuestions.count)")
                    .font(.headline)
                    .foregroundStyle(.green)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private func bossHUD(for examID: String) -> some View {
        let state = bossState(for: examID)
        let metrics = bossMetrics(for: examID)
        let remaining = bossTimeRemaining(for: examID)
        let exam = store.exams.first(where: { $0.id == examID })
        let level = exam?.normalizedLevel ?? "JLPT"
        let examTag = exam.map { bossExamTag(for: $0) }
        let mood = bossMood(state: state, metrics: metrics)
        let hpRatio = metrics.totalHP / Self.bossTotalHP
        let score = bossScore(for: metrics)
        let statusText: String = {
            if let _ = state.finishedAt {
                return state.didWin ? "Đã hạ boss" : "Boss thắng"
            }
            return "\(level) の試験官"
        }()

        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 16) {
                bossBattleArt(exam: exam, level: level, examTag: examTag, hpRatio: hpRatio, mood: mood, size: 92)
                    .frame(width: 96, height: 96)

                bossCompactStatusPanel(
                    statusText: statusText,
                    state: state,
                    metrics: metrics,
                    remaining: remaining,
                    level: level,
                    score: score
                )
            }
            .padding(12)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.18, green: 0.13, blue: 0.30).opacity(0.92),
                        Color(red: 0.34, green: 0.22, blue: 0.42).opacity(0.90)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color(red: 1.0, green: 0.72, blue: 0.52).opacity(0.45), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: Color.black.opacity(0.14), radius: 10, y: 5)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    bossBattleArt(exam: exam, level: level, examTag: examTag, hpRatio: hpRatio, mood: mood, size: 64)
                        .frame(width: 68, height: 68)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(statusText)
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text("\(level) boss • \(score)/120 điểm")
                            .font(.caption.bold())
                            .foregroundStyle(Color.white.opacity(0.76))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 5) {
                        Label(formattedBossTime(remaining), systemImage: "timer")
                            .font(.caption.bold().monospacedDigit())
                            .foregroundStyle(remaining <= 600 && state.finishedAt == nil ? .red : .white)
                        Label("\(state.heartsLeft)/\(Self.bossMaxHearts)", systemImage: "heart.fill")
                            .font(.caption.bold())
                            .foregroundStyle(state.heartsLeft <= 1 ? .red : .pink)
                    }
                }

                HStack(spacing: 10) {
                    ProgressView(value: Double(score), total: Self.bossTotalHP)
                        .tint(score >= 100 ? .green : .blue)
                    Text("\(score)/120")
                        .font(.caption2.bold().monospacedDigit())
                        .foregroundStyle(.white.opacity(0.85))
                }

                HStack(spacing: 10) {
                    Label("Combo \(min(state.combo, 6))/6", systemImage: "bolt.fill")
                    Label("🎫 \(state.wrongAnswerTickets)", systemImage: "ticket.fill")
                        .foregroundStyle(state.wrongAnswerTickets > 0 ? .yellow : .white.opacity(0.58))
                    Spacer()
                    Label("HP \(Int(metrics.totalHP.rounded()))/120", systemImage: "flame.fill")
                }
                .font(.caption2.bold())
                .foregroundStyle(.white.opacity(0.72))
            }
            .padding(10)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.18, green: 0.13, blue: 0.30).opacity(0.94),
                        Color(red: 0.34, green: 0.22, blue: 0.42).opacity(0.92)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color(red: 1.0, green: 0.72, blue: 0.52).opacity(0.38), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: Color.black.opacity(0.10), radius: 8, y: 4)
        }
        .frame(maxWidth: .infinity)
    }

    private func bossCompactStatusPanel(statusText: String, state: BossRunState, metrics: BossMetrics, remaining: TimeInterval, level: String, score: Int) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(statusText)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text("\(level) boss battle")
                        .font(.caption.bold())
                        .foregroundStyle(Color(red: 1.0, green: 0.80, blue: 0.56))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 5) {
                    Label(formattedBossTime(remaining), systemImage: "timer")
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(remaining <= 600 && state.finishedAt == nil ? .red : .white)
                    Label("\(state.heartsLeft)/\(Self.bossMaxHearts)", systemImage: "heart.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(state.heartsLeft <= 1 ? .red : .pink)
                }
            }

            HStack(spacing: 10) {
                Text("⭐ \(score)/120")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(score >= 100 ? .green : .white)
                ProgressView(value: Double(score), total: Self.bossTotalHP)
                    .tint(score >= 100 ? .green : .blue)
            }

            HStack(spacing: 10) {
                Label("Combo \(min(state.combo, 6))/6", systemImage: "bolt.fill")

                Label("🎫 \(state.wrongAnswerTickets)", systemImage: "ticket.fill")
                    .foregroundStyle(state.wrongAnswerTickets > 0 ? .yellow : .white.opacity(0.62))

                Spacer()

                Label("Boss HP \(Int(metrics.totalHP.rounded()))/120", systemImage: "flame.fill")
            }
            .font(.caption.bold())
            .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
    }

    private func bossBattleArt(exam: ExamDocument?, level: String, examTag: String?, hpRatio: Double, mood: BossMood, size: CGFloat) -> some View {
        ZStack {
            Group {
                if let exam {
                    BossArtView(exam: exam, mood: mood, size: size, hpRatio: hpRatio, showsYearBadge: false)
                } else {
                    BossMascotView(level: level, examTag: examTag, hpRatio: hpRatio, mood: mood, size: size, showsBackdrop: false)
                }
            }
                .scaleEffect(bossHitPulse ? 0.88 : 1)
                .rotationEffect(.degrees(bossHitPulse ? -5 : 0))
                .offset(x: bossHitPulse ? -8 : 0)

            if bossHitPulse {
                ZStack {
                    Image(systemName: "burst.fill")
                        .font(.system(size: size * 0.34, weight: .black))
                        .foregroundStyle(.yellow)
                        .shadow(color: .red.opacity(0.55), radius: 10)
                    Text("HIT!")
                        .font(.system(size: max(18, size * 0.14), weight: .black, design: .rounded))
                        .foregroundStyle(.red)
                        .rotationEffect(.degrees(-10))
                }
                .offset(x: size * 0.24, y: -size * 0.20)
                .transition(.scale.combined(with: .opacity))
            }

            if let battleFlashText {
                Text(battleFlashText)
                    .font(.system(size: max(16, size * 0.11), weight: .black, design: .rounded))
                    .foregroundStyle(battleFlashText == "COMBO!" ? .yellow : .white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.62))
                    .clipShape(Capsule())
                    .offset(y: -size * 0.46)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.20, dampingFraction: 0.45), value: bossHitPulse)
        .animation(.easeOut(duration: 0.22), value: battleFlashText)
    }

    private func bossStatusPanel(statusText: String, state: BossRunState, metrics: BossMetrics, remaining: TimeInterval, level: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("BOSS", systemImage: state.didWin ? "crown.fill" : "flame.fill")
                        .font(.caption.bold())
                        .foregroundStyle(state.finishedAt == nil ? Color(red: 1.0, green: 0.48, blue: 0.45) : (state.didWin ? .green : .red))
                    Text(statusText)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text("\(level) boss battle")
                        .font(.caption.bold())
                        .foregroundStyle(Color(red: 1.0, green: 0.80, blue: 0.56))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Label(formattedBossTime(remaining), systemImage: "timer")
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(remaining <= 600 && state.finishedAt == nil ? .red : .white)
                    Label("\(state.heartsLeft)/\(Self.bossMaxHearts)", systemImage: "heart.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(state.heartsLeft <= 1 ? .red : .pink)
                }
            }

            bossRankBadge(score: bossScore(for: metrics), isPerfect: bossIsPerfect(state: state, score: bossScore(for: metrics)))
            bossScoreBar(score: bossScore(for: metrics), maxScore: Self.bossTotalHP)
            bossComboBar(combo: state.combo, heartsLeft: state.heartsLeft)
            bossHPBar(title: "Boss HP", hp: metrics.totalHP, maxHP: Self.bossTotalHP, tint: .red)
            HStack(spacing: 12) {
                bossHPBar(
                    title: "Từ vựng + Ngữ pháp",
                    hp: metrics.languageHP,
                    maxHP: Self.bossSectionHP,
                    tint: .orange,
                    subtitle: "\(metrics.languageCorrect)/\(metrics.languageTotal)"
                )
                bossHPBar(
                    title: "Đọc hiểu",
                    hp: metrics.readingHP,
                    maxHP: Self.bossSectionHP,
                    tint: .purple,
                    subtitle: "\(metrics.readingCorrect)/\(metrics.readingTotal)"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func bossRankBadge(score: Int, isPerfect: Bool) -> some View {
        HStack(spacing: 10) {
            Label("Rank \(bossRank(for: score))", systemImage: "rosette")
                .font(.caption.bold())
                .foregroundStyle(bossRankColor(for: score))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.10))
                .clipShape(Capsule())
            if isPerfect {
                Label("PERFECT CLEAR", systemImage: "sparkles")
                    .font(.caption.bold())
                    .foregroundStyle(.yellow)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.yellow.opacity(0.14))
                    .clipShape(Capsule())
            }
        }
    }

    private func bossRank(for score: Int) -> String {
        switch score {
        case 120...: return "SS"
        case 115...: return "S"
        case 110...: return "A"
        case 100...: return "B"
        case 80...: return "C"
        case 60...: return "D"
        default: return "E"
        }
    }

    private func bossRankColor(for score: Int) -> Color {
        switch score {
        case 120...: return .yellow
        case 115...: return .purple
        case 110...: return .green
        case 100...: return .blue
        case 80...: return .orange
        default: return .secondary
        }
    }

    private func bossIsPerfect(state: BossRunState?, score: Int) -> Bool {
        guard let state, state.didWin else { return false }
        return state.heartsLeft == Self.bossMaxHearts && score >= 110
    }

    private func bossScoreBar(score: Int, maxScore: Double) -> some View {
        let targetScore = 100
        let didReachTarget = score >= targetScore

        return VStack(alignment: .leading, spacing: 5) {
            HStack {
                Label("Điểm của bạn", systemImage: didReachTarget ? "checkmark.seal.fill" : "star.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                Spacer()
                Text("\(score)/\(Int(maxScore))")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(didReachTarget ? .green : .white)
            }

            ProgressView(value: max(0, min(maxScore, Double(score))), total: maxScore)
                .tint(didReachTarget ? .green : .blue)

            HStack {
                Text(didReachTarget ? "Đủ điều kiện thắng boss" : "Cần đạt 100/120 để thắng")
                Spacer()
                Text("Mốc thắng: \(targetScore)/\(Int(maxScore))")
            }
            .font(.caption2.bold().monospacedDigit())
            .foregroundStyle(didReachTarget ? .green : .white.opacity(0.72))
        }
    }

    private func bossComboBar(combo: Int, heartsLeft: Int) -> some View {
        let maxCombo = 6
        let clampedCombo = max(0, min(combo, maxCombo))
        let reachedTimeBonus = clampedCombo >= 3
        let reachedUnlock = clampedCombo >= 5
        let reachedHeal = clampedCombo >= 6
        let iconName = reachedHeal ? "heart.circle.fill" : (reachedUnlock ? "arrow.counterclockwise.circle.fill" : (reachedTimeBonus ? "clock.badge.plus" : "bolt.fill"))
        let tint: Color = reachedHeal ? .pink : (reachedUnlock ? .yellow : (reachedTimeBonus ? .cyan : .white))

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Combo", systemImage: iconName)
                    .font(.caption.bold())
                    .foregroundStyle(tint)
                Spacer()
                Text("\(clampedCombo)/\(maxCombo)")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(tint)
            }

            ProgressView(value: Double(clampedCombo), total: Double(maxCombo))
                .tint(tint)

            Text("Mốc: 3 • 5 • 6")
                .font(.caption2.bold())
                .foregroundStyle(.white.opacity(0.62))
        }
    }

    private func milestoneRow(mark: Int, text: String, reached: Bool, color: Color) -> some View {
        HStack(spacing: 6) {
            Text("\(mark)")
                .font(.caption2.bold().monospacedDigit())
                .frame(width: 18, height: 18)
                .background(reached ? color.opacity(0.25) : Color.white.opacity(0.10))
                .foregroundStyle(reached ? color : .white.opacity(0.62))
                .clipShape(Circle())
            Text(text)
                .font(.caption2.bold())
                .foregroundStyle(reached ? color : .white.opacity(0.66))
        }
    }

    private func bossHPBar(title: String, hp: Double, maxHP: Double, tint: Color, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                Spacer()
                Text("\(Int(hp.rounded()))/\(Int(maxHP))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.70))
                }
            }
            ProgressView(value: max(0, min(maxHP, hp)), total: maxHP)
                .tint(tint)
        }
    }

    private func questionText(_ question: PracticeQuestion) -> some View {
        HStack(alignment: .top, spacing: 10) {
            SelectableAttributedTextView(
                attributedText: attributedQuestion(question, speechRange: speechHighlightRange(
                    in: questionTextWithInferredUnderline(question),
                    cleanedRange: speechRange(for: question.textForSpeech)
                )),
                onSelectionChange: handleInstantLookupSelection
            )
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                speech.speak(question.textForSpeech)
            } label: {
                Image(systemName: "speaker.wave.2.circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.green)
                    .frame(width: 36, height: 36)
                    .background(.regularMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Đọc câu hỏi")
        }
    }

    private func options(for question: PracticeQuestion) -> some View {
        VStack(spacing: 14) {
            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                HStack(alignment: .center, spacing: 12) {
                    SelectableTextView(
                        text: option,
                        font: .appPreferred(.title3),
                        onSelectionChange: handleInstantLookupSelection
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        selectAnswer(index, for: question)
                    } label: {
                        Image(systemName: selectedAnswer == index ? "checkmark.circle.fill" : "circle")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(selectedAnswer == index ? .green : .secondary)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Chọn đáp án \(index + 1)")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(optionBackground(index: index, question: question))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(optionBorder(index: index, question: question), lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .contentShape(Rectangle())
            }
        }
    }

    @ViewBuilder
    private func explanation(for question: PracticeQuestion) -> some View {
        if selectedAnswer != nil {
            let isReadingQuestion = question.sectionTitle == "Đọc hiểu"
            let isExpanded = expandedExplanationQuestionIDs.contains(question.id)

            VStack(alignment: .leading, spacing: 12) {
                if let correct = question.correctAnswer, question.options.indices.contains(correct - 1) {
                    SelectableTextView(
                        text: "Đáp án: \(correct). \(question.options[correct - 1])",
                        font: .appPreferred(.headline),
                        isBold: true,
                        onSelectionChange: handleInstantLookupSelection
                    )
                }

                Button {
                    if isExpanded {
                        expandedExplanationQuestionIDs.remove(question.id)
                    } else {
                        expandedExplanationQuestionIDs.insert(question.id)
                    }
                } label: {
                    Label(isExpanded ? "Thu giải thích" : "Hiện giải thích", systemImage: isExpanded ? "chevron.up.circle" : "lightbulb")
                }
                .buttonStyle(.bordered)
                .tint(.orange)

                if isExpanded {
                    let shouldLoadStudyNotes = !isReadingQuestion || expandedStudyNoteQuestionIDs.contains(question.id)
                    let vocabNotes = shouldLoadStudyNotes ? dictionary.vocabularyMatches(for: question) : []
                    let grammarNotes = shouldLoadStudyNotes ? dictionary.grammarMatches(for: question) : []
                    let explanationText = conciseExplanation(question.explanation, for: question) ?? fallbackExplanation(for: question, vocabNotes: vocabNotes, grammarNotes: grammarNotes)
                    let starOrderText = resolvedStarOrderText(for: question)
                    let answerMeaningText = answerMeaning(for: question, vocabNotes: vocabNotes, grammarNotes: grammarNotes)

                    if let answerMeaningText {
                        SelectableTextView(text: "Dịch đáp án: \(answerMeaningText)", onSelectionChange: handleInstantLookupSelection)
                    }
                    if let answerText = nonRedundantAnswerText(for: question) {
                        SelectableTextView(text: answerText, onSelectionChange: handleInstantLookupSelection)
                    }
                    if let starOrderText {
                        SelectableTextView(
                            text: "正しい順序: \(starOrderText)",
                            font: .appPreferred(.headline),
                            isBold: true,
                            onSelectionChange: handleInstantLookupSelection
                        )
                    }
                    if let explanation = explanationText {
                        Label("Giải thích", systemImage: "lightbulb")
                            .font(.headline)
                            .foregroundStyle(.orange)
                        SelectableTextView(text: explanation, onSelectionChange: handleInstantLookupSelection)
                    }
                    if isReadingQuestion && !shouldLoadStudyNotes {
                        Button {
                            expandedStudyNoteQuestionIDs.insert(question.id)
                        } label: {
                            Label("Hiện ghi chú từ vựng/ngữ pháp học thêm", systemImage: "text.book.closed")
                        }
                        .buttonStyle(.bordered)
                        .tint(.green)
                    }
                    if !grammarNotes.isEmpty {
                        noteSection(title: "Ngữ pháp", systemImage: "text.book.closed", lines: grammarNotes.map { "\($0.pattern) = \($0.meaning)" })
                    }
                    if !vocabNotes.isEmpty {
                        noteSection(title: "Từ vựng / cách đọc", systemImage: "character.book.closed", lines: vocabNotes.map(dictionary.note(for:)))
                    }
                } else if isReadingQuestion {
                    Button {
                        expandedStudyNoteQuestionIDs.insert(question.id)
                        expandedExplanationQuestionIDs.insert(question.id)
                    } label: {
                        Label("Hiện ghi chú từ vựng/ngữ pháp học thêm", systemImage: "text.book.closed")
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                }
            }
            .font(.body)
            .lineSpacing(6)
            .textSelection(.enabled)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.yellow.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func noteSection(title: String, systemImage: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(.green)
            ForEach(lines, id: \.self) { line in
                SelectableTextView(
                    text: "• \(line)",
                    font: .appPreferred(.callout),
                    onSelectionChange: handleInstantLookupSelection
                )
            }
        }
    }

    private func answerMeaning(for question: PracticeQuestion, vocabNotes: [VocabularyEntry], grammarNotes: [GrammarEntry]) -> String? {
        guard let correct = question.correctAnswer,
              question.options.indices.contains(correct - 1) else {
            return nil
        }

        let answer = question.options[correct - 1]
        if let fromExplanation = answerMeaningFromExplanation(question.explanation, answer: answer) {
            return fromExplanation
        }

        let underlinedTerms = underlinedTerms(in: question)
        let underlinedVocab = vocabNotes.filter { entry in
            underlinedTerms.contains { term in
                dictionary.matches(entry, in: term) || term.contains(entry.word)
            }
        }
        if !underlinedVocab.isEmpty {
            return underlinedVocab.prefix(3).map(dictionary.note(for:)).joined(separator: "; ")
        }

        if let grammar = grammarNotes.first(where: { grammar in
            grammar.searchTerms.contains { term in
                let normalized = term.replacingOccurrences(of: "〜", with: "")
                return normalized.count >= 2 && answer.contains(normalized)
            }
        }) {
            return "「\(grammar.pattern)」= \(grammar.meaning)"
        }

        let exactVocab = vocabNotes.filter { entry in
            answer == entry.word || answer.contains(entry.word) || dictionary.matches(entry, in: answer)
        }
        if !exactVocab.isEmpty {
            return exactVocab.prefix(3).map(dictionary.note(for:)).joined(separator: "; ")
        }

        return nil
    }

    private func nonRedundantAnswerText(for question: PracticeQuestion) -> String? {
        guard let answerText = question.answerText?.nonEmpty else { return nil }
        guard let correct = question.correctAnswer,
              question.options.indices.contains(correct - 1) else {
            return answerText
        }
        let answer = question.options[correct - 1]
        let normalizedAnswerText = answerText.removingAppMarkers
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedAnswer = answer.removingAppMarkers
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return normalizedAnswerText == normalizedAnswer ? nil : answerText
    }

    private func underlinedTerms(in question: PracticeQuestion) -> [String] {
        if questionHasBlankPlaceholder(question) {
            return []
        }
        if let preferred = preferredKanjiUnderlineTerm(for: question) {
            return [preferred]
        }

        guard let html = question.textHtml else {
            guard shouldInferUnderline(for: question) else { return [] }
            return dictionary.inferredUnderlineTerm(for: question).map { [$0] } ?? []
        }
        var terms: [String] = []
        var remainder = html

        while let start = remainder.range(of: "[[u]]") {
            remainder = String(remainder[start.upperBound...])
            guard let end = remainder.range(of: "[[/u]]") else { break }
            let term = String(remainder[..<end.lowerBound]).removingAppMarkers
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !term.isEmpty {
                terms.append(term)
            }
            remainder = String(remainder[end.upperBound...])
        }

        if terms.isEmpty, shouldInferUnderline(for: question), let inferred = dictionary.inferredUnderlineTerm(for: question) {
            return [inferred]
        }
        return terms
    }

    private func preferredKanjiUnderlineTerm(for question: PracticeQuestion) -> String? {
        guard question.sectionTitle == "Từ vựng",
              (1...10).contains(question.number),
              let term = dictionary.confidentKanjiUnderlineTerm(for: question) else {
            return nil
        }
        let cleanText = ((question.textHtml ?? question.text).nonEmpty ?? question.text).removingAppMarkers
        return cleanText.contains(term) ? term : nil
    }

    private func answerMeaningFromExplanation(_ raw: String?, answer: String) -> String? {
        guard let raw = raw?.nonEmpty else { return nil }
        let cleanedAnswer = answer.removingAppMarkers
        let candidates = [
            cleanedAnswer,
            "「\(cleanedAnswer)」",
            "『\(cleanedAnswer)』"
        ]
        let lines = raw
            .components(separatedBy: CharacterSet(charactersIn: "\n。"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        for line in lines {
            guard line.contains("=") || line.contains("＝") else { continue }
            let normalizedLine = line.replacingOccurrences(of: "＝", with: "=")
            guard candidates.contains(where: { normalizedLine.contains($0) }) else { continue }
            let parts = normalizedLine.components(separatedBy: "=")
            guard let meaning = parts.dropFirst().joined(separator: "=").nonEmpty else { continue }
            return "「\(cleanedAnswer)」= \(meaning.trimmingCharacters(in: .whitespacesAndNewlines))"
        }

        return nil
    }

    private var questionSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 60, coordinateSpace: .local)
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = abs(value.translation.height)
                guard abs(horizontal) > max(80, vertical * 1.8) else { return }
                if horizontal < 0 {
                    swipeQuestion(1)
                } else {
                    swipeQuestion(-1)
                }
            }
    }

    private func swipeQuestion(_ delta: Int) {
        questionTransitionDirection = delta >= 0 ? 1 : -1
        withAnimation(.snappy(duration: 0.28, extraBounce: 0.04)) {
            moveQuestion(delta)
        }
    }

    private func moveQuestion(_ delta: Int) {
        let next = selectedQuestionIndex + delta
        guard selectedQuestions.indices.contains(next) else { return }
        selectedQuestionIndex = next
        selectedAnswer = answerHistory[selectedQuestions[next].id]
    }

    private func saveAnswer(_ index: Int, for question: PracticeQuestion) {
        answerHistory[question.id] = index
        Self.saveAnswerHistory(answerHistory)
    }

    private func selectAnswer(_ index: Int, for question: PracticeQuestion) {
        guard selectedAnswer == nil else { return }
        guard !isActivePlayerDead else { return }

        if selectedDrill == nil,
           let state = bossStates[question.examID],
           state.finishedAt != nil {
            return
        }

        selectedAnswer = index
        saveAnswer(index, for: question)
        playAnswerEffect(index, for: question)
        applyBossAnswer(index, for: question)

        if selectedDrill != nil {
            saveCurrentProfile()
        }
    }

    private func playAnswerEffect(_ index: Int, for question: PracticeQuestion) {
        guard selectedDrill == nil else { return }
        if let correct = question.correctAnswer, index == correct - 1 {
            let state = bossStates[question.examID]
            triggerBossHit(combo: (state?.combo ?? 0) + 1 >= 5)
        } else {
            triggerPlayerHit()
        }
    }

    private func resetHistory() {
        answerHistory = [:]
        selectedAnswer = nil
        bossStates = [:]
        UserDefaults.standard.removeObject(forKey: Self.answerHistoryKey)
        UserDefaults.standard.removeObject(forKey: Self.bossStatesKey)
    }

    private func resetDrillHistory() {
        guard let selectedDrill else { return }
        let drillQuestionIDs = Set(cachedQuestions(for: selectedDrill).map(\.id))
        answerHistory = answerHistory.filter { !drillQuestionIDs.contains($0.key) }
        selectedAnswer = currentQuestion.flatMap { answerHistory[$0.id] }
        Self.saveAnswerHistory(answerHistory)
        saveCurrentProfile()
    }

    private func createNewPlayer() {
        let name = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let profile = PlayerProfile(
            id: UUID(),
            name: name,
            createdAt: now,
            lastPlayedAt: now,
            answerHistory: [:],
            bossStates: [:],
            isDead: false
        )
        playerProfiles.insert(profile, at: 0)
        activePlayerID = profile.id
        answerHistory = [:]
        bossStates = [:]
        selectedExamID = nil
        selectedDrill = nil
        selectedAnswer = nil
        selectedQuestionIndex = 0
        Self.savePlayerProfiles(playerProfiles)
        audio.play(.save)
        gameScreen = .bossMap
    }

    private func continuePlayer(_ profile: PlayerProfile) {
        activePlayerID = profile.id
        answerHistory = profile.answerHistory
        bossStates = Self.pausedBossStates(profile.bossStates)
        selectedExamID = nil
        selectedDrill = nil
        selectedAnswer = nil
        selectedQuestionIndex = 0
        saveCurrentProfile()
        audio.play(.boss)
        gameScreen = .bossMap
    }

    private func deleteProfile(_ profile: PlayerProfile) {
        playerProfiles.removeAll { $0.id == profile.id }
        if activePlayerID == profile.id {
            activePlayerID = nil
        }
        Self.savePlayerProfiles(playerProfiles)
    }

    private func enterPracticeHome(tab: String) {
        pauseBossTimerIfNeeded()
        isBossRunMode = false
        selectedLibraryTab = tab
        if tab == "N1" || tab == "N2" {
            selectedLevel = tab
        }
        selectedExamID = nil
        selectedDrill = nil
        selectedQuestionIndex = 0
        selectedAnswer = nil
        showsQuestionPicker = false
        gameScreen = .practice
    }

    private func saveCurrentProfile() {
        let persistedBossStates = Self.pausedBossStates(bossStates)
        guard let activePlayerID,
              let index = playerProfiles.firstIndex(where: { $0.id == activePlayerID }) else {
            Self.saveAnswerHistory(answerHistory)
            Self.saveBossStates(persistedBossStates)
            return
        }
        playerProfiles[index].answerHistory = answerHistory
        playerProfiles[index].bossStates = persistedBossStates
        playerProfiles[index].lastPlayedAt = now
        Self.saveAnswerHistory(answerHistory)
        Self.saveBossStates(persistedBossStates)
        Self.savePlayerProfiles(playerProfiles)
    }

    private func sanitizeSavedTimers() {
        let pausedGlobalStates = Self.pausedBossStates(bossStates)
        if pausedGlobalStates != bossStates {
            bossStates = pausedGlobalStates
            Self.saveBossStates(pausedGlobalStates)
        }

        var changedProfiles = false
        let pausedProfiles = playerProfiles.map { profile in
            var copy = profile
            let pausedStates = Self.pausedBossStates(profile.bossStates)
            if pausedStates != profile.bossStates {
                copy.bossStates = pausedStates
                changedProfiles = true
            }
            return copy
        }

        if changedProfiles {
            playerProfiles = pausedProfiles
            Self.savePlayerProfiles(pausedProfiles)
        }
    }

    private var isActivePlayerDead: Bool {
        guard let activePlayerID,
              let profile = playerProfiles.first(where: { $0.id == activePlayerID }) else {
            return false
        }
        return profile.isDead
    }

    private func markActivePlayerDead() {
        guard let activePlayerID,
              let index = playerProfiles.firstIndex(where: { $0.id == activePlayerID }) else { return }
        playerProfiles[index].isDead = true
        playerProfiles[index].answerHistory = answerHistory
        playerProfiles[index].bossStates = bossStates
        playerProfiles[index].lastPlayedAt = now
        Self.savePlayerProfiles(playerProfiles)
    }

    private func restartActivePlayer() {
        if let activePlayerID,
           let index = playerProfiles.firstIndex(where: { $0.id == activePlayerID }) {
            playerProfiles[index].answerHistory = [:]
            playerProfiles[index].bossStates = [:]
            playerProfiles[index].isDead = false
            playerProfiles[index].lastPlayedAt = now
        }
        answerHistory = [:]
        bossStates = [:]
        selectedExamID = nil
        selectedDrill = nil
        selectedAnswer = nil
        selectedQuestionIndex = 0
        Self.savePlayerProfiles(playerProfiles)
        audio.play(.save)
        gameScreen = .bossMap
    }

    private func bossMetrics(for examID: String) -> BossMetrics {
        var languageTotal = 0
        var readingTotal = 0
        var languageCorrect = 0
        var readingCorrect = 0

        for question in store.questions(for: examID) {
            let isReading = question.sectionTitle == "Đọc hiểu"
            let isCorrect = answerResult(for: question) == .correct

            if isReading {
                readingTotal += 1
                if isCorrect { readingCorrect += 1 }
            } else {
                languageTotal += 1
                if isCorrect { languageCorrect += 1 }
            }
        }

        let languageDamage = languageTotal == 0 ? 0 : Self.bossSectionHP / Double(languageTotal)
        let readingDamage = readingTotal == 0 ? 0 : Self.bossSectionHP / Double(readingTotal)
        let languageHP = max(0, Self.bossSectionHP - Double(languageCorrect) * languageDamage)
        let readingHP = max(0, Self.bossSectionHP - Double(readingCorrect) * readingDamage)

        return BossMetrics(
            totalHP: languageHP + readingHP,
            languageHP: languageHP,
            readingHP: readingHP,
            languageCorrect: languageCorrect,
            readingCorrect: readingCorrect,
            languageTotal: languageTotal,
            readingTotal: readingTotal
        )
    }

    private func bossMood(state: BossRunState?, metrics: BossMetrics) -> BossMood {
        if state?.didWin == true || metrics.isDefeated {
            return .champion
        }
        if state?.finishedAt != nil {
            return .defeated
        }
        let ratio = metrics.totalHP / Self.bossTotalHP
        if ratio <= 0.20 {
            return .pressured
        }
        if ratio <= 0.60 {
            return .angry
        }
        return .normal
    }

    private func bossExamTag(for exam: ExamDocument) -> String {
        let title = exam.title
            .replacingOccurrences(of: " tháng ", with: "/")
            .replacingOccurrences(of: " ", with: "")
        return title.isEmpty ? exam.normalizedLevel : title
    }

    private func bossState(for examID: String) -> BossRunState {
        bossStates[examID] ?? BossRunState(
            startedAt: now,
            heartsLeft: Self.bossStartingHearts,
            finishedAt: nil,
            didWin: false
        )
    }

    private func startBossIfNeeded(for examID: String) {
        guard bossStates[examID] == nil else { return }
        let metrics = bossMetrics(for: examID)
        bossStates[examID] = BossRunState(
            startedAt: now,
            activeElapsed: 0,
            lastActiveAt: metrics.isDefeated ? nil : now,
            heartsLeft: Self.bossStartingHearts,
            finishedAt: metrics.isDefeated ? now : nil,
            didWin: metrics.isDefeated
        )
        Self.saveBossStates(bossStates)
    }

    private func bossTimeRemaining(for examID: String) -> TimeInterval {
        let state = bossState(for: examID)
        let liveElapsed: TimeInterval
        let shouldCountLiveTime = selectedExamID == examID
            && gameScreen == .practice
            && selectedDrill == nil
            && state.finishedAt == nil

        if shouldCountLiveTime, let lastActiveAt = state.lastActiveAt {
            liveElapsed = max(0, now.timeIntervalSince(lastActiveAt))
        } else {
            liveElapsed = 0
        }
        return max(0, Self.bossTimeLimit - state.activeElapsed - liveElapsed)
    }

    private func pauseBossTimerIfNeeded() {
        var updated = bossStates
        var changed = false

        if let examID = selectedExamID,
           var state = updated[examID],
           state.finishedAt == nil,
           let lastActiveAt = state.lastActiveAt {
            state.activeElapsed += max(0, now.timeIntervalSince(lastActiveAt))
            state.lastActiveAt = nil
            updated[examID] = state
            changed = true
        }

        for key in updated.keys where key != selectedExamID {
            guard var state = updated[key],
                  state.lastActiveAt != nil else { continue }
            state.lastActiveAt = nil
            updated[key] = state
            changed = true
        }

        guard changed else { return }
        bossStates = updated
        Self.saveBossStates(bossStates)
        saveCurrentProfile()
    }

    private func resumeBossTimerIfNeeded() {
        guard let examID = selectedExamID,
              gameScreen == .practice,
              selectedDrill == nil,
              !isActivePlayerDead,
              var state = bossStates[examID],
              state.finishedAt == nil,
              state.lastActiveAt == nil else { return }
        state.lastActiveAt = now
        bossStates[examID] = state
        Self.saveBossStates(bossStates)
    }

    private func formattedBossTime(_ interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval.rounded(.down)))
        return String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    private func triggerBossHit(combo: Bool = false) {
        battleFlashText = combo ? "COMBO!" : "HIT!"
        withAnimation(.spring(response: 0.18, dampingFraction: 0.42)) {
            bossHitPulse = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            withAnimation(.easeOut(duration: 0.18)) {
                bossHitPulse = false
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.78) {
            withAnimation(.easeOut(duration: 0.18)) {
                battleFlashText = nil
            }
        }
    }

    private func triggerPlayerHit() {
        battleFlashText = "MISS!"
        withAnimation(.easeInOut(duration: 0.12).repeatCount(3, autoreverses: true)) {
            playerHitPulse = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.46) {
            withAnimation(.easeOut(duration: 0.18)) {
                playerHitPulse = false
                battleFlashText = nil
            }
        }
    }

    private func applyBossAnswer(_ index: Int, for question: PracticeQuestion) {
        guard selectedDrill == nil else { return }
        let examID = question.examID
        startBossIfNeeded(for: examID)
        guard var state = bossStates[examID], state.finishedAt == nil else { return }

        if let correct = question.correctAnswer, index == correct - 1 {
            audio.play(.correct)
            state.combo += 1
            if state.combo == 3 {
                state.activeElapsed = max(0, state.activeElapsed - 10 * 60)
                audio.play(.combo)
            }
            if state.combo == 5 {
                bossStates[examID] = state
                if unlockOneWrongAnswer(in: examID) {
                    if var refreshedState = bossStates[examID] {
                        state = refreshedState
                    }
                    audio.play(.combo)
                } else {
                    state.wrongAnswerTickets += 1
                    bossStates[examID] = state
                    battleFlashText = "+1 Ticket"
                    audio.play(.combo)
                }
            }
            if state.combo >= 6 {
                if state.heartsLeft < Self.bossMaxHearts {
                    state.heartsLeft += 1
                    audio.play(.combo)
                }
                state.combo = 0
            }
            if bossScore(for: bossMetrics(for: examID)) >= 100 {
                battleFlashText = "Qua cửa!"
            }
        } else {
            audio.play(.wrong)
            if state.wrongAnswerTickets > 0 {
                state.wrongAnswerTickets -= 1
                answerHistory.removeValue(forKey: question.id)
                selectedAnswer = nil
                Self.saveAnswerHistory(answerHistory)
                battleFlashText = "Ticket!"
                audio.play(.combo)
            }
            state.combo = 0
            state.heartsLeft = max(0, state.heartsLeft - 1)
            if state.heartsLeft == 0 {
                state.finishedAt = now
                state.didWin = false
                audio.play(.lose)
                bossStates[examID] = state
                markActivePlayerDead()
            }
        }

        if state.finishedAt == nil && answeredAllQuestions(in: examID) {
            let metrics = bossMetrics(for: examID)
            if bossScore(for: metrics) >= 100 {
                state.finishedAt = now
                state.didWin = true
                audio.play(.win)
            } else {
                state.finishedAt = now
                state.didWin = false
                audio.play(.lose)
                bossStates[examID] = state
                markActivePlayerDead()
            }
        }

        bossStates[examID] = state
        Self.saveBossStates(bossStates)
        saveCurrentProfile()
    }

    private func bossScore(for metrics: BossMetrics) -> Int {
        Int((Self.bossTotalHP - metrics.totalHP).rounded())
    }

    private func bossHasPassed(_ examID: String) -> Bool {
        if bossStates[examID]?.didWin == true { return true }
        return bossScore(for: bossMetrics(for: examID)) >= 100
    }

    private func answeredAllQuestions(in examID: String) -> Bool {
        let questions = store.questions(for: examID)
        return !questions.isEmpty && questions.allSatisfy { answerHistory[$0.id] != nil }
    }

    private func unlockOneWrongAnswer(in examID: String) -> Bool {
        let questions = store.questions(for: examID)
        guard let question = questions.first(where: { question in
            guard let saved = answerHistory[question.id],
                  let correct = question.correctAnswer else { return false }
            return saved != correct - 1
        }) else {
            return false
        }
        answerHistory.removeValue(forKey: question.id)
        if currentQuestion?.id == question.id {
            selectedAnswer = nil
        }
        Self.saveAnswerHistory(answerHistory)
        return true
    }

    private func updateBossTimeoutIfNeeded() {
        guard let examID = selectedExamID,
              gameScreen == .practice,
              selectedDrill == nil,
              var state = bossStates[examID],
              state.finishedAt == nil,
              bossTimeRemaining(for: examID) <= 0 else { return }
        state.finishedAt = now
        state.didWin = false
        bossStates[examID] = state
        Self.saveBossStates(bossStates)
        audio.play(.lose)
        markActivePlayerDead()
        saveCurrentProfile()
    }

    private static func questionSearchText(for question: PracticeQuestion) -> String {
        [
            question.examTitle,
            question.examLevel,
            question.sectionTitle,
            question.instruction ?? "",
            question.text,
            question.textHtml?.removingAppMarkers ?? "",
            question.passage ?? "",
            question.options.joined(separator: "\n"),
            question.answerText ?? "",
            question.explanation ?? ""
        ]
        .joined(separator: "\n")
    }

    private func searchSnippet(for question: PracticeQuestion) -> String {
        let source = (questionSearchIndex[question.id] ?? Self.questionSearchText(for: question))
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let range = source.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) else {
            return String(source.prefix(90))
        }
        let prefixStart = source.index(range.lowerBound, offsetBy: -30, limitedBy: source.startIndex) ?? source.startIndex
        let suffixEnd = source.index(range.upperBound, offsetBy: 60, limitedBy: source.endIndex) ?? source.endIndex
        let snippet = source[prefixStart..<suffixEnd]
        return "\(prefixStart == source.startIndex ? "" : "...")\(snippet)\(suffixEnd == source.endIndex ? "" : "...")"
    }

    private static func loadAnswerHistory() -> [String: Int] {
        let raw = UserDefaults.standard.dictionary(forKey: answerHistoryKey) ?? [:]
        return raw.reduce(into: [String: Int]()) { result, item in
            if let value = item.value as? Int {
                result[item.key] = value
            } else if let value = item.value as? NSNumber {
                result[item.key] = value.intValue
            }
        }
    }

    private static func saveAnswerHistory(_ history: [String: Int]) {
        UserDefaults.standard.set(history, forKey: answerHistoryKey)
    }

    private static func loadBossStates() -> [String: BossRunState] {
        guard let data = UserDefaults.standard.data(forKey: bossStatesKey) else { return [:] }
        let states = (try? JSONDecoder().decode([String: BossRunState].self, from: data)) ?? [:]
        return pausedBossStates(states)
    }

    private static func saveBossStates(_ states: [String: BossRunState]) {
        guard let data = try? JSONEncoder().encode(states) else { return }
        UserDefaults.standard.set(data, forKey: bossStatesKey)
    }

    private static func loadPlayerProfiles() -> [PlayerProfile] {
        guard let data = UserDefaults.standard.data(forKey: playerProfilesKey) else { return [] }
        let profiles = (try? JSONDecoder().decode([PlayerProfile].self, from: data)) ?? []
        return profiles.map { profile in
            var pausedProfile = profile
            pausedProfile.bossStates = pausedBossStates(profile.bossStates)
            return pausedProfile
        }
    }

    private static func savePlayerProfiles(_ profiles: [PlayerProfile]) {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        UserDefaults.standard.set(data, forKey: playerProfilesKey)
    }

    private static func pausedBossStates(_ states: [String: BossRunState]) -> [String: BossRunState] {
        states.mapValues { state in
            var paused = state
            paused.lastActiveAt = nil
            return paused
        }
    }

    private func optionBackground(index: Int, question: PracticeQuestion) -> Color {
        guard let selectedAnswer else { return Color(red: 1.0, green: 0.96, blue: 0.86) }
        if let correct = question.correctAnswer, index == correct - 1 {
            return Color.green.opacity(0.20)
        }
        if selectedAnswer == index {
            return Color.red.opacity(0.14)
        }
        return Color(red: 1.0, green: 0.96, blue: 0.86)
    }

    private func optionBorder(index: Int, question: PracticeQuestion) -> Color {
        guard let selectedAnswer else { return Color.gray.opacity(0.25) }
        if let correct = question.correctAnswer, index == correct - 1 {
            return .green
        }
        if selectedAnswer == index {
            return .red.opacity(0.65)
        }
        return Color.gray.opacity(0.18)
    }

    private func attributedQuestion(_ question: PracticeQuestion, speechRange: NSRange? = nil) -> NSAttributedString {
        let source = questionTextWithInferredUnderline(question)
        let output = NSMutableAttributedString()
        var remainder = source
        let baseFont = PlatformFont.appBold(ofSize: 30)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 8
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: baseFont,
            .foregroundColor: PlatformColor.appLabel,
            .paragraphStyle: paragraph
        ]

        while let start = remainder.range(of: "[[u]]") {
            let before = String(remainder[..<start.lowerBound])
            output.append(NSAttributedString(
                string: before.removingAppMarkers,
                attributes: baseAttributes
            ))
            remainder = String(remainder[start.upperBound...])

            guard let end = remainder.range(of: "[[/u]]") else { break }
            output.append(NSAttributedString(
                string: String(remainder[..<end.lowerBound]),
                attributes: baseAttributes.merging([
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .foregroundColor: PlatformColor.appSystemOrange
                ]) { _, new in new }
            ))
            remainder = String(remainder[end.upperBound...])
        }

        output.append(NSAttributedString(string: remainder.removingAppMarkers, attributes: baseAttributes))
        applySpeechHighlight(to: output, range: speechRange)
        return output
    }

    private func questionTextWithInferredUnderline(_ question: PracticeQuestion) -> String {
        let raw = (question.textHtml ?? question.text).nonEmpty ?? passageBlankPrompt(for: question) ?? ""
        if questionHasBlankPlaceholder(question) || containsBlankPlaceholder(raw) {
            return raw.removingAppMarkers
        }
        if raw.contains("[[u]]") {
            return raw
        }

        guard !raw.contains("[[u]]"),
              shouldInferUnderline(for: question),
              let term = preferredKanjiUnderlineTerm(for: question) ?? dictionary.inferredUnderlineTerm(for: question),
              let range = raw.range(of: term) else {
            return raw
        }
        var output = raw
        output.replaceSubrange(range, with: "[[u]]\(term)[[/u]]")
        return output
    }

    private func shouldInferUnderline(for question: PracticeQuestion) -> Bool {
        if question.sectionTitle != "Từ vựng" {
            return false
        }
        let rawText = [question.text, question.textHtml ?? ""].joined(separator: "\n")
        if containsBlankPlaceholder(rawText) {
            return false
        }
        let instruction = question.instruction ?? ""
        if instruction.contains("入れる")
            || instruction.localizedCaseInsensitiveContains("điền") {
            return false
        }
        return true
    }

    private func questionHasBlankPlaceholder(_ question: PracticeQuestion) -> Bool {
        containsBlankPlaceholder(question.text) || containsBlankPlaceholder(question.textHtml ?? "")
    }

    private func containsBlankPlaceholder(_ text: String) -> Bool {
        if text.contains("[[blank]]") {
            return true
        }
        return text.range(of: #"[（(][\s　]*[）)]"#, options: .regularExpression) != nil
    }

    private func attributedPassage(_ passage: String, currentQuestionNumber: Int) -> NSAttributedString {
        let output = NSMutableAttributedString(string: passage)
        let fullRange = NSRange(location: 0, length: output.length)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 8
        output.addAttributes([
            .font: PlatformFont.appPreferred(.title3),
            .foregroundColor: PlatformColor.appLabel,
            .paragraphStyle: paragraph
        ], range: fullRange)

        let patterns = [
            #"【\d+(?:-[ab])?】"#,
            #"\[\d+(?:-[ab])?\]"#,
            #"[\(（][0-9０-９]+(?:-[ab])?[\)）]"#
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            for match in regex.matches(in: passage, range: fullRange) {
                output.addAttributes([
                    .font: PlatformFont.appBold(ofSize: PlatformFont.appPreferred(.title3).pointSize),
                    .foregroundColor: PlatformColor.appSystemRed,
                    .backgroundColor: PlatformColor.appSystemRed.withAlphaComponent(0.13)
                ], range: match.range)
            }
        }

        let currentPatterns = [
            "【\(currentQuestionNumber)(?:-[ab])?】",
            "\\[\(currentQuestionNumber)(?:-[ab])?\\]",
            "[\\(（]\(fullWidthNumber(currentQuestionNumber))[\\)）]",
            "[\\(（]\(currentQuestionNumber)[\\)）]"
        ]

        for pattern in currentPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            for match in regex.matches(in: passage, range: fullRange) {
                output.addAttributes([
                    .font: PlatformFont.appBold(ofSize: PlatformFont.appPreferred(.title3).pointSize + 1),
                    .foregroundColor: PlatformColor.appWhite,
                    .backgroundColor: PlatformColor.appSystemRed
                ], range: match.range)
            }
        }

        return output
    }

    private func passageQuestionMarker(for question: PracticeQuestion) -> String? {
        let source = (question.textHtml ?? question.text).removingAppMarkers
        let patterns = [
            #"【\d+(?:-[ab])?】"#,
            #"\[\d+(?:-[ab])?\]"#,
            #"[\(（][0-9０-９]+(?:-[ab])?[\)）]"#
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(source.startIndex..<source.endIndex, in: source)
            if let match = regex.firstMatch(in: source, range: range),
               let swiftRange = Range(match.range, in: source) {
                return String(source[swiftRange])
            }
        }

        return nil
    }

    private func passageBlankPrompt(for question: PracticeQuestion) -> String? {
        guard question.passage?.nonEmpty != nil else { return nil }
        let isGrammarPassage = question.sectionTitle.contains("Ngữ pháp")
            && (question.instruction?.localizedCaseInsensitiveContains("đoạn văn") == true
                || question.instruction?.contains("文章") == true)
        guard isGrammarPassage else { return nil }
        return "（\(fullWidthNumber(question.number))）に入るものを選びなさい。"
    }

    private func fullWidthNumber(_ number: Int) -> String {
        String(number).map { character in
            switch character {
            case "0": return "０"
            case "1": return "１"
            case "2": return "２"
            case "3": return "３"
            case "4": return "４"
            case "5": return "５"
            case "6": return "６"
            case "7": return "７"
            case "8": return "８"
            case "9": return "９"
            default: return character
            }
        }
        .map(String.init)
        .joined()
    }

    private func conciseExplanation(_ raw: String?, for question: PracticeQuestion) -> String? {
        guard let raw = raw?.nonEmpty else { return nil }
        let blockedPrefixes = [
            "Từ N1 cần nhớ:",
            "Từ N2 cần nhớ:",
            "Cách đọc kanji trong câu:",
            "Ngữ pháp N1 cần nhớ:"
        ]
        let cleaned = removeGenericReadingPhrases(from: raw
            .components(separatedBy: .newlines)
            .map { line in
                var value = line.trimmingCharacters(in: .whitespacesAndNewlines)
                for prefix in blockedPrefixes where value.hasPrefix(prefix) {
                    value = ""
                }
                if value.hasPrefix("正しい順序:") {
                    value = value
                        .components(separatedBy: ". ")
                        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("正しい順序:") }
                        .joined(separator: ". ")
                }
                if value.hasPrefix("Đáp án:") {
                    value = value.replacingOccurrences(of: #"^Đáp án:\s*\d+\.?\s*"#, with: "", options: .regularExpression)
                }
                return value
            }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines))

        guard !cleaned.isEmpty else { return nil }
        if isRedundantVocabularyExplanation(cleaned, for: question) { return nil }
        if cleaned.count <= 180 { return cleaned }

        let separators = CharacterSet(charactersIn: "。.!?")
        let sentences = cleaned.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let short = sentences.prefix(2).joined(separator: "。")
        return short.isEmpty ? String(cleaned.prefix(180)) + "..." : short + "。"
    }

    private func isRedundantVocabularyExplanation(_ text: String, for question: PracticeQuestion) -> Bool {
        guard question.sectionTitle == "Từ vựng" else { return false }
        let compact = text.replacingOccurrences(of: " ", with: "")
        guard compact.hasPrefix("Chọn") || compact.hasPrefix("Đápán") else { return false }
        let genericMarkers = ["hợpnghĩa", "cáchdùng", "tựnhiên", "=", "（", "("]
        return genericMarkers.contains { compact.contains($0) }
    }

    private func resolvedStarOrderText(for question: PracticeQuestion) -> String? {
        if let order = question.correctOrder, !order.isEmpty {
            return order.joined(separator: " → ")
        }
        if let starOrder = question.starOrder?.nonEmpty {
            let pieces = starOrder
                .replacingOccurrences(of: "→", with: "-")
                .replacingOccurrences(of: "/", with: "-")
                .split(separator: "-")
                .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            if pieces.count == question.options.count,
               pieces.allSatisfy({ (1...question.options.count).contains($0) }) {
                return pieces
                    .map { question.options[$0 - 1].removingAppMarkers }
                    .joined(separator: " → ")
            }
            return normalizeOrderSeparators(starOrder)
        }
        guard let explanation = question.explanation,
              let range = explanation.range(of: "正しい順序:") else {
            return nil
        }
        let tail = explanation[range.upperBound...]
        let rawOrder = tail
            .components(separatedBy: ".")
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let rawOrder, !rawOrder.isEmpty else { return nil }
        return normalizeOrderSeparators(rawOrder)
    }

    private func normalizeOrderSeparators(_ text: String) -> String {
        text
            .replacingOccurrences(of: " / ", with: " → ")
            .replacingOccurrences(of: "/", with: " → ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func fallbackExplanation(for question: PracticeQuestion, vocabNotes: [VocabularyEntry], grammarNotes: [GrammarEntry]) -> String? {
        guard let correct = question.correctAnswer, question.options.indices.contains(correct - 1) else {
            return nil
        }

        let answer = question.options[correct - 1]
        switch question.sectionTitle {
        case "Ngữ pháp":
            if let grammar = grammarNotes.first {
                return "「\(grammar.pattern)」= \(grammar.meaning)."
            }
            if let correct = question.correctAnswer, question.options.indices.contains(correct - 1) {
                return "Đáp án đúng là 「\(question.options[correct - 1])」."
            }
            return nil
        case "Đọc hiểu":
            return readingFallbackExplanation(for: question)
        case "Từ vựng":
            return vocabularyFallbackExplanation(for: question, vocabNotes: vocabNotes)
        default:
            return "Chọn 「\(answer)」."
        }
    }

    private func vocabularyFallbackExplanation(for question: PracticeQuestion, vocabNotes: [VocabularyEntry]) -> String? {
        guard let correct = question.correctAnswer, question.options.indices.contains(correct - 1) else {
            return nil
        }

        let answer = question.options[correct - 1].removingAppMarkers
        let underlined = underlinedTerms(in: question)
        let queriedNotes = vocabNotes.filter { entry in
            underlined.contains { term in
                dictionary.matches(entry, in: term) || term.contains(entry.word) || entry.word.contains(term)
            }
        }
        let answerNotes = vocabNotes.filter { entry in
            answer == entry.word || answer == entry.reading || answer.contains(entry.word) || dictionary.matches(entry, in: answer)
        }
        var seenNoteIDs = Set<String>()
        let notes = (queriedNotes + answerNotes)
            .filter { entry in
                if seenNoteIDs.contains(entry.id) { return false }
                seenNoteIDs.insert(entry.id)
                return true
            }
            .prefix(3)
            .map(dictionary.note(for:))

        if question.number <= 5 {
            return "Cách đọc đúng là 「\(answer)」."
        }

        if (6...10).contains(question.number) {
            if !notes.isEmpty {
                return "Từ kana được hỏi viết bằng kanji là 「\(answer)」. \(notes.joined(separator: "; "))."
            }
            return "Từ kana được hỏi viết bằng kanji là 「\(answer)」."
        }

        if (11...20).contains(question.number) {
            if !notes.isEmpty {
                return "Điền 「\(answer)」. \(notes.joined(separator: "; "))."
            }
            return "Điền 「\(answer)」."
        }

        if (21...25).contains(question.number) {
            if !notes.isEmpty {
                return "Từ/cụm được hỏi gần nghĩa nhất với 「\(answer)」. \(notes.joined(separator: "; "))."
            }
            return "Từ/cụm được hỏi gần nghĩa nhất với 「\(answer)」."
        }

        if !notes.isEmpty {
            return "Cách dùng đúng là lựa chọn 「\(answer)」. \(notes.joined(separator: "; "))."
        }
        return "Cách dùng đúng là lựa chọn 「\(answer)」."
    }

    private func readingFallbackExplanation(for question: PracticeQuestion) -> String? {
        guard let correct = question.correctAnswer, question.options.indices.contains(correct - 1) else {
            return nil
        }
        let answer = question.options[correct - 1].removingAppMarkers
        let compactAnswer = answer.replacingOccurrences(of: "\n", with: " ")
        if let evidence = readingEvidenceSentence(for: question, answer: compactAnswer) {
            return "Chọn 「\(compactAnswer)」 vì khớp với đoạn: 「\(evidence)」."
        }
        return nil
    }

    private func readingEvidenceSentence(for question: PracticeQuestion, answer: String) -> String? {
        guard let passage = question.passage?.removingAppMarkers.nonEmpty else { return nil }
        let keywords = readingKeywords(from: answer + " " + question.text.removingAppMarkers)
        guard !keywords.isEmpty else { return nil }

        let sentences = passage
            .replacingOccurrences(of: "\n", with: "。")
            .components(separatedBy: CharacterSet(charactersIn: "。！？!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count >= 8 }

        let scored = sentences.compactMap { sentence -> (sentence: String, score: Int)? in
            let exactScore = keywords.reduce(0) { partial, keyword in
                sentence.contains(keyword) ? partial + keyword.count : partial
            }
            let fuzzyScore = readingFuzzyScore(sentence: sentence, keywords: keywords)
            let score = exactScore * 3 + fuzzyScore
            guard score >= 2 else { return nil }
            return (sentence, score)
        }
        .sorted {
            if $0.score == $1.score { return $0.sentence.count < $1.sentence.count }
            return $0.score > $1.score
        }

        if let best = scored.first?.sentence {
            return shortenEvidence(best)
        }

        for keyword in keywords.sorted(by: { $0.count > $1.count }) {
            if let range = passage.range(of: keyword) {
                let start = passage[..<range.lowerBound].lastIndex(of: "。").map { passage.index(after: $0) } ?? passage.startIndex
                let end = passage[range.upperBound...].firstIndex(of: "。") ?? passage.endIndex
                return shortenEvidence(String(passage[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
        return nil
    }

    private func readingFuzzyScore(sentence: String, keywords: [String]) -> Int {
        let sentenceCharacters = Set(sentence.filter { character in
            character.unicodeScalars.contains { scalar in
                let value = Int(scalar.value)
                return (0x3040...0x30FF).contains(value) || (0x4E00...0x9FFF).contains(value)
            }
        })
        guard !sentenceCharacters.isEmpty else { return 0 }

        var used = Set<Character>()
        for keyword in keywords where keyword.count >= 2 {
            for character in keyword where sentenceCharacters.contains(character) {
                used.insert(character)
            }
        }
        return used.count
    }

    private func readingKeywords(from text: String) -> [String] {
        let ignored: Set<String> = [
            "こと", "もの", "ため", "よう", "それ", "これ", "どれ", "どの", "筆者", "考え", "合う",
            "述べ", "いる", "する", "した", "して", "なる", "できる", "できない", "選びなさい"
        ]
        let pattern = #"[一-龯々〆ヵヶぁ-んァ-ヶーA-Za-z0-9]{2,}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let source = text.removingAppMarkers
        let nsRange = NSRange(source.startIndex..<source.endIndex, in: source)
        var seen = Set<String>()
        return regex.matches(in: source, range: nsRange)
            .compactMap { match -> String? in
                guard let range = Range(match.range, in: source) else { return nil }
                let word = String(source[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                guard word.count >= 2, !ignored.contains(word), !seen.contains(word) else { return nil }
                seen.insert(word)
                return word
            }
    }

    private func shortenEvidence(_ text: String) -> String {
        let cleaned = text
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.count > 120 else { return cleaned }
        return String(cleaned.prefix(120)) + "..."
    }

    private func removeGenericReadingPhrases(from text: String) -> String {
        let genericMarkers = [
            "Câu này cần đối chiếu",
            "Câu này hỏi quan điểm",
            "Câu này hỏi nội dung được chỉ tới",
            "Câu này hỏi tác giả mô tả",
            "Câu này hỏi kết luận",
            "Câu này hỏi lý do",
            "Ý đúng nằm ở lựa chọn này",
            "Các lựa chọn còn lại",
            "Các lựa chọn như",
            "thường sai vì",
            "dễ sai vì"
        ]

        return text
            .components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { sentence in
                !genericMarkers.contains { sentence.contains($0) }
            }
            .joined(separator: ". ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension PracticeQuestion {
    var textForSpeech: String {
        ((textHtml ?? text).nonEmpty ?? text).speechCleanedJapanese
    }

    var fullSpeechText: String {
        var parts: [String] = []
        if let passage = passage?.nonEmpty {
            parts.append(passage)
        }
        parts.append((textHtml ?? text).nonEmpty ?? text)
        if !options.isEmpty {
            let optionText = options.enumerated()
                .map { index, option in "\(index + 1)番。\(option)" }
                .joined(separator: "\n")
            parts.append(optionText)
        }
        return parts.joined(separator: "\n\n").speechCleanedJapanese
    }
}

private extension String {
    var speechCleanedJapanese: String {
        var output = removingAppMarkers
        output = output.replacingOccurrences(of: "（　）", with: "、かっこ、")
        output = output.replacingOccurrences(of: "(　)", with: "、かっこ、")
        output = output.replacingOccurrences(of: "( )", with: "、かっこ、")
        output = output.replacingOccurrences(of: "読み方は？", with: "")
        output = output.replacingOccurrences(of: "読み方は?", with: "")
        output = output.replacingOccurrences(of: "意味が近いものは？", with: "")
        output = output.replacingOccurrences(of: "意味が近いものは?", with: "")
        output = output.replacingOccurrences(of: "意味に近いものは？", with: "")
        output = output.replacingOccurrences(of: "意味に近いものは?", with: "")
        output = output.replacingOccurrences(of: "意味が最も近いものは？", with: "")
        output = output.replacingOccurrences(of: "意味が最も近いものは?", with: "")
        output = output.replacingOccurrences(of: "意味に最も近いものは？", with: "")
        output = output.replacingOccurrences(of: "意味に最も近いものは?", with: "")
        output = output.replacingOccurrences(of: "Đáp án", with: "")
        output = output.replacingOccurrences(of: "Dịch đáp án", with: "")
        output = output.replacingOccurrences(of: "Giải thích", with: "")
        output = output.replacingOccurrences(of: "Từ vựng", with: "")
        output = output.replacingOccurrences(of: "Ngữ pháp", with: "")

        let patterns = [
            #"(?m)^\s*[A-Za-zÀ-ỹ][A-Za-zÀ-ỹ0-9 ,.;:!?()/-]*$"#,
            #"\[\d+(?:-[ab])?\]"#,
            #"【\d+(?:-[ab])?】"#
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(output.startIndex..<output.endIndex, in: output)
                output = regex.stringByReplacingMatches(in: output, range: range, withTemplate: " ")
            }
        }

        return output
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}

private struct ReadingPassageCard: View, Equatable {
    let passage: String
    let currentQuestionNumber: Int
    let currentQuestionMarker: String?
    let speechRange: NSRange?
    var onSelectionChange: ((String) -> Void)?
    var onSpeak: (() -> Void)?

    static func == (lhs: ReadingPassageCard, rhs: ReadingPassageCard) -> Bool {
        lhs.passage == rhs.passage
            && lhs.currentQuestionNumber == rhs.currentQuestionNumber
            && lhs.currentQuestionMarker == rhs.currentQuestionMarker
            && lhs.speechRange == rhs.speechRange
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Button {
                onSpeak?()
            } label: {
                Image(systemName: "speaker.wave.2.circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Đọc đoạn văn")

            SelectableAttributedTextView(
                attributedText: attributedPassage(),
                onSelectionChange: onSelectionChange
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.92, green: 0.98, blue: 0.92),
                        Color(red: 0.86, green: 0.94, blue: 0.88)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.green.opacity(0.20), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func attributedPassage() -> NSAttributedString {
        let cacheKey = "\(currentQuestionNumber)-\(currentQuestionMarker ?? "")-\(passage)" as NSString
        if let cached = Self.attributedPassageCache.object(forKey: cacheKey) {
            let highlighted = NSMutableAttributedString(attributedString: cached)
            applySpeechHighlight(to: highlighted, range: speechHighlightRange(in: passage, cleanedRange: speechRange))
            return highlighted
        }

        let output = NSMutableAttributedString(string: passage)
        let fullRange = NSRange(location: 0, length: output.length)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 8
        output.addAttributes([
            .font: PlatformFont.appPreferred(.title3),
            .foregroundColor: PlatformColor.appLabel,
            .paragraphStyle: paragraph
        ], range: fullRange)

        for regex in Self.allQuestionRegexes {
            for match in regex.matches(in: passage, range: fullRange) {
                output.addAttributes([
                    .font: PlatformFont.appBold(ofSize: PlatformFont.appPreferred(.title3).pointSize),
                    .foregroundColor: PlatformColor.appSystemRed,
                    .backgroundColor: PlatformColor.appSystemRed.withAlphaComponent(0.13)
                ], range: match.range)
            }
        }

        for pattern in currentQuestionPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            for match in regex.matches(in: passage, range: fullRange) {
                output.addAttributes([
                    .font: PlatformFont.appBold(ofSize: PlatformFont.appPreferred(.title3).pointSize + 1),
                    .foregroundColor: PlatformColor.appWhite,
                    .backgroundColor: PlatformColor.appSystemRed
                ], range: match.range)
            }
        }

        Self.attributedPassageCache.setObject(output.copy() as! NSAttributedString, forKey: cacheKey)
        let highlighted = NSMutableAttributedString(attributedString: output)
        applySpeechHighlight(to: highlighted, range: speechHighlightRange(in: passage, cleanedRange: speechRange))
        return highlighted
    }

    private var currentQuestionPatterns: [String] {
        let halfWidth = currentQuestionNumber
        let fullWidth = Self.fullWidthNumber(currentQuestionNumber)
        var patterns = [
            "【\\s*\(halfWidth)\\s*(?:-[ab])?\\s*】",
            "【\\s*\(fullWidth)\\s*(?:-[ab])?\\s*】",
            "\\[\\s*\(halfWidth)\\s*(?:-[ab])?\\s*\\]",
            "\\[\\s*\(fullWidth)\\s*(?:-[ab])?\\s*\\]",
            "[\\(（]\\s*\(fullWidth)\\s*(?:-[ab])?\\s*[\\)）]",
            "[\\(（]\\s*\(halfWidth)\\s*(?:-[ab])?\\s*[\\)）]"
        ]
        if let currentQuestionMarker {
            patterns.append(NSRegularExpression.escapedPattern(for: currentQuestionMarker))
        }
        return patterns
    }

    private static let allQuestionRegexes: [NSRegularExpression] = [
        #"【\s*[0-9０-９]+(?:-[ab])?\s*】"#,
        #"\[\s*[0-9０-９]+(?:-[ab])?\s*\]"#,
        #"[\(（]\s*[0-9０-９]+(?:-[ab])?\s*[\)）]"#
    ].compactMap { try? NSRegularExpression(pattern: $0) }

    private static let attributedPassageCache = NSCache<NSString, NSAttributedString>()

    private static func fullWidthNumber(_ number: Int) -> String {
        String(number).map { character in
            switch character {
            case "0": return "０"
            case "1": return "１"
            case "2": return "２"
            case "3": return "３"
            case "4": return "４"
            case "5": return "５"
            case "6": return "６"
            case "7": return "７"
            case "8": return "８"
            case "9": return "９"
            default: return character
            }
        }
        .map(String.init)
        .joined()
    }
}
