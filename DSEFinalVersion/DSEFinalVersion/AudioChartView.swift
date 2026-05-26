/*import SwiftUI
// 自定义渐变类型
struct MyGradient {
    var colors: [Color]
    
    // 自定义方法将你的渐变转换为 SwiftUI 的渐变
    func toSwiftUIGradient() -> SwiftUI.Gradient {
        return SwiftUI.Gradient(colors: colors)
    }
}


struct AudioChartView: View {
    @State private var isVisualize: Bool = true
    @State private var timer: Timer?
    @State private var averageDb: Float = 0

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                HStack(spacing: 10) {
                    let availableWidth = geometry.size.width
                   
                    
                    let numberOfBars = Int(availableWidth / 20)

                    ForEach(0..<numberOfBars, id: \.self) { _ in
                        let normalizedDb = min(max(CGFloat(AudioProcessing.averageDb), 0.1), 10) / 10.0
                        let maxBarHeight = geometry.size.height * 0.6
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                                           LinearGradient(
                                                               gradient: MyGradient(colors: [Color(hex: "#63BEF3"), Color(hex: "#5C43A9")]).toSwiftUIGradient(),
                                                               startPoint: .top,
                                                               endPoint: .bottom
                                                           )
                                                       )
                            .frame(width: 10, height: averageDb == 0 ? 15 : .random(in: 0...CGFloat(averageDb)))
                          
                            .animation(.easeInOut(duration: 0.25), value: averageDb) // 使用 averageDb 作為動畫的綁定值
                    }
                    
           
                }
                Spacer()
            }
            .background(.clear)
            .ignoresSafeArea(.all)
            .onAppear {
                startTimer()
            }
            .onDisappear {
                stopTimer()
                
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            withAnimation {
                if AudioProcessing.averageDb > 0{
                    if AudioProcessing.averageDb == 1.0{
                        averageDb = 0
                    }else{
                        averageDb = AudioProcessing.averageDb * 0.6
                    }
                    
                   
                }else{
                    averageDb = AudioProcessing.averageDb // 更新分贝值
                }
              
               
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}


//以前source code有

import AVFoundation
import Accelerate
import SwiftUI
import UIKit

enum Constants {
    static let updateInterval = 0.03
    static let barAmount = 40
    static var magnitudeLimit: Float = 32
}

class AudioProcessing {
    static var shared = AudioProcessing()
    static var soundName = "CAN01"
    
    private let engine = AVAudioEngine()
    private let bufferSize = 1024
    private let player = AVAudioPlayerNode()
    static var fftMagnitudes: [Float] = []
    static var averageDb: Float = 0.0
    private var fftSetup: OpaquePointer?

    init() {
        configureAudioSession()
        setupEngine()
        setupFFT()
        startEngine()
    }
    
    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set audio session category for playback: \(error)")
        }
    }
    
    private func setupEngine() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: UInt32(bufferSize), format: nil) { [weak self] buffer, _ in
            guard let self = self else { return }
            self.processAudioBuffer(buffer)
        }
    }
    
    private func setupFFT() {
        fftSetup = vDSP_DFT_zop_CreateSetup(nil, UInt(bufferSize), vDSP_DFT_Direction.FORWARD)
    }
    
    private func startEngine() {
        engine.prepare()
        do {
            try engine.start()
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }
    
    // 新增重啟音頻引擎的方法
    func restartEngine() {
        stopEngine()
        startEngine()
    }
    
    func stopEngine() {
        player.stop()
        engine.stop()
    }
    
    func playSound(named name: String) {
        AudioProcessing.soundName = name
        
        guard let soundURL = Bundle.main.url(forResource: name, withExtension: "MP3") else {
            print("Error: Audio file \(name) not found.")
            return
        }
        
        do {
            let audioFile = try AVAudioFile(forReading: soundURL)
            player.stop()
            player.scheduleFile(audioFile, at: nil)
            player.play()
        } catch {
            print("Error loading audio file: \(error)")
        }
    }
    
    func play() {
        player.play()
    }
    
    func pause() {
        player.pause()
    }
    
    func stop() {
        player.stop()
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        AudioProcessing.fftMagnitudes = fft(data: channelData)
        
        if let averageDb = calculateDecibels(from: AudioProcessing.fftMagnitudes) {
            AudioProcessing.averageDb = abs(averageDb)
        }
    }
    
    private func fft(data: UnsafePointer<Float>) -> [Float] {
        guard let fftSetup = fftSetup else { return [] }
        
        var realIn = [Float](repeating: 0, count: bufferSize)
        var imagIn = [Float](repeating: 0, count: bufferSize)
        var realOut = [Float](repeating: 0, count: bufferSize)
        var imagOut = [Float](repeating: 0, count: bufferSize)
        
        for i in 0..<bufferSize {
            realIn[i] = data[i]
        }
        
        vDSP_DFT_Execute(fftSetup, &realIn, &imagIn, &realOut, &imagOut)
        
        var magnitudes = [Float](repeating: 0, count: Constants.barAmount)
        realOut.withUnsafeMutableBufferPointer { realBP in
            imagOut.withUnsafeMutableBufferPointer { imagBP in
                var complex = DSPSplitComplex(realp: realBP.baseAddress!, imagp: imagBP.baseAddress!)
                vDSP_zvabs(&complex, 1, &magnitudes, 1, UInt(Constants.barAmount))
            }
        }
        
        var normalizedMagnitudes = [Float](repeating: 0.0, count: Constants.barAmount)
        vDSP_vsmul(&magnitudes, 1, &Constants.magnitudeLimit, &normalizedMagnitudes, 1, UInt(Constants.barAmount))
        
        return normalizedMagnitudes
    }
    
    private func calculateDecibels(from magnitudes: [Float]) -> Float? {
        guard !magnitudes.isEmpty else { return nil }
        
        let sum = magnitudes.reduce(0) { $0 + ($1 > 0 ? 10 * log10($1) : 0) }
        return sum / Float(magnitudes.count)
    }
    
    deinit {
        if let fftSetup = fftSetup {
            vDSP_DFT_DestroySetup(fftSetup)
        }
        engine.mainMixerNode.removeTap(onBus: 0)
    }
}

// MARK: - 颜色扩展
extension Color {
    static let brandPrimary = Color(hex: "63BEF3")
     static let brandSecondary = Color(hex: "FFCC41")
     static let brandAccent = Color(hex: "5C43A9")
     static let brandBackground = Color("systemBackgroundColor")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
   
        AudioChartView()
  
}
*/
