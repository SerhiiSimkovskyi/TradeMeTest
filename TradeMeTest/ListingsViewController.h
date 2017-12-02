//
//  ListingsViewController
//  TradeMeTest
//
//  Created by Serhii Simkovskyi on Nov/29/17.
//  Copyright © 2017 Serhii Simkovskyi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TMListings.h"

@interface ListingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>

// UI Outlets
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnSort;

// Listings query properties. Changing them will auto reload listings if applicable
@property (strong, nonatomic, setter = setCategoryId:) NSString *categoryId;
@property (strong, nonatomic, setter = setSearchString:) NSString *searchString;
@property (assign, nonatomic, setter = setListingsSort:) ListingsSort listingsSort;
@property (assign, nonatomic, setter = setListingsCondition:) ListingsCondition listingsCondition;
@property (assign, nonatomic, setter = setCurrentPage:) NSInteger currentPage;

// Auxilary properties
@property (strong, nonatomic, setter = setCategoryName:) NSString *categoryName; // sets by CategoryViewController, updates searchBar placeholder
@property (strong, nonatomic) NSString *categoryPath; // sets by CategoryViewController

// loaded listings data from server
@property (strong, nonatomic) TMListings *listingsData;
@property (strong, nonatomic) NSString *errorMessage; // if load failed this prop will handle error message to be displayed to user

@end

