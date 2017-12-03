//
//  TMListings.m
//  TradeMeTest
//
//  Created by Serhii Simkovskyi on Nov/30/17.
//  Copyright © 2017 Serhii Simkovskyi. All rights reserved.
//

#import "TMListings.h"
#import "TMErrors.h"

#pragma mark - TMListingsItem implementation

// TMListingsItem is just a container
@implementation TMListingsItem
@end

#pragma mark - Private interface to TMListings

@interface TMListings()
- (nullable instancetype) initListings; // "hidden" init method
@end

#pragma mark -

@implementation TMListings

- (instancetype) initListings {
    // just call default init here, as it is hidden from a user of a class (class is not inteneded to be created outside of factory methods)
    return [super init];
}

#pragma mark - Factory methods

// Retrieves listings from server and creates instance of TMListings if successful (it is passed to completion handler)
+ (void) listingsByCategoryId: (NSString *) categoryId
                 searchString: (NSString *) searchString
                    condition: (ListingsCondition) condition
                   sortMethod: (ListingsSort) sortMethod
                         page: (NSInteger) page
             inceptionHandler:(void (^)(NSURLSessionDataTask *task))inceptionHandler
            completionHandler: (void (^)(TMListings *listings, NSError *error)) completionHandler {

    // --------------------------------------------------------------
    // REST API DESCR:
    // http://developer.trademe.co.nz/api-reference/search-methods/general-search/
    // --------------------------------------------------------------
    
    // Build URL to retrieve listings from server:
    // -- prepare condition param
    NSString *conditionParam=@"";
    switch (condition) {
        case ListingsCondition_All:
            conditionParam = @"All";
            break;
        case ListingsCondition_New:
            conditionParam = @"New";
            break;
        case ListingsCondition_Used:
            conditionParam = @"Used";
            break;
    }
    // -- prepare sort method param
    NSString *sortParam=@"";
    switch (sortMethod) {
        case ListingsSort_FeaturedFirst:
            sortParam = @"FeaturedFirst";
            break;
        case ListingsSort_LowestPrice:
            sortParam = @"PriceAsc";
            break;
        case ListingsSort_HighestPrice:
            sortParam = @"PriceDesc";
            break;
        case ListingsSort_LowestBuyNow:
            sortParam = @"BuyNowAsc";
            break;
        case ListingsSort_HighestBuyNow:
            sortParam = @"BuyNowDesc";
            break;
        case ListingsSort_MostBids:
            sortParam = @"BidsMost";
            break;
        case ListingsSort_LatestListings:
            sortParam = @"ExpiryDesc";
            break;
        case ListingsSort_ClosingSoon:
            sortParam = @"ExpiryAsc";
            break;
        case ListingsSort_Title:
            sortParam = @"TitleAsc";
            break;
    }
    // setup url from all params
    NSString *urlStr = [NSString stringWithFormat:@"https://api.tmsandbox.co.nz/v1/Search/General.json?category=%@&condition=%@&sort_order=%@&rows=%ld&page=%ld&photo_size=Thumbnail", categoryId, conditionParam, sortParam, LISTINGS_PAGE_SIZE, page];

    // -- add search string param (if present)
    if (searchString != nil && searchString.length > 0) {
        // percent-encode searchString for inclusion in a URL
        NSCharacterSet *allowedCharacters = [NSCharacterSet URLFragmentAllowedCharacterSet];
        NSString *percentEncodedString = [searchString stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
        urlStr = [NSString stringWithFormat:@"%@&search_string=%@",urlStr,percentEncodedString];
    }

    // create URL from string
    NSURL *url = [NSURL URLWithString:urlStr];

    // This API requires authentication
    NSString *authValue = [NSString stringWithFormat:@"OAuth oauth_consumer_key=\"%@\", oauth_signature_method=\"PLAINTEXT\", oauth_signature=\"%@&\"",@"A1AC63F0332A131A78FAC304D007E7D1",@"EC7F18B17A062962C6930A8AE88B16C7"];

    //Configure session with common header field: authorization
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
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                switch (((NSHTTPURLResponse*)response).statusCode) { // response:
                    case 200: {
                        // Success: HTTP 200 OK
                        // create and init TMListings object
                        listings = [TMListings createListingsFromJSONData:data];
                        if (listings == nil) {
                            // failed to create object from received data
                            error = [NSError errorWithDomain:TMErrDomain code:TMError_InvalidDataFormat userInfo:@{ NSLocalizedDescriptionKey:@"Invalid data format" }];
                        }
                    } break;
                        
                    case 401: { // Authentication failure
                        error = [NSError errorWithDomain:TMErrDomain code:TMError_AuthenticationFailure userInfo:@{ NSLocalizedDescriptionKey:@"Authentication failure" }];
                    } break;
                        
                    case 429: { // Rate limits are exceeded
                        error = [NSError errorWithDomain:TMErrDomain code:TMError_RateLimits userInfo:@{ NSLocalizedDescriptionKey:@"Rate limits are exceeded" }];
                    } break;
                        
                    case 500: { // Unplanned Outage
                        error = [NSError errorWithDomain:TMErrDomain code:TMError_UnplannedOutage userInfo:@{ NSLocalizedDescriptionKey:@"Unplanned Outage" }];
                    } break;
                        
                    case 503: { // Planned Outage
                        error = [NSError errorWithDomain:TMErrDomain code:TMError_PlannedOutage userInfo:@{ NSLocalizedDescriptionKey:@"Planned Outage" }];
                    } break;
                        
                    default: { // Invalid request
                        error = [NSError errorWithDomain:TMErrDomain code:TMError_InvalidRequest userInfo:@{ NSLocalizedDescriptionKey:@"Invalid request" }];
                    } break;
                }
            }  else { // received obj is not a NSHTTPURLResponse obj!
                //Web server is returning an error
                //NSLog(@"Web server is returning an error");
                error = [NSError errorWithDomain:TMErrDomain code:TMError_BadRequest userInfo:@{ NSLocalizedDescriptionKey:@"Bad request" }];
            }
        } else { // network error, e.g. no internet connection etc
            if (taskError.code == NSURLErrorCancelled) { // it was intended, so it is not "error"
                // task was canceled because a new task is to be started
                return; // we should not call any handlers in this case
            } else {
                // task failed
                //NSLog(@"error : %@", taskError.description);
                error = [NSError errorWithDomain:TMErrDomain code:TMError_Network userInfo:@{ NSLocalizedDescriptionKey:@"Network error" }];
            }
        }
        
        // Invoke completionHandler
        // We will update UI in completionHandler, so let's make sure it is run on main thread
        if (completionHandler) {
            if ( [[NSThread currentThread] isMainThread] ) {
                completionHandler(listings,error);
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(listings,error);
                });
            }
        }
    }];
    
    // Invoke inceptionHandler (on main thread)
    if (inceptionHandler) {
        if ( [[NSThread currentThread] isMainThread] ) {
            inceptionHandler(dataTask);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                inceptionHandler(dataTask);
            });
        }
    }
    
    // fire request
    [dataTask resume];
}

#pragma mark - private methods

// Parses JSON data and maps the data to foundadtion objects (encapsulated in TMListings)
+ (TMListings *) createListingsFromJSONData: (NSData *) data {
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
            
            // map dictionary info to our objects
            result = [[TMListings alloc] initListings];
            result.listingsCount = ((NSNumber *)[jsonDict objectForKey:@"TotalCount"]).integerValue;
            
            // populate listings
            NSArray *aListingsArray = [jsonDict objectForKey:@"List"];
            if (aListingsArray != nil) {
                result.list = [[NSMutableArray alloc] init];
                for (NSDictionary *dict in aListingsArray) {
                    TMListingsItem *aListingDetail = [[TMListingsItem alloc] init];
                    aListingDetail.listingId = ((NSNumber *)[dict objectForKey:@"ListingId"]).integerValue;
                    aListingDetail.title = [dict objectForKey:@"Title"];
                    aListingDetail.region = [dict objectForKey:@"Region"];
                    aListingDetail.price = [dict objectForKey:@"PriceDisplay"];
                    //aListingDetail.priceBuyNow = ((NSNumber *)[dict objectForKey:@"BuyNowPrice"]).floatValue;
                    //aListingDetail.priceMaxBid = ((NSNumber *)[dict objectForKey:@"MaxBidAmount"]).floatValue;
                    aListingDetail.thumbnailURL = [dict objectForKey:@"PictureHref"];
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
