//
//  PhotoPicker.swift
//  VideoEffect
//
//  Created by 이재현 on 2021/08/30.
//

import SwiftUI
import PhotosUI

struct PhotoPicker: UIViewControllerRepresentable {
    
    let configuration: PHPickerConfiguration
    
    @Binding var isPresented: Bool
    
    let handler: (Result<URL, Error>) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(context: self)
    }
    
    class Coordinator: PHPickerViewControllerDelegate {
        
        private let context: PhotoPicker
        
        init(context: PhotoPicker) {
            self.context = context
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            
            results.forEach {
                
                if $0.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    handleItemProvider($0.itemProvider, typeIdentifier: UTType.movie.identifier)
                } else if $0.itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    handleItemProvider($0.itemProvider, typeIdentifier: UTType.image.identifier)
                }
            }
            
            context.isPresented = false
        }
        
        private func handleItemProvider(_ itemProvider: NSItemProvider, typeIdentifier: String) {
            
            itemProvider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
                
                if let error = error {
                    self.context.handler(.failure(error))
                    return
                }
                
                guard let url = url else { return }
                
                let destinationURL = FileManager.default
                    .temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(url.pathExtension)
                
                try? FileManager.default.copyItem(at: url, to: destinationURL)
                
                self.context.handler(.success(destinationURL))
            }
        }
    }
}

extension PHPickerConfiguration {

    static var `default`: PHPickerConfiguration {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = PHPickerFilter.videos
        configuration.preferredAssetRepresentationMode = .current
        return configuration
    }
}
