import Foundation

struct ExamDocument: Decodable, Identifiable {
    let level: String?
    let date: String
    let year: Int
    let month: Int
    let sections: [ExamSection]

    var id: String { date }
    var title: String { "\(year) tháng \(month)" }
}

struct ExamSection: Decodable {
    let type: String
    let sectionNumber: Int?
    let groups: [QuestionGroup]

    var title: String {
        switch type {
        case "vocabulary": return "Từ vựng"
        case "grammar": return "Ngữ pháp"
        case "reading": return "Đọc hiểu"
        default: return type
        }
    }
}

struct QuestionGroup: Decodable {
    let instruction: String?
    let passage: String?
    let questions: [RawQuestion]
}

struct RawQuestion: Decodable {
    let id: Int?
    let questionNumber: Int?
    let text: String?
    let textHtml: String?
    let question: String?
    let prompt: String?
    let passage: String?
    let options: [String]
    let correctAnswer: Int?
    let explanation: String?
    let correctOrder: [String]?
    let starOrder: String?
    let answerText: String?
}

struct PracticeQuestion: Identifiable {
    let id: String
    let examID: String
    let examTitle: String
    let sectionTitle: String
    let instruction: String?
    let number: Int
    let text: String
    let textHtml: String?
    let passage: String?
    let options: [String]
    let correctAnswer: Int?
    let explanation: String?
    let correctOrder: [String]?
    let starOrder: String?
    let answerText: String?
}

extension String {
    var removingAppMarkers: String {
        replacingOccurrences(of: "[[u]]", with: "")
            .replacingOccurrences(of: "[[/u]]", with: "")
            .replacingOccurrences(of: "[[blank]]", with: "（　）")
            .replacingOccurrences(of: "[[/blank]]", with: "")
    }

    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
