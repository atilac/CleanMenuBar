import SwiftUI

/// The About tab: what this is, and who it came from.
///
/// Everything here is read from the bundle rather than written into the view, so
/// the version can never drift from what was actually built.
struct AboutView: View {
    private var version: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "\(short) (\(build))"
    }

    private var copyright: String {
        Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String ?? ""
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 84, height: 84)

                    Text("CleanMenuBar")
                        .font(.title2.weight(.semibold))

                    Text("Version \(version)")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    Text("Hide the menu bar icons you don't want to look at.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 3) {
                        Text(copyright)
                        Text("Released under the MIT License.")
                        Link("github.com/atilac/CleanMenuBar",
                             destination: URL(string: "https://github.com/atilac/CleanMenuBar")!)
                            // Explicit, because the surrounding block is
                            // .secondary and would otherwise grey the link out.
                            .foregroundStyle(Color.accentColor)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Thanks")
                        .font(.headline)

                    Text("CleanMenuBar stands on **Hidden Bar** by Dwarves Foundation. Its menus, settings and wording come from theirs, used under the MIT License.")

                    Text("Thank you to everyone who built and maintained Hidden Bar over six years — Thanh Nguyen, phucld, Trung Phan, Peter Luo, Phuc Le Dien, Licardo and Han Ngo among them. They kept a small, focused, genuinely free tool alive, and this app has its shape because of theirs.")

                    Text("The hiding mechanism here had to be rewritten: macOS 27 removed the behaviour every menu bar app depended on. That part is new; the design it replaces was theirs first.")
                        .foregroundStyle(.secondary)

                    Link("github.com/dwarvesf/hidden",
                         destination: URL(string: "https://github.com/dwarvesf/hidden")!)
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)

            }
            .padding(22)
        }
    }
}
