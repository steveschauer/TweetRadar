//
//  TRStorage.m
//  TweetRadar
//
//  Created by Steve Schauer on 9/12/14.
//  Copyright (c) 2014 Steve Schauer. All rights reserved.
//

#import "TRStorage.h"
#import <Parse/Parse.h>

@interface TRStorage ()

@property (nonatomic) long statusCode;
@property (nonatomic, strong) NSMutableData *container;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSURLConnection *connection;

@end

@implementation TRStorage

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

+ (TRStorage *) store
{
    static TRStorage *store = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[TRStorage alloc] init];
    });
    
    return store;
}

- (id) init
{
    self = [super init];
    NSFetchRequest *r = [NSFetchRequest fetchRequestWithEntityName:@"Tweet"];
    _tweetCount = [[self managedObjectContext] countForFetchRequest:r error:nil];
    if (_tweetCount) {
        // start fresh, location might have changed
        [self deleteAllTweets];
    }
    return self;
}

#pragma mark - Network stack
- (void)start
{
    [self setContainer:[[NSMutableData alloc] init]];
    [self setConnection:[[NSURLConnection alloc] initWithRequest:[self request]
                                                                delegate:self
                                                        startImmediately:YES]];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    _container = nil;
    NSLog(@"\n oops we failed: error %ld",(long)error.code);
    // not unusual to get a timeout error (-1001)
    if ([self completionBlock]) {
        if (_retrievingTweets)
            [self completionBlock]([NSNumber numberWithInteger:_tweetCount], error);
        else
            [self completionBlock](nil, error);
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *r = (NSHTTPURLResponse *)response;
    [self setStatusCode:[r statusCode]];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_container appendData:data];
    NSLog(@"%lu bytes received",(unsigned long)[data length]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSError *error = nil;
    NSDictionary *tweets = nil;
    
    if (_retrievingTweets) {
        if (_container) {
            tweets = [NSJSONSerialization JSONObjectWithData:_container options:0 error:&error];
            _container = nil;
        }
        
        NSArray *results = tweets[@"statuses"];
        if ([results count]) {
            [self saveTweets:tweets];
        } else {
            NSLog(@"hmmm did we run out of tweets?");
            error = [[NSError alloc] initWithDomain:@"noMoreTweets" code:1 userInfo:nil];
            if ([self completionBlock]) {
                [self completionBlock](0, error);
            }
            return;
        }
    }
    
    if ([self completionBlock]) {
        if (_retrievingTweets) {
            [self completionBlock]([NSNumber numberWithInteger:_tweetCount], nil);
        } else {
            if (_statusCode == 200)
                [self completionBlock](_container, nil);
            else {
                error = [[NSError alloc] initWithDomain:@"tweetError" code:_statusCode userInfo:nil];
                [self completionBlock](nil, error);
            }
        }
    }
    
}

- (void)saveTweets:(NSDictionary *)tweets
{
    NSArray *results = tweets[@"statuses"];
    NSMutableArray *newTweets = [[NSMutableArray alloc] init];
    [self saveTwitterResultsParamaters:tweets[@"search_metadata"][@"next_results"] refreshResult:tweets[@"search_metadata"][@"refresh_url"]];
    int count = 0;
    for (NSDictionary *tweet in results) {
        // don't save this tweet unless it has coordinates for the map
        if ((NSNull *)[tweet objectForKey:@"coordinates"] != [NSNull null]) {
            count++;
            _tweetCount++;
            Tweet *thisTweet = [NSEntityDescription insertNewObjectForEntityForName:@"Tweet" inManagedObjectContext:[self managedObjectContext]];
            thisTweet.name = tweet[@"user"][@"name"];
            thisTweet.screenName = tweet[@"user"][@"screen_name"];
            thisTweet.tweet = tweet[@"text"];
            thisTweet.imageURL = tweet[@"user"][@"profile_image_url"];
            thisTweet.latitude = tweet[@"coordinates"][@"coordinates"][1];
            thisTweet.longitude = tweet[@"coordinates"][@"coordinates"][0];
            thisTweet.tweetID = tweet[@"id"];
            [newTweets addObject:thisTweet];
            if (_tweetCount == 100)
                break;
        }
    }
    if (count) {
        NSLog(@"found %d, _tweetCount is now %lu",count,(unsigned long)_tweetCount);
        [self saveContext];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"newTweets" object:newTweets];
    }
}

- (TwitterState *)twitterResultsParamaters
{
    NSFetchRequest *r = [NSFetchRequest fetchRequestWithEntityName:@"TwitterState"];
    NSArray *array = [_managedObjectContext executeFetchRequest:r error:nil];
    if ([array count])
        return array[0];
    return nil;
}

- (void)saveTwitterResultsParamaters:(NSString *)nextResult refreshResult:(NSString *)refreshResult
{
    TwitterState *state;
    NSFetchRequest *r = [NSFetchRequest fetchRequestWithEntityName:@"TwitterState"];
    NSArray *array = [_managedObjectContext executeFetchRequest:r error:nil];
    if ([array count]) {
        state = array[0];
    } else {
        state = [NSEntityDescription insertNewObjectForEntityForName:@"TwitterState" inManagedObjectContext:[self managedObjectContext]];
    }
    state.nextResultsParamater = nextResult;
    state.refreshResultsParamater = refreshResult;
    [self saveContext];
}

- (TwitterState *)currentState
{
    NSFetchRequest *r = [NSFetchRequest fetchRequestWithEntityName:@"TwitterState"];
    NSArray *array = [_managedObjectContext executeFetchRequest:r error:nil];
    if ([array count])
        return array[0];
        
    return nil;
}

- (void) saveLocation:(NSNumber *)latitude longitude:(NSNumber *)longitude
{
    TwitterState *state;
    NSFetchRequest *r = [NSFetchRequest fetchRequestWithEntityName:@"TwitterState"];
    NSArray *array = [_managedObjectContext executeFetchRequest:r error:nil];
    if ([array count]) {
        state = array[0];
    } else {
        state = [NSEntityDescription insertNewObjectForEntityForName:@"TwitterState" inManagedObjectContext:[self managedObjectContext]];
    }
    state.latitude = latitude;
    state.longitude = longitude;
    [self saveContext];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"newRegion" object:state];
    
}

- (void)deleteTwitterState
{
    NSFetchRequest *r = [NSFetchRequest fetchRequestWithEntityName:@"TwitterState"];
    NSArray *array = [_managedObjectContext executeFetchRequest:r error:nil];
    if ([array count]) {
        [_managedObjectContext deleteObject:array[0]];
    }
}

- (NSArray *)allTweets
{
    NSFetchRequest *r = [NSFetchRequest fetchRequestWithEntityName:@"Tweet"];
    NSArray *array = [_managedObjectContext executeFetchRequest:r error:nil];
    _tweetCount = [array count];
    return array;
}

- (void)deleteAllTweets
{
    NSArray *tweets = [self allTweets];
    for (Tweet *tweet in tweets) {
        [_managedObjectContext deleteObject:tweet];
    }
    [self saveContext];
    _tweetCount = 0;
}

- (void)deleteTenTweets
{
    NSFetchRequest *r = [NSFetchRequest fetchRequestWithEntityName:@"Tweet"];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
                                        initWithKey:@"tweetID" ascending:YES];
    [r setSortDescriptors:@[sortDescriptor]];
    
    NSError *error;
    NSArray *array = [_managedObjectContext executeFetchRequest:r error:&error];
    int limit = (int)MIN(10,[array count]);
    for (int i = 0; i < limit; i++) {
        [_managedObjectContext deleteObject:array[i]];
    }
}


#pragma mark - Core Data stack

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}


// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"TweetRadar" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"TweetRadar.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
