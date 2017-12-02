//
//  TMCategory.h
//  TradeMeTest
//
//  Created by Serhii Simkovskyi on Nov/29/17.
//  Copyright © 2017 Serhii Simkovskyi. All rights reserved.
//

#import <Foundation/Foundation.h>

//////////////////////////////////////////////////////
// TMCategory: Retrieves categories from server and
// maps received info to foundation objects to be used in UI
//////////////////////////////////////////////////////
@interface TMCategory : NSObject

// Loaded from remote server
@property (nonatomic, strong) NSString *name; // e.g. @"Motorbikes"
@property (nonatomic, strong) NSString *categoryId; // e.g. @"0276"
@property (nonatomic, strong) NSString *path; // e.g. @"/Trade Me Jobs/Education/Primary"
@property (nonatomic, assign) NSInteger listingsCount; // total listings count returned by query e.g. 32
@property (nonatomic, strong) NSArray *subcategories; // of TMCategory, nil if no subcategories exist

// Retrieves categories from server and creates instance of TMCategory if successful (it is passed to completion handler)
+ (void) categoryById: (NSString *) categoryId
     inceptionHandler:(void (^)(NSURLSessionDataTask *task))inceptionHandler
    completionHandler: (void (^)(TMCategory *category, NSError *error)) completionHandler;

// creates Root category with (subcategories == nil), we use it in our Category Browser
+ (TMCategory *) rootCategoryWithNoSubcategories;

// instance is not intended to be created outside of factory methods
- (instancetype) init NS_UNAVAILABLE;

// Makes a carbon copy of itself but discards all subcategories
// (To make browsing categories more efficient we need to keep hierarchy of categories, but their subcategories will add overhead)
- (TMCategory *) copyWithNoSubcategories;

@end
