import SwiftUI

#if canImport(UIKit)
import UIKit

typealias PlatformFont = UIFont
typealias PlatformColor = UIColor

extension UIFont {
    static func appPreferred(_ textStyle: UIFont.TextStyle) -> UIFont {
        UIFont.preferredFont(forTextStyle: textStyle)
    }

    static func appBold(ofSize size: CGFloat) -> UIFont {
        UIFont.systemFont(ofSize: size, weight: .bold)
    }
}

extension UIColor {
    static var appLabel: UIColor { .label }
    static var appSystemOrange: UIColor { .systemOrange }
    static var appSystemRed: UIColor { .systemRed }
    static var appWhite: UIColor { .white }
}
#elseif canImport(AppKit)
import AppKit

typealias PlatformFont = NSFont
typealias PlatformColor = NSColor

extension NSFont {
    static func appPreferred(_ textStyle: Font.TextStyle) -> NSFont {
        switch textStyle {
        case .largeTitle: return NSFont.preferredFont(forTextStyle: .largeTitle)
        case .title: return NSFont.preferredFont(forTextStyle: .title1)
        case .title2: return NSFont.preferredFont(forTextStyle: .title2)
        case .title3: return NSFont.preferredFont(forTextStyle: .title3)
        case .headline: return NSFont.preferredFont(forTextStyle: .headline)
        case .subheadline: return NSFont.preferredFont(forTextStyle: .subheadline)
        case .callout: return NSFont.preferredFont(forTextStyle: .callout)
        case .caption: return NSFont.preferredFont(forTextStyle: .caption1)
        case .caption2: return NSFont.preferredFont(forTextStyle: .caption2)
        case .footnote: return NSFont.preferredFont(forTextStyle: .footnote)
        default: return NSFont.preferredFont(forTextStyle: .body)
        }
    }

    static func appBold(ofSize size: CGFloat) -> NSFont {
        NSFont.systemFont(ofSize: size, weight: .bold)
    }

}

extension NSColor {
    static var appLabel: NSColor { .labelColor }
    static var appSystemOrange: NSColor { .systemOrange }
    static var appSystemRed: NSColor { .systemRed }
    static var appWhite: NSColor { .white }
}
#endif

extension View {
    @ViewBuilder
    func disableAutocapitalizationIfAvailable() -> some View {
        #if canImport(UIKit)
        self.textInputAutocapitalization(.never)
        #else
        self
        #endif
    }
}
