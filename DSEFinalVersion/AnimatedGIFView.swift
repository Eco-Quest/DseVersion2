//
//  AnimatedGIFView.swift
//  DSEFinalVersion
//
//  Created by Matt on 2026/5/26.
//
import SwiftUI

struct AnimatedGIFView: UIViewRepresentable {
    let gifName: String
    var isAnimating: Bool = true
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        // 创建UIImageView
        let imageView = UIImageView()
        imageView.tag = 100
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // 尝试从不同来源加载GIF
        loadGIF(into: imageView)
        
        containerView.addSubview(imageView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let imageView = uiView.viewWithTag(100) as? UIImageView else { return }
        
        // 控制动画的播放与停止
        if isAnimating {
            if imageView.animationImages == nil || imageView.animationImages?.isEmpty == true {
                loadGIF(into: imageView)
            }
            imageView.startAnimating()
        } else {
            imageView.stopAnimating()
        }
    }
    
    private func loadGIF(into imageView: UIImageView) {
        // 方法1: 从Assets加载
        if let gifImage = UIImage.animatedGIF(named: gifName) {
            imageView.image = gifImage
            imageView.animationImages = gifImage.images
            imageView.animationDuration = gifImage.duration
            imageView.startAnimating()
            return
        }
        
        // 方法2: 从Bundle文件加载（如果GIF在文件系统中）
        if let path = Bundle.main.path(forResource: gifName, ofType: "gif"),
           let gifImage = UIImage.animatedGIF(at: path) {
            imageView.image = gifImage
            imageView.animationImages = gifImage.images
            imageView.animationDuration = gifImage.duration
            imageView.startAnimating()
            return
        }
        
        // 方法3: 尝试不带扩展名的加载
        if let path = Bundle.main.path(forResource: gifName, ofType: nil),
           let gifImage = UIImage.animatedGIF(at: path) {
            imageView.image = gifImage
            imageView.animationImages = gifImage.images
            imageView.animationDuration = gifImage.duration
            imageView.startAnimating()
            return
        }
        
        // 如果没有找到GIF，显示一个默认的加载动画
        imageView.image = UIImage(systemName: "hourglass")
        imageView.tintColor = .white
    }
}
extension UIImage {
    // 从Assets加载GIF
    static func animatedGIF(named name: String) -> UIImage? {
        // 首先尝试从Assets加载
        if let asset = NSDataAsset(name: name) {
            return animatedGIF(data: asset.data)
        }
        
        // 如果失败，尝试从main bundle加载
        if let path = Bundle.main.path(forResource: name, ofType: "gif"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            return animatedGIF(data: data)
        }
        
        // 如果还是失败，尝试不带扩展名
        if let path = Bundle.main.path(forResource: name, ofType: nil),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            return animatedGIF(data: data)
        }
        
        return nil
    }
    
    // 从文件路径加载GIF
    static func animatedGIF(at path: String) -> UIImage? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }
        return animatedGIF(data: data)
    }
    
    // 从Data加载GIF
    static func animatedGIF(data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        
        let count = CGImageSourceGetCount(source)
        
        // 如果是单张图片
        if count <= 1 {
            return UIImage(data: data)
        }
        
        var images = [UIImage]()
        var duration: TimeInterval = 0
        
        for i in 0..<count {
            // 获取图像
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else {
                continue
            }
            
            // 获取帧间隔时间
            let frameDuration = getFrameDuration(from: source, at: i)
            duration += frameDuration
            
            let image = UIImage(cgImage: cgImage)
            images.append(image)
        }
        
        // 创建动画图像
        let animatedImage = UIImage.animatedImage(with: images, duration: duration)
        return animatedImage
    }
    
    // 获取GIF每帧的持续时间
    private static func getFrameDuration(from source: CGImageSource, at index: Int) -> TimeInterval {
        var frameDuration: TimeInterval = 0.1
        
        // 获取帧属性
        guard let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil),
              let gifProperties = (cfProperties as NSDictionary)[kCGImagePropertyGIFDictionary] as? NSDictionary else {
            return frameDuration
        }
        
        // 尝试获取未延迟时间
        if let unclampedDelayTime = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? NSNumber {
            frameDuration = unclampedDelayTime.doubleValue
        }
        // 如果未延迟时间为0，尝试获取普通延迟时间
        else if let delayTime = gifProperties[kCGImagePropertyGIFDelayTime] as? NSNumber {
            frameDuration = delayTime.doubleValue
        }
        
        // 如果帧持续时间太短，设置一个默认值
        if frameDuration < 0.011 {
            frameDuration = 0.1
        }
        
        return frameDuration
    }
}

