//
//  MetalVideoProcessor.swift
//  VideoEffect
//
//  Created by 이재현 on 2021/09/01.
//

import AVFoundation
import CoreImage
import Combine
import Metal
import SwiftUI

final class MetalVideoProcessor: ObservableObject {
    
    private static let defaultURL = Bundle.main.url(forResource: "bunny", withExtension: "mp4")!
    
    let player = AVPlayer(url: defaultURL)
    
    @Published var currentFilter: Filter = .none {
        didSet {
            updateVideoComposition(with: currentFilter)
        }
    }
    
    @Published var exportProgress: Float?
    
    private var timerObserver: AnyCancellable?
    
    // MARK: Metal Components
    
    private static let device = MTLCreateSystemDefaultDevice()!
    
    private static let library = device.makeDefaultLibrary()!
    
    private let commandQueue = device.makeCommandQueue()!
    
    private let metalTextureCache = CVMetalTextureCache.makeDefault(device: device)!
    
    private let ciContext = CIContext(mtlDevice: device)
    
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
    
        timerObserver = Timer.publish(every: 0.1, on: .current, in: .default)
            .autoconnect()
            .sink(receiveValue: { [weak self] _ in
            
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

extension MetalVideoProcessor {
    
    private func createVideoComposition(asset: AVAsset, filter: Filter) -> AVVideoComposition? {
        
        let videoComposition = AVMutableVideoComposition()
        
        videoComposition.customVideoCompositorClass = Compositor.self
        videoComposition.instructions = [
            Instruction(
                timeRange: CMTimeRange(start: .zero, end: .positiveInfinity),
                handler: { [weak self] request in
                    
                    // 1. Apply preferred transform
                    
                    guard let self = self,
                          let trackID = request.sourceTrackIDs.first?.int32Value,
                          let sourcePixelBuffer = request.sourceFrame(byTrackID: trackID),
                          let transform = asset.track(withTrackID: trackID)?.preferredTransform else {
                              return
                          }
                    
                    guard let transformedPixelBuffer = request.renderContext.newPixelBuffer() else {
                        return
                    }
                    
                    let transformFilter = AnyCoreImageVideoFilter(context: self.ciContext) { image, _ in
                        if transform.isIdentity { return image }
                        return image
                            .verticallyFlipped()
                            .transformed(by: transform)
                            .verticallyFlipped()
                    }
                    
                    try transformFilter.process(sourcePixelBuffer: sourcePixelBuffer,
                                                destinationPixelBuffer: transformedPixelBuffer,
                                                at: request.compositionTime)
                    
                    // 2. Apply filter
                    
                    guard let filter = filter.filter,
                          let commandBuffer = self.commandQueue.makeCommandBuffer(),
                          let destinationPixelBuffer = request.renderContext.newPixelBuffer(),
                          let sourceTexture = transformedPixelBuffer.makeMetalTexture(textureFormat: .bgra8Unorm,
                                                                                      textureCache: self.metalTextureCache),
                          let destinationTexture = destinationPixelBuffer.makeMetalTexture(textureFormat: .bgra8Unorm,
                                                                                           textureCache: self.metalTextureCache) else {
                              request.finish(withComposedVideoFrame: transformedPixelBuffer)
                              return
                          }
                    
                    try filter.process(commandBuffer: commandBuffer,
                                       sourceTexture: sourceTexture,
                                       destinationTexture: destinationTexture,
                                       at: request.compositionTime)
                    
                    commandBuffer.commit()
                    
                    request.finish(withComposedVideoFrame: destinationPixelBuffer)
                })
        ]
        
        guard let firstVideoTrack = asset.tracks(withMediaType: .video).first else {
            return nil
        }
        
        let transformedSize = firstVideoTrack.naturalSize
            .applying(firstVideoTrack.preferredTransform)
        
        let renderSize = CGSize(width: abs(transformedSize.width), height: abs(transformedSize.height))
        videoComposition.renderSize = renderSize
        
        // 30 fps
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        
        return videoComposition
    }
}

extension MetalVideoProcessor {
    
    enum Filter: String, CaseIterable, Identifiable {
        case none = "No Filter"
        case gaussianBlur = "Gaussian Blur"
        case pixellateAnimation = "Pixellate Animation"
        case grayscaleAnimation = "Grayscale Animation"
        
        var id: String {
            self.rawValue
        }
        
        var filter: MetalVideoFilter? {
            switch self {
            case .gaussianBlur:
                return MetalVideoFilters.GaussianBlurFilter(device: MetalVideoProcessor.device)
                
            case .pixellateAnimation:
                guard let state = Self.pixellateComputePipelineState else {
                    return nil
                }
                return MetalVideoFilters.ComputeKernelFilter(computePipelineState: state)
                
            case .grayscaleAnimation:
                guard let state = Self.grayscaleComputePipelineState else {
                    return nil
                }
                return MetalVideoFilters.ComputeKernelFilter(computePipelineState: state)
                
            default:
                return nil
            }
        }
        
        private static let pixellateComputePipelineState: MTLComputePipelineState? = {
            guard let function = MetalVideoProcessor.library.makeFunction(name: "pixellateAnimationFilter") else {
                fatalError("Failed to create pixellateFilter function.")
            }
            return try? MetalVideoProcessor.device.makeComputePipelineState(function: function)
        }()
        
        private static let grayscaleComputePipelineState: MTLComputePipelineState? = {
            guard let function = MetalVideoProcessor.library.makeFunction(name: "grayscaleAnimationFilter") else {
                fatalError("Failed to create grayscaleColorFilter function.")
            }
            return try? MetalVideoProcessor.device.makeComputePipelineState(function: function)
        }()
    }
}
