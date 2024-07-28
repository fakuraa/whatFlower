//
//  ViewController.swift
//  WhatFlower
//
//  Created by Fadil Kurniawan on 28/07/24.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imgView: UIImageView!
    let imagePicker = UIImagePickerController()
    let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    
    @IBOutlet weak var flowerDescription: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
    }


    @IBAction func cameraPress(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
//            imgView.image = userPickedImage
            
            guard let ciimage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert into CIImage")
            }
            detect(image: ciimage)
        }
        imagePicker.dismiss(animated: true)
    }
    
    func detect(image:CIImage){
            guard let model = try? VNCoreMLModel(for: FloweClassifier().model) else {
                fatalError("Loading CoreML Model Failed.")
            }
        
        let request = VNCoreMLRequest(model: model){(request,error) in
            guard let results = request.results?.first as? VNClassificationObservation else{
                fatalError("Model Failed to process image")
            }
//            print(results)
                self.navigationItem.title = results.identifier.capitalized
            self.reqInfo(flowername: results.identifier)
            
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do{
            try handler.perform([request])
        }catch{
            print(error)
        }
    }
    
    func reqInfo(flowername:String){
        let parameters : [String : String] = [
            "format" : "json",
            "action" : "query",
            "prop":"extracts|pageimages",
//            "exintro":"",
//            "explaintext":"",
            "titles":flowername,
            "indexpageids":"1",
            "redirects":"1",
            "formatversion":"1",
            "pithumbsize":"500",
        ]
//    https://en.wikipedia.org/w/api.php?action=query&format=json&prop=extracts&indexpageids=1&titles=Passion%20flower&redirects=1&formatversion=1
        Alamofire.request(wikipediaURL, method: .get, parameters: parameters).responseJSON{(response) in
            if response.result.isSuccess{
                let flowerJson = JSON(response.result.value)
                print(flowerJson)
                let pageid = flowerJson["query"]["pageids"][0].stringValue
                let flowerDesc = flowerJson["query"]["pages"][pageid]["extract"].stringValue
                let flowerImgUrl = flowerJson["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                self.imgView.sd_setImage(with: URL(string: flowerImgUrl))
                self.flowerDescription.text = flowerDesc
            }
            
        }
    }

}

