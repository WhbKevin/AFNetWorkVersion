//
//  AFDataResponse.h
//  (数据返回结果)
//  Created by kevin on 15/7/31.
//  Copyright (c) 2015年 kevin. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface AFDataResponse : NSObject
@property (nonatomic,assign)NSInteger responseCode; //数据码
@property (nonatomic,assign)NSInteger responseStatus; //请求状态
@property (nonatomic,strong)id responseData; //数据内容
@property (nonatomic,copy)NSString *responseMsg; //提示语
@property (nonatomic,strong)NSError *responseError; //错误异常
@end

//文件类
@interface AFClientFileDetail : NSObject
@property(strong,nonatomic) NSString *name; //文件名字
@property(strong,nonatomic) NSData *data; //文件的二进制流
@property(strong,nonatomic) NSString *fileKey; //服务器上的key
@end
