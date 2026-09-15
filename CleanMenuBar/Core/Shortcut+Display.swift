import AppKit
import Carbon.HIToolbox

extension NSEvent.ModifierFlags {
    /// Carbon's modifier bits, which is what `RegisterEventHotKey` expects.
    var carbonFlags: UInt32 {
        var result: UInt32 = 0
        if contains(.command) { result |= UInt32(cmdKey) }
        if contains(.option) { result |= UInt32(optionKey) }
        if contains(.control) { result |= UInt32(controlKey) }
        if contains(.shift) { result |= UInt32(shiftKey) }
        return result
    }
}

extension Shortcut {
    /// The combination as a person reads it, e.g. `⌃⌥⌘H`.
    var displayString: String {
        var result = ""
        if modifierFlags & UInt32(controlKey) != 0 { result += "⌃" }
        if modifierFlags & UInt32(optionKey) != 0 { result += "⌥" }
        if modifierFlags & UInt32(shiftKey) != 0 { result += "⇧" }
        if modifierFlags & UInt32(cmdKey) != 0 { result += "⌘" }
        return result + Self.keyName(for: keyCode)
    }

    /// Reads the character the key produces under the user's current layout, so a
    /// non-US keyboard does not show the wrong letter.
    private static func keyName(for keyCode: UInt32) -> String {
        guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
              let pointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        else { return "?" }

        let data = Unmanaged<CFData>.fromOpaque(pointer).takeUnretainedValue() as Data
        var deadKeyState: UInt32 = 0
        var length = 0
        var characters = [UniChar](repeating: 0, count: 4)

        let status = data.withUnsafeBytes { buffer -> OSStatus in
            guard let layout = buffer.bindMemory(to: UCKeyboardLayout.self).baseAddress else {
                return OSStatus(paramErr)
            }
            return UCKeyTranslate(layout, UInt16(keyCode), UInt16(kUCKeyActionDisplay), 0,
                                  UInt32(LMGetKbdType()), OptionBits(kUCKeyTranslateNoDeadKeysBit),
                                  &deadKeyState, characters.count, &length, &characters)
        }
        guard status == noErr, length > 0 else { return "?" }
        return String(utf16CodeUnits: characters, count: length).uppercased()
    }
}

extension Shortcut {
    /// Combinations macOS already claims system-wide.
    ///
    /// `RegisterEventHotKey` happily accepts these, but the system keeps handling
    /// them too, so both actions fire at once — ⌥⌘H, for instance, toggles the
    /// hidden items *and* runs Hide Others. Warn rather than block: the reserved
    /// set varies with a user's own System Settings, so a hard refusal would be
    /// wrong as often as it was right.
    var systemConflict: String? {
        let cmd = modifierFlags & UInt32(cmdKey) != 0
        let option = modifierFlags & UInt32(optionKey) != 0
        let control = modifierFlags & UInt32(controlKey) != 0
        let shift = modifierFlags & UInt32(shiftKey) != 0

        switch (keyCode, cmd, option, control, shift) {
        case (4, true, true, _, _):    return String(localized: "Hide Others")
        case (4, true, false, false, false): return String(localized: "Hide the current app")
        case (12, true, _, _, _):      return String(localized: "Quit the current app")
        case (13, true, _, _, _):      return String(localized: "Close Window")
        case (48, true, _, _, _):      return String(localized: "Switch apps")
        case (49, true, false, false, false): return String(localized: "Spotlight")
        case (49, true, true, _, _):   return String(localized: "Character Viewer")
        case (53, _, _, _, _):         return String(localized: "Escape")
        case (0x7E, _, _, true, _), (0x7D, _, _, true, _): return String(localized: "Mission Control")
        default: return nil
        }
    }

    /// Combinations the system leaves alone but that apps commonly bind. A global
    /// hot key outranks an app's own menu shortcut, so this one quietly stops
    /// working inside those apps — worth saying, but not worth refusing.
    var appConflict: String? {
        let cmd = modifierFlags & UInt32(cmdKey) != 0
        let option = modifierFlags & UInt32(optionKey) != 0
        let control = modifierFlags & UInt32(controlKey) != 0
        guard cmd, option, !control else { return nil }
        switch keyCode {
        case 8:  return String(localized: "Copy Style (TextEdit, Pages, Keynote, Mail)")
        case 9:  return String(localized: "Paste Style (TextEdit, Pages, Keynote, Mail)")
        default: return nil
        }
    }
}

extension Notification.Name {
    /// Posted when settings change in a way the status bar has to react to.
    static let cleanMenuBarPreferencesChanged = Notification.Name("CleanMenuBarPreferencesChanged")
}
