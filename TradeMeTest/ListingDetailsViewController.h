//
//  ListingDetailsViewController.h
//  TradeMeTest
//
//  Created by Serhii Simkovskyi on Dec/2/17.
//  Copyright © 2017 Serhii Simkovskyi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TMListingDetails; // forward decl


@interface ListingDetailsViewController : UITableViewController

// is set by ListingsViewController (during segue)
@property (assign, nonatomic) NSInteger listingId;

// loaded data of current category
@property (strong, nonatomic) TMListingDetails *detailsData;
@property (strong, nonatomic) NSString *errorMessage; // if load failed this prop will handle error message to be displayed to user

@end
