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

    private let characterLimit = 280

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Xに投稿")
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
                        Text("Xに投稿する")
                    }
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(text.isEmpty || text.count > characterLimit || isPosting)
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

        let credentials = KeychainStore.load()
        guard credentials.isComplete else {
            statusIsError = true
            statusMessage = "設定画面(⚙️)でXのAPIキーを入力してください。"
            showingSettings = true
            return
        }

        do {
            var mediaId: String?
            if let imageURL {
                mediaId = try await TwitterClient.uploadImage(fileURL: imageURL, credentials: credentials)
            }
            try await TwitterClient.postTweet(text: text, mediaId: mediaId, credentials: credentials)

            copyToClipboard()
            statusIsError = false
            statusMessage = "Xに投稿しました。他のSNS用にテキストはコピー済みです。"
            text = ""
            self.imageURL = nil
        } catch {
            statusIsError = true
            statusMessage = error.localizedDescription
        }
    }
}
