import CoreGraphics

/// 座標変換の単一の真実の置き場所。NSScreen 依存を持たない純粋関数のみ。
///
/// 3つの座標系が登場する:
///   - CGEvent global  : 画面左上が原点・Y は下向き（`CGEvent.location`, `CGEventTap`）
///   - Accessibility   : 画面左上が原点・Y は下向き（`kAXPositionAttribute` 等）※CGEvent と同一系
///   - Cocoa(NSScreen) : メイン画面の左下が原点・Y は上向き（`NSScreen.frame/visibleFrame`）
///
/// primaryHeight（メイン画面の高さ）は呼び出し側（ScreenProviding 実装）から渡す。
/// これにより NSScreen への直接依存をなくし、XCTest で任意の値を注入できる。
public enum Geometry {

    /// CG global 点(左上原点・Y下) → Cocoa 点(左下原点・Y上)。
    public static func cgGlobalToCocoa(_ p: CGPoint, primaryHeight: CGFloat) -> CGPoint {
        CGPoint(x: p.x, y: primaryHeight - p.y)
    }

    /// Cocoa 矩形(左下原点) → CG global 矩形(左上原点)。
    /// 矩形は origin が左下なので、左上の y は `primaryHeight - maxY` になる。
    public static func cocoaRectToCGGlobal(_ r: CGRect, primaryHeight: CGFloat) -> CGRect {
        CGRect(x: r.origin.x,
               y: primaryHeight - r.maxY,
               width: r.width,
               height: r.height)
    }

    /// CG global 矩形(左上原点) → Cocoa 矩形(左下原点)。`cocoaRectToCGGlobal` の逆。
    /// プレビューオーバーレイ（NSWindow は Cocoa 座標）の配置に使う。
    public static func cgGlobalRectToCocoa(_ r: CGRect, primaryHeight: CGFloat) -> CGRect {
        CGRect(x: r.origin.x,
               y: primaryHeight - r.origin.y - r.height,
               width: r.width,
               height: r.height)
    }

    /// ゾーンに対応するスナップ先矩形を CG global(左上原点) で返す。
    /// `AXUIElementSetAttributeValue` の position/size にそのまま渡せる。
    /// `vf` は対象画面の visibleFrame(Cocoa, menubar/Dock 除外済み)。
    public static func snapRect(for zone: SnapZone, visibleFrameCocoa vf: CGRect, primaryHeight: CGFloat) -> CGRect {
        let halfW = vf.width / 2
        let halfH = vf.height / 2
        // Cocoa(左下原点) で各ゾーンの矩形を組み立てる。Cocoa では「上」が y の大きい側。
        let cocoaRect: CGRect
        switch zone {
        case .top:
            cocoaRect = vf                                                              // 全面（最大化）
        case .left:
            cocoaRect = CGRect(x: vf.minX,          y: vf.minY,          width: halfW, height: vf.height)
        case .right:
            cocoaRect = CGRect(x: vf.minX + halfW,  y: vf.minY,          width: halfW, height: vf.height)
        case .topLeft:
            cocoaRect = CGRect(x: vf.minX,          y: vf.minY + halfH,  width: halfW, height: halfH)
        case .topRight:
            cocoaRect = CGRect(x: vf.minX + halfW,  y: vf.minY + halfH,  width: halfW, height: halfH)
        case .bottomLeft:
            cocoaRect = CGRect(x: vf.minX,          y: vf.minY,          width: halfW, height: halfH)
        case .bottomRight:
            cocoaRect = CGRect(x: vf.minX + halfW,  y: vf.minY,          width: halfW, height: halfH)
        }
        return cocoaRectToCGGlobal(cocoaRect, primaryHeight: primaryHeight)
    }
}
