//
//  MapViewController.swift
//  GeoMndr
//
//  Created by Brandon on 7/14/17.
//  Copyright © 2017 BrandonAubrey. All rights reserved.
//

import Foundation
import UIKit
import MapKit

protocol MapViewControllerDelegate {
    func deleteGeoMndr(geoMndr: GeoMndr)
}

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    var geoMndrs: [GeoMndr] = []
    var delegate: MapViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        for gm in geoMndrs {
            mapView.addAnnotation(gm)
            addRadiusOverlay(gm)
        }
    }
    
    @IBAction func onCloseButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Map overlay functions
    func addRadiusOverlay(_ gemondr: GeoMndr) {
        mapView?.add(MKCircle(center: gemondr.coordinate, radius: gemondr.radius))
    }
}

// MARK: - MapView Delegate
extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "myGeoMndr"
        if annotation is GeoMndr {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                let removeButton = UIButton(type: .custom)
                removeButton.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
                removeButton.setImage(UIImage(named: "close_icon")!, for: .normal)
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
            circleRenderer.strokeColor = .green
            circleRenderer.fillColor = UIColor.purple.withAlphaComponent(0.4)
            return circleRenderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // Delete geoMndr
        let geoMndr = view.annotation as! GeoMndr
        delegate?.deleteGeoMndr(geoMndr: geoMndr)
        mapView.removeAnnotation(geoMndr)
        removeRadiusOverlay(geoMndr: geoMndr)
    }
    
    func removeRadiusOverlay(geoMndr: GeoMndr) {
        // Find exactly one overlay which has the same coordinates & radius to remove
        guard let overlays = mapView?.overlays else { return }
        for overlay in overlays {
            guard let circleOverlay = overlay as? MKCircle else { continue }
            let coord = circleOverlay.coordinate
            if coord.latitude == geoMndr.coordinate.latitude && coord.longitude == geoMndr.coordinate.longitude && circleOverlay.radius == geoMndr.radius {
                mapView?.remove(circleOverlay)
                break
            }
        }
    }
}
