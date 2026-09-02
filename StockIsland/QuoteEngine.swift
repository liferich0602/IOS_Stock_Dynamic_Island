//
//  QuoteEngine.swift
//  行情轮询 + 灵动岛(ActivityKit)控制
//

import Foundation
import ActivityKit

// MARK: - 行情请求（腾讯接口，GBK编码）

enum QuoteFetcher {
    static func fetch(code: String) async -> Quote? {
        guard let url = URL(string: "https://qt.gtimg.cn/q=" + code) else { return nil }
        var req = URLRequest(url: url, timeoutInterval: 8)
        req.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            guard let text = decodeGBK(data) else { return nil }
            return parseQuote(text)
        } catch {
            return nil
        }
    }
}

// MARK: - 灵动岛控制器

@MainActor
final class ActivityController {
    private var activity: Activity<StockAttributes>?

    /// 更新灵动岛；没有活动则创建（会接管旧app遗留的活动）
    func updateOrStart(code: String, quote: Quote, redUp: Bool) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let state = StockAttributes.ContentState(
            name: quote.name, price: quote.price, pct: quote.pct,
            time: Date(), redUp: redUp)

        if let activity = activity {
            await activity.update(using: state)
            return
        }
        // 接管上次app被杀时遗留的活动
        if let existing = Activity<StockAttributes>.activities.first {
            activity = existing
            await existing.update(using: state)
            return
        }
        do {
            let attributes = StockAttributes(code: code)
            activity = try Activity.request(
                attributes: attributes, contentState: state, pushType: nil)
        } catch {
            NSLog("request activity failed: \(error)")
        }
    }

    func end() async {
        if let activity = activity {
            await activity.end(dismissalPolicy: .immediate)
            self.activity = nil
        }
        // 清掉所有遗留活动
        for a in Activity<StockAttributes>.activities {
            await a.end(dismissalPolicy: .immediate)
        }
    }
}

// MARK: - 轮询引擎

@MainActor
final class QuoteEngine: ObservableObject {
    @Published var quote: Quote?
    @Published var running = false
    @Published var lastError: String?
    @Published var activityEnabled = ActivityAuthorizationInfo().areActivitiesEnabled

    private var loopTask: Task<Void, Never>?
    private let audio = AudioKeeper()
    private var activityController = ActivityController()
    private var redUp = true
    private var interval: TimeInterval = 5
    private var code = ""

    func start(rawCode: String, redUp: Bool, interval: TimeInterval) {
        guard let code = normalizeCode(rawCode) else {
            lastError = "股票代码无效：\(rawCode)（示例 usAAPL / hk09988 / sh600519）"
            return
        }
        self.code = code
        self.redUp = redUp
        self.interval = interval
        UserDefaults.standard.set(code, forKey: "code")
        UserDefaults.standard.set(redUp, forKey: "redUp")
        UserDefaults.standard.set(interval, forKey: "interval")

        lastError = nil
        running = true
        audio.start()  // 无声音频保活，保证后台持续轮询

        loopTask = Task { [weak self] in
            while let self = self, !Task.isCancelled {
                let q = await QuoteFetcher.fetch(code: code)
                if let q {
                    self.quote = q
                    self.lastError = nil
                    await self.activityController.updateOrStart(
                        code: code, quote: q, redUp: redUp)
                } else {
                    self.lastError = "行情获取失败，\(Int(self.interval))秒后重试"
                }
                try? await Task.sleep(nanoseconds: UInt64(self.interval * 1_000_000_000))
            }
        }
    }

    func stop() {
        loopTask?.cancel()
        loopTask = nil
        audio.stop()
        running = false
        let controller = activityController
        Task { await controller.end() }
    }
}
