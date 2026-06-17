# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## コマンド

```bash
# テスト（最重要 — ロジック変更時は必ず実行）
swift test

# ビルド（テスト用バイナリ作成 — 本番ビルドは scripts/ 経由）
WORKTREE="$(pwd)"
swift build --package-path "$WORKTREE" -c release
# .app バンドル化・署名は build-app.sh 参照（PROJECT_DIR をワークツリーに差し替えて実行）

# カバレッジ付きテスト
swift test --enable-code-coverage

# 特定テストのみ実行
swift test --filter SnapZoneTests
swift test --filter GeometryTests/testSnapRect_left
```

## アーキテクチャ

### ターゲット構成（Package.swift）

| ターゲット | 種別 | 役割 |
|----------|------|------|
| `WindowSnapCore` | library | 純粋ロジック。AppKit / AX 非依存。XCTest 対象 |
| `WindowSnap` | executable | 薄いグルー層。Core に依存。単体テスト対象外 |
| `WindowSnapCoreTests` | test | Core の XCTest |

### 座標系（最重要・バグの温床）

コード内に 2 つの座標系が混在する：

- **CG global（左上原点・Y 下向き）**: `CGEvent.location`、AX の position/size、`SnapZone` 判定。
- **Cocoa（メイン画面左下原点・Y 上向き）**: `NSScreen.frame/visibleFrame`、`NSWindow.setFrame`。

**経路の原則**: カーソル位置 → ウィンドウ取得 → position/size set まですべて CG global で通す。Cocoa を経由するのは `NSScreen` の frame/visibleFrame を読む一瞬だけ。変換は `Geometry` に集約。

`Geometry` の各関数は `primaryHeight: CGFloat`（メイン画面の高さ）を引数で受け取る（NSScreen 依存を排除してテスト可能にするため）。実環境では `SystemScreenProvider.primaryHeight` が `NSScreen.screens.first?.frame.height` を返す。

### WindowSnapCore のファイル構成

- `Protocols.swift` — `WindowControlling` / `ScreenProviding` / `SnapPreviewing` の 3 プロトコル定義
- `SnapZone.swift` — ゾーン enum と `zone(forCursorGlobal:screenFrameGlobal:)` 判定ロジック
- `Geometry.swift` — CG global ↔ Cocoa 変換 + `snapRect(for:visibleFrameCocoa:primaryHeight:)`
- `WindowDragger.swift` — ジェネリック状態機械 `WindowDragger<WC, SP>`。down/drag/up の3ステップでスナップを実行

### WindowSnap（executable グルー）のファイル構成

- `main.swift` — AppDelegate: アクセシビリティ権限ループ・`WindowDragger` 生成・スペース切替監視
- `event_tap.swift` — `CGEventTap` (listenOnly) のラッパ。タップ無効化時に自動再有効化
- `ax_window.swift` — AX ラッパ（`AXWindow` enum） + `SystemWindowController: WindowControlling`
- `screen_util.swift` — `SystemScreenProvider: ScreenProviding`
- `overlay_window.swift` — スナップ先プレビュー (`SnapOverlay: SnapPreviewing`)。`.transient` で Mission Control 中に自動退避
- `status_item.swift` — メニューバーアイコン（終了 / アクセシビリティ設定）

### テストにおけるフェイク注入

`Tests/WindowSnapCoreTests/Fakes.swift` に以下を定義：

- `FakeWindowController` — `setFrame` 呼び出しを記録。`stubWindow` / `stubTitlebarHit` で挙動を制御。
- `FakeScreenProvider` — `Screen = CGRect`（CG global フレームをスクリーン識別子として使う）。決定的な `visibleFrame` / `primaryHeight` を返す。
- `FakePreview` — `show` / `hide` 呼び出しを記録。

`WindowDragger` の `beginDrag` / `updateDrag` / `endDrag` は `internal` なので `@testable import WindowSnapCore` で直接テストする。

## テストとコードのルール

1. **ロジックは `WindowSnapCore` に置き、XCTest で担保する。** テスト不能なコードはシステム境界（executable 側のグルー）に限定する。
2. **PR 概要欄には「自動テスト項目」「手動テスト項目」を必ず記載する。** 手動項目はそのフェーズの変更分のみ・最小限に絞る。
3. CI（`swift test` + カバレッジ/テスト漏れ検知）が緑でないとマージしない。
4. **手動テストはフェーズ末尾に 1 回だけ実施する。** 全フェーズ完了後にまとめて行わない。

## 有料配布ロードマップ

実装順の正本は `docs/plans/pre-sales-roadmap.md`。現在地と次のフェーズはそのファイルを参照すること。
