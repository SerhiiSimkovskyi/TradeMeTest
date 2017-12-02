//
//  TMListingDetails.m
//  TradeMeTest
//
//  Created by Serhii Simkovskyi on Dec/2/17.
//  Copyright © 2017 Serhii Simkovskyi. All rights reserved.
//

#import "TMListingDetails.h"
#import "TMErrors.h"

#pragma mark - Private interface to TMListingDetails

@interface TMListingDetails()
- (nullable instancetype) initListingDetails; // "hidden" init
@end

#pragma mark -

@implementation TMListingDetails

- (instancetype) initListingDetails {
    // just call default init here, as it is hidden from a user of a class (class is not inteneded to be created outside of factory methods)
    return [super init];
}

#pragma mark - Factory methods

// Retrieves listing details from server and creates instance of TMListingDetails if successful (it is passed to completion handler)
+ (void) listingDetailsById: (NSInteger) listingId
            completionHandler: (void (^)(TMListingDetails *listingDetails, NSError *error)) completionHandler {
    
    // --------------------------------------------------------------
    // REST API DESCR:
    // http://developer.trademe.co.nz/api-reference/listing-methods/retrieve-the-details-of-a-single-listing/
    // --------------------------------------------------------------
    
    // Build URL to retrieve listing details from server:
    NSString *urlStr = [NSString stringWithFormat:@"https://api.tmsandbox.co.nz/v1/Listings/%ld.json", listingId];
    
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
        TMListingDetails *listingDetails = nil; // will be passed to completionHandler
        NSError *error = nil; // will be passed to completionHandler
        
        if (!taskError) {
            // Success
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                switch (((NSHTTPURLResponse*)response).statusCode) { // response:
                    case 200: {
                        // Success: HTTP 200 OK
                        listingDetails = [TMListingDetails createListingDetailsFromJSONData:data];
                        if (listingDetails == nil) {
                            error = [NSError errorWithDomain:TMErrDomain code:TMError_InvalidDataFormat userInfo:@{ NSLocalizedDescriptionKey:@"Invalid data format" }];
                        }
                    } break;
                        
                    case 401: { // Authentication failure
                        error = [NSError errorWithDomain:TMErrDomain code:TMError_AuthenticationFailure userInfo:@{ NSLocalizedDescriptionKey:@"Authentication failure" }];
                    } break;
                        
                    case 429: { // Rate limits are exceede
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
            }  else { // received not a NSHTTPURLResponse obj!
                //Web server is returning an error
                //NSLog(@"Web server is returning an error");
                error = [NSError errorWithDomain:TMErrDomain code:TMError_BadRequest userInfo:@{ NSLocalizedDescriptionKey:@"Bad request" }];
            }
        } else { // network error, e.g. no internet connection etc
            if (taskError.code == NSURLErrorCancelled) { // it was intended, so it is not "error"
                // task was canceled because a new task is to be started
                return; // we should not call any handlers in this case
            } else {
                // Fail
                //NSLog(@"error : %@", taskError.description);
                error = [NSError errorWithDomain:TMErrDomain code:TMError_Network userInfo:@{ NSLocalizedDescriptionKey:@"Network error" }];
            }
        }
        
        // Invoke completionHandler
        // We will update UI in completionHandler, so let's make sure it is run on main thread

        if (completionHandler) {
            if ( [[NSThread currentThread] isMainThread] ) {
                completionHandler(listingDetails,error);
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(listingDetails,error);
                });
            }
        }
    }];
    
    // fire request
    [dataTask resume];
}

#pragma mark - private methods

// Parses JSON data and maps the data to foundadtion objects (encapsulated in TMListingDetails)
+ (TMListingDetails *) createListingDetailsFromJSONData: (NSData *) data {
    TMListingDetails *result = nil;
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
            
            result = [[TMListingDetails alloc] initListingDetails];
            
            // do not parse any data here, just retain whole dictionary
            // we are going to display it as is in UI (just for test)
            result.details = jsonDict;
            
        } else {
            // Error -> data received from server do not match to our expectations
            // jsonResponse is NSArray, that's not what we expect!
            NSLog(@"Error loading categories: jsonResponse is expected to be NSDictionary");
        }
    }
    return result;
}

@end
