//
//  ContentView.swift
//  主界面：输入代码、开始/停止盯盘、颜色与频率设置
//

import SwiftUI
import ActivityKit

struct ContentView: View {
    @StateObject private var engine = QuoteEngine()
    @State private var codeInput: String
    @State private var redUp: Bool
    @State private var interval: Double

    init() {
        let d = UserDefaults.standard
        _codeInput = State(initialValue: d.string(forKey: "code") ?? "AAPL")
        _redUp = State(initialValue: d.object(forKey: "redUp") as? Bool ?? true)
        _interval = State(initialValue: d.object(forKey: "interval") as? Double ?? 5)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    quoteCard
                    inputCard
                    if !engine.activityEnabled { activityHint }
                    footer
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("股票灵动岛")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
        }
    }

    // MARK: 行情卡

    private var quoteCard: some View {
        VStack(spacing: 8) {
            if let q = engine.quote {
                Text(q.name.isEmpty ? codeInput : q.name)
                    .font(.headline)
                    .foregroundColor(.gray)
                Text(String(format: "%.2f", q.price))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
                Text(pctText(q.pct))
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(pctColor(q.pct, redUp: redUp))
                if let err = engine.lastError {
                    Text(err).font(.caption).foregroundColor(.orange)
                }
            } else {
                Text(engine.running ? "连接行情中…" : "未开始")
                    .font(.title3)
                    .foregroundColor(.gray)
                if let err = engine.lastError {
                    Text(err).font(.caption).foregroundColor(.orange)
                }
            }

            Button {
                if engine.running {
                    engine.stop()
                } else {
                    engine.start(rawCode: codeInput, redUp: redUp, interval: interval)
                }
            } label: {
                Label(engine.running ? "停止盯盘" : "开始盯盘",
                      systemImage: engine.running ? "stop.circle.fill" : "play.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(engine.running ? .red : .green)
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(white: 0.12)))
    }

    // MARK: 设置卡

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("设置").font(.headline).foregroundColor(.white)

            VStack(alignment: .leading, spacing: 6) {
                Text("股票代码").font(.subheadline).foregroundColor(.gray)
                TextField("如 AAPL / TSLA / hk09988 / sh600519", text: $codeInput)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .font(.body.monospaced())
                HStack(spacing: 8) {
                    ForEach(["AAPL", "TSLA", "NVDA", "MSFT"], id: \.self) { c in
                        Button(c) { codeInput = c }
                            .font(.caption)
                            .buttonStyle(.bordered)
                            .tint(.blue)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("刷新间隔").font(.subheadline).foregroundColor(.gray)
                Picker("刷新间隔", selection: $interval) {
                    Text("5秒").tag(5.0)
                    Text("10秒").tag(10.0)
                    Text("30秒").tag(30.0)
                }
                .pickerStyle(.segmented)
            }

            Toggle(isOn: $redUp) {
                Text("红涨绿跌（关=绿涨红跌）")
                    .font(.subheadline).foregroundColor(.white)
            }
            .tint(.blue)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(white: 0.12)))
    }

    private var activityHint: some View {
        Label("灵动岛实时活动未开启：设置 → 股票灵动岛 → 实时活动",
              systemImage: "exclamationmark.triangle")
            .font(.footnote)
            .foregroundColor(.orange)
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.orange.opacity(0.15)))
    }

    private var footer: some View {
        Text("开始盯盘后可退出app或锁屏，行情持续刷新\n控制中心的播放指示为后台保活所需，属正常现象\n收盘后价格不再变化，可停止盯盘省电")
            .font(.caption2)
            .foregroundColor(.gray)
            .multilineTextAlignment(.center)
    }
}
