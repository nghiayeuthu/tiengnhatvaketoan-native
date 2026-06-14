import SwiftUI

#if canImport(UIKit)
import UIKit

struct SelectableTextView: UIViewRepresentable {
    let text: String
    var font: PlatformFont = .appPreferred(.body)
    var color: PlatformColor = .appLabel
    var isBold: Bool = false
    var onTap: (() -> Void)?
    var onSelectionChange: ((String) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isEditable = false
        view.isSelectable = true
        view.isScrollEnabled = false
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.adjustsFontForContentSizeCategory = true
        view.dataDetectorTypes = []
        view.delegate = context.coordinator
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        context.coordinator.onTap = onTap
        context.coordinator.onSelectionChange = onSelectionChange
        let resolvedFont = isBold ? .appBold(ofSize: font.pointSize) : font
        if context.coordinator.text != text {
            view.text = text
            context.coordinator.text = text
            context.coordinator.cachedSize = nil
            context.coordinator.cachedWidth = nil
        }
        if view.textColor != color {
            view.textColor = color
        }
        if view.font != resolvedFont {
            view.font = resolvedFont
            context.coordinator.cachedSize = nil
            context.coordinator.cachedWidth = nil
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width ?? uiView.bounds.width
        guard width > 0 else { return nil }
        if let cachedWidth = context.coordinator.cachedWidth,
           abs(cachedWidth - width) < 0.5,
           let cachedSize = context.coordinator.cachedSize {
            return cachedSize
        }
        let size = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        let result = CGSize(width: width, height: size.height)
        context.coordinator.cachedWidth = width
        context.coordinator.cachedSize = result
        return result
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var text: String?
        var cachedWidth: CGFloat?
        var cachedSize: CGSize?
        var onTap: (() -> Void)?
        var onSelectionChange: ((String) -> Void)?

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard recognizer.state == .ended else { return }
            if let textView = recognizer.view as? UITextView,
               textView.selectedRange.length > 0 {
                return
            }
            onTap?()
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard textView.selectedRange.length > 0,
                  let range = Range(textView.selectedRange, in: textView.text ?? "") else {
                onSelectionChange?("")
                return
            }
            onSelectionChange?(String((textView.text ?? "")[range]))
        }
    }
}

struct SelectableAttributedTextView: UIViewRepresentable {
    let attributedText: NSAttributedString
    var onSelectionChange: ((String) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isEditable = false
        view.isSelectable = true
        view.isScrollEnabled = false
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.adjustsFontForContentSizeCategory = true
        view.dataDetectorTypes = []
        view.delegate = context.coordinator
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        context.coordinator.onSelectionChange = onSelectionChange
        guard context.coordinator.attributedText !== attributedText,
              context.coordinator.attributedText?.isEqual(to: attributedText) != true else {
            return
        }
        view.attributedText = attributedText
        context.coordinator.attributedText = attributedText
        context.coordinator.cachedSize = nil
        context.coordinator.cachedWidth = nil
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width ?? uiView.bounds.width
        guard width > 0 else { return nil }
        if let cachedWidth = context.coordinator.cachedWidth,
           abs(cachedWidth - width) < 0.5,
           let cachedSize = context.coordinator.cachedSize {
            return cachedSize
        }
        let size = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        let result = CGSize(width: width, height: size.height)
        context.coordinator.cachedWidth = width
        context.coordinator.cachedSize = result
        return result
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var attributedText: NSAttributedString?
        var cachedWidth: CGFloat?
        var cachedSize: CGSize?
        var onSelectionChange: ((String) -> Void)?

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard textView.selectedRange.length > 0,
                  let text = textView.text,
                  let range = Range(textView.selectedRange, in: text) else {
                onSelectionChange?("")
                return
            }
            onSelectionChange?(String(text[range]))
        }
    }
}

#elseif canImport(AppKit)
import AppKit

struct SelectableTextView: NSViewRepresentable {
    let text: String
    var font: PlatformFont = .appPreferred(.body)
    var color: PlatformColor = .appLabel
    var isBold: Bool = false
    var onTap: (() -> Void)?
    var onSelectionChange: ((String) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSTextView {
        let view = NSTextView()
        view.isEditable = false
        view.isSelectable = true
        view.drawsBackground = false
        view.textContainerInset = .zero
        view.textContainer?.lineFragmentPadding = 0
        view.isHorizontallyResizable = false
        view.isVerticallyResizable = true
        view.textContainer?.widthTracksTextView = true
        view.delegate = context.coordinator
        let click = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        view.addGestureRecognizer(click)
        return view
    }

    func updateNSView(_ view: NSTextView, context: Context) {
        context.coordinator.onTap = onTap
        context.coordinator.onSelectionChange = onSelectionChange
        let resolvedFont = isBold ? .appBold(ofSize: font.pointSize) : font
        if context.coordinator.text != text {
            view.string = text
            context.coordinator.text = text
        }
        view.font = resolvedFont
        view.textColor = color
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSTextView, context: Context) -> CGSize? {
        let width = proposal.width ?? nsView.bounds.width
        guard width > 0 else { return nil }
        nsView.textContainer?.containerSize = CGSize(width: width, height: .greatestFiniteMagnitude)
        nsView.layoutManager?.ensureLayout(for: nsView.textContainer!)
        let height = nsView.layoutManager?.usedRect(for: nsView.textContainer!).height ?? 0
        return CGSize(width: width, height: ceil(height))
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var text: String?
        var onTap: (() -> Void)?
        var onSelectionChange: ((String) -> Void)?

        @objc func handleTap() {
            onTap?()
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView,
                  let rangeValue = textView.selectedRanges.first as? NSValue else {
                onSelectionChange?("")
                return
            }
            let range = rangeValue.rangeValue
            guard range.length > 0,
                  let swiftRange = Range(range, in: textView.string) else {
                onSelectionChange?("")
                return
            }
            onSelectionChange?(String(textView.string[swiftRange]))
        }
    }
}

struct SelectableAttributedTextView: NSViewRepresentable {
    let attributedText: NSAttributedString
    var onSelectionChange: ((String) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSTextView {
        let view = NSTextView()
        view.isEditable = false
        view.isSelectable = true
        view.drawsBackground = false
        view.textContainerInset = .zero
        view.textContainer?.lineFragmentPadding = 0
        view.isHorizontallyResizable = false
        view.isVerticallyResizable = true
        view.textContainer?.widthTracksTextView = true
        view.delegate = context.coordinator
        return view
    }

    func updateNSView(_ view: NSTextView, context: Context) {
        context.coordinator.onSelectionChange = onSelectionChange
        view.textStorage?.setAttributedString(attributedText)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSTextView, context: Context) -> CGSize? {
        let width = proposal.width ?? nsView.bounds.width
        guard width > 0 else { return nil }
        nsView.textContainer?.containerSize = CGSize(width: width, height: .greatestFiniteMagnitude)
        nsView.layoutManager?.ensureLayout(for: nsView.textContainer!)
        let height = nsView.layoutManager?.usedRect(for: nsView.textContainer!).height ?? 0
        return CGSize(width: width, height: ceil(height))
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var onSelectionChange: ((String) -> Void)?

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView,
                  let rangeValue = textView.selectedRanges.first as? NSValue else {
                onSelectionChange?("")
                return
            }
            let range = rangeValue.rangeValue
            guard range.length > 0,
                  let swiftRange = Range(range, in: textView.string) else {
                onSelectionChange?("")
                return
            }
            onSelectionChange?(String(textView.string[swiftRange]))
        }
    }
}
#endif
