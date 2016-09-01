//
//  AFDownDataRequester.m
//  AFNetWorkVersion
//
//  Created by tutengdai on 16/8/30.
//  Copyright © 2016年 kevin. All rights reserved.
//

#import "AFDownDataRequester.h"

@implementation AFDownDataRequester
+(instancetype)manager{
    return [[[self class] alloc] init];
}
#pragma mark - 重写父类下载的方法
-(void)downloadSuccess:(NSURLSessionDownloadTask *)task dataRequesterType:(DataRequestType)aType withObject:(id)responesObject{
    AFDataResponse *response = [AFDataResponse new];
    response.responseData = responesObject;
    response.responseStatus = AFURLResponeStateSuccess;
    response.responseError = nil;
    response.responseMsg = @"下载成功!";
    if(self.delegate && [self.delegate respondsToSelector:@selector(dataRequesterSuccess:requesterWithType:receiveResponse:)]){
        [self.delegate dataRequesterSuccess:self requesterWithType:self.requestType receiveResponse:response];
    }else {
        if(self.sucessBlock){
            self.sucessBlock(self,self.requestType,response);
        }
    }
}
-(void)downloadFailure:(NSURLSessionDownloadTask *)task dataRequesterType:(DataRequestType)aType withError:(NSError *)error{
    AFDataResponse *response = [AFDataResponse new];
    response.responseData = nil;
    response.responseStatus = AFURLResponeStateFailure;
    response.responseError = error;
    response.responseMsg = @"下载失败!";
    if(self.delegate && [self.delegate respondsToSelector:@selector(dataRequesterFail:requesterWithType:receiveResponse:)]){
        [self.delegate dataRequesterFail:self requesterWithType:self.requestType receiveResponse:response];
    }else{
        if(self.failureBlock){
            self.failureBlock(self,self.requestType,response);
        }
    }
}

@end
