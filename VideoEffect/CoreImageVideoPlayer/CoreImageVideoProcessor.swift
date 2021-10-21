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
    
    @Published var currentFilter: Filter = .none {
        didSet {
            updateVideoComposition(with: currentFilter)
        }
    }
    
    @Published var exportProgress: Float?
    
    private var timerObserver: AnyCancellable?
    
    init() {
        updateVideoComposition(with: currentFilter)
    }
    
    func updateURL(_ url: URL) {
        
        let asset = AVAsset(url: url)
        let videoComposition = createVideoComposition(asset: asset, filter: currentFilter)
        
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.videoComposition = videoComposition
        
        self.player.replaceCurrentItem(with: playerItem)
        self.player.play()
    }
    
    private func createVideoComposition(asset: AVAsset, filter: Filter) -> AVVideoComposition? {
        
        let videoComposition = AVVideoComposition(asset: asset) { request in
            
            let sourceImage: CIImage = request.sourceImage
            
            guard let filter = filter.filter else {
                request.finish(with: sourceImage, context: nil)
                return
            }
            
            do {
                let outputImage = try filter.process(image: sourceImage, at: request.compositionTime)
                request.finish(with: outputImage, context: nil)
            } catch {
                request.finish(with: error)
            }
        }
        
        return videoComposition
    }
    
    private func updateVideoComposition(with filter: Filter) {
        
        guard let asset = self.player.currentItem?.asset else {
            return
        }
        
        let videoComposition = createVideoComposition(asset: asset, filter: filter)
        
        self.player.currentItem?.videoComposition = videoComposition
    }
    
    func export(completionHandler: @escaping (Result<URL, Error>) -> Void) {
        
        guard let currentItem = player.currentItem,
              let exportSession = AVAssetExportSession(asset: currentItem.asset,
                                                       presetName: AVAssetExportPreset1280x720) else {
                  completionHandler(.failure(AVError(.unknown)))
                  return
              }
        
        let outputURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("mov")
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.videoComposition = currentItem.videoComposition
    
        timerObserver = Timer.publish(every: 0.1, on: .current, in: .default).autoconnect().sink(receiveValue: { [weak self] _ in
            
            if exportSession.status == .exporting {
                self?.exportProgress = exportSession.progress
            } else {
                self?.exportProgress = nil
            }
        })
        
        exportSession.exportAsynchronously {
            if let error = exportSession.error {
                completionHandler(.failure(error))
            } else if let url = exportSession.outputURL {
                completionHandler(.success(url))
            } else {
                completionHandler(.failure(AVError(.unknown)))
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
