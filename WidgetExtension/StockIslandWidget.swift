//
//  StockIslandWidget.swift
//  灵动岛 Live Activity 界面
//

import WidgetKit
import SwiftUI
import ActivityKit

@main
struct StockIslandWidgetBundle: WidgetBundle {
    var body: some Widget {
        StockLiveActivityWidget()
    }
}

struct StockLiveActivityWidget: Widget {
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StockAttributes.self) { context in
            // 锁屏卡片
            LockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.8))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.name.isEmpty
                             ? shortCode(context.attributes.code)
                             : context.state.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text(shortCode(context.attributes.code))
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(String(format: "%.2f", context.state.price))
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(pctText(context.state.pct))
                        .font(.system(size: 21, weight: .bold))
                        .foregroundColor(pctColor(context.state.pct, redUp: context.state.redUp))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text("更新 " + Self.timeFormatter.string(from: context.state.time))
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                        Spacer()
                        Text(String(format: "%.2f", context.state.price) + " · " + pctText(context.state.pct))
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }
            } compactLeading: {
                // 灵动岛左侧胶囊：短代码
                Text(shortCode(context.attributes.code))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            } compactTrailing: {
                // 灵动岛右侧胶囊：涨跌幅
                Text(pctText(context.state.pct))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(pctColor(context.state.pct, redUp: context.state.redUp))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            } minimal: {
                Text(String(format: "%.1f%%", context.state.pct))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(pctColor(context.state.pct, redUp: context.state.redUp))
                    .minimumScaleFactor(0.6)
            }
            .keylineTint(pctColor(context.state.pct, redUp: context.state.redUp))
        }
    }
}

// MARK: - 锁屏卡片

struct LockScreenView: View {
    let context: ActivityViewContext<StockAttributes>

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.name.isEmpty
                     ? shortCode(context.attributes.code)
                     : context.state.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(shortCode(context.attributes.code)
                     + " · " + Self.timeFormatter.string(from: context.state.time))
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.2f", context.state.price))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
                Text(pctText(context.state.pct))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(pctColor(context.state.pct, redUp: context.state.redUp))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()
}
