# XPoster

音楽の投稿文を1回書いて、Blueskyにワンクリックで投稿するmacOSメニューバーアプリ。
投稿と同時に本文をクリップボードにコピーするので、Instagram/Threads/noteなど他のSNSには
手動で貼り付けるだけで済みます。

## できること

- メニューバーのアイコン(音符マーク)をクリックすると、投稿文を書く小さなウィンドウが出る
- 画像(jpg/png/gif)を1枚添付できる
- 「Blueskyに投稿する」でBlueskyに投稿し、同じ本文を自動でクリップボードにコピー
- 「コピーのみ」で投稿せずコピーだけも可能
- Blueskyのアカウント情報はmacOSのキーチェーンに保存(平文でファイルに保存しない)

## 必要なもの

- macOS 13以降、Xcode Command Line Tools(Swiftツールチェーン)
- 通常のBlueskyアカウントと App Password(無料、審査不要)

### Bluesky App Password の取得手順

1. Blueskyアプリ/Webで **設定 > プライバシーとセキュリティ > App Passwords** を開く
2. 「Add App Password」で新しいパスワードを発行してメモする(ログインパスワードとは別物)
3. XPosterの設定画面には、ハンドル(例: `you.bsky.social`)とこのApp Passwordを入力する

## ビルドと実行

```sh
cd mac-app/XPoster
swift run
```

Xcodeで編集したい場合は `Package.swift` をXcodeで開けばそのままプロジェクトとして開けます。

初回起動後、メニューバーのアイコン(音符マーク)から歯車ボタンを押し、ハンドルとApp Passwordを
入力して保存してください。

## 仕組みメモ

- Bluesky投稿: AT Protocol XRPC (`com.atproto.server.createSession` → `com.atproto.repo.createRecord`、
  画像は `com.atproto.repo.uploadBlob`、`BlueskyClient.swift`)
- 外部パッケージへの依存はなし
- 認証情報は `KeychainStore.swift` 経由でmacOSキーチェーンに保存

## 既知の制限

- 動画添付・複数画像には未対応(まずは「1テキスト+画像1枚」の単純投稿に絞っています)
- X・noteには対応していません(Xは有料プランが必要になったため削除、noteは公式APIが無いため
  未対応)。どちらもクリップボードコピーで手動投稿してください
