import AppKit
import Carbon.HIToolbox
import OSLog

/// Registers the global shortcut that toggles the hidden section.
///
/// Uses Carbon's `RegisterEventHotKey`, which — unlike a `CGEventTap` — needs no
/// Accessibility permission and is allowed inside the App Sandbox. That matters:
/// it keeps the app shippable on the Mac App Store.
@MainActor
final class HotKeyManager {
    private static let signature = OSType(0x434D4252)  // 'CMBR'

    private let logger = Logger(subsystem: "com.atilac.CleanMenuBar", category: "HotKey")
    // Opaque Carbon pointers. They are only ever touched on the main actor plus
    // once from deinit, which Swift 6 cannot prove — hence the explicit opt-out.
    private nonisolated(unsafe) var hotKeyRef: EventHotKeyRef?
    private nonisolated(unsafe) var eventHandler: EventHandlerRef?
    private var onTrigger: (() -> Void)?

    var isRegistered: Bool { hotKeyRef != nil }

    init() { installHandler() }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let eventHandler { RemoveEventHandler(eventHandler) }
    }

    /// Replaces any previously registered shortcut. Pass `nil` to clear it.
    func register(_ shortcut: Shortcut?, onTrigger: @escaping () -> Void) {
        self.onTrigger = onTrigger

        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        guard let shortcut else { return }

        var ref: EventHotKeyRef?
        let id = EventHotKeyID(signature: Self.signature, id: 1)
        let status = RegisterEventHotKey(shortcut.keyCode, shortcut.modifierFlags, id,
                                         GetApplicationEventTarget(), 0, &ref)
        guard status == noErr else {
            logger.error("RegisterEventHotKey failed: \(status)")
            return
        }
        hotKeyRef = ref
    }

    private func installHandler() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        let context = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            guard let userData else { return noErr }
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            MainActor.assumeIsolated { manager.onTrigger?() }
            return noErr
        }, 1, &spec, context, &eventHandler)
    }
}
