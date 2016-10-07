//
//  ImageLoader.swift
//  extension
//
//  Created by Nate Lyman on 7/5/14.
//  Copyright (c) 2014 NateLyman.com. All rights reserved.
//
// Extracted from
// https://github.com/natelyman/SwiftImageLoader
//

import UIKit
import Foundation


class ImageLoader {
    
    let cache = NSCache<AnyObject, AnyObject>()

    class var sharedLoader : ImageLoader {
    struct Static {
        static let instance : ImageLoader = ImageLoader()
        }
        return Static.instance
    }
    
	func imageForUrl(_ urlString: String, completionHandler:@escaping (_ image: UIImage?, _ url: String) -> ()) {
        DispatchQueue.global(qos: DispatchQoS.background.qosClass).async {
			let data: Data? = self.cache.object(forKey: urlString as AnyObject) as? Data
			
			if let goodData = data {
				let image = UIImage(data: goodData)
                DispatchQueue.main.async {
					completionHandler(image, urlString)
				}
				return
			}
            let downloadTasks: URLSessionDataTask = URLSession.shared.dataTask(with: URL(string: urlString)!) { data, response, error in
                if (error != nil) {
                    completionHandler(nil, urlString)
                    return
                }
                
                if let data = data {
                    let image = UIImage(data: data)
                    self.cache.setObject(data as AnyObject, forKey: urlString as AnyObject)
                    DispatchQueue.main.async {
                        completionHandler(image, urlString)
                    }
                    return
                }
            }
            downloadTasks.resume()
		}
		
	}
}
