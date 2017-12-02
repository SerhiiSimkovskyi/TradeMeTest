//
//  TMCategory.m
//  TradeMeTest
//
//  Created by Serhii Simkovskyi on Nov/29/17.
//  Copyright © 2017 Serhii Simkovskyi. All rights reserved.
//

#import "TMCategory.h"
#import "TMErrors.h"

#pragma mark - Private interface to TMCategory

@interface TMCategory()
- (nullable instancetype) initCategory; // "hidden" init method
@end

#pragma mark -

@implementation TMCategory

- (instancetype) initCategory {
    // just call default init here which is hidden from a user of a class (class is not inteneded to be created outside of factory methods)
    return [super init];
}

#pragma mark - Factory methods

// Retrieves categories from server and creates instance of TMCategory if successful (it is passed to completion handler)
+ (void) categoryById: (NSString *) categoryId
     inceptionHandler:(void (^)(NSURLSessionDataTask *task))inceptionHandler
    completionHandler: (void (^)(TMCategory *category, NSError *error)) completionHandler {
    
    // --------------------------------------------------------------
    // REST API DESCR:
    // https://developer.trademe.co.nz/api-reference/catalogue-methods/retrieve-general-categories/
    // --------------------------------------------------------------
    
    // Build URL to retrieve categories from server
    NSString *urlStr = [NSString stringWithFormat:@"https://api.tmsandbox.co.nz/v1/Categories/%@.json?depth=1&region=100&with_counts=true", categoryId];
    NSURL *url = [NSURL URLWithString:urlStr];
    
    // retrieve the contents of the specified URL
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *taskError) {
        // completion:
        TMCategory *category = nil; // will be passed to completionHandler
        NSError *error = nil; // will be passed to completionHandler
        
        if (!taskError) {
            // Success
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                switch (((NSHTTPURLResponse*)response).statusCode) { // response:
                    case 200: {
                        // Success: HTTP 200 OK
                        // create and init TMCategory object
                        category = [TMCategory createCategoryFromJSONData:data];
                        if (category == nil) {
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
                //NSLog(@"Web server is returning an error");
                error = [NSError errorWithDomain:TMErrDomain code:TMError_BadRequest userInfo:@{ NSLocalizedDescriptionKey:@"Bad request" }];
            }
        } else { // network error, e.g. no internet connection etc
            if (taskError.code == NSURLErrorCancelled) { // it was intended, so it is not "error"
                // task was canceled because a new task is to be started
                return; // we should not call any handlers in this case
            } else {
                // Task failed
                //NSLog(@"error : %@", taskError.description);
                error = [NSError errorWithDomain:TMErrDomain code:TMError_Network userInfo:@{ NSLocalizedDescriptionKey:@"Network error" }];
            }
        }
        
        // Invoke completionHandler
        // We will update UI in completionHandler, so let's make sure it is run on main thread
        if (completionHandler) {
            if ( [[NSThread currentThread] isMainThread] ) {
                completionHandler(category,error);
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(category,error);
                });
            }
        }
    }];
    
    // Invoke inceptionHandler (on main thread)
    // with inceptionHandler we pass dataTask to UI, so it is possible to cancel the task when starting new one
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

// creates Root category with (subcategories == nil), we use it in our Category Browser
+ (TMCategory *) rootCategoryWithNoSubcategories {
    TMCategory *category = [[TMCategory alloc] initCategory];
    category.name = @"Root";
    category.categoryId = @"0000";
    category.path = @"Root category";
    category.listingsCount = 0;
    return category;
}


#pragma mark -

// Makes a carbon copy of itself but discards all subcategories
// (To make browsing categories more efficient we need to keep hierarchy of categories, but their subcategories will add overhead)
- (TMCategory *) copyWithNoSubcategories {
    TMCategory *category = [[TMCategory alloc] initCategory];
    category.name = [self.name copy];
    category.categoryId = [self.categoryId copy];
    category.path = [self.path copy];
    category.listingsCount = self.listingsCount;
    return category;
}

#pragma mark - private methods

// Parses JSON data and maps the data to foundadtion objects (encapsulated in TMCategory)
+ (TMCategory *) createCategoryFromJSONData: (NSData *) data {
    TMCategory *result = nil;
    NSError *jsonError;
    
    // Get a foundation object from given JSON data (can be NSDictionary or NSArray)
    id jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    
    if (jsonError) {
        // Error parsing JSON
        NSLog(@"Error parsing JSON: %@", [jsonError description]);
    } else {
        // Success Parsing JSON
        if ([jsonResponse isKindOfClass:[NSDictionary class]]) {
            NSDictionary *jsonDict = (NSDictionary *)jsonResponse; // downcast jsonResponse to NSDictionary
            
            // map dictionary info to our objects
            result = [[TMCategory alloc] initCategory];
            result.name = [jsonDict objectForKey:@"Name"];
            result.path = [jsonDict objectForKey:@"Path"];
            result.listingsCount = ((NSNumber *)[jsonDict objectForKey:@"Count"]).integerValue;
            
            // Calc categoryId: category number can be either @"0276" or @"0001-0276-" etc
            // bring it @"XXXX" form
            NSString *number= [jsonDict objectForKey:@"Number"];
            if (number && number.length > 0) {
                if ([number hasSuffix:@"-"]) {
                    number = [number substringToIndex:number.length-1];
                }
                result.categoryId = [[number componentsSeparatedByString:@"-"] lastObject];
            } else {
                result.categoryId = @"0000"; // Root
            }
            
            // populate subcategories (we only need (and have) 1 level)
            NSArray *subcategories =[jsonDict objectForKey:@"Subcategories"];
            if (subcategories != nil) {
                result.subcategories = [[NSMutableArray alloc] init];
                for (NSDictionary *dict in subcategories) {
                    TMCategory *subcategory = [[TMCategory alloc] initCategory];
                    subcategory.name = [dict objectForKey:@"Name"];
                    subcategory.path = [dict objectForKey:@"Path"];
                    subcategory.listingsCount = ((NSNumber *)[dict objectForKey:@"Count"]).integerValue;

                    // Calc categoryId: category number can be either @"0276" or @"0001-0276-" etc
                    // bring it @"XXXX" form
                    NSString *number= [dict objectForKey:@"Number"];
                    if ([number hasSuffix:@"-"]) {
                        number = [number substringToIndex:number.length-1];
                    }
                    subcategory.categoryId = [[number componentsSeparatedByString:@"-"] lastObject];

                    // add the subcategory to result object
                    [(NSMutableArray *)result.subcategories addObject:subcategory];
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
