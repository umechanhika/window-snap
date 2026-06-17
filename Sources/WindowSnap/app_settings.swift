import Foundation
import ServiceManagement

/// アプリ設定の読み書き。UserDefaults と SMAppService を一元管理する。
final class AppSettings {
    static let shared = AppSettings()
    private init() {}

    private let defaults = UserDefaults.standard
    private static let enabledKey = "isEnabled"

    /// スナップ機能の有効/無効。デフォルト true（初回起動時はキーが無いので true を返す）。
    var isEnabled: Bool {
        get {
            guard defaults.object(forKey: Self.enabledKey) != nil else { return true }
            return defaults.bool(forKey: Self.enabledKey)
        }
        set { defaults.set(newValue, forKey: Self.enabledKey) }
    }

    /// ログイン時起動の登録状態。SMAppService から読み取る。
    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                NSLog("WindowSnap: SMAppService %@ 失敗: %@",
                      newValue ? "register" : "unregister", error.localizedDescription)
            }
        }
    }
}
