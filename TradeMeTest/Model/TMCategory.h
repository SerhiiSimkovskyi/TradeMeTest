//
//  TMCategory.h
//  TradeMeTest
//
//  Created by Serhii Simkovskyi on Nov/29/17.
//  Copyright © 2017 Serhii Simkovskyi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMCategory : NSObject

// PROPERTIES
@property (nonatomic, strong) NSString *name; // e.g. @"Motorbikes"
@property (nonatomic, strong) NSString *categoryId; // e.g. @"0276"
@property (nonatomic, strong) NSString *path; // e.g. @"/Trade Me Jobs/Education/Primary"
@property (nonatomic, assign) NSInteger listingsCount; // e.g. 32
@property (nonatomic, strong) NSArray *subcategories; // of TMCategory, nil if no subcategories exist

// FACTORY METHODS
+ (void) categoryById: (NSString *) categoryId completionHandler: (void (^)(TMCategory *category, NSError *error)) completionHandler;
+ (TMCategory *) rootCategoryWithNoSubcategories; // creates Root category with (subcategories == nil), we use it in our Category Browser

// instance is not intended to be created outside of factory methods
- (instancetype) init NS_UNAVAILABLE;

// Makes a carbon copy of itself but discards all subcategories
// (To make browsing categories more efficient we need to keep hierarchy of categories, but their subcategories will be excessive)
- (TMCategory *) copyWithNoSubcategories;

@end
