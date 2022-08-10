//
//  FYFViewController.m
//  FYFNetwork
//
//  Created by 786452470@qq.com on 08/10/2022.
//  Copyright (c) 2022 786452470@qq.com. All rights reserved.
//

#import "FYFViewController.h"

#import <FYFNetwork/FYFNetwork.h>

@interface FYFViewController ()<FYFRequestDelegate>

@end

@implementation FYFViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
//    [self getUserInfoWithId:@"1" successed:^(FYFRequest * _Nonnull request, id  _Nonnull responseData) {
//        NSLog(@"%@",responseData);
//    } failed:^(FYFRequest * _Nonnull request, NSError * _Nonnull error) {
//        NSLog(@"%@",error);
//    }];
    
//    [[self getUserInfoWithId:@"1"] start];
    
//    [self loadImageWithPath:@"" progress:^(NSProgress * _Nonnull progress) {
//        NSLog(@"progress = %lld",progress.completedUnitCount);
//    } successed:^(FYFRequest * _Nonnull request, id  _Nonnull responseData) {
//        NSLog(@"%@",responseData);
//    } failed:^(FYFRequest * _Nonnull request, NSError * _Nonnull error) {
//        NSLog(@"%@",error);
//    }];
    
    
    
//  1、test GET 成功的情况
    [[self getBannerInfo] start];
//    2、失败的情况测试
    [[self getUserInfoWithId:@"1"] start];
//    3、测试post
    [[self postAddUser:@"niko" password:@"abcd1234"] start];
//    4、多请求
//    [self multipleRequest];
    
}


- (FYFRequest *)getUserInfoWithId:(NSString *)userId  {
    FYFRequest *request = [[FYFRequest alloc] init];
    request.baseUrl = @"http://www.yuantiku.com";
    request.path = @"/iphone/users";
    request.delegate = self;
    request.parameter = @{ @"id": userId ?: @"1" };
//    [request startWithSuccess:success failure:failed];
    return request;
}
- (FYFRequest *)getBannerInfo {
    FYFRequest *request = [[FYFRequest alloc] init];
    request.baseUrl = @"https://gank.io";
    request.path = @"/api/v2/banners?user=100";
    request.parameter = @{
        @"test": @"niko"
    };
    request.delegate = self;
    return request;
}

- (FYFRequest *)postAddUser:(NSString *)username password:(NSString *)password {
    FYFRequest *request = [[FYFRequest alloc] init];
    request.baseUrl = @"http://www.yuantiku.com";
    request.path = @"/iphone/register";
    request.requestMethod = FYFRequestMethodPOST;
    request.delegate = self;
    request.parameter = @{
        @"username": username ?: @"",
        @"password": password ?: @"",
    };
    return request;
}

- (FYFRequest *)getUserInfoWithId:(NSString *)userId successed:(FYFRequestSuccessBlock)success failed:(FYFRequestFailureBlock)failed {
    FYFRequest *request = [[FYFRequest alloc] init];
    request.baseUrl = @"https://gank.io";
    request.path = @"/api/v2/banners";
    request.delegate = self;
//    request.parameter = @{ @"id": userId ?: @"1" };
    [request startWithSuccess:success failure:failed];
    return request;
}
//http://gank.io/images/cfb4028bfead41e8b6e34057364969d1
- (FYFRequest *)loadImageWithPath:(NSString *)path progress:(AFURLSessionTaskProgressBlock)progress successed:(FYFRequestSuccessBlock)success failed:(FYFRequestFailureBlock)failed {
    FYFRequest *request = [[FYFRequest alloc] init];
    request.baseUrl = @"https://gank.io";
    request.path = @"/images/cfb4028bfead41e8b6e34057364969d1";
    
    request.resumableDownloadPath = [FYFNetworkFileTool getDefaultCacheFilePath:@"1.png"] ;
    request.resumableDownloadProgressBlock = progress;
//    request.parameter = @{ @"id": userId ?: @"1" };
    [request startWithSuccess:success failure:failed];
    return request;
}

- (FYFMultipleRequest *)multipleRequest {
    FYFRequest *request01 = [self getUserInfoWithId:@"1"];
    FYFRequest *request02 = [self getBannerInfo];
    
    FYFMultipleRequest *multipleRequest = [[FYFMultipleRequest alloc] initWithRequestArray:@[request01,request02]];
    [multipleRequest startWithSuccess:^(FYFMultipleRequest * _Nonnull multipleRequest) {
        FYFRequest *request01 = multipleRequest.requestArray[0];
        FYFRequest *request02 = multipleRequest.requestArray[1];
        NSLog(@"all successed request01 = %@, request02 = %@",request01.responseObject,request02.responseObject);
    } failure:^(FYFMultipleRequest * _Nonnull multipleRequest) {
        NSLog(@"all failed");
    }];
    return multipleRequest;
}

#pragma mark - FYFRequestDelegate
- (void)requestFinished:(FYFRequest *)request responseData:(id)responseData {
//    NSLog(@"%@",responseData);
}

- (void)requestFailed:(FYFRequest *)request error:(NSError *)error {
//    NSLog(@"%@",error);
    
}


@end
