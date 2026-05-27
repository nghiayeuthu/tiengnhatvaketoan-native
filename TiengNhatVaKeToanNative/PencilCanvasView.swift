import PencilKit
import SwiftUI

struct PencilCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing

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
        canvas.tool = PKInkingTool(.pen, color: .black, width: 5)
        context.coordinator.showToolPicker(for: canvas)
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        if canvas.drawing != drawing {
            canvas.drawing = drawing
        }
        context.coordinator.showToolPicker(for: canvas)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawing: PKDrawing
        private var toolPicker: PKToolPicker?

        init(drawing: Binding<PKDrawing>) {
            _drawing = drawing
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            drawing = canvasView.drawing
        }

        func showToolPicker(for canvas: PKCanvasView) {
            DispatchQueue.main.async {
                guard let window = canvas.window else {
                    canvas.becomeFirstResponder()
                    return
                }

                let picker = PKToolPicker()
                picker.addObserver(canvas)
                picker.setVisible(true, forFirstResponder: canvas)
                canvas.becomeFirstResponder()
                self.toolPicker = picker
            }
        }
    }
}

struct ScratchPadView: View {
    @Binding var drawing: PKDrawing
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("Nháp Apple Pencil")
                    .font(.headline)
                    .foregroundStyle(.green)
                Spacer()
                Button("Xóa") { drawing = PKDrawing() }
                    .buttonStyle(.bordered)
                Button("Đóng") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
            }
            .padding()
            .background(.regularMaterial)

            PencilCanvasView(drawing: $drawing)
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
