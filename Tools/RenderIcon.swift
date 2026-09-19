import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Renders `Assets.xcassets/AppIcon.appiconset/AppIcon.png` from the *same*
/// geometry the app draws on screen — see `Sonder/Design/MarkGeometry.swift`.
/// Run it with `Tools/render-icon.sh`.
@main
enum RenderIcon {
    static let side = 1024

    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            FileHandle.standardError.write(Data("usage: render-icon <out.png>\n".utf8))
            exit(2)
        }

        let rect = CGRect(x: 0, y: 0, width: CGFloat(side), height: CGFloat(side))
        let ctx = CGContext(
            data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!

        // The geometry is authored y-down to match SwiftUI; flip once, here.
        ctx.translateBy(x: 0, y: CGFloat(side))
        ctx.scaleBy(x: 1, y: -1)

        // Drawn opaque and square on purpose: iOS applies the home screen mask
        // itself, and an icon that rounds its own corners shows a hairline of
        // background inside that mask.
        ctx.setFillColor(rgb(SonderMark.tile))
        ctx.fill(rect)

        let side = rect.width
        ctx.saveGState()
        ctx.addPath(CGPath(rect: rect, transform: nil))  // keep it inside the tile
        ctx.clip()
        ctx.addPath(SonderMark.swoosh(in: rect))
        ctx.setStrokeColor(rgb(SonderMark.swoosh))
        ctx.setLineWidth(side * SonderMark.swooshWidth)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.strokePath()
        ctx.restoreGState()

        let centre = CGPoint(x: rect.minX + SonderMark.bezelCentre.x * side,
                             y: rect.minY + SonderMark.bezelCentre.y * side)
        let r = side * SonderMark.bezelRadius
        let bezel = CGRect(x: centre.x - r, y: centre.y - r, width: r * 2, height: r * 2)

        ctx.setFillColor(rgb(SonderMark.tile))
        ctx.fillEllipse(in: bezel.insetBy(dx: side * SonderMark.bezelFillInset,
                                          dy: side * SonderMark.bezelFillInset))
        ctx.setStrokeColor(rgb(SonderMark.bezel))
        ctx.setLineWidth(side * SonderMark.bezelWidth)
        ctx.strokeEllipse(in: bezel)

        let n = side * SonderMark.needleSize
        ctx.addPath(SonderMark.needle(in: CGRect(x: centre.x - n / 2,
                                                 y: centre.y - n / 2,
                                                 width: n, height: n)))
        ctx.setFillColor(rgb(SonderMark.needle))
        ctx.fillPath()

        let out = URL(fileURLWithPath: CommandLine.arguments[1])
        guard let dest = CGImageDestinationCreateWithURL(
            out as CFURL, UTType.png.identifier as CFString, 1, nil
        ) else { throw Failure("could not open \(out.path) for writing") }

        CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
        guard CGImageDestinationFinalize(dest) else {
            throw Failure("could not write \(out.path)")
        }
        print("wrote \(out.path)")
    }

    static func rgb(_ hex: UInt32) -> CGColor {
        CGColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1)
    }

    struct Failure: Error, CustomStringConvertible { 
        let description: String
        init(_ description: String) { self.description = description }
    }
}
