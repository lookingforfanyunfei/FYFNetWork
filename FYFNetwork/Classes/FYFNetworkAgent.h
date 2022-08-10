/*
 #####################################################################
 # File    : FYFNetworkAgent.h
 # Project : Pods
 # Created : 2021/8/24 1:37 PM
 # DevTeam : fanyunfei
 # Author  : fanyunfei
 # Notes   : 网络处理中心
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
#import "FYFRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface FYFNetworkAgent : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;


/// 获取网络代理对象
+ (FYFNetworkAgent *)shared;


/// 添加网络请求
/// @param request 网络请求的request
- (void)addRequest:(FYFRequest *)request;


/// 取消网络请求
/// @param request 网络请求的request
- (void)cancelRequest:(FYFRequest *)request;


/// 取消所有的网络请求
- (void)cancelAllRequests;

@end

NS_ASSUME_NONNULL_END
