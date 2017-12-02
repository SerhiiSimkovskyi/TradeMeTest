//
//  ListingDetailsViewController.m
//  TradeMeTest
//
//  Created by Serhii Simkovskyi on Dec/2/17.
//  Copyright © 2017 Serhii Simkovskyi. All rights reserved.
//

#import "ListingDetailsViewController.h"
#import "TMListingDetails.h"

// Our view controller can be in 3 states
typedef NS_ENUM(NSInteger, DetailsViewState)
{
    DetailsViewState_Loading = 1,
    DetailsViewState_Loaded,
    DetailsViewState_Error
};

// private interface to ListingDetailsViewController
@interface ListingDetailsViewController ()
@property (assign, nonatomic) DetailsViewState viewState; // our view state
@property (strong, nonatomic) UIActivityIndicatorView *spinner; // activity indicator to entertain a user when data is being downloded
@end

#pragma mark -

@implementation ListingDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // setup properties with default values
    self.viewState = DetailsViewState_Loading;
    
    // set up tableview
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.clearsSelectionOnViewWillAppear = YES;
    
    // use some fancy colors for UI
    UIColor *tintColor = [UIColor colorWithRed:1. green:192./255. blue:65./255. alpha:1.];
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    [self.navigationController.navigationBar setBarTintColor:tintColor];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];

    // Create Activity indicator
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.center = self.tableView.center;
    self.spinner.hidesWhenStopped = YES;
    [self.view addSubview:self.spinner];
    [self.view bringSubviewToFront:self.spinner];
    
    // start loading listing data from server
    [self reloadDetails];
}

- (void)viewWillAppear:(BOOL)animated {
    self.spinner.center = self.tableView.center;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id)coordinator {
    // before rotation ->
    [coordinator animateAlongsideTransition:^(id  _Nonnull context) {
    } completion:^(id  _Nonnull context) {
        // after rotation ->
        self.spinner.center = self.tableView.center;
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -

- (void) reloadDetails {
    
    // change view state to loading
    self.viewState = DetailsViewState_Loading;
    [self.tableView reloadData];
    
    // let the fun begin
    self.spinner.center = self.tableView.center;
    [self.spinner startAnimating];
    
    __weak typeof(self) weakSelf = self;
    [TMListingDetails listingDetailsById: self.listingId
                   completionHandler:^(TMListingDetails *listingDetails, NSError *error) {
                       if (weakSelf != nil) { // usually it should not happen as this controller should outlive the block, for the sake of paranoia
                           [weakSelf.spinner stopAnimating];
                           if (error == nil) {
                               // success
                               weakSelf.viewState = DetailsViewState_Loaded;
                               weakSelf.detailsData = listingDetails;
                               [weakSelf.tableView reloadData]; // we should be running in main thread, TMListingDetails class guarantees it
                           } else {
                               // error
                               weakSelf.viewState = DetailsViewState_Error;
                               weakSelf.errorMessage = [error localizedDescription];
                               weakSelf.detailsData = nil;
                               [weakSelf.tableView reloadData]; // we should be running in main thread, TMListingDetails class guarantees it
                           }
                       }
                   }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (self.viewState) {
            
        case DetailsViewState_Loaded: {
            if (self.detailsData != nil)
                return self.detailsData.details.allKeys.count;
            else
                return 0;
        } break;
            
        case DetailsViewState_Loading: {
            return 0;
        } break;
            
        case DetailsViewState_Error: {
            return 1;
        } break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (self.viewState) {
            
        case DetailsViewState_Loaded: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellDetails" forIndexPath:indexPath];
            
            // dump whole dictionary in our tableview:
            
            NSString *key = self.detailsData.details.allKeys[indexPath.row];
            NSString *value;
            
            id valueObj = [self.detailsData.details objectForKey:key];
            value = [NSString stringWithFormat:@"%@", valueObj];
            // NSStringFromClass([valueObj class]);
            
            UILabel *labelKey = (UILabel *)[cell.contentView viewWithTag:101];
            UILabel *labelValue = (UILabel *)[cell.contentView viewWithTag:102];

            labelKey.text = key;
            labelValue.text = value;
            
            return cell;
        } break;
        
        case DetailsViewState_Loading: {
            return nil;
        } break;
            
        case DetailsViewState_Error: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellDetailsError" forIndexPath:indexPath];
            UILabel *labelErrorText = (UILabel *)[cell.contentView viewWithTag:100];
            labelErrorText.text = self.errorMessage;
            return cell;
        } break;
    }
    return nil;
}

#pragma mark -

- (IBAction)doneAction:(id)sender {
    // close details controller
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
