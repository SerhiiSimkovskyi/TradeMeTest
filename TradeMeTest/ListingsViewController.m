//
//  DetailViewController.m
//  TradeMeTest
//
//  Created by Serhii Simkovskyi on Nov/29/17.
//  Copyright © 2017 Serhii Simkovskyi. All rights reserved.
//

#import "ListingsViewController.h"
#import "TMListings.h"

@interface ListingsViewController ()

@end

@implementation ListingsViewController

- (void)configureView {
    // Update the user interface for the detail item.
    if (self.categoryId != nil) {
        self.detailDescriptionLabel.text = self.categoryId;
    } else {
        self.detailDescriptionLabel.text = @"-";
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationItem.title = @"RRRR!";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) reloadListings {
    //self.viewState = CategoryViewState_Loading;
    //[self.tableView reloadData];
    
    __weak typeof(self) weakSelf = self;
    [TMListings listingsByCategoryId: self.categoryId completionHandler:^(TMListings *listings, NSError *error) {
        //weakSelf.viewState = CategoryViewState_Loaded;
        weakSelf.listingsData = listings;
        //[weakSelf.tableView reloadData]; // we should be running in main thread, TMCategory class guarantees it
        NSLog(@"%ld", listings.listingsCount);
        for (TMListingDetails *ldetail in listings.list) {
            NSLog(@"%@", ldetail.title);
        }

        
        // !!!        if (error != nil) {
        //            // Error
        //            NSLog(@"%@", [error localizedDescription]);
        //        } else if (category != nil) {
        //            NSLog(@"%@", category.name);
        //        } else {
        //            NSLog(@"Category is nil");
        //        }
    }];
}

#pragma mark - Managing the detail item

- (void)setCategory:(NSString *)aCategoryId {
    self.categoryId = aCategoryId;
    [self configureView];
    [self reloadListings];
}

@end
