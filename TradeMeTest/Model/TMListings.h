//
//  TMListings.h
//  TradeMeTest
//
//  Created by Serhii Simkovskyi on Nov/30/17.
//  Copyright © 2017 Serhii Simkovskyi. All rights reserved.
//

#import <Foundation/Foundation.h>

//////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////
@interface TMListingDetails : NSObject
@property (nonatomic, assign) NSInteger listingId; // e.g. 6215751
@property (nonatomic, strong) NSString *title; // e.g. @"Pro1 OMEGA 0025"
@end

//////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////

@interface TMListings : NSObject

@property (nonatomic, assign) NSInteger listingsCount; // e.g. 32
@property (nonatomic, strong) NSArray *list; // of TMListingDetails

// FACTORY METHODS
+ (void) listingsByCategoryId: (NSString *) categoryId completionHandler: (void (^)(TMListings *listings, NSError *error)) completionHandler;

// instance is not intended to be created outside of factory methods
- (instancetype) init NS_UNAVAILABLE;

@end
