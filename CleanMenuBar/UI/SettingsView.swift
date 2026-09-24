import SwiftUI

/// The settings window, also shown at first launch — an accessory app otherwise
/// gives a new user no sign that anything installed.
///
/// The option set mirrors Hidden Bar's (MIT, see NOTICE).
struct SettingsView: View {
    /// Which tab to show. Bound from outside so the status item's "About" command
    /// can open this window straight onto the About tab.
    enum Tab: Hashable { case general, shortcut, howItWorks, about }

    @State private var preferences = Preferences.shared
    @Binding var selection: Tab

    var body: some View {
        TabView(selection: $selection) {
            GeneralSettingsView(preferences: preferences)
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag(Tab.general)
            ShortcutSettingsView(preferences: preferences)
                .tabItem { Label("Shortcut", systemImage: "keyboard") }
                .tag(Tab.shortcut)
            HowItWorksView()
                .tabItem { Label("How it works", systemImage: "questionmark.circle") }
                .tag(Tab.howItWorks)
            AboutView()
                .tabItem { Label("About", systemImage: "info.circle") }
                .tag(Tab.about)
        }
        .frame(width: 480, height: 560)
    }
}

struct GeneralSettingsView: View {
    /// The pink from the app icon and the site, so the one card that asks a
    /// question is recognisably part of the same product.
    static let brand = Color(red: 0.925, green: 0.282, blue: 0.600)

    @Bindable var preferences: Preferences
    @State private var language = AppLanguage.current
    @State private var languageNeedsRelaunch = false

    var body: some View {
        Form {
            // Asked once, at the only moment it makes sense: the window opens by
            // itself on first launch, and the switch it refers to is just below.
            // Consent beats a default — registering a login item unasked is what
            // App Store review objects to.
            if !preferences.loginSuggestionAnswered && !preferences.launchAtLogin {
                // No Section wrapper: a Form section draws its own grey frame,
                // and nesting the tinted card inside it put one rounded
                // rectangle around another. The card is the block.
                VStack(alignment: .leading, spacing: 12) {
                    Text("CleanMenuBar only works while it is running. Open it automatically when you log in?")
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Spacer()
                        Button("Not now") { preferences.loginSuggestionAnswered = true }
                        Button("Turn on") {
                            preferences.launchAtLogin = true
                            preferences.loginSuggestionAnswered = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Self.brand)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                // Tinted in the app's own pink rather than left in the grey
                // every other section uses: this card asks a question
                // instead of showing a setting, and should not read as one
                // more row. Kept light — a strong fill would look like an
                // error rather than an offer.
                //
                // Painted on the content, not via .listRowBackground: on
                // macOS a Form ignores that modifier, and the first attempt
                // left the card the same grey as everything around it.
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Self.brand.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Self.brand.opacity(0.40), lineWidth: 1)
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section {
                Picker("Language", selection: $language) {
                    ForEach(AppLanguage.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                if languageNeedsRelaunch {
                    HStack {
                        // Shown in the language just chosen, not the running one:
                        // the notice is about that language, and seeing it also
                        // confirms the pick was the intended one.
                        Text(language.string("CleanMenuBar has to restart to change language."))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button(language.string("Restart Now")) { AppLanguage.relaunch() }
                    }
                }
            } footer: {
                Text("Match macOS uses your Mac's language when CleanMenuBar has it, and English otherwise.")
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Launch CleanMenuBar at login", isOn: $preferences.launchAtLogin)
                Toggle("Show this window when CleanMenuBar starts",
                       isOn: $preferences.showSettingsAtLaunch)
            }

            Section {
                Toggle("Collapse automatically", isOn: $preferences.autoCollapse)
                Picker("Collapse after", selection: $preferences.autoCollapseDelay) {
                    ForEach(AutoCollapseDelay.allCases) { delay in
                        Text(delay.label).tag(delay.seconds)
                    }
                }
                .disabled(!preferences.autoCollapse)
                Toggle("Expand when hovering over the menu bar", isOn: $preferences.hoverToExpand)
            }

            Section {
                Toggle("Enable the always-hidden section", isOn: $preferences.alwaysHiddenSectionEnabled)
                Toggle("Hide the separators", isOn: $preferences.separatorsHidden)
                Toggle("Restore the last state at launch", isOn: $preferences.restoreLastState)
            } footer: {
                Text("Turning on the always-hidden section reveals it so you can ⌘-drag icons to the left of its faint separator; it hides again on the next collapse. Hiding the separators also makes them impossible to ⌘-drag, so arrange your icons first.")
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Section {
                PlannedToggle("Use the full menu bar when expanding",
                              issue: "become the active app while expanded, so its near-empty menus free the width the frontmost app's menus occupy — macOS 27 refuses the activation")
                PlannedToggle("Keep CleanMenuBar in the Dock",
                              issue: "shows a Dock icon instead of running as a menu bar-only app")
                PlannedToggle("Show a visual guide in this window",
                              issue: "the little menu bar diagram Hidden Bar draws, instead of the text on the next tab")
            } header: {
                Text("Planned")
            } footer: {
                Text("Not built yet — listed so it is clear they are coming, and so anyone who wants to pick one up knows where it belongs. See CONTRIBUTING.md.")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .onChange(of: language) { _, newValue in
            AppLanguage.select(newValue)
            // macOS binds the bundle's language at launch. Switching in place
            // would mean bypassing Bundle.main everywhere, which costs the
            // catalog's plural rules and leaves system UI in the old language.
            languageNeedsRelaunch = true
        }
        .onChange(of: preferences.alwaysHiddenSectionEnabled) { notifyController() }
        .onChange(of: preferences.separatorsHidden) { notifyController() }
        .onChange(of: preferences.hoverToExpand) { notifyController() }
        .onChange(of: preferences.useFullStatusBarOnExpand) { notifyController() }
        .onChange(of: preferences.autoCollapse) { notifyController() }
        .onChange(of: preferences.autoCollapseDelay) { notifyController() }
    }

    private func notifyController() {
        NotificationCenter.default.post(name: .cleanMenuBarPreferencesChanged, object: nil)
    }
}

/// A setting that is designed but not implemented.
///
/// Kept visible and switched off rather than hidden, so the gap is honest: users
/// can see what is coming, and contributors can see where it slots in.
struct PlannedToggle: View {
    private let title: LocalizedStringKey
    private let issue: String
    @State private var alwaysOff = false

    /// `title` must be a `LocalizedStringKey`. As a `String` the literal at the
    /// call site is invisible to the string extractor, and the row would stay in
    /// English in every translation while its badge was translated around it.
    init(_ title: LocalizedStringKey, issue: String) {
        self.title = title
        self.issue = issue
    }

    var body: some View {
        Toggle(isOn: $alwaysOff) {
            HStack(spacing: 6) {
                Text(title)
                Text("Planned")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(.quaternary))
            }
        }
        .disabled(true)
        .help(issue)
    }
}

struct ShortcutSettingsView: View {
    @Bindable var preferences: Preferences
    @State private var isRecording = false

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Toggle hidden items")
                    Spacer()
                    Button(isRecording ? String(localized: "Press keys…") : shortcutLabel) {
                        isRecording.toggle()
                    }
                    .buttonStyle(.bordered)
                    if preferences.globalShortcut != nil {
                        Button("Clear") {
                            preferences.globalShortcut = nil
                            notifyController()
                        }
                    }
                }
                if let shadowed = preferences.globalShortcut?.appConflict {
                    Label {
                        Text("This also means **\(shadowed)** stops working while CleanMenuBar is running, because a global shortcut outranks an app's own menu shortcut.")
                    } icon: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                    }
                    .font(.callout)
                }
                if let conflict = preferences.globalShortcut?.systemConflict {
                    Label {
                        Text("macOS already uses this for **\(conflict)**. Both will happen when you press it — pick another combination.")
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                    .font(.callout)
                }
            } footer: {
                Text("The shortcut works system-wide and needs no Accessibility permission, so CleanMenuBar keeps running inside the sandbox.")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .background(ShortcutRecorder(isRecording: $isRecording) { shortcut in
            preferences.globalShortcut = shortcut
            isRecording = false
            notifyController()
        })
    }

    private var shortcutLabel: String {
        guard let shortcut = preferences.globalShortcut else { return String(localized: "Set Shortcut") }
        return shortcut.displayString
    }

    private func notifyController() {
        NotificationCenter.default.post(name: .cleanMenuBarPreferencesChanged, object: nil)
    }
}

/// Captures the next key combination while recording. A local monitor is enough —
/// the window is key while the user is setting the shortcut.
struct ShortcutRecorder: NSViewRepresentable {
    @Binding var isRecording: Bool
    let onCapture: (Shortcut) -> Void

    func makeNSView(context: Context) -> NSView {
        context.coordinator.install()
        return NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.isRecording = isRecording
        context.coordinator.onCapture = onCapture
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    @MainActor
    final class Coordinator {
        var isRecording = false
        var onCapture: ((Shortcut) -> Void)?
        private var monitor: Any?

        func install() {
            guard monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self, self.isRecording else { return event }
                let carbonModifiers = event.modifierFlags.carbonFlags
                guard carbonModifiers != 0 else { return nil }  // bare keys make poor global shortcuts
                self.onCapture?(Shortcut(keyCode: UInt32(event.keyCode),
                                         modifierFlags: carbonModifiers))
                return nil
            }
        }

        deinit {
            MainActor.assumeIsolated { if let monitor { NSEvent.removeMonitor(monitor) } }
        }
    }
}

struct HowItWorksView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Setting up").font(.headline)

                stepRow("1.", "Hold **⌘** and drag the icons you want hidden so they sit to the **left** of the CleanMenuBar separator.")
                stepRow("2.", "Anything to the **right** of the separator stays visible at all times.")
                stepRow("3.", "Click the arrow to collapse or expand, or press **⌃⌥⌘C** from anywhere. Right-click the arrow or the separator for this window and the other options.")
                stepRow("4.", "Once everything is arranged, turn on **Hide the separators** to leave only the arrow on screen.")

                Divider()

                Text("macOS 27 note").font(.headline)
                Text("macOS 27 rebuilt the menu bar as a single window and drops any status item that grows to half the display width — which is what broke the technique some apps used. CleanMenuBar stays under that limit, so on a very wide display the hidden span is capped at half the narrowest screen's width.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Takes a `LocalizedStringKey`, not a `String`. With a `String` parameter the
    /// literal at the call site is invisible to the string extractor and the step
    /// would silently stay in English in every translation.
    private func stepRow(_ number: String, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(number).monospaced().foregroundStyle(.secondary)
            Text(text)
        }
    }
}
