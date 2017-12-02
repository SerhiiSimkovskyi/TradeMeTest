//
//  TMListings.h
//  TradeMeTest
//
//  Created by Serhii Simkovskyi on Nov/30/17.
//  Copyright © 2017 Serhii Simkovskyi. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UIImage; // forward decl

// The number of results per page; also the maximum number of results to return
#define LISTINGS_PAGE_SIZE ((NSInteger)20)

// Sort order FOR the returned results
typedef NS_ENUM(NSInteger, ListingsSort)
{
    ListingsSort_FeaturedFirst = 1,
    ListingsSort_LowestPrice,
    ListingsSort_HighestPrice,
    ListingsSort_LowestBuyNow,
    ListingsSort_HighestBuyNow,
    ListingsSort_MostBids,
    ListingsSort_LatestListings,
    ListingsSort_ClosingSoon,
    ListingsSort_Title
};

// Condition to filter listings
typedef NS_ENUM(NSInteger, ListingsCondition)
{
    ListingsCondition_All = 0,
    ListingsCondition_New,
    ListingsCondition_Used,
};

//////////////////////////////////////////////////////
// TMListingsItem (auxilary class that holds listing item)
//////////////////////////////////////////////////////
@interface TMListingsItem : NSObject

// Loaded from remote server
@property (nonatomic, assign) NSInteger listingId; // e.g. 6215751
@property (nonatomic, strong) NSString *title; // e.g. @"Pro1 OMEGA 0025"
@property (nonatomic, strong) NSString *thumbnailURL; // e.g. @"Pro1 OMEGA 0025"

// used for caching thumbnails
@property (nonatomic, strong) UIImage *thumbnailImage;
@property (nonatomic, assign) BOOL isThumbnailLoading;

@end

//////////////////////////////////////////////////////
// TMListings: Retrieves listings from server and
// maps received info to foundation objects to be used in UI
//////////////////////////////////////////////////////
@interface TMListings : NSObject

// Loaded from remote server
@property (nonatomic, assign) NSInteger listingsCount; // e.g. 32
@property (nonatomic, strong) NSArray *list; // of TMListingsItem

// Retrieves listings from server and creates instance of TMListings if successful (it is passed to completion handler)
+ (void) listingsByCategoryId: (NSString *) categoryId
                 searchString: (NSString *) searchString
                    condition: (ListingsCondition) condition
                   sortMethod: (ListingsSort) sortMethod
                         page: (NSInteger) page
             inceptionHandler: (void (^)(NSURLSessionDataTask *task))inceptionHandler
            completionHandler: (void (^)(TMListings *listings, NSError *error)) completionHandler;

// instance is not intended to be created outside of factory methods
- (instancetype) init NS_UNAVAILABLE;

@end
