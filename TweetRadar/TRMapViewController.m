//
//  TRMapViewController.m
//  TweetRadar
//
//  Created by Steve Schauer on 9/12/14.
//  Copyright (c) 2014 Steve Schauer. All rights reserved.
//

#import "TRMapViewController.h"
#import "TRDetailViewController.h"
#import "TRMapAnnotation.h"
#import "TRStorage.h"
#import "Tweet.h"
#import "TwitterState.h"

@interface TRMapViewController ()
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) Tweet *tweet;
@end

@implementation TRMapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showTweets:)
                                                 name:@"newTweets"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showRegion:)
                                                 name:@"newRegion"
                                               object:nil];
    _mapView.delegate = self;
}

- (void)showRegion:(NSNotification *)notification
{
    TwitterState *state = (TwitterState *)[notification object];
    CLLocationCoordinate2D coordinate;
    coordinate.latitude = [state.latitude doubleValue];
    coordinate.longitude = [state.longitude doubleValue];;
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(coordinate, (2*METERS_PER_MILE), (2*METERS_PER_MILE));
    MKCoordinateRegion adjustedRegion = [_mapView regionThatFits:viewRegion];
    [_mapView setRegion:adjustedRegion animated:YES];
    [self showTweets:notification];
}

- (void)showTweets:(NSNotification *)notification
{
    [self dropPins];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    TRMapAnnotation *myAnnotation = (TRMapAnnotation *)annotation;
    MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"loc"];
    if (annotationView == nil) {
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:myAnnotation reuseIdentifier:@"loc"];
        annotationView.enabled = YES;
        annotationView.canShowCallout = YES;
        annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeInfoLight];
    }
    
    return annotationView;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    TRMapAnnotation *annotation = (TRMapAnnotation *)view.annotation;
    _tweet = [_tabBarController tweets][annotation.index];
    [self performSegueWithIdentifier:@"showDetail" sender:self];
}


- (void)dropPins
{
    // TODO: optimize this to only add/subtract changed tweets
    for (id<MKAnnotation> annotation in _mapView.annotations)
        [_mapView removeAnnotation:annotation];

    for (int i = 0; i < [[_tabBarController tweets] count]; i++) {
        Tweet *tweet = [_tabBarController tweets][i];
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([tweet.latitude doubleValue],[tweet.longitude doubleValue]);
        TRMapAnnotation * annotation = [[TRMapAnnotation alloc] initWithCoordinate:coordinate];
        annotation.title = [NSString stringWithFormat:@"@%@",tweet.screenName];
        annotation.index = i;
        [_mapView addAnnotation:annotation];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    TRDetailViewController *dvc = [segue destinationViewController];
    dvc.tweet = _tweet;;
}

@end
