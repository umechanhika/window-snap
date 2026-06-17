import XCTest
@testable import WindowSnapCore

final class GeometryTests: XCTestCase {

    private let ph: CGFloat = 1080   // primaryHeight（テスト用固定値）

    // MARK: - Y 反転往復（CGGlobalToCocoa）

    func testCGGlobalToCocoa_topOfScreen() {
        // CG global (0,0) = 画面左上 → Cocoa では y = primaryHeight
        let result = Geometry.cgGlobalToCocoa(CGPoint(x: 0, y: 0), primaryHeight: ph)
        XCTAssertEqual(result, CGPoint(x: 0, y: 1080))
    }

    func testCGGlobalToCocoa_bottomOfScreen() {
        // CG global (0,1080) = 画面左下 → Cocoa では y = 0
        let result = Geometry.cgGlobalToCocoa(CGPoint(x: 0, y: 1080), primaryHeight: ph)
        XCTAssertEqual(result, CGPoint(x: 0, y: 0))
    }

    func testCGGlobalToCocoa_midpoint() {
        let result = Geometry.cgGlobalToCocoa(CGPoint(x: 100, y: 300), primaryHeight: ph)
        XCTAssertEqual(result, CGPoint(x: 100, y: 780))
    }

    // MARK: - cocoaRectToCGGlobal

    func testCocoaRectToCGGlobal_fullScreen() {
        // Cocoa (0,0,1920,1080) → CG global: y = 1080 - 1080 = 0
        let cocoa = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let result = Geometry.cocoaRectToCGGlobal(cocoa, primaryHeight: ph)
        XCTAssertEqual(result, CGRect(x: 0, y: 0, width: 1920, height: 1080))
    }

    func testCocoaRectToCGGlobal_withMenubar() {
        // visibleFrame: Cocoa (0,0,1920,1032) → menubar 48pt 上にある想定
        // CG global: y = 1080 - (0 + 1032) = 48
        let cocoa = CGRect(x: 0, y: 0, width: 1920, height: 1032)
        let result = Geometry.cocoaRectToCGGlobal(cocoa, primaryHeight: ph)
        XCTAssertEqual(result, CGRect(x: 0, y: 48, width: 1920, height: 1032))
    }

    // MARK: - cgGlobalRectToCocoa（cocoaRectToCGGlobal の逆）

    func testRoundTrip_cocoaToCGGlobalAndBack() {
        let cocoa = CGRect(x: 100, y: 200, width: 800, height: 600)
        let cg = Geometry.cocoaRectToCGGlobal(cocoa, primaryHeight: ph)
        let back = Geometry.cgGlobalRectToCocoa(cg, primaryHeight: ph)
        XCTAssertEqual(back.origin.x, cocoa.origin.x, accuracy: 0.001)
        XCTAssertEqual(back.origin.y, cocoa.origin.y, accuracy: 0.001)
        XCTAssertEqual(back.width,    cocoa.width,    accuracy: 0.001)
        XCTAssertEqual(back.height,   cocoa.height,   accuracy: 0.001)
    }

    // MARK: - マルチディスプレイ（異なる primaryHeight）

    func testCocoaRectToCGGlobal_tallPrimary() {
        // 4K 画面: primaryHeight = 2160
        let ph2: CGFloat = 2160
        let cocoa = CGRect(x: 0, y: 0, width: 3840, height: 2160)
        let result = Geometry.cocoaRectToCGGlobal(cocoa, primaryHeight: ph2)
        XCTAssertEqual(result, CGRect(x: 0, y: 0, width: 3840, height: 2160))
    }

    func testCocoaRectToCGGlobal_secondaryScreenOffset() {
        // 右隣の画面: Cocoa frame (1920, 0, 1920, 1080) = 第1画面と同じ高さ・右に並ぶ
        let cocoa = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        let result = Geometry.cocoaRectToCGGlobal(cocoa, primaryHeight: ph)
        // CG global: x は不変、y = 1080 - (0 + 1080) = 0
        XCTAssertEqual(result, CGRect(x: 1920, y: 0, width: 1920, height: 1080))
    }

    // MARK: - snapRect（全7ゾーン）

    // テスト用 visibleFrame (Cocoa): x=0, y=24, w=1920, h=1032  (menubar 24pt 分 y 上に)
    private let vf = CGRect(x: 0, y: 24, width: 1920, height: 1032)

    private func snap(_ zone: SnapZone) -> CGRect {
        Geometry.snapRect(for: zone, visibleFrameCocoa: vf, primaryHeight: ph)
    }

    func testSnapRect_top() {
        // .top = 全面 → cocoaRectToCGGlobal(vf) = (0, 1080-(24+1032), 1920, 1032) = (0, 24, 1920, 1032)
        let r = snap(.top)
        XCTAssertEqual(r, CGRect(x: 0, y: 24, width: 1920, height: 1032))
    }

    func testSnapRect_left() {
        // 左半分: Cocoa (0, 24, 960, 1032) → CG global y = 1080 - (24+1032) = 24
        let r = snap(.left)
        XCTAssertEqual(r, CGRect(x: 0, y: 24, width: 960, height: 1032))
    }

    func testSnapRect_right() {
        let r = snap(.right)
        XCTAssertEqual(r, CGRect(x: 960, y: 24, width: 960, height: 1032))
    }

    func testSnapRect_topLeft() {
        // 上左 1/4: Cocoa (0, 24+516, 960, 516) = (0, 540, 960, 516)
        // CG global y = 1080 - (540 + 516) = 24
        let r = snap(.topLeft)
        XCTAssertEqual(r, CGRect(x: 0, y: 24, width: 960, height: 516))
    }

    func testSnapRect_topRight() {
        let r = snap(.topRight)
        XCTAssertEqual(r, CGRect(x: 960, y: 24, width: 960, height: 516))
    }

    func testSnapRect_bottomLeft() {
        // 下左 1/4: Cocoa (0, 24, 960, 516) → CG global y = 1080 - (24+516) = 540
        let r = snap(.bottomLeft)
        XCTAssertEqual(r, CGRect(x: 0, y: 540, width: 960, height: 516))
    }

    func testSnapRect_bottomRight() {
        let r = snap(.bottomRight)
        XCTAssertEqual(r, CGRect(x: 960, y: 540, width: 960, height: 516))
    }
}
