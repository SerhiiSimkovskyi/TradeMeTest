//
//  TMErrors.h
//  TradeMeTest
//
//  Created by Serhii Simkovskyi on Dec/1/17.
//  Copyright © 2017 Serhii Simkovskyi. All rights reserved.
//

#ifndef TMErrors_h
#define TMErrors_h

typedef NS_ENUM(NSInteger, TMError)
{
    TMError_Network = 1,
    TMError_BadRequest,
    TMError_InvalidDataFormat,
    TMError_AuthenticationFailure,
    TMError_RateLimits,
    TMError_PlannedOutage,
    TMError_UnplannedOutage,
    TMError_InvalidRequest
};

#define TMErrDomain @"TM"

#endif /* TMErrors_h */
