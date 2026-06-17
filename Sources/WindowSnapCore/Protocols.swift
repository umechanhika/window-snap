import CoreGraphics

/// ウィンドウの検索・フレーム操作を抽象化。
/// テストでは FakeWindowController を注入し、AX 呼び出しを排除する。
public protocol WindowControlling {
    associatedtype Window
    func windowUnderCursor(at globalPoint: CGPoint) -> Window?
    func frontmostFocusedWindow() -> Window?
    func isTitlebarHit(_ window: Window, globalPoint: CGPoint) -> Bool
    func setFrame(_ window: Window, position: CGPoint, size: CGSize)
}

/// 画面列挙・カーソル位置特定・フレーム取得を抽象化。
/// primaryHeight は Geometry の Y 反転に必要（NSScreen 依存を Core から排除する橋渡し）。
public protocol ScreenProviding {
    associatedtype Screen
    /// カーソル(CG global)が乗っている画面を返す。どの画面にも乗っていなければ nil。
    func screenContainingCursorGlobal(_ p: CGPoint) -> Screen?
    /// 画面全体の CG global 矩形（ゾーン到達判定に使う）。
    func frameCGGlobal(of screen: Screen) -> CGRect
    /// menubar/Dock を除いた可視領域（Cocoa 座標・スナップ先矩形の算出に使う）。
    func visibleFrameCocoa(of screen: Screen) -> CGRect
    /// メイン画面の高さ(pt)。Cocoa ↔ CG global の Y 反転に使う。
    var primaryHeight: CGFloat { get }
}

/// スナップ先プレビューオーバーレイを抽象化。
/// テストでは FakePreview を注入して show/hide の呼び出しを検証する。
public protocol SnapPreviewing: AnyObject {
    func show(rectCGGlobal rect: CGRect)
    func hide()
}
