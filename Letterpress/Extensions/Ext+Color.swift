//
//  Ext+Color.swift
//  ColorfulApp
//
//  Created by 秋星桥 on 2024/8/13.
//

import SwiftUI
import UIKit

// MARK: - Apple-provided colors
extension Color {
    // MARK: - UI Element Colors (https://developer.apple.com/documentation/uikit/uicolor/ui_element_colors)
    // MARK: Label Colors
    /// The color for text labels that contain primary content.
    static var label: Color {
        return Color(UIColor.label)
    }

    /// The color for text labels that contain secondary content.
    static var secondaryLabel: Color {
        return Color(UIColor.secondaryLabel)
    }

    /// The color for text labels that contain tertiary content.
    static var tertiaryLabel: Color {
        return Color(UIColor.tertiaryLabel)
    }

    /// The color for text labels that contain quaternary content.
    static var quaternaryLabel: Color {
        return Color(UIColor.quaternaryLabel)
    }

    // MARK: Fill Colors
    /// An overlay fill color for thin and small shapes.
    static var systemFill: Color {
        return Color(UIColor.systemFill)
    }

    /// An overlay fill color for medium-size shapes.
    static var secondarySystemFill: Color {
        return Color(UIColor.secondarySystemFill)
    }

    /// An overlay fill color for large shapes.
    static var tertiarySystemFill: Color {
        return Color(UIColor.tertiarySystemFill)
    }

    /// An overlay fill color for large areas that contain complex content.
    static var quaternarySystemFill: Color {
        return Color(UIColor.quaternarySystemFill)
    }

    // MARK: Text Colors
    /// The color for placeholder text in controls or text views.
    static var placeholderText: Color {
        return Color(UIColor.placeholderText)
    }

    // MARK: Standard Content Background Colors
    /// The color for the main background of your interface.
    static var systemBackground: Color {
        return Color(UIColor.systemBackground)
    }

    /// The color for content layered on top of the main background.
    static var secondarySystemBackground: Color {
        return Color(UIColor.secondarySystemBackground)
    }

    /// The color for content layered on top of secondary backgrounds.
    static var tertiarySystemBackground: Color {
        return Color(UIColor.tertiarySystemBackground)
    }

    // MARK: Grouped Content Background Colors
    /// The color for the main background of your grouped interface.
    static var systemGroupedBackground: Color {
        return Color(UIColor.systemGroupedBackground)
    }

    /// The color for content layered on top of the main background of your grouped interface.
    static var secondarySystemGroupedBackground: Color {
        return Color(UIColor.secondarySystemGroupedBackground)
    }

    /// The color for content layered on top of secondary backgrounds of your grouped interface.
    static var tertiarySystemGroupedBackground: Color {
        return Color(UIColor.tertiarySystemGroupedBackground)
    }

    // MARK: Separator Colors
    /// The color for thin borders or divider lines that allows some underlying content to be visible.
    static var separator: Color {
        return Color(UIColor.separator)
    }

    /// The color for borders or divider lines that hides any underlying content.
    static var opaqueSeparator: Color {
        return Color(UIColor.opaqueSeparator)
    }

    // MARK: Link Color
    /// The color for links.
    static var link: Color {
        return Color(UIColor.link)
    }

    // MARK: - Standard Colors (https://developer.apple.com/documentation/uikit/uicolor/standard_colors)
    // MARK: Adaptable Colors
    static var systemBlue: Color {
        return Color(UIColor.systemBlue)
    }

    static var systemGreen: Color {
        return Color(UIColor.systemGreen)
    }

    static var systemIndigo: Color {
        return Color(UIColor.systemIndigo)
    }

    static var systemOrange: Color {
        return Color(UIColor.systemOrange)
    }

    static var systemPink: Color {
        return Color(UIColor.systemPink)
    }

    static var systemPurple: Color {
        return Color(UIColor.systemPurple)
    }

    static var systemRed: Color {
        return Color(UIColor.systemRed)
    }

    static var systemTeal: Color {
        return Color(UIColor.systemTeal)
    }

    static var systemYellow: Color {
        return Color(UIColor.systemYellow)
    }

    // MARK: Adaptable Gray Colors
    static var systemGray: Color {
        return Color(UIColor.systemGray)
    }

    static var systemGray2: Color {
        return Color(UIColor.systemGray2)
    }

    static var systemGray3: Color {
        return Color(UIColor.systemGray3)
    }

    static var systemGray4: Color {
        return Color(UIColor.systemGray4)
    }

    static var systemGray5: Color {
        return Color(UIColor.systemGray5)
    }

    static var systemGray6: Color {
        return Color(UIColor.systemGray6)
    }
}

// MARK: - Color Spaces
extension Color {
    typealias NativeColor = UIColor

    /// A list of changeable attributes of the Color.
    enum ChangeableAttribute {
        /// The red color part of RGB.
        case red
        /// The green color part of RGB.
        case green
        /// The blue color part of RGB.
        case blue
        /// The hue color part of HSB.
        case hueHSB
        /// The saturation color part of HSB.
        case saturation
        /// The brightness color part of HSB.
        case brightness
        /// The hue color part of HLC.
        case hueHLC
        /// The luminance color part of HLC.
        case luminance
        /// The chroma color part of HLC.
        case chroma
        /// The opacity color part of RGB / HSB / HLC.
        case opacity
    }

    // MARK: - Computed Properties
    /// The HSB & alpha attributes of the `Color` instance.
    var hsbo: (hue: Double, saturation: Double, brightness: Double, opacity: Double) {
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, opacity: CGFloat = 0
        let color = NativeColor(self)

        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &opacity)

        return (hue: Double(hue), saturation: Double(saturation), brightness: Double(brightness), opacity: Double(opacity))
    }

    /// The RGB & alpha attributes of the `Color` instance.
    var rgbo: (red: Double, green: Double, blue: Double, opacity: Double) {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, opacity: CGFloat = 0

        let color = NativeColor(self)
        color.getRed(&red, green: &green, blue: &blue, alpha: &opacity)

        return (red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(opacity))
    }

    /// The HLC & alpha attributes of the `Color` instance.
    var hlco: (hue: Double, luminance: Double, chroma: Double, opacity: Double) {
        let lch = self.rgbColor().toLCH()
        return (hue: lch.h / 360, luminance: lch.l / 100, chroma: lch.c / 128, opacity: lch.alpha)
    }

    /// Initializes and returns a color with the given HLCA values.
    ///
    /// - Parameters:
    ///   - hue:        The hue. A value between 0 and 1.
    ///   - luminance:  The luminance. A value between 0 and 1.
    ///   - chroma:     The chroma. A value between 0 and 1.
    ///   - opacity:    The opacity. A value between 0 and 1.
    init(
        hue: Double,
        luminance: Double,
        chroma: Double,
        opacity: Double
    ) {
        let rgb = LCHColor(l: luminance * 100, c: chroma * 128, h: hue * 360, alpha: opacity).toRGB()
        self.init(red: rgb.r, green: rgb.g, blue: rgb.b, opacity: rgb.alpha)
    }

    // MARK: - Methods
    /// Creates a new `Color` object with a single attribute changed by a given difference using addition.
    ///
    /// - Parameters:
    ///   - attribute: The attribute to change.
    ///   - by: The addition to be added to the current value of the attribute.
    /// - Returns: The resulting new `Color` with the specified change applied.
    func change(_ attribute: ChangeableAttribute, by addition: Double) -> Self {
        switch attribute {
        case .red:
            return change(attribute, to: rgbo.red + addition)

        case .green:
            return change(attribute, to: rgbo.green + addition)

        case .blue:
            return change(attribute, to: rgbo.blue + addition)

        case .hueHSB:
            return change(attribute, to: hsbo.hue + addition)

        case .saturation:
            return change(attribute, to: hsbo.saturation + addition)

        case .brightness:
            return change(attribute, to: hsbo.brightness + addition)

        case .hueHLC:
            return change(attribute, to: hlco.hue + addition)

        case .luminance:
            return change(attribute, to: hlco.luminance + addition)

        case .chroma:
            return change(attribute, to: hlco.chroma + addition)

        case .opacity:
            return change(attribute, to: hlco.opacity + addition)
        }
    }

    /// Creates a new `Color` object with the value of a single attribute set to a given value.
    ///
    /// - Parameters:
    ///   - attribute: The attribute to change.
    ///   - to: The new value to be set for the attribute.
    /// - Returns: The resulting new `Color` with the specified change applied.
    func change(_ attribute: ChangeableAttribute, to newValue: Double) -> Self {
        switch attribute {
        case .red, .green, .blue:
            return newRgboColor(attribute, newValue)

        case .hueHSB, .saturation, .brightness:
            return newHsboColor(attribute, newValue)

        case .hueHLC, .luminance, .chroma, .opacity:
            return newHlcoColor(attribute, newValue)
        }
    }

    func newHlcoColor(_ attribute: Self.ChangeableAttribute, _ newValue: Double) -> Self {
        var newHlco = hlco

        switch attribute {
        case .hueHLC:
            newHlco.hue = newValue

        case .luminance:
            newHlco.luminance = newValue

        case .chroma:
            newHlco.chroma = newValue

        case .opacity:
            newHlco.opacity = newValue

        default:
            break
        }

        return Self(hue: newHlco.hue, luminance: newHlco.luminance, chroma: newHlco.chroma, opacity: newHlco.opacity)
    }

    func newHsboColor(_ attribute: Self.ChangeableAttribute, _ newValue: Double) -> Self {
        var newHsbo = hsbo

        switch attribute {
        case .hueHSB:
            newHsbo.hue = newValue

        case .saturation:
            newHsbo.saturation = newValue

        case .brightness:
            newHsbo.brightness = newValue

        case .opacity:
            newHsbo.opacity = newValue

        default:
            break
        }

        return Self(
            hue: newHsbo.hue,
            saturation: newHsbo.saturation,
            brightness: newHsbo.brightness,
            opacity: newHsbo.opacity
        )
    }

    func newRgboColor(_ attribute: Self.ChangeableAttribute, _ newValue: Double) -> Self {
        var newRgbo = self.rgbo

        switch attribute {
        case .red:
            newRgbo.red = newValue

        case .green:
            newRgbo.green = newValue

        case .blue:
            newRgbo.blue = newValue

        case .opacity:
            newRgbo.opacity = newValue

        default:
            break
        }

        return Color(red: newRgbo.red, green: newRgbo.green, blue: newRgbo.blue, opacity: newRgbo.opacity)
    }
}

extension Color {
    init(hex: String) {
        let rgba = hex.toRGBA()
        self.init(.sRGB, red: Double(rgba.r), green: Double(rgba.g), blue: Double(rgba.b), opacity: Double(rgba.alpha))
    }

    func toHex(alpha: Bool = false) -> String? {
        guard let components = cgColor?.components, components.count >= 3 else { return nil }

        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)

        if components.count >= 4 {
            a = Float(components[3])
        }

        if alpha {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        }
        else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}

private struct ColorSpaces {}

// MARK: - Constants
private let RAD_TO_DEG = 180 / Double.pi

private let LAB_E: Double = 0.008856
private let LAB_16_116: Double = 0.1379310
private let LAB_K_116: Double = 7.787036
private let LAB_X: Double = 0.95047
private let LAB_Y: Double = 1
private let LAB_Z: Double = 1.088_83

// MARK: - RGB
struct RGBColor {
    let r: Double  // 0..1
    let g: Double  // 0..1
    let b: Double  // 0..1
    let alpha: Double  // 0..1

    init(
        r: Double,
        g: Double,
        b: Double,
        alpha: Double
    ) {
        self.r = r
        self.g = g
        self.b = b
        self.alpha = alpha
    }

    fileprivate func sRGBCompand(_ v: Double) -> Double {
        let absV = abs(v)
        let out = absV > 0.040_45 ? pow((absV + 0.055) / 1.055, 2.4) : absV / 12.92
        return v > 0 ? out : -out
    }

    func toXYZ() -> XYZColor {
        let R = sRGBCompand(r)
        let G = sRGBCompand(g)
        let B = sRGBCompand(b)
        let x: Double = (R * 0.412_456_4) + (G * 0.357_576_1) + (B * 0.180_437_5)
        let y: Double = (R * 0.212_672_9) + (G * 0.715_152_2) + (B * 0.072_175_0)
        let z: Double = (R * 0.019_333_9) + (G * 0.119_192_0) + (B * 0.950_304_1)
        return XYZColor(x: x, y: y, z: z, alpha: alpha)
    }

    func toLAB() -> LABColor {
        return toXYZ().toLAB()
    }

    func toLCH() -> LCHColor {
        return toXYZ().toLCH()
    }

    func lerp(_ other: RGBColor, t: Double) -> RGBColor {
        return RGBColor(
            r: r + (other.r - r) * t,
            g: g + (other.g - g) * t,
            b: b + (other.b - b) * t,
            alpha: alpha + (other.alpha - alpha) * t
        )
    }
}

extension Color {
    func rgbColor() -> RGBColor {
        let localRgbo = self.rgbo
        return RGBColor(r: localRgbo.red, g: localRgbo.green, b: localRgbo.blue, alpha: localRgbo.opacity)
    }
}

// MARK: - XYZ

struct XYZColor {
    let x: Double  // 0..0.95047
    let y: Double  // 0..1
    let z: Double  // 0..1.08883
    let alpha: Double  // 0..1

    init(
        x: Double,
        y: Double,
        z: Double,
        alpha: Double
    ) {
        self.x = x
        self.y = y
        self.z = z
        self.alpha = alpha
    }

    fileprivate func sRGBCompand(_ v: Double) -> Double {
        let absV = abs(v)
        let out = absV > 0.003_130_8 ? 1.055 * pow(absV, 1 / 2.4) - 0.055 : absV * 12.92
        return v > 0 ? out : -out
    }

    func toRGB() -> RGBColor {
        let r = (x * 3.240_454_2) + (y * -1.537_138_5) + (z * -0.498_531_4)
        let g = (x * -0.969_266_0) + (y * 1.876_010_8) + (z * 0.041_556_0)
        let b = (x * 0.055_643_4) + (y * -0.204_025_9) + (z * 1.057_225_2)
        let R = sRGBCompand(r)
        let G = sRGBCompand(g)
        let B = sRGBCompand(b)
        return RGBColor(r: R, g: G, b: B, alpha: alpha)
    }

    fileprivate func labCompand(_ v: Double) -> Double {
        return v > LAB_E ? pow(v, 1.0 / 3.0) : (LAB_K_116 * v) + LAB_16_116
    }

    func toLAB() -> LABColor {
        let fx = labCompand(x / LAB_X)
        let fy = labCompand(y / LAB_Y)
        let fz = labCompand(z / LAB_Z)
        return LABColor(
            l: 116 * fy - 16,
            a: 500 * (fx - fy),
            b: 200 * (fy - fz),
            alpha: alpha
        )
    }

    func toLCH() -> LCHColor {
        return toLAB().toLCH()
    }

    func lerp(_ other: XYZColor, t: Double) -> XYZColor {
        return XYZColor(
            x: x + (other.x - x) * t,
            y: y + (other.y - y) * t,
            z: z + (other.z - z) * t,
            alpha: alpha + (other.alpha - alpha) * t
        )
    }
}

// MARK: - LAB

struct LABColor {
    let l: Double  //    0..100
    let a: Double  // -128..128
    let b: Double  // -128..128
    let alpha: Double  //    0..1

    init(
        l: Double,
        a: Double,
        b: Double,
        alpha: Double
    ) {
        self.l = l
        self.a = a
        self.b = b
        self.alpha = alpha
    }

    fileprivate func xyzCompand(_ v: Double) -> Double {
        let v3 = v * v * v
        return v3 > LAB_E ? v3 : (v - LAB_16_116) / LAB_K_116
    }

    func toXYZ() -> XYZColor {
        let y = (l + 16) / 116
        let x = y + (a / 500)
        let z = y - (b / 200)
        return XYZColor(
            x: xyzCompand(x) * LAB_X,
            y: xyzCompand(y) * LAB_Y,
            z: xyzCompand(z) * LAB_Z,
            alpha: alpha
        )
    }

    func toLCH() -> LCHColor {
        let c = sqrt(a * a + b * b)
        let angle = atan2(b, a) * RAD_TO_DEG
        let h = angle < 0 ? angle + 360 : angle
        return LCHColor(l: l, c: c, h: h, alpha: alpha)
    }

    func toRGB() -> RGBColor {
        return toXYZ().toRGB()
    }

    func lerp(_ other: LABColor, t: Double) -> LABColor {
        return LABColor(
            l: l + (other.l - l) * t,
            a: a + (other.a - a) * t,
            b: b + (other.b - b) * t,
            alpha: alpha + (other.alpha - alpha) * t
        )
    }
}

// MARK: - LCH

struct LCHColor {
    let l: Double  // 0..100
    let c: Double  // 0..128
    let h: Double  // 0..360
    let alpha: Double  // 0..1

    init(
        l: Double,
        c: Double,
        h: Double,
        alpha: Double
    ) {
        self.l = l
        self.c = c
        self.h = h
        self.alpha = alpha
    }

    func toLAB() -> LABColor {
        let rad = h / RAD_TO_DEG
        let a = cos(rad) * c
        let b = sin(rad) * c
        return LABColor(l: l, a: a, b: b, alpha: alpha)
    }

    func toXYZ() -> XYZColor {
        return toLAB().toXYZ()
    }

    func toRGB() -> RGBColor {
        return toXYZ().toRGB()
    }

    func lerp(_ other: LCHColor, t: Double) -> LCHColor {
        let angle =
        (((((other.h - h).truncatingRemainder(dividingBy: 360)) + 540).truncatingRemainder(dividingBy: 360)) - 180) * t
        return LCHColor(
            l: l + (other.l - l) * t,
            c: c + (other.c - c) * t,
            h: (h + angle + 360).truncatingRemainder(dividingBy: 360),
            alpha: alpha + (other.alpha - alpha) * t
        )
    }
}

private extension String {
    func toRGBA() -> (r: CGFloat, g: CGFloat, b: CGFloat, alpha: CGFloat) {
        var normalizedHex = self.trimmingCharacters(in: .whitespacesAndNewlines)
        normalizedHex = normalizedHex.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0

        let length = normalizedHex.count

        Scanner(string: normalizedHex).scanHexInt64(&rgb)

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        }

        return (r, g, b, a)
    }
}
