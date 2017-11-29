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

@interface CategoryViewController ()
@property NSMutableArray *objects;
@end

@implementation CategoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    //UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    //self.navigationItem.rightBarButtonItem = addButton;
    
    self.detailViewController = (ListingsViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    __weak typeof(self) weakSelf = self;
    [TMCategory categoryById:1 completionHandler:^(TMCategory * _Nullable category, NSError * _Nullable error) {
        weakSelf.categoryData = category;
        weakSelf.navigationItem.title = self.categoryData.name;
        [weakSelf.tableView reloadData];
        
        if (error != nil) {
            // Error
            NSLog(@"%@", [error localizedDescription]);
        } else if (category != nil) {
            NSLog(@"%@", category.name);
        } else {
            NSLog(@"Category is nil");
        }
    }];
}


- (void)viewWillAppear:(BOOL)animated {
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed; // !!!!
    [super viewWillAppear:animated];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)insertNewObject:(id)sender {
    if (!self.objects) {
        self.objects = [[NSMutableArray alloc] init];
    }
    [self.objects insertObject:[NSDate date] atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}


#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        //!!NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSString* aCategoryName = nil;
        if (self.categoryData != nil) {
            aCategoryName = self.categoryData.name;
        }
        //!!NSDate *object = self.objects[indexPath.row];
        ListingsViewController *controller = (ListingsViewController *)[[segue destinationViewController] topViewController];
        //[controller setDetailItem:object];
        [controller setCategory:aCategoryName];
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.categoryData != nil)
        return self.categoryData.subcategories.count;
    else
        return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    TMCategory* aCategory = self.categoryData.subcategories[indexPath.row];
    cell.textLabel.text = aCategory.name;
    
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}


@end
