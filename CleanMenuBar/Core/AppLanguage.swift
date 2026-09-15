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
    /// For `.system` that has to be worked out from the *system's* language list,
    /// not from `Bundle.main.preferredLocalizations`: the latter reports what was
    /// resolved at launch, which already includes any override this app itself
    /// wrote. Reading it while running in a forced language would answer with that
    /// language instead of the one macOS would actually choose.
    private var resolvedCode: String {
        guard self == .system else { return rawValue }
        let systemPreferences = UserDefaults.standard
            .persistentDomain(forName: UserDefaults.globalDomain)?[Self.key] as? [String]
            ?? ["en"]
        return Bundle.preferredLocalizations(from: Bundle.main.localizations,
                                             forPreferences: systemPreferences).first ?? "en"
    }

    private static let key = "AppleLanguages"

    /// The language currently forced, or `.system` when following macOS.
    static var current: AppLanguage {
        guard let forced = UserDefaults.standard.stringArray(forKey: key)?.first else { return .system }
        return AppLanguage(rawValue: forced)
            // A stored "pt-BR" can come back canonicalised, so match on the prefix.
            ?? AppLanguage.allCases.first { $0 != .system && forced.hasPrefix($0.rawValue.prefix(2)) }
            ?? .system
    }

    static func select(_ language: AppLanguage) {
        if language == .system {
            UserDefaults.standard.removeObject(forKey: key)
        } else {
            UserDefaults.standard.set([language.rawValue], forKey: key)
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
