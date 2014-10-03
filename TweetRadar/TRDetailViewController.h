//
//  TRDetailViewController.h
//  TweetRadar
//
//  Created by Steve Schauer on 9/13/14.
//  Copyright (c) 2014 Steve Schauer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Tweet.h"

@interface TRDetailViewController : UIViewController <MKMapViewDelegate>
@property (nonatomic, weak) Tweet *tweet;
@end
