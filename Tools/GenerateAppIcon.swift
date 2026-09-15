// Generates CleanMenuBar's app icon at every size the asset catalogue needs.
//
// The mark is a bold "C" drawn as a dashed arc: solid enough to read as the
// letter, broken enough to say "partly hidden", which is what the app does.
//
// Run:  swift Tools/GenerateAppIcon.swift
// Then rebuild — the PNGs land in CleanMenuBar/Assets.xcassets/AppIcon.appiconset.

import AppKit

let outputDirectory = "CleanMenuBar/Assets.xcassets/AppIcon.appiconset"

/// (size in pixels, file name) for every slot a macOS icon set expects.
let slots: [(Int, String)] = [
    (16, "icon_16x16.png"),      (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),      (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),   (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),   (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),   (1024, "icon_512x512@2x.png"),
]

/// - Parameter bleed: when true the plate fills the canvas edge to edge.
///   macOS app icons sit inside their canvas; a favicon or a touch icon should
///   not, because the platform crops or rounds it and the margin is wasted at
///   16 or 32 pixels.
func drawIcon(size: CGFloat, bleed: Bool = false, into context: CGContext) {
    let inset = bleed ? 0 : size * 0.09
    let rect = CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let cornerRadius = rect.width * 0.2237  // the standard macOS squircle proportion

    context.saveGState()
    let plate = CGPath(roundedRect: rect, cornerWidth: cornerRadius,
                       cornerHeight: cornerRadius, transform: nil)
    context.addPath(plate)
    context.clip()

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    // Swipress pink: #ec4899 (Tailwind pink-500) falling to #be185d (pink-700),
    // so the plate keeps a light source rather than reading as flat fill.
    let gradient = CGGradient(colorsSpace: colorSpace,
                              colors: [
                                CGColor(red: 0.925, green: 0.282, blue: 0.600, alpha: 1),
                                CGColor(red: 0.745, green: 0.094, blue: 0.365, alpha: 1),
                              ] as CFArray,
                              locations: [0, 1])!
    context.drawLinearGradient(gradient,
                               start: CGPoint(x: rect.minX, y: rect.maxY),
                               end: CGPoint(x: rect.maxX, y: rect.minY),
                               options: [])
    context.restoreGState()

    // A hairline lip, so the plate keeps an edge on a dark desktop.
    context.addPath(plate)
    context.setStrokeColor(CGColor(gray: 1, alpha: 0.16))
    context.setLineWidth(max(1, size * 0.006))
    context.strokePath()

    // The dashed C.
    let centre = CGPoint(x: rect.midX + rect.width * 0.03, y: rect.midY)
    let radius = rect.width * 0.285
    let lineWidth = rect.width * 0.125

    // Drawn as explicit arcs rather than a dash pattern, because *where* the
    // breaks fall decides whether this still reads as a letter. An evenly spaced
    // dash pattern lands them wherever the maths puts them and the result looks
    // like a camera shutter. Placed by hand, three breaks stay legible: one in
    // each curve and one squarely at 9 o'clock, so the cut reads as deliberate
    // rather than as a gap that drifted onto the spine.
    //
    // The mouth is still the largest opening by a wide margin (105° against 22°),
    // which is what keeps the eye reading "C" instead of "broken ring".
    //
    // Degrees, counterclockwise from the 3 o'clock position.
    // Three cuts at every size, which only works because the stroke is kept
    // relatively light: a heavy stroke turns the four arcs into short stubby
    // blobs that stop joining up into a letter once the canvas is small.
    //
    // Geometry, in degrees counterclockwise from 3 o'clock. The mouth stays far
    // wider than the cuts — that ratio is what keeps the eye reading "C" rather
    // than "broken ring" — and the four segments divide what is left evenly.
    let mouth: CGFloat = 105
    let cut: CGFloat = 18
    let segmentCount = 4
    let sweep = 360 - mouth
    let segment = (sweep - cut * CGFloat(segmentCount - 1)) / CGFloat(segmentCount)

    var solidSegments: [(CGFloat, CGFloat)] = []
    var cursor = mouth / 2
    for _ in 0..<segmentCount {
        solidSegments.append((cursor, cursor + segment))
        cursor += segment + cut
    }

    context.saveGState()
    context.setLineWidth(lineWidth)
    context.setLineCap(.butt)
    context.setStrokeColor(CGColor(gray: 1, alpha: 1.0))

    let arcs = solidSegments
    let radians = { (degrees: CGFloat) in degrees * .pi / 180 }
    for (start, end) in arcs {
        let path = CGMutablePath()
        path.addArc(center: centre, radius: radius,
                    startAngle: radians(start), endAngle: radians(end),
                    clockwise: false)
        context.addPath(path)
        context.strokePath()
    }
    context.restoreGState()
}

func writeIcon(size: Int, bleed: Bool = false, to path: String) {
    let dimension = CGFloat(size)
    guard let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                                  bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { fatalError("could not create a \(size)px context") }

    context.setAllowsAntialiasing(true)
    drawIcon(size: dimension, bleed: bleed, into: context)

    guard let image = context.makeImage() else { fatalError("could not render \(size)px") }
    let rep = NSBitmapImageRep(cgImage: image)
    rep.size = NSSize(width: dimension, height: dimension)
    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("could not encode \(size)px")
    }
    try! data.write(to: URL(fileURLWithPath: path))
}

for (size, name) in slots {
    writeIcon(size: size, to: "\(outputDirectory)/\(name)")
    print("wrote \(name) (\(size)px)")
}

// Web icons: same mark, drawn edge to edge.
let webSlots: [(Int, String)] = [
    (32, "site/favicon-32.png"),
    (180, "site/apple-touch-icon.png"),
    (512, "site/icon-512.png"),
]
for (size, path) in webSlots {
    writeIcon(size: size, bleed: true, to: path)
    print("wrote \(path) (\(size)px)")
}
