//
//  CoreImageVideoProcessor.swift
//  VideoEffect
//
//  Created by 이재현 on 2021/09/27.
//

import AVFoundation
import CoreImage
import Combine

final class CoreImageVideoProcessor: ObservableObject {
    
    private static let defaultURL = Bundle.main.url(forResource: "bunny", withExtension: "mp4")!
    
    let player = AVPlayer(url: defaultURL)
    
    @Published
    var currentFilter: Filter = .none {
        didSet {
            updateVideoComposition()
        }
    }
    
    @Published
    private(set) var exportProgress: Float?
    
    private var timerObserver: AnyCancellable?
    
    init() {
        updateVideoComposition()
    }
    
    func updateURL(_ url: URL) {
        
        let asset = AVAsset(url: url)
        let videoComposition = createVideoComposition(asset: asset)
        
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.videoComposition = videoComposition
        
        self.player.replaceCurrentItem(with: playerItem)
        self.player.play()
    }
    
    private func createVideoComposition(asset: AVAsset) -> AVVideoComposition? {
        
        let videoComposition = AVVideoComposition(asset: asset) { request in
            
            let sourceImage: CIImage = request.sourceImage
            
            guard let filter = self.currentFilter.filter else {
                request.finish(with: sourceImage, context: nil)
                return
            }
            
            do {
                let outputImage = try filter.process(image: sourceImage,
                                                     at: request.compositionTime)
                request.finish(with: outputImage, context: nil)
            } catch {
                request.finish(with: error)
            }
        }
        
        return videoComposition
    }
    
    private func updateVideoComposition() {
        
        guard let asset = self.player.currentItem?.asset else {
            return
        }
        
        let videoComposition = createVideoComposition(asset: asset)
        
        self.player.currentItem?.videoComposition = videoComposition
    }
    
    func export(completion: @escaping (Result<URL, Error>) -> Void) {
        
        guard let currentItem = self.player.currentItem,
              let exportSession = AVAssetExportSession(asset: currentItem.asset,
                                                       presetName: AVAssetExportPreset1280x720) else {
                  return
              }
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.videoComposition = currentItem.videoComposition
        
        self.timerObserver = Timer.publish(every: 0.1, on: .main, in: .default)
            .autoconnect()
            .sink(receiveValue: { _ in
                if exportSession.status == .completed {
                    self.exportProgress = nil
                } else {
                    self.exportProgress = exportSession.progress
                }
            })
        
        exportSession.exportAsynchronously { [weak exportSession] in
            
            if let error = exportSession?.error {
                completion(.failure(error))
            } else if let outputURL = exportSession?.outputURL {
                completion(.success(outputURL))
            } else {
                completion(.failure(AVError(.unknown)))
            }
        }
    }
}

extension CoreImageVideoProcessor {
    
    enum Filter: String, CaseIterable, Identifiable {
        case none = "No Filter"
        case invert = "Invert"
        case gaussianBlur = "Gaussian Blur"
        case grayscale = "Grayscale"
        
        var filter: CoreImageVideoFilter? {
            switch self {
            case .invert:
                return CoreImageVideoFilters.InvertColorFilter()
            case .gaussianBlur:
                return CoreImageVideoFilters.GaussianBlurFilter()
            case .grayscale:
                return CoreImageVideoFilters.GrayscaleColorFilter()
            default:
                return nil
            }
        }
        
        var id: String {
            self.rawValue
        }
    }
}
