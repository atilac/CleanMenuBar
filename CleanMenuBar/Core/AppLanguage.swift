import Foundation
import AppKit

/// The language the app runs in.
///
/// macOS resolves an app's language at launch from `AppleLanguages`, so changing
/// it means writing that key and relaunching — there is no supported way to swap
/// a running app's bundle language underneath SwiftUI.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case portugueseBrazil = "pt-BR"
    case spanish = "es-ES"
    case french = "fr"
    case german = "de"
    case japanese = "ja"
    case chineseSimplified = "zh-Hans"
    case chineseTraditional = "zh-Hant"
    case russian = "ru"

    var id: String { rawValue }

    var label: String {
        switch self {
        // Each language names itself, the way macOS lists languages: someone
        // looking for their own language should not have to read English first.
        case .system: return String(localized: "Match macOS")
        case .english: return "English"
        case .portugueseBrazil: return "Português (Brasil)"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .japanese: return "日本語"
        case .chineseSimplified: return "简体中文"
        case .chineseTraditional: return "繁體中文"
        case .russian: return "Русский"
        }
    }

    /// Looks a string up in *this* language rather than the running one.
    ///
    /// A deliberate, contained exception. Routing the whole app around
    /// `Bundle.main` is what makes live switching expensive — it discards the
    /// catalog's plural rules and leaves system UI in the old language — but the
    /// restart notice is about the language just chosen, so showing it in the
    /// outgoing one reads as a contradiction. Two strings, one lookup.
    func string(_ key: String) -> String {
        guard let path = Bundle.main.path(forResource: resolvedCode, ofType: "lproj"),
              let bundle = Bundle(path: path)
        else { return Bundle.main.localizedString(forKey: key, value: key, table: nil) }
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }

    /// The `.lproj` this option resolves to.
    ///
    /// `.system` cannot use `Bundle.main.preferredLocalizations`: that reports
    /// what was resolved at launch, which already includes any override this app
    /// wrote, so asking it while running in a forced language answers with that
    /// forced language. The snapshot above holds the real answer, captured when
    /// nothing was being forced.
    private var resolvedCode: String {
        guard self == .system else { return rawValue }
        return UserDefaults.standard.string(forKey: Self.snapshotKey)
            ?? Bundle.main.preferredLocalizations.first
            ?? "en"
    }

    /// macOS reads this at launch to decide the bundle's language.
    private static let key = "AppleLanguages"
    /// Our own record of whether *we* forced a language. Needed because
    /// `UserDefaults` answers `AppleLanguages` from the global domain when the
    /// app has not set it, so that key can never be used to tell the two apart.
    private static let overrideKey = "forcedLanguage"
    private static let snapshotKey = "systemLanguageSnapshot"

    /// Records what macOS resolves to while no override of ours is in place.
    ///
    /// Reading the system's own language list directly means reaching into the
    /// global preferences domain, which lives outside the sandbox container. On
    /// macOS 27 that raises "CleanMenuBar tried to access your data from other
    /// apps" — a privacy warning shown to every user, for a cosmetic detail, and
    /// one that contradicts what this app promises.
    ///
    /// So instead: whenever the app launches with no override, whatever it
    /// resolved to *is* the system's answer. Remember it, in our own container.
    /// It refreshes on every unforced launch, so changing the macOS language
    /// updates it the next time the user is not overriding anything.
    static func refreshSystemSnapshot() {
        guard UserDefaults.standard.string(forKey: overrideKey) == nil,
              let resolved = Bundle.main.preferredLocalizations.first
        else { return }
        UserDefaults.standard.set(resolved, forKey: snapshotKey)
    }

    /// The language currently forced, or `.system` when following macOS.
    static var current: AppLanguage {
        guard let forced = UserDefaults.standard.string(forKey: overrideKey) else { return .system }
        return AppLanguage(rawValue: forced) ?? .system
    }

    static func select(_ language: AppLanguage) {
        if language == .system {
            UserDefaults.standard.removeObject(forKey: key)
            UserDefaults.standard.removeObject(forKey: overrideKey)
        } else {
            UserDefaults.standard.set([language.rawValue], forKey: key)
            UserDefaults.standard.set(language.rawValue, forKey: overrideKey)
        }
        UserDefaults.standard.synchronize()
    }

    /// Relaunches the app so the new language takes effect.
    @MainActor
    static func relaunch() {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL,
                                           configuration: configuration) { _, _ in
            Task { @MainActor in NSApp.terminate(nil) }
        }
    }
}
