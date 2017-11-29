//
//  TMCategory.m
//  TradeMeTest
//
//  Created by Serhii Simkovskyi on Nov/29/17.
//  Copyright © 2017 Serhii Simkovskyi. All rights reserved.
//

#import "TMCategory.h"

#pragma mark - Private interface to TMCategory

@interface TMCategory()
- (nullable instancetype) initCategory;
@end

#pragma mark -

@implementation TMCategory

- (nullable instancetype) initCategory {
    return [super init];
}

#pragma mark - Factory methods

+ (void) categoryById: (int) categoryId completionHandler: (void (^)(TMCategory *category, NSError *error)) completionHandler {
    // --------------------------------------------------------------
    // REST API DESCR:
    // https://developer.trademe.co.nz/api-reference/catalogue-methods/retrieve-general-categories/
    // --------------------------------------------------------------
    
    // Build URL to retrieve categories from server
    NSURL *url = [NSURL URLWithString:@"https://api.tmsandbox.co.nz/v1/Categories/0000.json?depth=1&region=1&with_counts=false"];
    
    // retrieve the contents of the specified URL
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *taskError) {
        // completion:
        TMCategory *category = nil; // will be passed to completionHandler
        NSError *error = nil; // will be passed to completionHandler
        
        if (!taskError) {
            // Success
            if ([response isKindOfClass:[NSHTTPURLResponse class]] && ((NSHTTPURLResponse*)response).statusCode == 200) {
                // response: HTTP 200 OK
                category = [TMCategory _createCategoryFromJSONData:data];
                if (category == nil) {
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
                completionHandler(category,error);
            } else {
                // We will update UI in completionHandler, so let's make sure it is run on  main thread
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(category,error);
                });
            }
        }
    }];
    
    // fire request
    [dataTask resume];
}

#pragma mark - private methods

+ (TMCategory *) _createCategoryFromJSONData: (NSData *) data {
    TMCategory *result = nil;
    
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
            
            result = [[TMCategory alloc] initCategory];
            result.name = [jsonDict objectForKey:@"Name"];
            result.path = [jsonDict objectForKey:@"Path"];
            result.number = [jsonDict objectForKey:@"Number"];
            
            // populate subcategories (we only need 1 level)
            NSArray *subcategories =[jsonDict objectForKey:@"Subcategories"];
            if (subcategories != nil) {
                result.subcategories = [[NSMutableArray alloc] init];
                for (NSDictionary *dict in subcategories) {
                    TMCategory *subcategory = [[TMCategory alloc] initCategory];
                    subcategory.name = [dict objectForKey:@"Name"];
                    subcategory.path = [dict objectForKey:@"Path"];
                    subcategory.number = [dict objectForKey:@"Number"];
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
