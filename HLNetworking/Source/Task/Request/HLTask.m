//
//  HLTask.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2016/9/25.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import "HLTask.h"
#import "HLTask_InternalParams.h"
#import "HLTaskManager.h"
#import "HLSecurityPolicyConfig.h"
#import "HLNetworkConfig.h"

@implementation HLTask

#pragma mark - init
- (instancetype)init {
    self = [super init];
    if (self) {
        _requestTaskType = Download;
        _baseURL = [HLTaskManager sharedManager].config.request.baseURL;
        NSString *baseResumePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"com.qkhl.HLNetworking/downloadDict"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:baseResumePath isDirectory:nil]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:baseResumePath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        _resumePath = [baseResumePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%lu.arc", (unsigned long)self.hash]];
#ifdef DEBUG
        _securityPolicy = [HLSecurityPolicyConfig policyWithPinningMode:HLSSLPinningModeNone];
#else
        _securityPolicy = [HLSecurityPolicyConfig policyWithPinningMode:HLSSLPinningModePublicKey];
#endif
    }
    return self;
}

+ (instancetype)task {
    return [[self alloc] init];
}

#pragma mark - Process

- (HLTask *)start {
    [HLTaskManager send:self];
    return self;
}

- (HLTask *)cancel {
    [HLTaskManager cancel:self];
    return self;
}

- (HLTask *)resume {
    [HLTaskManager resume:self];
    return self;
}

- (HLTask *)pause {
    [HLTaskManager pause:self];
    return self;
}

#pragma mark - NSObject
- (NSUInteger)hash {
    NSString *hashStr;
    if (self.taskURL) {
        hashStr = self.taskURL;
    } else {
        hashStr = [NSString stringWithFormat:@"%@/%@", self.baseURL, self.path];
    }
    return [hashStr hash];
}

- (BOOL)isEqualToTask:(HLTask *)task {
    return [self hash] == [task hash];
}

- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[HLTask class]]) return NO;
    return [self isEqualToTask:(HLTask *) object];
}

- (NSString *)description {
    NSMutableString *desc = [NSMutableString string];
#if DEBUG
    [desc appendString:@"\n===============HLTask Start===============\n"];
    [desc appendFormat:@"Class: %@\n", self.class];
    [desc appendFormat:@"BaseURL: %@\n", self.baseURL ?: [HLTaskManager sharedManager].config.request.baseURL];
    [desc appendFormat:@"Path: %@\n", self.path ?: @"未设置"];
    [desc appendFormat:@"TaskURL: %@\n", self.taskURL ?: @"未设置"];
    [desc appendFormat:@"ResumePath: %@", self.resumePath];
    [desc appendFormat:@"CachePath: %@", self.filePath];
    [desc appendFormat:@"TimeoutInterval: %f\n", self.timeoutInterval];
    [desc appendFormat:@"SecurityPolicy: %@\n", self.securityPolicy];
    [desc appendFormat:@"RequestTaskType: %@\n", [self getRequestTaskTypeString:self.requestTaskType]];
    [desc appendFormat:@"CachePolicy: %@\n", [self getCachePolicyString:self.cachePolicy]];
    [desc appendString:@"===============End===============\n"];
#else
    desc = @"";
#endif
    return desc;
}

- (NSString *)getRequestTaskTypeString:(HLRequestTaskType)type {
    switch (type) {
        case Download:
            return @"Download";
            break;
        case Upload:
            return @"Upload";
            break;
        default:
            return @"Download";
            break;
    }
}

- (NSString *)getCachePolicyString:(NSURLRequestCachePolicy)policy {
    switch (policy) {
        case NSURLRequestUseProtocolCachePolicy:
            return @"NSURLRequestUseProtocolCachePolicy";
            break;
        case NSURLRequestReloadIgnoringLocalCacheData:
            return @"NSURLRequestReloadIgnoringLocalCacheData";
            break;
        case NSURLRequestReloadIgnoringLocalAndRemoteCacheData:
            return @"NSURLRequestReloadIgnoringLocalAndRemoteCacheData";
            break;
        case NSURLRequestReturnCacheDataElseLoad:
            return @"NSURLRequestReturnCacheDataElseLoad";
            break;
        case NSURLRequestReturnCacheDataDontLoad:
            return @"NSURLRequestReturnCacheDataDontLoad";
            break;
        case NSURLRequestReloadRevalidatingCacheData:
            return @"NSURLRequestReloadRevalidatingCacheData";
            break;
        default:
            return @"NSURLRequestUseProtocolCachePolicy";
            break;
    }
}

#pragma mark - setter
/**
 设置HLAPI的requestDelegate
 */
- (HLTask *(^)(id<HLTaskRequestDelegate> delegate))setDelegate {
    return ^HLTask* (id<HLTaskRequestDelegate> delegate) {
        self.delegate = delegate;
        return self;
    };
}

- (HLTask *(^)(NSString *taskURL))setTaskURL {
    return ^HLTask* (NSString *taskURL) {
        self.taskURL = taskURL;
        NSURL *tmpURL = [NSURL URLWithString:taskURL];
        if (tmpURL) {
            self.baseURL = [NSString stringWithFormat:@"%@://%@", tmpURL.scheme, tmpURL.host];
            self.path = [NSString stringWithFormat:@"%@", tmpURL.query];
        }
        return self;
    };
}

- (HLTask *(^)(NSString *baseURL))setBaseURL {
    return ^HLTask* (NSString *baseURL) {
        self.baseURL = baseURL;
        return self;
    };
}

- (HLTask *(^)(NSString *path))setPath {
    return ^HLTask* (NSString *path) {
        self.path = path;
        return self;
    };
}

- (HLTask *(^)(NSString *filePath))setFilePath {
    return ^HLTask* (NSString *filePath) {
        self.filePath = filePath;
        return self;
    };
}

- (HLTask* (^)(HLSecurityPolicyConfig *apiSecurityPolicy))setSecurityPolicy {
    return ^HLTask* (HLSecurityPolicyConfig *apiSecurityPolicy) {
        self.securityPolicy = apiSecurityPolicy;
        return self;
    };
}

- (HLTask* (^)(HLRequestTaskType requestTaskType))setTaskType {
    return ^HLTask* (HLRequestTaskType requestTaskType) {
        self.requestTaskType = requestTaskType;
        return self;
    };
}

- (void)requestWillBeSent {
    if ([self.delegate respondsToSelector:@selector(requestWillBeSentWithTask:)]) {
        [self.delegate requestWillBeSentWithTask:self];
    }
}

- (void)requestDidSent {
    if ([self.delegate respondsToSelector:@selector(requestDidSentWithTask:)]) {
        [self.delegate requestDidSentWithTask:self];
    }
}
@end
