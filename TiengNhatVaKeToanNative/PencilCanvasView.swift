import PencilKit
import SwiftUI

enum PencilToolMode {
    case pen
    case eraser
}

struct PencilCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let toolMode: PencilToolMode

    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawing = drawing
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = .anyInput
        canvas.minimumZoomScale = 1
        canvas.maximumZoomScale = 1
        canvas.alwaysBounceVertical = false
        canvas.alwaysBounceHorizontal = false
        applyTool(to: canvas)
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        if canvas.drawing != drawing {
            canvas.drawing = drawing
        }
        applyTool(to: canvas)
    }

    private func applyTool(to canvas: PKCanvasView) {
        switch toolMode {
        case .pen:
            canvas.tool = PKInkingTool(.pen, color: .black, width: 5)
        case .eraser:
            canvas.tool = PKEraserTool(.bitmap)
        }
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawing: PKDrawing

        init(drawing: Binding<PKDrawing>) {
            _drawing = drawing
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            drawing = canvasView.drawing
        }
    }
}

struct ScratchPadView: View {
    @Binding var drawing: PKDrawing
    @Environment(\.dismiss) private var dismiss
    @State private var toolMode: PencilToolMode = .pen

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("Nháp Apple Pencil")
                    .font(.headline)
                    .foregroundStyle(.green)
                Spacer()
                Button("Bút") { toolMode = .pen }
                    .buttonStyle(.borderedProminent)
                    .tint(toolMode == .pen ? .green : .gray)
                Button("Tẩy lớn") { toolMode = .eraser }
                    .buttonStyle(.bordered)
                Button("Xóa") { drawing = PKDrawing() }
                    .buttonStyle(.bordered)
                Button("Đóng") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
            }
            .padding()
            .background(.regularMaterial)

            PencilCanvasView(drawing: $drawing, toolMode: toolMode)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.green.opacity(0.25), style: StrokeStyle(lineWidth: 2, dash: [8]))
                )
                .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
