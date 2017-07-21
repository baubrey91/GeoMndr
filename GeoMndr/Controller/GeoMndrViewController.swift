//
//  GeotificationViewController.swift
//  GeoMndr
//
//  Created by Brandon on 6/9/17.
//  Copyright © 2017 BrandonAubrey. All rights reserved.
//

import UIKit
import CoreLocation
import ContextMenu_iOS

struct PreferencesKeys {
    static let savedItems = "savedItems"
}

let menuCellIdentifier = "rotationCell"

class GeoMndrViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, YALContextMenuTableViewDelegate {
    
    @IBOutlet weak var geoMndrTableView: UITableView!
    
    var geoMndrs: [GeoMndr] = []
    
    var menuTitles: [String?] = []
    var menuIcons: [UIImage?] = []
    var enterExit: EventType = .onExit
    var contextMenuTableView: YALContextMenuTableView?
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initiateMenuOptions()
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        loadAllGeoMndrs()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "addGeomndrSegue" {
            let navigationController = segue.destination as! UINavigationController
            let vc = navigationController.viewControllers.first as! AddGeoMndrViewController
            vc.entryExit = enterExit
            vc.delegate = self
        }
        
        if segue.identifier == "mapSegue" {
            let navigationController = segue.destination as! UINavigationController
            let vc = navigationController.viewControllers.first as! MapViewController
            vc.geoMndrs = geoMndrs
            vc.delegate = self
        }
    }
    
    // MARK: Loading and saving functions
    func loadAllGeoMndrs() {
        geoMndrs = []
        guard let savedItems = UserDefaults.standard.array(forKey: PreferencesKeys.savedItems) else { return }
        for savedItem in savedItems {
            guard let geoMndr = NSKeyedUnarchiver.unarchiveObject(with: savedItem as! Data) as? GeoMndr else { continue }
            geoMndrs.append(geoMndr)
        }
    }
    
    func saveAllGeoMndrs() {
        var items: [Data] = []
        for geoMndr in geoMndrs {
            let item = NSKeyedArchiver.archivedData(withRootObject: geoMndr)
            items.append(item)
        }
        UserDefaults.standard.set(items, forKey: PreferencesKeys.savedItems)
    }
    
    // MARK: Functions that update the model/associated views with geotification changes
    func remove(geoMndr: GeoMndr) {
        if let indexInArray = geoMndrs.index(of: geoMndr) {
            geoMndrs.remove(at: indexInArray)
        }
    }

    func region(withGeoMndr geoMndr: GeoMndr) -> CLCircularRegion {
        let region = CLCircularRegion(center: geoMndr.coordinate, radius: geoMndr.radius, identifier: geoMndr.identifier)
        region.notifyOnEntry = (geoMndr.eventType == .onEntry)
        region.notifyOnExit = !region.notifyOnExit
        return region
    }
    
    func startMonitoring(geoMndr: GeoMndr) {
        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            showAlert(withTitle: "Error", message: "Geofencing is not supported on this device")
            return
        }
        if CLLocationManager.authorizationStatus() != .authorizedAlways{
            showAlert(withTitle:"Warning", message: "Your geoMndr is saved but will only be activated once you grant Geotify permission to access the device location.")
        }
        
        let region = self.region(withGeoMndr: geoMndr)
        locationManager.startMonitoring(for: region)
    }
    
    func stopMonitoring(geoMndr: GeoMndr) {
        for region in locationManager.monitoredRegions {
            guard let circularRegion = region as? CLCircularRegion,
                circularRegion.identifier == geoMndr.identifier else { continue }
            locationManager.stopMonitoring(for: circularRegion)
        }
    }
    
    @IBAction func onMenuButton(_ sender: Any) {
        
        self.contextMenuTableView = YALContextMenuTableView(tableViewDelegateDataSource: self)
        self.contextMenuTableView!.animationDuration = 0.11;
        //optional - implement custom YALContextMenuTableView custom protocol
        self.contextMenuTableView!.yalDelegate = self
        let cellNib = UINib(nibName: "ContextMenuCell", bundle: nil)
        self.contextMenuTableView?.register(cellNib, forCellReuseIdentifier: menuCellIdentifier)
        
        // it is better to use this method only for proper animation
        self.contextMenuTableView?.show(in: self.navigationController!.view, with: UIEdgeInsets.zero, animated: true)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: nil, completion: {(context: UIViewControllerTransitionCoordinatorContext!) -> Void in
            self.contextMenuTableView!.reloadData()
        })
        
        self.contextMenuTableView!.updateAlongsideRotation()
    }
    
    func contextMenuTableView(_ contextMenuTableView: YALContextMenuTableView!, didDismissWith indexPath: IndexPath!) {
        print("Menu dismissed with indexpath = \(indexPath)")
        switch indexPath.row {
        case 1:
            enterExit = .onExit
            self.performSegue(withIdentifier: "addGeomndrSegue", sender: self)
        case 2:
            enterExit = .onEntry
            self.performSegue(withIdentifier: "addGeomndrSegue", sender: self)
        case 3:
            self.performSegue(withIdentifier: "mapSegue", sender: self)
        case 4:
            self.performSegue(withIdentifier: "aboutSegue", sender: self)
        default:
            break
            //dismiss
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.geoMndrTableView {
            
        } else {
            let t = tableView as! YALContextMenuTableView
            t.dismis(with: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (tableView == self.geoMndrTableView) ? geoMndrs.count : self.menuTitles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == self.geoMndrTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "GeoMndrCell", for:indexPath)
            cell.textLabel?.text = geoMndrs[indexPath.row].note
            return cell
        } else {
            let t = tableView as! YALContextMenuTableView
            let cell = t.dequeueReusableCell(withIdentifier: menuCellIdentifier, for:indexPath) as! ContextMenuCell
            
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            cell.backgroundColor = UIColor.clear
            cell.menuTitleLabel.text = self.menuTitles[indexPath.row]
            cell.menuImageView.image = self.menuIcons[indexPath.row]
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return tableView == self.geoMndrTableView ? true : false
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            geoMndrs.remove(at: indexPath.row)
            saveAllGeoMndrs()
            geoMndrTableView.reloadData()
        }
    }
    
    func initiateMenuOptions() {
        self.menuTitles = ["Close",
                           "Leaving GM",
                           "Entering GM",
                           "Map"]
        
        self.menuIcons = [UIImage(named: "close_icon"), UIImage(named: "leaving_icon"), UIImage(named: "entering_icon"), UIImage(named: "globe_icon")]
    }
}

// MARK: AddGeotificationViewControllerDelegate
extension GeoMndrViewController: AddGeoMndrViewControllerDelegate {
    
    func addGeoMndrViewController(controller: AddGeoMndrViewController, didAddCoordinate coordinate: CLLocationCoordinate2D, radius: Double, identifier: String, note: String, eventType: EventType) {
        controller.dismiss(animated: true, completion: nil)
        
        let clampedRadius = min(radius, locationManager.maximumRegionMonitoringDistance)
        let geoMndr = GeoMndr(coordinate: coordinate, radius: clampedRadius, identifier: identifier, note: note, eventType: eventType)
        geoMndrs.append(geoMndr)
        startMonitoring(geoMndr: geoMndr)
        saveAllGeoMndrs()
        geoMndrTableView.reloadData()
    }
}

extension GeoMndrViewController: MapViewControllerDelegate {
    func deleteGeoMndr(geoMndr: GeoMndr) {
        
        stopMonitoring(geoMndr: geoMndr)
        remove(geoMndr: geoMndr)
        saveAllGeoMndrs()
        geoMndrTableView.reloadData()
    }
}

// MARK: - Location Manager Delegate
extension GeoMndrViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print(status)
        //mapView.showsUserLocation = (status == .authorizedAlways)
    }
}

