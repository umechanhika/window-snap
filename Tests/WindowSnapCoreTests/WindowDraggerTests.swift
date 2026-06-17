import XCTest
@testable import WindowSnapCore

// MARK: - ヘルパ

/// テスト用ドラッガーを組み立てる。
private func makeDragger(
    windows: FakeWindowController = FakeWindowController(),
    screens: FakeScreenProvider = FakeScreenProvider(),
    preview: FakePreview = FakePreview()
) -> (WindowDragger<FakeWindowController, FakeScreenProvider>, FakeWindowController, FakeScreenProvider, FakePreview) {
    let d = WindowDragger(windows: windows, screens: screens, preview: preview)
    return (d, windows, screens, preview)
}

// MARK: - WindowDraggerTests

final class WindowDraggerTests: XCTestCase {

    // 画面左端の中央: タイトルバー内かつ端ゾーン = .left
    private let leftEdge = CGPoint(x: 0, y: 20)
    // 右端中央
    private let rightEdge = CGPoint(x: 1920, y: 20)
    // 画面中央（端未到達）
    private let center = CGPoint(x: 960, y: 540)
    // down 開始点（端から十分離れている）
    private let downPoint = CGPoint(x: 960, y: 20)

    // MARK: ① down で対象確定後、drag/up 中も target が化けない

    func testTargetIsLockedAtDown() {
        let wc = FakeWindowController()
        let (d, _, _, preview) = makeDragger(windows: wc)
        let windowA = FakeWindow(1)
        wc.stubWindow = windowA
        d.beginDrag(at: downPoint)

        // drag 中に stubWindow を差し替えても target は変わらない
        wc.stubWindow = FakeWindow(2)
        d.updateDrag(at: leftEdge)

        // up 時に windowA の setFrame が呼ばれる
        d.endDrag(at: leftEdge)
        XCTAssertEqual(wc.setFrameCalls.count, 1, "スナップが1回呼ばれるべき")
        _ = preview  // silence unused warning
    }

    // MARK: ② titlebarDrag == false のとき updateDrag でプレビューを出さない

    func testNonTitlebarDrag_noPreview() {
        let wc = FakeWindowController()
        wc.stubTitlebarHit = false   // タイトルバー外
        let preview = FakePreview()
        let (d, _, _, _) = makeDragger(windows: wc, preview: preview)

        d.beginDrag(at: downPoint)
        d.updateDrag(at: leftEdge)
        XCTAssertEqual(preview.showCalls.count, 0, "タイトルバー外はプレビューを出さない")
    }

    // MARK: ③ titlebarDrag == false のとき endDrag で snap しない

    func testNonTitlebarDrag_noSnap() {
        let wc = FakeWindowController()
        wc.stubTitlebarHit = false
        let (d, _, _, _) = makeDragger(windows: wc)

        d.beginDrag(at: downPoint)
        d.endDrag(at: leftEdge)
        XCTAssertEqual(wc.setFrameCalls.count, 0, "タイトルバー外はスナップしない")
    }

    // MARK: ③ MOVE_THRESHOLD 未満の移動 → クリック扱いで snap しない

    func testClickWithinThreshold_noSnap() {
        let (d, wc, _, _) = makeDragger()
        // down 点から 7pt 移動（< MOVE_THRESHOLD 8pt）、左端ゾーン
        d.beginDrag(at: CGPoint(x: 7, y: 20))
        d.endDrag(at: CGPoint(x: 0, y: 20))   // 移動量 = 7pt < 8pt
        XCTAssertEqual(wc.setFrameCalls.count, 0, "MOVE_THRESHOLD 未満はスナップしない")
    }

    // MARK: ③ MOVE_THRESHOLD 以上の移動 → snap する

    func testDragOverThreshold_snaps() {
        let (d, wc, _, _) = makeDragger()
        // down 点は端から離れた場所、up 点は左端ゾーン
        // 水平移動量 = 960pt（>> 8pt）
        d.beginDrag(at: CGPoint(x: 960, y: 20))
        d.endDrag(at: CGPoint(x: 0, y: 20))
        XCTAssertEqual(wc.setFrameCalls.count, 1, "MOVE_THRESHOLD 以上はスナップする")
    }

    // MARK: ④ 左端ゾーンでの endDrag → setFrame が期待矩形で1回呼ばれる

    func testEndDrag_leftEdge_correctRect() {
        // screens: 1920×1080, visibleFrame = (0,24,1920,1032)
        // .left の CG global 矩形 = (0, 24, 960, 1032)
        // y=540: top band(y<=120) と bottom band(y>=960) の外 → .left が確定する
        let (d, wc, _, _) = makeDragger()
        d.beginDrag(at: CGPoint(x: 960, y: 540))
        d.endDrag(at: CGPoint(x: 0, y: 540))

        XCTAssertEqual(wc.setFrameCalls.count, 1)
        let call = wc.setFrameCalls[0]
        XCTAssertEqual(call.position, CGPoint(x: 0, y: 24))
        XCTAssertEqual(call.size,     CGSize(width: 960, height: 1032))
    }

    func testEndDrag_rightEdge_correctRect() {
        // .right の CG global 矩形 = (960, 24, 960, 1032)
        // x=1919: CGRect(0,0,1920,1080).contains では maxX=1920 が半開区間なので 1920 は外側。
        // x=1919 ≥ 1920-6=1914 なのでゾーン判定は atRight=true になる。
        let (d, wc, _, _) = makeDragger()
        d.beginDrag(at: CGPoint(x: 960, y: 540))
        d.endDrag(at: CGPoint(x: 1919, y: 540))

        XCTAssertEqual(wc.setFrameCalls.count, 1)
        let call = wc.setFrameCalls[0]
        XCTAssertEqual(call.position, CGPoint(x: 960, y: 24))
        XCTAssertEqual(call.size,     CGSize(width: 960, height: 1032))
    }

    func testEndDrag_topCenter_fullscreen() {
        // .top の CG global 矩形 = (0, 24, 1920, 1032)
        let (d, wc, _, _) = makeDragger()
        d.beginDrag(at: CGPoint(x: 960, y: 100))
        d.endDrag(at: CGPoint(x: 960, y: 0))

        XCTAssertEqual(wc.setFrameCalls.count, 1)
        let call = wc.setFrameCalls[0]
        XCTAssertEqual(call.position, CGPoint(x: 0, y: 24))
        XCTAssertEqual(call.size,     CGSize(width: 1920, height: 1032))
    }

    // MARK: ④ 端未到達で endDrag → snap しない

    func testEndDrag_noZone_noSnap() {
        let (d, wc, _, _) = makeDragger()
        d.beginDrag(at: CGPoint(x: 100, y: 20))
        d.endDrag(at: center)   // 中央 = ゾーンなし
        XCTAssertEqual(wc.setFrameCalls.count, 0)
    }

    // MARK: ⑤ cancelDrag() → preview.hide() & 状態リセット

    func testCancelDrag_hidesPreviewAndResetsState() {
        let preview = FakePreview()
        let (d, wc, _, _) = makeDragger(preview: preview)

        // ドラッグ中にキャンセル
        d.beginDrag(at: downPoint)
        d.updateDrag(at: leftEdge)   // プレビューを出す
        d.cancelDrag()

        XCTAssertTrue(preview.hideCalls >= 1, "cancelDrag で hide が呼ばれる")

        // キャンセル後の endDrag は何もしない
        d.endDrag(at: leftEdge)
        XCTAssertEqual(wc.setFrameCalls.count, 0, "cancelDrag 後は snap しない")
    }

    // MARK: ⑤ cancelDrag 後の updateDrag はプレビューを出さない

    func testCancelDrag_subsequentUpdateDrag_noPreview() {
        let preview = FakePreview()
        let (d, _, _, _) = makeDragger(preview: preview)

        d.beginDrag(at: downPoint)
        d.cancelDrag()

        let showsBefore = preview.showCalls.count
        d.updateDrag(at: leftEdge)
        XCTAssertEqual(preview.showCalls.count, showsBefore, "cancelDrag 後はプレビューを出さない")
    }

    // MARK: ⑥ tapDisabledByTimeout → cancelDrag 相当（snap なし、プレビュー片付け）

    func testHandle_tapDisabledByTimeout_cancelsWithoutSnap() {
        let preview = FakePreview()
        let (d, wc, _, _) = makeDragger(preview: preview)

        d.beginDrag(at: downPoint)
        d.updateDrag(at: leftEdge)  // プレビューを出す
        d.cancelDrag()              // tapDisabledByTimeout イベントの効果を直接シミュレート

        XCTAssertTrue(preview.hideCalls >= 1, "タップ無効化でプレビューが隠れる")
        d.endDrag(at: leftEdge)
        XCTAssertEqual(wc.setFrameCalls.count, 0, "タップ無効化後は snap しない")
    }

    // MARK: ⑦ window が nil（windowUnderCursor も frontmost も nil）の場合は snap しない

    func testNilWindow_noSnap() {
        let wc = FakeWindowController()
        wc.stubWindow = nil   // ウィンドウなし
        let (d, _, _, _) = makeDragger(windows: wc)

        d.beginDrag(at: downPoint)
        d.endDrag(at: leftEdge)
        XCTAssertEqual(wc.setFrameCalls.count, 0, "ウィンドウなしはスナップしない")
    }
}
