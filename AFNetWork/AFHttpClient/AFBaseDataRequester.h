//
//  AFBaseDataRequester.h
//  AFBaseDataRequester.h
//
//  Created by kevin on 15/7/7.
//  Copyright (c) 2015年 kevin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"
#import "AFCommunicationKeyDefinition.h"
#import "AFDataResponse.h"


@class AFBaseDataRequester;

@protocol AFDataRequesterDelegate <NSObject>
@optional
/******************************************
 *@Description:网络请求成功
 *@Params: dataRequester : 当前操作的Requeser  aType : 当前请求的类型  responseObject : 请求的结果
 ******************************************/
-(void)dataRequesterSuccess:(AFBaseDataRequester *)dataRequester requesterWithType:(DataRequestType)aType receiveResponse:(AFDataResponse*)response;
/******************************************
 *@Description:网络请求进度
 *@Params: dataRequester : 当前操作的Requeser  aType : 当前请求的类型  totalBytesRead : 当前进度的流的大小 totalBytes : 总流大小
 ******************************************/
-(void)dataRequesterProgress:(AFBaseDataRequester*)dataRequester requesterWithType:(DataRequestType)aType receiveTotalBytesRead:(long long)totalBytesRead  receiveTotalBytes:(long long)totalBytes DEPRECATED_ATTRIBUTE;
/******************************************
 *@Description:网络请求进度
 *@Params: dataRequester : 当前操作的Requeser  aType : 当前请求的类型  progress 进度对象（IOS 7.0以上)
 ******************************************/
-(void)dataRequesterProgress:(AFBaseDataRequester*)dataRequester requesterWithType:(DataRequestType)aType receiveDataProgress:(NSProgress*)progress;
/******************************************
 *@Description:网络请求失败
 *@Params: dataRequester : 当前操作的Requeser  aType : 当前请求的类型  responseObject : 请求的结果
 ******************************************/
- (void)dataRequesterFail:(AFBaseDataRequester*)requester requesterWithType:(DataRequestType)aType receiveResponse:(AFDataResponse*)response;
@end

@interface AFBaseDataRequester : NSObject{
    __unsafe_unretained id<AFDataRequesterDelegate> _delegate;
    Class _originalClass;
}
@property (nonatomic, assign)id <AFDataRequesterDelegate> delegate;
//区分相同类型请求中的不同请求
@property (nonatomic, copy) NSString *name;
//请求类型
@property (nonatomic, assign) DataRequestType requestType;
//当前的URL
@property (nonatomic, copy) NSString *currentURL;
//当前请求的参数
@property (nonatomic, strong) NSDictionary *currentParams;
//当前操作的请求对象
@property (nonatomic, strong) NSURLSessionDataTask * sessionDataTask;
//是否设有请求头文件
@property (nonatomic, strong) NSDictionary<NSString*,NSString*> *HTTPRequestHeaders;
//设置请求参数格式
@property (nonatomic, assign)AFRequestSerializer requestSerializer;
//设置返回数据格式参数
@property (nonatomic, assign)AFResponseSerializer responseSerializer;
//验证开启Cookie
@property (nonatomic,readwrite) BOOL isAuthCookie;
//使用支持HTTPS
@property (nonatomic,readwrite) BOOL isAuthHttps;

#pragma mark - block
/**
 *  成功回调
 */
@property (nonatomic, copy) void(^sucessBlock)(AFBaseDataRequester *requester,DataRequestType aType,AFDataResponse *resonse);
/**
 *  失败回调
 */
@property (nonatomic, copy) void(^failureBlock)(AFBaseDataRequester *requester,DataRequestType aType,AFDataResponse *resonse);
/**
 *  进度条回调
 */
@property (nonatomic, copy) void(^progressBlock)(AFBaseDataRequester *requester,DataRequestType aType,NSProgress *progress);

/**
 *  不带进度条的成功/失败回调
 *
 *  @param success 成功回调
 *  @param failure 失败回调
 */
- (void)completion:(void(^)(AFBaseDataRequester *requester,DataRequestType aType,AFDataResponse *resonse))success failure:(void(^)(AFBaseDataRequester *requester,DataRequestType aType,AFDataResponse *resonse))failure;

/**
 * 带进度条／成功／失败回调
 *
 *  @param progress 进度条回调
 *  @param success  成功回调
 *  @param failure  失败回调
 */
-  (void)progress:(void(^)(AFBaseDataRequester *requester,DataRequestType aType,NSProgress *progress))progress completion:(void(^)(AFBaseDataRequester *requester,DataRequestType aType,AFDataResponse *resonse))success failure:(void(^)(AFBaseDataRequester *requester,DataRequestType aType,AFDataResponse *resonse))failure;

/**
 *  取消当前网络操作（不是所有的网络操作）
 */
- (void)cancelDownload;
/**
 *  判断代理是否被释放（YES 已释放，NO未释放）
 *
 *  @return <#return value description#>
 */
-(BOOL)isDelegateRelease;
/**
 *  发送提交网络请求
 */
-(void)sendRequest;

#pragma mark - GET POST 数据请求回调（子类可继承重绘）
-(void)success:(NSURLSessionDataTask*)task  dataRequesterType:(DataRequestType)aType withObject:(id)responesObject;
-(void)failure:(NSURLSessionDataTask*)task dataRequesterType:(DataRequestType)aType withError:(NSError*)error;
#pragma mark - 下载数据回调（子类可继承重绘）
-(void)downloadSuccess:(NSURLSessionDownloadTask*)task dataRequesterType:(DataRequestType)aType withObject:(id)responesObject;
-(void)downloadFailure:(NSURLSessionDownloadTask*)task dataRequesterType:(DataRequestType)aType withError:(NSError*)error;

#pragma mark - 文件上传
/**
 *  value  文件类型 （可为NSData,NSString,这里的NSString是文件路径）
 *
 *  @param value <#value description#>
 *  @param key   服务器上传文件的文件字段
 */
- (void)setValue:(id)value forHTTPFileKey:(NSString *)key;
/**
 *  value  文件类型 （可为NSData,NSString,这里的NSString是文件路径）
 *
 *  @param value <#value description#>
 *  @param name  文件名字
 *  @param key   服务器上传文件的文件字段
 */
- (void)setValue:(id)value fileName:(NSString*)name forHTTPFileKey:(NSString *)key;

#pragma mark - 监听网络状态
/**
 *  监听网络状态
 *
 *  @param block <#block description#>
 */
+(void)listensNetworkReachability:(void(^)(BOOL success))block;

#pragma mark - Cookie
/**
 *  保存Cookie
 */
+ (void)saveCookie;
/**
 *  设置Cookie
 */
+ (void)setCookie;
/**
 *  清除Cookie
 */
+ (void)clearCookie;
@end

