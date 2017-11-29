//
//  DetailViewController.m
//  TradeMeTest
//
//  Created by Serhii Simkovskyi on Nov/29/17.
//  Copyright © 2017 Serhii Simkovskyi. All rights reserved.
//

#import "ListingsViewController.h"

@interface ListingsViewController ()

@end

@implementation ListingsViewController

- (void)configureView {
    // Update the user interface for the detail item.
    if (self.categoryName != nil) {
        self.detailDescriptionLabel.text = self.categoryName;
    } else {
        self.detailDescriptionLabel.text = @"-";
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Managing the detail item

- (void)setCategory:(NSString *)aCategoryName {
    self.categoryName = aCategoryName;
    [self configureView];
}

@end
