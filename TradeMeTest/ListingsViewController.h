//
//  DetailViewController.h
//  TradeMeTest
//
//  Created by Serhii Simkovskyi on Nov/29/17.
//  Copyright © 2017 Serhii Simkovskyi. All rights reserved.
//

#import <UIKit/UIKit.h>

// forward declaration
@class TMListings;

@interface ListingsViewController : UIViewController

// ** current category id
@property (strong, nonatomic) NSString *categoryId;

// loaded data of current category
@property (strong, nonatomic) TMListings *listingsData;

//@property (strong, nonatomic) NSString *categoryName;
//@property (strong, nonatomic) NSDate *detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

// **
- (void)setCategory:(NSString *)aCategoryName;

@end

