// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WindowSnap",
    platforms: [.macOS(.v13)],
    targets: [
        // 純粋ロジック: ゾーン判定・座標変換・ドラッグ状態機械。AppKit/AX 非依存。
        .target(
            name: "WindowSnapCore",
            path: "Sources/WindowSnapCore"
        ),
        // 薄いグルー層: システム依存（AX/NSScreen/EventTap/Overlay/StatusItem/main）のみ。
        .executableTarget(
            name: "WindowSnap",
            dependencies: ["WindowSnapCore"],
            path: "Sources/WindowSnap"
        ),
        // XCTest: WindowSnapCore のロジックを網羅テスト。
        .testTarget(
            name: "WindowSnapCoreTests",
            dependencies: ["WindowSnapCore"],
            path: "Tests/WindowSnapCoreTests"
        ),
    ]
)
