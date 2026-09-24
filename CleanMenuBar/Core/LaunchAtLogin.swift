import ServiceManagement
import OSLog

/// Launch-at-login, via `SMAppService`. Works inside the App Sandbox and needs
/// no helper bundle or entitlement.
enum LaunchAtLogin {
    private static let logger = Logger(subsystem: "com.monobit.CleanMenuBar", category: "LaunchAtLogin")

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            logger.error("could not \(enabled ? "register" : "unregister") login item: \(error.localizedDescription)")
        }
    }
}
