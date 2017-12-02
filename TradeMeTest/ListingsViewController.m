//
//  ListingsViewController
//  TradeMeTest
//
//  Created by Serhii Simkovskyi on Nov/29/17.
//  Copyright © 2017 Serhii Simkovskyi. All rights reserved.
//

#import "ListingsViewController.h"
#import "ListingDetailsViewController.h"

// Our view controller can be in 3 states
typedef NS_ENUM(NSInteger, ListingsViewState)
{
    ListingsViewState_Loading = 1,
    ListingsViewState_Loaded,
    ListingsViewState_Error
};

// private interface to ListingsViewController
@interface ListingsViewController ()
@property (weak,   nonatomic) NSURLSessionDataTask *loadingTask; // we don't retain it; we get it from inceptionHandler, we can cancel it when about to start a new task (if it exists)
@property (assign, nonatomic) ListingsViewState viewState; // our view state
@property (strong, nonatomic) UIActivityIndicatorView *spinner; // activity indicator to entertain a user when data is being downloded
@property (strong, nonatomic) NSURLSession *urlSessionThumbNails; // we create and retain URL session to load thumbnails, with it we can cancel all loading tasks when the data source is about to be changed

@end

#pragma mark -

@implementation ListingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // setup properties with default values
    self.viewState = ListingsViewState_Loading;
    _listingsSort = ListingsSort_FeaturedFirst; // address ivar directly to prevent the setter to be called (as it will try to reload data that is not needed now)
    _listingsCondition = ListingsCondition_All; // same here
    _searchString = @""; // same here
    _currentPage = 1; // same here
    
    // Assign delegates
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.searchBar.delegate = self;
    
    // set up tableview
    self.tableView.estimatedRowHeight = 64.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    // use some fancy colors for UI
    UIColor *tintColor = [UIColor colorWithRed:1. green:192./255. blue:65./255. alpha:1.];
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    [self.navigationController.navigationBar setBarTintColor:tintColor];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];

    self.searchBar.barStyle = UIBarStyleDefault;
    [self.searchBar setTranslucent:NO];
    self.searchBar.barTintColor = tintColor;
    self.searchBar.backgroundImage = [UIImage new];
    
    // Create Activity indicator
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.center = self.tableView.center;
    self.spinner.hidesWhenStopped = YES;
    [self.view addSubview:self.spinner];
    [self.view bringSubviewToFront:self.spinner];
}

- (void)viewWillAppear:(BOOL)animated {
    self.spinner.center = self.tableView.center; // update spinner position
}

- (void)viewDidAppear:(BOOL)animated {
    // deselect table selection
    NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
    if (indexPath) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:animated];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id)coordinator {
    // before rotation ->
    [coordinator animateAlongsideTransition:^(id  _Nonnull context) {
    } completion:^(id  _Nonnull context) {
        // after rotation ->
        self.spinner.center = self.tableView.center; // update spinner position
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 

- (void) reloadListings {

    // cancel all tasks that load thumbnails
    if (self.urlSessionThumbNails)
         [self.urlSessionThumbNails invalidateAndCancel];
    self.urlSessionThumbNails = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];

    // cancel previous loading task if any
    if (self.loadingTask != nil && self.loadingTask.state == NSURLSessionTaskStateRunning) {
        [self.loadingTask cancel];
    }
    
    // change view state to loading
    self.viewState = ListingsViewState_Loading;
    [self.tableView reloadData];
    
    // let the fun begin
    self.spinner.center = self.tableView.center;
    [self.spinner startAnimating];
    
    __weak typeof(self) weakSelf = self;
    [TMListings listingsByCategoryId: self.categoryId
                        searchString: self.searchString
                           condition: self.listingsCondition
                          sortMethod: self.listingsSort
                                page: self.currentPage
                    inceptionHandler:^(NSURLSessionDataTask *task) {
                        // we are given downloading task here, so we can cancel it when we need it
                        self.loadingTask = task;
                    }
                   completionHandler:^(TMListings *listings, NSError *error) {
                       if (weakSelf != nil) { // usually it should not happen as this controller should outlive the block, for the sake of paranoia
                           [weakSelf.spinner stopAnimating];
                           if (error == nil) {
                               // success
                               weakSelf.viewState = ListingsViewState_Loaded;
                               weakSelf.listingsData = listings;
                               [weakSelf.tableView reloadData]; // we should be running in main thread, TMListings class guarantees it
                           } else {
                               // error
                               weakSelf.viewState = ListingsViewState_Error;
                               weakSelf.errorMessage = [error localizedDescription];
                               weakSelf.listingsData = nil;
                               [weakSelf.tableView reloadData]; // we should be running in main thread, TMListings class guarantees it
                           }
                       }
                   }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (self.viewState) {
            
        case ListingsViewState_Loaded: {
            if (self.listingsData != nil)
                return self.listingsData.list.count;
            else
                return 0;
        } break;
            
        case ListingsViewState_Loading: {
            return 0;
        } break;
            
        case ListingsViewState_Error: {
            return 1;
        } break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (self.viewState) {
            
        case ListingsViewState_Loaded: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellListing" forIndexPath:indexPath];
            TMListingsItem *aListingItem = self.listingsData.list[indexPath.row];

            UILabel *labelText = (UILabel *)[cell.contentView viewWithTag:102];
            labelText.text = aListingItem.title;
            
            // ---------------------------------------------------
            // Setup thumbnail, load it async, with caching
            // ---------------------------------------------------
            UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:101];
            if (aListingItem.thumbnailImage != nil) {
                // thumbnail was already loaded. use it
                imageView.image = aListingItem.thumbnailImage;
            } else if (aListingItem.isThumbnailLoading) {
                // current thumbnail is already loading. Do nothing
                imageView.image = [UIImage imageNamed:@"thumbnail_loading"]; // we have to setup the image again as cell can be reused!
            } else {
                // there is no caching info -> intitiate thumbnail download:
                imageView.image = [UIImage imageNamed:@"thumbnail_loading"];
                if (aListingItem.thumbnailURL && aListingItem.thumbnailURL.length > 0) {
                    // url string looks valid at first sight (at least not empty)
                    NSURL *url = [NSURL URLWithString:aListingItem.thumbnailURL];
                    // create download task
                    aListingItem.isThumbnailLoading = YES;
                    NSURLSessionTask *task = [self.urlSessionThumbNails dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                        // === download task completion handler:
                        // (we should not worry about completion after date source and table was reloaded, as before reload we cancel all async loading tasks)

                        TMListingsItem *block_ListingItem = self.listingsData.list[indexPath.row];
                        if (block_ListingItem) {
                            block_ListingItem.isThumbnailLoading = NO;
                        }

                        if (error != nil || data == nil) {
                            if (error.code == -999) {
                                // task was canceled (data source is about to be reloaded), this is intened, do nothing
                                // NSLog(@"Task canceled");
                            } else {
                                // task failed:
                                // run block on main thread (to update UI)
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    // update cell image with N/A placeholder
                                    UITableViewCell *block_cell = (id)[tableView cellForRowAtIndexPath:indexPath];
                                    if (block_cell) {
                                        UIImageView *block_imageView = (UIImageView *)[block_cell.contentView viewWithTag:101];
                                        block_imageView.image = [UIImage imageNamed:@"thumbnail_na"];
                                    }
                                });
                            }
                        } else {
                            // task success:
                            // run block on main thread (to update UI)
                            dispatch_async(dispatch_get_main_queue(), ^{
                                // create image from loaded Data
                                UIImage *image = [UIImage imageWithData:data];

                                // cache image in data source for later use
                                if (block_ListingItem) {
                                    block_ListingItem.thumbnailImage = image; // can be nil, it is ok
                                }

                                // update cell with image
                                UITableViewCell *block_cell = (id)[tableView cellForRowAtIndexPath:indexPath];
                                if (block_cell) {
                                    UIImageView *block_imageView = (UIImageView *)[block_cell.contentView viewWithTag:101];
                                    if (image) {
                                        block_imageView.image = image;
                                    } else {
                                        // loaded data wasn't image
                                        block_imageView.image = [UIImage imageNamed:@"thumbnail_na"];
                                    }
                                }
                            });
                            
                        }
                    }];
                    [task resume];
                } else {
                    // empty URL, no need to even try to load it
                    imageView.image = [UIImage imageNamed:@"thumbnail_na"];
                }
                // ---------------------------------------------------
            }
            return cell;
        } break;
            
        case ListingsViewState_Loading: {
            return nil;
        } break;
            
        case ListingsViewState_Error: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellListingsError" forIndexPath:indexPath];
            UILabel *labelErrorText = (UILabel *)[cell.contentView viewWithTag:100];
            labelErrorText.text = self.errorMessage;
            return cell;
        } break;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (self.viewState) {
        case ListingsViewState_Loaded: {
            NSInteger from = (self.currentPage-1)*LISTINGS_PAGE_SIZE+1;
            NSInteger to = (self.currentPage-1)*LISTINGS_PAGE_SIZE+self.listingsData.list.count;
            NSString *displayStr = [NSString stringWithFormat:@"%ld listings, showing %ld to %ld", self.listingsData.listingsCount, from, to];
            if (self.listingsData.listingsCount == 0) {
                displayStr = @"No listings to display";
            }
            return [NSString stringWithFormat:@"%@\n\n%@", self.categoryPath, displayStr];
        } break;
            
        case ListingsViewState_Error: {
            return @"Error loading listings:";
        } break;
            
        case ListingsViewState_Loading: {
            return @"Loading listings..";
        } break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (self.viewState ==ListingsViewState_Loaded) {
        return 44.0;
    }
    return 0.0;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (self.viewState ==ListingsViewState_Loaded) {
        // let use one of the cells for footer
        UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"cellFooter"];
        
        // cells usually have a number of gesture recognisers, we don't need it, -> remove them
        while (cell.contentView.gestureRecognizers.count)
        {
            [cell.contentView removeGestureRecognizer:[cell.contentView.gestureRecognizers objectAtIndex:0]];
        }
        
        // set up cell buttons
        UIButton *buttonFirst = (UIButton*)[cell.contentView viewWithTag:101];
        UIButton *buttonPrev = (UIButton*)[cell.contentView viewWithTag:102];
        UIButton *buttonNext = (UIButton*)[cell.contentView viewWithTag:103];

        [buttonFirst addTarget:self action:@selector(firstPageAction:) forControlEvents:UIControlEventTouchUpInside];
        [buttonPrev addTarget:self action:@selector(prevPageAction:) forControlEvents:UIControlEventTouchUpInside];
        [buttonNext addTarget:self action:@selector(nextPageAction:) forControlEvents:UIControlEventTouchUpInside];
        
        // hide first and prev buttons when we are at first page already
        if (self.currentPage <= 1) {
            [buttonFirst setHidden:YES];
            [buttonPrev setHidden:YES];
        } else {
            [buttonFirst setHidden:NO];
            [buttonPrev setHidden:NO];
        }
        
        // hide next button when there are no more listings to display
        if (self.listingsData.list.count < 20 || ((self.currentPage-1)*LISTINGS_PAGE_SIZE+self.listingsData.list.count >= self.listingsData.listingsCount)) {
            [buttonNext setHidden:YES];
        } else {
            [buttonNext setHidden:NO];
        }
        
        return cell.contentView;

    } else {
        return nil;
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 64.0;
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (self.viewState) {
            
        case ListingsViewState_Loaded: {
            // showDetails segue will be fired when this row is pressed
            // it will open Listing Details controller
        } break;
            
        case ListingsViewState_Error: {
            [self reloadListings]; // RETRY reload
        } break;
            
        case ListingsViewState_Loading: {
        } break;
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.searchBar.showsCancelButton = YES;
}

// I'd like to have Cancel button to be visible even after end editing, so we can cancel filter anytime
- (void)enableCancelButton:(UIView *)view {
    if ([view isKindOfClass:[UIButton class]]) {
        [(UIButton *)view setEnabled:YES];
    } else {
        for (UIView *subview in view.subviews) {
            [self enableCancelButton:subview];
        }
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{
    // enable Cancel button
    [self performSelector:@selector(enableCancelButton:) withObject:searchBar afterDelay:0.001];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    // no dynamic search is needed, let's wait until user pushes Search button
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    self.searchBar.showsCancelButton = YES;
    [self.searchBar resignFirstResponder]; // hide keyboard
    self.searchString = searchBar.text; // update searchString property (it will also reload data if needed)
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchBar.showsCancelButton = NO;
    self.searchBar.text = @"";
    [self.searchBar resignFirstResponder]; // hide keyboard
    self.searchString = @""; // update searchString property (it will also reload data if needed)
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    self.listingsCondition = selectedScope;  // update property (it will also reload data if needed)
}

#pragma mark - Setter methods

- (void)setCategoryId:(NSString *)aCategoryId {
    if (![_categoryId isEqualToString:aCategoryId]) {
        _categoryId = aCategoryId;
        _currentPage = 1; // reset paging
        [self reloadListings];
    }
}

- (void)setSearchString:(NSString *)aSearchString {
    if (![_searchString isEqualToString:aSearchString]) {
        _searchString = aSearchString;
        _currentPage = 1; // reset paging
        [self reloadListings];
    }
}
- (void)setListingsSort:(ListingsSort)aListingsSort {
    if (_listingsSort != aListingsSort) {
        _listingsSort = aListingsSort;
        _currentPage = 1; // reset paging
        [self reloadListings];
    }
}

- (void)setListingsCondition:(ListingsCondition) aListingsCondition {
    if (_listingsCondition != aListingsCondition) {
        _listingsCondition = aListingsCondition;
        _currentPage = 1; // reset paging
        [self reloadListings];
    }
}

- (void)setCategoryName:(NSString *)aCategoryName {
    _categoryName = aCategoryName;
    self.searchBar.placeholder = [NSString stringWithFormat:@"Search in %@", _categoryName];
}

- (void)setCurrentPage:(NSInteger) aPageNum {
    if (_currentPage != aPageNum) {
        _currentPage = aPageNum;
        [self reloadListings];
    }
}

#pragma mark - Actions

- (void)firstPageAction:(id)sender {
    self.currentPage = 1; // it will also force to reload datasource
}
- (void)prevPageAction:(id)sender {
    self.currentPage -= 1; // it will also force to reload datasource
}
- (void)nextPageAction:(id)sender {
    self.currentPage += 1; // it will also force to reload datasource
}

// Allows a user to select sort method
- (IBAction)sortSelectionAction:(id)sender {
    
    UIAlertController *alertController;
    UIAlertAction *anAction;
    
    alertController = [UIAlertController alertControllerWithTitle:nil
                                                          message:nil
                                                   preferredStyle:UIAlertControllerStyleActionSheet];

    // define macros to save some time and minimize copy/paste errors
    #define ADDACTION(title,value) \
       anAction = [UIAlertAction actionWithTitle:@#title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { \
          self.listingsSort = value; \
       }]; \
       if (self.listingsSort == value) \
          [anAction setValue:@true forKey:@"checked"]; \
       [alertController addAction:anAction];
    
    ADDACTION("Featured first",ListingsSort_FeaturedFirst)
    ADDACTION("Lowest price",ListingsSort_LowestPrice)
    ADDACTION("Highest price",ListingsSort_HighestPrice)
    ADDACTION("Lowest Buy Now",ListingsSort_LowestBuyNow)
    ADDACTION("Highest Buy Now",ListingsSort_HighestBuyNow)
    ADDACTION("Most bids",ListingsSort_MostBids)
    ADDACTION("Latest listings",ListingsSort_LatestListings)
    ADDACTION("Closing soon",ListingsSort_ClosingSoon)
    ADDACTION("Title",ListingsSort_Title)

    // Cancel will be auto removed on ipad (as on iPad it is presented as popover)
    anAction = [UIAlertAction actionWithTitle:@"Cancel"
                                        style:UIAlertActionStyleCancel
                                      handler:^(UIAlertAction *action) {
                                          // do nothing
                                      }];
    [alertController addAction:anAction];

    [alertController setModalPresentationStyle:UIModalPresentationPopover];
    
    UIPopoverPresentationController *popPresenter = [alertController popoverPresentationController];
    popPresenter.barButtonItem = self.btnSort;
    popPresenter.sourceView = self.view;
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Navigation

// do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetails"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        TMListingsItem *aListingItem = self.listingsData.list[indexPath.row];
        
        // pass listingId to ListingDetailsViewController
        ListingDetailsViewController *controller = (ListingDetailsViewController *)[[segue destinationViewController] topViewController];
        controller.listingId = aListingItem.listingId;
    }
}

@end
