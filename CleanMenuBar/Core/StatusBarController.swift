import AppKit
import OSLog

/// Owns CleanMenuBar's status items and drives the collapse/expand behaviour.
///
/// ## Why this is not the classic technique
///
/// Every menu bar hider used to give one status item an enormous length. The bar
/// packs icons right-to-left, so an oversized item shoved everything to its left
/// past the screen edge. macOS 27 ended that: the bar no longer reflows around an
/// oversized item, and any item whose length reaches **half the display width** is
/// dropped outright. Measured on macOS 27.0 (1512pt display, cliff at 756pt):
///
///   * length 10000 — renders 5016pt wide, yields its slot, moves no neighbour.
///   * length 730 — not drawn anywhere, but icons to its left do disappear.
///   * length 500 — draws, and icons to its left move into the system's native
///     overflow, but the item sprawls across the bar and the push is far weaker.
///
/// So the item that pushes can never be the item you click. The pusher has to be
/// separate and expendable, and the arrow has to sit to its right:
///
///     [ always-hidden ] [ ahPusher ] [ hidden ] [ pusher ] [ arrow ] [ visible ]
///
/// Items are created right-to-left, so the arrow is created first.
@MainActor
final class StatusBarController {
    enum State: Equatable {
        case collapsed     // both sections hidden
        case expanded      // the normal hidden section is showing
        case allRevealed   // the always-hidden section is showing too
    }

    private let logger = Logger(subsystem: "com.atilac.CleanMenuBar", category: "StatusBar")
    private let preferences: Preferences

    private let toggleItem: NSStatusItem
    private let pusherItem: NSStatusItem
    private let alwaysHiddenPusherItem: NSStatusItem

    private var autoCollapseTimer: Timer?
    private var hoverMonitor: Any?
    private var hoverDwellTimer: Timer?

    private(set) var state: State = .expanded {
        didSet { if oldValue != state { applyState() } }
    }

    /// macOS 27 drops an item once its length reaches half the display width.
    /// Size against the *narrowest* attached display — that is the one that
    /// decides whether the item survives — and stay clear of the cliff.
    private var shoveLength: CGFloat {
        if let forced = ProcessInfo.processInfo.environment["CMB_FORCE_LEN"],
           let value = Double(forced) {
            return CGFloat(value)
        }
        let narrowest = NSScreen.screens.map(\.frame.width).min() ?? 1512
        return (narrowest / 2) - 20
    }

    init(preferences: Preferences = .shared) {
        self.preferences = preferences
        let bar = NSStatusBar.system
        toggleItem = bar.statusItem(withLength: NSStatusItem.variableLength)
        pusherItem = bar.statusItem(withLength: NSStatusItem.variableLength)
        alwaysHiddenPusherItem = bar.statusItem(withLength: NSStatusItem.variableLength)

        // The `_v27` suffix keeps these clear of any position table written by a
        // build that used the pre-27 technique.
        toggleItem.autosaveName = "CleanMenuBar.toggle_v27"
        pusherItem.autosaveName = "CleanMenuBar.pusher_v27"
        alwaysHiddenPusherItem.autosaveName = "CleanMenuBar.alwaysHiddenPusher_v27"

        configureButtons()
        restoreRemovedItems()
        if preferences.restoreLastState, preferences.lastStateCollapsed {
            state = .collapsed   // triggers applyState via didSet
        } else {
            applyState()
        }
        installHoverMonitorIfEnabled()

        NotificationCenter.default.addObserver(
            self, selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        MainActor.assumeIsolated {
            hoverDwellTimer?.invalidate()
            autoCollapseTimer?.invalidate()
            if let hoverMonitor { NSEvent.removeMonitor(hoverMonitor) }
        }
    }

    /// ⌘-dragging a status item off the bar is persisted by macOS via its autosave
    /// name, which leaves the app running with no way to reach it. These items are
    /// the app's only UI, so bring them back at launch.
    private func restoreRemovedItems() {
        toggleItem.isVisible = true
        pusherItem.isVisible = true
    }

    // MARK: - Appearance

    /// A missing SF Symbol yields a nil image, which leaves a zero-width, invisible
    /// status item the user can neither find nor drag — so always fall back to a
    /// glyph we draw ourselves.
    private static func symbol(_ name: String, _ description: String) -> NSImage {
        NSImage(systemSymbolName: name, accessibilityDescription: description) ?? handleImage()
    }

    /// The drag handle for a pusher — a thin vertical bar, drawn rather than looked
    /// up (`line.3.vertical` does not exist on macOS 27).
    ///
    /// It has to stay visible during setup because an invisible status item cannot
    /// be ⌘-dragged into position. `Preferences.separatorsHidden` takes it away
    /// once the user is done arranging things.
    private static func handleImage(translucent: Bool = false) -> NSImage {
        let image = NSImage(size: NSSize(width: 5, height: 13), flipped: false) { rect in
            let bar = NSRect(x: rect.midX - 1, y: rect.minY, width: 2, height: rect.height)
            NSColor.black.withAlphaComponent(translucent ? 0.35 : 1).setFill()
            NSBezierPath(roundedRect: bar, xRadius: 1, yRadius: 1).fill()
            return true
        }
        image.isTemplate = true
        return image
    }

    private func configureButtons() {
        if let b = toggleItem.button {
            b.target = self
            b.action = #selector(toggleClicked)
            b.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        // A separator is the obvious thing to click when you want to configure
        // the app, so either button opens the menu — no hunting for right-click.
        // ⌘-dragging is unaffected: macOS handles that before the action fires,
        // so the item stays positionable.
        for item in [pusherItem, alwaysHiddenPusherItem] {
            item.button?.target = self
            item.button?.action = #selector(separatorClicked)
            item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        updateAppearance()
    }

    private func updateAppearance() {
        toggleItem.button?.image = Self.symbol(
            state == .collapsed ? "chevron.left" : "chevron.right",
            state == .collapsed
                ? String(localized: "Expand hidden menu bar items")
                : String(localized: "Collapse menu bar items"))

        // A pusher's glyph must go while it is inflated. A status item button
        // centres its image in the item's width, so leaving the handle in place
        // paints it in the middle of a 736pt-wide item — which lands over by
        // Spotlight and reads as a stray mark flickering in the menu bar.
        pusherItem.button?.image = isInflated(pusherItem) ? nil : Self.handleImage()
        alwaysHiddenPusherItem.button?.image =
            isInflated(alwaysHiddenPusherItem) ? nil : Self.handleImage(translucent: true)

        pusherItem.isVisible = !preferences.separatorsHidden
        alwaysHiddenPusherItem.isVisible =
            preferences.alwaysHiddenSectionEnabled && !preferences.separatorsHidden
    }

    private func isInflated(_ item: NSStatusItem) -> Bool {
        item.length > 100
    }

    // MARK: - State

    private func applyState() {
        let length = shoveLength
        let alwaysHiddenEnabled = preferences.alwaysHiddenSectionEnabled

        switch state {
        case .collapsed:
            pusherItem.length = length
            alwaysHiddenPusherItem.length = alwaysHiddenEnabled ? length : NSStatusItem.variableLength
        case .expanded:
            pusherItem.length = NSStatusItem.variableLength
            alwaysHiddenPusherItem.length = alwaysHiddenEnabled ? length : NSStatusItem.variableLength
        case .allRevealed:
            pusherItem.length = NSStatusItem.variableLength
            alwaysHiddenPusherItem.length = NSStatusItem.variableLength
        }

        // Recorded on every change rather than at quit, so a crash or a force
        // quit does not lose it.
        if state != .allRevealed { preferences.lastStateCollapsed = (state == .collapsed) }
        applyFullStatusBarPolicy()
        updateAppearance()
        scheduleAutoCollapseIfNeeded()
        logger.debug("state=\(String(describing: self.state)) pusher=\(self.pusherItem.length) ah=\(self.alwaysHiddenPusherItem.length)")
    }

    /// "Use the full menu bar when expanding": becoming the active regular app
    /// replaces the frontmost app's menus with CleanMenuBar's near-empty one,
    /// which frees the horizontal space those menus were occupying.
    private func applyFullStatusBarPolicy() {
        guard preferences.useFullStatusBarOnExpand else { return }
        if state == .collapsed {
            NSApp.setActivationPolicy(.accessory)
            NSApp.deactivate()
        } else {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func set(_ newState: State) { state = newState }

    func toggle() {
        state = (state == .collapsed) ? .expanded : .collapsed
    }

    func toggleAlwaysHiddenSection() {
        state = (state == .allRevealed) ? .expanded : .allRevealed
    }

    @objc private func toggleClicked() {
        guard let event = NSApp.currentEvent else { toggle(); return }
        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            popUpMenu(on: toggleItem)
        } else {
            toggle()
        }
    }

    @objc private func separatorClicked() {
        popUpMenu(on: pusherItem)
    }

    @objc private func screenParametersChanged() {
        // Display layout changed, so the drop threshold moved with it.
        applyState()
    }

    // MARK: - Hover to expand

    private func installHoverMonitorIfEnabled() {
        if let hoverMonitor {
            NSEvent.removeMonitor(hoverMonitor)
            self.hoverMonitor = nil
        }
        hoverDwellTimer?.invalidate()
        hoverDwellTimer = nil
        guard preferences.hoverToExpand else { return }

        // Mouse-moved global monitors need no Accessibility permission — only
        // keyboard ones do — so this stays sandbox-safe.
        hoverMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            MainActor.assumeIsolated { self?.hoverMoved() }
        }
    }

    private func hoverMoved() {
        guard state == .collapsed, isMouseInMenuBar else {
            hoverDwellTimer?.invalidate()
            hoverDwellTimer = nil
            return
        }
        guard hoverDwellTimer == nil else { return }
        // A short dwell, so a pointer merely passing through does not expand.
        hoverDwellTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.hoverDwellTimer = nil
                if self.state == .collapsed, self.isMouseInMenuBar { self.set(.expanded) }
            }
        }
    }

    /// True while the pointer sits in any screen's menu bar band — the strip
    /// between `visibleFrame.maxY` and `frame.maxY`. On fullscreen spaces the bar
    /// is hidden and the band collapses to nothing, so this is false there, which
    /// is what we want: no visible bar, no hover.
    private var isMouseInMenuBar: Bool {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.contains { screen in
            mouse.x >= screen.frame.minX && mouse.x <= screen.frame.maxX
                && mouse.y >= screen.visibleFrame.maxY && mouse.y <= screen.frame.maxY
        }
    }

    // MARK: - Auto collapse

    private func scheduleAutoCollapseIfNeeded() {
        autoCollapseTimer?.invalidate()
        autoCollapseTimer = nil
        guard preferences.autoCollapse, state != .collapsed else { return }
        autoCollapseTimer = Timer.scheduledTimer(withTimeInterval: preferences.autoCollapseDelay,
                                                 repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.autoCollapseFired() }
        }
    }

    private func autoCollapseFired() {
        // Don't yank the bar shut mid-interaction, and don't deactivate the app
        // out from under someone editing settings.
        guard !isMouseInMenuBar, !SettingsWindowController.shared.isVisible else {
            scheduleAutoCollapseIfNeeded()
            return
        }
        set(.collapsed)
    }

    // MARK: - Menu

    /// Mirrors Hidden Bar's status item menu (MIT, see NOTICE).
    private func contextMenu() -> NSMenu {
        let menu = NSMenu()

        let preferencesItem = NSMenuItem(title: String(localized: "Preferences..."),
                                         action: #selector(openPreferences), keyEquivalent: ",")
        preferencesItem.target = self
        menu.addItem(preferencesItem)

        let autoCollapseItem = NSMenuItem(
            title: preferences.autoCollapse
                ? String(localized: "Disable Auto Collapse")
                : String(localized: "Enable Auto Collapse"),
            action: #selector(toggleAutoCollapse), keyEquivalent: "t")
        autoCollapseItem.target = self
        menu.addItem(autoCollapseItem)

        if preferences.alwaysHiddenSectionEnabled {
            let alwaysHiddenItem = NSMenuItem(
                title: state == .allRevealed
                    ? String(localized: "Hide Always-Hidden Items")
                    : String(localized: "Show Always-Hidden Items"),
                action: #selector(toggleAlwaysHidden), keyEquivalent: "h")
            alwaysHiddenItem.target = self
            menu.addItem(alwaysHiddenItem)
        }

        menu.addItem(.separator())

        let aboutItem = NSMenuItem(title: String(localized: "About CleanMenuBar"),
                                   action: #selector(openAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem(title: String(localized: "Quit"),
                                action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }

    /// Attaching the menu makes the next click open it; detach right afterwards so
    /// a plain left click keeps toggling instead of reopening the menu.
    private func popUpMenu(on item: NSStatusItem) {
        item.menu = contextMenu()
        item.button?.performClick(nil)
        item.menu = nil
    }

    @objc private func openPreferences() { SettingsWindowController.shared.show() }

    @objc private func openAbout() {
        // Our own About tab rather than the standard panel, so the credits live
        // in one place instead of being split between the two.
        SettingsWindowController.shared.show(tab: .about)
    }

    @objc private func toggleAutoCollapse() {
        preferences.autoCollapse.toggle()
        scheduleAutoCollapseIfNeeded()
    }

    @objc private func toggleAlwaysHidden() { toggleAlwaysHiddenSection() }

    /// What is actually in effect right now, for end-to-end verification of the
    /// settings — real item lengths and visibility, not stored preference values.
    func diagnostics() -> String {
        func describe(_ name: String, _ item: NSStatusItem) -> String {
            String(format: "%@(len=%.0f visible=%@ hasImage=%@)", name, item.length,
                   item.isVisible ? "Y" : "N", item.button?.image == nil ? "N" : "Y")
        }
        return [
            "state=\(state)",
            "shoveLength=\(Int(shoveLength))",
            describe("toggle", toggleItem),
            describe("pusher", pusherItem),
            describe("alwaysHiddenPusher", alwaysHiddenPusherItem),
            "hoverMonitor=\(hoverMonitor == nil ? "off" : "on")",
            "mouseInMenuBar=\(isMouseInMenuBar)",
            "mouseLoc=\(Int(NSEvent.mouseLocation.x)),\(Int(NSEvent.mouseLocation.y))",
            "menuBarBand=\(Int(NSScreen.main?.visibleFrame.maxY ?? 0))..\(Int(NSScreen.main?.frame.maxY ?? 0))",
            "autoCollapseTimer=\(autoCollapseTimer == nil ? "off" : "armed")",
        ].joined(separator: " ")
    }

    /// Re-read preferences that change what is on screen or which monitors run.
    func preferencesChanged() {
        installHoverMonitorIfEnabled()
        applyState()
    }
}
