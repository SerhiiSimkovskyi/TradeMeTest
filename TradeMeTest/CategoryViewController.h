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

// categoryHierarchy - array of TMCategory (with no subcategories);
// Contains a path of opened categories e.g. @"0000", @"0001", @"0276" , ..
// where the last object is currently selected category id;
// first object, which is root category id, should always exist.
@property (strong, nonatomic) NSMutableArray *categoryHierarchy; // of TMCategory

// loaded data of current category
@property (strong, nonatomic) TMCategory *categoryData;

// **
@property (strong, nonatomic) ListingsViewController *listingsViewController;

@end

