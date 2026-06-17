import Cocoa

/// メニューバー常駐アイコン。有効/無効・ログイン時起動・アクセシビリティ・終了を提供する。
/// （Dock 非表示の .accessory アプリなので、ユーザーが触れる唯一の UI）
final class StatusItem: NSObject {
    private let item: NSStatusItem
    private var enabledMenuItem: NSMenuItem?
    private var launchAtLoginMenuItem: NSMenuItem?

    /// 有効/無効が切り替わったときに AppDelegate へ通知する。
    var onEnabledChanged: ((Bool) -> Void)?

    override init() {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if let button = item.button {
            button.image = NSImage(systemSymbolName: "rectangle.split.2x1",
                                   accessibilityDescription: "WindowSnap")
            button.image?.isTemplate = true
        }

        let menu = NSMenu()

        let header = menu.addItem(withTitle: "WindowSnap", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(.separator())

        let enabled = NSMenuItem(
            title: "有効",
            action: #selector(toggleEnabled),
            keyEquivalent: "")
        enabled.target = self
        enabled.state = AppSettings.shared.isEnabled ? .on : .off
        menu.addItem(enabled)
        enabledMenuItem = enabled

        let launch = NSMenuItem(
            title: "ログイン時に起動",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: "")
        launch.target = self
        launch.state = AppSettings.shared.launchAtLogin ? .on : .off
        menu.addItem(launch)
        launchAtLoginMenuItem = launch

        menu.addItem(.separator())

        let accessibility = menu.addItem(
            withTitle: "アクセシビリティ設定を開く",
            action: #selector(openAccessibility),
            keyEquivalent: "")
        accessibility.target = self

        menu.addItem(.separator())

        let quit = menu.addItem(
            withTitle: "WindowSnap を終了",
            action: #selector(quit),
            keyEquivalent: "q")
        quit.target = self

        item.menu = menu
    }

    @objc private func toggleEnabled() {
        let newValue = !AppSettings.shared.isEnabled
        AppSettings.shared.isEnabled = newValue
        enabledMenuItem?.state = newValue ? .on : .off
        onEnabledChanged?(newValue)
    }

    @objc private func toggleLaunchAtLogin() {
        let newValue = !AppSettings.shared.launchAtLogin
        AppSettings.shared.launchAtLogin = newValue
        // SMAppService の実際の状態で checkmark を更新（register 失敗時を考慮）
        launchAtLoginMenuItem?.state = AppSettings.shared.launchAtLogin ? .on : .off
    }

    /// 「システム設定 → プライバシーとセキュリティ → アクセシビリティ」を直接開く。
    @objc private func openAccessibility() {
        guard let url = URL(string:
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
