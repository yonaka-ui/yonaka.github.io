# XPoster

音楽の投稿文を1回書いて、Xにワンクリックで投稿するだけのmacOSメニューバーアプリ。
投稿と同時に本文をクリップボードにコピーするので、Instagram/Threads/noteなど他のSNSには
手動で貼り付けるだけで済みます。

## できること

- メニューバーのアイコンをクリックすると、投稿文を書く小さなウィンドウが出る
- 画像(jpg/png/gif)を1枚添付できる
- 「Xに投稿する」でXに投稿し、同じ本文を自動でクリップボードにコピー
- 「コピーのみ」で投稿せずコピーだけも可能
- APIキーはmacOSのキーチェーンに保存(平文でファイルに保存しない)

## 必要なもの

- macOS 13以降 / Xcode 15以降(Swiftツールチェーン)
- X (旧Twitter) Developer アカウントと、"Read and Write" 権限の API キー一式

### X API キーの取得手順

1. https://developer.x.com/ でアプリ/プロジェクトを作成
2. アプリの設定で **User authentication settings** を有効化し、Permissions を
   **Read and write** に設定
3. **Keys and tokens** タブで以下を発行してメモする
   - API Key / API Key Secret
   - Access Token / Access Token Secret (App permissions を Read and write にしてから再生成する)
4. 投稿(`POST /2/tweets`)は無料(Free)プランでも利用可能

## ビルドと実行

```sh
cd mac-app/XPoster
swift run
```

Xcodeで編集したい場合は `Package.swift` をXcodeで開けばそのままプロジェクトとして開けます。

初回起動後、メニューバーのアイコン(鳥のマーク)から歯車ボタンを押し、上記で取得した
4つの値を入力して保存してください。

## 仕組みメモ

- 投稿: `POST https://api.twitter.com/2/tweets`
- 画像アップロード: `POST https://upload.twitter.com/1.1/media/upload.json` (simple upload, 5MBまで)
- 認証方式: OAuth 1.0a (HMAC-SHA1)。署名生成は `TwitterClient.swift` 内で自前実装しており、
  外部パッケージへの依存はなし(署名には Apple 標準の `Crypto` フレームワークのみ使用)。

## 既知の制限

- 動画添付・複数画像・スレッド投稿には未対応(まずは「1テキスト+画像1枚」の単純投稿に絞っています)
- OAuthのブラウザ認可フローは実装しておらず、Developer PortalでキーとAccess Tokenを
  手動発行する前提です(個人利用の1アカウント運用にはこれで十分なため)
