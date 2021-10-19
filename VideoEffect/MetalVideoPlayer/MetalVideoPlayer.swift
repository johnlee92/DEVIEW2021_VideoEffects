//
//  MetalVideoPlayer.swift
//  VideoEffect
//
//  Created by 이재현 on 2021/09/24.
//

import SwiftUI
import AVKit
import PhotosUI

struct MetalVideoPlayer: View {

    @StateObject var videoProcessor = MetalVideoProcessor()
    
    @State var showsPhotoPicker: Bool = false
    
    @State var activityItem: URL?
    
    @State var alertMessage: String?
    
    var body: some View {
        
        VideoPlayer(player: videoProcessor.player)
            .overlay(controlView)
            .aspectRatio(1, contentMode: .fit)
            .onAppear() {
                videoProcessor.player.play()
            }
            .onDisappear() {
                videoProcessor.player.pause()
            }
            .onChange(of: videoProcessor.player) { player in
                player.play()
            }
            .sheet(isPresented: $showsPhotoPicker) {
                PhotoPicker(configuration: .default,
                            isPresented: $showsPhotoPicker) { url in
                    if case let .success(url) = url {
                        videoProcessor.updateURL(url)
                    }
                }
            }
            .sheet(item: $activityItem) { item in
                ActivityView(activityItems: [item])
            }
            .toolbar {
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Open") {
                        showsPhotoPicker = true
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    
                    if let progress = self.videoProcessor.exportProgress {
                        
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(width: 72)
                        
                    } else {
                        Button("Export") {
                            videoProcessor.export { result in
                                switch result {
                                case let .success(url):
                                    self.activityItem = url
                                case let .failure(error):
                                    self.alertMessage = error.localizedDescription
                                }
                            }
                        }
                    }
                }
            }
            .alert(item: $alertMessage) { message in
                Alert(title: Text("Alert"), message: Text(message))
            }
            .navigationBarTitle("Metal Video Player", displayMode: .inline)
    }
    
    private var controlView: some View {
        
        VStack {
            
            HStack {
                
                Picker(selection: $videoProcessor.currentFilter,
                       label: Text(videoProcessor.currentFilter.rawValue)) {
                    ForEach(MetalVideoProcessor.Filter.allCases) { filter in
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
