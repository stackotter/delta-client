import SwiftUI
import WebKit

final class WebView {
  var request: URLRequest
  var urlChangeHandler: (URL) -> Void
  
  var observer: NSKeyValueObservation?
  
  // TODO: investigate weak variables
  // swiftlint:disable weak_delegate
  var delegate = WebViewDelegate()
  // swiftlint:enable weak_delegate
  
  init(request: URLRequest, urlChangeHandler: @escaping (URL) -> Void = { _ in }) {
    self.request = request
    self.urlChangeHandler = urlChangeHandler
  }

  final func makeView(context: Context) -> WKWebView {
    let config = WKWebViewConfiguration()
    config.limitsNavigationsToAppBoundDomains = true
    
    let webview = WKWebView()
    webview.navigationDelegate = delegate
    
    // Register observation for url changes
    observer = webview.observe(\.url, options: .new) { view, _ in
      if let newURL = view.url {
        self.urlChangeHandler(newURL)
      }
    }
    return webview
  }

  final func updateView(_ view: WKWebView, context: Context) {
    if view.url == nil {
      request.httpShouldHandleCookies = false
      view.load(request)
    }
  }
}

#if os(macOS)
extension WebView: NSViewRepresentable {
  final func makeNSView(context: Context) -> WKWebView {
    return makeView(context: context)
  }
  
  final func updateNSView(_ view: WKWebView, context: Context) {
    updateView(view, context: context)
  }
}
#elseif os(iOS)
extension WebView: UIViewRepresentable {
  final func makeUIView(context: Context) -> WKWebView {
    return makeView(context: context)
  }
  
  final func updateUIView(_ view: WKWebView, context: Context) {
    updateView(view, context: context)
  }
}
#endif

final class WebViewDelegate: NSObject, WKNavigationDelegate {
  // Disable custom url schemes to prevent popup error on auth redirect
  func webView(
    _ webView: WKWebView,
    decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
  ) {
    decisionHandler(.allow)
  }
}
