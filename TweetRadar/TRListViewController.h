//
//  TRListViewController.h
//  TweetRadar
//
//  Created by Steve Schauer on 9/12/14.
//  Copyright (c) 2014 Steve Schauer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TRTabBarController.h"

@interface TRListViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic,strong) TRTabBarController *tabBarController;

@end
