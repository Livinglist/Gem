import SwiftUI
import WebKit

struct WebView: View {
    let url: URL
    
    var body: some View {
        BaseWebView(url: url)
            .navigationTitle(url.host().orEmpty)
            .navigationBarTitleDisplayMode(.inline)
    }
}

extension WebView {
    fileprivate struct BaseWebView: UIViewRepresentable {
        let url: URL
        
        func makeUIView(context: Context) -> WKWebView {
            return WKWebView()
        }
        
        func updateUIView(_ webView: WKWebView, context: Context) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}
