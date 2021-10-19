//
//  ContentView.swift
//  VideoEffect
//
//  Created by 이재현 on 2021/08/30.
//

import SwiftUI

struct MainView: View {
    
    var body: some View {
        
        NavigationView {
            
            List {
                
                NavigationLink(destination: SimpleVideoPlayerView()) {
                    Text("Video Player")
                }
                
                NavigationLink(destination: CoreImageVideoPlayer()) {
                    Text("CoreImage Video Player")
                }
                
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle("Video Effects")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
