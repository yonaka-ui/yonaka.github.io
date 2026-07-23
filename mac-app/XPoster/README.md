# XPoster

音楽の投稿文を1回書いて、複数のSNSにワンクリックで投稿するmacOSメニューバーアプリ。
X・Blueskyは直接投稿し、それ以外(Instagram/Threads/noteなど)には投稿と同時に
本文をクリップボードにコピーするので、手動で貼り付けるだけで済みます。

## できること

- メニューバーのアイコンをクリックすると、投稿文を書く小さなウィンドウが出る
- 画像(jpg/png/gif)を1枚添付できる
- 投稿先(X / Bluesky)をチェックボックスで選べる。両方チェックしていれば同時投稿
- 投稿と同時に同じ本文を自動でクリップボードにコピー(他SNS用)
- 「コピーのみ」で投稿せずコピーだけも可能
- APIキー/パスワードはmacOSのキーチェーンに保存(平文でファイルに保存しない)

## 必要なもの

- macOS 13以降、Xcode Command Line Tools(Swiftツールチェーン)
- X: Developer アカウントと "Read and Write" 権限の API キー一式(**有料プランが必要な場合あり**)
- Bluesky: 通常のアカウントと App Password(**無料、審査不要**)

### X API キーの取得手順

1. https://developer.x.com/ でアプリ/プロジェクトを作成
2. アプリの設定で **User authentication settings** を有効化し、Permissions を
   **Read and write** に設定
3. **Keys and tokens** タブで以下を発行してメモする
   - API Key / API Key Secret
   - Access Token / Access Token Secret (App permissions を Read and write にしてから再生成する)
4. 投稿(`POST /2/tweets`)の利用条件はXの料金プランに依存します(無料枠が使えない場合は
   Bluesky投稿だけをオンにして使ってください)

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

初回起動後、メニューバーのアイコン(鳥のマーク)から歯車ボタンを押し、使うSNSの分だけ
認証情報を入力して保存してください(X・Blueskyどちらか片方だけでも動きます)。

## 仕組みメモ

- X投稿: `POST https://api.twitter.com/2/tweets` (OAuth 1.0a / HMAC-SHA1、`TwitterClient.swift`)
- X画像アップロード: `POST https://upload.twitter.com/1.1/media/upload.json` (simple upload, 5MBまで)
- Bluesky投稿: AT Protocol XRPC (`com.atproto.server.createSession` → `com.atproto.repo.createRecord`、
  画像は `com.atproto.repo.uploadBlob`、`BlueskyClient.swift`)
- 外部パッケージへの依存はなし(署名にはApple標準の`CryptoKit`のみ使用)
- 認証情報は `KeychainStore.swift` 経由でmacOSキーチェーンに保存

## 既知の制限

- 動画添付・複数画像・スレッド投稿には未対応(まずは「1テキスト+画像1枚」の単純投稿に絞っています)
- noteには公式の投稿APIが無いため対応していません(クリップボードコピーで手動投稿してください)
- OAuthのブラウザ認可フローは実装しておらず、Developer PortalでキーとAccess Tokenを
  手動発行する前提です(個人利用の1アカウント運用にはこれで十分なため)
