//
//  CategoryViewControler.h
//  TradeMeTest
//
//  Created by Serhii Simkovskyi on Nov/29/17.
//  Copyright © 2017 Serhii Simkovskyi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ListingsViewController; // forward declaration
@class TMCategory; // forward declaration


@interface CategoryViewController : UITableViewController

// categoryHierarchy - array of TMCategory (with no subcategories);
// Contains a path of opened categories e.g. @"0000" -> @"0001" -> @"0276" , ..
// where the last object is currently selected category id;
// first object, which is root category id, should always exist.
@property (strong, nonatomic) NSMutableArray *categoryHierarchy; // of TMCategory

// loaded data for current category
@property (strong, nonatomic) TMCategory *categoryData;
@property (strong, nonatomic) NSString *errorMessage; // if load failed this prop will handle error message to be displayed to user

// We are going to retain listings view controller (so it is not destroyed when split view is collapsed view and category view is presented)
@property (strong, nonatomic) ListingsViewController *listingsViewController;

@end

