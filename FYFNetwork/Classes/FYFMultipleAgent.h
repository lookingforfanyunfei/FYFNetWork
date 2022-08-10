/*
 #####################################################################
 # File    : FYFMultipleAgent.h
 # Project : Pods
 # Created : 2021/8/25 3:23 PM
 # DevTeam : fanyunfei
 # Author  : fanyunfei
 # Notes   : 多请求的管理类
 #####################################################################
 ### Change Logs   ###################################################
 #####################################################################
 ---------------------------------------------------------------------
 # Date  :
 # Author:
 # Notes :
 #
 #####################################################################
 */


#import <Foundation/Foundation.h>
#import "FYFMultipleRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface FYFMultipleAgent : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

///  Get the shared batch request agent.
+ (FYFMultipleAgent *)sharedAgent;

///  Add a batch request.
- (void)addMultipleRequest:(FYFMultipleRequest *)request;

///  Remove a previously added batch request.
- (void)removeMultipleRequest:(FYFMultipleRequest *)request;
@end

NS_ASSUME_NONNULL_END
