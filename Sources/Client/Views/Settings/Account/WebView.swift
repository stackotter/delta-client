import SwiftUI
import WebKit

@available(macOS 13, *)
@available(iOS 16, *)
struct WebView {
  @State var request: URLRequest
  var urlChangeHandler: (URL) -> Void
  
  @State var observer: NSKeyValueObservation?
  
  // TODO: investigate weak variables
  // swiftlint:disable weak_delegate
  var delegate = WebViewDelegate()
  // swiftlint:enable weak_delegate
  
  func makeView(context: Context) -> WKWebView {
    let config = WKWebViewConfiguration()
    config.limitsNavigationsToAppBoundDomains = true
    
    let webview = WKWebView()
    webview.navigationDelegate = delegate
    
    // Register observation for url changes
    // Async so we are not editing stateful during view update
    DispatchQueue(label: "dev.stackotter.delta-client.webview").async {
      observer = webview.observe(\.url, options: .new) { view, _ in
        if let newURL = view.url {
          self.urlChangeHandler(newURL)
        }
      }
    }
    return webview
  }

  func updateView(_ view: WKWebView, context: Context) {
    if view.url == nil {
      DispatchQueue(label: "dev.stackotter.delta-client.webview").async {
        request.httpShouldHandleCookies = false
      }
      view.load(request)
    }
  }
}

@available(macOS, deprecated: 13, renamed: "WebView")
@available(iOS, deprecated: 16, renamed: "WebView")
final class WebViewClass {
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
@available(macOS 13, *)
extension WebView: NSViewRepresentable {
  typealias NSViewType = WKWebView
  
  func makeNSView(context: Context) -> WKWebView {
    return makeView(context: context)
  }
  
  func updateNSView(_ view: WKWebView, context: Context) {
    updateView(view, context: context)
  }
}

extension WebViewClass: NSViewRepresentable {
  final func makeNSView(context: Context) -> WKWebView {
    return makeView(context: context)
  }
  
  final func updateNSView(_ view: WKWebView, context: Context) {
    updateView(view, context: context)
  }
}
#elseif os(iOS)
@available(iOS 16, *)
extension WebView: UIViewRepresentable {
  typealias UIViewType = WKWebView
  
  func makeUIView(context: Context) -> WKWebView {
    return makeView(context: context)
  }
  
  func updateUIView(_ view: WKWebView, context: Context) {
    updateView(view, context: context)
  }
}

extension WebViewClass: UIViewRepresentable {
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
