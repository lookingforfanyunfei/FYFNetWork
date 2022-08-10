/*
 #####################################################################
 # File    : FYFMultipleRequest.m
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


#import "FYFMultipleRequest.h"
#import "FYFMultipleAgent.h"

@interface FYFMultipleRequest ()<FYFRequestDelegate>

@property (nonatomic) NSInteger finishedCount;

@end

@implementation FYFMultipleRequest

/// 初始化多请求管理器
/// @param requestArray 多请求数组
- (instancetype)initWithRequestArray:(NSArray<FYFRequest *> *)requestArray {
    self = [super init];
    if (self) {
        _requestArray = [requestArray copy];
        _finishedCount = 0;
        for (FYFRequest * req in _requestArray) {
            if (![req isKindOfClass:[FYFRequest class]]) {
                FYFLog(@"Error, request item must be FYFRequest instance.");
                return nil;
            }
        }
    }
    return self;
}

/// 开始请求
- (void)start {
    if (_finishedCount > 0) {
        FYFLog(@"Error! Multiple Request has already started.");
        return;
    }
    _failedRequest = nil;
    [[FYFMultipleAgent sharedAgent] addMultipleRequest:self];
    for (FYFRequest * req in _requestArray) {
        req.delegate = self;
        [req clearCompletionBlock];
        [req start];
    }
}
/// 取消请求
- (void)stop {
    _delegate = nil;
    [self clearRequest];
    [[FYFMultipleAgent sharedAgent] removeMultipleRequest:self];
}

/// 开始请求
/// @param success 成功回调
/// @param failure 失败回调
- (void)startWithSuccess:(void (^)(FYFMultipleRequest *multipleRequest))success
                                    failure:(void (^)(FYFMultipleRequest *multipleRequest))failure {
    [self setWithSuccess:success failure:failure];
    [self start];
}
/// 设置多请求的回调
/// @param success 成功回调
/// @param failure 失败回调
- (void)setWithSuccess:(void (^)(FYFMultipleRequest *multipleRequest))success
                              failure:(void (^)(FYFMultipleRequest *multipleRequest))failure {
    self.successBlock = success;
    self.failureBlock = failure;
}

/// 清空所有的回调Block
- (void)clearCompletionBlock {
    // nil out to break the retain cycle.
    self.successBlock = nil;
    self.failureBlock = nil;
}

- (void)dealloc {
    [self clearRequest];
}

#pragma mark - FYFRequestDelegate

- (void)requestFinished:(FYFRequest *)request responseData:(nonnull id)responseData {
    _finishedCount++;
    if (_finishedCount == _requestArray.count) {
        if ([_delegate respondsToSelector:@selector(multipleRequestFinished:)]) {
            [_delegate multipleRequestFinished:self];
        }
        if (_successBlock) {
            _successBlock(self);
        }
        [self clearCompletionBlock];
        [[FYFMultipleAgent sharedAgent] removeMultipleRequest:self];
    }
}

- (void)requestFailed:(FYFRequest *)request error:(nonnull NSError *)error {
    _failedRequest = request;
    // Stop
    for (FYFRequest *req in _requestArray) {
        [req stop];
    }
    // Callback
    if ([_delegate respondsToSelector:@selector(multipleRequestFailed:)]) {
        [_delegate multipleRequestFailed:self];
    }
    if (_failureBlock) {
        _failureBlock(self);
    }
    // Clear
    [self clearCompletionBlock];
    [[FYFMultipleAgent sharedAgent] removeMultipleRequest:self];
}

- (void)clearRequest {
    for (FYFRequest *req in _requestArray) {
        [req stop];
    }
    [self clearCompletionBlock];
}

@end
