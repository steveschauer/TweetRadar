//
//  TRDetailViewController.m
//  TweetRadar
//
//  Created by Steve Schauer on 9/13/14.
//  Copyright (c) 2014 Steve Schauer. All rights reserved.
//

#import "TRDetailViewController.h"
#import "TRMapAnnotation.h"
#import "TRStorage.h"
#import <CoreLocation/CoreLocation.h>
#import <Parse/Parse.h>
#import <Accounts/ACAccountStore.h>
#import <Accounts/ACAccountType.h>

typedef enum
{
    TRRetweet=1,
    TRFavorite
} TRTwitterAction;


@interface TRDetailViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *screenName;
@property (weak, nonatomic) IBOutlet UITextView *tweetText;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) PFUser *user;

- (IBAction)retweetOrFavorite:(id)sender;

@end

@implementation TRDetailViewController

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
    // Do any additional setup after loading the view.
    _name.text = _tweet.name;
    _screenName.text = [NSString stringWithFormat:@"@%@",_tweet.screenName];
    _tweetText.text = _tweet.tweet;
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([_tweet.latitude doubleValue],[_tweet.longitude doubleValue]);
    TRMapAnnotation * annotation = [[TRMapAnnotation alloc] initWithCoordinate:coordinate];
    annotation.title = _tweet.name;
    [_mapView addAnnotation:annotation];
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(coordinate, (.5*METERS_PER_MILE), (.5*METERS_PER_MILE));
    MKCoordinateRegion adjustedRegion = [_mapView regionThatFits:viewRegion];
    [_mapView setRegion:adjustedRegion animated:YES];

    NSURL *url = [NSURL URLWithString:_tweet.imageURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setTimeoutInterval:10];
    [[PFTwitterUtils twitter] signRequest:request];
    [[TRStorage store] setRequest:request];
    [[TRStorage store] setRetrievingTweets:NO];
    
    [[TRStorage store] setCompletionBlock:^(NSData *imageData, NSError *err) {
        if (!err) {
            _imageView.image = [UIImage imageWithData:imageData];
        }
    }];
    [[TRStorage store] start];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)retweetOrFavorite:(id)sender {
    
    [PFTwitterUtils logInWithBlock:^(PFUser *user, NSError *error) {
        if (!user) {
            NSLog(@"Uh oh. The user cancelled the Twitter login.");
            return;
            
        } else {
            [user saveInBackground];
        }
        
        
    }];
    NSURL *url;
    NSString *message;
    if ([sender tag] == TRRetweet) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1.1/statuses/retweet/%@.json", _tweet.tweetID]];
        message = @"Couldn't retweet this tweet";
    } else {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1.1/favorites/create.json?id=%@", _tweet.tweetID]];
        message = @"Couldn't favorite this tweet";
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [[PFTwitterUtils twitter] signRequest:request];
    [[TRStorage store] setRequest:request];
    [request setTimeoutInterval:10];
    [[TRStorage store] setRetrievingTweets:NO];
    [request setHTTPBody:[_tweet.tweet dataUsingEncoding:NSUTF8StringEncoding]];
    
    [[TRStorage store] setCompletionBlock:^(NSData *data, NSError *err) {
        if (err) {
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Twitter Error" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [av show];
        }
    }];
    [[TRStorage store] start];
}

- (IBAction)doneButtonTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
