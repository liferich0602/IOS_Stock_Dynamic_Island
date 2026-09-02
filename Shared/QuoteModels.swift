//
//  QuoteModels.swift
//  主App与灵动岛扩展共用的模型与工具
//

import Foundation
import SwiftUI
import ActivityKit

// MARK: - 行情模型

struct Quote {
    var name: String
    var price: Double
    var prev: Double
    var pct: Double
}

// MARK: - Live Activity 属性定义

struct StockAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var name: String      // 股票名称
        var price: Double     // 现价
        var pct: Double       // 涨跌幅 %
        var time: Date        // 数据时间
        var redUp: Bool       // 红涨绿跌(true) / 绿涨红跌(false)
    }
    var code: String         // 腾讯接口代码，如 usAAPL
}

// MARK: - 代码规范化（与PC盯盘工具同规则）

func normalizeCode(_ raw: String) -> String? {
    let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: " ", with: "")
        .lowercased()
    guard !s.isEmpty else { return nil }

    func matches(_ pattern: String) -> Bool {
        s.range(of: pattern, options: .regularExpression) != nil
    }

    if matches(#"^(sh|sz|bj)\d{6}$"#) { return s }

    if let m = s.range(of: #"^hk(\d{4,6})$"#, options: .regularExpression) {
        let digits = String(s[m]).dropFirst(2)
        let padded = String(repeating: "0", count: max(0, 5 - digits.count)) + digits
        return "hk" + padded                       // hk9988 -> hk09988
    }

    if matches(#"^us[a-z.]{1,12}$"#) { return "us" + s.dropFirst(2).uppercased() }

    if s.allSatisfy({ $0.isNumber }) {
        guard s.count == 6 else { return nil }      // 纯数字仅认A股6位
        switch s.first {
        case "6": return "sh" + s
        case "0", "3": return "sz" + s
        case "4", "8": return "bj" + s
        default: return "sh" + s
        }
    }

    if matches(#"^[a-z.]{1,12}$"#) { return "us" + s.uppercased() }

    return nil
}

/// 代码去掉交易所前缀后的短代码，用于灵动岛紧凑视图：usAAPL -> AAPL
func shortCode(_ code: String) -> String {
    let lower = code.lowercased()
    for prefix in ["us", "sh", "sz", "bj", "hk"] where lower.hasPrefix(prefix) {
        return String(code.dropFirst(prefix.count)).uppercased()
    }
    return code.uppercased()
}

// MARK: - GBK 解码与行情解析（接口返回 GBK 编码）

func decodeGBK(_ data: Data) -> String? {
    // iOS SDK 里没有 kCFStringEncodingGB_18030_2000 常量，改用 CFStringEncodings 枚举
    let cfEnc = CFStringEncodings.GB_18030_2000
    let nsEnc = CFStringConvertEncodingToNSStringEncoding(
        CFStringEncoding(cfEnc.rawValue))
    return NSString(data: data, encoding: nsEnc) as String?
}

/// 解析 `v_usAAPL="200~苹果~AAPL.OQ~325.26~325.13~..." 格式的行情
func parseQuote(_ text: String) -> Quote? {
    guard let m = text.range(of: #"v_\w+="[^"]*""#, options: .regularExpression) else {
        return nil
    }
    let line = String(text[m])
    let parts = line.split(separator: "\"")
    guard parts.count >= 2 else { return nil }
    let fields = parts[1].split(separator: "~", omittingEmptySubsequences: false).map(String.init)
    guard fields.count > 4,
          let price = Double(fields[3]),
          let prev = Double(fields[4]), prev != 0 else { return nil }

    var p = price
    if p <= 0 { p = prev }                         // 停牌等异常时用昨收
    let name = fields[1]
    let pct = (p - prev) / prev * 100
    return Quote(name: name, price: p, prev: prev, pct: pct)
}

// MARK: - 展示辅助

func pctText(_ pct: Double) -> String {
    let sign = pct > 0 ? "+" : ""
    return String(format: "%@%.2f%%", sign, pct)
}

func pctColor(_ pct: Double, redUp: Bool) -> Color {
    let up = Color(red: 1.0, green: 0.23, blue: 0.19)     // 红
    let down = Color(red: 0.20, green: 0.78, blue: 0.35)  // 绿
    if pct > 0 { return redUp ? up : down }
    if pct < 0 { return redUp ? down : up }
    return Color(white: 0.75)
}

func quoteTimeFormatter() -> DateFormatter {
    let f = DateFormatter()
    f.dateFormat = "HH:mm:ss"
    return f
}
