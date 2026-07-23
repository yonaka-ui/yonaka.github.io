import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ComposeView: View {
    @State private var text: String = ""
    @State private var imageURL: URL?
    @State private var isPosting = false
    @State private var statusMessage: String?
    @State private var statusIsError = false
    @State private var showingSettings = false

    @State private var postToX = true
    @State private var postToBluesky = true

    private let characterLimit = 280 // stricter of X (280) and Bluesky (300)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("投稿する")
                    .font(.headline)
                Spacer()
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
                .help("APIキーの設定")
            }

            TextEditor(text: $text)
                .font(.system(size: 13))
                .frame(height: 120)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3)))

            HStack {
                Text("\(text.count) / \(characterLimit)")
                    .font(.caption)
                    .foregroundStyle(text.count > characterLimit ? .red : .secondary)
                Spacer()
                if let imageURL {
                    Text(imageURL.lastPathComponent)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Button {
                        self.imageURL = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    pickImage()
                } label: {
                    Image(systemName: "photo")
                }
                .buttonStyle(.plain)
                .help("画像を添付")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("投稿先").font(.caption).foregroundStyle(.secondary)
                Toggle("X", isOn: $postToX)
                Toggle("Bluesky", isOn: $postToBluesky)
            }
            .toggleStyle(.checkbox)

            if let statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(statusIsError ? .red : .green)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Button("コピーのみ") {
                    copyToClipboard()
                }
                .disabled(text.isEmpty)

                Spacer()

                Button {
                    Task { await post() }
                } label: {
                    if isPosting {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("投稿する")
                    }
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(text.isEmpty || text.count > characterLimit || isPosting || (!postToX && !postToBluesky))
            }
        }
        .padding(14)
        .frame(width: 340)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }

    private func pickImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .gif]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            imageURL = panel.url
        }
    }

    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        statusIsError = false
        statusMessage = "クリップボードにコピーしました。他のSNSに貼り付けてください。"
    }

    private func post() async {
        isPosting = true
        statusMessage = nil
        defer { isPosting = false }

        var successes: [String] = []
        var failures: [String] = []

        if postToX {
            let credentials = KeychainStore.loadX()
            if !credentials.isComplete {
                failures.append("X: 設定画面(⚙️)でAPIキーを入力してください")
            } else {
                do {
                    var mediaId: String?
                    if let imageURL {
                        mediaId = try await TwitterClient.uploadImage(fileURL: imageURL, credentials: credentials)
                    }
                    try await TwitterClient.postTweet(text: text, mediaId: mediaId, credentials: credentials)
                    successes.append("X")
                } catch {
                    failures.append("X: \(error.localizedDescription)")
                }
            }
        }

        if postToBluesky {
            let credentials = KeychainStore.loadBluesky()
            if !credentials.isComplete {
                failures.append("Bluesky: 設定画面(⚙️)でアカウント情報を入力してください")
            } else {
                do {
                    try await BlueskyClient.post(text: text, imageURL: imageURL, credentials: credentials)
                    successes.append("Bluesky")
                } catch {
                    failures.append("Bluesky: \(error.localizedDescription)")
                }
            }
        }

        copyToClipboard()

        if failures.isEmpty {
            statusIsError = false
            statusMessage = "\(successes.joined(separator: "・"))に投稿しました。他のSNS用にテキストはコピー済みです。"
            text = ""
            imageURL = nil
        } else {
            statusIsError = true
            var message = failures.joined(separator: "\n")
            if !successes.isEmpty {
                message = "\(successes.joined(separator: "・"))には投稿成功。\n" + message
            }
            statusMessage = message
        }
    }
}
