//
//  TRTabBarController.h
//  TweetRadar
//
//  Created by Steve Schauer on 9/12/14.
//  Copyright (c) 2014 Steve Schauer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>


@interface TRTabBarController : UITabBarController <CLLocationManagerDelegate>

@property (nonatomic, strong) NSMutableArray *tweets;

@end
