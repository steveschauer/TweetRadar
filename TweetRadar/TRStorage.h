//
//  TRStorage.h
//  TweetRadar
//
//  Created by Steve Schauer on 9/12/14.
//  Copyright (c) 2014 Steve Schauer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Tweet.h"
#import "TwitterState.h"

#define METERS_PER_MILE 1609.344

typedef enum
{
    TRTwitterURLParamaterNext,
    TRTwitterURLParamaterRefresh
} TRTwitterURLParamater;

@interface TRStorage : NSObject <NSURLConnectionDataDelegate>

@property (nonatomic, copy) NSMutableURLRequest *request;
@property (nonatomic, copy) void (^completionBlock)(id data, NSError *err);
@property (assign) NSUInteger tweetCount;
@property (assign) BOOL retrievingTweets;

+ (TRStorage *) store;
- (void)start;
- (TwitterState *)twitterResultsParamaters;
- (NSArray *)allTweets;
- (void)deleteAllTweets;
- (TwitterState *)currentState;
- (void) saveLocation:(NSNumber *)latitude longitude:(NSNumber *)longitude;
- (void)deleteTwitterState;
- (void)deleteTenTweets;

@end
