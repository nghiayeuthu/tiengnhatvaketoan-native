import Foundation
import SwiftUI

@MainActor
final class QuestionStore: ObservableObject {
    @Published private(set) var exams: [ExamDocument] = []
    @Published private(set) var questionsByExam: [String: [PracticeQuestion]] = [:]
    @Published private(set) var allQuestions: [PracticeQuestion] = []
    @Published private(set) var loadError: String?

    init() {
        load()
    }

    func questions(for examID: String?) -> [PracticeQuestion] {
        guard let examID else { return [] }
        return questionsByExam[examID] ?? []
    }

    private func load() {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "ExamData") else {
            loadError = "Không tìm thấy dữ liệu đề trong app."
            return
        }

        var loadedExams: [ExamDocument] = []
        var loadedQuestions: [String: [PracticeQuestion]] = [:]
        let decoder = JSONDecoder()

        let examURLs = urls
            .filter { $0.lastPathComponent.hasPrefix("exam-") }
            .sorted(by: { $0.lastPathComponent < $1.lastPathComponent })

        for url in examURLs {
            do {
                let data = try Data(contentsOf: url)
                let exam = try decoder.decode(ExamDocument.self, from: data)
                loadedExams.append(exam)
                loadedQuestions[exam.id] = flatten(exam)
            } catch {
                loadError = "Lỗi đọc \(url.lastPathComponent): \(error.localizedDescription)"
            }
        }

        exams = loadedExams.sorted {
            if $0.year == $1.year { return $0.month > $1.month }
            return $0.year > $1.year
        }
        questionsByExam = loadedQuestions
        allQuestions = exams.flatMap { loadedQuestions[$0.id] ?? [] }
    }

    private func flatten(_ exam: ExamDocument) -> [PracticeQuestion] {
        var result: [PracticeQuestion] = []
        var runningIndex = 1

        for section in exam.sections {
            for group in section.groups {
                var inheritedPassage = group.passage
                for raw in group.questions {
                    let number = raw.questionNumber ?? raw.id ?? runningIndex
                    let sourceTextHtml = raw.textHtml?.nonEmpty ?? raw.text?.nonEmpty ?? raw.prompt?.nonEmpty ?? raw.question?.nonEmpty
                    let textHtml = normalizeQuestionText(
                        sourceTextHtml,
                        section: section,
                        instruction: group.instruction
                    )
                    let text = (textHtml ?? "")
                        .removingAppMarkers
                    let explicitPassage = raw.passage ?? group.passage
                    if let explicitPassage {
                        inheritedPassage = explicitPassage
                    }
                    let passage = explicitPassage ?? (shouldInheritPassage(
                        section: section,
                        instruction: group.instruction,
                        questionNumber: number,
                        text: text
                    ) ? inheritedPassage : nil)

                    result.append(
                        PracticeQuestion(
                            id: "\(exam.id)-\(section.type)-\(number)-\(runningIndex)",
                            examID: exam.id,
                            examLevel: exam.normalizedLevel,
                            examTitle: exam.title,
                            sectionTitle: section.title,
                            instruction: group.instruction,
                            number: number,
                            text: text,
                            textHtml: textHtml,
                            passage: passage,
                            options: raw.options,
                            correctAnswer: raw.correctAnswer,
                            explanation: raw.explanation,
                            correctOrder: raw.correctOrder,
                            starOrder: raw.starOrder,
                            answerText: raw.answerText
                        )
                    )
                    runningIndex += 1
                }
            }
        }

        return result
    }

    private func shouldInheritPassage(section: ExamSection, instruction: String?, questionNumber: Int, text: String) -> Bool {
        guard section.type == "grammar" else { return false }
        let instruction = instruction ?? ""
        if instruction.contains("問題9")
            || instruction.contains("文章")
            || instruction.contains("文を読んで")
            || instruction.localizedCaseInsensitiveContains("đoạn văn") {
            return true
        }
        if text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("【") {
            return true
        }
        if instruction.localizedCaseInsensitiveContains("ngữ pháp") {
            return (48...54).contains(questionNumber) || (41...45).contains(questionNumber)
        }
        return false
    }

    private func normalizeQuestionText(_ text: String?, section: ExamSection, instruction: String?) -> String? {
        guard var output = text else { return nil }
        output = output
            .replacingOccurrences(of: "[[blank]]", with: "（　）")
            .replacingOccurrences(of: "[[/blank]]", with: "")

        let instruction = instruction ?? ""
        let isFillQuestion = instruction.contains("入れ")
            || instruction.contains("（")
            || instruction.contains("( )")
            || instruction.localizedCaseInsensitiveContains("điền")

        if isFillQuestion && !hasVisibleBlank(output) {
            let blankCharacters = ["\u{00A0}", "\u{2007}", "\u{202F}"]
            for blank in blankCharacters where output.contains(blank) {
                output = output.replacingOccurrences(of: blank, with: "（　）")
                return output
            }
        }

        guard section.type == "grammar" else { return output }
        let isFillGrammar = instruction.contains("問題7") || instruction.contains("入れる") || instruction.localizedCaseInsensitiveContains("ngữ pháp")
        let isStarGrammar = instruction.contains("問題8") || instruction.contains("★") || output.contains("★") || output.contains("_★_")
        let isPassageGrammar = instruction.contains("問題9") || instruction.contains("文章") || instruction.contains("文を読んで")
        guard isFillGrammar && !isStarGrammar && !isPassageGrammar else { return output }
        guard !hasVisibleBlank(output) else { return output }

        let blankCharacters = ["\u{00A0}", "\u{2007}", "\u{202F}"]
        for blank in blankCharacters where output.contains(blank) {
            output = output.replacingOccurrences(of: blank, with: "（　）")
            return output
        }

        if let range = output.range(
            of: #"[ \t　]+\)"#,
            options: .regularExpression
        ) {
            output.replaceSubrange(range, with: "（　）")
            return output
        }

        if let range = output.range(
            of: #"[ \t　]{2,}"#,
            options: .regularExpression
        ) {
            output.replaceSubrange(range, with: "（　）")
            return output
        }

        return output + "（　）"
    }

    private func hasVisibleBlank(_ text: String) -> Bool {
        text.contains("（　）")
            || text.contains("（ ）")
            || text.contains("(　)")
            || text.contains("( )")
            || text.contains("（）")
            || text.contains("()")
    }
}
