//
//  AppDelegate.swift
//  GeoMndr
//
//  Created by Brandon on 6/2/17.
//  Copyright © 2017 BrandonAubrey. All rights reserved.
//

import UIKit
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let locationManager = CLLocationManager()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil))
        UIApplication.shared.cancelAllLocalNotifications()
        
        return true
    }
    
    func handleEvent(forRegion region: CLRegion!) {
        if UIApplication.shared.applicationState == .active {
            guard let message = note(fromegionIdentifier: region.identifier) else { return }
            window?.rootViewController?.showAlert(withTitle: nil, message: message)
        } else {
            let notification = UILocalNotification()
            notification.alertBody = note(fromegionIdentifier: region.identifier)
            notification.soundName = "Default"
            UIApplication.shared.presentLocalNotificationNow(notification)
        }
    }
    
    func note(fromegionIdentifier identifier: String) -> String? {
        let savedItems = UserDefaults.standard.array(forKey: PreferencesKeys.savedItems) as? [NSData]
        let geoMndrs = savedItems?.map { NSKeyedUnarchiver.unarchiveObject(with: $0 as Data) as? GeoMndr }
        let index = geoMndrs?.index { $0?.identifier == identifier }
        return index != nil ? geoMndrs?[index!]?.note : nil
    }
}

extension AppDelegate: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion {
            handleEvent(forRegion: region)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region is CLCircularRegion {
            handleEvent(forRegion: region)
        }
    }
}
