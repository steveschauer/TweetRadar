//
//  TRMapViewController.h
//  TweetRadar
//
//  Created by Steve Schauer on 9/12/14.
//  Copyright (c) 2014 Steve Schauer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TRTabBarController.h"
#import <MapKit/MapKit.h>

@interface TRMapViewController : UIViewController <MKMapViewDelegate>

@property (nonatomic,strong) TRTabBarController *tabBarController;

@end
