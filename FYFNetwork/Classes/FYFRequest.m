/*
 #####################################################################
 # File    : FYFRequest.m
 # Project : Pods
 # Created : 2021/8/24 1:36 PM
 # DevTeam : fanyunfei
 # Author  : fanyunfei
 # Notes   : 网络请求所有信息管理类
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


#import "FYFRequest.h"
#import "FYFNetworkAgent.h"
#import "FYFNetworkConfig.h"

void FYFLog(NSString *format, ...) {
#ifdef DEBUG
    if (![FYFNetworkConfig sharedConfig].isDebug) {
        return;
    }
    va_list argptr;
    va_start(argptr, format);
    NSLogv(format, argptr);
    va_end(argptr);
#endif
}

@implementation FYFRequest

- (BOOL)isCancelled {
    if (!self.task) {
        return NO;
    }
    return self.task.state == NSURLSessionTaskStateCanceling;
}

- (BOOL)isExecuting {
    if (!self.task) {
        return NO;
    }
    return self.task.state == NSURLSessionTaskStateRunning;
}

#pragma mark - Request Configuration

- (void)setCompletionBlockWithSuccess:(FYFRequestSuccessBlock)success
                              failure:(FYFRequestFailureBlock)failure {
    self.successBlock = success;
    self.failureBlock = failure;
}

- (void)clearCompletionBlock {
    // nil out to break the retain cycle.
    self.successBlock = nil;
    self.failureBlock = nil;
    self.uploadProgressBlock = nil;
}

#pragma mark - Request Action

- (void)start {
    [[FYFNetworkAgent shared] addRequest:self];
}

- (void)stop {
    self.delegate = nil;
    [[FYFNetworkAgent shared] cancelRequest:self];
}

- (void)startWithSuccess:(FYFRequestSuccessBlock)success
                                    failure:(FYFRequestFailureBlock)failure {
    [self setCompletionBlockWithSuccess:success failure:failure];
    [self start];
}

#pragma mark - Default setting

- (NSDictionary<NSString *,NSString *> *)headerField {
    if (!_headerField) {
        _headerField = [FYFNetworkConfig sharedConfig].headerField;
    }
    return _headerField;
}

- (NSUInteger)requestTimeout {
    return [FYFNetworkConfig sharedConfig].requestTimeout;
}

- (AFHTTPRequestSerializer *)requestSerializer {
    if (!_requestSerializer) {
        _requestSerializer = [AFHTTPRequestSerializer serializer];
    }
    return _requestSerializer;
}

- (FYFRequestMethod)requestMethod {
    if (_requestMethod != FYFRequestMethodGET) {
        return _requestMethod;
    }
    return FYFRequestMethodGET;
}

- (FYFResponseSerializerType)responseSerializerType {
    if (_responseSerializerType != FYFResponseSerializerTypeJSON) {
        return _responseSerializerType;
    }
    return FYFResponseSerializerTypeJSON;
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p>{ URL: %@ } { method: %@ } { arguments: %@ }", NSStringFromClass([self class]), self, self.task.currentRequest.URL, self.task.currentRequest.HTTPMethod, self.parameter];
}
@end

