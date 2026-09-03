# 股票灵动岛 (StockIsland)

在 iPhone 灵动岛上实时显示美股（也支持 A 股/港股）现价与涨跌幅，5~30 秒自动刷新，锁屏/退后台依然更新。

- **数据源**：腾讯行情接口 `qt.gtimg.cn`（免费、无需 key）
- **实时原理**：无声音频后台保活 → app 后台持续轮询 → ActivityKit 更新灵动岛
- **适用机型**：iPhone 14 Pro 及以上（灵动岛机型），iOS 16.1+

## 项目结构

```
├── project.yml              # XcodeGen 工程描述（CI 上生成 .xcodeproj）
├── .github/workflows/build.yml  # GitHub Actions 云构建流水线
├── Shared/QuoteModels.swift     # 主App与Widget共用：模型/代码规范化/GBK解码/行情解析
├── StockIsland/                 # 主 App（SwiftUI）
│   ├── ContentView.swift        # 界面：代码输入/刷新间隔/红涨绿跌/开始停止
│   ├── QuoteEngine.swift        # 轮询引擎 + ActivityKit 灵动岛控制器
│   └── AudioKeeper.swift        # 无声WAV后台保活
└── WidgetExtension/StockIslandWidget.swift  # 灵动岛 Live Activity 界面
```

## 一、云构建出 ipa（Windows 即可，无需 Mac）

1. 在 GitHub 新建一个仓库（Public 免费额度更宽裕，Private 也够用）。
2. 把本目录推上去：
   ```bat
   cd /d G:\QWenWork\iosStock
   git init
   git add .
   git commit -m "StockIsland init"
   git remote add origin https://github.com/<你的用户名>/<仓库名>.git
   git branch -M main
   git push -u origin main
   ```
3. 推送后进入仓库页面 → **Actions** 标签 → 等待 `Build IPA` 跑完（约 3~5 分钟）。
4. 点进本次运行 → 底部 **Artifacts** → 下载 `StockIsland-ipa`，解压得到 `StockIsland.ipa`（未签名）。

之后每次改代码，push 即自动重新构建。

## 二、安装到 iPhone（爱思助手）

**一次性准备：**

1. 电脑安装[爱思助手](https://www.i4.cn/)（自带苹果 USB 驱动，无需另装 iTunes）。
2. 准备一个 **App 专用密码**：appleid.apple.com → 登录 → 登录与安全 → App 专用密码 → 生成（开启了两步验证的 Apple ID 必须用这个，不能用账号密码）。

**安装步骤：**

1. 数据线连接 iPhone（首次连接手机上点「信任」），爱思助手识别设备。
2. 爱思助手 → **工具箱** → **自签安装**。
3. 导入 `StockIsland.ipa` → 选「使用 Apple ID 自签」→ 填 Apple ID 账号与 App 专用密码 → 签名。
4. 签名完成 → 安装到手机。
5. 手机上：设置 → 通用 → **VPN与设备管理** → 找到你的 Apple ID → 点「信任」。
6. 打开「股票灵动岛」app → 首次点「开始盯盘」时弹窗允许「实时活动」。

**注意：免费 Apple ID 签名有效期 7 天**。到期后 app 打不开时，重复上面 1~4 步重签重装即可（数据保留，两三分钟的事）。

## 三、使用说明

- **股票代码**：美股直接字母（`AAPL`、`TSLA`）；A股 6 位数字（`600519`）；港股带 hk 前缀（`hk09988`）。
- **开始盯盘后**可以锁屏、退后台，灵动岛持续刷新（默认 5 秒）。
- 点灵动岛可展开详情：名称、现价、涨跌幅、更新时间。
- 控制中心的播放指示（音频图标）是后台保活的代价，属正常现象；要彻底关掉就点 app 里「停止盯盘」。
- app 被系统杀掉时灵动岛会定格：重新打开 app 点「开始盯盘」会自动接管旧活动继续刷新。
- 美股闭市时段价格不变，建议停止盯盘省电。

## 四、常见问题

| 现象 | 处理 |
|------|------|
| 灵动岛不出现 | 设置 → 股票灵动岛 → 实时活动，确认开启；且必须在开盘价格变动后才有内容 |
| 签名 7 天过期 app 闪退 | 连电脑用爱思助手重签（见上文） |
| 安装时报「无法验证其完整性」 | 手机时间设为自动；删除残留图标并重启手机后重新自签安装 |
| 长时间后灵动岛不动了 | iOS 内存压力大杀了后台，重开 app 即恢复 |
| 构建失败 | 看 Actions 日志；一般先检查 project.yml 的 YAML 缩进 |

## 五、技术备注

- **为什么不用推送**：秒级推送需付费开发者账号（$99/年）+ APNs + 常驻服务器；无声音频保活方案零成本达到 5 秒级，代价是控制中心播放指示 + 少量耗电。
- **GBK 解码**：腾讯接口返回 GBK，Swift 用 `CFStringEncodings.GB_18030_2000` 转码。
- **涨跌幅口径**：`(现价-昨收)/昨收`（美股以昨收为基准，盘中口径）。
