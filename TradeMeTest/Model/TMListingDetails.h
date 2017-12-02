//
//  TMListingDetails.h
//  TradeMeTest
//
//  Created by Serhii Simkovskyi on Dec/2/17.
//  Copyright © 2017 Serhii Simkovskyi. All rights reserved.
//

#import <Foundation/Foundation.h>

//////////////////////////////////////////////////////
// TMListingDetails: Retrieves listing details from server and
// maps received info to foundation objects to be used in UI
//////////////////////////////////////////////////////
@interface TMListingDetails : NSObject

// Loaded from remote server
@property (nonatomic, strong) NSDictionary *details; // contains dictionary with all listings details to dsiaply for test purpouses.

// Retrieves listing details from server and creates instance of TMListingDetails if successful (it is passed to completion handler)
+ (void) listingDetailsById: (NSInteger) listingId
            completionHandler: (void (^)(TMListingDetails *listingDetails, NSError *error)) completionHandler;

// instance is not intended to be created outside of factory methods
- (instancetype) init NS_UNAVAILABLE;

@end
