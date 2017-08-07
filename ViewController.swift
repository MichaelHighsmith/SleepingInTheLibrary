//
//  ViewController.swift
//  SleepingInTheLibrary
//
//  Created by Jarrod Parkes on 11/3/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import UIKit

// MARK: - ViewController: UIViewController

class ViewController: UIViewController {

    // MARK: Outlets
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var photoTitleLabel: UILabel!
    @IBOutlet weak var grabImageButton: UIButton!
    
    // MARK: Actions
    
    @IBAction func grabNewImage(_ sender: AnyObject) {
        setUIEnabled(false)
        getImageFromFlickr()
    }
    
    // MARK: Configure UI
    
    private func setUIEnabled(_ enabled: Bool) {
        photoTitleLabel.isEnabled = enabled
        grabImageButton.isEnabled = enabled
        
        if enabled {
            grabImageButton.alpha = 1.0
        } else {
            grabImageButton.alpha = 0.5
        }
    }
    
    // MARK: Make Network Request
    
    private func getImageFromFlickr() {
        
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.GalleryPhotosMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.GalleryID: Constants.FlickrParameterValues.GalleryID,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
        
        //create url and request
        let session = URLSession.shared
        let urlString = Constants.Flickr.APIBaseURL + escapedParameters(methodParameters as [String:AnyObject])
        let url = URL(string: urlString)!
        let request = URLRequest(url: url)
        
        let task = URLSession.shared.dataTask(with: request){ (data, response, error) in
            
            //if an error occurs, print it and re-enable the UI
            func displayError(_ error: String){
                print(error)
                print("URL at time of error: \(url)")
                performUIUpdatesOnMain {
                    self.setUIEnabled(true)
                }
            }
            
            //Guards can serve as safety checks that replace the if statements we used to check everything
            //guard: was there an error?
            guard(error == nil) else {
                displayError("There was an error with your request: \(error)")
                return
            }
            
            
            
            guard let data = data else {
                displayError("No data was returned by the request")
                return
            }
                
                //there was data returned
                let parsedResult: [String:AnyObject]!
                do {
                    parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
                } catch {
                    displayError("could not parse the data as JSON: '\(data)'")
                    return
                }
            
            

            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Are the "photos" and "photo" keys in our result? */
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject], let photoArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] else {
                displayError("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' and '\(Constants.FlickrResponseKeys.Photo)' in \(parsedResult)")
                return
            }
                        
                let randomPhotoIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
                let photoDictionary = photoArray[randomPhotoIndex] as [String:AnyObject]
                let photoTitle = photoDictionary[Constants.FlickrResponseKeys.Title] as? String
            
            guard let imageUrlString = photoDictionary[Constants.FlickrResponseKeys.MediumURL] as? String else {
                displayError("Cannot find key '\(Constants.FlickrResponseKeys.MediumURL)' in \(photoDictionary)")
                return
            }
            
                let imageURL = URL(string: imageUrlString)
                    if let imageData = try? Data(contentsOf: imageURL!){
                        performUIUpdatesOnMain {
                            self.photoImageView.image = UIImage(data: imageData)
                            self.photoTitleLabel.text = photoTitle
                            self.setUIEnabled(true)
                        }
                    } else {
                        displayError("Image does not exist at ](imageURL)")
            }

        }
        
        task.resume()
        
        
    }
    
    //take a dictionary of keyValuePairs (in the URL) and return a String where they are correctly formatted and have safe ASCII characters.  Also separate each pair by an &
    private func escapedParameters(_ parameters: [String:AnyObject]) -> String {
        
        //check that there are parameters
        if parameters.isEmpty {
            return ""
        } else {
            //create an array to store each keyValuePair
            var keyValuePairs = [String]()
            
            for(key, value) in parameters {
                
                //make sure that it is a string value
                let stringValue = "\(value)"
                
                //escape it (make it ASCII compliant)
                let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                
                //append it
                keyValuePairs.append(key + "=" + "\(escapedValue!)")
                
            }
            
            return "?\(keyValuePairs.joined(separator:"&"))"
        }
    }
    
    
    
    
    
    
    
    //API key
    //ccf09133936ed52d6e342b9fa3313b76
    
    //secret
    //a12df580e7f4b2a9
}
