//
//  MasterViewController.m
//  TradeMeTest
//
//  Created by Serhii Simkovskyi on Nov/29/17.
//  Copyright © 2017 Serhii Simkovskyi. All rights reserved.
//

#import "CategoryViewController.h"
#import "ListingsViewController.h"
#import "TMCategory.h"

typedef NS_ENUM(NSInteger, CategoryViewState)
{
    CategoryViewState_Loading = 1,
    CategoryViewState_Loaded,
    CategoryViewState_Error
};

// **
@interface CategoryViewController ()
@property (strong, nonatomic) UIBarButtonItem *upButton;
@property (strong, nonatomic) UIBarButtonItem *doneButton;
@property (assign, nonatomic) CategoryViewState viewState;
@end

@implementation CategoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.viewState = CategoryViewState_Loading;
    
    // Create navi bar buttons
    self.upButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind target:self action:@selector(upAction:)];
    self.navigationItem.leftBarButtonItem = self.upButton;
    self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
    self.navigationItem.rightBarButtonItem = self.doneButton;

    // **
    self.listingsViewController = (ListingsViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    self.listingsViewController.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    self.listingsViewController.navigationItem.leftItemsSupplementBackButton = YES;

    // **
    self.categoryHierarchy = [[NSMutableArray alloc] initWithObjects:[TMCategory rootCategoryWithNoSubcategories], nil];
    
    // Update UI
    [self categoryChangedHandler];
    [self reloadSubcategories];
    [self updateUpBtn];
    [self updateDoneBtn];
}

- (void)viewWillAppear:(BOOL)animated {
    [self updateDoneBtn];
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed; // !!!!
    [super viewWillAppear:animated];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -

- (void) reloadSubcategories {
    self.viewState = CategoryViewState_Loading;
    [self.tableView reloadData];
    
    __weak typeof(self) weakSelf = self;
    NSString *aCategoryId = ((TMCategory *)self.categoryHierarchy.lastObject).categoryId;
    [TMCategory categoryById: aCategoryId completionHandler:^(TMCategory * _Nullable category, NSError * _Nullable error) {
        weakSelf.viewState = CategoryViewState_Loaded;
        weakSelf.categoryData = category;
        [weakSelf.tableView reloadData]; // we should be running in main thread, TMCategory class guarantees it
        
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

- (void) updateUpBtn {
    if (self.categoryHierarchy.count <= 1) {
        self.navigationItem.leftBarButtonItem = nil;
    } else {
        self.navigationItem.leftBarButtonItem = self.upButton;
    }
}
    
- (void) updateDoneBtn {
    if (self.splitViewController.isCollapsed) {
        self.navigationItem.rightBarButtonItem = self.doneButton;
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void) categoryChangedHandler {
    TMCategory *aCategory = ((TMCategory *)self.categoryHierarchy.lastObject);
    self.navigationItem.title = aCategory.name;
    
    // update LisitingsController
    [self.listingsViewController setCategory:aCategory.categoryId];
//    if (!self.splitViewController.isCollapsed) { // If listings view is expanded then let's update it
//        [self performSegueWithIdentifier:@"showListings" sender:self];
//    }
}

#pragma mark - Actions

- (void)upAction:(id)sender {
    if (self.categoryHierarchy.count > 1) { // Root category should always exist
        [self.categoryHierarchy removeLastObject];
        [self categoryChangedHandler];
        [self reloadSubcategories];
        [self updateUpBtn];
    }
    
    self.listingsViewController.navigationItem.title = @"RRRR!";

}

- (void)doneAction:(id)sender {
    //[self performSegueWithIdentifier:@"showListings" sender:self];
    if (self.splitViewController.isCollapsed) { // **
         self.listingsViewController.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
         self.listingsViewController.navigationItem.leftItemsSupplementBackButton = YES;
         [self.navigationController pushViewController:self.listingsViewController.navigationController animated:YES];
    }
    //[self.listingsViewController setCategory:aCategory.name];
}

// !! Remove segway in story board
//#pragma mark - Segues
//
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    if ([[segue identifier] isEqualToString:@"showListings"]) {
//        ListingsViewController *controller = (ListingsViewController *)[[segue destinationViewController] topViewController];
//
//        // Update categories
//        TMCategory *aCategory = ((TMCategory *)self.categoryHierarchy.lastObject);
//        [controller setCategory:aCategory.name];
//
//        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
//        controller.navigationItem.leftItemsSupplementBackButton = YES;
//    }
//}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (self.viewState) {
        
        case CategoryViewState_Loaded: {
            if (self.categoryData != nil)
                return self.categoryData.subcategories.count;
            else
                return 0;
        } break;
     
        case CategoryViewState_Loading: {
            return 0;
        } break;

        case CategoryViewState_Error: {
            return 0;
        } break;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    switch (self.viewState) {
            
        case CategoryViewState_Loaded: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
            
            TMCategory* aCategory = self.categoryData.subcategories[indexPath.row];
            cell.textLabel.text = aCategory.name;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"(%ld)",aCategory.listingsCount];
            
            return cell;
        } break;
            
        case CategoryViewState_Loading: {
            return nil;
        } break;
            
        case CategoryViewState_Error: {
            return nil;
        } break;
    }

}

#pragma mark - UITableViewDelegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (self.viewState) {
            
        case CategoryViewState_Loaded: {
            if (self.categoryHierarchy.count <= 1) { // Root
                return @"";
            } else {
                TMCategory *aCategory = ((TMCategory *)self.categoryHierarchy.lastObject);
                NSString *str = (aCategory.listingsCount == 0) ? aCategory.path : [NSString stringWithFormat:@"%@ (%ld listings)",aCategory.path, aCategory.listingsCount];
                return (self.categoryData.subcategories != nil) ? str : [NSString stringWithFormat:@"%@\n\nNo subcategories",str];
            }
        } break;

        case CategoryViewState_Error: {
            return @"Error loading categories:";
        } break;

        case CategoryViewState_Loading: {
            return @"Loading subcategories..";
        } break;
    }
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    TMCategory* aCategory = self.categoryData.subcategories[indexPath.row];
    [self.categoryHierarchy addObject: [aCategory copyWithNoSubcategories] ];
    [self categoryChangedHandler];
    [self reloadSubcategories];
    [self updateUpBtn];

    // !!!!
    //if (!self.splitViewController.isCollapsed) { // If listings view is expanded then let's update it
    //    [self performSegueWithIdentifier:@"showListings" sender:self];
    //} // otherwise it will updated on Done button press
}


@end
