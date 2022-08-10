/*
 #####################################################################
 # File    : FYFRequest.h
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

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT void FYFLog(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);

///  HTTP 请求的方式
typedef NS_ENUM(NSInteger, FYFRequestMethod) {
    FYFRequestMethodGET = 0,
    FYFRequestMethodPOST,
    FYFRequestMethodHEAD,
    FYFRequestMethodPUT,
    FYFRequestMethodDELETE,
    FYFRequestMethodPATCH,
};
// 请求的解析类型
typedef NS_ENUM(NSInteger, FYFResponseSerializerType) {
    /// JSON object type
    FYFResponseSerializerTypeJSON = 0,
    /// NSData type
    FYFResponseSerializerTypeHTTP,
    /// NSXMLParser type
    FYFResponseSerializerTypeXMLParser,
};

@class FYFRequest;
@protocol FYFRequestDelegate <NSObject>
@optional
/// 网络请求成功
/// @param request 请求
/// @param responseData 成功的数据
- (void)requestFinished:(FYFRequest *)request responseData:(id)responseData;

/// 网络请求失败
/// @param request request
/// @param error 失败的原因
- (void)requestFailed:(FYFRequest *)request error:(NSError *)error;

@end

typedef void(^FYFRequestSuccessBlock)(FYFRequest *request,id responseData);
typedef void(^FYFRequestFailureBlock)(FYFRequest *request,NSError *error);
typedef void (^AFConstructingBlock)(id<AFMultipartFormData> formData);
typedef void (^AFURLSessionTaskProgressBlock)(NSProgress *);

@interface FYFRequest : NSObject
/**
    网络请求需要设置
 */
// 网络请求的域名 默认为nil
@property (nonatomic, copy) NSString *baseUrl;
// 网络请求的路径 默认为nil
@property (nonatomic, copy) NSString *path;
// 网络请求的参数 默认为nil
@property (nonatomic, strong) id parameter;
// 网络请求的类型 默认为Get请求
@property (nonatomic, assign) FYFRequestMethod requestMethod;
// 请求的代理 默认为nil 设置之后就会响应（优先block响应）
@property (nonatomic, weak, nullable) id<FYFRequestDelegate> delegate;
// 请求解析器 默认为AFHTTPRequestSerializer
@property (nonatomic, strong) AFHTTPRequestSerializer *requestSerializer;
// 请求支持的contentType
@property (nonatomic, strong) NSSet *acceptableContentTypes;
// 响应数据解析类型 默认为JSON解析方式
@property (nonatomic, assign) FYFResponseSerializerType responseSerializerType;
// 网络请求的header设置 默认config中统一设置，重新设置的话直接重新赋值即可
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *headerField;
// 请求的的tag 标识：默认为0
@property (nonatomic) NSInteger tag;
// 网络的超时时间 默认config中统一设置 默认为15秒
@property (nonatomic, assign) NSUInteger requestTimeout;
// 上传文件block 将上传文件参数规范化
@property (nonatomic, copy, nullable) AFConstructingBlock constructingBodyBlock;
// 文件下载的本地存储路径 建议直接使用FYFNetworkFileTool获取默认的路径 + 文件名.后缀（文件名保持唯一）
@property (nonatomic, strong, nullable) NSString *resumableDownloadPath;

/**
    网络请求的获取数据&状态
 */
// 返回task的是否cancel状态
@property (nonatomic, readonly, getter=isCancelled) BOOL cancelled;
// 返回task的执行状态
@property (nonatomic, readonly, getter=isExecuting) BOOL executing;
// 请求成功的回调
@property (nonatomic, copy, nullable) FYFRequestSuccessBlock successBlock;
// 请求失败的回调
@property (nonatomic, copy, nullable) FYFRequestFailureBlock failureBlock;
// 上传的进度
@property (nonatomic, copy, nullable) AFURLSessionTaskProgressBlock uploadProgressBlock;
// 下载进度
@property (nonatomic, copy, nullable) AFURLSessionTaskProgressBlock resumableDownloadProgressBlock;
// 请求的task
@property (nonatomic, strong) NSURLSessionTask *task;
// 网络请求下的数据 HTTP解析获取NSData/JSON解析获取字典/XML解析获取字典
@property (nonatomic, strong, readwrite) id responseObject;
// 错误信息
@property (nonatomic, strong, readwrite) NSError *error;

// 清除完成的block设置
- (void)clearCompletionBlock;

// 开始请求  建议使用delegate方式通过此方式开始网络请求
- (void)start;

// 取消请求
- (void)stop;

/// 开始请求
/// @param success 成功的回调
/// @param failure 失败的回调
- (void)startWithSuccess:(FYFRequestSuccessBlock)success
                 failure:(FYFRequestFailureBlock)failure;
@end


NS_ASSUME_NONNULL_END
