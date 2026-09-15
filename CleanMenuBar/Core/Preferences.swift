import Foundation
import Observation

/// User-facing settings, persisted in `UserDefaults`.
///
/// The option set mirrors Hidden Bar's (MIT, see NOTICE) so the app is a drop-in
/// replacement for people coming from it.
@MainActor
@Observable
final class Preferences {
    static let shared = Preferences()

    private enum Key {
        static let launchAtLogin = "launchAtLogin"
        static let autoCollapse = "autoCollapse"
        static let autoCollapseDelay = "autoCollapseDelay"
        static let alwaysHiddenSectionEnabled = "alwaysHiddenSectionEnabled"
        static let hoverToExpand = "hoverToExpand"
        static let separatorsHidden = "separatorsHidden"
        static let useFullStatusBarOnExpand = "useFullStatusBarOnExpand"
        static let globalShortcut = "globalShortcut"
        static let showSettingsAtLaunch = "showSettingsAtLaunch"
        static let restoreLastState = "restoreLastState"
        static let lastStateCollapsed = "lastStateCollapsed"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.autoCollapse: false,
            Key.autoCollapseDelay: AutoCollapseDelay.tenSeconds.seconds,
            Key.alwaysHiddenSectionEnabled: false,
            Key.hoverToExpand: false,
            Key.separatorsHidden: false,
            Key.useFullStatusBarOnExpand: false,
            // Hidden Bar opens its window on first launch; without it an accessory
            // app gives a new user no sign that anything installed.
            Key.showSettingsAtLaunch: true,
            // Off by default: an app that opens already collapsed makes icons
            // vanish with no explanation the first time someone installs it.
            Key.restoreLastState: false,
            Key.globalShortcut: Self.defaultShortcutData,
        ])
    }

    var launchAtLogin: Bool {
        get { access(keyPath: \.launchAtLogin); return defaults.bool(forKey: Key.launchAtLogin) }
        set {
            withMutation(keyPath: \.launchAtLogin) { defaults.set(newValue, forKey: Key.launchAtLogin) }
            LaunchAtLogin.setEnabled(newValue)
        }
    }

    var autoCollapse: Bool {
        get { access(keyPath: \.autoCollapse); return defaults.bool(forKey: Key.autoCollapse) }
        set { withMutation(keyPath: \.autoCollapse) { defaults.set(newValue, forKey: Key.autoCollapse) } }
    }

    var autoCollapseDelay: TimeInterval {
        get { access(keyPath: \.autoCollapseDelay); return defaults.double(forKey: Key.autoCollapseDelay) }
        set { withMutation(keyPath: \.autoCollapseDelay) { defaults.set(newValue, forKey: Key.autoCollapseDelay) } }
    }

    var alwaysHiddenSectionEnabled: Bool {
        get { access(keyPath: \.alwaysHiddenSectionEnabled); return defaults.bool(forKey: Key.alwaysHiddenSectionEnabled) }
        set { withMutation(keyPath: \.alwaysHiddenSectionEnabled) { defaults.set(newValue, forKey: Key.alwaysHiddenSectionEnabled) } }
    }

    var hoverToExpand: Bool {
        get { access(keyPath: \.hoverToExpand); return defaults.bool(forKey: Key.hoverToExpand) }
        set { withMutation(keyPath: \.hoverToExpand) { defaults.set(newValue, forKey: Key.hoverToExpand) } }
    }

    var separatorsHidden: Bool {
        get { access(keyPath: \.separatorsHidden); return defaults.bool(forKey: Key.separatorsHidden) }
        set { withMutation(keyPath: \.separatorsHidden) { defaults.set(newValue, forKey: Key.separatorsHidden) } }
    }

    var useFullStatusBarOnExpand: Bool {
        get { access(keyPath: \.useFullStatusBarOnExpand); return defaults.bool(forKey: Key.useFullStatusBarOnExpand) }
        set { withMutation(keyPath: \.useFullStatusBarOnExpand) { defaults.set(newValue, forKey: Key.useFullStatusBarOnExpand) } }
    }

    /// ⌃⌥⌘C — "C" for CleanMenuBar.
    ///
    /// The three-modifier form is deliberate. macOS builds its own shortcuts from
    /// ⌘, ⌃⌘, ⌥⌘ and ⇧⌘, and apps bind ⌥⌘-letter freely — ⌥⌘C is "Copy Style" in
    /// TextEdit, Pages, Keynote and Mail, and a global hot key would shadow it.
    /// ⌃⌥⌘ is left alone by both, which is why third-party tools favour it.
    ///
    /// Carbon modifier bits: cmdKey 256 | optionKey 2048 | controlKey 4096.
    static let defaultShortcut = Shortcut(keyCode: 8, modifierFlags: 6400)

    private static var defaultShortcutData: Data {
        (try? JSONEncoder().encode(defaultShortcut)) ?? Data()
    }

    var showSettingsAtLaunch: Bool {
        get { access(keyPath: \.showSettingsAtLaunch); return defaults.bool(forKey: Key.showSettingsAtLaunch) }
        set { withMutation(keyPath: \.showSettingsAtLaunch) { defaults.set(newValue, forKey: Key.showSettingsAtLaunch) } }
    }

    var restoreLastState: Bool {
        get { access(keyPath: \.restoreLastState); return defaults.bool(forKey: Key.restoreLastState) }
        set { withMutation(keyPath: \.restoreLastState) { defaults.set(newValue, forKey: Key.restoreLastState) } }
    }

    /// The state the bar was left in. Written on every change so it survives a
    /// crash or a force quit, not just a clean exit.
    var lastStateCollapsed: Bool {
        get { defaults.bool(forKey: Key.lastStateCollapsed) }
        set { defaults.set(newValue, forKey: Key.lastStateCollapsed) }
    }

    var globalShortcut: Shortcut? {
        get {
            access(keyPath: \.globalShortcut)
            guard let data = defaults.data(forKey: Key.globalShortcut) else { return nil }
            return try? JSONDecoder().decode(Shortcut.self, from: data)
        }
        set {
            withMutation(keyPath: \.globalShortcut) {
                defaults.set(newValue.flatMap { try? JSONEncoder().encode($0) }, forKey: Key.globalShortcut)
            }
        }
    }
}

/// The auto-collapse intervals Hidden Bar offers.
enum AutoCollapseDelay: Double, CaseIterable, Identifiable {
    case fiveSeconds = 5
    case tenSeconds = 10
    case fifteenSeconds = 15
    case thirtySeconds = 30
    case oneMinute = 60

    var id: Double { rawValue }
    var seconds: TimeInterval { rawValue }

    var label: String {
        // String(localized:) keeps the String Catalog's plural rules, which a
        // manual String(format:) would discard — Russian alone needs three forms.
        self == .oneMinute
            ? String(localized: "1 minute")
            : String(localized: "\(Int(rawValue)) seconds")
    }
}

/// A global keyboard shortcut, stored as raw Carbon key/modifier codes.
struct Shortcut: Codable, Equatable, Sendable {
    var keyCode: UInt32
    var modifierFlags: UInt32
}
