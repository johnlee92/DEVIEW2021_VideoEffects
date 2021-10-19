//
//  SimpleVideoPlayerView.swift
//  VideoEffect
//
//  Created by 이재현 on 2021/09/24.
//

import SwiftUI
import AVKit

class SimpleVideoPlayerViewModel: ObservableObject {
    
    private static let defaultURL = Bundle.main.url(forResource: "bunny", withExtension: "mp4")!
    
    let player = AVPlayer(url: defaultURL)
}

struct SimpleVideoPlayerView: View {
    
    @StateObject var model = SimpleVideoPlayerViewModel()
    
    @State var showsPhotoPicker: Bool = false
    
    var body: some View {
        
        VideoPlayer(player: model.player)
            .aspectRatio(1.0, contentMode: .fit)
            .onAppear {
                model.player.play()
            }
            .onDisappear {
                model.player.pause()
            }
            .sheet(isPresented: $showsPhotoPicker, content: {
                PhotoPicker(configuration: .default,
                            isPresented: $showsPhotoPicker) { result in
                    if case let .success(url) = result {
                        model.player.replaceCurrentItem(with: AVPlayerItem(url: url))
                    }
                }
            })
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Open") {
                        showsPhotoPicker = true
                    }
                }
            }
            .navigationBarTitle("Video Player", displayMode: .inline)
    }
}
