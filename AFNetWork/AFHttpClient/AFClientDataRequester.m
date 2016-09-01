//
//  AFClientDataRequester.h
//  AFClientDataRequester
//
//  Created by kevin on 15/7/7.
//  Copyright (c) 2015年 kevin. All rights reserved.
//

#import "AFClientDataRequester.h"

@implementation AFClientDataRequester

+(instancetype)manager{
//    static dispatch_once_t predicate;
//    static AFClientDataRequester * sharedManager;
//    dispatch_once(&predicate, ^{
//        sharedManager=[[[self class] alloc] init];
//    });
//    return sharedManager;
    return [[[self class] alloc] init];
}

#pragma mark - 重写了父类的GET POST 回调
-(void)success:(NSURLSessionDataTask *)task dataRequesterType:(DataRequestType)aType withObject:(id)responesObject{
    /**
     *  返回信息类
     */
    AFDataResponse *response = [AFDataResponse new];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)task.response;
    if([httpResponse statusCode] != 200){
        if([self isDelegateRelease]) return;
        response.responseCode = [httpResponse statusCode];
        response.responseStatus = AFURLResponeStateFailure;
        response.responseMsg = @"服务器网络异常";
        if(self.delegate && [self.delegate respondsToSelector:@selector(dataRequesterFail:requesterWithType:receiveResponse:)]){
            [self.delegate dataRequesterFail:self requesterWithType:aType receiveResponse:response];
        }else{
            if(self.failureBlock){
                self.failureBlock(self,aType,response);
            }
        }
        return;
    }
    //json 格式
    id dataObject = nil;
    if(self.responseSerializer == AF_JSONResponseSerializer){
        dataObject = responesObject;
    }else
    {
        NSError *error;
        dataObject = [NSJSONSerialization JSONObjectWithData:responesObject options:NSJSONReadingMutableLeaves error:&error];
        if(error){
            response.responseCode = AFURLResponeStateFailure;
            response.responseStatus = AFURLResponeStateFailure;
            response.responseMsg = @"服务器数据异常";
            NSString *string  = [[NSString alloc] initWithData:responesObject encoding:NSUTF8StringEncoding];
            response.responseData = string;
            //未被释放
            if(![self isDelegateRelease]){
                if(self.delegate && [self.delegate respondsToSelector:@selector(dataRequesterFail:requesterWithType:receiveResponse:)]){
                    [self.delegate dataRequesterFail:self requesterWithType:aType receiveResponse:response];
                }
            }
            else{
                if(self.failureBlock){
                    self.failureBlock(self,aType,response);
                }
            }
            return;
        }
        
    }
    if([dataObject isKindOfClass:[NSArray class]]){
        response.responseStatus = AFURLResponeStateSuccess;
        response.responseData  = dataObject;
    }else{
        //根据服务器返回结构解析
        NSString *code =[NSString stringWithFormat:@"%@",dataObject[@"code"]];
        NSString *status = [NSString stringWithFormat:@"%@",dataObject[@"status"]];
        NSString *msg = dataObject[@"msg"];
        id data = dataObject[@"data"];
        response.responseCode = code == nil ? 0:[code integerValue];
        response.responseStatus = status == nil ? 0 : [status integerValue];
        response.responseMsg = msg;
        response.responseData = data;
    }
    //未被释放
    if(![self isDelegateRelease])
    {
       if(self.delegate && [self.delegate respondsToSelector:@selector(dataRequesterSuccess:requesterWithType:receiveResponse:)]){
            [self.delegate dataRequesterSuccess:self requesterWithType:aType receiveResponse:response];
       }
    }else{
       if(self.sucessBlock){
           self.sucessBlock(self,aType,response);
       }
   }
    
}

-(void)failure:(NSURLSessionDataTask *)task dataRequesterType:(DataRequestType)aType withError:(NSError *)error{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    AFDataResponse *response = [AFDataResponse new];
    response.responseStatus = AFURLResponeStateFailure;
    response.responseError  = error;
    //未被释放
    if(![self isDelegateRelease]){
        if (self.delegate && [self.delegate respondsToSelector:@selector(dataRequesterFail:requesterWithType:receiveResponse:)]){
            [self.delegate dataRequesterFail:self requesterWithType:aType receiveResponse:response];
        }
    }
    else{
        if(self.failureBlock){
            self.failureBlock(self,aType,response);
        }
    }
}

-(void)testDownload{
    self.requestType = TEST_TYPE;
//    self.currentURL  = @"https://www.baidu.com/img/bd_logo1.png";
//    self.currentURL = @"http://gdown.baidu.com/data/wisegame/22c81dfffced2c1c/zhiwudazhanjiangshi2gaoqing_723.apk";
    self.currentURL = @"http://skiplagged.com/api/pokemon.php?bounds=40.724732,-74.015936,40.700855,-73.995936";
    [self sendRequest];
}

@end
