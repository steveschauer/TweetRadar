//
//  TRAppDelegate.m
//  TweetRadar
//
//  Created by Steve Schauer on 9/12/14.
//  Copyright (c) 2014 Steve Schauer. All rights reserved.
//

#import "TRAppDelegate.h"
#import "TRStorage.h"
#import <Parse/Parse.h>

@implementation TRAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Add your Parse ID and key here:
    [Parse setApplicationId:@"J7Egxihh0whFZafQUAMDJHXJ4bsK7ExheAzcjReP" clientKey:@"cQjfw1inSA9J5Fcblewexg1o0X9ffKQoXq5Mi3co"];
    
    // Add your Twitter keys and secrets here:
    [PFTwitterUtils initializeWithConsumerKey:@"w9UkgJefenCl0VjtR9yEa0qB1" consumerSecret:@"nW0MHfMLqFtfRr2RBoCMfjV0jbQ5HFdcDbDaVj1m6Q3zpfC6bn"];
    [[PFTwitterUtils twitter] setAuthToken:@"46272995-RC3fHUatSsmi4sclRaxRCw7iVn0is1oHK6JIXe3QL"];
    [[PFTwitterUtils twitter] setAuthTokenSecret:@"O0QU4cZadhPzt3JZLjTh0fUv0ypDfcQ292iRbVdaAc7xV"];
    
    // kick off the tweet retrieval
    [TRStorage store];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
