import AppKit

@main
enum CleanMenuBarMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: StatusBarController?
    private var hotKeys: HotKeyManager?
    private var signalSource: (any DispatchSourceSignal)?
    private var diagnosticsSource: (any DispatchSourceSignal)?
    private var alwaysHiddenSource: (any DispatchSourceSignal)?
    private var reloadSource: (any DispatchSourceSignal)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Before anything can force a language, record what macOS chose on its own.
        AppLanguage.refreshSystemSnapshot()

        let preferences = Preferences.shared

        // The stored preference and the system's login-item registration can
        // disagree: the default is on, but nothing registers it, and a user who
        // removes the item in System Settings leaves the switch showing on.
        // Reconciling at launch makes the switch tell the truth.
        if preferences.launchAtLogin != LaunchAtLogin.isEnabled {
            LaunchAtLogin.setEnabled(preferences.launchAtLogin)
        }
        let controller = StatusBarController(preferences: preferences)
        self.controller = controller

        let hotKeys = HotKeyManager()
        hotKeys.register(preferences.globalShortcut) { [weak controller] in
            controller?.toggle()
        }
        self.hotKeys = hotKeys

        NotificationCenter.default.addObserver(
            forName: .cleanMenuBarPreferencesChanged, object: nil, queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                controller.preferencesChanged()
                hotKeys.register(preferences.globalShortcut) { [weak controller] in
                    controller?.toggle()
                }
            }
        }

        // Without this an accessory app gives a new user no sign it installed.
        if preferences.showSettingsAtLaunch {
            // CMB_OPEN_TAB opens straight onto one tab. The settings window has no
            // scriptable interface, so this is how a given tab gets inspected.
            let tab: SettingsView.Tab = switch ProcessInfo.processInfo.environment["CMB_OPEN_TAB"] {
            case "about": .about
            case "shortcut": .shortcut
            case "howitworks": .howItWorks
            default: .general
            }
            SettingsWindowController.shared.show(tab: tab)
        }

        installDebugToggleSignal(controller)
        installDiagnosticsSignal(controller, preferences)
        installAlwaysHiddenSignal(controller)
        installReloadSignal(controller)
    }

    /// `kill -USR1 <pid>` toggles the bar. The menu bar cannot be driven by UI
    /// automation, so this is how the behaviour gets exercised from a script.
    private func installDebugToggleSignal(_ controller: StatusBarController) {
        let source = DispatchSource.makeSignalSource(signal: SIGUSR1, queue: .main)
        source.setEventHandler { [weak controller] in
            guard let controller else { return }
            controller.toggle()
            print("SIGUSR1 -> state=\(controller.state)")
            fflush(stdout)
        }
        source.resume()
        signalSource = source
        signal(SIGUSR1, SIG_IGN)
    }

    /// `kill -USR2 <pid>` dumps what is actually in effect — not what is stored in
    /// preferences, but what the status bar and the app are really doing. Used to
    /// verify each setting end to end.
    private func installDiagnosticsSignal(_ controller: StatusBarController,
                                          _ preferences: Preferences) {
        let source = DispatchSource.makeSignalSource(signal: SIGUSR2, queue: .main)
        source.setEventHandler { [weak controller] in
            guard let controller else { return }
            print("DIAG \(controller.diagnostics())")
            print("DIAG localizations=\(Bundle.main.localizations.sorted()) "
                  + "chosen=\(Bundle.main.preferredLocalizations) "
                  + "sample=\(String(localized: "Quit"))")
            print("DIAG activationPolicy=\(NSApp.activationPolicy().rawValue) "
                  + "isActive=\(NSApp.isActive) "
                  + "frontmost=\(NSWorkspace.shared.frontmostApplication?.localizedName ?? "?") "
                  + "settingsWindowVisible=\(SettingsWindowController.shared.isVisible) "
                  + "loginItem=\(LaunchAtLogin.isEnabled) "
                  + "shortcut=\(preferences.globalShortcut?.displayString ?? "none") "
                  + "hotKeyRegistered=\(self.hotKeys?.isRegistered ?? false)")
            fflush(stdout)
        }
        source.resume()
        diagnosticsSource = source
        signal(SIGUSR2, SIG_IGN)
    }

    /// `kill -INFO <pid>` toggles the always-hidden section. Reaching it normally
    /// means right-clicking a menu bar item, which no script can do.
    private func installAlwaysHiddenSignal(_ controller: StatusBarController) {
        let source = DispatchSource.makeSignalSource(signal: SIGINFO, queue: .main)
        source.setEventHandler { [weak controller] in
            guard let controller else { return }
            controller.toggleAlwaysHiddenSection()
            print("SIGINFO -> state=\(controller.state)")
            fflush(stdout)
        }
        source.resume()
        alwaysHiddenSource = source
        signal(SIGINFO, SIG_IGN)
    }

    /// `kill -HUP <pid>` re-reads preferences, the Unix convention for reload.
    /// Also stops SIGHUP from killing the app, which is its default action.
    private func installReloadSignal(_ controller: StatusBarController) {
        let source = DispatchSource.makeSignalSource(signal: SIGHUP, queue: .main)
        source.setEventHandler { [weak controller] in
            controller?.preferencesChanged()
            print("SIGHUP -> preferences reloaded")
            fflush(stdout)
        }
        source.resume()
        reloadSource = source
        signal(SIGHUP, SIG_IGN)
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }
}
