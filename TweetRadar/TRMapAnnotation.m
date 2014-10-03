//
//  TRMapAnnotation.h
//  TweetRadar
//
//  Created by Steve Schauer on 9/13/14.
//  Copyright (c) 2014 Steve Schauer. All rights reserved.
//

#import "TRMapAnnotation.h"

@implementation TRMapAnnotation

@synthesize coordinate = _coordinate;
@synthesize title = _title;
@synthesize index = _index;

- (id) initWithCoordinate:(CLLocationCoordinate2D)coord
{
    _coordinate = coord;
    return self;
}


@end
