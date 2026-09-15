import AppKit
import SwiftUI

/// Hosts the settings UI in a plain window.
///
/// An accessory app has no app menu, so SwiftUI's `Settings` scene is not
/// reachable — this owns the window directly instead.
@MainActor
final class SettingsWindowController {
    static let shared = SettingsWindowController()

    private var window: NSWindow?
    /// Held so `show(tab:)` can switch tabs on a window that is already open.
    private var selection = SettingsView.Tab.general


    /// Used to defer auto-collapse: collapsing with "use full menu bar" on
    /// deactivates the app and would dismiss this window mid-edit.
    var isVisible: Bool { window?.isVisible ?? false }

    func show(tab: SettingsView.Tab = .general) {
        selection = tab
        if window == nil {
            let binding = Binding(get: { [weak self] in self?.selection ?? .general },
                                  set: { [weak self] in self?.selection = $0 })
            let hosting = NSHostingController(rootView: SettingsView(selection: binding))
            let window = NSWindow(contentViewController: hosting)
            window.title = String(localized: "CleanMenuBar Settings")
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
