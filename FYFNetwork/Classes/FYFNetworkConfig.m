/*
 #####################################################################
 # File    : FYFNetworkConfig.m
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


#import "FYFNetworkConfig.h"

@implementation FYFNetworkConfig

+ (FYFNetworkConfig *)sharedConfig {
   static FYFNetworkConfig *sharedInstance = nil;
   static dispatch_once_t onceToken;
   dispatch_once(&onceToken, ^{
       sharedInstance = [[self alloc] init];
   });
   return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _securityPolicy = [AFSecurityPolicy defaultPolicy];
        _headerField = nil;
        _requestTimeout = 15;
        _isDebug = YES;
    }
    return self;
}
@end


@implementation FYFNetworkFileTool

+ (NSString *)getDefaultCacheFilePath:(NSString *)fileName {
    NSString *libPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *cachePath = [libPath stringByAppendingPathComponent:@"Caches"];
    NSString *filePath = [cachePath stringByAppendingPathComponent:fileName];
    return filePath;
}

@end
