/*
 #####################################################################
 # File    : FYFMultipleAgent.m
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


#import "FYFMultipleAgent.h"

@interface FYFMultipleAgent ()

@property (strong, nonatomic) NSMutableArray<FYFMultipleRequest *> *requestArray;

@end

@implementation FYFMultipleAgent


+ (FYFMultipleAgent *)sharedAgent {
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
        _requestArray = [NSMutableArray array];
    }
    return self;
}

- (void)addMultipleRequest:(FYFMultipleRequest *)request {
    @synchronized(self) {
        [_requestArray addObject:request];
    }
}

- (void)removeMultipleRequest:(FYFMultipleRequest *)request {
    @synchronized(self) {
        [_requestArray removeObject:request];
    }
}


@end
