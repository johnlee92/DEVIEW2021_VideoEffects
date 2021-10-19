//
//  ActivityView.swift
//  VideoEffect
//
//  Created by 이재현 on 2021/09/01.
//

import Foundation
import SwiftUI

struct ActivityView: UIViewControllerRepresentable {

    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityView>) -> UIActivityViewController {
        
        let controller = UIActivityViewController(activityItems: activityItems,
                                                  applicationActivities: applicationActivities)
        
        controller.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            self.presentationMode.wrappedValue.dismiss()
        }
        
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityView>) {
        
    }
}
