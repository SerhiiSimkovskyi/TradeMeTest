//
//  DetailViewController.h
//  TradeMeTest
//
//  Created by Serhii Simkovskyi on Nov/29/17.
//  Copyright © 2017 Serhii Simkovskyi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ListingsViewController : UIViewController

@property (strong, nonatomic) NSString *categoryName;
//@property (strong, nonatomic) NSDate *detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

// **
- (void)setCategory:(NSString *)aCategoryName;

@end

