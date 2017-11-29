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
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *number;
@property (nonatomic, strong) NSArray *subcategories; // of TMCategory

// FACTORY METHODS
+ (void) categoryById: (int) categoryId completionHandler: (void (^)(TMCategory *category, NSError *error)) completionHandler;

// instance is not intended to be created outside of factory methods
- (instancetype) init NS_UNAVAILABLE;

@end
