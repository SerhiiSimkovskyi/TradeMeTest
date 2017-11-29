//
//  MasterViewController.h
//  TradeMeTest
//
//  Created by Serhii Simkovskyi on Nov/29/17.
//  Copyright © 2017 Serhii Simkovskyi. All rights reserved.
//

#import <UIKit/UIKit.h>

// forward declaration
@class ListingsViewController;
@class TMCategory;

// ============================================================
@interface CategoryViewController : UITableViewController

@property (strong, nonatomic) TMCategory *categoryData;
@property (assign, nonatomic) NSInteger categoryNum;
@property (strong, nonatomic) ListingsViewController *detailViewController;

@end

