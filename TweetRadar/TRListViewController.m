//
//  TRListViewController.m
//  TweetRadar
//
//  Created by Steve Schauer on 9/12/14.
//  Copyright (c) 2014 Steve Schauer. All rights reserved.
//

#import "TRListViewController.h"
#import "TRStorage.h"
#import "Tweet.h"
#import "TRDetailViewController.h"
#import <Parse/Parse.h>

@interface TRListViewController ()
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) Tweet *tweet;
@end

@implementation TRListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Do any additional setup after loading the view, typically from a nib.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showTweets:)
                                                 name:@"newTweets"
                                               object:nil];
}

- (void)showTweets:(NSNotification *)notification
{
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[_tabBarController tweets] count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _tweet = [_tabBarController tweets][indexPath.row];
    [self performSegueWithIdentifier:@"showDetail" sender:self];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tweetCell" forIndexPath:indexPath];
    Tweet *tweet = [_tabBarController tweets][indexPath.row];
    cell.textLabel.text = tweet.tweet;
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    TRDetailViewController *dvc = [segue destinationViewController];
    dvc.tweet = _tweet;;
}

@end
