//
//  GeotificationViewController.swift
//  GeoMndr
//
//  Created by Brandon on 6/9/17.
//  Copyright © 2017 BrandonAubrey. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import ContextMenu_iOS

struct PreferencesKeys {
    static let savedItems = "savedItems"
}

class GeotificationsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, YALContextMenuTableViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var geotifications: [Geotification] = []
    
    var menuTitles: [String?] = []
    var menuIcons: [UIImage?] = []
    var contextMenuTableView: YALContextMenuTableView?
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initiateMenuOptions()
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        loadAllGeotifications()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addGeotification" {
            let navigationController = segue.destination as! UINavigationController
            let vc = navigationController.viewControllers.first as! AddGeotificationViewController
            vc.delegate = self
        }
    }
    
    // MARK: Loading and saving functions
    func loadAllGeotifications() {
        geotifications = []
        guard let savedItems = UserDefaults.standard.array(forKey: PreferencesKeys.savedItems) else { return }
        for savedItem in savedItems {
            guard let geotification = NSKeyedUnarchiver.unarchiveObject(with: savedItem as! Data) as? Geotification else { continue }
            add(geotification: geotification)
        }
    }
    
    func saveAllGeotifications() {
        var items: [Data] = []
        for geotification in geotifications {
            let item = NSKeyedArchiver.archivedData(withRootObject: geotification)
            items.append(item)
        }
        UserDefaults.standard.set(items, forKey: PreferencesKeys.savedItems)
    }
    
    // MARK: Functions that update the model/associated views with geotification changes
    func add(geotification: Geotification) {
        geotifications.append(geotification)
        mapView.addAnnotation(geotification)
        addRadiusOverlay(forGeotification: geotification)
        updateGeotificationsCount()
    }
    
    func remove(geotification: Geotification) {
        if let indexInArray = geotifications.index(of: geotification) {
            geotifications.remove(at: indexInArray)
        }
        mapView.removeAnnotation(geotification)
        removeRadiusOverlay(forGeotification: geotification)
        updateGeotificationsCount()
    }
    
    func updateGeotificationsCount() {
        title = "Geotifications (\(geotifications.count))"
        navigationItem.rightBarButtonItem?.isEnabled = (geotifications.count < 20)
    }
    
    // MARK: Map overlay functions
    func addRadiusOverlay(forGeotification geotification: Geotification) {
        mapView?.add(MKCircle(center: geotification.coordinate, radius: geotification.radius))
    }
    
    func removeRadiusOverlay(forGeotification geotification: Geotification) {
        // Find exactly one overlay which has the same coordinates & radius to remove
        guard let overlays = mapView?.overlays else { return }
        for overlay in overlays {
            guard let circleOverlay = overlay as? MKCircle else { continue }
            let coord = circleOverlay.coordinate
            if coord.latitude == geotification.coordinate.latitude && coord.longitude == geotification.coordinate.longitude && circleOverlay.radius == geotification.radius {
                mapView?.remove(circleOverlay)
                break
            }
        }
    }
    
    func region(withGeotification geotification: Geotification) -> CLCircularRegion {
        let region = CLCircularRegion(center: geotification.coordinate, radius: geotification.radius, identifier: geotification.identifier)
        region.notifyOnEntry = (geotification.eventType == .onEntry)
        region.notifyOnExit = !region.notifyOnExit
        return region
    }
    
    func startMonitoring(geotification: Geotification) {
        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            showAlert(withTitle: "Error", message: "Geofencing is not supported on this device")
            return
        }
        if CLLocationManager.authorizationStatus() != .authorizedAlways{
            showAlert(withTitle:"Warning", message: "Your geotification is saved but will only be activated once you grant Geotify permission to access the device location.")
        }
        
        let region = self.region(withGeotification: geotification)
        locationManager.startMonitoring(for: region)
    }
    
    func stopMonitoring(geotification: Geotification) {
        for region in locationManager.monitoredRegions {
            guard let circularRegion = region as? CLCircularRegion,
                circularRegion.identifier == geotification.identifier else { continue }
            locationManager.stopMonitoring(for: circularRegion)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Monitoring failed for region with identifier: \(region!.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager failed with the following error: \(error)")
    }
    
    
    
    // MARK: Other mapview functions
    @IBAction func zoomToCurrentLocation(sender: AnyObject) {
        mapView.zoomToUserLocation()
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
            self.performSegue(withIdentifier: "addSegue", sender: self)
        //add delegate here
        default:
            break
            //dismiss
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let t = tableView as! YALContextMenuTableView
        t.dismis(with: indexPath)
        
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.menuTitles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let t = tableView as! YALContextMenuTableView
        let cell = t.dequeueReusableCell(withIdentifier: menuCellIdentifier, for:indexPath) as! ContextMenuCell
        
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        cell.backgroundColor = UIColor.clear
        cell.menuTitleLabel.text = self.menuTitles[indexPath.row]
        cell.menuImageView.image = self.menuIcons[indexPath.row]
        
        
        return cell;
    }
    
    func initiateMenuOptions() {
        self.menuTitles = ["",
                           "Add new",
                           "Map",
                           "About",
                           "Add to favourites",
                           "Block user"]
        
        self.menuIcons = [UIImage(named: "Icnclose"), UIImage(named: "add_icon"), UIImage(named: "LikeIcn"), UIImage(named: "AddToFriendsIcn"), UIImage(named: "AddToFavouritesIcn"), UIImage(named: "BlockUserIcn")]
    }
}

// MARK: AddGeotificationViewControllerDelegate
extension GeotificationsViewController: AddGeotificationsViewControllerDelegate {
    
    func addGeotificationViewController(controller: AddGeotificationViewController, didAddCoordinate coordinate: CLLocationCoordinate2D, radius: Double, identifier: String, note: String, eventType: EventType) {
        controller.dismiss(animated: true, completion: nil)
        
        let clampedRadius = min(radius, locationManager.maximumRegionMonitoringDistance)
        let geotification = Geotification(coordinate: coordinate, radius: clampedRadius, identifier: identifier, note: note, eventType: eventType)
        add(geotification: geotification)
        startMonitoring(geotification: geotification)
        saveAllGeotifications()
    }
}

// MARK: - Location Manager Delegate
extension GeotificationsViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        mapView.showsUserLocation = (status == .authorizedAlways)
    }
    
}

// MARK: - MapView Delegate
extension GeotificationsViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "myGeotification"
        if annotation is Geotification {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                let removeButton = UIButton(type: .custom)
                removeButton.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
                //removeButton.setImage(UIImage(named: "DeleteGeotification")!, for: .normal)
                annotationView?.leftCalloutAccessoryView = removeButton
            } else {
                annotationView?.annotation = annotation
            }
            return annotationView
        }
        return nil
    }
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.lineWidth = 1.0
            circleRenderer.strokeColor = .purple
            circleRenderer.fillColor = UIColor.purple.withAlphaComponent(0.4)
            return circleRenderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // Delete geotification
        let geotification = view.annotation as! Geotification
        stopMonitoring(geotification: geotification)
        remove(geotification: geotification)
        saveAllGeotifications()
    }
}
