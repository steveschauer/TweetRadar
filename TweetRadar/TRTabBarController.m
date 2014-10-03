//
//  TRTabBarController.m
//  TweetRadar
//
//  Created by Steve Schauer on 9/12/14.
//  Copyright (c) 2014 Steve Schauer. All rights reserved.
//

#import "TRTabBarController.h"
#import "TRListViewController.h"
#import "TRMapViewController.h"
#import "TRStorage.h"
#import "TwitterState.h"
#import <Parse/Parse.h>

@interface TRTabBarController ()

@property (nonatomic, strong) NSError *error;
@property (nonatomic,strong) CLLocationManager *locationManager;
@end

@implementation TRTabBarController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[TRStorage store] deleteTwitterState];
    if ([CLLocationManager locationServicesEnabled]) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
            [self.locationManager requestAlwaysAuthorization];
        [self.locationManager startMonitoringSignificantLocationChanges];
    } else {
        NSLog(@"Location services are not enabled");
    }
    TRListViewController *listVC;
    TRMapViewController *mapVC;
    for (UIViewController *vc in self.viewControllers) {
        if ([vc isKindOfClass:[TRListViewController class]]) {
            listVC = (TRListViewController *)vc;
            listVC.tabBarController = self;
        } else {
            mapVC = (TRMapViewController *)vc;
            mapVC.tabBarController = self;
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newTweets:)
                                                 name:@"newTweets"
                                               object:nil];
    
    // check for new tweets every two minutes
    [NSTimer scheduledTimerWithTimeInterval:120.0 target:self selector:@selector(refreshTweets) userInfo:NULL repeats:YES];
    _tweets = [[NSMutableArray alloc] initWithCapacity:100];
}

- (void)newTweets:(NSNotification *)notification
{
    NSArray *newTweets = (NSArray *)[notification object];
    [_tweets addObjectsFromArray:newTweets];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    NSLog(@"didUpdateLocations");
    CLLocation *location = [locations lastObject];
    NSNumber *latitude = [NSNumber numberWithDouble:location.coordinate.latitude];
    NSNumber *longitude = [NSNumber numberWithDouble:location.coordinate.longitude];
    
    CLLocation* oldLocation;
    CLLocationDistance distance;
    TwitterState *state = [[TRStorage store] currentState];
    if (!state) {
        distance = (1.1*METERS_PER_MILE);
    } else {
        oldLocation = [[CLLocation alloc]initWithLatitude:[state.latitude doubleValue] longitude:[state.longitude doubleValue]];
        distance = [location distanceFromLocation:oldLocation];
    }
    
    [[TRStorage store] saveLocation:latitude longitude:longitude];

    if (distance > (1*METERS_PER_MILE)) {
        [[TRStorage store] deleteAllTweets];
        [self loadTweets];
    }
}

- (void)loadTweets
{
    NSString *urlString;
    TwitterState *state = [[TRStorage store] twitterResultsParamaters];
    if ([[state nextResultsParamater] length]) {
        urlString = [NSString stringWithFormat:@"https://api.twitter.com/1.1/search/tweets.json%@",[state nextResultsParamater]];
    }
    else
        urlString = [NSString stringWithFormat:@"https://api.twitter.com/1.1/search/tweets.json?geocode=%@,%@,1mi&result_type=recent&count=100",[state.latitude stringValue],[state.longitude stringValue]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setTimeoutInterval:10];
    [[PFTwitterUtils twitter] signRequest:request];
    [[TRStorage store] setRequest:request];
    [[TRStorage store] setRetrievingTweets:YES];
    
    [[TRStorage store] setCompletionBlock:^(NSNumber *tweetCount, NSError *err) {
        if (err && (err.code != -1001)) {
            [self setError:err];
            return;
        } else {
            if ([tweetCount integerValue] < 100) {
                [self loadTweets];
            } else {
                _tweets = [[NSMutableArray alloc] initWithArray:[[TRStorage store] allTweets]];
            }
        }
    }];
    [[TRStorage store] start];
}

- (void)refreshTweets
{
    TwitterState *state = [[TRStorage store] twitterResultsParamaters];
    if (![[state refreshResultsParamater] length]) {
        return;
    }
    if ([_tweets count] == 100) {
        [[TRStorage store] deleteTenTweets];
        _tweets = [[NSMutableArray alloc] initWithArray:[[TRStorage store] allTweets]];
    }
    NSString *urlString = [NSString stringWithFormat:@"https://api.twitter.com/1.1/search/tweets.json%@",[state refreshResultsParamater]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setTimeoutInterval:10];
    [[PFTwitterUtils twitter] signRequest:request];
    [[TRStorage store] setRequest:request];
    [[TRStorage store] setRetrievingTweets:YES];

    [[TRStorage store] setCompletionBlock:^(NSNumber *tweetCount, NSError *err) {
        if (err && (err.code != -1001)) {
            [self setError:err];
            return;
        } else {
            if ([tweetCount integerValue] < 100) {
                [self refreshTweets];
            } else {
                _tweets = [[NSMutableArray alloc] initWithArray:[[TRStorage store] allTweets]];                
            }
        }
    }];
    [[TRStorage store] start];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
