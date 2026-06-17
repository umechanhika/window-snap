import CoreGraphics

/// マウスドラッグの状態機械。EventTap から down/drag/up を受け取り、
/// 端ゾーンでの離上時に対象ウィンドウをスナップする。
///
/// WC: WindowControlling — ウィンドウ検索・フレーム操作（テストではフェイク注入）
/// SP: ScreenProviding   — 画面情報（テストでは決定的な値を返すフェイク注入）
///
/// 重要な設計判断:
///   - 対象ウィンドウは leftMouseDown 時点で確定して保持する（drag/up 中に再取得しない）。
///   - listenOnly タップから呼ばれるので down/drag では重い AX 呼び出しをしない。
///     実際の snap（AX への set）は up のとき一度だけ行う。
///   - NSWorkspace のスペース変更監視は呼び出し側（AppDelegate）が行い cancelDrag() を呼ぶ。
///     Core を AppKit 非依存に保つため。
public final class WindowDragger<WC: WindowControlling, SP: ScreenProviding> {
    /// 「単なるクリック」と区別するための最小移動量(pt)。
    /// ジェネリック型では static stored property が使えないため computed property にしている。
    static var MOVE_THRESHOLD: CGFloat { 8 }

    private let windows: WC
    private let screens: SP
    private let preview: any SnapPreviewing

    private var dragging = false
    private var target: WC.Window?
    private var titlebarDrag = false
    private var downPointGlobal: CGPoint = .zero

    public init(windows: WC, screens: SP, preview: any SnapPreviewing) {
        self.windows = windows
        self.screens = screens
        self.preview = preview
    }

    /// EventTap からの単一窓口。
    public func handle(_ type: CGEventType, _ event: CGEvent) {
        switch type {
        case .leftMouseDown:
            beginDrag(at: event.location)
        case .leftMouseDragged:
            updateDrag(at: event.location)
        case .leftMouseUp:
            endDrag(at: event.location)
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            // Mission Control 等でタップが無効化 → プレビューを即座に片付ける（snap はしない）。
            cancelDrag()
        default:
            break
        }
    }

    /// ドラッグを中断して状態とプレビューを片付ける（snap はしない）。
    /// スペース切替・タップ無効化など外部イベントから呼ばれる。
    public func cancelDrag() {
        preview.hide()
        reset()
    }

    // MARK: - 内部状態機械（@testable import で直接テスト可能）

    func beginDrag(at p: CGPoint) {
        downPointGlobal = p
        // 対象ウィンドウを down 時点で確定。直下→失敗時 最前面 focused の2段構え。
        let window = windows.windowUnderCursor(at: p) ?? windows.frontmostFocusedWindow()
        target = window
        titlebarDrag = window.map { windows.isTitlebarHit($0, globalPoint: p) } ?? false
        dragging = true
    }

    /// ドラッグ中: 現在のゾーンに応じてスナップ先プレビューを出す（軽い計算のみ）。
    func updateDrag(at p: CGPoint) {
        guard dragging, titlebarDrag else { return }
        guard let (zone, screen) = zoneAndScreen(at: p) else { preview.hide(); return }
        let rect = Geometry.snapRect(
            for: zone,
            visibleFrameCocoa: screens.visibleFrameCocoa(of: screen),
            primaryHeight: screens.primaryHeight
        )
        preview.show(rectCGGlobal: rect)
    }

    func endDrag(at p: CGPoint) {
        defer { reset() }
        preview.hide()
        guard dragging, titlebarDrag, let window = target else { return }

        // 移動量が小さい（≒クリック）なら誤爆防止で snap しない。
        let dx = p.x - downPointGlobal.x
        let dy = p.y - downPointGlobal.y
        guard (dx * dx + dy * dy).squareRoot() >= WindowDragger.MOVE_THRESHOLD else { return }

        guard let (zone, screen) = zoneAndScreen(at: p) else { return }
        let rect = Geometry.snapRect(
            for: zone,
            visibleFrameCocoa: screens.visibleFrameCocoa(of: screen),
            primaryHeight: screens.primaryHeight
        )
        windows.setFrame(window, position: rect.origin, size: rect.size)
    }

    /// カーソル位置(CG global)から (ゾーン, 画面) を返す。端に達していなければ nil。
    private func zoneAndScreen(at p: CGPoint) -> (SnapZone, SP.Screen)? {
        guard let screen = screens.screenContainingCursorGlobal(p) else { return nil }
        let frameGlobal = screens.frameCGGlobal(of: screen)
        guard let zone = SnapZone.zone(forCursorGlobal: p, screenFrameGlobal: frameGlobal) else { return nil }
        return (zone, screen)
    }

    private func reset() {
        dragging = false
        target = nil
        titlebarDrag = false
    }
}
