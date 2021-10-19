//
//  CoreImageVideoPlayer.swift
//  VideoEffect
//
//  Created by 이재현 on 2021/09/27.
//

import SwiftUI
import AVKit

struct CoreImageVideoPlayer: View {

    @StateObject var videoProcessor = CoreImageVideoProcessor()
    
    @State var showsPhotoPicker: Bool = false
    
    var body: some View {
        
        VideoPlayer(player: videoProcessor.player)
            .aspectRatio(1, contentMode: .fit)
            .onAppear() {
                videoProcessor.player.play()
            }
            .onDisappear() {
                videoProcessor.player.pause()
            }
            .sheet(isPresented: $showsPhotoPicker) {
                PhotoPicker(configuration: .default,
                            isPresented: $showsPhotoPicker) { url in
                    if case let .success(url) = url {
                        videoProcessor.updateURL(url)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Open") {
                        showsPhotoPicker = true
                    }
                }
            }
            .overlay(controlView)
            .navigationBarTitle("CoreImage Video Player", displayMode: .inline)
    }
    
    private var controlView: some View {
        
        VStack {
            
            HStack {
                
                Picker(selection: $videoProcessor.currentFilter,
                       label: Text(videoProcessor.currentFilter.rawValue)) {
                    ForEach(CoreImageVideoProcessor.Filter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
               .pickerStyle(MenuPickerStyle())
               .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
               .background(
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(Color(UIColor.secondarySystemBackground))
                        .opacity(0.9)
               )
                
                Spacer()
            }
            .padding()
            
            Spacer()
        }
    }
}
