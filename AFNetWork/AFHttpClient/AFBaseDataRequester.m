//
//  AFBaseDataRequester.m
//  AFBaseDataRequester
//
//  Created by kevin on 15/7/7.
//  Copyright (c) 2015年 kevin. All rights reserved.
//

#import "AFBaseDataRequester.h"

Class object_getClass(id object);
#define KMaxConcurrentOperationCount  3

#pragma mark - Block 机制

@interface AFBaseDataRequester()
@property (strong,nonatomic)NSMutableArray *uploadFileArray;
@end

@implementation AFBaseDataRequester
@synthesize requestType;
@synthesize currentURL;
@synthesize currentParams;
@synthesize delegate = _delegate;

-(void)dealloc{
}

- (void)cancelDownload
{
    self.delegate = nil;
    if(self.sessionDataTask){
        [self.sessionDataTask cancel];
        self.sessionDataTask = nil;
    }
    self.currentParams = nil;
    self.currentURL = nil;
    self.uploadFileArray = nil;
    self.HTTPRequestHeaders = nil;
    self.sucessBlock = nil;
    self.failureBlock = nil;
    self.progressBlock = nil;
}

#pragma mark -检索HTTP请求模式（HTTPMethod)
-(BOOL)requestTypeIsResource:(DataRequestType)type
{
    return type > DRT_TYPE_RESOURCE_BEGIN && type < DRT_TYPE_RESOURCE_END;
}

-(BOOL)requestTypeIsGet:(DataRequestType)aType
{
    return aType > DRT_TYPE_GET_BEGIN && aType < DRT_TYPE_GET_END;
}

-(BOOL)requestTypeIsPost:(DataRequestType)aType
{
    return aType > DRT_TYPE_POST_BEGIN && aType < DRT_TYPE_POST_END;
}

-(BOOL)requestTypeIsUpload:(DataRequestType)aType{
    return aType > DRT_TYPE_UPLOAD_BEGIN && aType < DRT_TYPE_UPLOAD_END;
}

-(BOOL)requestTypeIsDownLoad:(DataRequestType)aType{
    return aType > DRT_TYPE_DOWNLOAD_BEGIN && aType < DRT_TYPE_DOWNLOAD_END;
}
#pragma mark - Block 回调
/**
 *  不带进度条的成功/失败回调
 *
 *  @param success <#success description#>
 *  @param failure <#failure description#>
 */
- (void)completion:(void (^)(AFBaseDataRequester *, DataRequestType, AFDataResponse *))success failure:(void (^)(AFBaseDataRequester *, DataRequestType, AFDataResponse *))failure{
    self.sucessBlock = success;
    self.failureBlock = failure;
}
/**
 *  带进度条的成功/失败回调
 *
 *  @param progress <#progress description#>
 *  @param success  <#success description#>
 *  @param failure  <#failure description#>
 */
- (void)progress:(void (^)(AFBaseDataRequester *, DataRequestType, NSProgress *))progress completion:(void (^)(AFBaseDataRequester *, DataRequestType, AFDataResponse *))success failure:(void (^)(AFBaseDataRequester *, DataRequestType, AFDataResponse *))failure{
    self.progressBlock = progress;
    self.sucessBlock = success;
    self.failureBlock = failure;
}

#pragma mark - 设置请求头/请求返回
-(AFHTTPRequestSerializer*)setRequestSerializer{
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    if(self.requestSerializer == AF_JSONRequestSerializer){
        serializer = [AFJSONRequestSerializer serializer];
    }
    //超时时间
    serializer.timeoutInterval = timeoutInterval;
    //文本编码
    serializer.stringEncoding = NSUTF8StringEncoding;
    //设置请求头
    if(self.HTTPRequestHeaders){
        [self.HTTPRequestHeaders enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [serializer setValue:obj forHTTPHeaderField:key];
        }];
    }
    //cookie  开启
    if(self.isAuthCookie){
        //设置Cookie
        [AFBaseDataRequester setCookie];
    }
    return serializer;
}

- (AFHTTPResponseSerializer*)setResponseSerializer{
    AFHTTPResponseSerializer *response = [AFHTTPResponseSerializer serializer];
    if(self.responseSerializer == AF_JSONResponseSerializer){
        response = [AFJSONResponseSerializer serializer];
    }else{
        response.acceptableContentTypes = [NSSet setWithObjects:appJson, textJson, textJavascript, textHtml,textPlain,textXML,httpImages,nil];
    }
    //文本编码
    response.stringEncoding = NSUTF8StringEncoding;
    return response;
}

#pragma mark - 发送请求
-(void)sendRequest{
    _originalClass = object_getClass(_delegate);
    //连接成功
    if ([self requestTypeIsPost:requestType])
    {
        //POST 方式
        [self postRequester];
        
    }else if([self requestTypeIsGet:requestType]){
        //GET 方式
        [self getRequester];
    }else if([self requestTypeIsUpload:requestType]){
        //上传（同步）
        [self uploadSynchronousRequester];
    }else if([self requestTypeIsDownLoad:requestType])
    {
        //下载
        [self downRequester];
        
    }else{
        //扩展方式（其他方式)
    }
}
#pragma mark - GET 数据
/*
  GET 方式
*/
-(void)getRequester{
    
    __weak typeof(self) safeweak = self;
    /**
     *  IOS 7.0以上支持 NSURLSessionDataTask
     *
     *  @param __IPHONE_OS_VERSION_MAX_ALLOWED <#__IPHONE_OS_VERSION_MAX_ALLOWED description#>
     *
     *  @return <#return value description#>
     */
    #if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000) || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090)
        AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
        sessionManager.requestSerializer = [self setRequestSerializer];
        sessionManager.responseSerializer = [self setResponseSerializer];
        [sessionManager.operationQueue cancelAllOperations];
        sessionManager.operationQueue.maxConcurrentOperationCount = KMaxConcurrentOperationCount;
        //检验是否支持HTTPS
        [self checkSSL:sessionManager];
     self.sessionDataTask  = [sessionManager GET:safeweak.currentURL parameters:safeweak.currentParams progress:^(NSProgress * _Nonnull downloadProgress) {
        //block 回调
        if(safeweak.progressBlock){
            safeweak.progressBlock(safeweak,safeweak.requestType,downloadProgress);
        }
        //代理(未被释放）
        if(![safeweak isDelegateRelease]){
            if([safeweak.delegate respondsToSelector:@selector(dataRequesterProgress:requesterWithType:receiveDataProgress:)]){
                [safeweak.delegate dataRequesterProgress:safeweak requesterWithType:safeweak.requestType receiveDataProgress:downloadProgress];
            }
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)task.response;
        //保存Cookie(这里也可以指定在那个域名路径下的才保存Cookie) URL的Path
        //比如if([[[NSURL URLWithString:AF_BASE_URL] path] isEqualToString:@"login"])
        if(self.isAuthCookie){
            [AFBaseDataRequester saveCookie];
        }
        if(httpResponse.statusCode == 200)
        {
            if([safeweak respondsToSelector:@selector(success:dataRequesterType:withObject:)]){
                [safeweak success:task dataRequesterType:safeweak.requestType withObject:responseObject];
            }else{
            }
        }else{
            if([safeweak respondsToSelector:@selector(failure:dataRequesterType:withError:)]){
                [safeweak failure:task dataRequesterType:safeweak.requestType withError:nil];
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if([safeweak respondsToSelector:@selector(failure:dataRequesterType:withError:)]){
            [safeweak failure:task dataRequesterType:safeweak.requestType withError:error];
        }
    }];
    #endif
}
#pragma mark - POST 数据
/*
 POST  方式
 */
-(void)postRequester{
    __weak typeof(self) safeweak = self;
    
    /**
     *  IOS 7.0以上支持 NSURLSessionDataTask
     *
     *  @param __IPHONE_OS_VERSION_MAX_ALLOWED <#__IPHONE_OS_VERSION_MAX_ALLOWED description#>
     *
     *  @return <#return value description#>
     */
    #if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000) || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090)
    AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
    sessionManager.requestSerializer = [self setRequestSerializer];
    sessionManager.responseSerializer = [self setResponseSerializer];
    [sessionManager.operationQueue cancelAllOperations];
    //设置允许同时最大并发数量，过大容易出问题
    sessionManager.operationQueue.maxConcurrentOperationCount = KMaxConcurrentOperationCount;
    //检验是否支持HTTPS
    [self checkSSL:sessionManager];
    
    self.sessionDataTask = [sessionManager POST:safeweak.currentURL parameters:safeweak.currentParams progress:^(NSProgress * _Nonnull uploadProgress) {
        //block 回调
        if(safeweak.progressBlock){
            safeweak.progressBlock(safeweak,safeweak.requestType,uploadProgress);
        }
        //代理(未被释放）
        if(![safeweak isDelegateRelease]){
            if([safeweak.delegate respondsToSelector:@selector(dataRequesterProgress:requesterWithType:receiveDataProgress:)]){
                [safeweak.delegate dataRequesterProgress:safeweak requesterWithType:safeweak.requestType receiveDataProgress:uploadProgress];
            }
        }
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //保存Cookie(这里也可以指定在那个域名路径下的才保存Cookie) URL的Path
        //比如if([[[NSURL URLWithString:AF_BASE_URL] path] isEqualToString:@"login"])
        if(self.isAuthCookie){
            [AFBaseDataRequester saveCookie];
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)task.response;
        if(httpResponse.statusCode == 200)
        {
            if([safeweak respondsToSelector:@selector(success:dataRequesterType:withObject:)]){
                [safeweak success:task dataRequesterType:safeweak.requestType withObject:responseObject];
            }
        }else{
            if([safeweak respondsToSelector:@selector(failure:dataRequesterType:withError:)]){
                [safeweak failure:task dataRequesterType:safeweak.requestType withError:nil];
            }
        }

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if([safeweak respondsToSelector:@selector(failure:dataRequesterType:withError:)]){
            [safeweak failure:task dataRequesterType:safeweak.requestType withError:error];
        }
    }];
    #endif
}

#pragma mark - 下载文件
/*
  下载文件(显示进度条)
*/

-(void)downRequester{
    // 定义一个progress指针
//   __block NSProgress *progress;
    // 创建一个URL链接
    NSURL *URL = [NSURL URLWithString:self.currentURL];
    // 初始化一个请求
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    // 获取一个Session管理器
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    //检验是否支持HTTPS
    [self checkSSL:manager];
    // 开始下载任务
    //__block NSURLSessionDataTask *task
    __weak typeof(self) safeweak = self;
    __block NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        //block 回调
        if(safeweak.progressBlock){
            safeweak.progressBlock(safeweak,safeweak.requestType,downloadProgress);
        }
        //代理(未被释放)
        if(![safeweak isDelegateRelease]){
            if([safeweak.delegate respondsToSelector:@selector(dataRequesterProgress:requesterWithType:receiveDataProgress:)]){
                [safeweak.delegate dataRequesterProgress:safeweak requesterWithType:safeweak.requestType receiveDataProgress:downloadProgress];
            }
        }
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        //根据网址信息拼接成一个完整的文件存储路径并返回给block
        return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        //已经下载完成,移除进度监听任务
        if([downloadTask state] == NSURLSessionTaskStateCompleted)
        {
            if (error) {
                if([safeweak respondsToSelector:@selector(downloadFailure:dataRequesterType:withError:)]){
                    [safeweak downloadFailure:downloadTask dataRequesterType:safeweak.requestType withError:error];
                }
            } else {
                NSData *data = nil;
                if(filePath)
                {
                    data = [NSData dataWithContentsOfURL:filePath];
                }
                if([safeweak respondsToSelector:@selector(downloadSuccess:dataRequesterType:withObject:)]){
                    [safeweak downloadSuccess:downloadTask dataRequesterType:safeweak.requestType withObject:data];
                }
            }
        }

    }];
    [downloadTask resume];
    self.sessionDataTask = (NSURLSessionDataTask*)downloadTask;
}

#pragma mark - 上传文件
/**
 *  上传文件(同步上传)
 */
-(void)uploadSynchronousRequester{
    AFHTTPSessionManager * manager =[AFHTTPSessionManager manager];
    //检验是否支持HTTPS
    [self checkSSL:manager];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    if(self.HTTPRequestHeaders){
        [self.HTTPRequestHeaders enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [manager.requestSerializer setValue:obj forHTTPHeaderField:key];
        }];
    }
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:appJson, textJson, textJavascript, textHtml,textPlain,textXML,httpImages, nil];
    __weak typeof(self) safeweak = self;
    self.sessionDataTask  = [manager POST:safeweak.currentURL parameters:safeweak.currentParams constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        [safeweak.uploadFileArray enumerateObjectsUsingBlock:^(AFClientFileDetail  *fileDetail, NSUInteger idx, BOOL * _Nonnull stop) {
            [formData appendPartWithFileData:fileDetail.data
                                        name:fileDetail.fileKey
                                    fileName:fileDetail.name
                                    mimeType:cotetStream];
        }];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        //进度
        //block 回调
        if(safeweak.progressBlock){
            safeweak.progressBlock(safeweak,safeweak.requestType,uploadProgress);
        }
        //代理(未被释放)
        if(![safeweak isDelegateRelease]){
            if([safeweak.delegate respondsToSelector:@selector(dataRequesterProgress:requesterWithType:receiveDataProgress:)]){
                [safeweak.delegate dataRequesterProgress:safeweak requesterWithType:safeweak.requestType receiveDataProgress:uploadProgress];
            }
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if([safeweak respondsToSelector:@selector(success:dataRequesterType:withObject:)])
        {
            [safeweak success:task dataRequesterType:safeweak.requestType withObject:responseObject];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if([safeweak respondsToSelector:@selector(failure:dataRequesterType:withError:)]){
            [safeweak failure:task dataRequesterType:safeweak.requestType withError:error];
        }
    }];
}

/**
 *  检验是否支持HTTPS
 *
 *  @return <#return value description#>
 */
- (void)checkSSL:(AFHTTPSessionManager*)manager{
    //支持 HTTPS
    if(self.isAuthHttps){
        //
        [manager setSecurityPolicy:[AFBaseDataRequester customSecurityPolicy]];
    }
}
#pragma mark - 上传文件
/**
 *  value  文件类型 （可为NSData,NSString,这里的NSString是文件路径）
 *
 *  @param value <#value description#>
 *  @param key   服务器上传文件的文件字段
 */
- (void)setValue:(id)value forHTTPFileKey:(NSString *)key{
    NSString *fileName = nil;
    if([value isKindOfClass:[NSData class]]){
        NSDate* date = [NSDate date];
        NSTimeInterval time = [date timeIntervalSince1970];
        //文件名
        fileName = [NSString stringWithFormat:@"%.0f.png", time];
        
    }else if([value isKindOfClass:[NSString class]]){
        NSString *path = (NSString*)value;
        fileName = path.lastPathComponent;
    }
    if(fileName){
        [self setValue:value fileName:fileName forHTTPFileKey:key];
    }
}
/**
 *  value  文件类型 （可为NSData,NSString,这里的NSString是文件路径）
 *
 *  @param value <#value description#>
 *  @param name  文件名字
 *  @param key   服务器上传文件的文件字段
 */
- (void)setValue:(id)value fileName:(NSString*)name forHTTPFileKey:(NSString *)key{
    if(self.uploadFileArray == nil){
        self.uploadFileArray = [NSMutableArray arrayWithCapacity:0];
    }
    NSData *data = nil;
    if([value isKindOfClass:[NSData class]]){
        data = (NSData*)value;
    }else if([value isKindOfClass:[NSString class]]){
        data = [NSData dataWithContentsOfFile:value];
    }
    if(data){
        AFClientFileDetail *fileDetail = [AFClientFileDetail new];
        fileDetail.name = name;
        fileDetail.data = value;
        fileDetail.fileKey = key;
        [self.uploadFileArray addObject:fileDetail];
    }
}

#pragma mark - 代理释放
-(BOOL)isDelegateRelease{
    if(_originalClass == object_getClass(_delegate)){
        return NO;
    }
    return YES;
}

#pragma mark - 网络监听
+(void)listensNetworkReachability:(void (^)(BOOL))block{
    AFNetworkReachabilityManager *afNetworkReachabilityManager = [AFNetworkReachabilityManager sharedManager];
    [afNetworkReachabilityManager startMonitoring];  //开启网络监视器；
    [afNetworkReachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusNotReachable:{
//                externAppNSLog(@"网络不通：%f", 0.0f);
                break;
            }
            case AFNetworkReachabilityStatusReachableViaWiFi:{
//                externAppNSLog(@"网络通过WIFI连接：%f", 1.0f );
                break;
            }
            case AFNetworkReachabilityStatusReachableViaWWAN:{
//                externAppNSLog(@"网络通过无线连接：%f", 1.0f);
                break;
            }
            default:
                break;
        }
        if(status == AFNetworkReachabilityStatusUnknown){
            //网络连接失败
            if(block){
                block(NO);
            }
        }else{
            //网络正常
            if(block){
                block(YES);
            }
        }
    }];
}

#pragma mark - GET POST 回调(子类去实现）
-(void)success:(NSURLSessionDataTask*)task  dataRequesterType:(DataRequestType)aType withObject:(id)responesObject{
    
}

-(void)failure:(NSURLSessionDataTask*)task dataRequesterType:(DataRequestType)aType withError:(NSError*)error{
    
}
#pragma mark - 下载回调(子类去实现）
-(void)downloadSuccess:(NSURLSessionDownloadTask *)task dataRequesterType:(DataRequestType)aType withObject:(id)responesObject{
}
-(void)downloadFailure:(NSURLSessionDownloadTask *)task dataRequesterType:(DataRequestType)aType withError:(NSError *)error{
}
#pragma mark - Cookie 操作
/**
 *  保存Cookie
 */
+ (void)saveCookie{
    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    identifier = [identifier stringByAppendingString:@".cookie"];
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL: [NSURL URLWithString:AF_BASE_URL]];
    if(cookies.count){
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:cookies];
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:identifier];
    }
}
/**
 *  设置Cookie
 */
+ (void)setCookie{
    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    identifier = [identifier stringByAppendingString:@".cookie"];
    NSData *cookiesData = [[NSUserDefaults standardUserDefaults]objectForKey:identifier];
    if ([cookiesData length]) {
        NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookiesData];
        NSHTTPCookie *cookie;
        for (cookie in cookies) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        }
    }
}
/**
 *  删除Cookie
 */
+ (void)clearCookie{
    //cookie （这里是指定域名下的cookie)
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL: [NSURL URLWithString:AF_BASE_URL]];
    for (NSHTTPCookie *cookie in cookies) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    identifier = [identifier stringByAppendingString:@".cookie"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:identifier];
}

+ (AFSecurityPolicy*)customSecurityPolicy
{
    // /先导入证书
    NSString *cerPath =[[NSBundle mainBundle] pathForResource:SSLCertificate ofType:nil];//证书的路径
    NSData *certData = [NSData dataWithContentsOfFile:cerPath];
    AFSecurityPolicy *securityPolicy = nil;
    //证书验证
    if(certData.length)
    {
        // AFSSLPinningModeCertificate 使用证书验证模式
            securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
        // allowInvalidCertificates 是否允许无效证书（也就是自建的证书），默认为NO
        // 如果是需要验证自建证书，需要设置为YES
        // securityPolicy.allowInvalidCertificates = YES;
        
        //validatesDomainName 是否需要验证域名，默认为YES；
        //假如证书的域名与你请求的域名不一致，需把该项设置为NO；如设成NO的话，即服务器使用其他可信任机构颁发的证书，也可以建立连接，这个非常危险，建议打开。
        //置为NO，主要用于这种情况：客户端请求的是子域名，而证书上的是另外一个域名。因为SSL证书上的域名是独立的，假如证书上注册的域名是www.google.com，那么mail.google.com是无法验证通过的；当然，有钱可以注册通配符的域名*.google.com，但这个还是比较贵的。
        //如置为NO，建议自己添加对应域名的校验逻辑。
        securityPolicy.validatesDomainName = NO;
        securityPolicy.pinnedCertificates = [NSSet setWithObjects:certData, nil];
    }else{
        securityPolicy = [AFSecurityPolicy defaultPolicy];
    }
    //如果是需要验证自建证书，需要设置为YES
    securityPolicy.allowInvalidCertificates = YES;
    return securityPolicy;
}
@end
