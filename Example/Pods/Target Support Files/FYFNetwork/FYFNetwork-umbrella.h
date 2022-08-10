#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "FYFMultipleAgent.h"
#import "FYFMultipleRequest.h"
#import "FYFNetwork.h"
#import "FYFNetworkAgent.h"
#import "FYFNetworkConfig.h"
#import "FYFRequest.h"

FOUNDATION_EXPORT double FYFNetworkVersionNumber;
FOUNDATION_EXPORT const unsigned char FYFNetworkVersionString[];

