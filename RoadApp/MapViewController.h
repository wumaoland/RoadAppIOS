//
//  MapViewController.h
//  RoadApp
//
//  Created by devil2010 on 12/28/16.
//  Copyright © 2016 admin2. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMaps/GoogleMaps.h>
#import "SlideNavigationController.h"

@interface MapViewController : UIViewController <SlideNavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet GMSMapView *mapView;

@end
