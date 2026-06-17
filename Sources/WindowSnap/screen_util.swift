import Cocoa
import WindowSnapCore

/// NSScreen を使った ScreenProviding の具象実装。
/// テスト時は FakeScreenProvider に差し替える。
struct SystemScreenProvider: ScreenProviding {
    typealias Screen = NSScreen

    var primaryHeight: CGFloat {
        NSScreen.screens.first?.frame.height ?? 0
    }

    /// カーソル(CG global)がどの画面上にあるかを返す。
    ///
    /// 注意: `NSScreen.main` は「キーウィンドウのある画面」であってカーソルのいる画面ではない。
    /// そのため frame.contains で自前判定する。どの画面にも入らなければ main にフォールバック。
    func screenContainingCursorGlobal(_ pCG: CGPoint) -> NSScreen? {
        let ph = primaryHeight
        let cocoa = Geometry.cgGlobalToCocoa(pCG, primaryHeight: ph)
        if let hit = NSScreen.screens.first(where: { $0.frame.contains(cocoa) }) {
            return hit
        }
        return NSScreen.main
    }

    /// 画面全体の frame を CG global(左上原点) で返す。ゾーン判定（端への到達）に使う。
    func frameCGGlobal(of screen: NSScreen) -> CGRect {
        Geometry.cocoaRectToCGGlobal(screen.frame, primaryHeight: primaryHeight)
    }

    /// menubar/Dock を除いた可視領域（Cocoa）。スナップ先のサイズ計算に使う。
    func visibleFrameCocoa(of screen: NSScreen) -> CGRect {
        screen.visibleFrame
    }
}
