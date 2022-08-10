/*
 #####################################################################
 # File    : FYFNetworkConfig.h
 # Project : Pods
 # Created : 2021/8/24 2:55 PM
 # DevTeam : fanyunfei
 # Author  : fanyunfei
 # Notes   : 网络请求统一的默认设置
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
#import <AFNetworking/AFNetworking.h>

NS_ASSUME_NONNULL_BEGIN

@interface FYFNetworkConfig : NSObject

// 默认的网络请求的策略 可以设置请求头、超时等 默认为nil
@property (nonatomic, strong, nullable) NSURLSessionConfiguration* sessionConfiguration;
// 默认的加密策略 默认 default
@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;
// 网络的超时时间 默认 15秒
@property (nonatomic, assign) NSUInteger requestTimeout;
// 网络请求的header设置 默认为nil
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *headerField;
// 是否debug 默认YES：开启 (只有在debug环境下有效)
@property (nonatomic, assign) BOOL isDebug;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

///  单例对象的获取
+ (FYFNetworkConfig *)sharedConfig;


@end

@interface FYFNetworkFileTool : NSObject

/// 获取默认的下载文件缓存路径
/// @param fileName 文件名
+ (NSString *)getDefaultCacheFilePath:(NSString *)fileName;

@end


NS_ASSUME_NONNULL_END
