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
/// Handles the calls to the Twitter API
class TwitterDataManager: NSObject {
    
    var twitterConsumerKey = ""
    var twitterConsumerSecret = ""
    var twitterAuthURL = ""
    var mediaWallURL = ""
  
    static let sharedInstance = TwitterDataManager()
    fileprivate override init() {
        
        if let path = Bundle.main.path(forResource: "TwitterInfo", ofType: "plist") {
            if let myDictionary = NSDictionary(contentsOfFile: path) {
                
                if let key = myDictionary["twitterConsumerKey"] as? String, let secret = myDictionary["twitterConsumerSecret"] as? String,
                    let authURL = myDictionary["twitterAuthURL"] as? String, let mediaURL = myDictionary["mediaWallURL"] as? String {
                    
                        self.twitterConsumerKey = key
                        self.twitterConsumerSecret = secret
                        self.twitterAuthURL = authURL
                        self.mediaWallURL = mediaURL
                }
            }
        }
        
    }
    
    // MARK: App only Auth tasks for Twitter
    // extracted from https://github.com/rshankras/SwiftDemo
    
    func getBearerToken(_ completion: @escaping (_ bearerToken: String) ->Void) {
        var request = URLRequest(url: URL(string: twitterAuthURL)!)
        
        request.httpMethod = "POST"
        request.addValue("Basic " + getBase64EncodeString(), forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        let grantType =  "grant_type=client_credentials"
        
        request.httpBody = grantType.data(using: String.Encoding.utf8, allowLossyConversion: true)

        URLSession.shared.dataTask(with: request) { data, response, error in
            
            guard let authData = data else {
                print(error?.localizedDescription)
                return
            }
            
            do {
                let results: NSDictionary = try JSONSerialization.jsonObject(with: authData, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
                if let token = results["access_token"] as? String {
                    completion(token)
                } else {
                    print(results["errors"])
                }
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }.resume()
        
    }
    
    func getBase64EncodeString() -> String {
        
        let consumerKeyRFC1738 = twitterConsumerKey.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)
        let consumerSecretRFC1738 = twitterConsumerSecret.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)
        
        let concatenateKeyAndSecret = consumerKeyRFC1738! + ":" + consumerSecretRFC1738!
        
        let secretAndKeyData = concatenateKeyAndSecret.data(using: String.Encoding.ascii, allowLossyConversion: true)
        
        let base64EncodeKeyAndSecret = secretAndKeyData?.base64EncodedString(options: NSData.Base64EncodingOptions())
        
        return base64EncodeKeyAndSecret!
    }

}
