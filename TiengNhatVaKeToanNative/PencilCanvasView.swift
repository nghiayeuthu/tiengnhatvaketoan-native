import PencilKit
import SwiftUI

#if canImport(UIKit)
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
                guard canvas.window != nil else {
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
#endif

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

            #if canImport(UIKit)
            PencilCanvasView(drawing: $drawing)
                .background(Color(red: 1.0, green: 0.96, blue: 0.86))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.green.opacity(0.25), style: StrokeStyle(lineWidth: 2, dash: [8]))
                )
                .padding()
            #else
            ContentUnavailableView(
                "Nháp Apple Pencil",
                systemImage: "pencil.tip.crop.circle",
                description: Text("Phần viết tay chỉ dùng trên iPad. Trên iPhone và Mac có thể luyện đề và xem đáp án bình thường.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            #endif
        }
        .background(Color(red: 0.95, green: 0.96, blue: 0.94))
    }
}
