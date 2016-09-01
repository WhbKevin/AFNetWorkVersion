//
//  AFDataResponse.h
//
//  Created by kevin on 15/7/31.
//  Copyright (c) 2015年 kevin. All rights reserved.
//

#import "AFDataResponse.h"

@implementation AFDataResponse
-(instancetype)init{
    self = [super init];
    if(self){
        [self setResponse];
    }
    return self;
}
-(void)setResponse{
    self.responseData = nil;
    self.responseMsg = nil;
    self.responseError = nil;
}
-(void)dealloc{
    [self setResponse];
}
@end

#pragma mark - 文件类
@implementation AFClientFileDetail
@synthesize name;
@synthesize data;
@synthesize fileKey;
-(void)dealloc{
    self.name = nil;
    self.data = nil;
    self.fileKey =nil;
}
- (instancetype)init{
    self =[super init];
    if(self){
        self.name = nil;
        self.data = nil;
        self.fileKey =nil;
    }
    return self;
}
@end