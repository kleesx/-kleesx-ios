import UIKit
import WebKit
import Darwin

/// 读取内部硬件型号标识符（如 iPhone15,2）
func machineIdentifier() -> String {
    var size: Int = 0
    sysctlbyname("hw.machine", nil, &size, nil, 0)
    var machine = [CChar](repeating: 0, count: size)
    sysctlbyname("hw.machine", &machine, &size, nil, 0)
    return String(cString: machine)
}

/// 内部型号 → 常见机型名称映射，未收录的回退为内部型号
let deviceModelMap: [String: String] = [
    "iPhone14,7": "iPhone 14",
    "iPhone14,8": "iPhone 14 Plus",
    "iPhone14,2": "iPhone 14 Pro",
    "iPhone14,3": "iPhone 14 Pro Max",
    "iPhone15,1": "iPhone 15",
    "iPhone15,3": "iPhone 15 Plus",
    "iPhone15,2": "iPhone 15 Pro",
    "iPhone15,4": "iPhone 15 Pro Max",
    "iPhone16,1": "iPhone 16",
    "iPhone16,2": "iPhone 16 Plus",
    "iPhone16,3": "iPhone 16 Pro",
    "iPhone16,4": "iPhone 16 Pro Max",
    "iPhone13,4": "iPhone 13",
    "iPhone13,5": "iPhone 13 Pro",
    "iPad13,1": "iPad Pro 11 英寸 (第三代)",
    "iPad13,4": "iPad Air (第五代)",
    "iPad14,1": "iPad Pro 11 英寸 (第四代)",
    "iPad14,2": "iPad Pro 12.9 英寸 (第六代)",
    "iPad14,4": "iPad Air (第六代)"
]

/// 采集本机设备信息（序列号 / 真 UDID 受系统限制，普通 App 无法获取）
func collectDeviceInfo() -> [String: String] {
    let device = UIDevice.current
    let machine = machineIdentifier()
    let modelName = deviceModelMap[machine] ?? machine

    let idiom: String
    switch device.userInterfaceIdiom {
    case .pad: idiom = "iPad"
    case .phone: idiom = "iPhone"
    default: idiom = "其他"
    }

    // identifierForVendor 是供应商标识符，并非设备真 UDID；取不到时标记不可用
    let udid = device.identifierForVendor?.uuidString ?? "不可用"

    return [
        "name": device.name,
        "type": idiom,
        "ios": device.systemVersion,
        "modelName": modelName,
        "model": machine,
        "serial": "不可用",
        "udid": udid
    ]
}

class ViewController: UIViewController, WKNavigationDelegate {

    var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = false

        // 采集本机信息，以 JSON 注入网页 window.NATIVE_DEVICE，供前端回填字段
        let info = collectDeviceInfo()
        if let jsonData = try? JSONSerialization.data(withJSONObject: info, options: []),
           let json = String(data: jsonData, encoding: .utf8) {
            let script = "window.NATIVE_DEVICE = \(json);"
            let userScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            config.userContentController.addUserScript(userScript)
        }

        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.isOpaque = true
        webView.scrollView.isScrollEnabled = false
        view.addSubview(webView)

        // 加载内置的 index.html（菜单页面）
        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }

    override var prefersStatusBarHidden: Bool { true }
}
