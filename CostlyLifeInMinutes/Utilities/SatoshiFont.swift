import SwiftUI
import CoreText

enum SatoshiFont {
    static let light = "Satoshi-Light"
    static let regular = "Satoshi-Regular"
    static let medium = "Satoshi-Medium"
    static let bold = "Satoshi-Bold"
    static let black = "Satoshi-Black"

    static func registerFonts() {
        let fontNames = [
            "Satoshi-Light",
            "Satoshi-Regular",
            "Satoshi-Medium",
            "Satoshi-Bold",
            "Satoshi-Black"
        ]
        for name in fontNames {
            guard let url = Bundle.main.url(forResource: name, withExtension: "otf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

extension Font {
    static func satoshi(_ weight: SatoshiWeight, size: CGFloat) -> Font {
        .custom(weight.fontName, size: size)
    }

    static func satoshiFixed(_ weight: SatoshiWeight, size: CGFloat) -> Font {
        .custom(weight.fontName, fixedSize: size)
    }
}

enum SatoshiWeight {
    case light
    case regular
    case medium
    case bold
    case black

    var fontName: String {
        switch self {
        case .light: return SatoshiFont.light
        case .regular: return SatoshiFont.regular
        case .medium: return SatoshiFont.medium
        case .bold: return SatoshiFont.bold
        case .black: return SatoshiFont.black
        }
    }
}
