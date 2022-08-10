/*
 #####################################################################
 # File    : FYFMultipleRequest.h
 # Project : Pods
 # Created : 2021/8/25 2:33 PM
 # DevTeam : fanyunfei
 # Author  : fanyunfei
 # Notes   : 多请求管理器
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

@class FYFMultipleRequest;
@protocol FYFMultipleRequestDelegate <NSObject>
@optional

/// 所有请求都成功的回调
/// @param multipleRequest 多请求管理器
- (void)multipleRequestFinished:(FYFMultipleRequest *)multipleRequest;

/// 有请求失败，并非所有请求都成功回调
/// @param multipleRequest 多请求管理器
- (void)multipleRequestFailed:(FYFMultipleRequest *)multipleRequest;

@end

@interface FYFMultipleRequest : NSObject

/// 请求的管理数组
@property (nonatomic, strong, readonly) NSArray<FYFRequest *> *requestArray;
/// 多请求的代理
@property (nonatomic, weak, nullable) id<FYFMultipleRequestDelegate> delegate;
/// 多请求完成所有请求的回调
@property (nonatomic, copy, nullable) void (^successBlock)(FYFMultipleRequest *);
/// 多请求并非完成所有请求的回调
@property (nonatomic, copy, nullable) void (^failureBlock)(FYFMultipleRequest *);
/// 第一个失败的请求
@property (nonatomic, strong, readonly, nullable) FYFRequest *failedRequest;



/// 初始化多请求管理器
/// @param requestArray 多请求数组
- (instancetype)initWithRequestArray:(NSArray<FYFRequest *> *)requestArray;

/// 设置多请求的回调
/// @param success 成功回调
/// @param failure 失败回调
- (void)setWithSuccess:(nullable void (^)(FYFMultipleRequest *multipleRequest))success
                              failure:(nullable void (^)(FYFMultipleRequest *multipleRequest))failure;

/// 清空所有的回调Block
- (void)clearCompletionBlock;


/// 开始请求
- (void)start;


/// 取消请求
- (void)stop;


/// 开始请求
/// @param success 成功回调
/// @param failure 失败回调
- (void)startWithSuccess:(nullable void (^)(FYFMultipleRequest *multipleRequest))success failure:(nullable void (^)(FYFMultipleRequest *multipleRequest))failure;

@end

NS_ASSUME_NONNULL_END
