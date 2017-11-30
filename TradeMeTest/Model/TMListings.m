//
//  TMListings.m
//  TradeMeTest
//
//  Created by Serhii Simkovskyi on Nov/30/17.
//  Copyright © 2017 Serhii Simkovskyi. All rights reserved.
//

#import "TMListings.h"

//////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////

@implementation TMListingDetails
@end

//////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////

#pragma mark - Private interface to TMListings

@interface TMListings()
- (nullable instancetype) initListings;
@end

#pragma mark -

@implementation TMListings

- (instancetype) initListings {
    return [super init];
}

#pragma mark - Factory methods

+ (void) listingsByCategoryId: (NSString *) categoryId completionHandler: (void (^)(TMListings *listings, NSError *error)) completionHandler {

    // --------------------------------------------------------------
    // REST API DESCR:
    // http://developer.trademe.co.nz/api-reference/search-methods/general-search/
    // --------------------------------------------------------------
    
    // Build URL to retrieve categories from server
    NSString * urlStr = [NSString stringWithFormat:@"https://api.tmsandbox.co.nz/v1/Search/General.json?category=%@", categoryId];
    NSURL *url = [NSURL URLWithString:urlStr];

    // **
    NSString *authValue = [NSString stringWithFormat:@"OAuth oauth_consumer_key=\"%@\", oauth_signature_method=\"PLAINTEXT\", oauth_signature=\"%@&\"",@"A1AC63F0332A131A78FAC304D007E7D1",@"EC7F18B17A062962C6930A8AE88B16C7"];

    //Configure your session with common header fields like authorization etc
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.HTTPAdditionalHeaders = @{@"Authorization": authValue};
    
    // retrieve the contents of the specified URL
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *taskError) {
        // completion:
        TMListings *listings = nil; // will be passed to completionHandler
        NSError *error = nil; // will be passed to completionHandler
        
        if (!taskError) {
            // Success
            if ([response isKindOfClass:[NSHTTPURLResponse class]] && ((NSHTTPURLResponse*)response).statusCode == 200) {
                // response: HTTP 200 OK
                listings = [TMListings _createListingsFromJSONData:data];
                if (listings == nil) {
                    error = [NSError errorWithDomain:@"TM" code:1 userInfo:@{ NSLocalizedDescriptionKey:@"Error loading categories. Invalid data format." }];
                }
            }  else {
                //Web server is returning an error
                NSLog(@"Web server is returning an error");
                error = [NSError errorWithDomain:@"TM" code:1 userInfo:@{ NSLocalizedDescriptionKey:@"Error loading categories. Bad request." }];
            }
        } else {
            // Fail
            NSLog(@"error : %@", taskError.description);
            error = [NSError errorWithDomain:@"TM" code:1 userInfo:@{ NSLocalizedDescriptionKey:@"Error loading categories. Network error." }];
        }
        
        // Invoke completionHandler (on main thread!)
        if (completionHandler) {
            if ( [[NSThread currentThread] isMainThread] ) {
                completionHandler(listings,error);
            } else {
                // We will update UI in completionHandler, so let's make sure it is run on  main thread
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(listings,error);
                });
            }
        }
    }];
    
    // fire request
    [dataTask resume];
}

#pragma mark - private methods

+ (TMListings *) _createListingsFromJSONData: (NSData *) data {
    TMListings *result = nil;
    
    NSError *jsonError;
    
    // Get a foundation object from given JSON data (NSDictionary, NSArray)
    id jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    
    if (jsonError) {
        // Error parsing JSON
        NSLog(@"Error parsing JSON: %@", [jsonError description]);
    } else {
        // Success Parsing JSON
        if ([jsonResponse isKindOfClass:[NSDictionary class]]) {
            NSDictionary *jsonDict = (NSDictionary *)jsonResponse; // downcast jsonResponse to NSDictionary
            
            result = [[TMListings alloc] initListings];
            result.listingsCount = ((NSNumber *)[jsonDict objectForKey:@"TotalCount"]).integerValue;
            
            // populate listings
            NSArray *aListingsArray = [jsonDict objectForKey:@"List"];
            if (aListingsArray != nil) {
                result.list = [[NSMutableArray alloc] init];
                for (NSDictionary *dict in aListingsArray) {
                    TMListingDetails *aListingDetail = [[TMListingDetails alloc] init];
                    aListingDetail.listingId = ((NSNumber *)[dict objectForKey:@"ListingId"]).integerValue;
                    aListingDetail.title = [dict objectForKey:@"Title"];
                    [(NSMutableArray *)result.list addObject:aListingDetail];
                }
            }
        } else {
            // Error -> data received from server do not match to our expectations
            // jsonResponse is NSArray, that's not what we expect!
            NSLog(@"Error loading categories: jsonResponse is expected to be NSDictionary");
        }
    }
    return result;
}

@end
