/*
 #####################################################################
 # File    : FYFNetworkAgent.m
 # Project : Pods
 # Created : 2021/8/24 1:37 PM
 # DevTeam : fanyunfei
 # Author  : fanyunfei
 # Notes   :  网络处理中心
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


#import "FYFNetworkAgent.h"
#import "FYFNetworkConfig.h"
#import <pthread/pthread.h>
#import <CommonCrypto/CommonDigest.h>
#if __has_include(<AFNetworking/AFHTTPSessionManager.h>)
#import <AFNetworking/AFHTTPSessionManager.h>
#else
#import <AFNetworking/AFHTTPSessionManager.h>
#endif

#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)


@implementation FYFNetworkAgent {
    AFHTTPSessionManager *_manager;
    FYFNetworkConfig *_config;
    AFJSONResponseSerializer *_jsonResponseSerializer;
    AFXMLParserResponseSerializer *_xmlParserResponseSerialzier;
    NSMutableDictionary<NSNumber *, FYFRequest *> *_requestsRecord;
    dispatch_queue_t _processingQueue;
    pthread_mutex_t _lock;
    
}

+ (FYFNetworkAgent *)shared {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _config = [FYFNetworkConfig sharedConfig];
        _manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:_config.sessionConfiguration];
        _requestsRecord = [NSMutableDictionary dictionary];
        _processingQueue = dispatch_queue_create("com.fanyunfei.networkagent.processing", DISPATCH_QUEUE_CONCURRENT);
        pthread_mutex_init(&_lock, NULL);

        _manager.securityPolicy = _config.securityPolicy;
        _manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        _manager.completionQueue = _processingQueue;
    }
    return self;
}

- (AFJSONResponseSerializer *)jsonResponseSerializer {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _jsonResponseSerializer = [AFJSONResponseSerializer serializer];
    });
    return _jsonResponseSerializer;
}

- (AFXMLParserResponseSerializer *)xmlParserResponseSerialzier {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _xmlParserResponseSerialzier = [AFXMLParserResponseSerializer serializer];
    });
    return _xmlParserResponseSerialzier;
}

- (AFHTTPRequestSerializer *)requestSerializerForRequest:(FYFRequest *)request {
    AFHTTPRequestSerializer *requestSerializer = request.requestSerializer;
    if (request.requestSerializer == nil) {
        requestSerializer = [AFHTTPRequestSerializer serializer];
    }
    requestSerializer.timeoutInterval = request.requestTimeout;
    // If api needs to add custom value to HTTPHeaderField
    NSDictionary<NSString *, NSString *> *headerFieldValueDictionary = request.headerField;
    if (headerFieldValueDictionary != nil) {
        for (NSString *httpHeaderField in headerFieldValueDictionary.allKeys) {
            NSString *value = headerFieldValueDictionary[httpHeaderField];
            [requestSerializer setValue:value forHTTPHeaderField:httpHeaderField];
        }
    }
    return requestSerializer;
}

- (NSURLSessionTask *)sessionTaskForRequest:(FYFRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    FYFRequestMethod method = [request requestMethod];
    NSString *url = [request.baseUrl stringByAppendingPathComponent:request.path];
    id param = request.parameter;
    AFConstructingBlock constructingBlock = [request constructingBodyBlock];
    AFURLSessionTaskProgressBlock uploadProgressBlock = [request uploadProgressBlock];
    AFHTTPRequestSerializer *requestSerializer = [self requestSerializerForRequest:request];

    switch (method) {
        case FYFRequestMethodGET:
            if (request.resumableDownloadPath) {
                return [self downloadTaskWithDownloadPath:request.resumableDownloadPath
                                        requestSerializer:requestSerializer
                                                URLString:url
                                               parameters:param
                                                 progress:request.resumableDownloadProgressBlock
                                                    error:error];
            } else {
                return [self dataTaskWithHTTPMethod:@"GET"
                                  requestSerializer:requestSerializer
                                          URLString:url
                                         parameters:param
                                              error:error];
            }
        case FYFRequestMethodPOST:
            return [self dataTaskWithHTTPMethod:@"POST"
                              requestSerializer:requestSerializer
                                      URLString:url
                                     parameters:param
                                 uploadProgress:uploadProgressBlock
                      constructingBodyWithBlock:constructingBlock
                                          error:error];
        case FYFRequestMethodHEAD:
            return [self dataTaskWithHTTPMethod:@"HEAD"
                              requestSerializer:requestSerializer
                                      URLString:url
                                     parameters:param
                                          error:error];
        case FYFRequestMethodPUT:
            return [self dataTaskWithHTTPMethod:@"PUT"
                              requestSerializer:requestSerializer
                                      URLString:url
                                     parameters:param
                                 uploadProgress:uploadProgressBlock
                      constructingBodyWithBlock:constructingBlock
                                          error:error];
        case FYFRequestMethodDELETE:
            return [self dataTaskWithHTTPMethod:@"DELETE"
                              requestSerializer:requestSerializer
                                      URLString:url
                                     parameters:param
                                          error:error];
        case FYFRequestMethodPATCH:
            return [self dataTaskWithHTTPMethod:@"PATCH"
                              requestSerializer:requestSerializer
                                      URLString:url
                                     parameters:param
                                          error:error];
    }
}

- (void)addRequest:(FYFRequest *)request {
    NSParameterAssert(request != nil);

    NSError * __autoreleasing requestSerializationError = nil;
    request.task = [self sessionTaskForRequest:request error:&requestSerializationError];

    if (requestSerializationError) {
        [self requestDidFailWithRequest:request error:requestSerializationError];
        return;
    }

    NSAssert(request.task != nil, @"requestTask should not be nil");
    // Retain request
    FYFLog(@"Add request: %@", NSStringFromClass([request class]));
    [self addRequestToRecord:request];
    [request.task resume];
}

- (void)cancelRequest:(FYFRequest *)request {
    NSParameterAssert(request != nil);
    if (request.resumableDownloadPath && [self incompleteDownloadTempPathForDownloadPath:request.resumableDownloadPath] != nil) {
        NSURLSessionDownloadTask *requestTask = (NSURLSessionDownloadTask *)request.task;
        [requestTask cancelByProducingResumeData:^(NSData *resumeData) {
            NSURL *localUrl = [self incompleteDownloadTempPathForDownloadPath:request.resumableDownloadPath];
            [resumeData writeToURL:localUrl atomically:YES];
        }];
    } else {
        [request.task cancel];
    }
    [self removeRequestFromRecord:request];
    [request clearCompletionBlock];
}

- (void)cancelAllRequests {
    Lock();
    NSArray *allKeys = [_requestsRecord allKeys];
    Unlock();
    if (allKeys && allKeys.count > 0) {
        NSArray *copiedKeys = [allKeys copy];
        for (NSNumber *key in copiedKeys) {
            Lock();
            FYFRequest *request = _requestsRecord[key];
            Unlock();
            // We are using non-recursive lock.
            // Do not lock `stop`, otherwise deadlock may occur.
            [request stop];
        }
    }
}

- (void)handleRequestResult:(NSURLSessionTask *)task responseObject:(id)responseObject error:(NSError *)error {
    Lock();
    FYFRequest *request = _requestsRecord[@(task.taskIdentifier)];
    Unlock();

    // When the request is cancelled and removed from records, the underlying
    // AFNetworking failure callback will still kicks in, resulting in a nil `request`.
    //
    // Here we choose to completely ignore cancelled tasks. Neither success or failure
    // callback will be called.
    if (!request) {
        return;
    }
    NSError * __autoreleasing serializationError = nil;

    NSError *requestError = nil;
    BOOL succeed = NO;

    request.responseObject = responseObject;
    if ([request.responseObject isKindOfClass:[NSData class]]) {
        request.responseObject = responseObject;
        switch (request.responseSerializerType) {
            case FYFResponseSerializerTypeHTTP:
                // Default serializer. Do nothing.
                break;
            case FYFResponseSerializerTypeJSON:
                if (request.acceptableContentTypes.count > 0) {
                    self.jsonResponseSerializer.acceptableContentTypes = request.acceptableContentTypes;
                }
                request.responseObject = [self.jsonResponseSerializer responseObjectForResponse:task.response data:request.responseObject error:&serializationError];
                request.responseObject = request.responseObject;
                break;
            case FYFResponseSerializerTypeXMLParser:
                if (request.acceptableContentTypes.count > 0) {
                    self.xmlParserResponseSerialzier.acceptableContentTypes = request.acceptableContentTypes;
                }
                request.responseObject = [self.xmlParserResponseSerialzier responseObjectForResponse:task.response data:request.responseObject error:&serializationError];
                break;
        }
    }
    if (error) {
        succeed = NO;
        requestError = error;
    } else if (serializationError) {
        succeed = NO;
        requestError = serializationError;
    }else{
        succeed = YES;
    }
    FYFLog(@"*****************************************************");
    FYFLog(@"request URL = %@ \n param = %@\n response data = %@",task.response.URL.absoluteString,request.parameter,request.responseObject);
    FYFLog(@"*****************************************************");
    if (succeed) {
        [self requestDidSucceedWithRequest:request];
    } else {
        [self requestDidFailWithRequest:request error:requestError];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeRequestFromRecord:request];
        [request clearCompletionBlock];
    });
}

- (void)requestDidSucceedWithRequest:(FYFRequest *)request {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (request.delegate != nil && [request.delegate respondsToSelector:@selector(requestFinished:responseData:)]) {
            [request.delegate requestFinished:request responseData:request.responseObject];
        }
        if (request.successBlock) {
            request.successBlock(request, request.responseObject);
        }
    });
}

- (void)requestDidFailWithRequest:(FYFRequest *)request error:(NSError *)error {
    request.error = error;
    // Save incomplete download data.
    NSData *incompleteDownloadData = error.userInfo[NSURLSessionDownloadTaskResumeData];
    NSURL *localUrl = nil;
    if (request.resumableDownloadPath) {
        localUrl = [self incompleteDownloadTempPathForDownloadPath:request.resumableDownloadPath];
    }
    if (incompleteDownloadData && localUrl != nil) {
        [incompleteDownloadData writeToURL:localUrl atomically:YES];
    }
    // Load response from file and clean up if download task failed.
    if ([request.responseObject isKindOfClass:[NSURL class]]) {
        NSURL *url = request.responseObject;
        if (url.isFileURL && [[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
            request.responseObject = [NSData dataWithContentsOfURL:url];
            [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
        }
        request.responseObject = nil;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (request.delegate != nil && [request.delegate respondsToSelector:@selector(requestFailed:error:)]) {
            [request.delegate requestFailed:request error:request.error];
        }
        if (request.failureBlock) {
            request.failureBlock(request, request.error);
        }
    });
}

- (void)addRequestToRecord:(FYFRequest *)request {
    Lock();
    _requestsRecord[@(request.task.taskIdentifier)] = request;
    Unlock();
}

- (void)removeRequestFromRecord:(FYFRequest *)request {
    Lock();
    [_requestsRecord removeObjectForKey:@(request.task.taskIdentifier)];
    Unlock();
}

#pragma mark -

- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                               requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                           error:(NSError * _Nullable __autoreleasing *)error {
    return [self dataTaskWithHTTPMethod:method
                      requestSerializer:requestSerializer
                              URLString:URLString
                             parameters:parameters
                         uploadProgress:nil
              constructingBodyWithBlock:nil
                                  error:error];
}

- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                               requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                  uploadProgress:(AFURLSessionTaskProgressBlock)uploadProgress
                       constructingBodyWithBlock:(nullable void (^)(id <AFMultipartFormData> formData))block
                                           error:(NSError * _Nullable __autoreleasing *)error {
    NSMutableURLRequest *request = nil;

    if (block) {
        request = [requestSerializer multipartFormRequestWithMethod:method URLString:URLString parameters:parameters constructingBodyWithBlock:block error:error];
    } else {
        request = [requestSerializer requestWithMethod:method URLString:URLString parameters:parameters error:error];
    }

    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [_manager dataTaskWithRequest:request
                              uploadProgress:uploadProgress
                            downloadProgress:nil
                           completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *_error) {
                               [self handleRequestResult:dataTask responseObject:responseObject error:_error];
                           }];

    return dataTask;
}

- (NSURLSessionDownloadTask *)downloadTaskWithDownloadPath:(NSString *)downloadPath
                                         requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                                 URLString:(NSString *)URLString
                                                parameters:(id)parameters
                                                  progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgressBlock
                                                     error:(NSError * _Nullable __autoreleasing *)error {
    // add parameters to URL;
    NSMutableURLRequest *urlRequest = [requestSerializer requestWithMethod:@"GET" URLString:URLString parameters:parameters error:error];

    NSString *downloadTargetPath;
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:downloadPath isDirectory:&isDirectory]) {
        isDirectory = NO;
    }
    // If targetPath is a directory, use the file name we got from the urlRequest.
    // Make sure downloadTargetPath is always a file, not directory.
    if (isDirectory) {
        NSString *fileName = [urlRequest.URL lastPathComponent];
        downloadTargetPath = [NSString pathWithComponents:@[downloadPath, fileName]];
    } else {
        downloadTargetPath = downloadPath;
    }

    // AFN use `moveItemAtURL` to move downloaded file to target path,
    // this method aborts the move attempt if a file already exist at the path.
    // So we remove the exist file before we start the download task.
    // https://github.com/AFNetworking/AFNetworking/issues/3775
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadTargetPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:downloadTargetPath error:nil];
    }

    BOOL resumeSucceeded = NO;
    __block NSURLSessionDownloadTask *downloadTask = nil;
    NSURL *localUrl = [self incompleteDownloadTempPathForDownloadPath:downloadPath];
    if (localUrl != nil) {
        BOOL resumeDataFileExists = [[NSFileManager defaultManager] fileExistsAtPath:localUrl.path];
        NSData *data = [NSData dataWithContentsOfURL:localUrl];
        BOOL resumeDataIsValid = [self validateResumeData:data];

        BOOL canBeResumed = resumeDataFileExists && resumeDataIsValid;
        // Try to resume with resumeData.
        // Even though we try to validate the resumeData, this may still fail and raise excecption.
        if (canBeResumed) {
            @try {
                downloadTask = [_manager downloadTaskWithResumeData:data progress:downloadProgressBlock destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                    return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];
                } completionHandler:
                                ^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                                    [self handleRequestResult:downloadTask responseObject:filePath error:error];
                                }];
                resumeSucceeded = YES;
            } @catch (NSException *exception) {
                FYFLog(@"Resume download failed, reason = %@", exception.reason);
                resumeSucceeded = NO;
            }
        }
    }
    if (!resumeSucceeded) {
        downloadTask = [_manager downloadTaskWithRequest:urlRequest progress:downloadProgressBlock destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];
        } completionHandler:
                        ^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                            [self handleRequestResult:downloadTask responseObject:filePath error:error];
                        }];
    }
    return downloadTask;
}

#pragma mark - Resumable Download

- (NSString *)incompleteDownloadTempCacheFolder {
    NSFileManager *fileManager = [NSFileManager new];
    NSString *cacheFolder = [NSTemporaryDirectory() stringByAppendingPathComponent:@"ks_file_temp"];

    BOOL isDirectory = NO;
    if ([fileManager fileExistsAtPath:cacheFolder isDirectory:&isDirectory] && isDirectory) {
        return cacheFolder;
    }
    NSError *error = nil;
    if ([fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:&error] && error == nil) {
        return cacheFolder;
    }
    FYFLog(@"Failed to create cache directory at %@ with error: %@", cacheFolder, error != nil ? error.localizedDescription : @"unkown");
    return nil;
}

- (NSURL *)incompleteDownloadTempPathForDownloadPath:(NSString *)downloadPath {
    if (downloadPath == nil || downloadPath.length == 0) {
        return nil;
    }
    NSString *tempPath = nil;
    NSString *md5URLString = [self md5StringFromString:downloadPath];
    tempPath = [[self incompleteDownloadTempCacheFolder] stringByAppendingPathComponent:md5URLString];
    return tempPath == nil ? nil : [NSURL fileURLWithPath:tempPath];
}

- (NSString *)md5StringFromString:(NSString *)string {
    NSParameterAssert(string != nil && [string length] > 0);

    const char *value = [string UTF8String];

    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, (CC_LONG)strlen(value), outputBuffer);

    NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++){
        [outputString appendFormat:@"%02x", outputBuffer[count]];
    }

    return outputString;
}
- (BOOL)validateResumeData:(NSData *)data {
    // From http://stackoverflow.com/a/22137510/3562486
    if (!data || [data length] < 1) return NO;

    NSError *error;
    NSDictionary *resumeDictionary = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:&error];
    if (!resumeDictionary || error) return NO;

    // Before iOS 9 & Mac OS X 10.11
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED < 90000)\
|| (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED < 101100)
    NSString *localFilePath = [resumeDictionary objectForKey:@"NSURLSessionResumeInfoLocalPath"];
    if ([localFilePath length] < 1) return NO;
    return [[NSFileManager defaultManager] fileExistsAtPath:localFilePath];
#endif
    // After iOS 9 we can not actually detects if the cache file exists. This plist file has a somehow
    // complicated structure. Besides, the plist structure is different between iOS 9 and iOS 10.
    // We can only assume that the plist being successfully parsed means the resume data is valid.
    return YES;
}

#pragma mark - Testing

- (AFHTTPSessionManager *)manager {
    return _manager;
}

- (void)resetURLSessionManager {
    _manager = [AFHTTPSessionManager manager];
}

- (void)resetURLSessionManagerWithConfiguration:(NSURLSessionConfiguration *)configuration {
    _manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
}

@end
