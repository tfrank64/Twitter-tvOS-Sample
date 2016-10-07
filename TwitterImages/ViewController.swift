/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import UIKit

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
  
    @IBOutlet weak var collectionView: UICollectionView!
    var wallImages = [UIImage]()
    var combinedImages = [UIImage]()
    var scrollingPoint = CGPoint(x: 0, y: 0)
    var endingPoint = CGPoint.zero

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self

        authenticateRequest(TwitterDataManager.sharedInstance.mediaWallURL)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return combinedImages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "stadiumCell", for: indexPath) as? StadiumCollectionViewCell {
            cell.stadiumImageView.image = combinedImages[indexPath.row]
            return cell
        }
        return UICollectionViewCell()
    }
    
    func beginSlowScroll() {

        endingPoint = CGPoint(x: view.frame.size.width * 2, y: 0)
        Timer.scheduledTimer(timeInterval: 0.030, target: self, selector: #selector(ViewController.scrollSlowlyToPoint), userInfo: nil, repeats: true)
    }
    
    func scrollSlowlyToPoint() {
        
        collectionView.contentOffset = scrollingPoint

        // Detect when scrolled to the end and scroll without animation to index 0
        if scrollingPoint.equalTo(endingPoint) {
            // reset scrolling point and instantly scroll to first cell
            scrollingPoint.x = 0
        }
        
        scrollingPoint = CGPoint(x: scrollingPoint.x + 1, y: scrollingPoint.y)
    }
    
    func setupCollectionViewData() {
        
        if wallImages.count == 120 {
            // append data from first full screen to all data so we have data to fill 3 screens
            let half = wallImages.count / 2
            let screenOneData = Array(wallImages[0 ..< half])
            combinedImages = wallImages + screenOneData
        } else {
            combinedImages = wallImages
        }
        
    }
  
    // MARK: Remote data call methods
  
    func authenticateRequest(_ url:String) {

        // if using twitter, use this method. Add more auth methods if necessary, later
        TwitterDataManager.sharedInstance.getBearerToken { bearerToken in
          
            var request = URLRequest(url: URL(string: url)!)
            request.httpMethod = "GET"
          
            let token = "Bearer " + bearerToken
            request.addValue(token, forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let validData = data , error == nil {
                    do {
                        let results = try JSONSerialization.jsonObject(with: validData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String : AnyObject]
                        if let resultDictionary = results {
                            self.processMediaWall(resultDictionary)
                        }
                        
                    } catch let error as NSError {
                        print(error.localizedDescription)
                    }
                } else {
                    print(error?.localizedDescription)
                }
            }.resume()
        }

    }
  
    func processMediaWall(_ results: [String : AnyObject]) {

        var mediaURLs = [String]()
        if let statuses = results["statuses"] as? [AnyObject] {
            
            // 1 extract image urls from all the twitter data
            for status in statuses {
                
                // unrap all the things, to get to a mediaURL of an image
                if let entities = status["entities"] as? [String : AnyObject], let mediaArray = entities["media"] as? [AnyObject],
                    let media = mediaArray.first as? [String : AnyObject], let mediaURL = media["media_url"] as? String {
                    
                    mediaURLs.append(mediaURL + ":small")
                }
            }
            
            // 2 repeat images if less than 120
            if mediaURLs.count < 120 {
                
                let tempArray = mediaURLs
                // repeat loop until we have enough media URLs
                parentLoop: while mediaURLs.count < 120 {
                    childLoop: for url in tempArray {
                        
                        mediaURLs.append(url)
                        if mediaURLs.count == 120 {
                            break parentLoop
                        }
                    }
                }
            }
            
            // 3 pull images from server using URLs from Twitter
            var images = [UIImage]()
            for url in mediaURLs {
                ImageLoader.sharedLoader.imageForUrl(url, completionHandler: { (image, url) -> () in
                    if let remoteImage = image {
                        images.append(remoteImage)
                        self.populateMediaWall(images)
                    }
                })
            }
        }

    }
    
    func populateMediaWall(_ images: [UIImage]) {

        wallImages = images
        setupCollectionViewData()
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()

            if self.wallImages.count == 120 {
                self.beginSlowScroll()
                self.wallImages.removeAll()
            }
        }
    }

}

