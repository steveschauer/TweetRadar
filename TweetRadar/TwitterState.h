//
//  TwitterState.h
//  TweetRadar
//
//  Created by Steve Schauer on 9/13/14.
//  Copyright (c) 2014 Steve Schauer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface TwitterState : NSManagedObject

@property (nonatomic, retain) NSString * nextResultsParamater;
@property (nonatomic, retain) NSString * refreshResultsParamater;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;

@end
