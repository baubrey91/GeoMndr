//
//  AddGeotificationViewController.swift
//  GeoMndr
//
//  Created by Brandon on 6/9/17.
//  Copyright © 2017 BrandonAubrey. All rights reserved.
//

import UIKit
import MapKit
import AASegmentedControl

protocol AddGeoMndrViewControllerDelegate {
    func addGeoMndrViewController(controller: AddGeoMndrViewController, didAddCoordinate coordinate: CLLocationCoordinate2D,
                                        radius: Double, identifier: String, note: String, eventType: EventType)
}

class AddGeoMndrViewController: UITableViewController {
    
    @IBOutlet var addButton: UIBarButtonItem!
    @IBOutlet var zoomButton: UIBarButtonItem!
    @IBOutlet weak var noteTextField: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var radiusSegment: AASegmentedControl!
    
    var delegate: AddGeoMndrViewControllerDelegate?
    var locationManager = CLLocationManager()
    var geoMndrCoordinates: CLLocationCoordinate2D!
    var entryExit: EventType = .onExit
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItems = [addButton, zoomButton]
        
        //mapView.zoomToUserLocation()
        if let coordinate = mapView.userLocation.location?.coordinate {
            let region = MKCoordinateRegionMakeWithDistance(coordinate, 10000, 10000)
            mapView.setRegion(region, animated: true)
        }
        if entryExit == .onExit {
            zoomButton.tintColor = UIColor.clear
        }
        addButton.isEnabled = false
        
        radiusSegment.itemNames = ["1","10","100","500"]
        radiusSegment.font = .systemFont(ofSize: 14)
        radiusSegment.selectedIndex = 0
    }
    
    @IBAction func textFieldEditingChanged(sender: UITextField) {
        addButton.isEnabled = !noteTextField.text!.isEmpty
    }
    
    @IBAction func onCancel(sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func onAdd(sender: AnyObject) {
        let coordinate = (entryExit == .onExit) ? mapView.userLocation.coordinate : mapView.centerCoordinate
        let radius = 1000.00//Double(radiusSegment.itemNames[radiusSegment.selectedIndex]) ?? 0
        let identifier = NSUUID().uuidString
        let note = noteTextField.text
        let eventType: EventType = entryExit
        delegate?.addGeoMndrViewController(controller: self, didAddCoordinate: coordinate, radius: radius, identifier: identifier, note: note!, eventType: eventType)
    }
    
    @IBAction private func onZoomToCurrentLocation(sender: AnyObject) {
        mapView.zoomToUserLocation()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return entryExit == .onExit ? 0 : 300
        } else {
            return 60
        }
    }
}
