//
//  AudioKeeper.swift
//  无声音频后台保活：循环播放0.5秒静音WAV，让iOS把app当"正在播放音乐"
//  保持后台存活，从而持续轮询行情并更新灵动岛
//

import AVFoundation

final class AudioKeeper {
    private var player: AVAudioPlayer?

    func start() {
        if player?.isPlaying == true { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)

            let p = try AVAudioPlayer(data: Self.silentWavData())
            p.numberOfLoops = -1   // 无限循环
            p.volume = 0.0
            p.play()
            player = p
        } catch {
            NSLog("audio keeper failed: \(error)")
        }
    }

    func stop() {
        player?.stop()
        player = nil
        try? AVAudioSession.sharedInstance().setActive(
            false, options: [.notifyOthersOnDeactivation])
    }

    /// 生成 8kHz 16bit 单声道 0.5秒 静音 WAV
    static func silentWavData() -> Data {
        let sampleRate = 8000
        let numSamples = 4000
        let dataSize = UInt32(numSamples * 2)   // 16bit = 2字节/样本

        var data = Data()
        func le32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
        func le16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }

        data.append(contentsOf: Array("RIFF".utf8))
        le32(36 + dataSize)
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8))
        le32(16)                 // fmt块大小
        le16(1)                  // PCM
        le16(1)                  // 单声道
        le32(UInt32(sampleRate))
        le32(UInt32(sampleRate * 2))  // 字节率 = 采样率*块对齐
        le16(2)                  // 块对齐
        le16(16)                 // 位深
        data.append(contentsOf: Array("data".utf8))
        le32(dataSize)
        data.append(Data(count: Int(dataSize)))  // 全零 = 静音
        return data
    }
}
