//
//  MasterViewController.h
//  TradeMeTest
//
//  Created by Serhii Simkovskyi on Nov/29/17.
//  Copyright © 2017 Serhii Simkovskyi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ListingsViewController;

@interface CategoryViewController : UITableViewController

@property (strong, nonatomic) ListingsViewController *detailViewController;


@end

