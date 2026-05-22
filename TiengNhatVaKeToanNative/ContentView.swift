import PencilKit
import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var store = QuestionStore()
    @StateObject private var dictionary = StudyDictionaryStore()
    @State private var selectedExamID: String?
    @State private var selectedQuestionIndex = 0
    @State private var selectedAnswer: Int?
    @State private var showsQuestionPicker = false
    @State private var scratchDrawing = PKDrawing()
    @State private var showsScratchPad = false

    var selectedQuestions: [PracticeQuestion] {
        store.questions(for: selectedExamID)
    }

    var currentQuestion: PracticeQuestion? {
        guard selectedQuestions.indices.contains(selectedQuestionIndex) else { return nil }
        return selectedQuestions[selectedQuestionIndex]
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            ZStack(alignment: .bottom) {
                questionDetail
                bottomBar
            }
            .sheet(isPresented: $showsScratchPad) {
                ScratchPadView(drawing: $scratchDrawing)
            }
        }
    }

    @ViewBuilder
    private var sidebar: some View {
        if showsQuestionPicker, let selectedExamID, let exam = store.exams.first(where: { $0.id == selectedExamID }) {
            questionPicker(for: exam)
        } else {
            examList
        }
    }

    private var examList: some View {
        List {
            Section("Luyện đề N1") {
                ForEach(store.exams) { exam in
                    examRow(exam)
                }
            }
        }
        .navigationTitle("Thư mục đề")
    }

    private func questionPicker(for exam: ExamDocument) -> some View {
        let questions = store.questions(for: exam.id)
        let columns = [
            GridItem(.adaptive(minimum: 48, maximum: 64), spacing: 10)
        ]

        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Button {
                    showsQuestionPicker = false
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.headline)
                }
                .buttonStyle(.bordered)
                .tint(.green)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Chọn câu")
                        .font(.title2.bold())
                    Text("\(exam.title) • \(questions.count) câu")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                    ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                        questionNumberButton(index: index, question: question)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Chọn câu")
    }

    private func questionNumberButton(index: Int, question: PracticeQuestion) -> some View {
        Button {
            selectedQuestionIndex = index
            selectedAnswer = nil
        } label: {
            Text("\(index + 1)")
                .font(.headline)
                .frame(width: 48, height: 44)
                .background(selectedQuestionIndex == index ? Color.green : Color(.secondarySystemGroupedBackground))
                .foregroundStyle(selectedQuestionIndex == index ? .white : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(questionButtonBorder(for: question, isSelected: selectedQuestionIndex == index), lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Câu \(question.number)")
    }

    private func questionButtonBorder(for question: PracticeQuestion, isSelected: Bool) -> Color {
        if isSelected { return .green }
        switch question.sectionTitle {
        case "Từ vựng": return .orange.opacity(0.45)
        case "Ngữ pháp": return .blue.opacity(0.45)
        case "Đọc hiểu": return .purple.opacity(0.45)
        default: return .gray.opacity(0.3)
        }
    }

    private func examRow(_ exam: ExamDocument) -> some View {
        let count = store.questions(for: exam.id).count
        let isSelected = selectedExamID == exam.id

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(exam.title)
                    .font(.headline)
                    .foregroundStyle(isSelected ? .white : .primary)
                Text("\(count) câu")
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
        .background(isSelected ? Color.green : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .onTapGesture {
            selectExam(exam.id)
        }
        .accessibilityAddTraits(.isButton)
    }

    private func selectExam(_ examID: String) {
        selectedExamID = examID
        selectedQuestionIndex = 0
        selectedAnswer = nil
        showsQuestionPicker = true
    }

    @ViewBuilder
    private var questionDetail: some View {
        if let error = store.loadError {
            ContentUnavailableView("Lỗi dữ liệu", systemImage: "exclamationmark.triangle", description: Text(error))
        } else if selectedExamID == nil {
            ContentUnavailableView("Chọn thư mục đề", systemImage: "book.closed", description: Text("Chọn một đề ở bên trái để bắt đầu luyện."))
        } else if let question = currentQuestion {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header(for: question)
                    if let passage = question.passage?.nonEmpty {
                        SelectableTextView(
                            text: passage,
                            font: .preferredFont(forTextStyle: .title3)
                        )
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.green.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    questionText(question)
                    options(for: question)
                    explanation(for: question)
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .padding(.bottom, 120)
                .frame(maxWidth: 980, alignment: .leading)
                .textSelection(.enabled)
            }
            .background(Color(.systemGroupedBackground))
        } else {
            ContentUnavailableView("Chọn thư mục đề", systemImage: "book.closed", description: Text("Chọn một đề ở bên trái để bắt đầu luyện."))
        }
    }

    private func header(for question: PracticeQuestion) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(question.examTitle) - \(question.sectionTitle)")
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

    private func questionText(_ question: PracticeQuestion) -> some View {
        SelectableAttributedTextView(attributedText: attributedQuestion(question))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func options(for question: PracticeQuestion) -> some View {
        VStack(spacing: 14) {
            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                HStack {
                    SelectableTextView(
                        text: option,
                        font: .preferredFont(forTextStyle: .title3)
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Button {
                        selectedAnswer = index
                    } label: {
                        Image(systemName: selectedAnswer == index ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(selectedAnswer == index ? .green : .secondary)
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
            let vocabNotes = dictionary.vocabularyMatches(for: question)
            let grammarNotes = question.sectionTitle == "Ngữ pháp" ? dictionary.grammarMatches(for: question) : []
            let explanationText = conciseExplanation(question.explanation) ?? fallbackExplanation(for: question, vocabNotes: vocabNotes, grammarNotes: grammarNotes)
            let starOrderText = starOrderText(for: question)

            VStack(alignment: .leading, spacing: 12) {
                if let correct = question.correctAnswer, question.options.indices.contains(correct - 1) {
                    SelectableTextView(
                        text: "Đáp án: \(correct). \(question.options[correct - 1])",
                        font: .preferredFont(forTextStyle: .headline),
                        isBold: true
                    )
                }
                if let answerText = question.answerText?.nonEmpty {
                    SelectableTextView(text: answerText)
                }
                if let order = question.correctOrder, !order.isEmpty {
                    SelectableTextView(text: "正しい順序: \(order.joined(separator: " → "))")
                }
                if let starOrderText {
                    SelectableTextView(
                        text: "正しい順序: \(starOrderText)",
                        font: .preferredFont(forTextStyle: .headline),
                        isBold: true
                    )
                }
                if let explanation = explanationText {
                    Label("Giải thích", systemImage: "lightbulb")
                        .font(.headline)
                        .foregroundStyle(.orange)
                    SelectableTextView(text: explanation)
                }
                if !grammarNotes.isEmpty {
                    noteSection(title: "Ngữ pháp", systemImage: "text.book.closed", lines: grammarNotes.map { "\($0.pattern) = \($0.meaning)" })
                }
                if !vocabNotes.isEmpty {
                    noteSection(title: "Từ vựng / cách đọc", systemImage: "character.book.closed", lines: vocabNotes.map(dictionary.note(for:)))
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
                    font: .preferredFont(forTextStyle: .callout)
                )
            }
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                moveQuestion(-1)
            } label: {
                Label("Câu trước", systemImage: "chevron.left")
            }
            .disabled(selectedQuestionIndex == 0)

            Button {
                showsScratchPad = true
            } label: {
                Label("Nháp", systemImage: "pencil.tip.crop.circle")
            }

            Button {
                moveQuestion(1)
            } label: {
                Label("Câu tiếp", systemImage: "chevron.right")
            }
            .disabled(selectedQuestionIndex >= max(selectedQuestions.count - 1, 0))
        }
        .font(.headline)
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(radius: 16)
        .padding(.bottom, 18)
    }

    private func moveQuestion(_ delta: Int) {
        let next = selectedQuestionIndex + delta
        guard selectedQuestions.indices.contains(next) else { return }
        selectedQuestionIndex = next
        selectedAnswer = nil
    }

    private func optionBackground(index: Int, question: PracticeQuestion) -> Color {
        guard let selectedAnswer else { return Color(.secondarySystemGroupedBackground) }
        if let correct = question.correctAnswer, index == correct - 1 {
            return Color.green.opacity(0.16)
        }
        if selectedAnswer == index {
            return Color.red.opacity(0.10)
        }
        return Color(.secondarySystemGroupedBackground)
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

    private func attributedQuestion(_ question: PracticeQuestion) -> NSAttributedString {
        let source = question.textHtml ?? question.text
        let output = NSMutableAttributedString()
        var remainder = source
        let baseFont = UIFont.boldSystemFont(ofSize: 30)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 8
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: baseFont,
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraph
        ]

        while let start = remainder.range(of: "[[u]]") {
            let before = String(remainder[..<start.lowerBound])
            output.append(NSAttributedString(
                string: before.replacingOccurrences(of: "[[blank]]", with: "（　）").replacingOccurrences(of: "[[/blank]]", with: ""),
                attributes: baseAttributes
            ))
            remainder = String(remainder[start.upperBound...])

            guard let end = remainder.range(of: "[[/u]]") else { break }
            output.append(NSAttributedString(
                string: String(remainder[..<end.lowerBound]),
                attributes: baseAttributes.merging([
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .foregroundColor: UIColor.systemOrange
                ]) { _, new in new }
            ))
            remainder = String(remainder[end.upperBound...])
        }

        output.append(NSAttributedString(string: remainder.removingAppMarkers, attributes: baseAttributes))
        return output
    }

    private func conciseExplanation(_ raw: String?) -> String? {
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
        if cleaned.count <= 180 { return cleaned }

        let separators = CharacterSet(charactersIn: "。.!?")
        let sentences = cleaned.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let short = sentences.prefix(2).joined(separator: "。")
        return short.isEmpty ? String(cleaned.prefix(180)) + "..." : short + "。"
    }

    private func starOrderText(for question: PracticeQuestion) -> String? {
        if let starOrder = question.starOrder?.nonEmpty {
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
                return "Chọn 「\(answer)」 vì mẫu 「\(grammar.pattern)」 nghĩa là \(grammar.meaning), hợp với quan hệ ý trong câu."
            }
            return nil
        case "Đọc hiểu":
            return nil
        case "Từ vựng":
            return nil
        default:
            return "Chọn 「\(answer)」."
        }
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
