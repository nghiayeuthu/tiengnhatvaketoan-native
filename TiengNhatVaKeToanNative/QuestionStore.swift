import Foundation
import SwiftUI

@MainActor
final class QuestionStore: ObservableObject {
    @Published private(set) var exams: [ExamDocument] = []
    @Published private(set) var questionsByExam: [String: [PracticeQuestion]] = [:]
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

        for url in urls.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
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
    }

    private func flatten(_ exam: ExamDocument) -> [PracticeQuestion] {
        var result: [PracticeQuestion] = []
        var runningIndex = 1

        for section in exam.sections {
            for group in section.groups {
                for raw in group.questions {
                    let number = raw.questionNumber ?? raw.id ?? runningIndex
                    let textHtml = raw.textHtml?.nonEmpty ?? raw.prompt?.nonEmpty ?? raw.question?.nonEmpty
                    let text = (textHtml ?? raw.text?.nonEmpty ?? raw.question?.nonEmpty ?? raw.prompt?.nonEmpty ?? "")
                        .removingAppMarkers
                    let passage = raw.passage ?? group.passage

                    result.append(
                        PracticeQuestion(
                            id: "\(exam.id)-\(section.type)-\(number)-\(runningIndex)",
                            examID: exam.id,
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
                            answerText: raw.answerText
                        )
                    )
                    runningIndex += 1
                }
            }
        }

        return result
    }
}
