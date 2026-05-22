import PencilKit
import SwiftUI

struct ContentView: View {
    @StateObject private var store = QuestionStore()
    @StateObject private var dictionary = StudyDictionaryStore()
    @State private var selectedExamID: String?
    @State private var selectedQuestionIndex = 0
    @State private var selectedAnswer: Int?
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
            List {
                Section("Luyện đề N1") {
                    ForEach(store.exams) { exam in
                        examRow(exam)
                    }
                }
            }
            .navigationTitle("TiengNhatVaKeToan")
            .onAppear {
                if selectedExamID == nil {
                    selectedExamID = store.exams.first?.id
                }
            }
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
    }

    @ViewBuilder
    private var questionDetail: some View {
        if let error = store.loadError {
            ContentUnavailableView("Lỗi dữ liệu", systemImage: "exclamationmark.triangle", description: Text(error))
        } else if let question = currentQuestion {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header(for: question)
                    if let passage = question.passage?.nonEmpty {
                        Text(passage)
                            .font(.title3)
                            .lineSpacing(8)
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
        Text(attributedQuestion(question))
            .font(.system(size: 30, weight: .bold))
            .lineSpacing(8)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func options(for question: PracticeQuestion) -> some View {
        VStack(spacing: 14) {
            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                Button {
                    selectedAnswer = index
                } label: {
                    HStack {
                        Text(option)
                            .font(.title3)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(optionBackground(index: index, question: question))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(optionBorder(index: index, question: question), lineWidth: 1.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func explanation(for question: PracticeQuestion) -> some View {
        if selectedAnswer != nil {
            let vocabNotes = dictionary.vocabularyMatches(for: question)
            let grammarNotes = dictionary.grammarMatches(for: question)

            VStack(alignment: .leading, spacing: 12) {
                if let correct = question.correctAnswer, question.options.indices.contains(correct - 1) {
                    Text("Đáp án: \(correct). \(question.options[correct - 1])")
                        .font(.headline)
                }
                if let answerText = question.answerText?.nonEmpty {
                    Text(answerText)
                }
                if let order = question.correctOrder, !order.isEmpty {
                    Text("正しい順序: \(order.joined(separator: " → "))")
                }
                if let explanation = conciseExplanation(question.explanation) {
                    Label("Giải thích", systemImage: "lightbulb")
                        .font(.headline)
                        .foregroundStyle(.orange)
                    Text(explanation)
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
                Text("• \(line)")
                    .font(.callout)
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

    private func attributedQuestion(_ question: PracticeQuestion) -> AttributedString {
        let source = question.textHtml ?? question.text
        var output = AttributedString()
        var remainder = source

        while let start = remainder.range(of: "[[u]]") {
            let before = String(remainder[..<start.lowerBound])
            output.append(AttributedString(before.replacingOccurrences(of: "[[blank]]", with: "（　）").replacingOccurrences(of: "[[/blank]]", with: "")))
            remainder = String(remainder[start.upperBound...])

            guard let end = remainder.range(of: "[[/u]]") else { break }
            var marked = AttributedString(String(remainder[..<end.lowerBound]))
            marked.underlineStyle = .single
            marked.foregroundColor = .orange
            output.append(marked)
            remainder = String(remainder[end.upperBound...])
        }

        output.append(AttributedString(remainder.removingAppMarkers))
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
        let cleaned = raw
            .components(separatedBy: .newlines)
            .map { line in
                var value = line.trimmingCharacters(in: .whitespacesAndNewlines)
                for prefix in blockedPrefixes where value.hasPrefix(prefix) {
                    value = ""
                }
                if value.hasPrefix("Đáp án:") {
                    value = value.replacingOccurrences(of: #"^Đáp án:\s*\d+\.?\s*"#, with: "", options: .regularExpression)
                }
                return value
            }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else { return nil }
        if cleaned.count <= 180 { return cleaned }

        let separators = CharacterSet(charactersIn: "。.!?")
        let sentences = cleaned.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let short = sentences.prefix(2).joined(separator: "。")
        return short.isEmpty ? String(cleaned.prefix(180)) + "..." : short + "。"
    }
}
