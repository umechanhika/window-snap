import XCTest
@testable import WindowSnapCore

final class SnapZoneTests: XCTestCase {

    // プライマリ画面: CG global フレーム (0,0)-(1920,1080)
    let f = CGRect(x: 0, y: 0, width: 1920, height: 1080)

    private func zone(_ x: CGFloat, _ y: CGFloat) -> SnapZone? {
        SnapZone.zone(forCursorGlobal: CGPoint(x: x, y: y), screenFrameGlobal: f)
    }

    // MARK: - 端到達なし → nil

    func testNoEdge_returnsNil() {
        XCTAssertNil(zone(960, 540))          // 中央
        XCTAssertNil(zone(100, 100))          // 左上寄りだが端未到達
        XCTAssertNil(zone(1800, 900))         // 右下寄りだが端未到達
    }

    // MARK: - 上端（最大化）

    func testTopCenter_returnsTop() {
        // 上端中央（CORNER_BAND=120 の外）
        XCTAssertEqual(zone(960, 0), .top)
        XCTAssertEqual(zone(960, 3), .top)
        XCTAssertEqual(zone(960, 6), .top)    // EDGE_THRESHOLD ちょうど
    }

    func testTopJustOutsideEdgeThreshold_returnsNil() {
        // y=7 は EDGE_THRESHOLD(6) を超える → 上端未到達
        XCTAssertNil(zone(960, 7))
    }

    // MARK: - 四隅（1/4）

    func testTopLeft_corner() {
        // 上端 + 左寄り(x <= 120)
        XCTAssertEqual(zone(0, 0), .topLeft)
        XCTAssertEqual(zone(119, 0), .topLeft)
        XCTAssertEqual(zone(120, 0), .topLeft)   // CORNER_BAND ちょうど → 隅に含まれる
    }

    func testTopLeft_justOutsideCornerBand() {
        // x=121 は CORNER_BAND(120) を超える → 上端中央 = .top
        XCTAssertEqual(zone(121, 0), .top)
    }

    func testTopRight_corner() {
        // 上端 + 右寄り(x >= 1920-120 = 1800)
        XCTAssertEqual(zone(1920, 0), .topRight)
        XCTAssertEqual(zone(1800, 0), .topRight)
        XCTAssertEqual(zone(1799, 0), .top)      // 1px 外 → .top
    }

    func testBottomLeft_corner() {
        // 下端 + 左寄り → bottomLeft
        XCTAssertEqual(zone(0, 1080), .bottomLeft)
        XCTAssertEqual(zone(120, 1080), .bottomLeft)
    }

    func testBottomRight_corner() {
        XCTAssertEqual(zone(1920, 1080), .bottomRight)
        XCTAssertEqual(zone(1800, 1080), .bottomRight)
    }

    // MARK: - 下端中央 → nil（Dock 干渉回避）

    func testBottomCenter_returnsNil() {
        XCTAssertNil(zone(960, 1080))   // 下端中央はスナップしない
        XCTAssertNil(zone(960, 1074))   // EDGE_THRESHOLD 内
    }

    // MARK: - 左右端（半分）

    func testLeft_center() {
        // 左端・縦中央（CORNER_BAND の外）
        XCTAssertEqual(zone(0, 540), .left)
        XCTAssertEqual(zone(6, 540), .left)      // EDGE_THRESHOLD ちょうど
    }

    func testLeft_justOutsideEdgeThreshold() {
        XCTAssertNil(zone(7, 540))
    }

    func testRight_center() {
        XCTAssertEqual(zone(1920, 540), .right)
        XCTAssertEqual(zone(1914, 540), .right)  // EDGE_THRESHOLD ちょうど
    }

    func testLeft_topBand_returnsTopLeft() {
        // 左端 + 上寄り(y <= 120) → topLeft
        XCTAssertEqual(zone(0, 0), .topLeft)
        XCTAssertEqual(zone(0, 120), .topLeft)
        XCTAssertEqual(zone(0, 121), .left)      // 1px 外 → .left
    }

    func testLeft_bottomBand_returnsBottomLeft() {
        // 左端 + 下寄り(y >= 1080-120=960)
        XCTAssertEqual(zone(0, 1080), .bottomLeft)
        XCTAssertEqual(zone(0, 960), .bottomLeft)
        XCTAssertEqual(zone(0, 959), .left)
    }

    // MARK: - マルチディスプレイ（非ゼロ origin）

    func testSecondaryScreen_nonZeroOrigin() {
        // 右隣の画面: CG global (1920,0)-(3840,1080)
        let f2 = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        let zone2 = { (x: CGFloat, y: CGFloat) -> SnapZone? in
            SnapZone.zone(forCursorGlobal: CGPoint(x: x, y: y), screenFrameGlobal: f2)
        }
        XCTAssertEqual(zone2(1920, 540), .left)    // 第2画面の左端 → left
        XCTAssertEqual(zone2(3840, 540), .right)   // 第2画面の右端 → right
        XCTAssertEqual(zone2(2880, 0), .top)       // 第2画面の上端中央 → top
        XCTAssertNil(zone2(2880, 540))             // 第2画面の中央 → nil
    }
}
