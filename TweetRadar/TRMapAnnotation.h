//
//  TRMapAnnotation.h
//  TweetRadar
//
//  Created by Steve Schauer on 9/13/14.
//  Copyright (c) 2014 Steve Schauer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface TRMapAnnotation : NSObject<MKAnnotation> {
}

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
@property (assign) NSInteger index;

- (id) initWithCoordinate:(CLLocationCoordinate2D)coord;


@end
