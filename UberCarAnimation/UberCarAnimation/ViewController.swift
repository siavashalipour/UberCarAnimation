//
//  ViewController.swift
//  UberCarAnimation
//
//  Created by siavash abbasalipour on 19/5/17.
//  Copyright © 2017 Siavash. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {
  
  @IBOutlet weak var mapView: MKMapView!
  var route: MKRoute!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    mapView.delegate = self
    setup()
    
  }
  func setup() {
    let sourceLocation = CLLocationCoordinate2D(latitude: 40.759011, longitude: -73.984472)
    let destinationLocation = CLLocationCoordinate2D(latitude: 40.748441, longitude: -73.985564)
    
    let sourcePlacemark = MKPlacemark(coordinate: sourceLocation, addressDictionary: nil)
    let destinationPlacemark = MKPlacemark(coordinate: destinationLocation, addressDictionary: nil)
    
    let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
    let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
    
    let sourceAnnotation = CarAnnotation(coordinate: sourceLocation)
    self.mapView.addAnnotation(sourceAnnotation)
    
    if let location = sourcePlacemark.location {
      sourceAnnotation.coordinate = location.coordinate
    }
    
    
    let destinationAnnotation = CarAnnotation(coordinate: destinationLocation)
    
    if let location = destinationPlacemark.location {
      destinationAnnotation.coordinate = location.coordinate
    }
    
    
    let directionRequest = MKDirectionsRequest()
    directionRequest.source = sourceMapItem
    directionRequest.destination = destinationMapItem
    directionRequest.transportType = .automobile
    
    // Calculate the direction
    let directions = MKDirections(request: directionRequest)
    
    directions.calculate {
      (response, error) -> Void in
      
      guard let response = response else {
        if let error = error {
          print("Error: \(error)")
        }
        
        return
      }
      
      self.route = response.routes[0]
      
      self.mapView.add((self.route.polyline), level: MKOverlayLevel.aboveRoads)
      
      let rect = self.route.polyline.boundingMapRect
      
      self.mapView.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
    }
  }
  // MARK:- Action
  @IBAction func startAniamte(_ sender: Any) {
    let btn = sender as! UIButton
    btn.isEnabled = false
    var i = -1
    let polyline = route.polyline
    if #available(iOS 10.0, *) {
      Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { (_) in
        var firstDouble: Double = 0
        if i == -1 {
          firstDouble = self.getBearingBetweenTwoPoints(point1: polyline.coordinates[0], point2: polyline.coordinates[1])
        } else {
          if i < polyline.coordinates.count - 1 {
            firstDouble = self.getBearingBetweenTwoPoints(point1: polyline.coordinates[i], point2: polyline.coordinates[i+1])
            
          }
        }
        i += 1
        
        if i < polyline.coordinates.count - 1 {
          UIView.animate(withDuration: 0.45, animations: {
            let innerA = self.getBearingBetweenTwoPoints(point1: polyline.coordinates[i], point2: polyline.coordinates[i+1])
            if innerA > firstDouble + 10 {
              if ((innerA) > self.radiansToDegrees(radians: Double.pi/3)) {
                self.animateWithCoordinate(polyline.coordinates[i], bearing: innerA + Double.pi/1.5)
              } else {
                self.animateWithCoordinate(polyline.coordinates[i], bearing: innerA - 2*Double.pi/1.5)
              }
            } else {
              self.animateWithCoordinate(polyline.coordinates[i], bearing: 0)
            }
          }, completion: nil)
        } else if i < polyline.coordinates.count {
          UIView.animate(withDuration: 0.45, animations: {
            let innerA =  self.getBearingBetweenTwoPoints(point1: polyline.coordinates[i-1], point2: polyline.coordinates[i])
            self.animateWithCoordinate(polyline.coordinates[i], bearing: innerA + Double.pi/3)
          }, completion: nil)
        }
      })
    } else {
      // Fallback on earlier versions
    }
  }
  // MARK:- Helpers
  func radiansToDegrees(radians: Double) -> Double {
    return radians * 180.0 / Double.pi
  }
  
  func getBearingBetweenTwoPoints(point1 : CLLocationCoordinate2D, point2 : CLLocationCoordinate2D) -> Double {
    // Returns a float with the angle between the two points
    let x = point1.longitude - point2.longitude
    let y = point1.latitude - point2.latitude
    
    return fmod(radiansToDegrees(radians: atan2(y, x)), 360.0) + 90.0
  }
  func animateWithCoordinate(_ coor: CLLocationCoordinate2D, bearing: Double? = nil ) {
    
    let ann = self.mapView.annotations.first! as! CarAnnotation
    var loc = ann.coordinate
    loc.latitude = coor.latitude
    loc.longitude = coor.longitude
    if let bearing = bearing {
      let v = self.mapView.view(for: ann)!
      v.transform = v.transform.rotated(by: ( -CGFloat(bearing)))
    }
    
    ann.coordinate = loc
    
  }
}

extension ViewController: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    let renderer = MKPolylineRenderer(overlay: overlay)
    renderer.strokeColor = UIColor.red
    renderer.lineWidth = 4.0
    
    return renderer
  }
  //MARK: MKMapViewDelegate
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    
    if annotation is MKUserLocation
    {
      return nil
    }
    var annotationView = self.mapView.dequeueReusableAnnotationView(withIdentifier: "Pin")
    if annotationView == nil{
      annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "Pin")
      annotationView?.canShowCallout = false
    } else {
      annotationView?.annotation = annotation
    }
    annotationView?.image = UIImage(named: "car")
    annotationView?.transform = (annotationView?.transform.rotated(by: -CGFloat.pi/3))!
    return annotationView
  }
}

public extension MKPolyline {
  public var coordinates: [CLLocationCoordinate2D] {
    var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid,
                                          count: self.pointCount)
    
    self.getCoordinates(&coords, range: NSRange(location: 0, length: self.pointCount))
    
    return coords
  }
}

class CarAnnotation: NSObject, MKAnnotation {
  
  dynamic var coordinate: CLLocationCoordinate2D
  var phone: String!
  var name: String!
  var address: String!
  var image: UIImage!
  var imageView: UIImageView!
  
  init(coordinate: CLLocationCoordinate2D) {
    self.coordinate = coordinate
  }
}
