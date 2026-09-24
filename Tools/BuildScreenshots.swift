// Builds the Mac App Store screenshots.
//
// A menu bar app is awkward to screenshot: the part that matters is a 40pt
// strip at the top of the screen, and a full desktop capture buries it. So each
// frame states one claim in type and shows the evidence enlarged beneath it,
// rather than hoping the viewer spots a changed sliver.
//
// Run:  swift Tools/BuildScreenshots.swift <assets-dir> <output-dir>

import AppKit

let arguments = CommandLine.arguments
guard arguments.count >= 4 else {
    fputs("usage: BuildScreenshots.swift <assets-dir> <output-dir> <language>\n", stderr)
    exit(2)
}
let assets = arguments[1]
let output = arguments[2]
let language = arguments[3]

/// Headlines and captions live in JSON so they can be corrected without
/// touching this file — and so a missing translation fails here rather than
/// shipping an English frame into a Japanese listing.
let copyPath = (arguments.count > 4) ? arguments[4] : "Tools/screenshot-copy.json"
guard let copyData = FileManager.default.contents(atPath: copyPath),
      let allCopy = try? JSONSerialization.jsonObject(with: copyData) as? [String: [String: String]],
      let copy = allCopy[language]
else {
    fputs("no copy for \(language) in \(copyPath)\n", stderr)
    exit(3)
}
func text(_ key: String) -> String {
    guard let value = copy[key] else {
        fputs("missing key \(key) for \(language)\n", stderr)
        exit(4)
    }
    return value
}
try? FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)

/// Apple accepts 2880x1800 or 2560x1600 for macOS. The larger one leaves room
/// for the menu bar strip to be enlarged without going soft.
let size = NSSize(width: 2880, height: 1800)

let pink = NSColor(srgbRed: 0.925, green: 0.282, blue: 0.600, alpha: 1)
let pinkDeep = NSColor(srgbRed: 0.745, green: 0.094, blue: 0.365, alpha: 1)
let ink = NSColor(srgbRed: 0.07, green: 0.07, blue: 0.08, alpha: 1)
let muted = NSColor(srgbRed: 0.42, green: 0.42, blue: 0.46, alpha: 1)

/// Returns the image and its size in *pixels*.
///
/// `NSImage.size` reports points, and a screencapture PNG carries Retina DPI, so
/// a 960x1184 file measures 480x592 there — scaling by that silently halves
/// everything. Reading the bitmap rep avoids guessing.
func load(_ name: String) -> (image: NSImage, pixels: NSSize)? {
    guard let image = NSImage(contentsOfFile: "\(assets)/\(name)"),
          let rep = image.representations.first
    else { return nil }
    return (image, NSSize(width: rep.pixelsWide, height: rep.pixelsHigh))
}

/// Draws a centred block whose *top* edge sits at `top`, and returns its height.
///
/// Cocoa's origin is bottom-left but text fills a rect downward from its top, so
/// positioning by the rect's origin puts every block a block-height too high —
/// which is how the first attempt pushed the headline off the canvas and dropped
/// the captions on top of the artwork.
@discardableResult
func draw(_ text: String, centreX: CGFloat, top: CGFloat, size fontSize: CGFloat,
          weight: NSFont.Weight, colour: NSColor, maxWidth: CGFloat) -> CGFloat {
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    style.lineHeightMultiple = 1.1
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: fontSize, weight: weight),
        .foregroundColor: colour,
        .paragraphStyle: style,
    ]
    let string = NSAttributedString(string: text, attributes: attributes)
    let measured = string.boundingRect(with: NSSize(width: maxWidth, height: .greatestFiniteMagnitude),
                                       options: [.usesLineFragmentOrigin, .usesFontLeading])
    let height = ceil(measured.height)
    string.draw(with: NSRect(x: centreX - maxWidth / 2, y: top - height, width: maxWidth, height: height),
                options: [.usesLineFragmentOrigin, .usesFontLeading])
    return height
}

/// The menu bar strips are 80px tall captures of a 40pt band. Blown up they
/// carry the whole point of the app, so they get a card of their own with a
/// soft shadow — otherwise they read as a stray line across the canvas.
func drawStrip(_ asset: (image: NSImage, pixels: NSSize), top: CGFloat,
               targetWidth: CGFloat, label: String?) -> CGFloat {
    let image = asset.image
    let width = targetWidth
    let height = targetWidth * asset.pixels.height / asset.pixels.width
    let rect = NSRect(x: (size.width - width) / 2, y: top - height, width: width, height: height)

    NSGraphicsContext.current?.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
    shadow.shadowBlurRadius = 34
    shadow.shadowOffset = NSSize(width: 0, height: -10)
    shadow.set()
    let card = NSBezierPath(roundedRect: rect.insetBy(dx: -18, dy: -18), xRadius: 22, yRadius: 22)
    NSColor.white.setFill()
    card.fill()
    NSGraphicsContext.current?.restoreGraphicsState()

    image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)

    var bottom = rect.minY - 18
    if let label {
        bottom -= 34
        bottom -= draw(label, centreX: size.width / 2, top: bottom,
                       size: 42, weight: .medium, colour: muted, maxWidth: 1800)
    }
    return bottom
}

func drawWindow(_ asset: (image: NSImage, pixels: NSSize), top: CGFloat, targetHeight: CGFloat) {
    let image = asset.image
    let height = targetHeight
    let width = targetHeight * asset.pixels.width / asset.pixels.height
    let rect = NSRect(x: (size.width - width) / 2, y: top - height, width: width, height: height)
    NSGraphicsContext.current?.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
    shadow.shadowBlurRadius = 48
    shadow.shadowOffset = NSSize(width: 0, height: -16)
    shadow.set()
    NSBezierPath(roundedRect: rect, xRadius: 20, yRadius: 20).fill()
    NSGraphicsContext.current?.restoreGraphicsState()
    image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
}

func frame(_ name: String, headline: String, subhead: String,
           body: (NSRect) -> Void) {
    // An explicit bitmap rep, not NSImage.lockFocus(): on a Retina display
    // lockFocus renders at 2x, producing 5760x3600 where Apple wants exactly
    // 2880x1800 and rejects anything else.
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size.width), pixelsHigh: Int(size.height),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
    else { fatalError("could not create a \(Int(size.width))x\(Int(size.height)) bitmap") }
    rep.size = size

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    NSGradient(colors: [
        NSColor(srgbRed: 0.98, green: 0.97, blue: 0.98, alpha: 1),
        NSColor(srgbRed: 0.95, green: 0.94, blue: 0.96, alpha: 1),
    ])?.draw(in: NSRect(origin: .zero, size: size), angle: -90)

    // A pink wash at the top ties the frames to the icon without shouting.
    NSGradient(colors: [pink.withAlphaComponent(0.13), pink.withAlphaComponent(0)])?
        .draw(in: NSRect(x: 0, y: size.height - 620, width: size.width, height: 620), angle: -90)

    var cursor = size.height - 170
    cursor -= draw(headline, centreX: size.width / 2, top: cursor,
                   size: 108, weight: .bold, colour: ink, maxWidth: 2320)
    cursor -= 40
    cursor -= draw(subhead, centreX: size.width / 2, top: cursor,
                   size: 48, weight: .regular, colour: muted, maxWidth: 2040)

    body(NSRect(origin: .zero, size: size))

    NSGraphicsContext.restoreGraphicsState()

    guard let png = rep.representation(using: .png, properties: [:])
    else { fatalError("could not encode \(name)") }
    try! png.write(to: URL(fileURLWithPath: "\(output)/\(name).png"))
    print("wrote \(name).png")
}

let expanded = load("bar_expanded.png")
let collapsed = load("bar_collapsed.png")
let general = load("win_general.png")
let howItWorks = load("win_howitworks.png")

frame("01-before-after",
      headline: text("h1"),
      subhead: text("s1")) { _ in
    // Centred in the space the headline leaves, rather than hugging it: the
    // first attempt stacked both strips high and left a third of the canvas
    // empty underneath.
    var y: CGFloat = 1120
    if let expanded { y = drawStrip(expanded, top: y, targetWidth: 1560, label: text("capExpanded")) }
    y -= 230
    if let collapsed { y = drawStrip(collapsed, top: y, targetWidth: 1560, label: text("capCollapsed")) }
    y -= 170
    draw(text("capShortcut"), centreX: size.width / 2, top: y,
         size: 44, weight: .regular, colour: muted.withAlphaComponent(0.85), maxWidth: 1800)
}

frame("02-settings",
      headline: text("h2"),
      subhead: text("s2")) { _ in
    if let general { drawWindow(general, top: 1250, targetHeight: 1120) }
}

// The headline has to describe what the frame actually shows. An earlier
// version promised "No permissions. No network." over a window full of setup
// steps, which asks the reader to take the claim on faith while looking at
// something else.
frame("03-how-it-works",
      headline: text("h3"),
      subhead: text("s3")) { _ in
    if let howItWorks { drawWindow(howItWorks, top: 1250, targetHeight: 1120) }
}
