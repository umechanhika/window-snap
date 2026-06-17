import CoreGraphics
@testable import WindowSnapCore

// MARK: - FakeWindow

/// テスト用ウィンドウトークン。AXUIElement の代替として使う。
final class FakeWindow {
    let id: Int
    init(_ id: Int = 0) { self.id = id }
}

// MARK: - FakeWindowController

/// WindowControlling のフェイク実装。戻り値・挙動を外から制御し、呼び出しを記録する。
final class FakeWindowController: WindowControlling {
    typealias Window = FakeWindow

    /// windowUnderCursor / frontmostFocusedWindow が返すウィンドウ。nil で「ウィンドウなし」。
    var stubWindow: FakeWindow? = FakeWindow(1)
    /// isTitlebarHit の戻り値。
    var stubTitlebarHit: Bool = true
    /// setFrame の呼び出し履歴。
    var setFrameCalls: [(position: CGPoint, size: CGSize)] = []

    func windowUnderCursor(at globalPoint: CGPoint) -> FakeWindow? { stubWindow }
    func frontmostFocusedWindow() -> FakeWindow? { stubWindow }
    func isTitlebarHit(_ window: FakeWindow, globalPoint: CGPoint) -> Bool { stubTitlebarHit }
    func setFrame(_ window: FakeWindow, position: CGPoint, size: CGSize) {
        setFrameCalls.append((position: position, size: size))
    }
}

// MARK: - FakeScreenProvider

/// ScreenProviding のフェイク実装。決定的な画面フレームを返す。
/// Screen の型は CGRect（CG global フレームそのものをスクリーン識別子として使う）。
struct FakeScreenProvider: ScreenProviding {
    typealias Screen = CGRect

    /// このプロバイダが返す画面の CG global フレーム（1920×1080 相当）。
    var screenFrameCGGlobal: CGRect
    /// visibleFrame（Cocoa 座標。menubar/Dock 除外済み）。
    var visibleFrame: CGRect
    var primaryHeight: CGFloat

    init(
        screenFrameCGGlobal: CGRect = CGRect(x: 0, y: 0, width: 1920, height: 1080),
        visibleFrame: CGRect = CGRect(x: 0, y: 24, width: 1920, height: 1032),
        primaryHeight: CGFloat = 1080
    ) {
        self.screenFrameCGGlobal = screenFrameCGGlobal
        self.visibleFrame = visibleFrame
        self.primaryHeight = primaryHeight
    }

    func screenContainingCursorGlobal(_ p: CGPoint) -> CGRect? {
        screenFrameCGGlobal.contains(p) ? screenFrameCGGlobal : nil
    }

    func frameCGGlobal(of screen: CGRect) -> CGRect { screen }
    func visibleFrameCocoa(of screen: CGRect) -> CGRect { visibleFrame }
}

// MARK: - FakePreview

/// SnapPreviewing のフェイク実装。show/hide の呼び出しを記録する。
final class FakePreview: SnapPreviewing {
    var showCalls: [CGRect] = []
    var hideCalls = 0
    var isVisible = false

    func show(rectCGGlobal rect: CGRect) {
        showCalls.append(rect)
        isVisible = true
    }

    func hide() {
        hideCalls += 1
        isVisible = false
    }
}
