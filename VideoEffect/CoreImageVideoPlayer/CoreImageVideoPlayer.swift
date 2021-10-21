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
    
    @State var outputURL: URL?
    
    @State var errorMessage: String?
    
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
            .sheet(item: $outputURL) { url in
                ActivityView(activityItems: [url])
            }
            .alert(item: $errorMessage) {
                Alert(title: Text("Error"), message: Text($0))
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Open") {
                        showsPhotoPicker = true
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        videoProcessor.export { result in
                            switch result {
                            case let .success(url):
                                self.outputURL = url
                            case let .failure(error):
                                self.errorMessage = error.localizedDescription
                            }
                        }
                    }
                }
            }
            .overlay(
                ZStack {
                    controlView
                    
                    if let progress = videoProcessor.exportProgress {
                        
                        ProgressView("Exporting... \(Int(progress * 100))%", value: progress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(width: 200)
                            .padding(30)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundColor(Color(UIColor.secondarySystemBackground))
                                    .opacity(0.9)
                            )
                    }
                }
            )
            .navigationTitle("CoreImage Video Player")
            .navigationBarTitleDisplayMode(.inline)
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
