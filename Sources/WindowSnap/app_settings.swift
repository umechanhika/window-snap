import Foundation
import ServiceManagement

/// アプリ設定の読み書き。UserDefaults と SMAppService を一元管理する。
final class AppSettings {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard
    private static let enabledKey = "isEnabled"

    /// スナップ機能の有効/無効。インメモリキャッシュ経由で読み書きする。
    /// EventTap コールバック（メインスレッド）と UI 操作（メインスレッド）の両方から
    /// 同一スレッドでアクセスするため、スレッドセーフ上の問題はない。
    private(set) var isEnabled: Bool

    private init() {
        // 起動時は UserDefaults から初期値を読む（キー未存在なら true）。
        let stored = defaults.object(forKey: Self.enabledKey)
        isEnabled = stored != nil ? defaults.bool(forKey: Self.enabledKey) : true
    }

    func setEnabled(_ value: Bool) {
        isEnabled = value                             // インメモリ即時反映
        defaults.set(value, forKey: Self.enabledKey) // 永続化
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
