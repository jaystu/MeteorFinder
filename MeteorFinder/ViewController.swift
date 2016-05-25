//
//  ViewController.swift
//  MeteorFinder
//
//  Created by John Stuart on 5/25/16.
//  Copyright © 2016 John Stuart. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import SwiftyJSON
import Alamofire

var json : JSON = [:]
let numberOfMeteorsToFind = 5

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    // MARK : - Properties
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var findMeteorButton: UIButton!
    
    let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Access API Endpoint with limit set to max (50000)
        Alamofire.request(.GET, "https://data.nasa.gov/resource/y77d-th95.json?$limit=50000").validate().responseJSON { response in
            switch response.result {
            case .Success:
                if let value = response.result.value {
                    json = JSON(value)
                    //print("request successful")
                    self.findMeteorButton.hidden = false
                }
            case .Failure(let error):
                print(error)
            }
        }
        
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        
        // Setting our location
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.startUpdatingLocation()
        self.mapView.showsUserLocation = true
    }
    
    // MARK: - Location Delegate Methods
    // Deals with location intialization and Region
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
        self.mapView.setRegion(region, animated: true)
        self.locationManager.stopUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Error: " + error.localizedDescription)
    }
    
    

    // MARK: - Actions
    @IBAction func findMeteor(sender: AnyObject) {
        let currentLatitude = locationManager.location!.coordinate.latitude
        let currentLongitude = locationManager.location!.coordinate.longitude
        
        let closestMeteors = getClosestMeteors(currentLatitude, currentLongitude: currentLongitude)
        for index in 0..<closestMeteors.count {
            let location = CLLocationCoordinate2D(
                latitude: Double(closestMeteors[index]["reclat"].stringValue)!,
                longitude: Double(closestMeteors[index]["reclong"].stringValue)!
            )
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = location
            annotation.title = "Meteor Name: \(closestMeteors[index]["name"].stringValue)"
            let stringIndex = closestMeteors[index]["year"].stringValue.startIndex.advancedBy(4)
            let yearFallen = closestMeteors[index]["year"].stringValue.substringToIndex(stringIndex)
            annotation.subtitle = "Weight (g): \(closestMeteors[index]["mass"].stringValue)     Year Fallen: \(yearFallen)"
            mapView.addAnnotation(annotation)
        }
        mapView.showAnnotations(mapView.annotations, animated: true)
        
        findMeteorButton.hidden = true
    }
    
    // MARK: - Algorithms
    func getClosestMeteors(currentLatitude: Double, currentLongitude: Double) -> [JSON] {
        var closestMeteors = [JSON]()
        var closestMeteorDistances = [Double]()
        
        for _ in 0..<numberOfMeteorsToFind {
            closestMeteorDistances += [19960352.0]
        }
        var distanceToBeat = closestMeteorDistances.last
        
        for jsonIndex in 0..<json.count {
            if let meteorLatitude = Double(json[jsonIndex]["reclat"].stringValue) {
                if let meteorLongitude = Double(json[jsonIndex]["reclong"].stringValue) {
                    let distanceFromNextMeteor = calcDistance(currentLatitude, currentLongitude: currentLongitude, meteorLatitude: meteorLatitude, meteorLongitude: meteorLongitude)
                    
                    if distanceFromNextMeteor < distanceToBeat {
                        for index in 0..<closestMeteorDistances.count {
                            if distanceFromNextMeteor < closestMeteorDistances[index] {
                                closestMeteorDistances.insert(distanceFromNextMeteor, atIndex: index)
                                closestMeteors.insert(json[jsonIndex], atIndex: index)
                                
                                //makes sure number of meteors to find stays at number specified
                                if closestMeteorDistances.count == numberOfMeteorsToFind + 1 {
                                    closestMeteorDistances.removeLast()
                                }
                                if closestMeteors.count == numberOfMeteorsToFind + 1 {
                                    closestMeteors.removeLast()
                                }
                                break
                            }
                        }
                        distanceToBeat = closestMeteorDistances.last
                    }
                }
            }
        }
        return closestMeteors
    }
    
    //calculates distance between 2 coordinates
    func calcDistance(currentLatitude: Double, currentLongitude: Double, meteorLatitude:Double, meteorLongitude: Double)->Double {
        
        let currentLocation = CLLocation(latitude: currentLatitude, longitude: currentLongitude)
        let meteorLocation = CLLocation(latitude: meteorLatitude, longitude: meteorLongitude)
        let distance = currentLocation.distanceFromLocation(meteorLocation)
        
        return distance
    }
    

}

