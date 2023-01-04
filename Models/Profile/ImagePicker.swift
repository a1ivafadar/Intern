//
//  ImagePicker.swift
//  Intern
//
//  Created by Ali on 20/03/21.
//

import Foundation
import SwiftUI
import UIKit

final class Camera: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    //@ObservableObject var output: Image
    
    let uiImage = UIImage()
    
    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) -> Image {
        picker.dismiss(animated: true, completion: nil)
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return Image("")
        }
        
        let image = Image(uiImage: uiImage)
        return image
        
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    
    
    @Environment(\.presentationMode)
    private var presentationMode
    
    
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void
    let allowsEditing: Bool
    
    final class Coordinator: NSObject,
                             UINavigationControllerDelegate,
                             UIImagePickerControllerDelegate {
        
        @Binding
        private var presentationMode: PresentationMode
        private let sourceType: UIImagePickerController.SourceType
        private let allowsEditing: Bool
        private let onImagePicked: (UIImage) -> Void
        
        init(presentationMode: Binding<PresentationMode>,
             sourceType: UIImagePickerController.SourceType, allowsEditing: Bool,
             onImagePicked: @escaping (UIImage) -> Void) {
            _presentationMode = presentationMode
            self.sourceType = sourceType
            self.allowsEditing = allowsEditing
            self.onImagePicked = onImagePicked
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let uiImage = info[UIImagePickerController.InfoKey.editedImage] as! UIImage
            onImagePicked(uiImage)
            
            presentationMode.dismiss()
            
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            presentationMode.dismiss()
        }
        
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(presentationMode: presentationMode,
                           sourceType: sourceType, allowsEditing: allowsEditing,
                           onImagePicked: onImagePicked)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = allowsEditing
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController,
                                context: UIViewControllerRepresentableContext<ImagePicker>) {
        
    }
    
}
//struct ImagePicker2 : UIViewControllerRepresentable {
//
//    class Coordinator : NSObject , UINavigationControllerDelegate, UIImagePickerControllerDelegate {
//        let parent : ImagePicker
//
//        init(_ parent : ImagePicker){
//            self.parent = parent
//        }
//
//        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//            if let uiimage = info[.editedImage] as? UIImage{
//                parent.image = uiimage
//            }
//            parent.presentationMode.wrappedValue.dismiss()
//        }
//    }
//
//    @Environment(\.presentationMode) var presentationMode
//    @Binding var image : UIImage?
//    @State var source : UIImagePickerController.SourceType
//
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//
//    func makeUIViewController(context: Context) -> UIImagePickerController {
//        let picker = UIImagePickerController()
//        picker.delegate = context.coordinator
//        picker.sourceType = source
//        picker.allowsEditing = true
//        return picker
//    }
//
//    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
//
//    }
//
//}
