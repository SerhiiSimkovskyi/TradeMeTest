//
//  CategoryViewControler.m
//  TradeMeTest
//
//  Created by Serhii Simkovskyi on Nov/29/17.
//  Copyright © 2017 Serhii Simkovskyi. All rights reserved.
//

#import "CategoryViewController.h"
#import "ListingsViewController.h"
#import "TMCategory.h"

// Our view controller can be in 3 states
typedef NS_ENUM(NSInteger, CategoryViewState)
{
    CategoryViewState_Loading = 1,
    CategoryViewState_Loaded,
    CategoryViewState_Error
};

#pragma mark -

// private interface to CategoryViewController
@interface CategoryViewController ()

@property (weak,   nonatomic) NSURLSessionDataTask *loadingTask; // we don't retain it; we get it from inceptionHandler, we can cancel it when about to start a new task (if it exists)
@property (strong, nonatomic) UIBarButtonItem *upButton; // toolbar button (we retain it as it can be removed from toolbar from time to time)
@property (strong, nonatomic) UIBarButtonItem *doneButton; // same here
@property (assign, nonatomic) CategoryViewState viewState; // our view state
@property (strong, nonatomic) UIActivityIndicatorView *spinner; // activity indicator to entertain a user when data is being downloded

@end

#pragma mark -

@implementation CategoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // setup states
    self.viewState = CategoryViewState_Loading;
    
    // Create navi bar buttons
    self.upButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind target:self action:@selector(upAction:)];
    self.navigationItem.leftBarButtonItem = self.upButton;
    self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
    self.navigationItem.rightBarButtonItem = self.doneButton;

    // Create Activity indicator
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.center = self.tableView.center;
    self.spinner.hidesWhenStopped = YES;
    [self.view addSubview:self.spinner];
    [self.view bringSubviewToFront:self.spinner];    

    // We are going to retain listings view controller (so it is not destroyed when split view is collapsed view and category view is presented)
    self.listingsViewController = (ListingsViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    self.listingsViewController.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    self.listingsViewController.navigationItem.leftItemsSupplementBackButton = YES;

    // set up path, add root category there so far
    self.categoryHierarchy = [[NSMutableArray alloc] initWithObjects:[TMCategory rootCategoryWithNoSubcategories], nil];
    
    // use some fancy colors for UI
    UIColor *tintColor = [UIColor colorWithRed:1. green:192./255. blue:65./255. alpha:1.];
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    [self.navigationController.navigationBar setBarTintColor:tintColor];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];

    // Update UI
    [self reloadSubcategories];
    [self updateUpBtn];
    [self updateDoneBtn];
    
    // invoke categoryChangedHandler with delay (to allow ListingsViewController to be loaded first)
    [self performSelector:@selector(delayedListingsUpdate:) withObject:self afterDelay:0.01];
}

- (void)delayedListingsUpdate:(id)obj {
    [self categoryChangedHandler];
}
- (void)viewWillAppear:(BOOL)animated {
    self.spinner.center = self.tableView.center; // update spinner position
    
    // done button should NOT be displayed when both category and listings view are displayed on screen
    [self updateDoneBtn];

    [super viewWillAppear:animated];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id)coordinator {
    // before rotation ->
    [coordinator animateAlongsideTransition:^(id  _Nonnull context) {
    } completion:^(id  _Nonnull context) {
        // after rotation ->
        
        // done button should NOT be displayed when both category and listings view are displayed on screen
        // on latest iphones in portrait mode split view is collapsed but in landscape mode 2 views are displayed
        // so we need to handle rotation and hide/show Done button when required
        [self updateDoneBtn];

        self.spinner.center = self.tableView.center;
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -

- (void) reloadSubcategories {
    // cancel previous loading task if any
    if (self.loadingTask != nil && self.loadingTask.state == NSURLSessionTaskStateRunning) {
        [self.loadingTask cancel];
    }
    
    // change view state to loading
    self.viewState = CategoryViewState_Loading;
    [self.tableView reloadData];
    
    // let the fun begin
    self.spinner.center = self.tableView.center;
    [self.spinner startAnimating];

    __weak typeof(self) weakSelf = self;
    NSString *aCategoryId = ((TMCategory *)self.categoryHierarchy.lastObject).categoryId;
    [TMCategory categoryById: aCategoryId
            inceptionHandler:^(NSURLSessionDataTask *task) {
                // we are given downloading task here, so we can cancel it when we need it
                self.loadingTask = task;
            }
           completionHandler:^(TMCategory *category, NSError *error) {
               // completion:
               if (weakSelf != nil) { // usually it should not happen as this controller should outlive the block, just for the sake of paranoia
                   [weakSelf.spinner stopAnimating];
                   if (error == nil) {
                       // success
                       weakSelf.viewState = CategoryViewState_Loaded;
                       weakSelf.categoryData = category;
                       weakSelf.errorMessage = nil;
                       [weakSelf.tableView reloadData]; // we should be running in main thread, TMCategory class guarantees it
                   } else {
                       // error
                       weakSelf.viewState = CategoryViewState_Error;
                       weakSelf.errorMessage = [error localizedDescription];
                       weakSelf.categoryData = nil;
                       [weakSelf.tableView reloadData]; // we should be running in main thread, TMCategory class guarantees it
                   }
               }
           }];
}

- (void) updateUpBtn {
    // Up button should not be displayed when we are on the top level already
    if (self.categoryHierarchy.count <= 1) {
        self.navigationItem.leftBarButtonItem = nil;
    } else {
        self.navigationItem.leftBarButtonItem = self.upButton;
    }
}
    
- (void) updateDoneBtn {
    // done button should NOT be displayed when both category and listings view are displayed on screen
    if (self.splitViewController.isCollapsed) {
        self.navigationItem.rightBarButtonItem = self.doneButton;
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

// this is called when current category is changed
- (void) categoryChangedHandler {
    // updated our view with new category
    TMCategory *aCategory = ((TMCategory *)self.categoryHierarchy.lastObject);
    self.navigationItem.title = aCategory.name;
    
    // and don't forget about LisitingsController, it is currious about new category as well
    self.listingsViewController.categoryId = aCategory.categoryId;
    self.listingsViewController.categoryName = aCategory.name;
    self.listingsViewController.categoryPath = aCategory.path;    
}

#pragma mark - Actions

// goes back to previous category
- (void)upAction:(id)sender {
    if (self.categoryHierarchy.count > 1) { // Root category should always exist
        [self.categoryHierarchy removeLastObject];
        [self categoryChangedHandler];
        [self reloadSubcategories];
        [self updateUpBtn];
    }
}

- (void)doneAction:(id)sender {
    if (self.splitViewController.isCollapsed) { // it makes sense only split view is collapsed
         self.listingsViewController.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
         self.listingsViewController.navigationItem.leftItemsSupplementBackButton = YES;
         [self.navigationController pushViewController:self.listingsViewController.navigationController animated:YES];
    }
}

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
            return 1;
        } break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    switch (self.viewState) {
            
        case CategoryViewState_Loaded: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellCategory" forIndexPath:indexPath];
            TMCategory *aCategory = self.categoryData.subcategories[indexPath.row];
            cell.textLabel.text = aCategory.name;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"(%ld)",aCategory.listingsCount];
            return cell;
        } break;
            
        case CategoryViewState_Loading: {
            return nil;
        } break;
            
        case CategoryViewState_Error: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellCategoryError" forIndexPath:indexPath];
            UILabel *labelErrorText = (UILabel *)[cell.contentView viewWithTag:100];
            labelErrorText.text = self.errorMessage;
            return cell;
        } break;
    }

}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (self.viewState) {
            
        case CategoryViewState_Loaded: {
            TMCategory *aCategory = ((TMCategory *)self.categoryHierarchy.lastObject);
            NSString *str = (aCategory.listingsCount == 0) ? aCategory.path : [NSString stringWithFormat:@"%@ (%ld listings)",aCategory.path, aCategory.listingsCount];
            return (self.categoryData.subcategories != nil) ? str : [NSString stringWithFormat:@"%@\n\nNo subcategories",str];
        } break;
            
        case CategoryViewState_Error: {
            return @"Error loading categories:";
        } break;
            
        case CategoryViewState_Loading: {
            return @"Loading subcategories..";
        } break;
    }
}


#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (self.viewState) {
            
        case CategoryViewState_Loaded: {
            // open selected category
            TMCategory *aCategory = self.categoryData.subcategories[indexPath.row];
            [self.categoryHierarchy addObject: [aCategory copyWithNoSubcategories] ];
            [self categoryChangedHandler];
            [self reloadSubcategories];
            [self updateUpBtn];
        } break;
            
        case CategoryViewState_Error: {
            [self reloadSubcategories]; // RETRY reload
        } break;
            
        case CategoryViewState_Loading: {
        } break;
    }
}


@end
