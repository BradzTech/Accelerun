//
//  RunPoint.swift
//  XCSync
//
//  Created by Bradley Klemick on 6/10/17.
//  Copyright © 2017 BradzTech. All rights reserved.
//

import CoreData
import CoreLocation

class RunPoint: NSManagedObject {
    @NSManaged var date: Date
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var altitude: Double
    @NSManaged var stepsPerMinute: Float
    @NSManaged var heartrate: Float
    @NSManaged var accuracyHorizontal: Float
    @NSManaged var accuracyVertical: Float
    
    init(location: CLLocation, stepsPerMinute: Float = 0, heartrate: Float = 0) {
        super.init(entity: NSEntityDescription.entity(forEntityName: "RunPoint", in: AppDelegate.moc)!, insertInto: AppDelegate.moc)
        date = location.timestamp
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        altitude = location.altitude
        accuracyHorizontal = Float(location.horizontalAccuracy)
        accuracyVertical = Float(location.verticalAccuracy)
        self.stepsPerMinute = stepsPerMinute
        self.heartrate = heartrate
    }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    var cllocation: CLLocation {
        return CLLocation(coordinate: CLLocationCoordinate2DMake(latitude, longitude), altitude: altitude, horizontalAccuracy: Double(accuracyHorizontal), verticalAccuracy: Double(accuracyVertical), timestamp: date)
    }
}
